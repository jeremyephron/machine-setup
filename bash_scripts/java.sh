#!/bin/bash
# WARNING: This file is not meant to be run directly.

################
#     Java     #
################

# Java Runtime Environment

brew_install openjdk Java

if [[ -n ${SETUP_ON_LINUX} ]]; then
  add_to_bash_profile '# Add java to path' 'export PATH=$PATH:$HOMEBREW_PREFIX/opt/openjdk/bin/'
fi
