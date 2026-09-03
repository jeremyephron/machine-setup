#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"
# shellcheck source=lib/packages.sh
. "${SOURCE_DIR}/lib/packages.sh"

# Destructive cleanup always asks for each exact target. `--yes` only applies
# to the non-destructive apply workflow.
MACHINE_SETUP_ASSUME_YES=0
backup_root="$(machine_setup_state_dir)/backups/$(date +%Y%m%d-%H%M%S)"

move_to_backup() {
  local target="$1"
  local label="$2"
  local backup_name="${3:-$(basename "$target")}"
  [ -e "$target" ] || return 0
  printf '\nCandidate: %s\nAction: move to recoverable backup under %s\n' "$target" "$backup_root"
  if confirm "Back up and remove ${label} from its active location?"; then
    ensure_dir "$backup_root"
    mv "$target" "${backup_root}/${backup_name}"
    success "Moved ${target} to ${backup_root}."
  else
    info "Kept ${target}."
  fi
}

heading 'Legacy cleanup preview'
printf '%s\n' \
  'Nothing below is required for the new setup to run.' \
  'Every material removal has its own confirmation, even when --yes was used.'

if activate_homebrew; then
  if brew list --formula pyenv >/dev/null 2>&1; then
    printf '\nCandidate: Homebrew pyenv and ~/.pyenv\nReplacement: mise-managed Python plus the isolated scratch environment\n'
    if have mise && mise which python >/dev/null 2>&1 && [ -x "$HOME/.local/share/machine-setup/python-scratch/bin/python" ]; then
      if confirm 'Uninstall the pyenv formula now?'; then
        brew uninstall pyenv
        move_to_backup "$HOME/.pyenv" 'the pyenv data directory'
      else
        info 'Kept pyenv and its data directory.'
      fi
    else
      warn 'mise Python and the scratch environment are not both healthy; pyenv will not be touched.'
    fi
  fi

  if brew list --cask mactex >/dev/null 2>&1; then
    printf '\nCandidate: full MacTeX\nReplacement: BasicTeX plus latexmk and recommended fonts/packages\n'
    if confirm 'Replace full MacTeX with BasicTeX now?'; then
      brew uninstall --cask mactex
      brew install --cask basictex
      eval "$(/usr/libexec/path_helper)"
      sudo tlmgr install latexmk collection-latexrecommended collection-fontsrecommended
    fi
  fi

  heading 'Unselected Homebrew inventory'
  info 'This inventory is for review only; packages are never bulk-uninstalled.'
  printf 'Formula leaves:\n'
  brew leaves | sed 's/^/  /'
  printf 'Casks:\n'
  brew list --cask | sed 's/^/  /'
fi

move_to_backup "$HOME/.local/share/nvim/plugged" 'the legacy Neovim vim-plug directory' 'nvim-vim-plug'
move_to_backup "$HOME/.vim/plugged" 'the legacy Vim vim-plug directory' 'vim-vim-plug'

if [ "$(uname -s)" = 'Darwin' ]; then
  java_plugin='/Library/Internet Plug-Ins/JavaAppletPlugin.plugin'
  java_pane='/Library/PreferencePanes/JavaControlPanel.prefPane'
  if [ -e "$java_plugin" ] || [ -e "$java_pane" ]; then
    printf '\nCandidates:\n  %s\n  %s\nReplacement: mise-managed current LTS JDK\n' "$java_plugin" "$java_pane"
    if confirm 'Remove the obsolete Oracle Java 8 browser plugin and preference pane?'; then
      [ ! -e "$java_plugin" ] || sudo rm -rf -- "$java_plugin"
      [ ! -e "$java_pane" ] || sudo rm -rf -- "$java_pane"
      success 'Removed the obsolete Oracle Java UI components.'
    fi
  fi
fi

heading 'Folder migration'
company_folder="$(company_workspace_folder)"
cat <<EOF
The target structure is:
  $HOME/src/personal
  $HOME/src/work
  $HOME/src/$company_folder
  $HOME/src/scratch

Existing repositories are not guessed or moved automatically. Use
docs/existing-machines.md to classify each repository.
EOF

if [ -d "$backup_root" ]; then
  warn "Recoverable cleanup backups are in ${backup_root}."
fi
