#!/usr/bin/env bash

if [ -n "${MACHINE_SETUP_COMMON_LOADED:-}" ]; then
  return 0
fi
MACHINE_SETUP_COMMON_LOADED=1

if [ -t 1 ]; then
  _MS_BOLD='\033[1m'
  _MS_BLUE='\033[34m'
  _MS_GREEN='\033[32m'
  _MS_YELLOW='\033[33m'
  _MS_RED='\033[31m'
  _MS_RESET='\033[0m'
else
  _MS_BOLD=''
  _MS_BLUE=''
  _MS_GREEN=''
  _MS_YELLOW=''
  _MS_RED=''
  _MS_RESET=''
fi

info() {
  printf '%binfo%b  %s\n' "${_MS_BLUE}" "${_MS_RESET}" "$*"
}

success() {
  printf '%bok%b    %s\n' "${_MS_GREEN}" "${_MS_RESET}" "$*"
}

warn() {
  printf '%bwarn%b  %s\n' "${_MS_YELLOW}" "${_MS_RESET}" "$*" >&2
}

error() {
  printf '%berror%b %s\n' "${_MS_RED}" "${_MS_RESET}" "$*" >&2
}

die() {
  error "$*"
  exit 1
}

heading() {
  printf '\n%b%s%b\n' "${_MS_BOLD}" "$*" "${_MS_RESET}"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

ensure_dir() {
  [ -d "$1" ] || mkdir -p "$1"
}

shell_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

run() {
  if [ "${MACHINE_SETUP_DRY_RUN:-0}" = "1" ]; then
    printf '+ '
    printf '%s ' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

confirm() {
  local prompt="${1:-Continue?}"
  local answer

  if [ "${MACHINE_SETUP_ASSUME_YES:-0}" = "1" ]; then
    return 0
  fi
  if [ ! -t 0 ]; then
    return 1
  fi
  printf '%s [y/N] ' "$prompt"
  IFS= read -r answer
  case "$answer" in
    y | Y | yes | YES | Yes) return 0 ;;
    *) return 1 ;;
  esac
}

sha256_file() {
  if have sha256sum; then
    sha256sum "$1" | awk '{print $1}'
  elif have shasum; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    die "Neither sha256sum nor shasum is available."
  fi
}

download_verified() {
  local url="$1"
  local expected="$2"
  local destination="$3"
  local actual

  have curl || die "curl is required to download ${url}."
  run curl --fail --location --proto '=https' --tlsv1.2 \
    --retry 3 --silent --show-error --output "$destination" "$url"
  [ "${MACHINE_SETUP_DRY_RUN:-0}" = "1" ] && return 0
  actual="$(sha256_file "$destination")"
  if [ "$actual" != "$expected" ]; then
    rm -f "$destination"
    die "Checksum mismatch for ${url}. Expected ${expected}; got ${actual}."
  fi
}

is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

is_linux() {
  [ "$(uname -s)" = "Linux" ]
}

cpu_arch() {
  case "$(uname -m)" in
    arm64 | aarch64) printf 'arm64\n' ;;
    x86_64 | amd64) printf 'amd64\n' ;;
    *) die "Unsupported CPU architecture: $(uname -m)" ;;
  esac
}

path_prepend() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) PATH="$1:${PATH}" ;;
  esac
  export PATH
}

version_at_least() {
  awk -v actual="$1" -v required="$2" 'BEGIN {
    split(actual, a, "."); split(required, r, ".");
    for (i = 1; i <= 3; i++) {
      a[i] += 0; r[i] += 0;
      if (a[i] > r[i]) exit 0;
      if (a[i] < r[i]) exit 1;
    }
    exit 0;
  }'
}

machine_setup_state_dir() {
  printf '%s\n' "${XDG_STATE_HOME:-${HOME}/.local/state}/machine-setup"
}

machine_setup_config_dir() {
  printf '%s\n' "${XDG_CONFIG_HOME:-${HOME}/.config}/machine-setup"
}

company_workspace_folder() {
  local config_file
  local folder=''

  config_file="${XDG_CONFIG_HOME:-${HOME}/.config}/chezmoi/chezmoi.toml"
  if [ -r "$config_file" ]; then
    folder="$(awk '
      /^\[data\.machineSetup\]$/ { in_section = 1; next }
      in_section && /^\[/ { exit }
      in_section && /^companyFolder[[:space:]]*=/ {
        sub(/^[^=]*=[[:space:]]*/, "")
        gsub(/^"|"$/, "")
        print
        exit
      }
    ' "$config_file")"
  fi
  folder="${folder:-company}"
  case "$folder" in
    *[!A-Za-z0-9._-]* | '') die 'companyFolder must be one folder name containing only letters, numbers, dots, underscores, or hyphens.' ;;
  esac
  case "$folder" in
    [A-Za-z0-9]*) ;;
    *) die 'companyFolder must begin with a letter or number.' ;;
  esac
  printf '%s\n' "$folder"
}

default_identity_ssh_key() {
  case "$1" in
    personal) printf '%s\n' "$HOME/.ssh/id_ed25519_personal_gh" ;;
    work) printf '%s\n' "$HOME/.ssh/id_ed25519" ;;
    *) die "Unknown identity: $1" ;;
  esac
}

# Return the private key selected by an identity's generated Git configuration.
# Identity key paths are intentionally machine-local and may keep historical
# filenames; they do not need to match this repository's defaults.
identity_ssh_key() {
  local identity="$1"
  local identity_file="$HOME/.gitconfig-${identity}"
  local ssh_command=''
  local key=''

  if [ -f "$identity_file" ]; then
    ssh_command="$(git config --file "$identity_file" --get core.sshCommand 2>/dev/null || true)"
    key="$(printf '%s\n' "$ssh_command" | awk '{
      for (i = 1; i < NF; i++) {
        if ($i == "-i") {
          print $(i + 1)
          exit
        }
      }
    }')"
    key="${key#\"}"
    key="${key%\"}"
    key="${key#\'}"
    key="${key%\'}"
  fi

  if [ -z "$key" ]; then
    default_identity_ssh_key "$identity"
    return
  fi
  case "$key" in
    \~/*) printf '%s\n' "$HOME/${key#\~/}" ;;
    \$HOME/*) printf '%s\n' "$HOME/${key#\$HOME/}" ;;
    *) printf '%s\n' "$key" ;;
  esac
}
