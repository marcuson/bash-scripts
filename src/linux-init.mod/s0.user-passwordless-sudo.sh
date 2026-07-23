#!/usr/bin/env bash

Mbs:LinuxInit:enablePasswordlessSudo() {
    Mbs:Io:print "Setting sudo without password"

    if Mbs:Var:isEmpty "$MBS__LI__USER"; then
        Mbs:Io:print "Missing MBS__LI__USER, please enter the normal user name and press enter: "
        read -r
        MBS__LI__USER="$REPLY"
    fi

    if ! Mbs:User:isNormal "$MBS__LI__USER"; then
        Mbs:Io:error "MBS__LI__USER problem, it must be set, it must be a normal user, it must exists"
        return 1
    fi

    Mbs:Io:print "New super-uber-user: $MBS__LI__USER"

    local sudoers_f="/etc/sudoers.d/99-$MBS__LI__USER"

    if [ -f "$sudoers_f" ]; then
        Mbs:Io:print "$sudoers_f file already exists, please check"
        return 0
    fi

    echo "$MBS__LI__USER ALL=(ALL) NOPASSWD: ALL" | tee "$sudoers_f" >/dev/null
    chmod 750 "$sudoers_f"
    Mbs:Io:print "$MBS__LI__USER can run sudo without password from the next boot."
    return 0
}
