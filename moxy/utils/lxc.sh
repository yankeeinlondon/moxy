#!/usr/bin/env bash

# shellcheck source="./logging.sh"
. "./utils/logging.sh"

export LXC_DISTROS=(debian ubuntu centos )


# list_services()
# 
# prints a list of all the distros which a user can
# choose from.
function list_lxc_distros() {
    log "Available LXC Distros:"
    log ""
    
}
