#!/usr/bin/env bash

# !mbs meta require-tools docker

Mbs:LinuxInit:dockerLogin() {
    Mbs:Io:print "Docker login"

    local docker_group="docker"

    if Mbs:Var:isEmpty "$home_user_d"; then
        home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')
    fi
    local auth_f="$home_user_d/.docker/config.json"

    if grep -q "index.docker.io" "$auth_f"; then
        Mbs:Io:print "Already logged to DockerHub, skipping"
        return 0
    fi

    Mbs:Io:print "Please prepare docker hub user and password"
    Mbs:Io:paktc

    if Mbs:Var:isEmpty "$LI__USER"; then
        Mbs:Io:error "Missing LI__USER, please enter the normal user name and press enter"
        read -r
        LI__USER="$REPLY"
    fi

    if ! Mbs:User:isNormal "$LI__USER"; then
        Mbs:Io:error "LI__USER problem, it must be set, it must be a normal user, it must exists"
        return 1
    fi

    if ! Mbs:User:isCurrentInGroup "$LI__USER" "$docker_group"; then
        Mbs:Io:error "LI__USER found, $LI__USER isn't in $docker_group group"
        read -p "Do you want to add $LI__USER to $docker_group group? Y/N: " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            usermod -aG "$docker_group" "$LI__USER"
        else
            Mbs:Io:error "Cannot proceed"
            return 1
        fi
    fi

    sudo -u "$LI__USER" docker login -u "$LI__DOCKER_LOGIN__USERNAME"
    return 0
}
