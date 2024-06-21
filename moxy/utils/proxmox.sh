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
    local return_code=0
    allow_errors
    # shellcheck disable=SC2009
    ps -ef | grep pvedaemon | grep -v grep
    return_code=$?
    catch_errors

    if [[ "${return_code}" == "0" ]]; then
        debug "is_pve_node" "detected as PVE node"
        return 0
    else
        debug "is_pve_node" "is NOT a PVE node"
        # shellcheck disable=SC2086
        return ${ERR_NOT_PVE_NODE}
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
        version=$(pveversion)
        version="$(strip_after_last "/"  "$(version)")"
        version="$(retain_after "/" "${version}")"

        echo "${version}"
    else
        local -r version="$(get_pve_version)"

        echo "${version}"
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
# PVE ID in the cluster. If running external to the cluster it use
# the DEFAULT_TEMPLATE_ID environment variable.
function next_container_id() {
    local -r current=$(pause_errors)
    if is_pve_node; then
        log "IS PVE NODE"
        catch_errors
        local -r cid=$(pvesh get /cluster/nextid)
        echo "$cid"
        catch_errors
        return 0
    else
        restore_errors "$current"
        echo "${DEFAULT_TEMPLATE_ID}"
        return 0
    fi
}
