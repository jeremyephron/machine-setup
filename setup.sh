#!/bin/bash
set -u # treat unset variables as error

# Variables
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BASH_SCRIPTS_DIR="${SOURCE_DIR}/bash_scripts"
RESOUCES_DIR="${SOURCE_DIR}/resources"

# Check if the OS is Linux
if [[ "$(uname)" = "Linux" ]]; then
  SETUP_ON_LINUX=1
fi

# Load other files
source "${BASH_SCRIPTS_DIR}/utils.sh"

if should_run HOMEBREW; then
  source "${BASH_SCRIPTS_DIR}/homebrew.sh"
fi

if should_run VIM; then
  source "${BASH_SCRIPTS_DIR}/vim.sh"
fi

