#!/bin/bash
set -u # treat unset variables as error

ENABLE=1 \
  ENABLE_BASH_MISC=1 \
  ENABLE_HOMEBREW=1 \
  ENABLE_GCC=1 \
  ENABLE_GIT=1 \
  ENABLE_PYTHON=1 \
  ENABLE_NVIM=1 \
  ENABLE_FZF=1 \
  ENABLE_NNN=1 \
  ./setup.sh
