#!/usr/bin/env bash


# shellcheck source="./env.sh"
. "./utils/env.sh"
# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./info.sh"
. "./utils/info.sh"
# shellcheck source="./mutate.sh"
. "./utils/mutate.sh"
# shellcheck source="./errors.sh"
. "./utils/errors.sh"
# shellcheck source="./fetch.sh"
. "./utils/fetch.sh"

# is_pve_node
#
# Returns an exit code which indicates whether the given machine is
# a PVE node or not.
function is_pve_node() {
    if has_command "pveversion"; then
        debug "is_pve_node" "is a pve node"
        return 0
    else
        debug "is_pve_node" "is NOT a pve node"
        return 1
    fi
}

function set_default_token() {
    local -r token="${1:?no URL was passed to fetch_get()}"

    replace_line_in_file "${MOXY_CONFIG}" "DEFAULT_API" "DEFAULT_API=${token}"
}


# get_default_node()
#
# Gets the address for the "default host" for PVE.
function get_default_node() {
    local -r def_node=$(find_in_file "${MOXY_CONFIG}" "DEFAULT_NODE")

    if not_empty "$def_node"; then
        echo "${def_node}"
        return 0
    else
        # shellcheck disable=SC2207
        local -ra all_nodes=($(findall_in_file "${MOXY_CONFIG}" "API_TOKEN"))

        if  [[ $(length "${all_nodes[@]}") -gt 0 ]]; then
            echo "${all_nodes[0]}"
            return 0
        else
            return 1
        fi
    fi
}

# pve_version
#
# Provides the PVE version of the current node (if a PVE node)
# or the DEFAULT_NODE setting in the configuration if a remote
# node.
function pve_version() {
    if is_pve_node; then
        local version
        version="$(pveversion)"
        version="$(strip_before "pve-manager/" "${version}")"
        version="$(strip_after_last "/"  "${version}")"

        echo "${version}"
        return 0
    else
        local -r version="$(get_pve_version)"

        echo "${version}"
        return 0
    fi
}

# pve_version_check()
# 
# Validates that the PVE version is the minimum required.
# It uses `pveversion` command when directly no a host 
# but otherwise relies on the API.
function pve_version_check() {
    local -r version="$(pve_version)"
    # shellcheck disable=SC2207
    local -ri major=( $(major_version "${version}") )

    if [[ major -lt 7  ]]; then
        log "You are running version ${version} of Proxmox but the scripts\nin Moxy require at least version 7."
        log ""
        log "Please consider upgrading."
        log ""
        exit
    fi

}



function has_proxmox_api_key() {
    log ""
}

# next_container_id
#
# If executing on a PVE node it will return the lowest available
# PVE ID in the cluster.
function next_container_id() {
    if is_pve_node; then
        local -r cid=$(pvesh get /cluster/nextid)
        echo "$cid"
        return 0
    else
        printf "%s" "$(get_next_container_id "")"
        return 0
    fi
}

function get_pvesh() {
    local -r path=${1:?no path provided to get_pvesh())}
    local -r filter=${2:-}

    local request
    request="$(printf "%s" "$(pvesh get "${path}" --output-format=json)")"

    if not_empty "${response}" && not_empty "${filter}"; then
        debug "get_pve(${path})" "got a response, now filtering with: ${filter}"

        local -r response="$(printf "%s" "${request}" | jq --raw-output "${filter}")" || error "Problem using jq with filter '${filter}' on a response [${#request} chars] from the URL ${url}"
        printf "%s" "${response}"
    else 
        debug "get_pve(${path})" "got a response [${#request} chars], no filter to apply"
        echo "${request}"
    fi
}

function pve_resources() {
    local resources
    if is_pve_node; then
        resources="$(get_pvesh "/cluster/resources" ".data")"
    else 
        resources="$(get_pve "/cluster/resources" ".data")"
    fi

    printf "%s" "$(list "${resources}")"
}

function pve_lxc_containers() {
    local -r path="/cluster/resources"
    local -r filter=".data | map(select(.type == \"lxc\"))"
    local resources
    if is_pve_node; then
        resources="$(get_pvesh "${path}" "${filter}")"
    else 
        resources="$(get_pve "${path}" "${filter}")"
    fi

    printf "%s" "${resources}"
}

function pve_vm_containers() {
    local -r path="/cluster/resources"
    local -r filter=".data.[] | select(.type == \"qemu\")"
    local resources
    if is_pve_node; then
        resources="$(get_pvesh "${path}" "${filter}")"
    else 
        resources="$(get_pve "${path}" "${filter}")"
    fi

    printf "%s" "$(list "${resources}")"
}

function pve_storage() {
    local -r path="/cluster/resources"
    local -r filter=".data.[] | select(.type == \"storage\")"
    local resources
    if is_pve_node; then
        resources="$(get_pvesh "${path}" "${filter}")"
    else 
        resources="$(get_pve "${path}" "${filter}")"
    fi

    printf "%s" "$(list "${resources}")"
}

function pve_sdn() {
    local -r path="/cluster/resources"
    local -r filter=".data | map(select(.type == \"sdn\"))"
    local resources
    if is_pve_node; then
        resources="$(get_pvesh "${path}" "${filter}")"
    else 
        resources="$(get_pve "${path}" "${filter}")"
    fi

    printf "%s" "$(list "${resources}")"
}

function pve_nodes() {
    local nodes
    if is_pve_node; then
        nodes=$(get_pvesh "/nodes" ".data")
    else
        nodes="$(get_pve "/nodes" ".data")"
    fi

    printf "%s" "$(list "${nodes}")"
}

function pve_node_config() {
    local nodes
    if is_pve_node; then
        nodes=$(get_pvesh "/cluster/config/nodes" ".data")
    else
        nodes="$(get_pve "/cluster/config/nodes" ".data")"
    fi

    printf "%s" "$(list "${nodes}")"
}
