#!/bin/bash
# WARNING: This file is not meant to be run directly.

#####################################
#     Miscellaneous Bash Things     #
#####################################

echo "-- Adding miscellaneous bash things..."

add_to_bash_profile '# Shell prompt' 'if test -t 1 && [ ! -z $TERM ] && [ ! $TERM == "dumb" ]; then

    # ANSI escape colors
    black=$(tput setaf 0)
    red=$(tput setaf 1)
    green=$(tput setaf 2)
    yellow=$(tput setaf 3)
    blue=$(tput setaf 4)
    magenta=$(tput setaf 5)
    cyan=$(tput setaf 6)
    white=$(tput setaf 7)
    reset=$(tput sgr0)

    # Custom prompt
    export PS1="[\[$cyan\]\u\[$reset\]@\[$cyan\]\h\[$reset\]:\[$green\]\w\[$reset\]]\n\[$red\]λ\[$reset\] "
fi'

echo "-- Miscellaneous bash things added"
