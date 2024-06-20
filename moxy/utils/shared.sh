#!/usr/bin/env bash

# shellcheck source="./errors.sh"
source "./utils/errors.sh"
# shellcheck source="./env.sh"
source "./utils/env.sh"

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

function info() {
    log "${GREEN}INFO ${RESET} ==> ${*}"
}

function warn() {
    log "${YELLOW}WARN ${RESET} ==> ${*}"
}

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

# error_handler
function error_handler() {
    local -r exit_code="$?"
    local -r line_number="$1"
    local -r command="$2"
    log "  [${RED}x${RESET}] ERROR in line $line_number [ exit code $exit_code ] while executing command \"${DIM}$command${RESET}\""
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

# catch_errors()
#
# Catches all errors found in a script -- including pipeline errors -- and
# sends them to an error handler to report the error.
function catch_errors() {
  set -Eeuo pipefail
  trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
}

function nbsp() {
    printf '\xc2\xa0'
}

# is_array <any>
# 
# boolean test to see if first parameter is an array
function is_array() {
    local _var="${1:?no parameter passed into is_array}"
    local declaration=""
    # shellcheck disable=SC2086
    declaration=$(declare -p $1)

    if [[ "$declaration"  =~ "declare -a" ]]; then
        return 0
    else
        return 1
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

# ui_availability() → [whiptail|dialog|ERROR]
#
# tests whether "whiptail" or "display" (https://invisible-island.net/dialog/) 
# packages are available on the execution platform. 
# For PVE hosts "whiptail" should always be available.
function ui_availability() {
    if has_command "whiptail"; then
        debug "ui_availability" "has whiptail"
        return 0
    elif has_command "dialog"; then
        debug "ui_availability" "no whiptail but has dialog"
        return 0
    else
        debug "ui_availability" "neither whiptail nor dialog found on host"
        return 1
    fi
}

function shell_options() {
    local current_state=""
    current_state=$(printf %s\\n "$-")

    debug "shell_options" "${current_state}"
    echo "${current_state}"
    return 0
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

function is_shell_command() {
    local _var=${1:?no parameter passed into is_array}
    local declaration=""

    # shellcheck disable=SC2086
    declaration=$(LC_ALL=C type -t $1)


    if [[ "$declaration" == "file" || "$declaration" == "builtin" ]]; then
        return 0
    else
        return 1
    fi
}

function is_shell_alias() {
    local possible_alias="${1:?no parameter passed into is_array}"
    local -r state=$(manage_err)
    alias "$possible_alias" 1>/dev/null 2>/dev/null
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

# is_installed
# 
# checks whether a particular program passed in via $1 is installed on the OS or not
function is_installed() {
    local to_check=${1:?nothing was passed to is_function to check}
    if ! command -v "${to_check}" &> /dev/null; then
        return 0
    else 
        return 1
    fi
}


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

# pretty_single_line <list|kv|object|array> → string
#
# converts a container into a single line string which 
# nicely displays a container type in a way which a user
# would understand
# 
# example output: ( foo bar baz ) would display as ↓
# [0]=foo [1]=bar [2]=baz
# 
# - adding "true" to $2 will colorize the string
function pretty_single_line() {
    local -r expected="${1:?nothing passed to is_numeric}"

    # TODO

}

function has_command() {
    local -r cmd="${1:?cmd is missing}"

    if command -v "${cmd}" &> /dev/null; then
        return 0
    else 
        return 1
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

# ensure_trailing <ensured-str> <content>
#
# ensures that the "content" will end with the <ensured-str>
function ensure_trailing() {
    local -r ensured="${1:?No ensured string provided to ensure_trailing}"
    local -r content="${2:?-}"

    if ends_with "${ensured}" "${content}"; then
        echo "${content}"
    else
        echo "${content}${ensured}"
    fi

    return 0
}

# ensure_starting <ensured-str> <content>
#
# ensures that the "content" will start with the <ensured-str>
function ensure_starting() {
    local -r ensured="${1:?No ensured string provided to ensure_starting}"
    local -r content="${2:?-}"

    if starts_with "${ensured}"; then
        echo "${content}"
    else
        echo "${ensured}${content}"
    fi

    return 0
}

# strip_starting <avoid-str> <content>
#
# ensures that the "content" will NOT start with the <avoid-str>
function strip_starting() {
    local -r avoid="${1:?No avoid string provided to ensure_starting}"
    local -r content="${2:-}"

    echo "${content#"$avoid"}"

    return 0
}

# strip_trailing <avoid> <content>
#
# Strips the <avoid> string at the END of <content> if it exists.
function strip_trailing() {
    local -r avoid="${1:?No avoid string provided to ensure_starting}"
    local -r content="${2:-}"

    echo "${content%"$avoid"}"

    return 0
}


# split <delimiter> <content> → array
#
# splits string content on a given delimiter and returns
# an array
function split() {
    local -r delimiter="${1:-not-specified}"
    local content="${2:-no-content}"
    local -a parts=()

    if [ "$delimiter" == "not-specified" ] && [ "$content" == "no-content" ]; then
        debug "split" "no parameters provided!"
        error "split() called with no parameters provided!" 10
    elif [[ "$delimiter" == "not-specified" ]]; then
        debug "split" "split string not specified so will use <space>"
        delimiter=" "
    elif [[ "$content" == "no-content" ]]; then
        debug "split" "no content, will return empty array but this may be a mistake"
        echo "${items[@]}"
        return 0
    fi
    debug "split" "splitting string using \"${YELLOW}${BOLD}${delimiter}${RESET}\" delimiter"

    content="${content}${delimiter}"
    while [[ "$content" ]]; do
        parts+=( "${content%%"$delimiter"*}" )
        content=${content#*"$delimiter"}
    done

    debug "split" "split into ${YELLOW}${BOLD}${#parts[@]}${RESET} parts: ${DIM}${parts[*]}${RESET}"

    echo "${parts[@]}"
    return 0
}


# flags <array|list> → [ params, flags ]
#
# Looks for any "flags" in an array or list -- where a 
# flag is a string starting in "-" -- and returns
# an array of two lists: `[ params, flags ]`
function flags() {
    local -r maybe_list="$1:-"
    local -a items=()
    params=$(list)
    flags=$(list)

    # ensure $items are moved to common form
    if is_list "${maybe_list}"; then
        items=( values "$maybe_list" )
    else
        items=( "$@" )
    fi

    for i in "${items[@]}"; do
        if starts_with "-" "${i}"; then
            flags=$(push "${i}" "${flags}")
        else
            params=$(push "${i}" "${params}")
        fi
    done

    result=( "${params}" "$files" )

    echo "${result[@]}"
    return 0
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


# extract <look-for> <list>
# 
# Looks for a string in the "$@" list and filters
# it out if it exists.
# 
# Returns:
#  - 0 if it was extracted otherwise 1
#  - StdOut gets the new list with the value extracted
function extract() {
    local -r match="${1:?match expression not passed to extract}"
    local Args=()
    found="false"

    for arg in "${@:2}"; do
        if [[ "${arg}" == "${match}" ]]; then
            found="true"
        else
            Args+=( "${arg}" )
        fi
    done

    echo "${Args[@]}"

    if [[ "${found}" == "false" ]]; then
        return 1
    else
        return 0
    fi
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

# replace <find> <replace> <content>
#
# Looks for "find" in the "content" string passed in and replaces it
# with "replace".
function replace() {
    local -r find="${1:?the FIND string was not passed to replace}"
    local -r replace="${2:?the REPLACE string was not passed to replace}"
    local -r content="${3:-}"
    debug "replace" "replacing \"${find}\" with \"${replace}\""

    new_content="${content//"${find}"/"${replace}"}"
    debug "replace" "was: ${content}"
    debug "replace" "now: ${new_content}"
    echo "${new_content}"
    return 0
}

# kv <key> <value>
#
# Creates a KV pairing with default delimiter of "::" (unless
# overriden by another delimiter)
function kv() {
    local -r key="${1:?the KEY was not passed to kv}"
    local -r val="${2:?the VALUE was not passed to kv}"
    
    local kv_defn="${KV_PREFIX}${key}${KV_DELIMITER}${val}${KV_SUFFIX}"

    debug "kv" "${key}:${val} → ${DIM}${kv_defn}${RESET}"
    echo "${kv_defn}"
    
    return 0
}

function kv_strip() {
    local kv="${1:?KV not provided to kv_strip fn}"

    kv=$(strip_starting "$KV_PREFIX" "$kv")
    kv=$(strip_trailing "$KV_SUFFIX" "$kv")

    echo "${kv}"
}

function is_kv_pair() {
    local -r maybe_kv="${1:-}"

    if starts_with "${KV_PREFIX}" "${maybe_kv}"; then
        if ends_with "${KV_SUFFIX}" "${maybe_kv}"; then
            debug "is_kv_pair" "true (\"${DIM}${maybe_kv}${RESET}\")"
            return 0
        fi
    fi

    debug "is_kv_pair" "false (\"${DIM}${maybe_kv}${RESET}\")"
    return 1
}

# join <str> <...list>
#
# Joins the string passed in $1 with all other parameters passed in
function join() {
    local -r join_str="${1:?the JOIN string was not passed to join}"
    local -ra list=( "${@:2}" )
    local joined=""
    for item in "${list[@]}"; do
        joined="${joined}${join_str}${item}"
    done
    echo "${joined}"
}

#shellcheck disable=SC2120
# list <[items]>
#
# Instantiates a `list` type and optionally assigns it values
function list() {
    local -a initial=("${@}")
    local list_defn=""

    for i in "${initial[@]}"; do
        list_defn="${list_defn}${LIST_DELIMITER}${i}"
    done

    list_defn=$(strip_starting "$LIST_DELIMITER" "$list_defn")
    list_defn="${LIST_PREFIX}${list_defn}${LIST_SUFFIX}"

    debug "list" "${list_defn}"
    echo "${list_defn}"

    return 0
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

# replace_substring_in_file( match, replace, file )
#
# Loads a file from the local filesystem and then looks
# for all matches to the string "match". All matched
# string will be replaced with "replace".
function replace_substring_in_file() {
    local match="${1:-not-defined}"
    local replace="${2:-not-defined}"
    local file="${3:-not-defined}"

    sed -i -e "s/${match}/${replace}/g" "${file}"
}


# shellcheck disable=SC2120
function object() {
    local -a initial=()
    if has_parameters "$@"; then
        initial=("${@}")
    fi

    local object_defn=""

    for i in "${initial[@]}"; do
        if is_kv_pair "${i}"; then
            object_defn="${object_defn}${OBJECT_DELIMITER}${i}"
        else
            warn "invalid KeyValue passed to object(): ${DIM}${i}${RESET}"
        fi
    done

    object_defn=$(strip_starting "$OBJECT_DELIMITER" "$object_defn")
    object_defn="${OBJECT_PREFIX}${object_defn}${OBJECT_SUFFIX}"

    debug "object" "${object_defn}"
    echo "${object_defn}"

    return 0
}

# object_strip <object>
#
# strips prefix and suffix and exposes just
# delimited KV's
function object_strip() {
    local obj="${1?:nothing passed into object_stript}"

    obj=$(strip_starting "${OBJECT_PREFIX}" "$obj")
    obj=$(strip_trailing "${OBJECT_SUFFIX}" "$obj")

    echo "$obj"
}

# object_to_kv_array <obj> → arr[kv]
#
# converts an object to an array of kv pairs
function object_to_kv_array() {
    local obj="${1?:nothing passed into object_stript}"
    obj=$(object_strip "$obj")
    local -a kv_arr=()
    # shellcheck disable=SC2207
    kv_arr=( $(split "${OBJECT_DELIMITER}" "${obj}") )

    echo "${kv_arr[@]}"
    return 0
}

# set <kv-pair> <obj>
# set <key> <value> <obj>
# 
# sets a key-value pair, overwriting the old key value (when it exists)
function set_value() {
    local key=""
    local value=""

    if [[ $# == 2 ]]; then
        if ! is_kv_pair "$1"; then
            error "set_value() called with two parameters but first param was not a kv-pair [ ${DIM}$1${RESET}, ${DIM}$2${RESET} ]" 1
        fi
        if ! is_object "$2"; then
            error "set_value() called with two parameters but the second param was not an object" 1
        fi
        local -ra kv_split=( split "$KV_DELIMITER" "$(kv_strip "$1")")
        key="${kv_split[0]}"
        value="${kv_split[1]}"
        debug "set_value" "two parms indicates KV pair: [ k: ${key}, v: ${value} ]"
    elif [[ $# == 3 ]]; then
        if ! is_object "$3"; then
            error "set() called with three params but the third param was not an object"
            return 1
        fi
        key="$1"
        value="$2"
        debug "set_value" "three params indicates separate key and value params: [ ${DIM}key: ${key}, value: ${value}, obj: ${3}${RESET} ]"
    fi

    local overwritten="false"
    local new_obj=""
    local -ra obj_keys=( $(keys "$obj") )

    for k in "${obj_keys[@]}"; do
        local -r v=$(get "$k" "$obj")

        if [[ "$k" == "$key" ]]; then
            # overwrite
            local -r kv=$(kv "$k" "$value") 
            new_obj="${new_obj}${OBJECT_DELIMITER}${kv}"
            debug "set_value" "overriding key of \"${k}\" to be: ${DIM}${value}${RESET}"
            overwritten="true"
        else
            # maintain in new obj
            local -r kv=$(kv "$k" "$v") 
            new_obj="${new_obj}${OBJECT_DELIMITER}${kv}"
        fi

        if [[ "$overwritten" == "false" ]]; then
            local -r kv=$(kv "$key" "$value") 
            debug "se_valuet" "the key of \"${k}\" was not in object so adding KV: ${DIM}${kv}${RESET}"
            new_obj="${new_obj}${OBJECT_DELIMITER}${kv}"
        fi
    done

    echo "${new_obj}"

}


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

function quoted() {
    local string="${1:?no string passed to quoted}"
    string=$(ensure_starting '"' "$string")
    string=$(ensure_trailing '"' "$string")
    echo "${string}"
    return 0
}

function length() {
    local -r container="${1:-empty}"
    local count=0
    if [[ "$container" == "empty" ]]; then
        debug "length" "0 (container empty)"
        echo "0"
        return 0
    fi

    if is_list "$container"; then
        count=${#$(as_array "$container")}
        debug "length" "list has ${count} elements"
    elif is_object "$container"; then
        count=${#$(keys "$container")}
        debug "length" "object has ${count} keys"
    else
        local count=$#
        debug "length" "length of parameters is ${count}"
    fi

    echo "${count}"
    return 0
}

# count_char_in_file <filepath> <chars>
function count_char_in_file {
    local -r filename="${1:?no filename passed to count_char_in_file}"
    local -r chars="${2:?no chars passed to count_char_in_file}"

    local count
    count="$(tr -d -c \'"${chars}"\' < "$filename" | awk '{ print length; }')"

    echo "${count}"
}

# count_char_in_str <content> <chars>
function count_char_in_str {
    local -r content="${1:?no filename passed to count_char_in_file}"
    local -r chars="${2:?no chars passed to count_char_in_file}"

    local -i count
    count="$(echo "${content}" | tr -d -c \'"${chars}"\' | awk '{ print length; }')"

    echo "$count"
}


function push() {
    local -r param_count="${#@}"

    debug "push" "pushing with ${param_count} parameters: ${DIM}${*}${RESET}"

    case "$param_count" in
        "1") 
            error "Invalid call to push(); only one parameter received: ${DIM}${*}${RESET}";;
        "2") 
            if is_list "${2}"; then
                local elements=""
                elements=$(list_elements "${2}")
                debug "push" "added to list [ $(length "$elements" + 1)  ]"
                echo "${LIST_PREFIX}${2}{$LIST_DELIMITER}${1}${LIST_SUFFIX}"
                return 0

            elif [[ $(is_object "${2}") && $(is_kv_pair "${1}") ]]; then
                local obj=""
                obj=$(set "$1" "$2")
                debug "push" "pushed KV into an object"
                echo "$obj"
                return 0
            else
                error "Invalid call to push(); two parameters received wrong type: ${DIM}$*${RESET}" 1
            fi
            ;;
        "3")
            if is_object "${3}"; then
                debug "push" "detected object (k:${1}, v:${2}, obj:${3})"
                local obj=""
                obj=$(object)
                obj=$(set_value "$1" "$2" "$obj")
                debug "push" "pushed a key ${ITALIC}and${RESET} value into an object [key: ${1}, value: ${2}]"
                echo "${obj}"
                return 0
            else 
                error "Invalid call to push(); three parameters but wrong types: ${DIM}${*}${RESET}" 1
            fi

            ;;
        *) error "Invalid number of parameters in call to push(). 2 or 3 are ok but received ${param_count}!  ${DIM}${*}${RESET}";;
    esac

}

# list_elements <list>
#
# strips the leading and trailing markers of a list, leaving only the
# elements
function list_elements() {
    local -r list_str="${1:?no list provided to list_elements}"
    local -r elements=$(strip_trailing "${LIST_SUFFIX}" "$(strip_starting "${LIST_PREFIX}" "${list_str}")")

    echo "${elements}"
    return 0
}

# get <index> <container>
function get() {
    local -r idx="${1:?No index value was passed to get()}"
    local -r container="${2:?No container was passed to get()}"
    debug "get" "index ${BOLD}${YELLOW}${idx}${RESET} in: ${DIM}${container}${RESET}"

    if is_list "${container}"; then
        deref=$(( idx + 0 ))
        debug "get" "container identified as a list"
        local elements=""
        elements=$(list_elements "${container}")
        elements=$(replace "${LIST_DELIMITER}" " " "${elements}")
        debug "get" "${elements}"
        # shellcheck disable=SC2207
        arr=( $(split "${LIST_DELIMITER}" "${elements}" ) )

        if (( deref > ${#arr[@]} )); then
            warn "attempt to dereference a list with an invalid index: ${DIM}${idx}${RESET}"
            debug "get" "invalid index of ${idx}"
            return 10
        else
            debug "get" "value was: ${DIM}${arr[$deref]}${RESET}"
            echo "${arr[$deref]}"
        fi

        return 0

    elif is_object "$container"; then
        local -a kv_pairs=()
        debug "get" "container is an object"
        content=$(object_strip "${container}")
        # shellcheck disable=SC2207
        kv_pairs=( $(split "${OBJECT_DELIMITER}" "$content") )
        debug "get" "object has ${#kv_pairs[@]} keys"

        for i in "${kv_pairs[@]}"; do
            i=$(kv_strip "$i")
            local -a key_value=()
            # shellcheck disable=SC2207
            key_value=( $(split "${KV_DELIMITER}" "${i}") )
            debug "get" "key: ${DIM}${key_value[0]}${RESET}, value:  ${DIM}${key_value[1]}${RESET}"

            if [[ "$idx" == "${key_value[0]}" ]]; then
                debug "get" "matched index to value: ${DIM}${key_value[1]}${RESET}"
                echo "${key_value[1]}"
                return 0
            fi
        done

        error "\"${idx}\" used as an invalid dereferencing key to an object" 
        return "$ERR_INVALID_DEREF_KEY"
    fi

    debug "get" "container type not known: ${DIM}: ${container} ${RESET}"
    return "$ERR_UNKNOWN_CONTAINER_TYPE"
}


function as_array() {
    local container="${1:?as_array() did not receive a value}"
    if is_list "${container}"; then
        elements=$(list_elements "${container}")
        #shellcheck disable=SC2206
        local -a arr=( ${elements//"${LIST_DELIMITER}"/ } )

        debug "as_array" "array of length ${#arr[@]}: [ ${arr[*]} ]"
        echo "${arr[@]}"

        return 0
    fi

    if is_object "${container}"; then
        local -ra arr=( $(object_to_kv_array "${container}") )
        echo "${arr[@]}"
        return 0
    fi

    debug "as_array" "container pattern not recognized: ${DIM}${1}${RESET}"
    return 1
}

function first() {

    if is_kv_pair "$1"; then
        local -r kv=$(kv_strip "$1")
        local -ra pair=( $(split "${KV_DELIMITER}" "$kv" ) )
        debug "first" "found a kv-pair [${#pair[@]}]: ${DIM}${pair[*]} -> ${pair[0]}${RESET}"
        echo "${pair[0]}"
        return 0
    fi

    if is_list "$1"; then
        local -a arr=()
        arr=( $(as_array "$1") ) 
        debug "first" "found a list [${#arr[@]}]: ${DIM}${arr[0]}${RESET}"
        echo "${arr[0]}"
        return 0
    fi
    
    if is_array "$@"; then
        debug "first" "found an array [${#${@}}]: ${DIM}${1}${RESET}"
        echo "$1"
        return 0
    fi

    debug "first" "failed to match container type in call to first(); ${DIM}${1}${RESET}"
    return 1
}

function last() {

    if is_kv_pair "$1"; then
        local -r kv=$(kv_strip "$1")
        local -ra pair=( $(split "${KV_DELIMITER}" "$kv" ) )
        debug "last" "found a kv-pair [${#pair[@]}]: ${DIM}${pair[*]} -> ${pair[1]}${RESET}"
        echo "${pair[1]}"
        return 0
    fi

    if is_list "$1"; then
        local -a arr=()
        arr=( $(as_array "$1") ) 
        debug "last" "found a list [${#arr[@]}]: ${DIM}${arr[0]}${RESET}"
        echo "${arr[-1]}"
        return 0
    fi
    
    if is_array "$@"; then
        local -r idx=$(( $# -1 ))
        local -r last=${idx}
        debug "last" "found an array [${#${@}}]: ${DIM}${last}${RESET}"
        echo "${last}"
        return 0
    fi

    debug "first" "failed to match container type in call to first(); ${DIM}${1}${RESET}"
    return 1
}

# keys <object>
#
# Returns an array of keys for a given object
function keys() {
    local obj="${1:?no parameters passed into keys()}"
    local -a items=()
    if ! is_object "${obj}"; then
        debug "keys" "invalid object: ${DIM}${obj}${RESET}"
        return 1
    else
        # shellcheck disable=SC2207
        local -ra kvs=( $(object_to_kv_array "$obj") )

        for kv in "${kvs[@]}"; do
            local -a key=""
            key=$(first "$kv")
            debug "keys" "kv: ${kv}, key: ${key}"
            items+=( "${key}" )
        done

        debug "keys" "${items[*]}"
        echo "${items[@]}"
        return 0
    fi
    # while read -r line; do items+=("$line"); done <<< "$(split "${DICT_DELIMITER}" "$dict_hash"))"

}

# dict_add <key> <value> <list>
#
# Adds 
function dict_add() {
    local -r key="${1:?the KEY was not passed to dict_add}"
    local -r val="${2:?the VALUE was not passed to dict_add}"
    local -a dict_hash="${3}"

    kv=$(kv "${key}" "${val}" "${KV_DELIMITER}") || (error "failed to create KV while trying to add to dictionary" && exit 1)

    dict_hash+=( "${kv}" )

    echo "${dict_hash[@]}"
    return 0
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

# find_in_file <filepath> <key>
#
# Finds the first occurance of <key> in the given file
# and if that line is the form "<key>=<value>" then 
# it returns the value, otherwise it will return 
# the line.
function find_in_file() {
    local -r filepath="${1:?find_in_file() called but no filepath passed in!}"
    local -r key="${2:?find_in_file() called but key value passed in!}"


}


function directory_exists() {
    local dir="${1:?directory is missing}"

    if [[ -d "${dir}" ]]; then
        return 0;
    else
        return 1;
    fi    
}

function get_file() {
    local -r filepath="${1:?get_file() called but no filepath passed in!}"
    
    if file_exists "${filepath}"; then
        debug "get_file(${filepath})" "getting data"
        local content
        { IFS= read -rd '' content <"${filepath}";} 2>/dev/null
        printf '%s' "${content}"
    else
        debug "get_file(${filepath})" "call to get_file(${filepath}) had invalid filepath"
        return 1
    fi
}

function get_moxy_config() {
    if file_exists "${PWD}/.moxy"; then
        get_file "${PWD}/.moxy"
    elif file_exists "${HOME}/.moxy"; then
        get_file "${HOME}/.moxy"
    else
        debug "- no moxy config file found"
        echo "is_first_run=true"
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

# get_env <variable name> <default>
#
# Get's an ENV variable name when defined or returns <default>
function get_env() {
    local -r var="${1:?has_env() called but no variable name passed in!}"
    local -r def_val="${2:-false}"
    if has_env "$var"; then
        log "${var}"
    else
        log "${def_val}"
    fi
}

# get_files <base_dir> <regex> [filter1 filter2 ...]
#
# Returns a list of files from a base directory (and all subdirectories) which
# match a certain regex pattern.
# 
# - it ALWAYS excludes files from ".git"
# - you may use the '--relative' flag in the filter params to force all file
#   paths to be relative to the base directory
# - any filter params will be "wildcarded" (e.g., 'local' passed in converts
#   to the path of '*local*')
# - Errors:
#   1 - invalid base directory
#   2 - error running "find" command
#   3 - other
#
# parameters:
# - $1 [required] provides a base directory to start the search
# - $2 [required] provides the regex expression to look for
# - $3.. [opt] provides a list of filters where ANY can eliminate the match
function get_files() {
    local -r BASE="${1:?base directory must be provided to get_files}"
    local -r FIND="${2:?RegEx to search for must be provided to get_files}"


    if ! directory_exists "${BASE}"; then
        error "The base directory \"${BASE}\" passed to get_files() is not valid!"
        return 1
    fi

    local BASE_CMD="-type f -not -path \"*.git*\" -path '${FIND}'"
    local ABS_OR_REL="ABS"

    ARGS=( "${@}" )

    for filter in "${ARGS[@]:2}"; do 
        if [[ "${filter}" == "--relative"  ]]; then
            ABS_OR_REL="REL"
        elif starts_with '!' "${filter}"; then
            filter="$(strip_starting "!" "${filter}")"
            BASE_CMD="${BASE_CMD} -not -path \"*${filter}*\""
        else
            BASE_CMD="${BASE_CMD} -path \"*${filter}*\""
        fi
    done

    if [[ "${ABS_OR_REL}" == "ABS" ]]; then
        BASE_CMD="find ${BASE} ${BASE_CMD}"
        RESULT=$(eval "${BASE_CMD}")
        echo "${RESULT}"
    else
        BASE_CMD="find . ${BASE_CMD}"
        RETURN="${PWD}"
        cd "${BASE}" || exit 1
        if RESULT=$(eval "${BASE_CMD}"); then
            cd "${RETURN}" > /dev/null || exit 3
            echo "${RESULT}"
            return 0
        else 
            error "Failed to run the find command in get_files()"
            cd "${RETURN}" > /dev/null || exit 3
            return 2
        fi
    fi
}

# destruct
#
# syntax:
#   destruct a,b,c = ${my_arr}
#   destruct a, b, c = ${my_arr}
#
# destructuring assignment for arrays
function destruct() {
    # all but last two params constitute the variable names
    local -ra initial_inputs=( "${@:1:$#-2}" )
    local -a variable_names=()
    # the input array is the last parameter in $@
    local -ra input_arr=( "${@:-1}" )

    # first, we need to finalize the variable names
    for i in "${initial_inputs[@]}"; do
        if [[ "$i" =~ "," ]]; then
            local -a vars=()
            # shellcheck disable=SC2207
            vars=( $(split "," "$i") )
            variable_names+=( "${vars[@]}" )
        else
            variable_names+=("$i")
        fi
    done

    # now we can 
    idx=0

    for name in "${variable_names[@]}"; do
        local var_value=""
        declare -g "${name}=${var_value}"
    done

    # for ((i=0; i < ${#variable_names[@]}; i++)) do 
    #     local value_name="${!#}[$i]"
    #     declare -g """${var_names[$i]}""=${!value_name}"
    # done
}

_iterator() {
    local payload="${1:?no payload received by _iterator()}"
    # shellcheck disable=SC2317
    function api_surface() {
        local -r cmd="${1:?no command provided to a call of the iterator\'s api }"

        case $cmd in


            "value")
                echo "$payload"
                return 0
                ;;

            "next") echo "TODO";;

            "take") echo "TODO";;

            *)
                error "Unknown command sent to iterable API: ${DIM}${cmd}${RESET}" "$ERR_UNKNOWN_COMMAND"
                ;;
        esac
    }

}


# as_iterable <object|list|array> → <iterable>
function as_iterator() {
    local maybe_iterable="${1:?iterator fn did not receive any parameters}"
    local -xf api

    if is_list "${maybe_iterable}"; then
        debug "iterator" "payload detected as a list"
        
        # shellcheck disable=SC2317
        function api_surface() {
            local -r cmd="${1:?no command provided to a call of the iterator\'s api }"

            case $cmd in

                "value")
                    echo "TODO"
                    ;;

                "next") echo "TODO";;

                "take") echo "TODO";;

                *)
                    error "Unknown command sent to iterable API: ${DIM}${cmd}${RESET}" "$ERR_UNKNOWN_COMMAND"
                    ;;
            esac
        }
        api=api_surface
        echo "${api}"
        return 0
    fi

    if is_kv_pair "${maybe_iterable}"; then
        debug "iterator" "payload detected as KV pair"
        local -ra payload=( "$(as_array "$maybe_iterable")" )
        # shellcheck disable=SC2317
        function api_surface {
            local -r cmd="${1:?no command provided to a call of the iterator\'s api }"
            local 

            case $cmd in 


                *)
                    error "Unknown command sent to iterable API: ${DIM}${cmd}${RESET}" "$ERR_UNKNOWN_COMMAND"
                    ;;
            esac
        }


    fi

    error "Unexpected outcome from calling iterator() fn" "$ERR_UNEXPECTED_OUTCOME"
}

