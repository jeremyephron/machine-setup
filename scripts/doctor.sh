#!/usr/bin/env bash
set -uo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"
# shellcheck source=lib/profiles.sh
. "${SOURCE_DIR}/lib/profiles.sh"
# shellcheck source=lib/packages.sh
. "${SOURCE_DIR}/lib/packages.sh"

load_profile "$1"
activate_homebrew || true
path_prepend "${HOME}/.local/bin"
if have mise; then
  eval "$(mise activate bash)"
fi
if have brew && rustup_prefix="$(brew --prefix rustup 2>/dev/null)" && [ -d "$rustup_prefix/bin" ]; then
  path_prepend "$rustup_prefix/bin"
fi
mason_bin="${XDG_DATA_HOME:-${HOME}/.local/share}/nvim/mason/bin"
if [ -d "$mason_bin" ]; then
  # Mason prepends this directory inside Neovim; mirror that environment when
  # checking editor-only tools without exposing them globally in the shell.
  path_prepend "$mason_bin"
fi

DOCTOR_FAILURES=0
DOCTOR_WARNINGS=0

pass_check() {
  printf '  %bok%b    %s\n' "${_MS_GREEN}" "${_MS_RESET}" "$*"
}

warn_check() {
  DOCTOR_WARNINGS=$((DOCTOR_WARNINGS + 1))
  printf '  %bwarn%b  %s\n' "${_MS_YELLOW}" "${_MS_RESET}" "$*"
}

fail_check() {
  DOCTOR_FAILURES=$((DOCTOR_FAILURES + 1))
  printf '  %bfail%b  %s\n' "${_MS_RED}" "${_MS_RESET}" "$*"
}

check_command() {
  if have "$1"; then
    pass_check "$1"
  else
    fail_check "$1 is missing"
  fi
}

check_optional_command() {
  if have "$1"; then
    pass_check "$1"
  else
    warn_check "$1 is not available on this profile"
  fi
}

heading "Machine setup doctor: ${PROFILE_NAME}"
heading 'Core command line'
for command in bash git ssh chezmoi mise nvim fzf rg; do
  check_command "$command"
done
for command in bat btop direnv fd gh git-lfs gpg jq nnn shellcheck shfmt tmux tree watch yq; do
  if [ "$PROFILE_NEEDS_ROOT" = '0' ]; then
    check_optional_command "$command"
  else
    check_command "$command"
  fi
done

case "$PROFILE_NAME" in
  minimal-remote | minimal-remote-no-root) ;;
  *)
    if have tree-sitter; then
      tree_sitter_version="$(tree-sitter --version | awk '{ print $2 }')"
      if version_at_least "$tree_sitter_version" '0.26.1'; then
        pass_check "tree-sitter CLI ${tree_sitter_version}"
      else
        fail_check "tree-sitter CLI ${tree_sitter_version} is older than 0.26.1"
      fi
    else
      fail_check 'tree-sitter CLI is missing'
    fi
    ;;
esac

heading 'Managed state'
for target in \
  "$HOME/.bash_profile" \
  "$HOME/.bashrc" \
  "$HOME/.gitconfig" \
  "$HOME/.gitconfig-personal" \
  "$HOME/.gitconfig-work" \
  "$HOME/.ssh/config" \
  "$HOME/.config/nvim/init.lua" \
  "$HOME/.config/mise/config.toml"; do
  if [ -e "$target" ]; then
    pass_check "${target#"$HOME"/}"
  else
    fail_check "${target#"$HOME"/} is missing"
  fi
done

company_folder="$(company_workspace_folder)"
for workspace in personal work "$company_folder" scratch; do
  if [ -d "$HOME/src/$workspace" ]; then
    pass_check "src/${workspace}/"
  else
    fail_check "src/${workspace}/ is missing"
  fi
done

if [ -f "$HOME/.gitconfig" ] && git config --file "$HOME/.gitconfig" --get user.useConfigOnly 2>/dev/null | grep -qx true; then
  pass_check 'Git requires an explicit directory identity'
else
  fail_check 'Git identity guard is not active'
fi

for identity in personal work; do
  identity_file="$HOME/.gitconfig-${identity}"
  signing_key=''
  ssh_key="$(identity_ssh_key "$identity")"
  if [ -f "$identity_file" ] && git config --file "$identity_file" --get user.email >/dev/null 2>&1; then
    pass_check "${identity} Git identity"
  else
    fail_check "${identity} Git identity is incomplete"
  fi
  if [ -f "$identity_file" ]; then
    signing_key="$(git config --file "$identity_file" --get user.signingKey 2>/dev/null || true)"
  fi
  if [ -n "$signing_key" ] && gpg --batch --list-secret-keys "$signing_key" >/dev/null 2>&1; then
    pass_check "${identity} GPG signing key configured and available"
  elif [ -n "$signing_key" ]; then
    warn_check "${identity} GPG signing key is configured but its secret key is unavailable"
  elif gpg --batch --with-colons --list-secret-keys 2>/dev/null | grep -q '^sec:'; then
    warn_check "${identity} GPG signing key is not selected; secret GPG keys are installed"
  else
    warn_check "${identity} GPG signing key is not selected and no secret GPG keys are installed"
  fi
  if [ -f "$ssh_key" ] && [ -f "${ssh_key}.pub" ]; then
    pass_check "${identity} SSH key pair (${ssh_key#"$HOME"/})"
  elif [ -f "$ssh_key" ]; then
    warn_check "${identity} SSH private key exists but its .pub file is missing (${ssh_key#"$HOME"/})"
  else
    warn_check "${identity} configured SSH key pair is missing (${ssh_key#"$HOME"/}); run ./setup.sh identities"
  fi
done

if [ "$PROFILE_DEV" = '1' ] && [ "${MACHINE_SETUP_CORE_ONLY:-0}" = '0' ]; then
  heading 'Development runtimes'
  for command in bazel cmake ffmpeg gcc magick node npm python rustc cargo java javac ninja pre-commit slack; do
    check_command "$command"
  done
  if [ "$PROFILE_PLATFORM" = 'darwin' ]; then
    check_command lldb
  else
    check_command gdb
  fi
  if [ -x "$HOME/.local/share/machine-setup/python-scratch/bin/ipython" ]; then
    pass_check 'Python scientific scratch environment'
  else
    fail_check 'Python scientific scratch environment is missing'
  fi

  heading 'Editor development tools'
  for command in bash-language-server basedpyright-langserver clangd debugpy-adapter docker-langserver jdtls prettier ruff rust-analyzer stylua terraform-ls typescript-language-server yaml-language-server; do
    check_command "$command"
  done
fi

if [ "$PROFILE_INFRA" = '1' ] && [ "${MACHINE_SETUP_CORE_ONLY:-0}" = '0' ]; then
  heading 'Infrastructure'
  for command in aws kubectl terraform; do
    check_command "$command"
  done
  if [ "${MACHINE_SETUP_CI:-0}" = '0' ]; then
    check_command docker
    if [ "$PROFILE_PLATFORM" = 'ubuntu' ]; then
      check_command tailscale
    fi
    if have docker && docker info >/dev/null 2>&1; then
      pass_check 'Docker daemon is reachable'
    else
      warn_check 'Docker daemon is not reachable'
    fi
    if have tailscale && tailscale status >/dev/null 2>&1; then
      pass_check 'Tailscale is connected'
    elif [ "$PROFILE_PLATFORM" = 'darwin' ] && [ -d /Applications/Tailscale.app ]; then
      warn_check 'Tailscale app is installed; verify its connection in the menu bar'
    else
      warn_check 'Tailscale still needs sign-in'
    fi
  fi
fi

if [ "$PROFILE_PLATFORM" = 'darwin' ]; then
  heading 'macOS'
  if [ "${SHELL:-}" = '/opt/homebrew/bin/bash' ]; then
    pass_check 'Homebrew Bash is the login shell'
  else
    warn_check "Login shell is ${SHELL:-unknown}; a fresh login may be required"
  fi
  if [ "${MACHINE_SETUP_CI:-0}" = '0' ]; then
    initial_repeat="$(defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null || true)"
    key_repeat="$(defaults read NSGlobalDomain KeyRepeat 2>/dev/null || true)"
    if [ "$initial_repeat" = '10' ] && [ "$key_repeat" = '1' ]; then
      pass_check 'Keyboard repeat is 150 ms / 15 ms'
    else
      fail_check 'Keyboard repeat does not match the requested values'
    fi
    if fdesetup status 2>/dev/null | grep -q 'FileVault is On'; then
      pass_check 'FileVault'
    else
      warn_check 'FileVault is off'
    fi
    firewall_state="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || true)"
    case "$firewall_state" in
      *enabled*) pass_check 'Application firewall' ;;
      *) warn_check 'Application firewall is off' ;;
    esac
  fi
  if [ "$PROFILE_DESKTOP" = '1' ] && [ "${MACHINE_SETUP_CORE_ONLY:-0}" = '0' ] && [ "${MACHINE_SETUP_SKIP_DESKTOP:-0}" = '0' ]; then
    for app in 'Docker' 'Ghostty' 'Google Chrome' 'Microsoft Excel' 'Microsoft PowerPoint' 'Microsoft Word' 'Obsidian' 'OpenSuperWhisper' 'OpenVPN Connect' 'Rectangle' 'Signal' 'Skim' 'Slack' 'Spotify' 'Tailscale' 'TickTick' 'WhatsApp' 'XQuartz' 'Zotero'; do
      if [ -d "/Applications/${app}.app" ] ||
        [ -d "$HOME/Applications/${app}.app" ] ||
        { [ "$app" = 'XQuartz' ] && [ -d /Applications/Utilities/XQuartz.app ]; }; then
        pass_check "$app"
      else
        fail_check "$app is missing"
      fi
    done
  fi
fi

if [ "$PROFILE_PLATFORM" != 'darwin' ]; then
  heading 'Linux shell'
  case "${SHELL:-}" in
    */bash) pass_check "Bash login shell (${SHELL})" ;;
    *) warn_check "Login shell is ${SHELL:-unknown}; run chsh -s /bin/bash if this host permits it" ;;
  esac
fi

if [ "$PROFILE_DESKTOP" = '1' ] && [ "${MACHINE_SETUP_CORE_ONLY:-0}" = '0' ] && [ "${MACHINE_SETUP_SKIP_DESKTOP:-0}" = '0' ] && [ "${MACHINE_SETUP_CI:-0}" = '0' ]; then
  heading 'Manual account and browser checks'
  warn_check 'Verify Chrome sync plus Bitwarden, Vimium, and Video Speed Controller'
  warn_check 'Verify Bitwarden, GitHub, Slack, VPN, email, Signal, WhatsApp, TickTick, Zotero, and Tailscale sign-ins'
fi

heading 'Doctor summary'
printf '  %d failure(s), %d item(s) needing attention\n' "$DOCTOR_FAILURES" "$DOCTOR_WARNINGS"
if [ "$DOCTOR_FAILURES" -gt 0 ]; then
  exit 1
fi
