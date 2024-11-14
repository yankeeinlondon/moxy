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


IS_FIRST_TIME=0

function ensure_curl() {
    if ! has_command "curl"; then
        error "- to use moxy on a non-pve node you'll need to have 'curl' installed"
        exit
    fi
}

function ensure_bash() {
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
                log "Since you don't appear to have ${BOLD}Homebrew${RESET} installed, we'll let you upgrade"
                log "your version of bash and rerun Moxy when you're ready"
                log ""
                exit
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
    if using_bash_3; then
        ensure_bash
    fi
    ensure_curl
    ensure_tui
    ensure_jq
}

# makes sure the directory where the config file is supposed to be
# is created
function ensure_config_dir() {
    if ! config_file_exists; then
        if has_env "MOXY_CONFIG_FILE"; then
            local -r config_dir=$(remove_file_from_filepath  "${MOXY_CONFIG_FILE}")
            ensure_directory "${config_dir}"
        else
            error "no MOXY_CONFIG_FILE env variable is set!" 1
        fi
    fi
}

function ensure_config_file() {
    if has_env "MOXY_CONFIG_FILE"; then

        if ! file_exists "$MOXY_CONFIG_FILE"; then
            if touch "${MOXY_CONFIG_FILE}"; then
                debug "ensure_config_file" "created config file at ${MOXY_CONFIG_FILE}"
                return 0
            else
                panic "Attempt to create configuration file at ${BLUE}${MOXY_CONFIG_FILE}${RESET} failed! Please create this file and restart moxy"
            fi
        else
            panic "call to ensure_config_file() prior to MOXY_CONFIG_FILE being set!"
        fi
    fi
}

function configure_non_pve_node() {
    if ! is_pve_node; then
        if ! config_has "API_TOKEN"; then
            if ! has_env "PVEAPIToken"; then
                declare -A token=(
                    [title]="Save API Token\n\nYou are not on a PVE node so we will need to use the Proxmox API:\n\n  - to do that we will need an API_KEY\n  - you can provide the ENV variable PVEAPIToken\n  - however, we can store your key in ~/.config/moxy/config.toml\n  - permissions will be set so only you can access it\n\n\n  - if you don't have a key you can create via UI\n\nIf you'd prefer just to use ENV vars then exit, export the variable and run moxy again. \n\n"
                    [backmsg]="Proxmox Config"
                    [height]=23
                    [width]=60
                    [ok]="Save API Key"
                    [cancel]="Exit"
                    [on_cancel]="exit"
                    [exit_msg]="${GREEN}PVEAPIToken${RESET} ENV variable and then reload Moxy."
                )

                API="$(ask_inputbox token )"

                if is_empty "$API"; then
                    panic "Didn't get a valid API Token; quiting"
                fi

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

        if ! config_has "NODE"; then

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

            if is_empty "$NODE"; then
                panic "Didn't receive an IP address for you're first Proxmox Node; quiting."
            else
                update_config "NODE" "$NODE" "true"
                update_config "DEFAULT_NODE" "$NODE"
            fi

            # printf "%s\n" "NODE=${NODE}" >> "${HOME}/.moxy"
        fi
    fi
}

function specify_config_dir() {
    if initialize_config; then
        # config file exists at current ENV state
        # so nothing to do
        return 0
    else
        if has_env "MOXY_CONFIG_FILE"; then
            # ENV set but no file
            log "It appears that you have set the ${BOLD}MOXY_CONFIG_FILE${RESET}"
            log "but that this file doesn't exist yet."
            log ""
            log "Should we create it for you and help you get it configured with a"
            log "base configuration (${DIM}${MOXY_CONFIG_FILE}${RESET})?"
            if ! text_confirm "Create config file" "y"; then
                log ""
                log "Ok, no problem ... see you soon"
                log ""

                exit 0
            else
                # set configuration to ENV
                ensure_config_dir
                ensure_config_file
            fi
        else
            # no ENV and no known config file location
            local -r title="Moxy Config File\n\nMoxy needs to be able to save it's configuration state to the file system. There are two standard locations which you can choose from below.\n\n- the ~/.config/moxy/config.toml option resides in a location which is often shared between computers\n\n- whereas the ~/.moxy location can keep the config isolated to a single machine\n\nUltimately the final option is to set the MOXY_CONFIG_FILE env variable to another location. If you want to do that now then choose 'Exit' button and run moxy again\n$(nbsp)"
            local -ra location_choices=( 
                '.config' "$(space_to_nbsp "${HOME}/.config/moxy/config.toml")" ON
                'Home' "$(space_to_nbsp "${HOME}/.moxy")" OFF
            )
            local -rA _where=(
                [title]="${title}"
                [backmsg]="Moxy Configuration"
                [choices]="${location_choices[@]}"
                [height]=26
                [ok]="Set Location"
                [cancel]="Exit"
            )
            local -r location="$(ask_radiolist _where)"

            if is_empty "$location"; then
                clear;
                log ""
                log "- set the MOXY_CONFIG_FILE env variable and run Moxy again"
                log ""
                exit 0
            else
                if [[ "$location" == ".config"  ]]; then 
                    set_env "MOXY_CONFIG_FILE" "${HOME}/.config/moxy/config.toml"
                else
                    set_env "MOXY_CONFIG_FILE" "${HOME}/.moxy"
                fi
                ensure_config_dir
                ensure_config_file
            fi
        fi
    fi
}

function set_other_defaults() {
    if configuration_missing "DEFAULT_LXC_DISK"; then
        update_config "DEFAULT_LXC_DISK" "1024"
    fi
    if configuration_missing "DEFAULT_VM_DISK"; then
        update_config "DEFAULT_VM_DISK" "8192"
    fi

    if configuration_missing "DEFAULT_LXC_RAM"; then
        update_config "DEFAULT_LXC_RAM" "1024"
    fi
    if configuration_missing "DEFAULT_VM_RAM"; then
        update_config "DEFAULT_VM_RAM" "2048"
    fi

    if configuration_missing "DEFAULT_LXC_CORES"; then
        update_config "DEFAULT_LXC_CORES" "1"
    fi
    if configuration_missing "DEFAULT_VM_CORES"; then
        update_config "DEFAULT_VM_CORES" "1"
    fi

    if configuration_missing "DEFAULT_VLAN"; then
        update_config "DEFAULT_VLAN" "none"
    fi
    if configuration_missing "DEFAULT_DISABLE_IP6"; then
        update_config "DEFAULT_DISABLE_IP6" "false"
    fi
    if configuration_missing "DEFAULT_BRIDGE"; then
        update_config "DEFAULT_BRIDGE" "vmbr0"
    fi

    if configuration_missing "PREFER_NALA_OVER_APT"; then
        update_config "PREFER_NALA_OVER_APT" "true"
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

    set_other_defaults
}

function ensure_proper_configuration() {
    # ALL REQUIRED PROGRAMS INSTALLED; NOW CHECK CONFIG
    specify_config_dir
    configure_non_pve_node
    pve_version_check
    configure_preferences
}

function is_first_time() {
    if initialize_config; then
        return 1
    else
        return 0
    fi
}

function test_if_ready_to_start() {
    if is_first_time; then
        ensure_dependant_programs
        ensure_proper_configuration

        make_config_secure
    fi
}
