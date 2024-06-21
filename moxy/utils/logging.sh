#!/usr/bin/env bash

export RESET='\033[0m'
export GREEN='\033[38;5;2m'
export RED='\033[38;5;1m'
export YELLOW='\033[38;5;3m'
export BOLD='\033[1m'
export NO_BOLD='\033[21m'
export DIM='\033[2m'
export NO_DIM='\033[22m'
export ITALIC='\033[3m'
export NO_ITALIC='\033[23m'
export STRIKE='\033[9m'
export NO_STRIKE='\033[29m'
export REVERSE='\033[7m'
export NO_REVERSE='\033[27m'

# log
#
# Logs the parameters passed to STDERR
function log() {
    printf "%b\\n" "${*}" >&2
}

# debug <fn> <msg> <...>
# 
# Logs to STDERR when the DEBUG env variable is set
# and not equal to "false".
function debug() {
    DEBUG=$(lc "$DEBUG")
    if [[ "${DEBUG}" != "false" ]]; then
        if (( $# > 1 )); then
            local fn="$1"

            shift
            local regex=""
            local lower_fn="" 
            lower_fn=$(lc "$fn")
            regex="(.*[^a-z]+|^)$lower_fn($|[^a-z]+.*)"

            if [[ "${DEBUG}" == "true" || "${DEBUG}" =~ $regex ]]; then
                log "       ${GREEN}◦${RESET} ${BOLD}${fn}()${RESET} → ${*}"
            fi
        else
            log "       ${GREEN}DEBUG: ${RESET} → ${*}"
        fi
    fi
}

# info <msg>
#
# Logs to STDERR with `INFO ==> ` precursor to the
# passed in parameters. 
function info() {
    log "${GREEN}INFO ${RESET} ==> ${*}"
}


# warn <msg>
#
# Logs to STDERR with `WARN ==> ` precursor to the
# passed in parameters.
function warn() {
    log "${YELLOW}${BOLD}WARN ${RESET} ==> ${*}"
}

# spinner
#
# This function displays a spinner to console
spinner() {
    local chars="/-\|"
    local spin_i=0
    printf "\e[?25l"
    while true; do
        printf "\r \e[36m%s\e[0m" "${chars:spin_i++%${#chars}:1}"
        sleep 0.1
    done
}
