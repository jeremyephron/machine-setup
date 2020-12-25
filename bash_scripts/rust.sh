#!/bin/bash
# WARNING: This file is not meant to be run directly.

################
#     Rust     #
################

# Rust language

brew_install rustup
echo "1" | rustup-init
source $HOME/.cargo/env
