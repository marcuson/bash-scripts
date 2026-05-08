#!/usr/bin/env bash

LinuxInitMod:configGit() {
  IO:print "Configuring basic Git settings"

  LinuxInitMod:ensureVar LI__USER "normal user name"

  if ! LinuxInitMod:isNormalUser "$LI__USER"; then
    IO:die "LI__USER problem, it must be set, it must be a normal user, it must exists"
  fi

  LinuxInitMod:ensureVar "LI__GIT_CONFIG__USERNAME" "Git username (first_name last_name)"
  LinuxInitMod:ensureVar "LI__GIT_CONFIG__EMAIL" "Git email"

  sudo -u "$LI__USER" sh -c "git config --global user.name \"$LI__GIT_CONFIG__USERNAME\""
  sudo -u "$LI__USER" sh -c "git config --global user.email \"$LI__GIT_CONFIG__EMAIL\""
  return 0
}
