#!/usr/bin/env bash

# shellcheck disable=SC1091
source "${PWD}/utils//shared.sh"

function is_valid_distro() {
    local -r distro="${1:no distro passed to valid_distro validation function}"
    local -a valid_choices=( "ubuntu" "debian" "alpine" "arch" "rocky" "devuan" )

    if list_contains "${distro}" "${valid_choices[@]}"; then
        return 0
    else
        return 1
    fi
}

function is_valid_constraint() {
    local -r constraint="${1:no constraint passed into is_valid_value}"
    local -ra valid_choices=( "numeric" "list" )
    if list_contains "${constraint}" "${valid_choices[@]}"; then
        return 0
    else
        return 1
    fi
}

function is_valid_constrained_value() {
    local -r constraint="${1:no constraint passed into is_valid_value}"
    local -ra _value=( "${@:1}" )

    if is_valid_constraint "${constraint}"; then
        echo "TEST CONSTRAINT"
    else
        error "An invalid constraint \"${constraint}\" was used in is_valid_constrained_value"
        return 1
    fi
}



# is_valid_ct_fn
#
# determines whether a given CT definition file produces enough information
# to be considered a valid base CT fn.
function is_valid_ct_fn() {
    local -r name="${1:the name of the CT definition was not passed to is_valid_ct_fn}"
    local -r filename="${2:the filename of the CT definition was not passed to is_valid_ct_fn}"
    local -ra required=( "type" "disk" "cpu" "ram" "os" "version" )
    local -A questions=()
    

    if has_required_params "${questions[@]}" "${required[@]}"; then
        return 0
    else 
        error ""
    fi
}

# is_valid_vm_fn
#
# determines whether a given file produces enough information
# to be considered a valid base VM fn.
function is_valid_vm_fn() {
    echo "TODO"
}

# is_valid_service_fn
#
# determines whether a given file produces enough information
# to be considered a valid service fn.
function is_valid_service_fn() {
    echo "TODO"
}
