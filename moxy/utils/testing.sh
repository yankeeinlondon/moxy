#!/usr/bin/env bash


#shellcheck disable=SC2034
RESET='\033[0m'
GREEN='\033[38;5;2m'
RED='\033[38;5;1m'
YELLOW='\033[38;5;3m'
#shellcheck disable=SC2034
BOLD='\033[1m'
#shellcheck disable=SC2034
NO_BOLD='\033[21m'
#shellcheck disable=SC2034
DIM='\033[2m'
#shellcheck disable=SC2034
NO_DIM='\033[22m'
#shellcheck disable=SC2034
ITALIC='\033[3m'
#shellcheck disable=SC2034
NO_ITALIC='\033[23m'
#shellcheck disable=SC2034
STRIKE='\033[9m'
#shellcheck disable=SC2034
NO_STRIKE='\033[29m'
#shellcheck disable=SC2034
REVERSE='\033[7m'
#shellcheck disable=SC2034
NO_REVERSE='\033[27m'

function lc() {
    local -r str="${1-}"
    echo "${str}" | tr '[:upper:]' '[:lower:]'
}

function uc() {
    local -r str="${1-}"
    echo "${str}" | tr -s '[:lower:]' '[:upper:]'
}

function log() {
    printf "%b\\n" "${*}" >&2
}

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


function has_command() {
    local -r cmd="${1:?cmd is missing}"

    if eval "which ${cmd}" >/dev/null; then
        return 0; # exists
    else
        return 1; # does not exist
    fi
}

# ui_availability() → [whiptail|dialog|ERROR]
#
# tests whether "whiptail" or "display" 
# (https://invisible-island.net/dialog/) packages are 
# available on the execution platform. For PVE hosts 
# -- or any Debian OS -- "whiptail" should always be available.
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

ui_availability
