#!/usr/bin/env bash

LinuxInitMod:komodoPrep() {
    IO:print "Prepare Komodo"

    if ! LinuxInitMod:isNormalUser "$LI__USER"; then
        IO:die "LI__USER problem, it must be set, it must be a normal user, it must exists"
    fi

    if LinuxInitMod:isVarEmpty "$home_user_d"; then
        home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')
    fi

    if LinuxInitMod:isVarEmpty "$LI__KOMODO_PREP__SOPS_KEY"; then
        IO:die "LI__KOMODO_PREP__SOPS_KEY env var must be set"
    fi

    local home_root_d="$HOME"
    local profile_root_f="$home_root_d/.profile"
    local profile_user_f="$home_user_d/.profile"

    if [ ! -f "$profile_root_f" ] || ! grep -q 'SOPS_AGE_KEY_FILE' "$profile_root_f"; then
        echo "export SOPS_AGE_KEY_FILE=/srv/docker/age.key" >>"$profile_root_f"
        IO:print "Added SOPS_AGE_KEY_FILE to $profile_root_f"
    else
        IO:print "$profile_root_f already configured with SOPS_AGE_KEY_FILE"
    fi

    if [ ! -f "$profile_user_f" ] || ! grep -q 'SOPS_AGE_KEY_FILE' "$profile_user_f"; then
        sudo -u "$LI__USER" "sh" -c "echo export SOPS_AGE_KEY_FILE=/srv/docker/age.key >> \"$profile_user_f\""
        IO:print "Added SOPS_AGE_KEY_FILE to $profile_user_f"
    else
        IO:print "$profile_user_f already configured with SOPS_AGE_KEY_FILE"
    fi

    local inst_type="${LI__KOMODO_PREP__TYPE:=komodoperiphery}"

    mkdir -p "/srv/docker/stacks/$inst_type"
    mkdir -p "/srv/docker/data/$inst_type"

    echo "$LI__KOMODO_PREP__SOPS_KEY" >/srv/docker/age.key

    # FIXME: Copy komodoperiphery/komodo stacks (from an ecnrypted zip)

    chown -R "root:docker" /srv/docker
    chmod -R g+rw /srv/docker

    IO:print "Komodo prep finished"

    return 0
}
