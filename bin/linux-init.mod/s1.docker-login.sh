#!/usr/bin/env bash

LinuxInitMod:dockerLogin() {
    IO:print "Docker login"

    local docker_group="docker"

    if ! LinuxInitMod:checkCommand "docker"; then
        IO:alert "docker command missing, cannot proceed"
        return 1
    fi

    if LinuxInitMod:isVarEmpty "$home_user_d"; then
        home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')
    fi
    local auth_f="$home_user_d/.docker/config.json"

    if grep -q "index.docker.io" "$auth_f"; then
        IO:print "Already logged to DockerHub, skipping"
        return 0
    fi

    IO:print "Please prepare docker hub user and password"
    LinuxInitMod:paktc

    if LinuxInitMod:isVarEmpty "$LI__USER"; then
        IO:alert "Missing LI__USER, please enter the normal user name and press enter"
        read -r
        LI__USER="$REPLY"
    fi

    if ! LinuxInitMod:isNormalUser "$LI__USER"; then
        IO:alert "LI__USER problem, it must be set, it must be a normal user, it must exists"
        return 1
    fi

    if ! LinuxInitMod:isUserInGroup "$LI__USER" "$docker_group"; then
        IO:alert "LI__USER found, $LI__USER isn't in $docker_group group"
        read -p "Do you want to add $LI__USER to $docker_group group? Y/N: " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            usermod -aG "$docker_group" "$LI__USER"
        else
            IO:alert "Cannot proceed"
            return 1
        fi
    fi

    LinuxInitMod:ensureVar "LI__DOCKER_LOGIN__USERNAME" "DockerHub username"
    sudo -u "$LI__USER" docker login -u "$LI__USER"
    return 0
}
