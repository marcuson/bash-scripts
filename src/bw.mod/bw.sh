#!/usr/bin/env bash

# !mbs meta require-tools bw

# Unlocks the Bitwarden vault and ensures a valid session is available.
#
# Globals:
#   MBS__BW__HELPER_F: Path to the helper file that stores active session IDs.
#   MBS__BW__URL: Bitwarden server URL.
#   MBS__BW__CLIENT_ID: Bitwarden client ID.
#   MBS__BW__CLIENT_SECRET: Bitwarden client secret.
#   MBS__BW__MASTER_PASSWORD: Bitwarden master password.
# Returns:
#   0 if the vault is unlocked successfully, non-zero otherwise.
Mbs:Bw:unlock() {
    if [ -z "${MBS__BW__HELPER_F}" ]; then
        Mbs:Io:error "Bitwarden helper file path not set, cannot proceed"
        return 1
    fi

    if [ ! -f "${MBS__BW__HELPER_F}" ]; then
        Mbs:Io:error "Bitwarden helper file path does not exist, cannot proceed"
        return 1
    fi

    if [ -z "${MBS__BW__URL:-}" ]; then
        Mbs:Io:error "Missing MBS__BW__URL config, cannot proceed"
        return 1
    fi
    if [ -z "${MBS__BW__CLIENT_ID:-}" ]; then
        Mbs:Io:error "Missing MBS__BW__CLIENT_ID config, cannot proceed"
        return 1
    fi
    if [ -z "${MBS__BW__CLIENT_SECRET:-}" ]; then
        Mbs:Io:error "Missing MBS__BW__CLIENT_SECRET config, cannot proceed"
        return 1
    fi
    if [ -z "${MBS__BW__MASTER_PASSWORD:-}" ]; then
        Mbs:Io:error "Missing MBS__BW__MASTER_PASSWORD config, cannot proceed"
        return 1
    fi

    export BW_CLIENTID="${MBS__BW__CLIENT_ID:-}"
    export BW_CLIENTSECRET="${MBS__BW__CLIENT_SECRET:-}"
    export BW_MASTER_PASSWORD="${MBS__BW__MASTER_PASSWORD:-}"

    local bw_url
    local bw_status
    local session

    bw_url=$(bw status | jq -r .serverUrl 2>/dev/null)
    if [[ "$bw_url" != "$MBS__BW__URL" ]]; then
        Mbs:Io:print "Configuring Bitwarden CLI to use server URL '$MBS__BW__URL'" >/dev/tty
        Mbs:Bw:lock
        bw config server "$MBS__BW__URL" >/dev/tty || IO:die "Bitwarden config failed"
    fi

    bw_status=$(bw status | jq -r .status)
    if [ -z "$bw_status" ] || [ "$bw_status" = "unauthenticated" ]; then
        Mbs:Io:print "Bitwarden: login"
        bw login --apikey || IO:die "Bitwarden login failed"
    fi

    bw_status=$(bw status | jq -r .status)
    if [ "$bw_status" = "locked" ]; then
        Mbs:Io:print "Bitwarden: unlock"
        session=$(bw unlock --passwordenv BW_MASTER_PASSWORD --raw) || IO:die "Bitwarden unlock failed"
        echo "$session" >>"$MBS__BW__HELPER_F"
        export BW_SESSION="$session"
    fi

    bw sync --force
}

# Locks and invalidates a specific Bitwarden session.
#
# Arguments:
#   session: Session token to invalidate.
# Returns:
#   0 if the session is already unauthenticated or was invalidated
#   successfully, non-zero if invalidation fails.
Mbs:Bw:lockSession() {
    local session
    session="$1"
    local bw_status

    bw_status=$(BW_SESSION="$session" bw status | jq -r .status)
    if [ -z "$bw_status" ] || [ "$bw_status" = "unauthenticated" ]; then
        Mbs:Io:print "Bitwarden: not logged in"
        return 0
    fi

    if ! BW_SESSION="$session" bw lock; then
        Mbs:Io:error "Failed to invalidate Bitwarden session"
        return 1
    fi

    Mbs:Io:print "Bitwarden session invalidated"
    return 0
}

# Locks the Bitwarden vault and invalidates all stored sessions.
#
# Globals:
#   MBS__BW__HELPER_F: Path to the helper file that stores active session IDs.
# Returns:
#   0 on success.
Mbs:Bw:lock() {
    Mbs:Io:print "Invalidating Bitwarden sessions from helper file [$MBS__BW__HELPER_F]"
    if [ -n "${MBS__BW__HELPER_F:-}" ] && [ -f "$MBS__BW__HELPER_F" ]; then
        while IFS= read -r line; do
            Mbs:Bw:lockSession "$line"
        done <"$MBS__BW__HELPER_F"
    fi

    unset BW_SESSION
    cat /dev/null >|"$MBS__BW__HELPER_F"

    return 0
}

# Retrieves a value from a Bitwarden item.
#
# Arguments:
#   item_name: Name of the Bitwarden item.
#   property: Optional property to retrieve. Defaults to "item".
# Returns:
#   0 on success, non-zero on failure.
Mbs:Bw:get() {
    if [ $# -lt 1 ]; then
        Mbs:Io:error "Usage: Mbs:Bw:get <item-name> [property]"
        return 2
    fi

    local item_name="$1"
    local item_field="${2:-item}"

    Mbs:Bw:unlock &>/dev/tty

    bw get "$item_field" "$item_name"
}

# Retrieves the value of a custom field from a Bitwarden item.
#
# Arguments:
#   item_name: Name of the Bitwarden item.
#   custom_field: Name of the custom field to retrieve.
# Returns:
#   0 on success, non-zero on failure.
Mbs:Bw:getCF() {
    if [ $# -lt 2 ]; then
        Mbs:Io:error "Usage: Mbs:Bw:getCF <item-name> <field-name>"
        return 2
    fi

    local item_name="$1"
    local custom_field="$2"

    Mbs:Bw:get "$item_name" | jq -r ".fields[] | select(.name==\"$custom_field\") | .value"
}
