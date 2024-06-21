#!/usr/bin/env bash

# shellcheck source="./logging.sh"
. "./utils/logging.sh"


# is_array <any>
# 
# boolean test to see if first parameter is an array
function is_array() {
    local var=$1

    # use a variable to avoid having to escape spaces
    local regex="^declare -[aA] ${var}(=|$)"
    if [[ $(declare -p "$var" 2> /dev/null) =~ $regex ]]; then
        debug "is_array(${var})" "is an array"
        return 0
    else 
        debug "is_array(${var})" "is NOT an array"
        return 1
    fi
}

# has_newline() <str>
#
# returns 0/1 based on whether <str> has a newline character in it
function has_newline() {
    local str="${1:?no parameter passed into has_newline()}"

    if [[ "$str" ==  *$'\n'* ]]; then
        return 0;
    else 
        return 1;
    fi
}

function is_keyword() {
    local _var=${1:?no parameter passed into is_array}
    local declaration=""
    # shellcheck disable=SC2086
    declaration=$(LC_ALL=C type -t $1)

    if [[ "$declaration" == "keyword" ]]; then
        return 0
    else
        return 1
    fi
}

# not_empty() <test>
# 
# tests whether the <test> value passed in is an empty string (or is unset)
# and returns 0 when it is NOT empty and 1 when it is.
function not_empty() {
    if [ -z "$1" ]; then
        return 1
    else
        return 0
    fi
}

# is_shell_alias() <candidate>
#
# Boolean check on whether <candidate> is the name of a
# SHELL alias that exists in the user's terminal.
function is_shell_alias() {
    local candidate="${1:?no parameter passed into is_shell_alias}"
    local -r state=$(manage_err)
    alias "$candidate" 1>/dev/null 2>/dev/null
    local -r error_state="$?"
    set "-${state}" # reset error handling to whatever it had been

    if [[ "${error_state}" == "0" ]]; then
        debug "is_shell_alias" "\"$1\" is a shell alias"
        echo "$declaration"
        return 0
    else
        debug "is_shell_alias" "\"$1\" is ${ITALIC}${RED}not${RESET} a shell alias"

        return 1
    fi
}

# has_command <cmd>
#
# same as is_installed, checks whether <cmd> is installed in OS path.
function has_command() {
    local -r cmd="${1:?cmd is missing}"

    if command -v "${cmd}" &> /dev/null; then
        return 0
    else 
        return 1
    fi
}

# is_installed
# 
# checks whether a particular program passed in via $1 is installed 
# on the OS or not (at least within the $PATH)
function is_installed() {
    local to_check=${1:?nothing was passed to is_function to check}
    if ! command -v "${to_check}" &> /dev/null; then
        return 0
    else 
        return 1
    fi
}


# is_numeric() <candidate>
#
# returns 0/1 based on whether <candidate> is numeric
function is_numeric() {
    local -r maybe_numeric="${1:?no value passed to is_numeric}"

    if ! [[ "$maybe_numeric" =~ ^[0-9]+$ ]]; then
        debug "is_numeric" "false"
        return 1
    else
        debug "is_numeric" "true"
        return 0
    fi
}

# is_shell_command() <candidate>
# 
# tests whether <candidate> is a builtin shell command
function is_shell_command() {
    local candidate=${1:?no parameter passed into is_array}
    local declaration=""

    # shellcheck disable=SC2086
    declaration=$(LC_ALL=C type -t $candidate)

    if [[ "$declaration" == "file" || "$declaration" == "builtin" ]]; then
        return 0
    else
        return 1
    fi
}

# is_object() <candidate>
# 
# tests whether <candidate> is an object and returns 0/1
function is_object() {
    local -r candidate="${1:-}"

    if starts_with "${OBJECT_PREFIX}" "${candidate}"; then
        if ends_with "${OBJECT_SUFFIX}" "${candidate}"; then
            debug "is_object" "true"
            return 0
        fi
    fi

    debug "is_object" "false (${DIM}${candidate}${RESET})"
    return 1
}

# file_contains <filepath> <...find> 
# 
# will search the contents of the file in the "filepath" passed in for 
# any substring which matches one of the parameters passed in for 
# "find".
function file_contains() {
    local -r filepath="${1:?filepath expression not passed to file_has_content()}"
    local -ra find=( "${@:2}");

    local -r content="$(get_file "$filepath")"

    for item in "${find[@]}"; do
        if [[ "${content}" =~ ${item} ]]; then
            return 0 # successful match
        fi
    done

    return 1
}

function str_eq() {
    local -r a="${1}"
    local -r b="${2}"
    if [[ "${a}" == "${b}" ]]; then
        return 0
    else
        return 1
    fi
}

function is_list() {
    local -r content="${1:-}"
    if starts_with "${LIST_PREFIX}" "${content}"; then
        if ends_with "${LIST_SUFFIX}" "${content}"; then
            debug "is_list" "true"
            return 0
        else
            debug "is_list" "false (prefix matched, suffix did not): \"${LIST_SUFFIX}\""
            debug "is_list" "${content}"
            return 1
        fi
    fi

    debug "is_list" "false"
    return 1
}


# starts_with <look-for> <content>
function starts_with() {
    local -r look_for="${1:?No look-for string provided to starts_with}"
    local -r content="${2:-}"

    if [[ "${content}" == "${content#"$look_for"}" ]]; then
        debug "starts_with" "false (\"${DIM}${look_for}${RESET}\")"
        return 1; # was not present
    else
        debug "starts_with" "true (\"${DIM}${look_for}${RESET}\")"
        return 0; # found "look_for"
    fi
}

# ends_with <look-for> <content>
function ends_with() {
    local -r look_for="${1:?No look-for string provided to ends_with}"
    local -r content="${2:?No content string provided to ends_with}"
    local -r no_suffix="${content%"${look_for}"}"

    if [[ "${content}" == "${no_suffix}" ]]; then
        debug "ends_with" "false (\"${DIM}${look_for}${RESET}\")"
        return 1;
    else
        debug "ends_with" "true (\"${DIM}${look_for}${RESET}\")"
        return 0;
    fi
}

# is_function <any> -> 0 | 1
#
# checks whether the passed in $1 is a bash function or not
function is_function() {
    local to_check=${1:?nothing was passed to is_function to check}

    # shellcheck disable=SC2086
    if [[ -n "$(LC_ALL=C type -t ${to_check})" && "$(LC_ALL=C type -t ${to_check})" == "function" ]]; then
        return 0
    else
        return 1
    fi

}

# contains <content> <matches> 
# 
# given the "content" string, all other parameters passed in
# will be looked for in this content.
function contains() {
    local -r content="${1:?content expression not passed to contains()}"
    local -ra list=( "${@:2}" )
    
    for item in "${list[@]}"; do
        if [[ "${content}" =~ ${item} ]]; then
            return 0 # successful match
        fi
    done

    return 1
}

function has_parameters() {
    local first_param="${1:-not-defined}"

    if [[ "$first_param" == "not-defined" ]]; then
        debug "has_parameters" "false"
        return 1
    else
        debug "has_parameters" "true [${DIM}${#@}${RESET}]"
        return 0
    fi
}

# file_exists <filepath>
#
# tests whether a given filepath exists in the filesystem
function file_exists() {
    local filepath="${1:?filepath is missing}"

    if [ -f "${filepath}" ]; then
        debug "file_exists(${filepath})" "exists"
        return 0;
    else
        debug "file_exists(${filepath})" "does not exists"
        return 1;
    fi
}


function directory_exists() {
    local dir="${1:?directory is missing}"

    if [[ -d "${dir}" ]]; then
        return 0;
    else
        return 1;
    fi    
}

# has_env <variable name>
#
# checks whether a given ENV variable name is defined
function has_env() {
    local -r var="${1:?has_env() called but no variable name passed in!}"

    if [[ -z "${var}" ]]; then
        return 0
    else
        return 1
    fi
}



# is_kv_pair() <test>
#
# tests whether passed in <test> is considered a "KV Pair"
function is_kv_pair() {
    local -r test="${1:-}"

    if starts_with "${KV_PREFIX}" "${test}"; then
        if ends_with "${KV_SUFFIX}" "${test}"; then
            debug "is_kv_pair" "true (\"${DIM}${test}${RESET}\")"
            return 0
        fi
    fi

    debug "is_kv_pair" "false (\"${DIM}${test}${RESET}\")"
    return 1
}
