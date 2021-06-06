#!/bin/bash
set -u # treat unset variables as error

if [ $# -gt 0 ] && ([ "$1" == "?" ] || [ "$1" == "--help" ]); then
  msg="Components:\n"
  msg+="  - BASH_MISC\n"
  msg+="  - HOMEBREW\n"
  msg+="  - GCC\n"
  msg+="  - GIT\n"
  msg+="  - NVIM\n"
  msg+="  - VIM\n"
  msg+="  - FZF\n"
  msg+="  - NNN\n"
  msg+="  - TREE\n"
  msg+="  - LATEX\n"
  msg+="  - PYTHON\n"
  msg+="  - NODEJS\n"
  msg+="  - RUST\n"
  msg+="  - JAVA\n"

  printf "${msg}"
  exit 0
fi

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

if should_run BASH_MISC; then
  source "${BASH_SCRIPTS_DIR}/bash_misc.sh"
fi

if should_run HOMEBREW; then
  source "${BASH_SCRIPTS_DIR}/homebrew.sh"
fi

if should_run GCC; then
  source "${BASH_SCRIPTS_DIR}/gcc.sh"
fi

if should_run NVIM; then
  source "${BASH_SCRIPTS_DIR}/nvim.sh"
fi

if should_run VIM; then
  source "${BASH_SCRIPTS_DIR}/vim.sh"
fi

if should_run FZF; then
  source "${BASH_SCRIPTS_DIR}/fzf.sh"
fi

if should_run TREE; then
  source "${BASH_SCRIPTS_DIR}/tree.sh"
fi

if should_run GIT; then
  source "${BASH_SCRIPTS_DIR}/git.sh"
fi

if should_run NNN; then
  source "${BASH_SCRIPTS_DIR}/nnn.sh"
fi

if should_run LATEX; then
  source "${BASH_SCRIPTS_DIR}/latex.sh"
fi

if should_run PYTHON; then
  source "${BASH_SCRIPTS_DIR}/python.sh"
fi

if should_run NODEJS; then
  source "${BASH_SCRIPTS_DIR}/nodejs.sh"
fi

if should_run JAVA; then
  source "${BASH_SCRIPTS_DIR}/java.sh"
fi

if should_run RUST; then
  source "${BASH_SCRIPTS_DIR}/rust.sh"
fi

if should_run BOOST; then
  source "${BASH_SCRIPTS_DIR}/boost.sh"
fi

if should_run PYTHON_PACKAGES; then
  source "${BASH_SCRIPTS_DIR}/python_packages.sh"
fi
