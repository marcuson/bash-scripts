#!/usr/bin/env bash

LinuxInitMod:prepareSSH() {
    IO:print "Adding .ssh folders and basic files"

    if LinuxInitMod:isVarEmpty "$LI__USER"; then
        IO:print "Missing LI__USER, please enter the normal user name and press enter\n"
        read -r
        LI__USER="$REPLY"
    fi

    if ! LinuxInitMod:isNormalUser "$LI__USER"; then
        IO:alert "LI__USER problem, it must be set, it must be a normal user, it must exists"
        return 1
    fi

    if LinuxInitMod:isVarEmpty "$home_user_d"; then
        home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')
    fi

    local ssh_user_d="$home_user_d/.ssh"
    export ssh_auth_keys_user_f="$ssh_user_d/authorized_keys"
    export ssh_known_hosts_user_f="$ssh_user_d/known_hosts"

    sudo -u "$LI__USER" mkdir -p "$ssh_user_d"
    sudo -u "$LI__USER" touch "$ssh_auth_keys_user_f" "$ssh_known_hosts_user_f"
    chmod 700 "$ssh_user_d"
    chmod 600 "$ssh_auth_keys_user_f" "$ssh_known_hosts_user_f"
    IO:print ".ssh folders and basic files added"
    return 0
}
