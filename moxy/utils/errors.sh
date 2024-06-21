#!/usr/bin/env bash

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


# error <msg> <[code]>
#
# sends an error message to STDERR and if an error code
# has been included then it will return that error code too
function error() {
    local -r possible_code="${2:-error code not-specified}"

    if [[ "$possible_code" == "error code not-specified" ]]; then
        log "${RED}ERROR ${RESET} ==> ${*}"
    else
        log "${RED}ERROR [${possible_code}] ${RESET} ==> ${1}"
        declare code=$(( possible_code ))

        debug "error" "returning with code ${code}"

        return $code
    fi
}

# error_handler()
#
# Handles error when they are caught
function error_handler() {
    local -r exit_code="$?"
    local -r line_number="$1"
    local -r command="$2"

    log "  [${RED}x${RESET}] ERROR in line $line_number [ exit code $exit_code ] while executing command \"${DIM}$command${RESET}\""
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
    set +e
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

