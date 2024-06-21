#!/usr/bin/env bash

# shellcheck source="./logging.sh"
. "./utils/logging.sh"


# replace_substring_in_file() <match> <replace> <file>
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

# replace_line_in_file() <filepath> <find> <new-line>
#
# loads a file <filepath> and searches for a line which has <find>; if found
# it will return 0 otherwise it will raise an error.
function replace_line_in_file() {
    local -r filepath="${1:?no filepath was passed to replace_line_in_file()}"
    local -r find="${2:?no find string passed to replace_line_in_file()}"
    local -r new_line="${3:?no new_line string passed to replace_line_in_file()}"

    local file_changed="false"
    local -a new_content=()

    if file_exists "$filepath"; then
        local -ra content=$(get_file "${filepath}")
        for line in "${content[@]}"; do
            if not_empty "${line}" && contains "${find}" "${line}" && [[ "$file_changed" == "false" ]]; then
                new_content+=("$new_line")
                file_changed="true"
            else
                new_content+=("$line")
            fi
        done

        if [[ "$file_changed" == "true" ]]; then
            printf "%s\n" "${new_content[@]}"
            return 0
        else
            debug "replace_line_in_file()" "the string '${find}' was not found in the file '${filepath}'"
            return 1
        fi
    fi
}

# major_version() <semver>
#
# given a semver version number, this extracts the major version number
function major_version() {
    local -r semver="${1:?no semver version number provided to major_version()}"
    local -ra parts=($(split_on "." "${semver}"))

    echo "${parts[0]}"
}


# nbsp()
#
# prints a non-breaking space to STDOUT
function nbsp() {
    printf '\xc2\xa0'
}

# split_on <delimiter> <content> → array
#
# splits string content on a given delimiter and returns
# an array
function split_on() {
    local -r delimiter="${1:-not-specified}"
    local content="${2:-no-content}"
    local -a parts=()

    if [ "$delimiter" == "not-specified" ] && [ "$content" == "no-content" ]; then
        debug "split_on" "no parameters provided!"
        error "split_on() called with no parameters provided!" 10
    elif [[ "$delimiter" == "not-specified" ]]; then
        debug "split_on" "split string not specified so will use <space>"
        delimiter=" "
    elif [[ "$content" == "no-content" ]]; then
        debug "split_on" "no content, will return empty array but this may be a mistake"
        echo "${items[@]}"
        return 0
    fi
    debug "split_on" "splitting string using \"${YELLOW}${BOLD}${delimiter}${RESET}\" delimiter"

    content="${content}${delimiter}"
    while [[ "$content" ]]; do
        parts+=( "${content%%"$delimiter"*}" )
        content=${content#*"$delimiter"}
    done

    debug "split_on" "split into ${YELLOW}${BOLD}${#parts[@]}${RESET} parts: ${DIM}${parts[*]}${RESET}"

    echo "${parts[@]}"
    return 0
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

function kv_strip() {
    local kv="${1:?KV not provided to kv_strip fn}"

    kv=$(strip_leading "$KV_PREFIX" "$kv")
    kv=$(strip_trailing "$KV_SUFFIX" "$kv")

    echo "${kv}"
}


# join <str> <...list>
#
# Joins the all the parameters passed in to a single
# string. Note: at least one parameter is required.
function join() {
    local -r join_str="${1:?the JOIN string was not passed to join}"
    local -ra list=( "${@:2}" )
    local joined=""
    for item in "${list[@]}"; do
        joined="${joined}${join_str}${item}"
    done
    echo "${joined}"
}

# join_with <delimiter> <...list>
#
# Joins the all the parameters passed in to a single
# string using <delimiter> between each parameter.
function join_with() {
    local -r delimiter="${1:?the delimiter was not passed to join_with(delimiter, ...list)}"
    # shellcheck disable=SC2207
    local -ra list=($( as_array "${@:2}" ))
    local joined=""
    debug "join_with(${delimiter})" "joining ${#list[@]} items"
    for item in "${list[@]}"; do
        if [[ "$joined" == "" ]]; then
            joined="${item}"
        else
            joined="${joined}${delimiter}${item}"
        fi
    done
    echo "${joined}"
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

# list <[items]>
#
# Instantiates a `list` type and optionally assigns it values
function list() {
    local -a initial=("${@}")
    local list_defn=""

    for i in "${initial[@]}"; do
        list_defn="${list_defn}${LIST_DELIMITER}${i}"
    done

    list_defn=$(strip_leading "$LIST_DELIMITER" "$list_defn")
    list_defn="${LIST_PREFIX}${list_defn}${LIST_SUFFIX}"

    debug "list" "${list_defn}"
    echo "${list_defn}"

    return 0
}

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

    object_defn=$(strip_leading "$OBJECT_DELIMITER" "$object_defn")
    object_defn="${OBJECT_PREFIX}${object_defn}${OBJECT_SUFFIX}"

    debug "object" "${object_defn}"
    echo "${object_defn}"

    return 0
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

# object_strip <object>
#
# strips prefix and suffix and exposes just
# delimited KV's
function object_strip() {
    local obj="${1?:nothing passed into object_stript}"

    obj=$(strip_leading "${OBJECT_PREFIX}" "$obj")
    obj=$(strip_trailing "${OBJECT_SUFFIX}" "$obj")

    echo "$obj"
}

# length() <subject>
#
# returns the length of <subject> where <subject> can be
# a "array", "object", "list"
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

# as_array() <container>
#
# Ensures that <container> is a bash array and will convert
# lists, objects, and proxy normal arrays
function as_array() {
    local container="${1:?as_array() did not receive a value}"

    if is_list "${container}"; then
        elements=$(list_elements "${container}")
        #shellcheck disable=SC2206
        local -a arr=( ${elements//"${LIST_DELIMITER}"/ } )

        debug "as_array" "array of length ${#arr[@]}: [ ${arr[*]} ]"
        printf "%s\n" "${arr[@]}"

        return 0
    fi

    if is_object "${container}"; then
        # shellcheck disable=SC2207
        local -ra arr=( $(object_to_kv_array "${container}") )
        printf "%s\n" "${arr[@]}"
        return 0
    fi

    if has_newline "${container}"; then
        debug "as_array()" "because it's a string with newline characters we'll assume it already was an array"
        printf "%s" "$container"
        return 0
    fi


    debug "as_array" "container pattern not recognized: ${DIM}${1}${RESET}"
    return 1
}

# dict_add <key> <value> <list>
#
# Adds a new key and value to an "object"
function dict_add() {
    local -r key="${1:?the KEY was not passed to dict_add}"
    local -r val="${2:?the VALUE was not passed to dict_add}"
    local -a dict_hash="${3}"

    kv=$(kv "${key}" "${val}" "${KV_DELIMITER}") || (error "failed to create KV while trying to add to dictionary" && exit 1)

    dict_hash+=( "${kv}" )

    echo "${dict_hash[@]}"
    return 0
}


# lc() <str>
#
# converts the passed in <str> to lowercase
function lc() {
    local -r str="${1-}"
    echo "${str}" | tr '[:upper:]' '[:lower:]'
}

# uc() <str>
#
# converts the passed in <str> to uppercase
function uc() {
    local -r str="${1-}"
    echo "${str}" | tr -s '[:lower:]' '[:upper:]'
}

# quoted() <str>
#
# puts double quotes around a <str> passed in
function quoted() {
    local string="${1:?no string passed to quoted}"
    string=$(ensure_starting '"' "$string")
    string=$(ensure_trailing '"' "$string")
    echo "${string}"
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
    # shellcheck disable=SC2207
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


# ensure_trailing <ensure> <content>
#
# ensures that the "content" will end with the <ensure>
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

# ensure_starting <ensure> <content>
#
# ensures that the "content" will start with the <ensure>
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

# strip_leading <avoid-str> <content>
#
# ensures that the "content" will NOT start with the <avoid-str>
function strip_leading() {
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
