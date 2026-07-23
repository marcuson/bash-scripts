#!/usr/bin/env bash

Mbs:LinuxInit:configGit() {
  Mbs:Io:print "Configuring basic Git settings"

  if ! Mbs:User:isNormal "$MBS__LI__USER"; then
    Mbs:Script:die "MBS__LI__USER problem, it must be set, it must be a normal user, it must exists"
  fi

  sudo -u "$MBS__LI__USER" sh -c "git config --global user.name \"$MBS__LI__GIT_CONFIG__USERNAME\""
  sudo -u "$MBS__LI__USER" sh -c "git config --global user.email \"$MBS__LI__GIT_CONFIG__EMAIL\""
  return 0
}
