#!/usr/bin/env bash

activate_homebrew() {
  local brew_bin=''
  if have brew; then
    brew_bin="$(command -v brew)"
  elif [ -x /opt/homebrew/bin/brew ]; then
    brew_bin='/opt/homebrew/bin/brew'
  elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    brew_bin='/home/linuxbrew/.linuxbrew/bin/brew'
  elif [ -x "${HOME}/.linuxbrew/bin/brew" ]; then
    brew_bin="${HOME}/.linuxbrew/bin/brew"
  fi
  [ -n "$brew_bin" ] || return 1
  eval "$("$brew_bin" shellenv)"
}

sudo_run() {
  if [ "$(id -u)" -eq 0 ]; then
    run "$@"
  elif have sudo; then
    run sudo "$@"
  else
    die "Root access is required for: $*"
  fi
}

ensure_texlive_recommended_packages() {
  local tlmgr_bin
  local tex_package
  local missing_tex=()

  tlmgr_bin="$(command -v tlmgr 2>/dev/null || true)"
  [ -n "$tlmgr_bin" ] || die 'TeX Live is installed, but tlmgr is not on PATH. Start a new shell and retry.'

  for tex_package in latexmk collection-latexrecommended collection-fontsrecommended; do
    if ! "$tlmgr_bin" info --only-installed "$tex_package" 2>/dev/null | grep -Eq '^installed:[[:space:]]+Yes$'; then
      missing_tex+=("$tex_package")
    fi
  done
  if [ "${#missing_tex[@]}" -eq 0 ]; then
    success 'Recommended TeX packages are installed'
    return 0
  fi

  # TeX Live requires its package manager to be current before it will install
  # packages from a newer CTAN repository snapshot.
  sudo_run "$tlmgr_bin" update --self
  sudo_run "$tlmgr_bin" install "${missing_tex[@]}"
}

ensure_xcode_tools() {
  xcode-select -p >/dev/null 2>&1 && return 0
  if [ "$MACHINE_SETUP_DRY_RUN" = '1' ]; then
    run xcode-select --install
    return 0
  fi
  xcode-select --install || true
  die 'Finish the Command Line Tools installer, then run apply again.'
}

ensure_ubuntu_prerequisites() {
  local packages=''
  local package
  while IFS= read -r package; do
    [ -n "$package" ] && packages="${packages} ${package}"
  done <"${SOURCE_DIR}/packages/apt/base.txt"
  if [ "$PROFILE_DEV" = '1' ] && [ "$MACHINE_SETUP_CORE_ONLY" = '0' ]; then
    while IFS= read -r package; do
      [ -n "$package" ] && packages="${packages} ${package}"
    done <"${SOURCE_DIR}/packages/apt/dev.txt"
  fi
  if [ "$PROFILE_LATEX" = '1' ] && [ "$MACHINE_SETUP_CORE_ONLY" = '0' ]; then
    while IFS= read -r package; do
      [ -n "$package" ] && packages="${packages} ${package}"
    done <"${SOURCE_DIR}/packages/apt/latex.txt"
  fi
  # Word splitting is intentional for package names from repository-owned files.
  # shellcheck disable=SC2086
  sudo_run apt-get update
  # shellcheck disable=SC2086
  sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y $packages
}

install_homebrew() {
  local installer
  local url

  activate_homebrew && return 0
  heading 'Homebrew'
  info 'Installing the checksum-verified bootstrap revision.'
  installer="$(mktemp "${TMPDIR:-/tmp}/machine-setup-brew.XXXXXX")"
  url="https://raw.githubusercontent.com/Homebrew/install/${HOMEBREW_INSTALL_COMMIT}/install.sh"
  download_verified "$url" "$HOMEBREW_INSTALL_SHA256" "$installer"
  if [ "$MACHINE_SETUP_DRY_RUN" = '0' ]; then
    NONINTERACTIVE=1 CI=1 /bin/bash "$installer"
    rm -f "$installer"
  fi
  activate_homebrew || die 'Homebrew installed but could not be activated.'
}

cask_app_name() {
  case "$1" in
    cursor) printf 'Cursor\n' ;;
    docker) printf 'Docker\n' ;;
    ghostty) printf 'Ghostty\n' ;;
    google-chrome) printf 'Google Chrome\n' ;;
    microsoft-excel) printf 'Microsoft Excel\n' ;;
    microsoft-powerpoint) printf 'Microsoft PowerPoint\n' ;;
    microsoft-word) printf 'Microsoft Word\n' ;;
    obsidian) printf 'Obsidian\n' ;;
    opensuperwhisper) printf 'OpenSuperWhisper\n' ;;
    openvpn-connect) printf 'OpenVPN Connect\n' ;;
    rectangle) printf 'Rectangle\n' ;;
    signal) printf 'Signal\n' ;;
    skim) printf 'Skim\n' ;;
    slack) printf 'Slack\n' ;;
    spotify) printf 'Spotify\n' ;;
    tailscale-app) printf 'Tailscale\n' ;;
    ticktick) printf 'TickTick\n' ;;
    whatsapp) printf 'WhatsApp\n' ;;
    zotero) printf 'Zotero\n' ;;
    *) return 1 ;;
  esac
}

cask_artifact_exists() {
  local app_name
  if [ "$1" = 'xquartz' ]; then
    [ -d /Applications/Utilities/XQuartz.app ]
    return
  fi
  app_name="$(cask_app_name "$1" 2>/dev/null)" || return 1
  [ -d "/Applications/${app_name}.app" ] || [ -d "${HOME}/Applications/${app_name}.app" ]
}

install_desktop_casks() {
  local brewfile="$1"
  local cask
  while IFS= read -r cask <&3; do
    [ -n "$cask" ] || continue
    if brew list --cask "$cask" >/dev/null 2>&1; then
      success "${cask} is already Homebrew-managed"
    elif cask_artifact_exists "$cask"; then
      warn "${cask} already exists outside Homebrew; preserving that installation"
    else
      run brew install --cask "$cask"
    fi
  done 3<<EOF
$(awk -F'"' '/^cask / { print $2 }' "$brewfile")
EOF
}

update_desktop_casks() {
  local brewfile="$1"
  local cask
  while IFS= read -r cask <&3; do
    [ -n "$cask" ] || continue
    if brew list --cask "$cask" >/dev/null 2>&1; then
      run brew upgrade --cask "$cask"
    elif cask_artifact_exists "$cask"; then
      warn "${cask} is not Homebrew-managed and was left for its own updater"
    else
      run brew install --cask "$cask"
    fi
  done 3<<EOF
$(awk -F'"' '/^cask / { print $2 }' "$brewfile")
EOF
}

brewfile_check() {
  local brewfile="$1"
  local kind
  local item
  local missing=''
  [ -f "$brewfile" ] || return 0
  while IFS=' ' read -r kind item <&3; do
    [ -n "$item" ] || continue
    if brew list "--${kind}" "$item" >/dev/null 2>&1; then
      continue
    fi
    if [ "$kind" = 'cask' ] && cask_artifact_exists "$item"; then
      warn "${item} is installed outside Homebrew and will be preserved"
    else
      missing="${missing}\n    ${item}"
    fi
  done 3<<EOF
$(awk -F'"' '/^brew / { print "formula " $2 } /^cask / { print "cask " $2 }' "$brewfile")
EOF
  if [ -z "$missing" ]; then
    success "$(basename "$brewfile") is satisfied"
  else
    warn "$(basename "$brewfile") has missing items"
    printf '%b\n' "$missing"
  fi
}

brew_bundle_install() {
  local brewfile="$1"
  local attempts=1
  local attempt=1
  shift

  if [ "$(basename "$brewfile")" = 'Brewfile.infra' ] && brew help trust >/dev/null 2>&1; then
    # Homebrew 6 requires explicit trust for formulae from third-party taps.
    # Trust only Terraform rather than every formula in HashiCorp's tap.
    run brew trust --formula hashicorp/tap/terraform
  fi
  if [ "${MACHINE_SETUP_CI:-0}" = '1' ]; then
    attempts=2
  fi
  while [ "$attempt" -le "$attempts" ]; do
    # Bundle already leaves successful installs in place, so a CI retry is both
    # cheap and useful for transient Homebrew download-cache races. Automatic
    # cleanup is unnecessary during an install and can race parallel downloads.
    if run env HOMEBREW_NO_INSTALL_CLEANUP=1 brew bundle install "$@" --file "$brewfile"; then
      return 0
    fi
    if [ "$attempt" -lt "$attempts" ]; then
      warn "Homebrew bundle failed; retrying $(basename "$brewfile") once."
    fi
    attempt=$((attempt + 1))
  done
  return 1
}

install_brewfile() {
  local brewfile="$1"
  [ -f "$brewfile" ] || return 0
  heading "Packages: $(basename "$brewfile")"
  if [ "$(basename "$brewfile")" = 'Brewfile.dev' ] &&
    brew list --formula bazel >/dev/null 2>&1 &&
    ! brew list --formula bazelisk >/dev/null 2>&1; then
    warn 'Homebrew Bazel is installed, but Bazelisk is the managed Bazel version selector.'
    if confirm 'Temporarily unlink Bazel so Bazelisk can provide the bazel command? (brew link bazel reverses this)'; then
      run brew unlink bazel
    else
      die 'Bazelisk cannot be installed while Homebrew Bazel is linked.'
    fi
  fi
  if [ "$(basename "$brewfile")" = 'Brewfile.desktop' ]; then
    install_desktop_casks "$brewfile"
  else
    brew_bundle_install "$brewfile" --no-upgrade
  fi
}

update_brewfile() {
  local brewfile="$1"
  [ -f "$brewfile" ] || return 0
  if [ "$(basename "$brewfile")" = 'Brewfile.desktop' ]; then
    update_desktop_casks "$brewfile"
  else
    brew_bundle_install "$brewfile"
  fi
}

for_profile_brewfiles() {
  printf '%s\n' "${SOURCE_DIR}/packages/Brewfile.core"
  if [ "$PROFILE_DEV" = '1' ] && [ "$MACHINE_SETUP_CORE_ONLY" = '0' ]; then
    printf '%s\n' "${SOURCE_DIR}/packages/Brewfile.dev"
  fi
  if [ "$PROFILE_INFRA" = '1' ] && [ "$MACHINE_SETUP_CORE_ONLY" = '0' ]; then
    printf '%s\n' "${SOURCE_DIR}/packages/Brewfile.infra"
  fi
  if [ "$PROFILE_DESKTOP" = '1' ] && [ "$MACHINE_SETUP_CORE_ONLY" = '0' ] && [ "$MACHINE_SETUP_SKIP_DESKTOP" = '0' ] && [ "$PROFILE_PLATFORM" = 'darwin' ]; then
    printf '%s\n' "${SOURCE_DIR}/packages/Brewfile.desktop"
  fi
  if [ "$PROFILE_LATEX" = '1' ] && [ "$MACHINE_SETUP_CORE_ONLY" = '0' ] && [ "$PROFILE_PLATFORM" = 'darwin' ]; then
    if activate_homebrew && brew list --cask mactex >/dev/null 2>&1; then
      warn 'MacTeX is installed and already satisfies the LaTeX requirement; preserving it instead of installing BasicTeX.'
    else
      printf '%s\n' "${SOURCE_DIR}/packages/Brewfile.latex"
    fi
  fi
}

package_plan() {
  local brewfile
  heading 'Packages'
  if [ "$PROFILE_NEEDS_ROOT" = '0' ]; then
    info 'No-root mode uses pinned user-local bootstrap tools and mise-managed runtimes.'
    return 0
  fi
  if ! activate_homebrew; then
    warn 'Homebrew is missing; apply will install it from a pinned, verified revision.'
    while IFS= read -r brewfile <&3; do
      [ -n "$brewfile" ] || continue
      printf '  %s\n' "$(basename "$brewfile")"
    done 3<<EOF
$(for_profile_brewfiles)
EOF
    return 0
  fi
  while IFS= read -r brewfile <&3; do
    brewfile_check "$brewfile"
  done 3<<EOF
$(for_profile_brewfiles)
EOF
}

install_profile_packages() {
  local brewfile
  if [ "$PROFILE_NEEDS_ROOT" = '0' ]; then
    return 0
  fi
  if is_macos; then
    ensure_xcode_tools
  elif [ "$PROFILE_PLATFORM" = 'ubuntu' ]; then
    ensure_ubuntu_prerequisites
  fi
  install_homebrew
  while IFS= read -r brewfile <&3; do
    [ -n "$brewfile" ] && install_brewfile "$brewfile"
  done 3<<EOF
$(for_profile_brewfiles)
EOF
}

update_profile_packages() {
  local brewfile
  [ "$PROFILE_NEEDS_ROOT" = '1' ] || die 'No-root profiles do not perform blanket upgrades. Re-run bootstrap after reviewing pinned versions.'
  activate_homebrew || die 'Homebrew is not installed. Run apply first.'
  run brew update
  while IFS= read -r brewfile <&3; do
    [ -n "$brewfile" ] && update_brewfile "$brewfile"
  done 3<<EOF
$(for_profile_brewfiles)
EOF
}
