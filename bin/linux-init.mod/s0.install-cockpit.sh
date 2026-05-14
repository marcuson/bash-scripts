#!/usr/bin/env bash

IO:print() {
    echo $1
}

IO:alert() {
    echo ">>> $1"
}

_tryRepo() {
    local repo="$1"
    local apt_exit_code
    local apt_output

    IO:print "Trying to search Cockpit in '$repo' APT repository"

    apt_output=$(apt list -t "$repo" "cockpit" 2>/dev/null)
    apt_exit_code="$?"

    if [ "$apt_exit_code" == "100" ]; then
        # 100 means repo is not available, probably it is the case for newer versions
        return 1
    elif [ "$apt_exit_code" == "0" ]; then
        if awk 'NR > 1 && NF' <<<"$apt_output" | grep -q .; then
            return 0
        fi
        return 1
    else
        IO:alert "Error during APT list for Cockpit"
        return 1
    fi
}

LinuxInitMod:installCockpit() {
    IO:print "Installing Cockpit"

    local version_codename
    local repos
    local repo_to_use

    # shellcheck disable=SC2034
    version_codename=$(. /etc/os-release && echo ${VERSION_CODENAME})
    repos="${version_codename}-backports,${version_codename}"

    # split the comma-separated repo list and try each one in turn
    for repo in ${repos//,/ }; do
        if _tryRepo "$repo"; then
            IO:print "Cockpit package found in '$repo' repository"
            repo_to_use="$repo"
            break
        fi
    done

    if [ "$repo_to_use" == "" ]; then
        IO:alert "Cockpit not found in any APT repository: $repos"
        return 1
    fi

    apt install -y -t "$repo_to_use" cockpit cockpit-sosreport cockpit-files

    if nmcli -o -t | grep cockpitfake0 1>/dev/null 2>&1; then
        IO:print "Cockpit fake connection already exists, skipping creation"
    else
        IO:print "Creating Cockpit fake connection for package updates"
        nmcli con add type dummy con-name cockpit-fake-conn ifname cockpitfake0 ip4
    fi

    IO:print "Installing plugins"
    mkdir -p /usr/share/cockpit/sensors
    wget -O - https://github.com/ocristopfer/cockpit-sensors/releases/latest/download/cockpit-sensors.tar.xz |
        tar -Jxf - --strip-components=2 -C /usr/share/cockpit/sensors cockpit-sensors/dist
    return 0
}

LinuxInitMod:installCockpit
