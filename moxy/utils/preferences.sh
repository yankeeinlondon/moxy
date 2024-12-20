#!/usr/bin/env bash

# shellcheck source="./env.sh"
. "./utils/env.sh"
# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./mutate.sh"
. "./utils/mutate.sh"
# shellcheck source="./interactive/ask.sh"
. "./utils/interactive/ask.sh"


export DISTRO_CHOICES=(
    "Alpine_3.18" "3.18" OFF
    "Debian_10" "Buster" OFF
    "Debian_11" "Bullseye" OFF
    "Debian_12" "Bookworm" ON
    "Ubuntu_20_04" "$(space_to_nbsp "Focal (LTS)")" OFF
    "Ubuntu_22_04" "$(space_to_nbsp "Jammy (LTS)")" OFF
    "Ubuntu_23_04" "Lunar" OFF
    "Ubuntu_24_04" "$(space_to_nbsp "Noble (LTS)")" OFF
    "Fedora_38" "6.2" OFF
    "Fedora_39" "6.5" OFF
    "Fedora_40" "6.8" OFF
    "CentOS_8" "v8" OFF
    "CentOS_9" "v9" OFF
    "NixOS_23.05" "Sloat" OFF
    "NixOS_23.11" "Tapir" OFF
    "NixOS_24_05" "Uakari" OFF
)

function preferred_distro() {
    clear

    # shellcheck disable=SC2034
    local -rA radio=( 
        [title]="What would like your default distro choice to be?" 
        [backmsg]="Moxy Preferences" 
        [width]=60 
        [height]=23  
        [radio_height]=12 
        [choices]="${DISTRO_CHOICES[@]}"
        [exit_msg]="Ok, see you later ..."
    )

    clear
    local -r distro=$(ask_radiolist radio)
    if is_empty "distro"; then
        update_config "DEFAULT_DISTRO" "Debian_12"
    else
        update_config "DEFAULT_DISTRO" "$distro"
    fi
}


function sudo_user() {
    clear

    # shellcheck disable=SC2034
    local -rA yn=(
        [title]="Create a sudo user?\n\nAs a default when you create a container, do you want to create a user other than just the 'root' user who will be the primary user you will login in with and whom is part of the sudoers group?\n\nYou will be given the chance to override this default whenever you create a container."
        [backmsg]="Moxy Preferences"
        [width]=60
        [height]=23
        [yes]="Yes"
        [no]="No"
    )

    if ask_yes_no yn; then
        local -rA _username=(
            [title]="What should the sudo-users's username be?\n\nPlease remember what you're setting here is just the default value and whenever you create a container you'll be able to override it to whatever you like"
            [backmsg]="Moxy Preferences"
            [width]=60
            [height]=23
            [ok]="Set Default Username"
            [cancel]="None"
        )

        local -r username=$(ask_inputbox _username)

        if was_cancelled "$username" || [[ "${#username}" -lt 2 ]]; then
            update_config "SUDO_USER" "${username}"
            if config_is_missing "DEFAULT_SUDO_USER"; then
                update_config "DEFAULT_SUDO_USER" "true"
            fi
        else 
            update_config "SUDO_USER" "${username}"
            if config_is_missing "DEFAULT_SUDO_USER"; then
                update_config "DEFAULT_SUDO_USER" "${username}"
            fi
        fi


    else
        update_config "DEFAULT_SUDO_USER" "false"
        if config_is_missing "DEFAULT_SUDO_USER"; then
            update_config "DEFAULT_SUDO_USER" "${username}"
        fi
    fi
}


function ssh_access() {
    clear

    local -ra choices=(
        "No_SSH" "$(space_to_nbsp "No SSH. Only access via Proxmox console.")" ON
        "Keys_Only" "$(space_to_nbsp "only crypto keys in .ssh/authorized")" OFF
        # shellcheck disable=SC2207
        "Keys_Or_Password" "$(space_to_nbsp "SSH allowed with key or user/pwd")" OFF
    )

    local -rA _radio=(
        [title]="Defaults for SSH\n\nChoose from the options below to specify the default values you'd like to set for how SSH should be used with new containers"
        [backmsg]="Moxy Preferences"
        [width]=70
        [height]=23
        [radio_height]=5
        [choices]="${choices[@]}"
        [exit_msg]=""
    )

    local -r choice=$(ask_radiolist _radio)

    if not_empty "$choice"; then
        update_config "DEFAULT_SSH" "${choice}"
    else
        update_config "DEFAULT_SSH" "No_SSH"
    fi
}
