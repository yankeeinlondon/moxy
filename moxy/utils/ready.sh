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

function ensure_curl() {
    if ! has_command "curl"; then
        error "- to use moxy on a non-pve node you'll need to have 'curl' installed"
        exit 1
    fi
}

function ensure_bash() {
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
}

function  ensure_tui() {
    if ! ui_availability; then
        log "- you must have either the ${BOLD}display${RESET} ${ITALIC}or${RESET} ${BOLD}whiptail${RESET} to run the TUI on Moxy"
        log "  - all debian distributions and therefore all PVE nodes will have whiptail"
        log "  - if you're on macOS, then ${BOLD}display${RESET} is available ${BOLD}brew${RESET}"
        log "  - otherwise do a little google research and see if you can get onto your platform"
        log "  - rerun moxy after you've installed"
        log ""
        exit 1
    fi
}

function ensure_jq() {
    if ! has_command "jq"; then
        log "- you must have ${BOLD}${GREEN}jq${RESET} available on your system to run Moxy"
        log "- it is a very popular library and should be available on every platform"
        exit 1
    fi
}

function  ensure_dependant_programs() {
    ensure_bash
    ensure_curl
    ensure_tui
    ensure_jq
}

function ensure_config_dir() {
    if ! config_file_exists; then
        if has_env "MOXY_CONFIG_FILE"; then
            local -r config_dir=$(remove_file_from_filepath  "$MOXY_CONFIG_FILE")
            if not_empty "$config_dir"; then
                ensure_directory "$config_dir"
            else
                error "The configuration directory resolved to an empty string!" 1
            fi
        else
            error "no MOXY_CONFIG_FILE env variable is set!"
        fi
    fi
}

function configure_non_pve_node() {
    if ! is_pve_node; then
        
        
        if ! config_has "API_TOKEN"; then
            if ! has_env "PVEAPIToken"; then
                title="Save API Token\n\nYou are not on a PVE node so we will need to use the Proxmox API:\n\n  - to do that we will need an API_KEY\n  - you can provide the ENV variable PVEAPIToken\n  - however, we can store your key in ~/.moxy\n  - permissions will be set so only you can access it\n\n\n  - if you don't have a key you can create via UI\n\nIf you'd prefer just to use ENV vars then exit, export the variable and run moxy again. \n\n";

                declare -A token=(
                    [title]="${title}"
                    [backmsg]="Proxmox Config"
                    [height]=23
                    [width]=60
                    [ok]="Save API Key"
                    [cancel]="Exit"
                    [on_cancel]="exit"
                    [exit_msg]="${GREEN}PVEAPIToken${RESET} ENV variable and then reload Moxy."
                )

                API="$(ask_inputbox token )"

                if [ "${#API}" -lt 8 ]; then
                    clear
                    clear
                    log ""
                    log ""
                    error "The API key you passed in was too short [${#API} characters], please refer to the Promox docs for how to generate the key and test it out with Postman (or equivalent) if you're unsure if it's right"
                    exit 1
                fi
                
                # for consistency sake, make sure the leading 
                # 'PVEAPIToken=' is not included and we'll add
                # it into the Authorization header when we need it
                API_TOKEN="$(strip_leading "PVEAPIToken=" "${API}")"
                update_config "API_TOKEN" "${API_TOKEN}" "true"

                # also make this token the "default token" as right
                # now it is the only token
                update_config "DEFAULT_TOKEN" "${API_TOKEN}"
                
            fi
        fi

        if ! file_contains "${MOXY_CONFIG_FILE}" "NODE="; then


            declare -Ar _node=(
                [title]="Add PVE Node\n\nIn order to start we will need at least one PVE node to work on. If you choose a node that is a cluster node then all of the nodes in the cluster will be made available\n\nPlease enter the IPv4 address of your first node:"
                [backmsg]="Proxmox Config"
                [width]=60
                [height]=23
                [ok]="Add Node"
                [cancel]="Exit"
                [on_exit]="exit"

            )

            NODE="$(ask_inputbox _node)"

            printf "%s\n" "NODE=${NODE}" >> "${HOME}/.moxy"
            chmod 600 "${HOME}/.moxy"
        fi
    fi
}

function configure_preferences() {
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

function ensure_proper_configuration() {
    # ALL REQUIRED PROGRAMS INSTALLED; NOW CHECK CONFIG

    ensure_config_dir
    configure_non_pve_node
    pve_version_check

    configure_preferences
}

function test_if_ready_to_start() {
    ensure_dependant_programs
    ensure_proper_configuration

    make_config_secure
}
