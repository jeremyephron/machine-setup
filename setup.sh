#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"
# shellcheck source=lib/versions.sh
. "${SOURCE_DIR}/lib/versions.sh"
# shellcheck source=lib/profiles.sh
. "${SOURCE_DIR}/lib/profiles.sh"
# shellcheck source=lib/packages.sh
. "${SOURCE_DIR}/lib/packages.sh"
# shellcheck source=lib/portable.sh
. "${SOURCE_DIR}/lib/portable.sh"

COMMAND=''
PROFILE_NAME="${MACHINE_SETUP_PROFILE:-}"
MACHINE_SETUP_ASSUME_YES="${MACHINE_SETUP_ASSUME_YES:-0}"
MACHINE_SETUP_CI="${MACHINE_SETUP_CI:-0}"
MACHINE_SETUP_DRY_RUN=0
MACHINE_SETUP_CORE_ONLY=0
MACHINE_SETUP_SKIP_DESKTOP=0

usage() {
  cat <<'EOF'
Usage: ./setup.sh COMMAND [OPTIONS]

Commands:
  plan        Show the selected profile, package gaps, and dotfile changes.
  apply       Install missing dependencies and apply the managed configuration.
  doctor      Check the machine against the selected profile.
  update      Explicitly upgrade managed packages and language tool versions.
  identities Generate missing SSH keys and guide Git/GPG identity setup.
  cleanup     Preview or perform opt-in migration and legacy cleanup.

Options:
  --profile NAME   Select a machine profile.
  --yes            Accept non-destructive apply prompts.
  --core-only      Stop after the fast shell/editor/core-tool baseline.
  --skip-desktop   Skip GUI applications for this run.
  --dry-run        Print system-changing commands without running them.
  --ci             Use disposable-test defaults and skip host-only settings.
  -h, --help       Show this help.

Profiles:
  personal-mac-laptop, work-mac-laptop, work-mac-server,
  work-linux-server, personal-linux-laptop, minimal-remote,
  minimal-remote-no-root
EOF
}

parse_args() {
  [ "$#" -gt 0 ] || {
    usage
    exit 1
  }
  COMMAND="$1"
  shift
  case "$COMMAND" in
    plan | apply | doctor | update | identities | cleanup) ;;
    -h | --help | help)
      usage
      exit 0
      ;;
    *) die "Unknown command: ${COMMAND}" ;;
  esac

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        [ "$#" -ge 2 ] || die '--profile needs a value.'
        PROFILE_NAME="$2"
        shift 2
        ;;
      --yes)
        MACHINE_SETUP_ASSUME_YES=1
        shift
        ;;
      --core-only)
        MACHINE_SETUP_CORE_ONLY=1
        shift
        ;;
      --skip-desktop)
        MACHINE_SETUP_SKIP_DESKTOP=1
        shift
        ;;
      --dry-run)
        MACHINE_SETUP_DRY_RUN=1
        shift
        ;;
      --ci)
        MACHINE_SETUP_CI=1
        MACHINE_SETUP_ASSUME_YES=1
        MACHINE_SETUP_SKIP_DESKTOP=1
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *) die "Unknown option: $1" ;;
    esac
  done
}

saved_profile() {
  local file
  file="$(machine_setup_config_dir)/profile"
  [ -r "$file" ] && sed -n '1p' "$file"
}

resolve_profile() {
  if [ -z "$PROFILE_NAME" ]; then
    PROFILE_NAME="$(saved_profile || true)"
  fi
  if [ -z "$PROFILE_NAME" ]; then
    select_profile
  fi
  load_profile "$PROFILE_NAME"
  validate_profile_platform
}

save_profile() {
  local directory
  directory="$(machine_setup_config_dir)"
  ensure_dir "$directory"
  printf '%s\n' "$PROFILE_NAME" >"${directory}/profile"
}

chezmoi_config_profile() {
  local config_file="$1"
  awk '
    /^\[data\.machineSetup\]$/ { in_section = 1; next }
    in_section && /^\[/ { exit }
    in_section && /^profile[[:space:]]*=/ {
      sub(/^[^=]*=[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$config_file"
}

validate_existing_chezmoi_config() {
  local config_file
  local configured_profile
  config_file="${XDG_CONFIG_HOME:-${HOME}/.config}/chezmoi/chezmoi.toml"
  [ -f "$config_file" ] || return 0
  configured_profile="$(chezmoi_config_profile "$config_file")"
  if [ -z "$configured_profile" ]; then
    die "Existing chezmoi config at ${config_file} is not configured for this repository. Merge it with home/.chezmoi.toml.tmpl, then retry."
  fi
  if [ "$configured_profile" != "$PROFILE_NAME" ]; then
    die "Selected profile ${PROFILE_NAME} conflicts with ${configured_profile} in ${config_file}. Update the local chezmoi profile or select the configured profile, then retry."
  fi
}

ensure_chezmoi_initialized() {
  local config_file
  config_file="${XDG_CONFIG_HOME:-${HOME}/.config}/chezmoi/chezmoi.toml"
  if [ -f "$config_file" ]; then
    validate_existing_chezmoi_config
    return 0
  fi
  heading 'Personal configuration'
  info 'Collecting machine-local names, account emails, signing keys, and proxy settings.'
  export MACHINE_SETUP_PROFILE="$PROFILE_NAME"
  export MACHINE_SETUP_CI
  if [ "$MACHINE_SETUP_CI" = '1' ]; then
    export MACHINE_SETUP_PERSONAL_NAME='CI User'
    export MACHINE_SETUP_PERSONAL_EMAIL='ci-personal@example.invalid'
    export MACHINE_SETUP_WORK_NAME='CI User'
    export MACHINE_SETUP_WORK_EMAIL='ci-work@example.invalid'
  fi
  chezmoi init --source "$SOURCE_DIR"
}

show_dotfile_plan() {
  if ! have chezmoi; then
    warn 'chezmoi is not installed yet; apply will install it before previewing configuration.'
    return 0
  fi
  if [ ! -f "${XDG_CONFIG_HOME:-${HOME}/.config}/chezmoi/chezmoi.toml" ]; then
    warn 'Machine-local answers have not been collected; apply will prompt before changing dotfiles.'
    return 0
  fi
  heading 'Managed configuration diff'
  chezmoi --source "$SOURCE_DIR" diff --no-pager || true
}

retire_legacy_nvim_init() {
  local legacy_init="${XDG_CONFIG_HOME:-${HOME}/.config}/nvim/init.vim"
  local backup_dir
  local backup_path

  if [ ! -e "$legacy_init" ] && [ ! -L "$legacy_init" ]; then
    return 0
  fi
  backup_dir="$(machine_setup_state_dir)/backups/$(date +%Y%m%d-%H%M%S)"
  backup_path="${backup_dir}/nvim-init.vim"
  heading 'Legacy Neovim configuration'
  warn "Neovim cannot use both ${legacy_init} and the managed init.lua."
  if ! confirm "Move ${legacy_init} to the recoverable backup ${backup_path}?"; then
    die 'The legacy init.vim must be moved before the managed Neovim configuration can be applied.'
  fi
  ensure_dir "$backup_dir"
  [ ! -e "$backup_path" ] || die "Backup target already exists: ${backup_path}"
  run mv "$legacy_init" "$backup_path"
  success "Moved the legacy init.vim to ${backup_path}."
}

apply_dotfiles() {
  ensure_chezmoi_initialized
  retire_legacy_nvim_init
  heading 'Managed configuration'
  if [ "$MACHINE_SETUP_CI" = '1' ]; then
    # Hosted runner images are disposable but can contain pre-existing dotfiles.
    # Make the repository authoritative without attempting to open /dev/tty.
    chezmoi --source "$SOURCE_DIR" apply --force --no-tty
  elif [ "$MACHINE_SETUP_ASSUME_YES" = '1' ]; then
    chezmoi --source "$SOURCE_DIR" apply
  else
    chezmoi --source "$SOURCE_DIR" diff --no-pager || true
    if confirm 'Apply these managed configuration changes?'; then
      chezmoi --source "$SOURCE_DIR" apply --interactive
    else
      warn 'Managed configuration was not applied; stopping before runtimes and operating-system preferences.'
      return 1
    fi
  fi
  save_profile
}

run_post_apply() {
  local nvim_error_guard='+if v:errmsg != "" | cquit 1 | endif'

  [ "$MACHINE_SETUP_DRY_RUN" = '1' ] && return 0
  if [ "$PROFILE_NEEDS_ROOT" = '0' ]; then
    heading 'No-root user-local tools'
    mise install --locked --yes
    mise reshim
    mise exec -- nvim --headless '+Lazy! restore' "$nvim_error_guard" +qa
    mise exec -- nvim --headless \
      '+lua local missing = {}; for name, plugin in pairs(require("lazy.core.config").plugins) do if plugin._.installed ~= true then table.insert(missing, name) end end; assert(#missing == 0, "missing plugins: " .. table.concat(missing, ", "))' \
      "$nvim_error_guard" \
      +qa
  fi
  if [ "$PROFILE_NEEDS_ROOT" = '1' ] && { [ "$PROFILE_DEV" = '0' ] || [ "$MACHINE_SETUP_CORE_ONLY" = '1' ]; }; then
    "${SOURCE_DIR}/scripts/install-editor.sh"
  fi
  if [ "$PROFILE_DEV" = '1' ] && [ "$MACHINE_SETUP_CORE_ONLY" = '0' ]; then
    "${SOURCE_DIR}/scripts/install-runtimes.sh" "$PROFILE_NAME"
    "${SOURCE_DIR}/scripts/install-python-scratch.sh"
  fi
  if [ "$PROFILE_PLATFORM" = 'darwin' ] && [ "$PROFILE_MACOS_DEFAULTS" = '1' ] && [ "$MACHINE_SETUP_CI" = '0' ]; then
    "${SOURCE_DIR}/scripts/apply-macos-defaults.sh"
  fi
  if [ "$PROFILE_PLATFORM" = 'ubuntu' ] && [ "$PROFILE_INFRA" = '1' ] && [ "$MACHINE_SETUP_CORE_ONLY" = '0' ] && [ "$MACHINE_SETUP_CI" = '0' ]; then
    "${SOURCE_DIR}/scripts/install-linux-services.sh" "$PROFILE_NAME"
  fi
  if [ "$PROFILE_PLATFORM" = 'ubuntu' ] && [ "$PROFILE_DESKTOP" = '1' ] && [ "$MACHINE_SETUP_CORE_ONLY" = '0' ] && [ "$MACHINE_SETUP_SKIP_DESKTOP" = '0' ] && [ "$MACHINE_SETUP_CI" = '0' ]; then
    "${SOURCE_DIR}/scripts/install-ubuntu-desktop.sh"
  fi
}

command_plan() {
  describe_profile
  package_plan
  show_dotfile_plan
  heading 'Safety boundary'
  printf '  plan changes nothing\n'
  printf '  apply installs missing items and updates managed files\n'
  printf '  update is the only normal command that upgrades packages\n'
  printf '  cleanup is separate, previews exact targets, and asks again\n'
}

command_apply() {
  if [ "$MACHINE_SETUP_DRY_RUN" = '1' ]; then
    warn '--dry-run uses the same fully read-only inspection as plan.'
    command_plan
    return 0
  fi
  describe_profile
  install_profile_packages
  ensure_portable_bootstrap_tools
  apply_dotfiles
  run_post_apply
  success 'Apply finished. Run ./setup.sh doctor to see anything still needing attention.'
}

command_update() {
  describe_profile
  update_profile_packages
  if have mise; then
    "${SOURCE_DIR}/scripts/update-mise-lock.sh"
  fi
  success 'Update finished. Review and commit any intentional lockfile changes.'
}

command_doctor() {
  "${SOURCE_DIR}/scripts/doctor.sh" "$PROFILE_NAME"
}

command_identities() {
  "${SOURCE_DIR}/scripts/setup-identities.sh" "$PROFILE_NAME"
}

command_cleanup() {
  "${SOURCE_DIR}/scripts/cleanup-legacy.sh" "$PROFILE_NAME"
}

main() {
  parse_args "$@"
  resolve_profile
  validate_existing_chezmoi_config
  export SOURCE_DIR MACHINE_SETUP_ASSUME_YES MACHINE_SETUP_CI MACHINE_SETUP_DRY_RUN
  export MACHINE_SETUP_CORE_ONLY MACHINE_SETUP_SKIP_DESKTOP

  case "$COMMAND" in
    plan) command_plan ;;
    apply) command_apply ;;
    doctor) command_doctor ;;
    update) command_update ;;
    identities) command_identities ;;
    cleanup) command_cleanup ;;
  esac
}

main "$@"
