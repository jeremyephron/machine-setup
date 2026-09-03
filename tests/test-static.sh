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

if rg -n --hidden --glob '!.git/**' --glob '!tests/**' \
  '(BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,})' "$SOURCE_DIR"; then
  printf 'Potential secret material found.\n' >&2
  exit 1
fi

printf 'static tests passed\n'
