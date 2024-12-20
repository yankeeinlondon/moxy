#!/usr/bin/env bash

# shellcheck source="./env.sh"
. "./utils/env.sh"
# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./errors.sh"
. "./utils/errors.sh"
# shellcheck source="./conditionals.sh"
. "./utils/conditionals.sh"


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

# replace_line_in_file_or_append() <filepath> <find> <new-line>
#
# loads a file <filepath> and searches for a line which has <find>; 
# if found it will replace that line with <new-line> but if not
# found it will append this to the end of the file.
function replace_line_in_file_or_append() {
    local -r filepath="${1:?no filepath was passed to replace_line_in_file()}"
    local -r find="${2:?no find string passed to replace_line_in_file()}"
    local -r new_line="${3:?no new_line string passed to replace_line_in_file()}"

    local file_changed="false"
    local -a new_content=()

    if file_exists "$filepath"; then
        if ! replace_line_in_file "${filepath}" "${find}" "${new_line}"; then
            printf "%s\n" "${new_line}" >> "${filepath}"
        fi
    fi
}

# major_version() <semver>
#
# given a semver version number, this extracts the major version number
function major_version() {
    local -r semver="${1:?no semver version number provided to major_version()}"
    local -a parts
    # shellcheck disable=SC2207
    parts=( $(split_on "." "${semver}") )

    echo "${parts[0]}"
}


# nbsp()
#
# prints a non-breaking space to STDOUT
function nbsp() {
    printf '\xc2\xa0'
}

function space_to_nbsp() {
    local -r input="${1}"

    if not_empty "$input"; then
        printf "%s" "${input// /$(nbsp)}"
    else
        echo ""
    fi
}

function nbsp_to_space() {
    local -r input="${1}"

    if not_empty "$input"; then
        printf "%s" "${input//$(nbsp)/ }"
    else
        echo ""
    fi
}

# split_on <delimiter> <content> <ref:array>
#
# splits string content on a given delimiter and returns
# an array
function split_on() {
    local -r delimiter="${1:-not-specified}"
    local content="${2:-no-content}"
    local retain="${3:-false}"
    local -a parts=()

    if [ "$delimiter" == "not-specified" ] && [ "$content" == "no-content" ]; then
        debug "split_on" "no parameters provided!"
        error "split_on() called with no parameters provided!" 10
    elif [[ "$delimiter" == "not-specified" ]]; then
        debug "split_on" "delimiter string not specified so will use <space>"
        delimiter=" "
    elif [[ "$content" == "no-content" ]]; then
        debug "split_on" "no content, will return empty array but this may be a mistake"
        echo "${items[@]}"
        return 0
    fi
    debug "split_on" "splitting string using \"${YELLOW}${BOLD}${delimiter}${RESET}\" delimiter"

    content="${content}${delimiter}"
    while [[ "$content" ]]; do
        if [[ "$retain" == "true" ]]; then
            parts+=( "${content%%"$delimiter"*}${delimiter}" )
        else
            parts+=( "${content%%"$delimiter"*}" )
        fi
        content=${content#*"$delimiter"}
    done

    debug "split_on" "split into ${YELLOW}${BOLD}${#parts[@]}${RESET} parts: ${DIM}${parts[*]}${RESET}"

    printf "%s" "${parts[*]}"
}


# replace <find> <replace> <content>
#
# Looks for "find" in the "content" string passed in and replaces it
# with "replace".
function replace() {
    local -r find="${1:?the FIND string was not passed to replace()}"
    local -r replace="${2:?the REPLACE string was not passed to replace()}"
    local -r content="${3:-}"
    local new_content
    debug "replace" "replacing \"${find}\" with \"${replace}\""

    new_content="${content//"${find}"/"${replace}"}"
    debug "replace" "was: ${content}"
    debug "replace" "now: ${new_content}"
    echo "${new_content}"
    return 0
}

# remove <find> <content>
#
# Looks for "find" in the "content" string passed in and removes it.
function remove() {
    local -r find="${1:?the FIND string was not passed to replace()}"
    local -r content="${2:-}"
    local new_content

    new_content="${content//"${find}"/}"
    debug "remove" "\nwas: ${content}\nnow: ${new_content}"
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

# join_with <delimiter> <...list  | ref:array|list>
#
# Joins the all the parameters passed in to a single
# string using <delimiter> between each parameter.
function join_with() {
    allow_errors
    local -r delimiter="${1:?the delimiter was not passed to join_with(delimiter, ...list)}"
    # shellcheck disable=SC2207
    local -n list_ref=$2

    if is_typeof list_ref "list"; then
        # shellcheck disable=SC2207
        as_array list_ref
    fi

    if is_typeof list_ref "array"; then
        local joined=""
        debug "join_with(${delimiter})" "joining ${#list[@]} items"
        for item in "${list_ref[@]}"; do
            if [[ "$joined" == "" ]]; then
                joined="${item}"
            else
                joined="${joined}${delimiter}${item}"
            fi
        done
        echo "${joined}"
    else
        local -ra params=( "$@" )
        local -ra parts=( "${params[@]:1}" )
        local joined
        joined=""
        for item in "${parts[@]}"; do
            if [[ "$joined" == "" ]]; then
                joined="${item}"
            else
                joined="${joined}${delimiter}${item}"
            fi
        done

    fi

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
    allow_errors
    local -ra params=( "$@" )
    if ! has_characters '!@#$%^&()_+' "$1:-"; then
        local -n assoc_candidate=$1 2>/dev/null

        if is_assoc_array assoc_candidate; then
        debug "object" "parsing associative array"
        for key in "${!assoc_candidate[@]}"; do
            local kv_pair
            kv_pair=$(kv "${key}" "${assoc_candidate[${key}]}")
            object_defn="${object_defn}${OBJECT_DELIMITER}${kv_pair}"
        done
        fi
    fi
    catch_errors
    local object_defn=""

    if is_assoc_array assoc_candidate; then
        debug "object" "parsing associative array"
        for key in "${!assoc_candidate[@]}"; do
            local kv_pair
            kv_pair=$(kv "${key}" "${assoc_candidate[${key}]}")
            object_defn="${object_defn}${OBJECT_DELIMITER}${kv_pair}"
        done

    else 
        for i in "${params[@]}"; do
            if is_kv_pair "${i[@]}"; then
                debug "object" "parsing KV syntax: ${i}"
                object_defn="${object_defn}${OBJECT_DELIMITER}${i}"

            elif has_characters "=" "${i}"; then
                debug "object" "parsing x=y syntax: ${i}"
                local k
                k=$(strip_after "=" "${i}")
                local v
                v=$(strip_before "=" "${i}")
                local key_value
                key_value=$(kv "${k}" "${v}")
                object_defn="${object_defn}${OBJECT_DELIMITER}${key_value}"
            else
                debug "object" "invalid initializer: ${i}"
                if ! is_assoc_array "${i}"; then
                    panic "\nInvalid initializer value '${i}' passed to object(${params[*]}): ${DIM}${i}${RESET}\n"
                fi
            fi
        done
    fi

    object_defn=$(strip_leading "$OBJECT_DELIMITER" "$object_defn")
    object_defn="${OBJECT_PREFIX}${object_defn}${OBJECT_SUFFIX}"

    debug "object" "${object_defn}"
    echo "${object_defn}"
    

    return 0
}

function index_of() {
    local -r container="$1"
    local -r key="$2"

    if is_object "$container" && not_empty "$key"; then
        local value
        value=$(strip_before "${KV_PREFIX}${key}${KV_DELIMITER}" "${container}")
        value=$(strip_after "KV_SUFFIX" "$value" )
    fi
}

function json_to_assoc_array() {
    local -r json="${1:?No JSON string was passed to json_to_assoc_array}"
    local -nA data=$2


    while IFS= read -r -d '' key && IFS= read -r -d '' value; do
        # shellcheck disable=SC2034
        data[$key]=$value
    done < <(jq -j 'to_entries[] | (.key, "\u0000", .value, "\u0000")' <<<"$json")
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
        printf "%s\n" "${items[@]}"
        return 0
    fi
}

# values <object>
#
# Returns an array of values for a given object
function values() {
    local obj="${1:?no parameters passed into keys()}"
    local -a items=()
    if ! is_object "${obj}"; then
        debug "values" "invalid object: ${DIM}${obj}${RESET}"
        return 1
    else
        # shellcheck disable=SC2207
        local -ra kvs=( $(object_to_kv_array "$obj") )

        for kv in "${kvs[@]}"; do
            local val=""
            val=$(last "$kv")
            debug "keys" "kv: ${kv}, val: ${val}"
            items+=( "${val}" )
        done

        debug "values" "${items[*]}"
        printf "%s\n" "${items[@]}"
        return 0
    fi
}

# kv <key> <value>
#
# Creates a KV pairing with default delimiter of "::" (unless
# overriden by another delimiter)
function kv() {
    local -r key="${1:?the KEY was not passed to kv}"
    local -r val="${2:?the VALUE was not passed to kv}"
    
    local kv_defn="${KV_PREFIX}${key}${KV_DELIMITER}${val}${KV_SUFFIX}"

    debug "kv" "${kv_defn}"
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
    debug "object_to_kv_array" "object stripped down to just kv_pair's: ${obj}"
    local -a kv_arr=()
    # shellcheck disable=SC2207
    kv_arr=( $(split_on "${OBJECT_DELIMITER}" "${obj}") )
    debug "object_to_kv_array" "object represented as a ${#kv_arr[@]} element KV array: ${kv_arr[*]}"

    printf "%s\n" "${kv_arr[@]}"
    return 0
}

# as_array() <container>
#
# Ensures that <container> is a bash array and will convert
# lists, objects, and proxy normal arrays
function as_array() {
    local -r by_val="$1"

    if is_list "$by_val"; then
        elements=$(list_elements "${by_val}")
        #shellcheck disable=SC2206
        local -a arr=( ${elements//"${LIST_DELIMITER}"/ } )

        debug "as_array" "array of length ${#arr[@]}: [ ${arr[*]} ]"
        printf "%s\n" "${arr[@]}"

        catch_errors
        return 0
    fi


    if is_object "$by_val"; then
        # shellcheck disable=SC2207
        local -ra arr=( $(object_to_kv_array "${by_val}") )
        printf "%s\n" "${arr[@]}"
        catch_errors
        return 0
    fi

    if is_typeof "$by_val" "string" && has_newline "${by_val}"; then
        debug "as_array()" "because it's a string with newline characters we'll assume it already was an array"
        printf "%s" "$by_val"
        catch_errors
        return 0
    fi

    allow_errors
    local -n __container=$1 2>/dev/null

    if is_list __container; then
        elements=$(list_elements "${__container}")
        #shellcheck disable=SC2206
        local -a arr=( ${elements//"${LIST_DELIMITER}"/ } )

        debug "as_array" "array of length ${#arr[@]}: [ ${arr[*]} ]"
        printf "%s\n" "${arr[@]}"

        catch_errors
        return 0
    fi

    if is_object __container; then
        # shellcheck disable=SC2207
        local -ra arr=( $(object_to_kv_array "${__container}") )
        printf "%s\n" "${arr[@]}"
        catch_errors
        return 0
    fi

    catch_errors
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


function set_env() {
    local -r var="${1}"
    local -r val="${2}"

    if is_empty "$var"; then
        panic "set_env(var,val) called without VAR!"
    fi

    local -r setter=$(printf "\n%s\n" "${var}=${val}")

    eval "$setter"

    # source <<<"${setter}"
    debug "set_env" "set ENV variable '${var}' to '${val}'"
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

    if starts_with "${ensured}" "$content"; then
        debug "ensure_starting" "the ensured text '${ensured}' was already in place"
        echo "${content}"
    else
        debug "ensure_starting" "the ensured text '${ensured}' was added in front of '${content}'"

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

# strip_after <find> <content>
#
# Strips all characters after finding <find> in content inclusive
# of the <find> text.
#
# Ex: strip_after ":" "hello:world:of:tomorrow" → "hello"
function strip_after() {
    local -r find="${1:?strip_after() requires that a find parameter be passed!}"
    local -r content="${2:-}"

    if not_empty "content"; then
        echo "${content%%"${find}"*}"
    else 
        echo ""
    fi
}

# strip_after_last <find> <content>
#
# Strips all characters after finding the FINAL <find> substring 
# in the content. 
#
# Ex: strip_after_last ":" "hello:world:of:tomorrow" → "hello:world:of"
function strip_after_last() {
    local -r find="${1:?strip_after_last() requires that a find parameter be passed!}"
    local -r content="${2:-}"

    if not_empty "content"; then
        echo "${content%"${find}"*}"
    else 
        echo ""
    fi
}

# strip_before <find> <content>
#
# Retains all the characters after the first instance of <find> is
# found.
#
# Ex: strip_after ":" "hello:world:of:tomorrow" → "world:of:tomorrow"
function strip_before() {
    local -r find="${1:?strip_before() requires that a find parameter be passed!}"
    local -r content="${2:-}"

    echo "${content#*"${find}"}"
}

# strip_before_last <find> <content>
#
# Retains all the characters after the last instance of <find> is
# found.
#
# Ex: strip_after ":" "hello:world:of:tomorrow" → "tomorrow"
function strip_before_last() {
    local -r find="${1:?strip_before_last() requires that a find parameter be passed!}"
    local -r content="${2:-}"

    echo "${content##*"${find}"}"
    
}

# summarize() <content> <[length]>
#
# helps to describe long text by only showing the first
# <length> characters, an ellipsis, and then the last
# <length> characters.
#
# Note if the overall length of the text is not long
# enough then no summarization will be done.
function summarize() {
    local -r content="${1}"
    local -r len="${2:-16}"
    local -ir min=( "${len}" * 2 ) # min content len before trucate
    local -r content_len=(${#content})

    if not_empty "$content"; then
        if [[ min -gt  content_len  ]]; then
            echo "${content}"
        else
            printf "%s" "${content:0:${len}} ... ${content:-${len}}"
        fi
    else
        echo ""
    fi

}


# yes_no <num>
# 
# Converts a numeric response into yes/no/maybe where:
#  - 0 → "yes"
#  - 1 → "no"
#  - [num] → "maybe(${num})"
function yes_no() {
    local -ri evaluate="${1:?yes_no() expects a numeric value to be passed in}"
    if [[ $evaluate -eq 0 ]]; then
        debug "yes_no" "value of '${evaluate}' is converted to 'yes'"
        echo "yes"
    elif [[ $evaluate -eq 1 ]]; then
        debug "yes_no" "value of '${evaluate}' is converted to 'no'"
        echo "no"
    else
        debug "yes_no" "value of '${evaluate}' is converted to 'maybe(${evaluate})'"
        echo "maybe(${evaluate})"
    fi

}


# true_false <num>
# 
# Converts a numeric response into yes/no/maybe where:
#  - 0 → "true"
#  - 1 → "false"
#  - [num] → "boolean(${num})"
function true_false() {
    local -ri evaluate="${1:?yes_no() expects a numeric value to be passed in}"
    if [[ $evaluate -eq 0 ]]; then
        debug "true_false" "value of '${evaluate}' is converted to 'true'"
        echo "true"
    elif [[ $evaluate -eq 1 ]]; then
        debug "true_false" "value of '${evaluate}' is converted to 'false'"
        echo "false"
    else
        debug "true_false" "value of '${evaluate}' is converted to 'boolean(${evaluate})'"
        echo "boolean(${evaluate})"
    fi
}

# pop() <ref:array> <ref:value-or-key> [<ref:value-of-obj>]
#
# Takes a reference to an array value and
# pops off the last element and mutating the
# <ref:array> to the reduced array while
# setting <ref:popped-value> to be the 
# value which was just popped off the array
#
# If you pass in an associative array it will 
# pop off both a "key" and a "value"
function pop() {
    allow_errors
    local -n __array__=$1
    local -n __value_or_key__=$2
    local -n __value_of_obj__=$3 2>/dev/null


    if [ "$$" -ne "$BASHPID" ]; then
        if [[ "$$" -ne "$APP_ID" ]]; then
            warn "pop() was called from a subshell that is not the APP_ID. This is probably not what you want!"
        fi
    fi

    if is_array __array__; then
        # REGULAR ARRAY
        if [[ ${#__array__} -eq 0 ]]; then
            debug "pop" "pop() called on an empty array"
            __value_or_key__=""
            return 1
        fi

        # return the last element in the array
        __value_or_key__="${__array__[-1]}"
        
        # remove the last element from the array
        local -ri count="${#__array__[@]}"-1
        debug "pop" "popped off ${BOLD}${__array__[1]}${RESET} from numeric array; leaving ${count[*]} elements"
        unset "__array__[-1]"
        __array__=("${__array__[@]}")
        catch_errors

    elif is_assoc_array __array__; then
        # ASSOCIATIVE ARRAY
        allow_errors
        local -ra keys=("${!__array__[@]}")
        local -ri count=$(( ${#keys} ))
        catch_errors

        if [[ count -eq 0 ]]; then
            debug "pop" "pop() called on an empty associative array"
            __value_or_key__=""
            __value_of_obj3ect__=""
            return 1
        fi

        local -r last_key="${keys[-1]}"

        __value_or_key__="${last_key}"
        __value_of_obj__="${__array__["$last_key"]}"

        unset "__array__[${last_key}]"
        # __array__=( "${__array__[@]}" )
        catch_errors
    else 
        catch_errors
        error "Unexpected type passed into pop()"
    fi
}


# unshift() <ref:array> <ref:value-or-key> [<ref:value-of-obj>]
#
# Takes a reference to an array value and
# pops off the first element while mutating the
# <ref:array> to <ref:popped-value> and removes that
# element from the array
#
# If you pass in an associative array it will 
# pop off both a "key" and a "value"
function unshift() {
    allow_errors
    # shellcheck disable=SC2178
    local -n __array__=$1
    local -n __value_or_key__=$2
    local -n __value_of_obj__=$3:- 2>/dev/null

    if [ "$$" -ne "$BASHPID" ]; then
        if [[ "$$" -ne "$APP_ID" ]]; then
            warn "unshift() was called from a subshell that is not the APP_ID. This is probably not what you want!"
        fi
    fi

    if is_array __array__; then
        # REGULAR ARRAY
        if [[ ${#__array__} -eq 0 ]]; then
            debug "pop" "pop() called on an empty array"
            __value_or_key__=""
            catch_errors
            return 1
        fi

        # return the last element in the array
        __value_or_key__="${__array__[0]}"
        
        # remove the last element from the array
        local -ri count="${#__array__[@]}"-1
        debug "pop" "popped off ${BOLD}${__array__[0]}${RESET} from numeric array; leaving ${count[*]} elements"
        unset "__array__[0]"
        __array__=("${__array__[@]}")
        catch_errors

    elif is_assoc_array __array__; then
        # ASSOCIATIVE ARRAY
        local -r keys=( "${!__array__[@]}")

        if [[ ${#keys} -eq 0 ]]; then
            debug "pop" "pop() called on an empty associative array"
            __value_or_key__=""
            __value_of_obj3ect__=""
            catch_errors
            return 1
        fi

        local -r first_key="${keys[0]}"

        __value_or_key__="${first_key}"
        __value_of_obj__="${__array__["$first_key"]}"

        unset "__array__[${first_key}]"
        __array__=( "${__array__[@]}" )
        catch_errors
    else 
        error "Unexpected type passed into pop()"
    fi
}


# push_object() <ref:obj> <kv_pair|"key=value">
function push_object() {
    local -n __obj=$1
    local -ra all=( "$@" )
    local -ra params=( "${all[@]:1}" )

    if ! is_object __obj; then
        error "call to push_object(obj-ref, ...params) was called expecting an object reference as the first parameter but instead got $(typeof __obj)"
    fi

    local -a kvs
    # shellcheck disable=SC2207
    kvs=( $(as_array "${__obj}") )

    debug "push_object" "object arrived as ${#kvs[@]} key/value pairs"

    for p in "${params[@]}"; do
        if is_kv_pair "${p}"; then
            kvs+=( "$p" )
        elif has_characters "=" "${p}"; then
            debug "object" "parsing x=y syntax: ${p}"
            local key_value
            key_value=$(kv "$(strip_after "=" "${p}")" "$(strip_before "=" "${p}")")
            kvs+=( "${key_value}" )
        else
            debug "push_object" "and parameter '${p}' was unable to be converted to a kv_pair and added to object"
        fi
    done

    debug "push_object" "object now consists of ${#kvs[@]} key/value pairs"
    __obj=$(object "${kvs[@]}")
}

function push() {
    allow_errors
    # shellcheck disable=SC2178
    local -n __array__=$1
    # parameter for use when passed by value
    local -ra params=( "$@" )
    local -ra __params__=("${params[@]:1}")
    local -ra __params_no_key__=("${params[@]:2}")
    local -ra __params_no_key_or_val__=("${params[@]:3}")
    local -n _ref_key=$2 2>/dev/null
    local -n _ref_val=$3 2>/dev/null

    catch_errors

    if is_array __array__; then
        # REGULAR NUMERIC ARRAY
        if is_not_typeof ref_key "empty"; then
            # no ref key so just add all params
            __array__+=("${__params__[@]}")
            debug "push" "pushed non-reference parameters onto numeric array: ${__params__[*]}; the array now has a length of ${#__array__[@]}."
        else
            if is_not_typeof ref_val "empty"; then
                # two values treated as ref values
                __array__+=(_ref_key _ref_val "${__params_no_key_or_val__[@]}")
                local -r len="${#__params_no_key_or_val__[@]}"
                debug "push" "pushed two reference values and ${len} non-reference values; length of array is now ${#__array__[@]}." 
            else    
                __array__+=(_ref_key "${__params_no_key__[@]}")
                local -r len="${#__params_no_key__[@]}"
                debug "push" "pushed one reference value and ${len} non-reference values; length of array is now ${#__array__[@]}."
            fi
        fi
        return 0
    elif is_assoc_array __array__; then
        # ASSOCIATIVE ARRAY
        if is_not_type ref_key "empty" && is_not_typeof ref_value "empty"; then
            # both key and value are ref values
            __array__["$_ref_key"]=$_ref_val
        elif is_not_typeof ref_value "empty"; then
            local -r k=$(typeof "$1")
            if is_typeof k "string"; then
                __array__["${1}"]=$_ref_val
            else
                error "invalid key value passed into push(${k})"
            fi
        else
            local -r k=$(typeof "$1")
            if is_typeof k "string"; then
                if is_empty "$2"; then
                    unset "__array__[$k]"
                else
                    __array__["${1}"]="${__value_of_obj__}"
                fi
            else
                error "invalid key value passed into push(${k})"
            fi
        fi
    elif is_object __array__; then
        # allows the more convenient "push" syntax to run "push_object"
        push_object __array__ "${__params__[@]}"

    else
        error "invalid array passed into push(arr,...)"
        exit 1
    fi
}


function filter() {
    # shellcheck disable=SC2178
    local -na __array=$1
    local -fn __fn=$2

    for key in "${!__array[@]}"; do

        if ! __fn "${__array[$key]}"; then
            unset "${__array[key]}"
        fi

    done
}
