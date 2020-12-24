#!/bin/bash
set -u # treat unset variables as error

# Load other files
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${SOURCE_DIR}/bash_scripts/utils.sh"

# Check if the OS is Linux
if [[ "$(uname)" = "Linux" ]]; then
  SETUP_ON_LINUX=1
fi

####################
#     Homebrew     #
####################

# Homebrew is a wonderful package manager, and the first thing I would install on any machine

install_homebrew() {
  if exec_exists brew; then
    echo "-- Homebrew is already installed"
    return
  fi

  echo "-- Installing Homebrew..."

  HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL ${HOMEBREW_INSTALL_URL})"

  # Add Homebrew to path and profile script
  test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
  test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
  test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
  test -r ~/.profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile

  echo "-- Homebrew has been installed"
}

if should_run HOMEBREW; then
  install_homebrew
fi

###############
#     Vim     #
###############

# Vim is my goto editor

install_vim() {
  if is_installed_with_brew vim; then
    echo "-- Vim is already installed"
    return
  fi

  echo "-- Installing Vim"

  # Install the latest version of Vim with Homebrew
  brew install vim

  echo "-- Vim has been installed"
}

if should_run VIM; then
  install_vim
fi
