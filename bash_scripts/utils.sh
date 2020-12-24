#!/bin/bash

# Utility functions

# Determine whether a component of the setup should run
# Disable component by setting DISABLE_<COMPONENT>
# Alternatively, you can require that components be enabled 
# by setting ENABLE, and enabling with ENABLE_<COMPONENT>
should_run() {
  if [[ -n ${ENABLE-} ]]; then
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
