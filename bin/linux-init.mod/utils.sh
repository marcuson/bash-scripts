#!/usr/bin/env bash

# Press any key to continue
LinuxInitMod:paktc() {
    IO:print ""
    IO:print "Press any key to continue"
    read -n 1 -s -r
    IO:print ""
}

# Check if running as root
LinuxInitMod:checkSU() {
    if [ ! "${EUID:-$(id -u)}" -eq 0 ]; then
        return 1
    fi
    return 0
}

# Check if a bool/ask configuration var exists via indirection
# The argument to use is the name of the var, not the var itself
# If it exists and its value is true or false: returns the value (true=0 false=1)
# If it doesn't exist, or if it's value is 'ask': configures it on the fly as boolean and returns the result
# If it exists and its value is any other value: returns >1 values as error
# EG: checkConfig LI__ENABLE_RFKILL
LinuxInitMod:checkInitConfig() {
    if [ $# -eq 0 ]; then
        IO:print "No arguments provided to function. Call stack:"
        LinuxInitMod:callStack
        LinuxInitMod:paktc
        return 2
    fi
    if [ -z ${!1+x} ] || [ "${!1}" = "ask" ]; then
        read -p "Do you want to apply init config for $1? Y/N: " -n 1 -r
        IO:print ""
        [[ $REPLY =~ ^[Yy]$ ]] && return 0
        return 1
    elif [ "${!1}" = true ]; then
        return 0
    elif [ "${!1}" = false ]; then
        return 1
    else
        IO:print "Config error for $1: wrong value, current value: '${!1}'\nPossible values are true,false,ask"
        LinuxInitMod:paktc
        return 3
    fi
}

# Check if a configuration var exists via indirection
# The argument to use is the name of the var, not the var itself
# If it exists and its value is not empty it returns 0, > 0 in any other case
# EG: checkConfig LI__JOURNAL_LIMIT__SYSTEM_MAX
LinuxInitMod:checkConfig() {
    if [ $# -eq 0 ]; then
        IO:alert "${BASH_SOURCE[$i + 1]}:${BASH_LINENO[$i]} - ${FUNCNAME[$i]}: no arguments provided"
        LinuxInitMod:paktc
        return 2
    fi
    if [ -z ${!1+x} ]; then
        IO:alert "Missing $1 config, cannot proceed"
        return 1
    fi
    return 0
}

# Check if a command exists
LinuxInitMod:checkCommand() {
    [ $# -eq 0 ] && return 1
    if ! command -v "$1" &>/dev/null; then
        IO:alert "$1 command not found"
        return 1
    fi
    return 0
}

# Check if a var is set, bash only
# $1: var name
# EG: isVarSet variable_name
LinuxInitMod:isVarSet() {
    [ $# -eq 0 ] && return 1
    [ -z "$1" ] && return 1
    declare -p "$1" &>/dev/null
}

# Check if a var content has no value assigned
# $1: var content
# EG: isVarEmpty $variable_name
LinuxInitMod:isVarEmpty() {
    [ $# -eq 0 ] && return 1
    [ -z "$1" ] && return 0
    return 1
}

# Return type of a variable, bash only
# $1: var name
# EG: getVarType variable_name
LinuxInitMod:getVarType() {
    if ! LinuxInitMod:isVarSet "$1"; then
        IO:print "UNSET"
        return 1
    fi

    local var
    var=$(declare -p "$1" 2>/dev/null)
    local reg='^declare -n [^=]+=\"([^\"]+)\"$'
    while [[ $var =~ $reg ]]; do
        var=$(declare -p "${BASH_REMATCH[1]}")
    done

    case "${var#declare -}" in
    a*)
        IO:print "ARRAY"
        ;;
    A*)
        IO:print "HASH"
        ;;
    i*)
        IO:print "INT"
        ;;
    x*)
        IO:print "EXPORT"
        ;;
    *)
        IO:print "OTHER"
        ;;
    esac
    return 0
}

# Check if a var is an array, bash only
# $1: var name
# EG: isVarArray variable_name
LinuxInitMod:isVarArray() {
    LinuxInitMod:getVarType "$1" | grep -q "ARRAY"
}

# Check if a var is int, input arg is var name, bash only
# $1: var name
# EG: isVarInt variable_name
LinuxInitMod:isVarInt() {
    LinuxInitMod:getVarType "$1" | grep -q "INT"
}

# Check if a var is other, input arg is var name, bash only
# Userful for strings
# $1: var name
# EG: isVarOther variable_name
LinuxInitMod:isVarOther() {
    LinuxInitMod:getVarType "$1" | grep -q "OTHER"
}

# Check if provided user exists and isn't root
# $1: username to check
LinuxInitMod:isNormalUser() {
    [ $# -eq 0 ] && return 1
    LinuxInitMod:isVarEmpty "$1" && return 1
    ! id "$1" &>/dev/null && return 1
    [ "$1" = "root" ] && return 1
    return 0
}

# Enable a service if exists
# $1 service name
# $2 true/false start service
# EG: enableService docker true

LinuxInitMod:enableService() {
    [ $# -eq 0 ] && return 1

    local serviceName="$1"
    local startService="${2:-false}" # Default value is false
    IO:print "Enabling service '$serviceName'"

    systemctl list-unit-files | grep "$serviceName" 1>/dev/null 2>&1
    if ! systemctl list-unit-files | grep "$serviceName" 1>/dev/null 2>&1; then
        IO:alert "$serviceName service does NOT exist."
        return 1
    fi

    if [ "$startService" = true ]; then
        systemctl enable --now "$serviceName"
        IO:print "$serviceName service enabled and started"
    else
        systemctl enable "$serviceName"
        IO:print "$serviceName service enabled"
    fi
    return 0
}

# Check if current user is in a group
# $1: group
# EG: isMeInGroup nobody
LinuxInitMod:isMeInGroup() {
    [ $# -eq 0 ] && return 1
    LinuxInitMod:isVarEmpty "$1" && return 1
    groups 2>/dev/null | grep -q "\b$1\b"
}

# Check if a user is in a group
# $1: user
# $2: group
# EG: isUserInGroup pi nobody
LinuxInitMod:isUserInGroup() {
    [ $# -lt 2 ] && return 1
    LinuxInitMod:isVarEmpty "$1" && return 1
    LinuxInitMod:isVarEmpty "$2" && return 1
    groups "$1" 2>/dev/null | grep -q "\b$2\b"
}

# Request manual input if var is not present or empty via indirection
# The argument to use is the name of the var, not the var itself
# $1: var_name
# $2: optional message to show to user
# EG: isUserInGroup pi nobody
LinuxInitMod:ensureVar() {
    if LinuxInitMod:isVarEmpty "${!1+x}"; then
        IO:print "Missing '$1' config. Please enter '$1' (${2:-$1}): "
        read -r
        declare -g "$1"="$REPLY"
    fi
}

# Print simple separator
LinuxInitMod:printSep() {
    IO:print "\n-----------------------------\n"
}

# Show call stack
LinuxInitMod:callStack() {
    local i=1
    while caller $i; do
        ((i++))
    done
}
