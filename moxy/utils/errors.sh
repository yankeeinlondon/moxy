#!/usr/bin/env bash
# shellcheck source="./env.sh"
. "./utils/env.sh"
# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./conditionals.sh"
. "./utils/conditionals.sh"

export ERR_CONFIG_FILE_MISSING=25
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

export CALL_STACK=()

function returned() {
    local -ri code="${1:-Function must provide a return code to returned()}"
    local -r err_msg="${2}"
    local -A current
    unshift CALL_STACK current

    if [[ $code -eq 0 ]]; then

        return 0
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



# error_path()
#
# makes a prettier display of the error path
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

function panic() {
    local -r msg="${1:?no message passed to error()!}"
    local -ri code=$(( "${2:-1}" ))
    local -r fn="${3:-${FUNCNAME[1]}}" || echo "unknown"

    log "\n  [${RED}x${RESET}] ${BOLD}ERROR ${DIM}${RED}$code${RESET}${BOLD} →${RESET} ${msg}" 
    log ""
    for i in "${!BASH_SOURCE[@]}"; do
        if ! contains "errors.sh" "${BASH_SOURCE[$i]}"; then
            log "    - ${FUNCNAME[$i]}() ${ITALIC}${DIM}at line${RESET} ${BASH_LINENO[$i-1]} ${ITALIC}${DIM}in${RESET} $(error_path "${BASH_SOURCE[$i]}")"
        fi
    done
    log ""
    exit $code
}

# error <msg>
#
# sends a formatted error message to STDERR
function error() {
    local -r msg="${1:?no message passed to error()!}"
    local -ri code=$(( "${2:-1}" ))
    local -r fn="${3:-${FUNCNAME[1]}}"

    log "\n  [${RED}x${RESET}] ${BOLD}ERROR ${DIM}${RED}$code${RESET}${BOLD} →${RESET} ${msg}" && return $code
}


# error_handler()
#
# Handles error when they are caught
function error_handler() {
    local -r exit_code="$?"
    local -r _line_number="$1"
    local -r command="$2"

    # shellcheck disable=SC2016
    if is_bound command && [[ "$command" != 'return $code' ]]; then
        log "  [${RED}x${RESET}] ${BOLD}ERROR ${DIM}${RED}$exit_code${RESET}${BOLD} → ${command}${RESET} "
    fi
    log ""

    for i in "${!BASH_SOURCE[@]}"; do
        if ! contains "errors.sh" "${BASH_SOURCE[$i]:-unknown}"; then
            log "    - ${FUNCNAME[$i]:-unknown}() ${ITALIC}${DIM}at line${RESET} ${BASH_LINENO[$i-1]:-unknown} ${ITALIC}${DIM}in${RESET} $(error_path "${BASH_SOURCE[$i]:-unknown}")"
        fi
    done
    log ""
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
