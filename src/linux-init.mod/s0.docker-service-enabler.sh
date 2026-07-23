#!/usr/bin/env bash

Mbs:LinuxInit:enableDockerService() {
    Mbs:Io:print "Enabling Docker services"

    if ! Mbs:LinuxInit:enableService "docker.service" false; then
        Mbs:Io:error "Failed to enable docker service"
        return 1
    fi

    if ! Mbs:Os:enableService "containerd.service" false; then
        Mbs:Io:error "Failed to enable containerd service"
        return 1
    fi

    return 0
}
