#!/usr/local/env bash

# shellcheck disable=SC1091
source "${MOXY}/utils//shared.sh"

# test_result <exit-code> <script> <msg>
function test_result() {
    local -r exit_code=${1:?No exit code provided to test_result}
    local msg="${2:-}"

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
    log "  [${RED}x${RESET}] ERROR in line $line_number [ exit code $exit_code] while executing command \"${DIM}$command${RESET}\""
}

function try() {
    debug "try" "params: $*"
    local -r maybe_object="$1"
    local msg=""
    local cmd=""
    local -ar known=( exit_code exit_code_ne return_eq return_ne return_contains )
    local comparisons=""
    comparisons=$(object)

    # configure tests based on whether an object or array is passed in
    if is_object "${maybe_object}"; then
        debug "try" "payload detected as object: ${DIM}${maybe_object}${RESET}"
        cmd=$(get "cmd" "${maybe_object}")
        msg=$(get "msg" "${maybe_object}") 
        local -ra obj_keys=( $(keys "${maybe_object}") )

        debug "try" "cmd: ${cmd}, msg: ${msg}"
        debug "try" "keys are: ${DIM}${obj_keys[*]}"

        # exit_code=$(get "exit_code" "${maybe_object}") || push "exit_code" "0" "${comparisons}"

        # iterate over remaining key/values
        for key in $(keys "${maybe_object}"); do
            if contains "${key}" "${known[@]}"; then
                value=$(get "${key}" "${maybe_object}")
                comparisons=$(push "${key}" "${value}" "${comparisons}")
            else
                warn "unknown key \"${key}\" added to try()"
            fi
        done
    else
        debug "try" "payload detected as array definition"
        cmd="${1:?no command provided to try}"
        msg="${2:-}"
        expected_value=${3:-not-set}
        if [[ "${expected_value}" == "not-set" ]]; then
            comparisons=$(push "exit_code" "0" "${comparisons}")
        else
            comparisons=$(push "exit_code" "0" "${comparisons}")
            info "comparisons: ${comparisons}"
            comparisons=$(push "return_eq" "${expected_value}" "${comparisons}")
        fi
    fi

    debug "try" "cmd: ${cmd}"
    debug "try" "msg: ${msg}"
    debug "try" "comparisons: ${comparisons}"

    # catch_errors
    
    # shellcheck disable=SC2178
    result=$(eval "${cmd}")
    # set +Eeuo pipefail
    

    for comp in "${comparisons[@]}"; do
        value=$(get "${comp}" "${comparisons}")

        case "${comp}" in

            exit_code)
                if [[ "$value" == "$?" ]]; then
                    log "  [${GREEN}✔${RESET}] ${msg}; ${ITALIC}exit code${RESET} of \"${DIM}${value}${RESET}\" was expected from: \$( ${DIM}${cmd}${RESET} )"
                else
                    log "  [${RED}x${RESET}] ${msg}; expected return value did not match"
                fi
                ;;

            exit_code_ne)
                if [[ "$value" != "$?" ]]; then
                    log "  [${GREEN}✔${RESET}] ${msg}; ${ITALIC}exit code${RESET} was NOT \"${DIM}${value}${RESET}\"; which was expected from: \$( ${DIM}${cmd}${RESET} )"
                else
                    log "  [${RED}x${RESET}] ${msg}; ${ITALIC}exit code${RESET} was ${value} but was not supposed to be from: \$( ${DIM}${cmd}${RESET} )"
                fi
                ;;

            return_eq)
                if [[ "$value" != "$?" ]]; then
                    log "  [${GREEN}✔${RESET}] ${msg}; ${ITALIC}exit code${RESET} was NOT \"${DIM}${value}${RESET}\"; which was expected from: \$( ${DIM}${cmd}${RESET} )"
                else
                    log "  [${RED}x${RESET}] ${msg}; ${ITALIC}exit code${RESET} was ${value} but was not supposed to be from: \$( ${DIM}${cmd}${RESET} )"
                fi
                ;;

            return_ne)
                ;;
            
            return_contains)
                ;;

            

        esac

    done

    if [[ "${comparisons}" != "none" ]]; then
        if [[ "$comp" == "${result}" ]]; then
            log "  [${GREEN}✔${RESET}] ${msg}; ${ITALIC}return value${RESET} of \"${DIM}${result}${RESET}\" was expected"
        else
            log "  [${RED}x${RESET}] ${msg}; expected return value did not match"
        fi
    fi

    # echo "${result}"
    return 0
}

function test_separator() {
    local title="${1:-not-defined}"
    if [[ ${title} == "not-defined" ]]; then
        log "  ${DIM}---${RESET}"
    else
        log "  ${DIM}---${ITALIC} ${title} ${NO_ITALIC}---${RESET}"
    fi
}

function assert_eq() {
    local -r a="${1:?the first value was not passed into assert_eq}"
    local -r b="${2:?the second value was not passed into assert_eq}"
    if [[ "${a}" == "${b}" ]]; then
        echo "${a}"
        return 0
    else
        echo "\"${DIM}${a}${RESET}\" ≠ \"${DIM}${b}${RESET}\""
        return 1
    fi
}

function assert_error() {
    local -r return_code="${1:?no return code was passed to assert_error}"

    if [[ "${return_code}" == "0" ]]; then
        error "expected test to fail but a successful outcome was attained"
        return 1
    else
        return 0
    fi
}

function assert_contains() {
    local -r find="${1:? did not get FIND string for assert_contains}"
    shift
    read -r -a list <<< "${*}"
    
    # shellcheck disable=SC2206
    local contains="false"
    for i in "${list[@]}"; do
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
