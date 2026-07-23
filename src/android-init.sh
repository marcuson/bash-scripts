#!/usr/bin/env bash
# shellcheck disable=SC1091

# @describe Init a new Android machine.
# @meta version 0.0.1

set -euo pipefail

# !mbs keep
_this_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# !mbs include=android-init.mod/config.tpl.env
cfg_tpl_content=$(base64 -w0 "$_this_dir/android-init.mod/config.tpl.env")

# shellcheck source=utils.mod/io.sh
source "$_this_dir/utils.mod/io.sh"
# shellcheck source=utils.mod/script.sh
source "$_this_dir/utils.mod/script.sh"

# Constants
readonly progress_filename="progress"
readonly bw_filename="bw.sessions"

# @cmd Create a config template.
# @arg out-file Where to write the file. Defaults to $HOME/storage/shared/_marcdata/android-init/config.env
cfg() {
  Mbs:Io:print "Generate default config file"

  local cfg_f="${argc_out_file:-$HOME/storage/shared/_marcdata/android-init/config.env}"
  if [[ -f "$cfg_f" ]]; then
    if Mbs:Io:confirmDefaultNo "Config file already exists at $cfg_f, do you want to overwrite it?"; then
      Mbs:Io:debug "Overwrite config file $cfg_f"
    else
      Mbs:Io:print "Config file generation cancelled, exiting."
      exit 0
    fi
  fi

  cfg_d=$(dirname "$cfg_f")
  mkdir -p "$cfg_d"
  echo "$cfg_tpl_content" | base64 --decode >"$cfg_f"
  Mbs:Io:success "Config file generated at $cfg_f"
}

# @cmd run Load config and init the machine.
# @arg cfg-file Config file location. Defaults to $HOME/storage/shared/_marcdata/android-init/config.env
# @option -d --data-dir Data dir location. Defaults to $HOME/storage/shared/_marcdata/android-init/data
run() {
  Mbs:Io:print "Android init start"

  # Source utils
  # shellcheck source=utils.mod/var.sh
  . "$_this_dir/utils.mod/var.sh"
  # shellcheck source=bw.mod/bw.sh
  . "$_this_dir/bw.mod/bw.sh"

  local data_dir="${argc_data_dir:-$HOME/storage/shared/_marcdata/android-init/data}"
  local helper_f="$data_dir/${progress_filename}"
  export MBS__BW__HELPER_F="$data_dir/${bw_filename}"

  ai_modules_d="$_this_dir/android-init.mod"

  # Create helper files if not found
  mkdir -p "$data_dir"
  if [ ! -f "$helper_f" ]; then
    echo "0" | tee "$helper_f" >/dev/null
  fi

  if [ ! -f "$MBS__BW__HELPER_F" ]; then
    touch "$MBS__BW__HELPER_F" >/dev/null
  fi

  local cfg_file
  cfg_file="${argc_cfg_file:-$HOME/storage/shared/_marcdata/android-init/config.env}"
  Mbs:Var:importDotenv "$cfg_file"

  Mbs:Script:addTrapMultiSignal "Mbs:Bw:lock" INT TERM EXIT

  home_user_d="$HOME"

  helper_f_content=$(<"$helper_f")

  if [[ "$helper_f_content" == "1" ]]; then
    Mbs:Io:print "All config already done, exiting."
  elif [[ "$helper_f_content" == "0" ]]; then
    _run_step_0
  fi

  exit 0
}

function _run_step_0() {
  Mbs:Io:print "First init pass"

  # pkg - update
  Mbs:Io:printSep
  Mbs:Io:print "Updating packages"
  pkg update -y
  pkg upgrade -y
  echo "Packages updated"

  # PKG - install packages
  if Mbs:Var:isTrue "$MBS__AI__PKG_INSTALL_PACKAGES__IS_ENABLED"; then
    Mbs:Io:printSep
    # shellcheck source=android-init.mod/s0.pkg-install-pkgs.sh
    . "$ai_modules_d/s0.pkg-install-pkgs.sh"
    Mbs:AndroidInit:installPkgPackages || Mbs:Script:die "Failed to install PKG packages"
  fi

  # SSH - prepare
  Mbs:Io:printSep
  # shellcheck source=android-init.mod/s0.ssh-prepare.sh
  . "$ai_modules_d/s0.ssh-prepare.sh"
  Mbs:AndroidInit:prepareSSH || Mbs:Script:die "Failed to prepare SSH"

  # Git - config
  if Mbs:Var:isTrue "$MBS__AI__GIT_CONFIG__IS_ENABLED"; then
    Mbs:Io:printSep
    # shellcheck source=android-init.mod/s0.git-config.sh
    . "$ai_modules_d/s0.git-config.sh"
    Mbs:AndroidInit:configGit || Mbs:Script:die "Failed to configure Git"
  fi

  # Pass 0 done
  echo "1" | tee "$helper_f" >/dev/null
  Mbs:Io:printSep
  Mbs:Io:success "First part of the config done"
  Mbs:Io:print ""
  Mbs:Io:print "Please check sshd config using 'sudo sshd -t' command and fix any problem before rebooting"
  Mbs:Io:print "If the command sudo sshd -t has no output the config is ok"
  Mbs:Io:print ""
  Mbs:Io:print "Reboot to finalize the configuration"
}

eval "$(argc --argc-eval "$0" "$@")"
