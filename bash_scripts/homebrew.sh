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
  /bin/bash -c "$(curl -fsSL ${HOMEBREW_INSTALL_URL})"

  # Add Homebrew to path
  test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
  test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

  echo "-- Homebrew has been installed"
}

install_homebrew
add_to_bash_profile "# Add homebrew to environment" "eval \$($(brew --prefix)/bin/brew shellenv)"
