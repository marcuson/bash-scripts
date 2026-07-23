#!/usr/bin/env bash

Mbs:LinuxInit:configGit() {
  Mbs:Io:print "Configuring basic Git settings"

  if ! Mbs:User:isNormal "$LI__USER"; then
    Mbs:Script:die "LI__USER problem, it must be set, it must be a normal user, it must exists"
  fi

  sudo -u "$LI__USER" sh -c "git config --global user.name \"$LI__GIT_CONFIG__USERNAME\""
  sudo -u "$LI__USER" sh -c "git config --global user.email \"$LI__GIT_CONFIG__EMAIL\""
  return 0
}
