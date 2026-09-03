#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"

path_prepend "${HOME}/.local/bin"
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

have uv || die 'uv is required for the Python scratch environment.'
have mise || die 'mise is required for the Python scratch environment.'

environment="${HOME}/.local/share/machine-setup/python-scratch"
heading 'Python scratch environment'
UV_PROJECT_ENVIRONMENT="$environment" uv sync \
  --locked \
  --project "${SOURCE_DIR}/python-scratch" \
  --python "$(mise which python)"
success "Use 'ipy' or 'pyscratch' for the global scientific REPL."
