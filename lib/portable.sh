#!/usr/bin/env bash

portable_asset_details() {
  local tool="$1"
  local os
  local arch
  os="$(uname -s)"
  arch="$(cpu_arch)"

  case "${tool}:${os}:${arch}" in
    chezmoi:Darwin:arm64)
      PORTABLE_URL="https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_darwin_arm64.tar.gz"
      PORTABLE_SHA="$CHEZMOI_SHA256_DARWIN_ARM64"
      ;;
    chezmoi:Linux:amd64)
      PORTABLE_URL="https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz"
      PORTABLE_SHA="$CHEZMOI_SHA256_LINUX_AMD64"
      ;;
    chezmoi:Linux:arm64)
      PORTABLE_URL="https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_arm64.tar.gz"
      PORTABLE_SHA="$CHEZMOI_SHA256_LINUX_ARM64"
      ;;
    mise:Darwin:arm64)
      PORTABLE_URL="https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-macos-arm64"
      PORTABLE_SHA="$MISE_SHA256_DARWIN_ARM64"
      ;;
    mise:Linux:amd64)
      PORTABLE_URL="https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-x64"
      PORTABLE_SHA="$MISE_SHA256_LINUX_AMD64"
      ;;
    mise:Linux:arm64)
      PORTABLE_URL="https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-arm64"
      PORTABLE_SHA="$MISE_SHA256_LINUX_ARM64"
      ;;
    *) die "No pinned ${tool} build for ${os}/${arch}." ;;
  esac
}

install_portable_chezmoi() {
  local archive
  local extract_dir
  local bin_dir="${HOME}/.local/bin"

  portable_asset_details chezmoi
  archive="$(mktemp "${TMPDIR:-/tmp}/machine-setup-chezmoi.XXXXXX")"
  extract_dir="$(mktemp -d "${TMPDIR:-/tmp}/machine-setup-chezmoi-dir.XXXXXX")"
  download_verified "$PORTABLE_URL" "$PORTABLE_SHA" "$archive"
  if [ "$MACHINE_SETUP_DRY_RUN" = '0' ]; then
    tar -xzf "$archive" -C "$extract_dir" chezmoi
    ensure_dir "$bin_dir"
    install -m 0755 "${extract_dir}/chezmoi" "${bin_dir}/chezmoi"
    rm -f "$archive"
    rm -rf "$extract_dir"
    path_prepend "$bin_dir"
  fi
}

install_portable_mise() {
  local download
  local bin_dir="${HOME}/.local/bin"

  portable_asset_details mise
  download="$(mktemp "${TMPDIR:-/tmp}/machine-setup-mise.XXXXXX")"
  download_verified "$PORTABLE_URL" "$PORTABLE_SHA" "$download"
  if [ "$MACHINE_SETUP_DRY_RUN" = '0' ]; then
    ensure_dir "$bin_dir"
    install -m 0755 "$download" "${bin_dir}/mise"
    rm -f "$download"
    path_prepend "$bin_dir"
  fi
}

ensure_portable_bootstrap_tools() {
  activate_homebrew || true
  path_prepend "${HOME}/.local/bin"
  have chezmoi || install_portable_chezmoi
  have mise || install_portable_mise
}
