#!/usr/bin/env bash

# FIXME: Merge with linux-init.sh

Mbs:AndroidInit:configGit() {
  Mbs:Io:print "Configuring basic Git settings"

  git config --global user.name "$MBS__AI__GIT_CONFIG__USERNAME"
  git config --global user.email "$MBS__AI__GIT_CONFIG__EMAIL"
  return 0
}
