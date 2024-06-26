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
# shellcheck source="./interactive/ask.sh"
. "./utils/interactive/ask.sh"
# shellcheck source="./preferences.sh"
. "./utils/preferences.sh"
# shellcheck source="./file.sh"
. "./utils/file.sh"

function test_if_ready_to_start() {

    if using_bash_3; then

cat <<"EOF"
                ______.------.
            /'              \
            /'\               \
        ..-'\()'\    .'''.    ./'
        |                .'    /
        \..}                '\.
        /     {      /'  '\   \
        {------'    .'      '.  '|
        \        . |         \   |
        '\_____/  |          |   |
        /       |           |    |
        .'       |            |   |
        |       |            |     |
        |      |            |     |
        |                  |       \
                                    |
EOF
        log ""
        log "Yuck! You are using an ancient ${GREEN}bash${RESET} version: ${BOLD}$(bash_version)${RESET}!"
        log ""
        log "In order to use ${BOLD}Moxy${RESET} you'll need ${ITALIC}at least${RESET} version 4 of bash"
        log "and any package manager worth it's grain in salt will give you"
        log "version 5.x of bash."
        log ""

        if starts_with "macos" "$(os)";then
            log "Noticed that you're running on macOS and that's likely why"
            log "you're on such an old version. Apple's OS is ${ITALIC}way${RESET} behind"
            log "WRT to ${GREEN}bash${RESET} but the ${BOLD}Homebrew${RESET} package manager has a modern version."
            log ""
            if has_command "brew";then
                log "I see you have ${BOLD}Homebrew${RESET} installed, would you like to upgrade"
                if text_confirm "now?"; then
                    # install newer version of bash via homebrew
                    brew update
                    brew install bash
                    eval "$(brew shellenv)"
                    log ""
                    log ""
                    log "- bash has been installed [$(bash_version)]"
                    log "- you might have to re-source your shell to ensure the\n  the new ${GREEN}bash${RESET} is in the path"
                    log ""

                else 
                    log "don't"
                fi
                log ""
            else
                log "You don't have ${BOLD}Homebrew${RESET}(${DIM}https://brew.sh/${RESET}) so I'll let you upgrade"
                log "to the latest ${GREEN}bash${RESET} yourself before trying ${BOLD}Moxy${RESET} again."
                log ""
            fi
        else
            log "Use your package manager to install a newer version of ${GREEN}bash${RESET}"
            log "and then rerun ${BOLD}Moxy${RESET}"
            log ""
        fi

        exit
    fi

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

    if [[ "$MOXY_CONFIG_FILE" == "${HOME}/.config/moxy/moxy.toml" ]]; then
        ensure_directory "${HOME}/.config"
        ensure_directory "${HOME}/.config/moxy"
    else
        ensure_directory "$(strip_after "/moxy.toml" "$MOXY_CONFIG_FILE")"
    fi

    if ! is_pve_node; then
        if ! has_command "wget"; then
            error "- to use moxy on a non-pve node you'll need to have 'wget' installed"
            exit 1
        fi
        
        if ! file_contains "${MOXY_CONFIG_FILE}" "API_TOKEN"; then
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

        if ! file_contains "${MOXY_CONFIG_FILE}" "NODE="; then

            msg="Add PVE Node\n\nIn order to start we will need at least one PVE node to work on. If you choose a node that is a cluster node then all of the nodes in the cluster will be made available\n\nPlease enter the IPv4 address of your first node:"

            NODE="$(ask_inputbox "${msg}" 23 60 "Add Node" "Exit")"

            printf "%s\n" "NODE=${NODE}" >> "${HOME}/.moxy"
            chmod 600 "${HOME}/.moxy"
        fi
    fi

    pve_version_check;

    if ! file_contains "${MOXY_CONFIG_FILE}" "DEFAULT_DISTRO"; then
        preferred_distro
    fi

    if ! file_contains "${MOXY_CONFIG_FILE}" "SUDO_USER"; then
        sudo_user
    fi

    if ! file_contains "${MOXY_CONFIG_FILE}" "DEFAULT_SSH"; then
        ssh_access
    fi


}

