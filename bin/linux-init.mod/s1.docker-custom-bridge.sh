#!/usr/bin/env bash

LinuxInitMod:createCustomDockerBridgeNetwork() {
  IO:print "Creating Docker custom bridge network"

  local docker_group="docker"

  if ! LinuxInitMod:checkCommand "docker"; then
    IO:alert "docker command missing, cannot proceed"
    return 1
  fi

  LinuxInitMod:checkConfig "LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME" || return 1

  if ! LinuxInitMod:checkSU 2>/dev/null && ! LinuxInitMod:isMeInGroup "$docker_group"; then
    IO:alert "Current user isn't in $docker_group group, cannot proceed"
    IO:alert "Add current user to $docker_group group or run this script as root"
    return 1
  fi

  if docker network ls | grep "$LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME" 1>/dev/null 2>&1; then
    IO:print "Docker bridge network '$LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME' already exists, skipping"
    return 0
  fi

  docker network create "$LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME"
  IO:print "Docker custom bridge network '$LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME' created"
  return 0
}
