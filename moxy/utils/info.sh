#!/usr/bin/env bash

# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./conditionals.sh"
. "./utils/conditionals.sh"
# shellcheck source="./mutate.sh"
. "./utils/mutate.sh"

function shell_options() {
    local current_state=""
    current_state=$(printf %s\\n "$-")

    debug "shell_options" "${current_state}"
    echo "${current_state}"
    return 0
}

# find_in_file <filepath> <key>
#
# Finds the first occurance of <key> in the given file
# and if that line is the form "<key>=<value>" then 
# it returns the <value>, otherwise it will return 
# the line.
function find_in_file() {
    local -r filepath="${1:?find_in_file() called but no filepath passed in!}"
    local -r key="${2:?find_in_file() called but key value passed in!}"

    if file_exists "${filepath}"; then
        debug "find_in_file(${filepath})" "file found"
        local -a found=()

        while read -r line; do
            if not_empty "${line}" && contains "${line}" "${key}"; then
                if starts_with "${key}=" "${line}"; then
                    found+=("$(strip_leading "${key}=" "${line}")")
                else
                    found+=("${line}")
                fi
            fi
        done < "$filepath"

        echo "${found[0]}"
    else
        debug "find_in_file(${filepath})" "no file at filepath"
        return 1
    fi
}


# distro_version() <[vmid]>
#
# will try to detect the linux distro's version id and name 
# of the host computer or the <vmid> if specified.
function distro_version() {
    local -r vm_id="$1:-"

    if [[ $(os "$vm_id") == "linux" ]]; then
        if file_exists "/etc/os-release"; then
            local -r id="$(find_in_file "VERSION_ID=" "/etc/os-release")"
            local -r codename="$(find_in_file "VERSION_CODENAME=" "/etc/os-release")"
            echo "${id}/${codename}"
            return 0
        fi
    else
        error "Called distro() on a non-linux OS [$(os "$vm_id")]!"
    fi
}

# distro() <[vmid]>
#
# will try to detect the linux distro of the host computer
# or the <vmid> if specified.
function distro() {
    local -r vm_id="$1:-"

    if [[ $(os "$vm_id") == "linux" ]]; then
        if file_exists "/etc/os-release"; then
            local -r name="$(find_in_file "ID=" "/etc/os-release")" || "$(find_in_file "NAME=" "/etc/os-release")"
            echo "${name}"
            return 0
        fi
    else
        error "Called distro() on a non-linux OS [$(os "$vm_id")]!"
    fi
}

# os() <[vmid]>
#
# will try to detect the operating system of the host computer
# or a container if a <vmid> is passed in as a parameter.
function os() {
    local -r vm_id="$1"
    local -r os_type=$(lc "${OSTYPE}") || "$(lc "$(uname)")" || "unknown"

    if is_empty "${vm_id}"; then
        case "$os_type" in
            'linux'*)
                if distro "$vm_id"; then 
                    echo "linux/$(distro "${vm_id}")/$(distro_version "$vm_id")"
                else
                    echo "linux"
                fi
                ;;
            'freebsd'*)
                echo "freebsd"
                ;;
            'windowsnt'*)
                echo "windows"
                ;;
            'darwin'*) 
                echo "macos/$(strip_before "darwin" "${OSTYPE}")"
                ;;
            'sunos'*)
                echo "solaris"
                ;;
            'aix'*) 
                echo "aix"
                ;;
            *) echo "unknown/${os_type}"
            esac
    fi
}

# findall_in_file <filepath> <key>
#
# Finds all occurances of <key> in the given file
# and if that line is the form "<key>=<value>" then 
# it returns the an array of values.
function findall_in_file() {
    local -r filepath="${1:?find_in_file() called but no filepath passed in!}"
    local -r key="${2:?find_in_file() called but key value passed in!}"

    if file_exists "${filepath}"; then
        debug "find_in_file(${filepath})" "file found"
        local -a found=()

        while read -r line; do
            if not_empty "${line}" && contains "${line}" "${key}"; then
                if starts_with "${key}=" "${line}"; then
                    found+=("$(strip_leading "${key}=" "${line}")")
                else
                    found+=("${line}")
                fi
            fi
        done < "$filepath"

        printf "%s\n" "${found[@]}"
    else
        debug "find_in_file(${filepath})" "no file at filepath"
        return 1
    fi
}


# flags <array|list> → [ params, flags ]
#
# Looks for any "flags" in an array or list -- where a 
# flag is a string starting in "-" -- and returns
# an array of two lists: `[ params, flags ]`
function flags() {
    local -r maybe_list="$1:-"
    local -a items=()
    params=$(@list)
    flags=$(@list)

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

# ui_availability() → [whiptail|dialog|ERROR]
#
# tests whether "whiptail" or "display" 
# (https://invisible-island.net/dialog/) packages are 
# available on the execution platform. 
# 
# For PVE hosts "whiptail" should always be available.
function ui_availability() {
    if has_command "whiptail"; then
        debug "ui_availability" "has whiptail"
        return 0
    elif has_command "dialog"; then
        debug "ui_availability" "no whiptail but has dialog"
        return 0
    else
        debug "ui_availability()" "Neither ${GREEN}whiptail${RESET} nor ${GREEN}dialog${RESET} found on host! One of these is required for the TUI of Moxy to run."
        return 1
    fi
}

function typeof() {
    local -n _var_type=$1

    if is_array _var_type; then
        echo "array"
    elif is_assoc_array _var_type; then
        echo "assoc-array"
    elif is_numeric _var_type; then
        echo "number"
    elif is_list _var_type; then
        echo "list"
    elif is_kv_pair _var_type; then
        echo "kv"
    elif is_object _var_type; then
        echo "object"
    elif is_empty "${_var_type}"; then
        echo "empty"
    else
        echo "string"
    fi

}

# get <index> <container>
#
# Gets the value of a a <container> by <index>
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


# first() <container>
#
# Gets the first value from a <container> where container is distinguished
# between being a "kv_pair", a "list", or an "array".
function first() {

    if is_kv_pair "$1"; then
        local -r kv=$(kv_strip "$1")
        # shellcheck disable=SC2207
        local -ra pair=( $(split "${KV_DELIMITER}" "$kv" ) )
        debug "first" "found a kv-pair [${#pair[@]}]: ${DIM}${pair[*]} -> ${pair[0]}${RESET}"
        echo "${pair[0]}"
        return 0
    fi

    if is_list "$1"; then
        local -a arr=()
        # shellcheck disable=SC2207
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

# last() <container>
#
# Gets the last value from a <container> where container is distinguished
# between being a "kv_pair", a "list", or an "array".
function last() {

    if is_kv_pair "$1"; then
        local -r kv=$(kv_strip "$1")
        # shellcheck disable=SC2207
        local -ra pair=( $(split "${KV_DELIMITER}" "$kv" ) )
        debug "last" "found a kv-pair [${#pair[@]}]: ${DIM}${pair[*]} -> ${pair[1]}${RESET}"
        echo "${pair[1]}"
        return 0
    fi

    if is_list "$1"; then
        local -a arr=()
        # shellcheck disable=SC2207
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


# push() <container> <...values>
#
# Pushes new <values> onto the <container>
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
    local -r elements=$(strip_trailing "${LIST_SUFFIX}" "$(strip_leading "${LIST_PREFIX}" "${list_str}")")

    echo "${elements}"
    return 0
}


# get_file() <filepath>
#
# Gets the content from a file at the given <filepath>
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


# get_MOXY_CONFIG_FILE()
#
# gets the `.moxy` configuration file
function get_MOXY_CONFIG_FILE() {
    if file_exists "${PWD}/.moxy"; then
        get_file "${PWD}/.moxy"
    elif file_exists "${HOME}/.moxy"; then
        get_file "${HOME}/.moxy"
    else
        debug "- no moxy config file found"
        echo "is_first_run=true"
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
            filter="$(strip_leading "!" "${filter}")"
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

# using_bash_3
#
# tests whether the host OS has bash version 3 installed
function using_bash_3() {
    local -r version=$(bash_version)

    if starts_with "3" "${version}"; then
        debug "using_bash_3" "IS version 3 variant!"
        return 0
    else
        debug "using_bash_3" "is not version 3 variant"
        return 1
    fi
}

# bash_version()
#
# returns the version number of bash for the host OS
function bash_version() {
    local version
    version=$(bash --version)
    version=$(strip_after "(" "$version")
    version=$(strip_before "version " "$version")

    echo "$version"
}
