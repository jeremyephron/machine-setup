#!/usr/bin/env bash

MACHINE_SETUP_PROFILES='personal-mac-laptop work-mac-laptop work-mac-server work-linux-server personal-linux-laptop minimal-remote minimal-remote-no-root'

profile_is_valid() {
  case " $MACHINE_SETUP_PROFILES " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

load_profile() {
  PROFILE_NAME="$1"
  profile_is_valid "$PROFILE_NAME" || die "Unknown profile: ${PROFILE_NAME}"

  PROFILE_PLATFORM=''
  PROFILE_NEEDS_ROOT=1
  PROFILE_CORE_ONLY=0
  PROFILE_DESKTOP=0
  PROFILE_DEV=0
  PROFILE_INFRA=0
  PROFILE_LATEX=0
  PROFILE_MACOS_DEFAULTS=0

  case "$PROFILE_NAME" in
    personal-mac-laptop | work-mac-laptop | work-mac-server)
      PROFILE_PLATFORM='darwin'
      PROFILE_DESKTOP=1
      PROFILE_DEV=1
      PROFILE_INFRA=1
      PROFILE_LATEX=1
      PROFILE_MACOS_DEFAULTS=1
      ;;
    work-linux-server)
      PROFILE_PLATFORM='ubuntu'
      PROFILE_DEV=1
      PROFILE_INFRA=1
      ;;
    personal-linux-laptop)
      PROFILE_PLATFORM='ubuntu'
      PROFILE_DESKTOP=1
      PROFILE_DEV=1
      PROFILE_INFRA=1
      PROFILE_LATEX=1
      ;;
    minimal-remote)
      PROFILE_PLATFORM='ubuntu'
      PROFILE_CORE_ONLY=1
      ;;
    minimal-remote-no-root)
      PROFILE_PLATFORM='linux'
      PROFILE_NEEDS_ROOT=0
      PROFILE_CORE_ONLY=1
      ;;
  esac
  export PROFILE_NAME PROFILE_PLATFORM PROFILE_NEEDS_ROOT PROFILE_CORE_ONLY
  export PROFILE_DESKTOP PROFILE_DEV PROFILE_INFRA PROFILE_LATEX PROFILE_MACOS_DEFAULTS
}

select_profile() {
  local choice
  local index=1

  [ -t 0 ] || die "Choose a profile with --profile when running non-interactively."
  heading 'Choose this machine profile'
  for choice in $MACHINE_SETUP_PROFILES; do
    printf '  %d) %s\n' "$index" "$choice"
    index=$((index + 1))
  done
  while :; do
    printf 'Profile [1-7]: '
    IFS= read -r choice
    case "$choice" in
      1) PROFILE_NAME='personal-mac-laptop' ;;
      2) PROFILE_NAME='work-mac-laptop' ;;
      3) PROFILE_NAME='work-mac-server' ;;
      4) PROFILE_NAME='work-linux-server' ;;
      5) PROFILE_NAME='personal-linux-laptop' ;;
      6) PROFILE_NAME='minimal-remote' ;;
      7) PROFILE_NAME='minimal-remote-no-root' ;;
      *)
        warn 'Please enter a number from 1 to 7.'
        continue
        ;;
    esac
    break
  done
}

validate_profile_platform() {
  local os_name
  local ubuntu_major

  os_name="$(uname -s)"
  case "$PROFILE_PLATFORM" in
    darwin)
      [ "$os_name" = 'Darwin' ] || die "${PROFILE_NAME} requires macOS."
      [ "$(uname -m)" = 'arm64' ] || die 'Only Apple silicon macOS is supported.'
      ;;
    ubuntu)
      [ "$os_name" = 'Linux' ] || die "${PROFILE_NAME} requires Ubuntu Linux."
      [ -r /etc/os-release ] || die 'Cannot identify this Linux distribution.'
      # shellcheck disable=SC1091
      . /etc/os-release
      [ "${ID:-}" = 'ubuntu' ] || die "${PROFILE_NAME} supports Ubuntu only."
      ubuntu_major="${VERSION_ID%%.*}"
      [ "$ubuntu_major" -ge 24 ] || die 'Ubuntu 24.04 or newer is required.'
      if [ "$PROFILE_DESKTOP" = '1' ] && [ "$(cpu_arch)" != 'amd64' ]; then
        die 'The Ubuntu desktop profile requires x86-64 because Chrome, Slack, Spotify, and Signal do not publish the requested full ARM64 app set. Ubuntu ARM64 remains supported for server and remote profiles.'
      fi
      ;;
    linux)
      [ "$os_name" = 'Linux' ] || die "${PROFILE_NAME} requires Linux."
      ;;
  esac
}

describe_profile() {
  heading "Profile: ${PROFILE_NAME}"
  if [ "${MACHINE_SETUP_CORE_ONLY:-0}" = '1' ] || [ "$PROFILE_CORE_ONLY" = '1' ]; then
    printf '  run scope:      core only\n'
  elif [ "${MACHINE_SETUP_SKIP_DESKTOP:-0}" = '1' ]; then
    printf '  run scope:      full, without desktop apps\n'
  else
    printf '  run scope:      full profile\n'
  fi
  printf '  platform:       %s\n' "$PROFILE_PLATFORM"
  printf '  root access:    %s\n' "$PROFILE_NEEDS_ROOT"
  printf '  desktop apps:   %s\n' "$PROFILE_DESKTOP"
  printf '  development:    %s\n' "$PROFILE_DEV"
  printf '  infrastructure: %s\n' "$PROFILE_INFRA"
  printf '  LaTeX:          %s\n' "$PROFILE_LATEX"
}
