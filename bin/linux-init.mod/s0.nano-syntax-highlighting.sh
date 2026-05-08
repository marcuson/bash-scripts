#!/usr/bin/env bash

LinuxInitMod:enableNanoSyntaxHighlighting() {
    IO:print "Enabling Nano Syntax highlighting"

    if LinuxInitMod:isVarEmpty "$LI__USER"; then
        IO:print "Missing LI__USER, please enter the normal user name and press enter: "
        read -r
        LI__USER="$REPLY"
    fi

    if ! LinuxInitMod:isNormalUser "$LI__USER"; then
        IO:alert "\nLI__USER problem, it must be set, it must be a normal user, it must exists"
        return 1
    fi

    if LinuxInitMod:isVarEmpty "$home_user_d"; then
        home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')
    fi

    home_root_d=$(sudo -u root sh -c 'echo $HOME')

    local nano_conf_f=".nanorc"
    local nano_conf_user_f="$home_user_d/$nano_conf_f"
    local nano_conf_root_f="$home_root_d/$nano_conf_f"

    if [ ! -f "$nano_conf_root_f" ] || ! grep -q 'include "/usr/share/nano/\*.nanorc' "$nano_conf_root_f"; then
        echo -e 'include "/usr/share/nano/*.nanorc"\nset linenumbers' | tee -a "$nano_conf_root_f" >/dev/null
    else
        IO:print "$nano_conf_root_f already configured"
    fi

    if [ ! -f "$nano_conf_user_f" ] || ! grep -q 'include "/usr/share/nano/\*.nanorc' "$nano_conf_user_f"; then
        echo -e 'include "/usr/share/nano/*.nanorc"\nset linenumbers' | sudo -u "$LI__USER" tee -a "$nano_conf_user_f" >/dev/null
    else
        IO:print "$nano_conf_user_f already configured"
    fi
    IO:print "Nano Syntax highlighting enabled"
    return 0
}
