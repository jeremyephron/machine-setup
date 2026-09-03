#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"
# shellcheck source=lib/packages.sh
. "${SOURCE_DIR}/lib/packages.sh"

activate_homebrew || true
path_prepend "${HOME}/.local/bin"
if have brew && rustup_prefix="$(brew --prefix rustup 2>/dev/null)" && [ -d "$rustup_prefix/bin" ]; then
  path_prepend "$rustup_prefix/bin"
fi

heading 'Language runtimes'
if have mise; then
  mise install --locked --yes
  mise reshim
else
  die 'mise is missing after package setup.'
fi

if have rustup; then
  if ! rustup toolchain list | grep -q '^stable'; then
    rustup toolchain install stable --profile default
  fi
  rustup default stable
fi

if have git-lfs; then
  git lfs install --skip-repo
fi

"${SOURCE_DIR}/scripts/install-editor.sh" --development

if [ "$(uname -s)" = 'Darwin' ]; then
  # BasicTeX updates /etc/paths.d, which does not affect this already-running
  # setup process until path_helper is evaluated again.
  eval "$(/usr/libexec/path_helper)"
  if have tlmgr; then
    heading 'LaTeX tools'
    ensure_texlive_recommended_packages
  fi
fi
