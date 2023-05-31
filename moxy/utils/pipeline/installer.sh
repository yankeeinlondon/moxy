#!/usr/bin/env bash

function nix_add() {
    local pkg="${1:nix_add was called without any packages specified}"
    local rest=( "${@:2}" )
    local cmd="nix-env -iA nixpkgs.${pkg}"
    for p in "${rest[@]}"; do
        cmd="${cmd} nixpkgs.${p}"
    done

    eval "$cmd" || (error "problem running Nix's add command: ${cmd}" && exit 1)
    info "- Nix package manager used to install the following packages:"
    info "  ${DIM}${pkg}${rest[*]}${RESET}"
}

function nix_upgrade() {
    if nix-env --upgrade; then
        log "- Nix packages upgraded"
    else
        error "- ran into problems upgrading Nix package manager!"
    fi
}

function apt_add() {
    local pkg="${1:nix_add was called without any packages specified}"
    local rest=( "${@:2}" )
    local cmd="nix-env -iA nixpkgs.${pkg}"
    for p in "${rest[@]}"; do
        cmd="${cmd} ${p}"
    done
    cmd="${cmd} -y"

    eval "$cmd" || (error "problem running Nix's add command: ${cmd}" && exit 1)
    info "- APT package manager used to install the following packages:"
    info "  ${DIM}${pkg}${rest[*]}${RESET}"
}

function apt_upgrade() {
    if apt update && apt upgrade -y; then
        log "- APT packages upgraded"
    else
        error "- ran into problems upgrading APT!"
    fi
}


# given a distro name and ENV variables this function
# will return an API to add packages and update existing
function get_package_manager() {
    local -r distro="${1:?the distro was not provided to get_package_manager}"
    local add_cmd=""
    local upgrade_cmd=""

    if [[ "${PKG_MANAGER}" == "nix" ]]; then
        add_cmd=${nix_add}
        upgrade_cmd=${nix_upgrade}
    else
        # use the native pkg manager for the given distro
        case $distro in

            "ubuntu" | "debian" | "devuan")
                add_cmd=${apt_add}
                upgrade_cmd=${apt_upgrade}
                ;;
            "alpine")
                add_cmd=${apk_add}
                upgrade_cmd=${apk_upgrade}
                ;;
            "rocky")
                add_cmd=""
                upgrade_cmd=""
                ;;
            "arch")
                add_cmd=""
                upgrade_cmd=""
                ;;
            *)
                error "Invalid package manager \"${distro}\" passed to get_package_manager"
                exit 1
                ;;
        esac

    fi

    # API Surface
    local -A api=( add=${add_cmd} upgrade=${upgrade_cmd} )
    echo "${api[@]}"
}

function add_default_packages() {
    echo "TODO"
}

function add_default_ct_packages() {
    echo "TODO"
}

function add_default_vm_packages() {
    echo "TODO"
}

