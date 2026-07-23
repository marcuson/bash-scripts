#!/usr/bin/env bash

Mbs:LinuxInit:komodoPrep() {
    Mbs:Io:print "Prepare Komodo"

    if ! Mbs:User:isNormal "$MBS__LI__USER"; then
        Mbs:Script:die "MBS__LI__USER problem, it must be set, it must be a normal user, it must exists"
    fi

    if Mbs:Var:isEmpty "$home_user_d"; then
        home_user_d=$(sudo -u "$MBS__LI__USER" sh -c 'echo $HOME')
    fi

    if Mbs:LinuxInit:isVarEmpty "$MBS__LI__KOMODO_PREP__SOPS_KEY"; then
        Mbs:Script:die "MBS__LI__KOMODO_PREP__SOPS_KEY env var must be set"
    fi

    local home_root_d="$HOME"
    local profile_root_f="$home_root_d/.profile"
    local profile_user_f="$home_user_d/.profile"

    if [ ! -f "$profile_root_f" ] || ! grep -q 'SOPS_AGE_KEY_FILE' "$profile_root_f"; then
        echo "export SOPS_AGE_KEY_FILE=/srv/docker/age.key" >>"$profile_root_f"
        Mbs:Io:print "Added SOPS_AGE_KEY_FILE to $profile_root_f"
    else
        Mbs:Io:print "$profile_root_f already configured with SOPS_AGE_KEY_FILE"
    fi

    if [ ! -f "$profile_user_f" ] || ! grep -q 'SOPS_AGE_KEY_FILE' "$profile_user_f"; then
        sudo -u "$MBS__LI__USER" "sh" -c "echo export SOPS_AGE_KEY_FILE=/srv/docker/age.key >> \"$profile_user_f\""
        Mbs:Io:print "Added SOPS_AGE_KEY_FILE to $profile_user_f"
    else
        Mbs:Io:print "$profile_user_f already configured with SOPS_AGE_KEY_FILE"
    fi

    local inst_type="${MBS__LI__KOMODO_PREP__TYPE:=komodoperiphery}"

    mkdir -p "/srv/docker/stacks/$inst_type"
    mkdir -p "/srv/docker/data/$inst_type"

    echo "$MBS__LI__KOMODO_PREP__SOPS_KEY" >/srv/docker/age.key

    # FIXME: Copy komodoperiphery/komodo stacks (from an encrypted zip)

    chown -R "root:docker" /srv/docker
    chmod -R g+rw /srv/docker

    Mbs:Io:print "Komodo prep finished"

    return 0
}
