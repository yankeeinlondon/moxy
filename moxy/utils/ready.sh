#!/usr/bin/env bash

# Tests whether a user is ready to start using Moxy

# shellcheck source="./proxmox.sh"
source "./utils/proxmox.sh"

# shellcheck source="./interactive/ask.sh"
source "./utils/interactive/ask.sh"



if ! ui_availability; then
    log "- you must have either the ${BOLD}display${RESET} ${ITALIC}or${RESET} ${BOLD}whiptail${RESET} to run the TUI on Moxy"
    log "  - all debian distributions and therefore all PVE nodes will have whiptail"
    log "  - if you're on macOS, then ${BOLD}display${RESET} is available ${BOLD}brew${RESET}"
    log "  - otherwise do a little google research and see if you can get onto your platform"
    log "  - rerun moxy after you've installed"
    log ""
    exit 1
fi

if ! is_pve_node; then
    if ! has_command "wget"; then
        error "- to use moxy on a non-pve node you'll need to have 'wget' installed"
        exit 1
    fi
    CONFIG=$(get_moxy_config)
    if ! contains "$CONFIG" "API_KEY"; then
        if ! has_env "PVEAPIToken"; then
            msg="Save API Token\n\nYou are not on a PVE node so we will need to use the Proxmox API:\n\n  - to do that we will need an API_KEY\n  - you can provide the ENV variable PVEAPIToken\n  - however, we can store your key in ~/.moxy\n  - permissions will be set so only you can access it\n\n\n  - if you don't have a key you can create via UI\n\nIf you'd prefer just to use ENV vars then exit, export the variable and run moxy again. \n\n";

            ask_password "${msg}" 23 60 "Save Key" "Exit" "- add ${GREEN}PVEAPIToken${RESET} ENV variable and then reload Moxy"
        fi
    fi
fi

