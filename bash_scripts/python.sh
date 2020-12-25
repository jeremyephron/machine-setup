#!/bin/bash
# WARNING: This file is not meant to be run directly.

##################
#     Python     #
##################

# Python  and environment related packages

brew_install python "Python"
brew_install pyenv

add_to_bash_profile '# Add pyenv to environment' 'eval "$(pyenv init -)"'
