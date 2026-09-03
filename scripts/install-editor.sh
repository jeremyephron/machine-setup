#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"
# shellcheck source=lib/packages.sh
. "${SOURCE_DIR}/lib/packages.sh"

development=0
[ "${1:-}" != '--development' ] || development=1
nvim_error_guard='+if v:errmsg != "" | cquit 1 | endif'

activate_homebrew || true
path_prepend "${HOME}/.local/bin"
have nvim || die 'Neovim is missing after package setup.'

nvim_version="$(nvim --version | sed -n '1s/^NVIM v//p')"
if ! version_at_least "$nvim_version" '0.11.3'; then
  if activate_homebrew; then
    warn "Neovim ${nvim_version} is too old for the managed configuration; this required dependency will be upgraded."
    brew upgrade neovim
  else
    die 'Neovim 0.11.3 or newer is required.'
  fi
fi

heading 'Neovim plugins'
nvim --headless '+Lazy! sync' \
  '+lua local missing = {}; for name, plugin in pairs(require("lazy.core.config").plugins) do if plugin._.installed ~= true then table.insert(missing, name) end end; assert(#missing == 0, "missing plugins: " .. table.concat(missing, ", "))' \
  "$nvim_error_guard" \
  +qa
if [ "$development" = '1' ]; then
  heading 'Neovim language tools'
  nvim --headless '+MasonToolsInstallSync' "$nvim_error_guard" +qa || warn 'Some editor language tools will finish installing when Neovim next opens.'
fi
