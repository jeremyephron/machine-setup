#!/bin/bash
# WARNING: This file is not meant to be run directly.

####################
#     Homebrew     #
####################

# Homebrew is a wonderful package manager and the first thing I would install 
# on any machine.

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

install_homebrew
