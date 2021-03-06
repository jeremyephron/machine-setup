#!/bin/bash
# WARNING: This file is not meant to be run directly.

###############
#     nnn     #
###############

# Terminal file manager

configure_nnn() {
  echo "-- Configuring nnn..."

  # Install nnn plugins
  curl -Ls "https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs" | sh

  add_to_bash_profile '# nnn settings' \
'export NNN_PLUG="o:fzopen"
export NNN_FCOLORS="0000E6310000000000000000"
export NNN_FIFO="/tmp/nnn.fifo"'

  add_to_bashrc '# nnn alias' \
'n() {
  # Block nesting of nnn in subshells
  if [ -n $NNNLVL ] && [ "${NNNLVL:-0}" -ge 1 ]; then
    echo "nnn is already running"
    return
  fi

  # The default behaviour is to cd on quit (nnn checks if NNN_TMPFILE is set)
  # To cd on quit only on ^G, remove the "export" as in:
  #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
  # NOTE: NNN_TMPFILE is fixed, should not be modified
  NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

  # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
  # stty start undef
  # stty stop undef
  # stty lwrap undef
  # stty lnext undef

  nnn -e "$@"

  if [ -f "$NNN_TMPFILE" ]; then
    . "$NNN_TMPFILE"
    rm -f "$NNN_TMPFILE" > /dev/null
  fi
}'

  echo "-- nnn has been configured"
}

brew_install nnn
configure_nnn
