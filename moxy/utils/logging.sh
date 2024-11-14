#!/usr/bin/env bash

export RESET='\033[0m'

export GREEN='\033[38;5;2m'
export RED='\033[38;5;1m'
export YELLOW2='\033[38;5;3m'
export BLACK='\033[30m'
export RED='\033[31m'
export GREEN='\033[32m'
export YELLOW='\033[33m'
export BLUE='\033[34m'
export MAGENTA='\033[35m'
export CYAN='\033[36m'
export WHITE='\033[37m'

export BRIGHT_BLACK='\033[90m'
export BRIGHT_RED='\033[91m'
export BRIGHT_GREEN='\033[92m'
export BRIGHT_YELLOW='\033[93m'
export BRIGHT_BLUE='\033[94m'
export BRIGHT_MAGENTA='\033[95m'
export BRIGHT_CYAN='\033[96m'
export BRIGHT_WHITE='\033[97m'

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

export BG_BLACK='\033[40m'
export BG_RED='\033[41m'
export BG_GREEN='\033[42m'
export BG_YELLOW='\033[43m'
export BG_BLUE='\033[44m'
export BG_MAGENTA='\033[45m'
export BG_CYAN='\033[46m'
export BG_WHITE='\033[47m'

export BG_BRIGHT_BLACK='\033[100m'
export BG_BRIGHT_RED='\033[101m'
export BG_BRIGHT_GREEN='\033[102m'
export BG_BRIGHT_YELLOW='\033[103m'
export BG_BRIGHT_BLUE='\033[104m'
export BG_BRIGHT_MAGENTA='\033[105m'
export BG_BRIGHT_CYAN='\033[106m'
export BG_BRIGHT_WHITE='\033[107m'

export BG_PALLETTE=(
    "${BG_MAGENTA}"
    "${BG_BLUE}"
    "${BG_BRIGHT_BLACK}"
    "${BG_RED}"
    "${BG_GREEN}"
    "${BG_BRIGHT_YELLOW}"
    "${BG_CYAN}"
    "${BG_BRIGHT_MAGENTA}"
    "${BG_BRIGHT_BLUE}"
    "${BG_BRIGHT_RED}"
    "${BG_BRIGHT_CYAN}"
    "${BG_BRIGHT_GREEN}"
    "${BG_BRIGHT_WHITE}"
    "${BG_WHITE}"
    "${BG_BLACK}"
)

print_rounded_text() {
    local bg_color=$1
    local text=$2

    echo -e "${bg_color}╭─────────────────╮${RESET}"
    echo -e "${bg_color}│ ${text}   │${RESET}"
    echo -e "${bg_color}╰─────────────────╯${RESET}"
}

# Example usage


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
    local -r DEBUG=$(lc "${DEBUG:-}")
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
