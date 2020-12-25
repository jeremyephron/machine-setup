#!/bin/bash
# WARNING: This file is not meant to be run directly.

#################
#     LaTeX     #
#################

# Typesetting

if [[ -n ${SETUP_ON_LINUX} ]]; then
  brew_install texlive LaTeX
else
  brew_install mactex LaTeX --cask
fi
