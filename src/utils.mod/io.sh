#!/usr/bin/env bash

# Prints text to stdout.
#
# Args:
#   msg: Message or text to print. Accepts multiple arguments.
# Outputs:
#   Prints the provided message to stdout.
Mbs:Io:print() {
    printf '%b\n' "$*"
}

# Prints an error message with an [ERR] prefix.
#
# Args:
#   msg: Error message text to print.
# Outputs:
#   Prints the provided message to stdout with an [ERR] prefix.
Mbs:Io:error() {
    Mbs:Io:print '[ERR]' "$*"
}

# Prints a warning message with a [WRN] prefix.
#
# Args:
#   msg: Warning message text to print.
# Outputs:
#   Prints the provided message to stdout with a [WRN] prefix.
Mbs:Io:warn() {
    Mbs:Io:print '[WRN]' "$*"
}

# Prints an informational message with an [INF] prefix.
#
# Args:
#   msg: Informational message text to print.
# Outputs:
#   Prints the provided message to stdout with an [INF] prefix.
Mbs:Io:info() {
    Mbs:Io:print '[INF]' "$*"
}

# Prints a success message with a [SUC] prefix.
#
# Args:
#   msg: Success message text to print.
# Outputs:
#   Prints the provided message to stdout with a [SUC] prefix.
Mbs:Io:success() {
    Mbs:Io:print '[SUC]' "$*"
}

# Prints a debug message with a [DBG] prefix.
#
# Args:
#   msg: Success message text to print.
# Outputs:
#   Prints the provided message to stdout with a [DBG] prefix.
Mbs:Io:debug() {
    Mbs:Io:print '[DBG]' "$*"
}

# Prints a simple separator line.
#
# Outputs:
#   Prints a separator to stdout.
Mbs:Io:printSep() {
    Mbs:Io:print "\n-----------------------------\n"
}

# Pauses execution until the user presses a key.
#
# Outputs:
#   Prompts the user to press any key and then continues.
# Returns:
#   0 after the user presses a key.
Mbs:Io:paktc() {
    Mbs:Io:print ""
    Mbs:Io:print "Press any key to continue"
    read -n 1 -s -r
    Mbs:Io:print ""
}

Mbs:Io:confirm() {
    local default_choice text_suffix
    default_choice="$1"
    [[ $default_choice =~ ^[Yy]$ ]] && text_suffix="[Y/n]" || text_suffix="[y/N]"

    read -r -p "$2 $text_suffix " -n 1
    echo " "

    local answer
    answer="${REPLY:-$default_choice}"
    [[ $answer =~ ^[Yy]$ ]]
}

Mbs:Io:confirmDefaultNo() {
    Mbs:Io:confirm "n" "$1"
}

Mbs:Io:confirmDefaultYes() {
    Mbs:Io:confirm "y" "$1"
}
