#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"

[ "$(uname -s)" = 'Linux' ] || die 'Linux services can only be installed on Linux.'
# shellcheck disable=SC1091
. /etc/os-release
[ "${ID:-}" = 'ubuntu' ] || die 'The service installer currently supports Ubuntu only.'

sudo_run_local() {
  if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

heading 'Docker Engine'
sudo_run_local install -m 0755 -d /etc/apt/keyrings
docker_key="$(mktemp "${TMPDIR:-/tmp}/docker-key.XXXXXX")"
curl --fail --location --proto '=https' --tlsv1.2 --silent --show-error \
  https://download.docker.com/linux/ubuntu/gpg -o "$docker_key"
sudo_run_local install -m 0644 "$docker_key" /etc/apt/keyrings/docker.asc
rm -f "$docker_key"
docker_arch="$(dpkg --print-architecture)"
docker_codename="${UBUNTU_CODENAME:-${VERSION_CODENAME}}"
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu %s stable\n' \
  "$docker_arch" "$docker_codename" | sudo_run_local tee /etc/apt/sources.list.d/docker.list >/dev/null

heading 'Tailscale and VPN'
tailscale_key="$(mktemp "${TMPDIR:-/tmp}/tailscale-key.XXXXXX")"
tailscale_list="$(mktemp "${TMPDIR:-/tmp}/tailscale-list.XXXXXX")"
curl --fail --location --proto '=https' --tlsv1.2 --silent --show-error \
  "https://pkgs.tailscale.com/stable/ubuntu/${docker_codename}.noarmor.gpg" -o "$tailscale_key"
curl --fail --location --proto '=https' --tlsv1.2 --silent --show-error \
  "https://pkgs.tailscale.com/stable/ubuntu/${docker_codename}.tailscale-keyring.list" -o "$tailscale_list"
sudo_run_local install -m 0644 "$tailscale_key" /usr/share/keyrings/tailscale-archive-keyring.gpg
sudo_run_local install -m 0644 "$tailscale_list" /etc/apt/sources.list.d/tailscale.list
rm -f "$tailscale_key" "$tailscale_list"

sudo_run_local apt-get update
sudo_run_local env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  containerd.io docker-buildx-plugin docker-ce docker-ce-cli docker-compose-plugin openvpn tailscale
sudo_run_local systemctl enable --now docker
sudo_run_local systemctl enable --now tailscaled

if [ "$(id -u)" -ne 0 ] && ! id -nG "$USER" | tr ' ' '\n' | grep -Fxq docker; then
  sudo_run_local usermod -aG docker "$USER"
  warn 'Log out and back in before using Docker without sudo.'
fi
warn "Run 'sudo tailscale up' when you are ready to authenticate this machine."
