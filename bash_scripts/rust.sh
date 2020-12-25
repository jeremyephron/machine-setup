#!/bin/bash
# WARNING: This file is not meant to be run directly.

################
#     Rust     #
################

# Rust language

brew_install rustup
if exec_exists rustc && exec_exists cargo; then
  echo "-- Rust is already installed"
else
  echo "-- Installing Rust..."

  echo "1" | rustup-init
  source $HOME/.cargo/env

  echo "-- Rust has been installed"
fi
