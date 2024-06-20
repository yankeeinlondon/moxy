#!/usr/bin/env bash

# shellcheck source="./logging.sh"
source "./utils/logging.sh"

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


pve_version_check() {
    if is_pve_node; then
        # shellcheck disable=SC2046
        if [ $(pveversion | grep -c "pve-manager/7\.[0-9]") -eq 0 ]; then
            echo -e "${CROSS} This version of Proxmox Virtual Environment is not supported"
            echo -e "Requires PVE Version 7.0 or higher"
            echo -e "Exiting..."
            sleep 2
            exit
        fi
    else
        # check version with API
        log "API Version Check not implemented yet"
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
