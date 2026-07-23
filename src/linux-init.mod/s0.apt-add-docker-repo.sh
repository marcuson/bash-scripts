#!/usr/bin/env bash

# !mbs meta require-tools curl

Mbs:LinuxInit:aptAddDockerRepo() {
  Mbs:Io:print "Add Docker repo to APT"

  local docker_gpg_f="/etc/apt/keyrings/docker.asc"
  local docker_list_f="/etc/apt/sources.list.d/docker.list"

  # Add Docker's official GPG key
  if [ ! -f "$docker_gpg_f" ]; then
    apt update
    apt install ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "${docker_gpg_f}"
    chmod a+r "${docker_gpg_f}"
  else
    Mbs:Io:print "Docker repo GPG key already added"
  fi

  # Add the repository to Apt sources
  if [ ! -f "$docker_list_f" ]; then
    # shellcheck disable=SC2034
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=$docker_gpg_f] \
        https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
      tee "${docker_list_f}" >/dev/null
    apt update
  else
    Mbs:Io:print "Docker repo already added"
  fi

  Mbs:Io:print "Docker APT repo added and configured"
  return 0
}
