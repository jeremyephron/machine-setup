#!/bin/bash
# WARNING: This file is not meant to be run directly.

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

configure_vim() {
  echo "-- Configuring Vim (will not overwrite existing ~/.vimrc or ~/.vim/)..."

  cp -n "${RESOUCES_DIR}/vim/.vimrc" ~/.vimrc
  cp -nr "${RESOUCES_DIR}/vim/.vim" ~/.vim

  echo "-- Vim has been configured"
}

install_vim
configure_vim
