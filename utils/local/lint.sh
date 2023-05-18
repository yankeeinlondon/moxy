#!/usr/bin/env bash

# shellcheck disable=SC1091
source "./utils/local/shared.sh"
source "./utils/build.func"
# catch_errors

SUCCESS=0
FAILURE=1
# URL for how to ignore errors
IGNORE_ERRORS="https://github.com/koalaman/shellcheck/wiki/Ignore"



# Lints shell files with `*.sh` extension
#
# - expects $1 to have a base path to start file matching at
# - recursively gets all shell files from dir/subdirs
# - if parameters beyond $1 are provided:
#   - will filter file list by those which meet ANY of the param's
function linter() {
    local -r BASE="${1:?base directory must be provided to get_files}"

    ARGS=( "${BASE}" "*.sh" "--relative" )

    # whether or not to display verbose output
    local VERBOSE="false"
    if extract "-v" "$@"; then
        # shellcheck disable=SC2207
        T=( $(extract "-v" "$@") )
        for p in "${T[@]:1}"; do
            ARGS+=( "${p}" )
        done

        VERBOSE="true"
    else
        ARGS+=("${@:2}")
    fi

    #shellcheck disable=SC2310
    if ! has_command "shellcheck"; then
        log ""
        log "- linting shell scripts requires that \"shellcheck\" be installed"
        log "- on debian just use \"apt install shellcheck\""
        log ""
        return 5
    fi

    STATE=${SUCCESS}
    SUCCESSES=0
    FAILURES=0
    LINT_MESSAGES=""

    # files as an array
    FILES=()
    while read -r line; do FILES+=("$line"); done <<< "$(get_files "${ARGS[@]}")"

    NUM_FILES=${#FILES[@]}

    if [[ -z "${FILES[0]}" ]]; then
        log ""
        log "Linting:"
        NUM_FILES="0"
    else
        log ""
        log "Linting ${NUM_FILES} files:"
        log ""
    fi

    if [[ "${NUM_FILES}" == "0" ]]; then
        log ""
        log "${RED}No shell files found to lint based on filters!${RESET}"
        log ""

        return 2;
    fi


    cd "${BASE}" > /dev/null  || ( error "Not able to change into repos directory" && exit 10 )
    # execute shellcheck and capture results and status
    # without sending anything to the shell    
    # exec 5>&1
    # result=$(eval shellcheck --color=always -s bash -o all "${file}" |tee /dev/fd/5; exit "${PIPESTATUS[0]}")
    for file in "${FILES[@]}"; do
        result=$(eval shellcheck --color=always -s bash -o all "${file}")

        # Command succeeded, now we look for lint suggestions
        if [[ -z "${result}" ]]; then
            # an empty result means there were no warnings/errors
            log "[${GREEN}✔${RESET}]: ${file}"
            SUCCESSES=$(( SUCCESSES+1 ))
        else
            log "[${RED}x${RESET}]: ${file}"
            FAILURES=$(( FAILURES+1 ))
            STATE="${FAILURE}"

            LINT_MESSAGES="${LINT_MESSAGES}\n\n${BOLD}Lint errors for ${file}${RESET}\n${result}"
        fi
    done
    cd - >/dev/null || exit 10

    if [[ "${STATE}" == "${SUCCESS}" ]]; then
        log ""
        log "Linting finished:"
        log ""
        log "- all linting rules passed 🚀"
        log ""
        return 0
    else
        log ""
        log "Linting finished:"
        log ""
        log "- ${SUCCESSES} scripts were without error 👍"
        log "- ${FAILURES} scripts have linting errors 👎"
        log ""
        if [[ "${VERBOSE}" == "true" ]]; then
            log "${LINT_MESSAGES}"
        fi
        log "- how to ignore certain errors: ${GREEN}${IGNORE_ERRORS}${RESET}"
        log ""

        return 1
    fi
}

# main
linter "${@:1}"
