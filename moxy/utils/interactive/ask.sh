#!/usr/bin/env bash

# shellcheck disable=1091
source "${MOXY}/utils/shared.sh"

function default_validator () {
    return 0;
}

# ui_availability() → [whiptail|dialog|ERROR]
#
# tests whether "whiptail" or "display" (https://invisible-island.net/dialog/) 
# packages are available on the execution platform. 
# For PVE hosts "whiptail" should always be available.
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

# responsible for handling the interactive parts of the process, including:
# - gathering a pipeline of questions and default answers
# - validating that all default values are valid

function ask_to_continue() {
    local -r default_answer="${1:-yes}"
    local -r exit_msg="${2:-Exiting...}"
    local -r continue_msg="${1:-}"
    local prompt=""

    lc "${default_answer}" | grep -Eq "^(y|yes)"
    DEFAULT_YES=$?

    if $DEFAULT_YES; then 
        read -r -p "Continue? <Y/n> " prompt
        if echo "$prompt" | grep -Eq "^(n|no)$"; then
            log "${exit_msg}"
            exit 1
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

    if ! is_object "${choices}"; then
        error "ask_from_menu() was called without a valid set of choices: ${DIM}${choices}${RESET}"
        # shellcheck disable=SC2086
        return $ERR_MENU_NOT_OBJECT
    fi

    


    local -r num_choices=iterable "count"
        local dialog_height=$(( num_options+2 ))
        if [[ dialog_height -gt 20 ]]; then
            dialog_height=$(( 20 ))
        fi
    local -r height="${3:8}"
    local -r width="${4:60}"
    local -r def_value="${5:-}"
    local -rf validate="${6:-$default_validator}"
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
