#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"
# shellcheck source=lib/profiles.sh
. "${SOURCE_DIR}/lib/profiles.sh"

have chezmoi || die 'chezmoi must be on PATH for template tests.'

home_token='~'
company_folder='ci-company'
for profile in $MACHINE_SETUP_PROFILES; do
  test_root="$(mktemp -d "${TMPDIR:-/tmp}/machine-setup-template.XXXXXX")"
  test_home="${test_root}/home"
  mkdir -p "$test_home"
  HOME="$test_home" \
    XDG_CONFIG_HOME="$test_home/.config" \
    MACHINE_SETUP_PROFILE="$profile" \
    MACHINE_SETUP_CI=1 \
    MACHINE_SETUP_PERSONAL_NAME='CI Personal' \
    MACHINE_SETUP_PERSONAL_EMAIL='personal@example.invalid' \
    MACHINE_SETUP_WORK_NAME='CI Work' \
    MACHINE_SETUP_WORK_EMAIL='work@example.invalid' \
    MACHINE_SETUP_COMPANY_FOLDER="$company_folder" \
    MACHINE_SETUP_PERSONAL_SSH_KEY="$home_token/.ssh/ci_personal" \
    MACHINE_SETUP_WORK_SSH_KEY="$home_token/.ssh/ci_work" \
    chezmoi init --source "$SOURCE_DIR"
  HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" \
    chezmoi --source "$SOURCE_DIR" apply
  HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" \
    chezmoi --source "$SOURCE_DIR" verify --exclude scripts

  for required in .bashrc .gitconfig .gitconfig-personal .gitconfig-work .ssh/config .tmux.conf .config/nvim/init.lua .config/mise/config.toml .config/mise/mise.lock; do
    [ -e "$test_home/$required" ] || die "${profile} did not render ${required}."
  done
  for workspace in personal work "$company_folder" scratch; do
    [ -d "$test_home/src/$workspace" ] || die "${profile} did not create src/${workspace}."
  done
  [ "$(git config --file "$test_home/.gitconfig" --get user.useConfigOnly)" = true ] || die 'Git identity guard is missing.'
  expected_work_config="$home_token/.gitconfig-work"
  [ "$(git config --file "$test_home/.gitconfig" --get "includeIf.gitdir:~/src/${company_folder}/.path")" = "$expected_work_config" ] || die 'The configured company folder must use the work Git identity.'
  [ -z "$(git config --file "$test_home/.gitconfig" --get commit.gpgSign 2>/dev/null || true)" ] || die 'Signing must not be enabled globally.'
  [ "$(git config --file "$test_home/.gitconfig-personal" --get user.email)" = personal@example.invalid ] || die 'Personal identity did not render.'
  [ "$(git config --file "$test_home/.gitconfig-personal" --get core.sshCommand)" = 'ssh -i ~/.ssh/ci_personal -o IdentitiesOnly=yes' ] || die 'Personal SSH key selection did not render.'
  [ "$(git config --file "$test_home/.gitconfig-work" --get core.sshCommand)" = 'ssh -i ~/.ssh/ci_work -o IdentitiesOnly=yes' ] || die 'Work SSH key selection did not render.'
  grep -Fq 'IdentityFile ~/.ssh/ci_personal' "$test_home/.ssh/config" || die 'Personal SSH host alias did not render.'
  grep -Fq 'IdentityFile ~/.ssh/ci_work' "$test_home/.ssh/config" || die 'Work SSH host alias did not render.'
  [ -f "$test_home/.config/machine-setup/local.bash" ] || die 'Private local config did not render.'

  case "$profile" in
    personal-mac-laptop | work-mac-laptop | work-mac-server)
      [ -f "$test_home/.config/ghostty/config" ] || die "${profile} did not render Ghostty."
      ;;
    minimal-remote | minimal-remote-no-root | work-linux-server)
      [ ! -e "$test_home/.config/ghostty/config" ] || die "${profile} unexpectedly rendered Ghostty."
      ;;
  esac
  printf 'template test passed: %s\n' "$profile"
done
