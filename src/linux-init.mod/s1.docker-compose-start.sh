#!/usr/bin/env bash

# !mbs meta require-tools docker

Mbs:LinuxInit:startDockerCompose() {
    Mbs:Io:print "Starting docker compose"

    local docker_group="docker"
    if ! Mbs:User:isCurrentRunningAsRoot 2>/dev/null && ! Mbs:User:isCurrentInGroup "$docker_group"; then
        Mbs:Io:error "Current user isn't in $docker_group group, cannot proceed"
        Mbs:Io:error "Add current user to $docker_group group or run this script as root"
        return 1
    fi

    Mbs:LinuxInit:checkConfig "MBS__LI__DOCKER_COMPOSE_START__FILE_PATH" || return 1

    if [ ! -f "$MBS__LI__DOCKER_COMPOSE_START__FILE_PATH" ]; then
        Mbs:Io:error "Cannot find $MBS__LI__DOCKER_COMPOSE_START__FILE_PATH compose file, please check"
        Mbs:LinuxInit:paktc
        return 1
    fi

    docker compose -f "$MBS__LI__DOCKER_COMPOSE_START__FILE_PATH" up -d
    Mbs:Io:print "Services in $MBS__LI__DOCKER_COMPOSE_START__FILE_PATH compose file should be up and running"

    return 0
}
