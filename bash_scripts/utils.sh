#!/bin/bash

# Utility functions

# Determine whether a component of the setup should run
# Disable component by setting DISABLE_<COMPONENT>
# Alternatively, you can require that components be enabled 
# by setting ENABLE, and enabling with ENABLE_<COMPONENT>
should_run() {
  if [[ -n ${INTERACTIVE-} ]]; then
    read -p "Run component $1? (y/n): " CONFIRM
    [[ ${CONFIRM} == [yY] || ${CONFIRM} == [yY][eE][sS] ]]
  elif [[ -n ${ENABLE-} ]]; then
    ENABLE_VAR="ENABLE_$1"
    [[ -n ${!ENABLE_VAR-} ]]
  else
    DISABLE_VAR="DISABLE_$1"
    [[ -z ${!DISABLE_VAR-} ]]
  fi
}

# Determine whether an executable exists
exec_exists() {
  hash $1 2>/dev/null
}

# Determine whether a formula has been installed by brew
is_installed_with_brew() {
  brew list $1 >/dev/null 2>&1
}

# Install a formula with brew
brew_install() {
  FORMULA=$1
  NAME=$1
  CASK=""
  if [[ $# -gt 1 ]]; then
    NAME=$2
    if [[ $# -gt 2 ]]; then
      CASK=$3
    fi
  fi

  if is_installed_with_brew ${FORMULA}; then
    echo "-- ${NAME} is already installed"
    return
  fi

  echo "-- Installing ${NAME}..."

  if ! brew install ${CASK} ${FORMULA}; then
    brew install --build-from-source ${FORMULA} && brew link ${FORMULA}
  fi
  
  if [[ $? -eq 0 ]]; then
    echo "-- ${NAME} has been installed"
  else
    echo "-- ${NAME} could not be installed"
  fi
}

# Determine whether a package has been installed by pip
is_installed_with_pip() {
  python3 -m pip show $1 >/dev/null 2>&1
}

# Install a package with pip
pip_install() {
  PACKAGE=$1
  NAME=$1
  if [[ $# -gt 1 ]]; then
    NAME=$2
  fi

  if is_installed_with_pip ${PACKAGE}; then
    echo "-- ${NAME} is already installed"
    return
  fi

  echo "-- Installing ${NAME}..."

  python3 -m pip install ${PACKAGE}

  if [[ $? -eq 0 ]]; then
    echo "-- ${NAME} has been installed"
  else
    echo "-- ${NAME} could not be installed"
  fi
}

# Write a line to bash profile file
add_to_bash_profile() {
  COMMENT=$1
  TO_ADD=$2
  if test -r ~/.bash_profile; then
    BASH_PROFILE=~/.bash_profile
  else 
    BASH_PROFILE=~/.profile
  fi

  if ! grep "${COMMENT}" ${BASH_PROFILE} >/dev/null 2>&1; then
    echo "" >>${BASH_PROFILE}
    echo "${COMMENT}" >>${BASH_PROFILE}
    echo "${TO_ADD}" >>${BASH_PROFILE}
  fi
}

# Write a line to bashrc file
add_to_bashrc() {
  COMMENT=$1
  TO_ADD=$2
  if ! grep "${COMMENT}" ~/.bashrc >/dev/null 2>&1; then
    echo "" >>~/.bashrc
    echo "${COMMENT}" >>~/.bashrc
    echo "${TO_ADD}" >>~/.bashrc
  fi
}
