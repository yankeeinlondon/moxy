#!/usr/bin/env bash
# shellcheck source="./env.sh"
. "./utils/env.sh"
# shellcheck source="./logging.sh"
. "./utils/logging.sh"

export ERR_UNKNOWN_CONTAINER_TYPE=5
export ERR_INVALID_DEREF_KEY=10
export ERR_UNKNOWN_COMMAND=50
export ERR_UNEXPECTED_OUTCOME=100

# when a text question is returned with an invalid response
# based on the "validator" function passed in
export ERR_INVALID_TEXT_RESPONSE=101
# when a user "cancels" an interactive question
export ERR_USER_CANCEL=102

# when testing for being a PVE node; this is the return code
# for it NOT being one
export ERR_NOT_PVE_NODE=103

export ERR_MENU_NOT_OBJECT=120
export ERR_MENU_INVALID_CHOICES=121

export ERR_INVALID_API_KEY=130

function returned() {
    local -ri code="${1:-Function must provide a return code to returned()}"
    local -r err_msg="${2}"
    local -A current
    unshift CALL_STACK current

    if [[ $code -eq 0 ]]; then

        return 0;
    else
        log "${BOLD}${RED}Error in ${current["fn"]}() with ID ${current["id"]}:${RESET} ${err_msg}"

        return $code;
    fi
}

function called() {
    local -r fn_name="${1:-Function name was not provided to called()!}"
    local -r fn_id="${2:-Function ID was not passed in with $$!}"
    local -A _stack_el=(
        [fn]="${fn_name}"
        [id]="${fn_id}"
    )
    push CALL_STACK _stack_el
}

function panic() {
    local -r msg="${1:-Exiting due to panic!}"
    local -ri code=${2:-((1))}
    catch_errors

    log "$$: ${msg}"
    exit $code
}

# error <msg>
#
# sends an error message to STDERR and if an error code
# has been included then it will return that error code too
function error() {
    log "${RED}ERROR →${RESET} ${1}"
}


function error_path() {
    local -r path="$1"
    allow_errors

    if not_empty "$path"; then
        local -r delimiter=$(os_path_delimiter)
        local -r start=$(strip_after_last "$delimiter" "$path")
        local -r end=$(strip_before_last "$delimiter" "$path")

        printf "%s" "${start}/${RED}${end}${RESET}"
    else
        printf "%s" "${ITALIC}${DIM}unknown${RESET}"
    fi

}

# error_handler()
#
# Handles error when they are caught
function error_handler() {
    local -r exit_code="$?"
    local -r line_number="$1"
    local -r command="$2"

    log "  [${RED}x${RESET}] ERROR [${BOLD}${exit_code}${RESET}] at line ${line_number} while executing command \"${DIM}$command${RESET}\""
    log ""
    local -i i
    i=0
    for file in "${BASH_SOURCE[@]}"; do

        if ! contains "errors.sh" "$file"; then
            log "- ${FUNCNAME[$i]}() ${ITALIC}${DIM}at line${RESET} ${BASH_LINENO[$i]} ${ITALIC}${DIM}in${RESET} $(error_path "${file}")"
        fi
        i=$(( i + 1 ))
    done
}

# catch_errors()
#
# Catches all errors found in a script -- including pipeline errors -- and
# sends them to an error handler to report the error.
function catch_errors() {
  set -Eeuo pipefail
  trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
}

# allow_errors()
#
# Allows for non-zero return-codes to avoid being sent to the error_handler
# and is typically used to temporarily check on an external state from the shell
# where an error might be encountered but which will be handled locally
function allow_errors() {
    set +Eeuo pipefail
    trap - ERR
}

function error_state_fails() {
    local -r current_state=$-
    case $current_state in

        *e*) return 0;;
        *) return 1;;

    esac
}

# pause_errors()
#
# Passes back the current state of error handling so it may be restored
# later but then disables it at this point.
function pause_errors() {
    local -r current_state=$-
    case $current_state in

        *e*) echo "true";;
        *) echo "false";;

    esac

    return 0
}

function restore_errors() {
    local -r prior="${1:?no prior state was passed into restore_errors}"

    if [[ "$prior" == "true" ]]; then
        set -e
    fi
}


# manage_err () -> "prior error state"
#
# Turns off error (aka, set -e) but returns
# what the single-letter states were prior
# to doing to so that you can revert back
# to this state at the appropriate time
function manage_err() {
    local -r set_state="$(shell_options)"
    set +e
    echo "${set_state}"
    return 0
}
