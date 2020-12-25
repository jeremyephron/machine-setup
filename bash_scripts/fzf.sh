#!/bin/bash
# WARNING: This file is not meant to be run directly.

###############
#     FZF     #
###############

# FZF is a fantastic fuzzy file searcher.
# https://github.com/junegunn/fzf

configure_fzf() {
  echo "-- Configuring FZF..."

  # Say yes to fuzzy completion, key bindings, and updating .bashrc
  printf "y\ny\ny\n" | ${HOMEBREW_PREFIX}/opt/fzf/install

  echo "-- FZF has been configured" 
}

brew_install fzf FZF
configure_fzf
