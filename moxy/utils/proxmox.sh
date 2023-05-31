#!/usr/bin/env bash

# shellcheck disable=1091
source "${MOXY}/utils/shared.sh"

# is_pve_node
#
# Returns an exit code which indicates whether the given machine is
# a PVE node.
function is_pve_node() {
    set +e
    # shellcheck disable=SC2009
    ps -ef | grep pvedaemon | grep -v grep
    catch_errors

    return $?
}

# next_container_id
#
# returns the lowest available container id on a PVE node
function next_container_id() {
    if is_pve_node; then
        local -r cid=$(pvesh get /cluster/nextid)
        echo "$cid"
        return 0
    else
        error "called next_container_id() on a non PVE node [${HOST}]!"
        return 1
    fi
}
