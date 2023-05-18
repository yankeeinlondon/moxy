#!/usr/bin/env bash

LIST_DELIMITER="${LIST_DELIMITER:-|*|}"
LIST_PREFIX="list::[ "
LIST_SUFFIX=" ]"
OBJECT_PREFIX="${OBJECT_PREFIX:-object::{}"
OBJECT_SUFFIX="${OBJECT_SUFFIX:-}}"
OBJECT_DELIMITER="${OBJECT_DELIMITER:- |,| }"
KV_PREFIX="${KV_PREFIX:-kv[}"
KV_SUFFIX="${KV_SUFFIX:-]}"
KV_DELIMITER="${KV_DELIMITER:-→}"
DEBUG="${DEBUG:-false}"

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

function log() {
    printf "%b\\n" "${*}" >&2
}

function debug() {
    if [[ "${DEBUG}" != "false" ]]; then
        if (( $# > 1 )); then
            local -r fn="$1"
            shift
            log "       ${GREEN}◦${RESET} ${BOLD}${fn}()${RESET} → ${*}"
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

function error() {
    log "${RED}ERROR ${RESET} ==> ${*}"
}



function has_command() {
    local -r cmd="${1:?cmd is missing}"

    if eval "which ${cmd}" >/dev/null; then
        return 0; # exists
    else
        return 1; # does not exist
    fi
}

# ends_with <look-for> <content>
function ends_with() {
    local -r look_for="${1:?No look-for string provided to ends_with}"
    local -r content="${2:?No content string provided to ends_with}"
    local -r no_suffix="${content%"${look_for}"}"
    debug "ends_with" "checking whether the content ends with \"${look_for}\""

    if [[ "${content}" == "${no_suffix}" ]]; then
        return 1;
    else
        return 0;
    fi
}

# starts_with <look-for> <content>
function starts_with() {
    local -r look_for="${1:?No look-for string provided to starts_with}"
    local -r content="${2:-}"

    if [[ "${content}" == "${content#"$look_for"}" ]]; then
        return 1; # was not present
    else
        return 0; # found "look_for"
    fi
}

# ensure_trailing <ensured-str> <content>
#
# ensures that the "content" will end with the <ensured-str>
function ensure_trailing() {
    local -r ensured="${1:?No ensured string provided to ensure_trailing}"
    local -r content="${2:?No content string provided to ensure_trailing}"

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
    local -r content="${2:?No content string provided to ensure_starting}"

    if starts_with "${ensured}"; then
        echo "${content}"
    else
        echo "${ensured}${content}"
    fi

    return 0
}

# avoid_starting <avoid-str> <content>
#
# ensures that the "content" will NOT start with the <avoid-str>
function avoid_starting() {
    local -r avoid="${1:?No avoid string provided to ensure_starting}"
    local -r content="${2}"

    echo "${content#"$avoid"}"

    return 0
}

function avoid_trailing() {
    local -r avoid="${1:?No avoid string provided to ensure_starting}"
    local -r content="${2:?No content string provided to ensure_starting}"

    echo "${content%"$avoid"}"

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

function contains() {
    local -r match="${1:?match expression not passed to extract}"
    local -ra list=( "${@:2}" )
    
    for item in "${list[@]}"; do
        if [[ "${item}" == "${match}" ]]; then
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

function is_kv_pair() {
    local -r maybe_kv="${1:-}"

    if starts_with "${KV_PREFIX}" "${maybe_kv}"; then
        if ends_with "${KV_SUFFIX}" "${maybe_kv}"; then
            debug "is_kv_pair" "true"
            return 0
        fi
    fi

    debug "is_kv_pair" "false (${maybe_kv})"
    return 1
}

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

    list_defn=$(avoid_starting "$LIST_DELIMITER" "$list_defn")
    list_defn="${LIST_PREFIX}${list_defn}${LIST_SUFFIX}"

    debug "list" "${list_defn}"
    echo "${list_defn}"

    return 0
}

function is_list() {
    local -r content="${1:-}"
    debug "is_list" "checking whether this is a list: ${content}"
    if starts_with "${LIST_PREFIX}" "${content}"; then
        debug "is_list" "[1 of 2] starts with list prefix"
        if ends_with "${LIST_SUFFIX}" "${content}"; then
            debug "is_list" "[2 of 2] ends with list suffix"
            return 0
        else
            debug "is_list" "the prefix matched the content but not the suffix: \"${LIST_SUFFIX}\""
            debug "is_list" "${content}"
        fi
    fi

    return 1
}

function object() {
    local -a initial=("${@}")
    local object_defn=""

    for i in "${initial[@]}"; do
        if is_kv_pair "${i}"; then
            object_defn="${object_defn}${OBJECT_DELIMITER}${i}"
        else
            warn "invalid KeyValue passed to object(): ${DIM}${i}${RESET}"
        fi
    done

    object_defn=$(avoid_starting "$OBJECT_DELIMITER" "$object_defn")
    object_defn="${OBJECT_PREFIX}${object_defn}${OBJECT_SUFFIX}"

    debug "object" "${object_defn}"
    echo "${object_defn}"

    return 0
}

function push() {
    local -r item="${1:?No new item was given to push fn}"
    local items="${2:-$(list)}"

    if ! is_list "${items}"; then
        error "the LIST sent to push() function was invalid! [ ${items} ]"
        return 1
    fi

    items=$(list )
}

# list_elements <list>
#
# strips the leading and trailing markers of a list, leaving only the
# elements
function list_elements() {
    local -r list_str="${1:?no list provided to list_elements}"
    local -r elements=$(avoid_trailing "${LIST_SUFFIX}" "$(avoid_starting "${LIST_PREFIX}" "${list_str}")")

    echo "${elements}"
    return 0
}

# get <container> <index>
#
# dereferences an element from a container where a "container" can be:
#   - a "list"
#   - an "object"
#   - a bash array
#   - an associative bash array
function get() {
    local -r container="${1:?No container was passed to get()}"
    local -r idx="${2:?No index value was passed to get()}"
    debug "get" "container passed in: ${container}, with index of: ${idx}"

    if is_list "${container}"; then
        deref=$(( idx + 0 ))
        debug "get" "container identified as a list"
        local elements=""
        elements=$(list_elements "${container}")
        elements=$(replace "${LIST_DELIMITER}" " " "${elements}")
        debug "get" "${elements}"
        arr=( ${elements//${LIST_DELIMITER} / } )
        
        if (( $deref > ${#arr[@]} )); then
            warn "attempt to dereference a list with an invalid index: ${DIM}${idx}${RESET}"
            debug "get" "invalid index of ${idx}"
            return 10
        else
            echo "${arr[$deref]}"
        fi

        return 0
    fi

    debug "get" "container type not known"
    return 5
}

function split() {
    local -r content="${1:?the CONTENT string was not passed to split}"
    local -r split_str="${2:- \n\t}"
    local items=""

    items=$(list)

    IFS=${split_str} read -ra ITEMS <<< "$content"

    for i in "${ITEMS[@]}"; do
        items="$(push "${i}" "${items}")"
    done

    info "${items}"
    echo "${items}"
    return 0
}

function as_array() {
    local input="${1:?as_array() did not receive a value}"
    if is_list "${input}"; then
        elements=$(list_elements "${input}")
        #shellcheck disable=SC2206
        local -a arr=( ${elements//"${LIST_DELIMITER}"/ } )

        debug "as_array" "array of length ${#arr[@]}: [ ${arr[*]} ]"
        echo "${arr[@]}"

        return 0
    fi
}


function keys() {
    local dict_hash="${1:?the dictionary hash was not passed into keys}"
    local -a items=()
    while read -r line; do items+=("$line"); done <<< "$(split "${DICT_DELIMITER}" "$dict_hash"))"
    
    local content=""

    for i in "${items[@]}"; do
        content="${content}${i}"
    done
    echo "${content}"
    return 0
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


function file_exists() {
    local filepath="${1:?filepath is missing}"

    if [[ -f "${filepath}" ]]; then
        return 0;
    else
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
            filter="$(avoid_starting "!" "${filter}")"
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

# destruct <v1> ... <vX> = <arr>
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
            local -a vars=$(split "," "$i")
            variable_names+=(  )
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


function length() {
    return "${#[@]}"
}


