#!/usr/bin/env bash

# Tests whether a user is ready to start using Moxy

# shellcheck source="./env.sh"
. "./utils/env.sh"
# shellcheck source="./errors.sh"
. "./utils/errors.sh"
# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./conditionals.sh"
. "./utils/conditionals.sh"
# shellcheck source="./mutate.sh"
. "./utils/mutate.sh"
# shellcheck source="./info.sh"
. "./utils/info.sh"
# shellcheck source="./proxmox.sh"
. "./utils/proxmox.sh"


if ! ui_availability; then
    log "- you must have either the ${BOLD}display${RESET} ${ITALIC}or${RESET} ${BOLD}whiptail${RESET} to run the TUI on Moxy"
    log "  - all debian distributions and therefore all PVE nodes will have whiptail"
    log "  - if you're on macOS, then ${BOLD}display${RESET} is available ${BOLD}brew${RESET}"
    log "  - otherwise do a little google research and see if you can get onto your platform"
    log "  - rerun moxy after you've installed"
    log ""
    exit 1
fi

if ! has_command "jq"; then
    log "- you must have ${BOLD}${GREEN}jq${RESET} available on your system to run Moxy"
    log "- it is a very popular library and should be available on every platform"
    exit 1
fi

if ! is_pve_node; then
    if ! has_command "wget"; then
        error "- to use moxy on a non-pve node you'll need to have 'wget' installed"
        exit 1
    fi
    
    if ! file_contains "${MOXY_CONFIG}" "API_TOKEN"; then
        if ! has_env "PVEAPIToken"; then
            msg="Save API Token\n\nYou are not on a PVE node so we will need to use the Proxmox API:\n\n  - to do that we will need an API_KEY\n  - you can provide the ENV variable PVEAPIToken\n  - however, we can store your key in ~/.moxy\n  - permissions will be set so only you can access it\n\n\n  - if you don't have a key you can create via UI\n\nIf you'd prefer just to use ENV vars then exit, export the variable and run moxy again. \n\n";

            API="$(ask_inputbox "${msg}" 23 60 "Save Key" "Exit" "- add ${GREEN}PVEAPIToken${RESET} ENV variable and then reload Moxy.")"

            if [ "${#API}" -lt 8 ]; then
                clear
                log ""
                log ""
                error "The key you passed in was too short [${#API} characters], please refer to the Promox docs for how to generate the key and test it out with Postman or equivalent if you're unsure if it's right"
                exit 1
            fi

            printf "%s\n" "API_TOKEN=$(strip_leading "PVEAPIToken=" "${API}")" >> "${HOME}/.moxy"
            printf "%s\n" "DEFAULT_TOKEN=$(strip_leading "PVEAPIToken=" "${API}")" >> "${HOME}/.moxy"
            chmod 600 "${HOME}/.moxy"
        fi
    fi

    if ! file_contains "${MOXY_CONFIG}" "NODE="; then

        msg="Add PVE Node\n\nIn order to start we will need at least one PVE node to work on. If you choose a node that is a cluster node then all of the nodes in the cluster will be made available\n\nPlease enter the IPv4 address of your first node:"

        NODE="$(ask_inputbox "${msg}" 23 60 "Add Node" "Exit")"

        printf "%s\n" "NODE=${NODE}" >> "${HOME}/.moxy"
        chmod 600 "${HOME}/.moxy"
    fi
fi

pve_version_check;


if file_contains "${MOXY_CONFIG}" "API_TOKEN"; then
    KEY=$(find_in_file "${MOXY_CONFIG}" "API_TOKEN") || error "could not find API_TOKEN"
    

fi
