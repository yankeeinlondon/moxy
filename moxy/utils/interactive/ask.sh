#!/usr/bin/env bash

# shellcheck source="../shared.sh"
source "./utils/shared.sh"

function default_validator () {
    return 0;
}

function exit_ask() {
    local -r msg="${1:-}"
    clear
    log "${msg}"
    exit
}

let DIALOG_OK=0;
let DIALOG_CANCEL=1;
let DIALOG_HELP=2;
let DIALOG_EXTRA=3;
let DIALOG_HELP=4;
let DIALOG_TIMEOUT=5;
# when error occur inside dialog or user presses ESC
let DIALOG_ERR=-1;



# ask
#
# determines which TUI to use
function ask() {
    if has_command "whiptail"; then
        debug "ask" "using whiptail for TUI"
        whiptail "${@}"
    elif has_command "dialog"; then
        debug "ask" "using Display for TUI"
        display "${@}"
    fi
}

function tui() {
    local var

    if has_command "whiptail"; then
        var="whiptail"
    elif has_command "dialog"; then
        var="dialog"
    else 
        var="none"
    fi

    echo "${var}"
}

# ask_yes_no <Prompt>
# 
function ask_password() {
    local -r title="${1:?No title provided to ask_yes_no()}"
    local -r height="${2:?No height provided to ask_yes_no()}"
    local -r width="${3:?No width provided to ask_yes_no()}"
    local -r ok_btn="${4:-Ok}"
    local -r cancel_btn="${5:-Cancel}"
    local -r exit_msg="${6:-Goodbye}"
    local -r tool="$(tui)"
    local choice

    if [[ "$tool" == "dialog" ]]; then 
        choice=$(
            dialog --ok-label "${ok_btn}" --cancel-label "${cancel_btn}" --inputbox "${title}" "${height}" "${width}"  3>&2 2>&1 1>&3
        ) || exit_ask "${exit_msg}"
    elif [[ "$tool" == "whiptail" ]]; then 
        choice=$(
            whiptail --ok-btn "${ok_btn}" --cancel-btn "${cancel_btn}" --inputbox "${title}" "${height}" "${width}"  3>&2 2>&1 1>&3
        ) || exit_ask "${exit_msg}"
    else
        error "can't ask for password as no TUI is available [${tool}]"
        exit 1
    fi

    if [ "${#choice}" -lt 8 ]; then
        log ""
        log ""
        error "The key you passed in was too short [${#choice}], please refer to the Promox docs for how to generate the key and test it out with Postman or equivalent if you're unsure if it's right"
        log ""
        exit 1
    else 
        log "${choice}"
        log "Tui: $(tui)"
    fi

}


# ask_to_continue <continue msg> <exit msg> <y|n> <err>
function ask_to_continue() {
    local -r continue_msg="${1:-Ok}"
    local -r exit_msg="${2:-Exiting...}"
    local -r def_val="${3:-y}"
    local -r exit_is_error="${4:-false}"


    if [[ "$def_val" == "y" ]]; then 
        read -r -p "Continue? <Y/n> " prompt
        if echo "$prompt" | grep -Eq "^(n|no)$"; then
            log "${exit_msg}"
            if [[ "${exit_is_error}" == "false" ]]; then
                exit 0
            else
                exit 1
            fi
        else
            log "${continue_msg}"
            log ""
        fi

    else
        read -r -p "Continue? <y/N> " prompt
        if echo "$prompt" | grep -Eq "^(y|yes)$"; then
            log "${exit_msg}"
            exit 1
        else
            log "${continue_msg}"
            log ""
        fi
    fi
}


# ask_for_text <id> <title> <question> <[height]> <[width]> <[def_value]> <[validator fn]>
#
# interactively asks user for a text input and returns key/value pair to the
# "answers" variable which it assumes to be an existingly scoped local variable
#
# by default any text provided by the user is considered valid but the caller may
# pass in a validator function to limit this.
function ask_for_text() {
    local -r title="${1:?no title passed to ask_for_text()}"
    local -r question="${2:?no question text passed to ask_for_text()}"
    local -r height="${3:8}"
    local -r width="${4:60}"
    local -r def_value="${5:-}"
    local -rf validate="${6:-$default_validator}"

    if ui_availability; then
        local -r ui_pkg="$(ui_availability)"
        debug "ask_for_text" "\"${title}\" to be asked for text input by \"${ui_pkg}\""

        allow_errors
        def_value=$(${ui_pkg} --inputbox \""${question}"\" "${height}" "${width}" "${def_value}" --title "${title}" 3>&1 1>&2 2>&3)
        local -r cmd_response=$?
        catch_errors

        if ! ${cmd_response}; then
            debug "ask_for_text" "user opted to cancel the process"
            # shellcheck disable=SC2086
            return ${ERR_USER_CANCEL}
        fi

    else
        debug "ask_for_text" "\"${title}\" to be asked for text input in plain text"
        def_value=$(read -r -p "${BOLD}${title}${RESET}\n${question} [${value}]")
    fi

    if "$validate" "${value}"; then
        debug "ask_for_text" "valid text being returned: ${value}"
        echo "${value}"
        return 0
    else
        debug "ask_for_text" "invalid text: ${value}"
        # shellcheck disable=SC2086
        return ${ERR_INVALID_TEXT_RESPONSE}
    fi
}

function ask_from_menu() {
    local -r title="${1:?no title passed to ask_for_text()}"
    local -r question="${2:?no question text passed to ask_for_text()}"
    local -r choices="${3:?no choices provided to ask_for_menu}"

    # if ! is_object "${choices}"; then
    #     error "ask_from_menu() was called without a valid set of choices: ${DIM}${choices}${RESET}"
    #     # shellcheck disable=SC2086
    #     return $ERR_MENU_NOT_OBJECT
    # fi

    


    local -r num_choices=iterable "count"
    local dialog_height=$(( num_options+2 ))
    if [[ dialog_height -gt 20 ]]; then
        dialog_height=$(( 20 ))
    fi
    local -r height="${3:8}"
    local -r width="${4:60}"
    local -r def_value="${5:-}"
    local -r validate="${6:-$default_validator}"
}

function ask_yes_no() {
    local -rA answers="${1:the dictionary of answers was not provided to ask_yes_no}"
    local -r question="${2:the question text was not provided to ask_yes_no}"
    local value="${3:-yes}"

    echo "TODO"
}

function ask_select_one() {
    local -r answers="${1:the dictionary of answers was not provided to ask_select_one}"
    local -r question="${2:the question text was not provided to ask_select_one}"
    local -r options="${3:the list of options was not provided to ask_select_one}"
    local -r value="${4:-$(first "$answers")}"

    echo "TODO"
}

function ask_select_many() {
    local -rA answers="${1:the dictionary of answers was not provided to ask_select_many}"
    local -r question="${2:the question text was not provided to ask_select_many}"
    local -r options="${3:the list of options was not provided to ask_select_many}"
    local default_value="${4}"

    echo "TODO"
}


