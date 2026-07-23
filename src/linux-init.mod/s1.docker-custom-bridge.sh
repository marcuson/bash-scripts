#!/usr/bin/env bash

# !mbs meta require-tools docker

Mbs:LinuxInit:createCustomDockerBridgeNetwork() {
  Mbs:Io:print "Creating Docker custom bridge network"

  local docker_group="docker"

  Mbs:Var:isSet "MBS__LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME" || return 1

  if ! Mbs:User:isCurrentRunningAsRoot 2>/dev/null && ! Mbs:User:isCurrentInGroup "$docker_group"; then
    Mbs:Io:error "Current user isn't in $docker_group group, cannot proceed"
    Mbs:Io:error "Add current user to $docker_group group or run this script as root"
    return 1
  fi

  if docker network ls | grep "$MBS__LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME" 1>/dev/null 2>&1; then
    Mbs:Io:print "Docker bridge network '$MBS__LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME' already exists, skipping"
    return 0
  fi

  docker network create "$MBS__LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME"
  Mbs:Io:print "Docker custom bridge network '$MBS__LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME' created"
  return 0
}
