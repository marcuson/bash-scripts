#!/usr/bin/env bash

LinuxInitMod:startDockerCompose() {
    IO:print "Starting docker compose"

    if ! LinuxInitMod:checkCommand "docker"; then
        IO:alert "docker command missing, cannot proceed"
        return 1
    fi

    local docker_group="docker"
    if ! LinuxInitMod:checkSU 2>/dev/null && ! LinuxInitMod:isMeInGroup "$docker_group"; then
        IO:alert "Current user isn't in $docker_group group, cannot proceed"
        IO:alert "Add current user to $docker_group group or run this script as root"
        return 1
    fi

    LinuxInitMod:checkConfig "LI__DOCKER_COMPOSE_START__FILE_PATH" || return 1

    if [ ! -f "$LI__DOCKER_COMPOSE_START__FILE_PATH" ]; then
        IO:alert "Cannot find $LI__DOCKER_COMPOSE_START__FILE_PATH compose file, please check"
        LinuxInitMod:paktc
        return 1
    fi

    docker compose -f "$LI__DOCKER_COMPOSE_START__FILE_PATH" up -d
    IO:print "Services in $LI__DOCKER_COMPOSE_START__FILE_PATH compose file should be up and running"

    return 0
}
