#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

while IFS= read -r script; do
  bash -n "$script"
done <<EOF
$(find "$SOURCE_DIR" -path "$SOURCE_DIR/.git" -prune -o -type f -name '*.sh' -print)
EOF
bash -n "$SOURCE_DIR/home/dot_bash_profile" "$SOURCE_DIR/home/dot_bashrc"
grep -Fq 'BASH_SILENCE_DEPRECATION_WARNING=1' "$SOURCE_DIR/home/dot_bash_profile"
grep -Fq "chezmoi --source \"\$SOURCE_DIR\" apply --force --no-tty" "$SOURCE_DIR/setup.sh"
grep -Fq '{ "folke/lazy.nvim", branch = "main" }' "$SOURCE_DIR/home/dot_config/nvim/lua/machine_setup/plugins.lua"
grep -Fq 'rocks = { enabled = false }' "$SOURCE_DIR/home/dot_config/nvim/lua/machine_setup/lazy.lua"
grep -Fq 'vim.g.loaded_python3_provider = 0' "$SOURCE_DIR/home/dot_config/nvim/init.lua"
grep -Fq 'brew "tree-sitter-cli"' "$SOURCE_DIR/packages/Brewfile.core"
grep -Fq 'HOMEBREW_NO_INSTALL_CLEANUP=1 brew bundle install' "$SOURCE_DIR/lib/packages.sh"
grep -Fq 'brew trust --formula hashicorp/tap/terraform' "$SOURCE_DIR/lib/packages.sh"
grep -Fq 'ensure_texlive_recommended_packages' "$SOURCE_DIR/scripts/cleanup-legacy.sh"
grep -Fq 'ensure_texlive_recommended_packages' "$SOURCE_DIR/scripts/install-runtimes.sh"
grep -Fq "heading 'LaTeX'" "$SOURCE_DIR/scripts/doctor.sh"
grep -Fq 'retire_legacy_nvim_init' "$SOURCE_DIR/setup.sh"
grep -Fq 'nvim-init.vim' "$SOURCE_DIR/setup.sh"
grep -Fq 'nvim/mason/bin' "$SOURCE_DIR/scripts/doctor.sh"
grep -Fq '/Applications/Utilities/XQuartz.app' "$SOURCE_DIR/scripts/doctor.sh"
grep -Fq "'+Lazy! restore'" "$SOURCE_DIR/scripts/install-editor.sh"
grep -Fq "'+Lazy! restore'" "$SOURCE_DIR/setup.sh"
grep -Fq 'missing first-use Telescope mapping: ,ff' "$SOURCE_DIR/scripts/install-editor.sh"
grep -Fq 'missing first-use Telescope mapping: ,ff' "$SOURCE_DIR/setup.sh"
grep -Fq 'basedpyright lacks definition support' "$SOURCE_DIR/scripts/install-editor.sh"
grep -Fq 'basedpyright lacks references support' "$SOURCE_DIR/scripts/install-editor.sh"
if grep -RFn 'Lazy! sync' "$SOURCE_DIR/setup.sh" "$SOURCE_DIR/scripts"; then
  printf 'Normal apply must not upgrade Neovim plugins.\n' >&2
  exit 1
fi
grep -Fq 'cquit 1' "$SOURCE_DIR/setup.sh"
grep -Fq 'cquit 1' "$SOURCE_DIR/scripts/install-editor.sh"

for document in "$SOURCE_DIR/README.md" "$SOURCE_DIR"/docs/*.md; do
  while IFS= read -r link; do
    case "$link" in
      http://* | https://* | mailto:* | \#* | '') continue ;;
    esac
    target="${link%%#*}"
    if [ ! -e "$(dirname "$document")/$target" ]; then
      printf 'Broken local Markdown link in %s: %s\n' "$document" "$link" >&2
      exit 1
    fi
  done < <(grep -Eo ']\([^)]+\)' "$document" | sed -e 's/^](//' -e 's/)$//')
done

if command -v shellcheck >/dev/null 2>&1; then
  # The linter does not understand chezmoi directives embedded in shell templates.
  shellcheck "$SOURCE_DIR/setup.sh" "$SOURCE_DIR"/lib/*.sh "$SOURCE_DIR"/scripts/*.sh "$SOURCE_DIR"/tests/*.sh \
    "$SOURCE_DIR/home/dot_bash_profile" "$SOURCE_DIR/home/dot_bashrc"
fi

if command -v shfmt >/dev/null 2>&1; then
  shfmt -d -i 2 -ci "$SOURCE_DIR/setup.sh" "$SOURCE_DIR/lib" "$SOURCE_DIR/scripts" "$SOURCE_DIR/tests"
fi

git -C "$SOURCE_DIR" diff --check

if grep -REn --exclude-dir=.git --exclude-dir=tests --binary-files=without-match \
  '(BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,})' "$SOURCE_DIR"; then
  printf 'Potential secret material found.\n' >&2
  exit 1
fi

printf 'static tests passed\n'
