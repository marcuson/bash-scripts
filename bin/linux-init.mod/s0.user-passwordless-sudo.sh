#!/usr/bin/env bash

LinuxInitMod:enablePasswordlessSudo() {
    IO:print "Setting sudo without password"

    if LinuxInitMod:isVarEmpty "$LI__USER"; then
        IO:print "Missing LI__USER, please enter the normal user name and press enter: "
        read -r
        LI__USER="$REPLY"
    fi

    if ! LinuxInitMod:isNormalUser "$LI__USER"; then
        IO:alert "LI__USER problem, it must be set, it must be a normal user, it must exists"
        return 1
    fi

    IO:print "New super-uber-user: $LI__USER"

    local sudoers_f="/etc/sudoers.d/99-$LI__USER"

    if [ -f "$sudoers_f" ]; then
        IO:print "$sudoers_f file already exists, please check"
        return 0
    fi

    echo "$LI__USER ALL=(ALL) NOPASSWD: ALL" | tee "$sudoers_f" >/dev/null
    chmod 750 "$sudoers_f"
    IO:print "$LI__USER can run sudo without password from the next boot."
    return 0
}
