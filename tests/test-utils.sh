#!/usr/local/env bash

# shellcheck disable=SC1091
source "${PWD}/utils/local/shared.sh"

# test_result <exit-code> <script> <msg>
function test_result() {
    local -r exit_code=${1:?No exit code provided to test_result}
    # local -r script="${2:?No script name provided to test_result}"
    local msg="${2:-}"

    # local -r line_number="$1"
    # local -r command="$2"

    if [[ $exit_code == "0" ]]; then
        log "  [${GREEN}✔${RESET}] ${msg}"
    else
        log "  [${RED}x${RESET}] ${msg} [code: ${1}]"
    fi
}

catch_errors() {
  set -Eeuo pipefail
  trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
}

function error_handler() {
    local -r exit_code="$?"
    local -r line_number="$1"
    local -r command="$2"
    log "  [${RED}x${RESET}] ERROR in line $line_number [ exit code $exit_code] while executing command\n       ${DIM}$command${RESET}"
}

function try() {
    local -ra context=( "$@" )
    local -r cmd="${context[0]:?no command provided to try}"
    local -r msg="${context[1]}"
    local -r comparison="${context[2]:-none}"

    debug "try" "cmd: ${cmd}"
    debug "try" "msg: ${msg}"

    # catch_errors
    
    # shellcheck disable=SC2178
    result=$(eval "${cmd}")
    # set +Eeuo pipefail
    log "  [${GREEN}✔${RESET}] ${msg}; return ${ITALIC}code${RESET} of \"${DIM}0${RESET}\" was expected from: \$( ${DIM}${cmd}${RESET} )"


    if [[ "${comparison}" != "none" ]]; then
        if [[ "$comparison" == "${result}" ]]; then
            log "  [${GREEN}✔${RESET}] ${msg}; return ${ITALIC}value${RESET} of \"${DIM}${result}${RESET}\" was expected"
        else
            log "  [${RED}x${RESET}] ${msg}; expected return value did not match"
        fi
    fi

    # echo "${result}"
    return 0
}

function test_separator() {
    log "  ${DIM}---${RESET}"
}

function assert_eq() {
    local -r a="${1:?the first value was not passed into assert_eq}"
    local -r b="${2:?the second value was not passed into assert_eq}"
    if [[ "${a}" == "${b}" ]]; then
        echo "${a}"
        return 0
    else
        echo "${a} != ${b}"
        return 1
    fi
}

function assert_contains() {
    local -r find="${1:? did not get FIND string for assert_contains}"
    shift
    read -r -a list <<< "${*}"
    
    # shellcheck disable=SC2206
    local contains="false"
    for i in "${list[@]}"; do
        warn "\"${i}\""
        if [[ "${i}" == "${find}" ]]; then
            contains="true"
        fi
    done

    if [[ "${contains}" == "true" ]]; then
        echo "\"${find}\""
        return 0
    else
        local response="\"${find}\" ⊄ ["
        for i in "${@:2}"; do
            response="${response}\"${i}\","
        done
        response="$(avoid_trailing "," "${response}")] "
        echo "${response}"
        return 1
    fi
}
