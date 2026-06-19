#!/usr/bin/env bash

LinuxInitMod:installSops() {
    IO:print "Installing sops"

    local sops_version
    local pc_arch

    case "$(uname -m)" in
    x86_64 | amd64)
        pc_arch=amd64
        ;;
    aarch64 | arm64)
        pc_arch=arm64
        ;;
    *)
        IO:alert "Unsupported architecture: $(uname -m)"
        return 1
        ;;
    esac

    # Get latest SOPS version from GitHub releases
    sops_version=$(curl -fsSL https://api.github.com/repos/getsops/sops/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')
    if [ -z "$sops_version" ]; then
        IO:alert "Unable to detect latest sops version"
        return 1
    fi

    curl -L --output sops "https://github.com/getsops/sops/releases/download/${sops_version}/sops-${sops_version}.linux.${pc_arch}"
    mv -f sops /usr/local/bin/sops
    chmod +x /usr/local/bin/sops

    return 0
}
