#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"

have mise || die 'mise is required to refresh its lockfile.'
heading 'Pinned runtime and no-root tool versions'
MISE_CONFIG_FILE="${SOURCE_DIR}/lockfiles/mise.toml" \
  mise lock --global --bump --platform linux-x64,linux-arm64,macos-arm64 --yes
generated="${SOURCE_DIR}/lockfiles/mise.lock"
[ -f "$generated" ] || die "mise did not create ${generated}."
cp "$generated" "${SOURCE_DIR}/home/dot_config/mise/mise.lock"
rm -f "$generated"
success 'Refreshed the cross-platform mise lockfile; review it before committing.'
