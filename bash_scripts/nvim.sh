#!/bin/bash
# WARNING: This file is not meant to be run directly.

##################
#     Neovim     #
##################

# Neovim is my go-to editor

configure_nvim() {
  echo "-- Configuring Neovim (will not overwrite existing ~/.config/nvim/)..."

  mkdir -p "$HOME/.config/"
  cp -nr "${RESOUCES_DIR}/nvim/" "$HOME/.config/"

  echo "-- Neovim has been configured"
}

brew_install nvim Neovim --HEAD
configure_nvim

# TODO: fix these dependencies
brew install ripgrep
npm i -g bash-language-server
