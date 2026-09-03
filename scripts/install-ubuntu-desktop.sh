#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"
# shellcheck source=lib/versions.sh
. "${SOURCE_DIR}/lib/versions.sh"

# shellcheck disable=SC1091
. /etc/os-release
[ "${ID:-}" = 'ubuntu' ] || die 'The desktop installer supports Ubuntu only.'

sudo_run_local() {
  if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

heading 'Ubuntu desktop applications'
sudo_run_local apt-get install -y snapd xclip

ubuntu_major="${VERSION_ID%%.*}"
if [ "$ubuntu_major" -ge 26 ]; then
  sudo_run_local apt-get install -y ghostty
elif ! snap list ghostty >/dev/null 2>&1; then
  sudo_run_local snap install ghostty --classic
fi

for snap_app in slack spotify; do
  if ! snap list "$snap_app" >/dev/null 2>&1; then
    sudo_run_local snap install "$snap_app"
  fi
done

if ! command -v google-chrome >/dev/null 2>&1; then
  chrome_arch="$(dpkg --print-architecture)"
  chrome_key="$(mktemp "${TMPDIR:-/tmp}/google-chrome-key.XXXXXX")"
  curl --fail --location --proto '=https' --tlsv1.2 --silent --show-error \
    https://dl.google.com/linux/linux_signing_key.pub -o "$chrome_key"
  gpg --dearmor --batch --yes --output "${chrome_key}.gpg" "$chrome_key"
  sudo_run_local install -m 0644 "${chrome_key}.gpg" /usr/share/keyrings/google-chrome.gpg
  printf 'deb [arch=%s signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main\n' \
    "$chrome_arch" | sudo_run_local tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
  rm -f "$chrome_key" "${chrome_key}.gpg"
  sudo_run_local apt-get update
  sudo_run_local apt-get install -y google-chrome-stable
fi

if [ "$(dpkg --print-architecture)" = 'amd64' ] && ! dpkg-query -W signal-desktop >/dev/null 2>&1; then
  signal_key="$(mktemp "${TMPDIR:-/tmp}/signal-key.XXXXXX")"
  signal_sources="$(mktemp "${TMPDIR:-/tmp}/signal-sources.XXXXXX")"
  curl --fail --location --proto '=https' --tlsv1.2 --silent --show-error \
    https://updates.signal.org/desktop/apt/keys.asc -o "$signal_key"
  gpg --dearmor --yes --output "${signal_key}.gpg" "$signal_key"
  curl --fail --location --proto '=https' --tlsv1.2 --silent --show-error \
    https://updates.signal.org/static/desktop/apt/signal-desktop.sources -o "$signal_sources"
  sudo_run_local install -m 0644 "${signal_key}.gpg" /usr/share/keyrings/signal-desktop-keyring.gpg
  sudo_run_local install -m 0644 "$signal_sources" /etc/apt/sources.list.d/signal-desktop.sources
  rm -f "$signal_key" "${signal_key}.gpg" "$signal_sources"
  sudo_run_local apt-get update
  sudo_run_local apt-get install -y signal-desktop
fi

heading 'Obsidian'
desktop_arch="$(dpkg --print-architecture)"
if [ "$desktop_arch" = 'amd64' ]; then
  # shellcheck disable=SC2016
  installed_obsidian="$(dpkg-query -W -f='${Version}' obsidian 2>/dev/null || true)"
  if [ "$installed_obsidian" != "$OBSIDIAN_VERSION" ]; then
    obsidian_package="$(mktemp "${TMPDIR:-/tmp}/obsidian.XXXXXX.deb")"
    download_verified \
      "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/obsidian_${OBSIDIAN_VERSION}_amd64.deb" \
      "$OBSIDIAN_SHA256_LINUX_AMD64" "$obsidian_package"
    sudo_run_local apt-get install -y "$obsidian_package"
    rm -f "$obsidian_package"
  fi
else
  obsidian_dir="${HOME}/.local/opt/obsidian"
  ensure_dir "$obsidian_dir"
  obsidian_image="${obsidian_dir}/Obsidian-${OBSIDIAN_VERSION}-arm64.AppImage"
  if [ ! -f "$obsidian_image" ]; then
    download_verified \
      "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/Obsidian-${OBSIDIAN_VERSION}-arm64.AppImage" \
      "$OBSIDIAN_SHA256_LINUX_ARM64" "$obsidian_image"
    chmod 0755 "$obsidian_image"
  fi
  ln -sfn "$obsidian_image" "${obsidian_dir}/Obsidian.AppImage"
fi

heading 'Zotero'
case "$desktop_arch" in
  amd64)
    zotero_arch='x86_64'
    zotero_sha="$ZOTERO_SHA256_LINUX_AMD64"
    ;;
  arm64)
    zotero_arch='arm64'
    zotero_sha="$ZOTERO_SHA256_LINUX_ARM64"
    ;;
  *) die "Zotero is not pinned for ${desktop_arch}." ;;
esac
zotero_root="${HOME}/.local/opt"
zotero_target="${zotero_root}/zotero-${ZOTERO_VERSION}"
if [ ! -d "$zotero_target" ]; then
  zotero_archive="$(mktemp "${TMPDIR:-/tmp}/zotero.XXXXXX.tar.xz")"
  zotero_extract="$(mktemp -d "${TMPDIR:-/tmp}/zotero-extract.XXXXXX")"
  download_verified \
    "https://download.zotero.org/client/release/${ZOTERO_VERSION}/Zotero-${ZOTERO_VERSION}_linux-${zotero_arch}.tar.xz" \
    "$zotero_sha" "$zotero_archive"
  tar -xJf "$zotero_archive" -C "$zotero_extract"
  ensure_dir "$zotero_root"
  mv "${zotero_extract}/Zotero_linux-${zotero_arch}" "$zotero_target"
  rm -f "$zotero_archive"
  rmdir "$zotero_extract"
fi
ln -sfn "$zotero_target" "${zotero_root}/zotero"
ensure_dir "$HOME/.local/bin"
ln -sfn "${zotero_root}/zotero/zotero" "$HOME/.local/bin/zotero"
(
  cd "$zotero_target"
  ./set_launcher_icon
)
ensure_dir "$HOME/.local/share/applications"
ln -sfn "${zotero_root}/zotero/zotero.desktop" "$HOME/.local/share/applications/zotero.desktop"

warn 'WhatsApp, TickTick, and Office use the managed Chrome launchers on Ubuntu.'
