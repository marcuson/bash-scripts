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

# Add a trap
LinuxInitMod:addTrap() {
    local cmd=$1         # command(s) to add
    local sig=${2:-EXIT} # signal name or number

    # validate signal name or numeric id
    local sig_name
    {
        if [[ $sig =~ ^[0-9]+$ ]]; then
            sig_name=$(kill -l "$sig")
        else
            sig_name=${sig^^}
            kill -l "$sig_name" &>/dev/null
        fi
    } || {
        echo "add_trap: invalid signal '$sig'" >&2
        return 1
    }

    # Compute effective trap list for current (sub)shell
    # Based on info from https://stackoverflow.com/a/59307894/5116073
    local old
    if [[ "${BASH_VERSINFO:-0}" -ge 4 ]]; then
        trap -- KILL &>/dev/null || true
        old=$(trap -p "$sig_name")
    else
        old=$( (trap -p "$sig_name"))
    fi

    # extract/cleanup the existing registered command(s)
    old=${old#*\'}         # remove leading "trap -- '"
    old=${old%\'*}         # remove trailing "' EXIT"
    old=${old//"'\''"/"'"} # unescape every '\'' to '

    # if command is already registered, do nothing
    if [[ ";$old;" == *";$cmd;"* ]]; then
        return 0
    fi

    # build the new combined handler
    if [[ -n $old ]]; then
        combined="$old;$cmd"
    else
        combined="$cmd"
    fi

    # register the new combined handler
    trap -- "$combined" "$sig"
}

# Login to Bitwarden and unlock vault
LinuxInitMod:bwUnlock() {
    if [ -z "${bw_helper_f}" ]; then
        IO:alert "Bitwarden helper file path not set, cannot proceed"
        return 1
    fi
    if [ ! -f "${bw_helper_f}" ]; then
        IO:alert "Bitwarden helper file path does not exist, cannot proceed"
        return 1
    fi

    if [ -z "${LI__BW__URL:-}" ]; then
        IO:alert "Missing LI__BW__URL config, cannot proceed"
        return 1
    fi
    if [ -z "${LI__BW__CLIENT_ID:-}" ]; then
        IO:alert "Missing LI__BW__CLIENT_ID config, cannot proceed"
        return 1
    fi
    if [ -z "${LI__BW__CLIENT_SECRET:-}" ]; then
        IO:alert "Missing LI__BW__CLIENT_SECRET config, cannot proceed"
        return 1
    fi
    if [ -z "${LI__BW__MASTER_PASSWORD:-}" ]; then
        IO:alert "Missing LI__BW__MASTER_PASSWORD config, cannot proceed"
        return 1
    fi

    export BW_CLIENTID="${LI__BW__CLIENT_ID:-}"
    export BW_CLIENTSECRET="${LI__BW__CLIENT_SECRET:-}"
    export BW_MASTER_PASSWORD="${LI__BW__MASTER_PASSWORD:-}"

    local bw_url
    local bw_status
    local session

    bw_url=$(bw status | jq -r .serverUrl 2>/dev/null)
    if [[ "$bw_url" != "$LI__BW__URL" ]]; then
        IO:print "Configuring Bitwarden CLI to use server URL '$LI__BW__URL'" >/dev/tty
        LinuxInitMod:bwLogout
        bw config server "$LI__BW__URL" >/dev/tty || IO:die "Bitwarden config failed"
    fi

    bw_status=$(bw status | jq -r .status)
    if [ -z "$bw_status" ] || [ "$bw_status" = "unauthenticated" ]; then
        IO:print "Bitwarden: login"
        bw login --apikey || IO:die "Bitwarden login failed"
    fi

    bw_status=$(bw status | jq -r .status)
    if [ "$bw_status" = "locked" ]; then
        IO:print "Bitwarden: unlock"
        session=$(bw unlock --passwordenv BW_MASTER_PASSWORD --raw) || IO:die "Bitwarden unlock failed"
        echo "$session" >>"$bw_helper_f"
        export BW_SESSION="$session"
    fi

    bw sync --force
}

# Lock and invalidate specific BW session
LinuxInitMod:bwLockSession() {
    Os:require bw "snap install bw"

    local session
    session="$1"
    local bw_status

    bw_status=$(BW_SESSION="$session" bw status | jq -r .status)
    if [ -z "$bw_status" ] || [ "$bw_status" = "unauthenticated" ]; then
        IO:print "Bitwarden: no logged in"
        return 0
    fi

    if ! BW_SESSION="$session" bw lock; then
        IO:alert "Failed to invalidate Bitwarden session"
        return 1
    fi

    IO:print "Bitwarden session invalidated"
    return 0
}

# Lock Bitwarden vault and invalidate session (also old ones)
LinuxInitMod:bwLock() {
    Os:require bw "snap install bw"

    IO:print "Invalidating Bitwarden sessions from helper file"
    if [ -n "${bw_helper_f:-}" ] && [ -f "$bw_helper_f" ]; then
        while IFS= read -r line; do
            LinuxInitMod:bwLockSession "$line"
        done <"$bw_helper_f"
    fi

    unset BW_SESSION
    cat /dev/null >|"$bw_helper_f"

    return 0
}

# Copy value from Bitwarden vault
LinuxInitMod:bwGet() {
    Os:require bw "snap install bw"

    if [ $# -lt 1 ]; then
        IO:alert "Usage: LinuxInitMod:bwGet <item-name> [property]"
        return 2
    fi

    local item_name="$1"
    local item_field="${2:-item}"

    LinuxInitMod:bwUnlock &>/dev/tty

    bw get "$item_field" "$item_name"
}

# Get custom field value from Bitwarden vault
LinuxInitMod:bwGetCF() {
    Os:require bw "snap install bw"

    if [ $# -lt 2 ]; then
        IO:alert "Usage: LinuxInitMod:bwGetCF <item-name> <field-name>"
        return 2
    fi

    local item_name="$1"
    local custom_field="$2"

    LinuxInitMod:bwGet "$item_name" | jq -r ".fields[] | select(.name==\"$custom_field\") | .value"
}
