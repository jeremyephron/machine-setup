#!/bin/bash
# WARNING: This file is not meant to be run directly.

###############
#     Vim     #
###############

# Vim is my goto editor

configure_vim() {
  echo "-- Configuring Vim (will not overwrite existing ~/.vimrc or ~/.vim/)..."

  cp -n "${RESOUCES_DIR}/vim/.vimrc" ~/.vimrc
  cp -nr "${RESOUCES_DIR}/vim/.vim" ~/.vim

  echo "-- Vim has been configured"
}

brew_install vim Vim
configure_vim
