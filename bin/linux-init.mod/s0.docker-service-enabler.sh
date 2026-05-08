#!/usr/bin/env bash

LinuxInitMod:enableDockerService() {
    IO:print "Enabling Docker services"

    if ! LinuxInitMod:enableService "docker.service" false; then
        IO:alert "Failed to enable docker service"
        return 1
    fi

    if ! LinuxInitMod:enableService "containerd.service" false; then
        IO:alert "Failed to enable containerd service"
        return 1
    fi

    return 0
}
