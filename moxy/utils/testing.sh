#!/usr/bin/env bash

source "${PWD}/shared.sh";

# ui_availability() → [whiptail|dialog|ERROR]
#
# tests whether "whiptail" or "display" 
# (https://invisible-island.net/dialog/) packages are 
# available on the execution platform. For PVE hosts 
# -- or any Debian OS -- "whiptail" should always be available.
function ui_availability() {
    if has_command "whiptail"; then
        echo "whiptail" "has whiptail"
        return 0
    elif has_command "dialog"; then
        debug "ui_availability" "no whiptail but has dialog"
        echo "dialog"
        return 0
    else
        debug "ui_availability" "neither whiptail nor dialog found on host"
        return 1
    fi
}

ui_availability
