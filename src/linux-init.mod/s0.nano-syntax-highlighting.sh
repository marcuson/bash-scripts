#!/usr/bin/env bash

Mbs:LinuxInit:enableNanoSyntaxHighlighting() {
    Mbs:Io:print "Enabling Nano Syntax highlighting"

    if ! Mbs:User:isNormal "$MBS__LI__USER"; then
        Mbs:Script:die "\nMBS__LI__USER problem, it must be set, it must be a normal user, it must exists"
    fi

    if Mbs:Var:isEmpty "$home_user_d"; then
        home_user_d=$(sudo -u "$MBS__LI__USER" sh -c 'echo $HOME')
    fi

    home_root_d=$(sudo -u root sh -c 'echo $HOME')

    local nano_conf_f=".nanorc"
    local nano_conf_user_f="$home_user_d/$nano_conf_f"
    local nano_conf_root_f="$home_root_d/$nano_conf_f"

    if [ ! -f "$nano_conf_root_f" ] || ! grep -q 'include "/usr/share/nano/\*.nanorc' "$nano_conf_root_f"; then
        echo -e 'include "/usr/share/nano/*.nanorc"\nset linenumbers' | tee -a "$nano_conf_root_f" >/dev/null
    else
        Mbs:Io:print "$nano_conf_root_f already configured"
    fi

    if [ ! -f "$nano_conf_user_f" ] || ! grep -q 'include "/usr/share/nano/\*.nanorc' "$nano_conf_user_f"; then
        echo -e 'include "/usr/share/nano/*.nanorc"\nset linenumbers' | sudo -u "$MBS__LI__USER" tee -a "$nano_conf_user_f" >/dev/null
    else
        Mbs:Io:print "$nano_conf_user_f already configured"
    fi
    Mbs:Io:print "Nano Syntax highlighting enabled"
    return 0
}
