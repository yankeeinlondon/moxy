#!/usr/bin/env bash

# shellcheck source="./logging.sh"
. "./utils/logging.sh"


function is_bound() {
    allow_errors
    local -n __test_by_ref=$1 2>/dev/null || { debug "is_bound" "unbounded ref";  return 1; }
    local -r by_val="${1}:-"
    local name="${!__test_by_ref}" 2
    local -r arithmetic='→+-=><%'
    if has_characters "${arithmetic}" "$1"; then
        debug "is_bound" "${name} is NOT bound"
        return 1
    else
        local idx=${!1} 2>/dev/null 
        local a="${__test_by_ref@a}" 

        if [[ -z "${idx}${a}" ]]; then
            debug "is_bound" "${name} is NOT bound: ${idx}, ${a}"
            catch_errors
            return 1
        else 
            debug "is_bound" "${name} IS bound: ${idx}, ${a}"
            catch_errors
            return 0
        fi
    fi
}

# is_assoc_array() <ref:var>
#
# tests whether the passed in variable reference is
# an associative array.
#
# Note: this only works on later versions of bash which
# definitely means not v3 but also may exclude parts of v4
#
# Note: this check only works after the variable passed in
# is actually set and set -u is in effect
function is_assoc_array() {
    local -r var="$1"
    if has_characters '!@#$%^&()_+' "$var"; then
        return 1; 
    fi
    allow_errors
    local -n __var__=$1 2>/dev/null

    if [[ ${__var__@a} = A ]] || [[ ${__var__@a} = Ar ]]; then
        catch_errors
        return 0; # true
    else
        catch_errors
        return 1; # false
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
    allow_errors
    local _var=${1:?no parameter passed into is_array}
    local declaration=""
    # shellcheck disable=SC2086
    declaration=$(LC_ALL=C type -t $1)

    if [[ "$declaration" == "keyword" ]]; then
        catch_errors
        return 0
    else
        catch_errors
        return 1
    fi
}

# not_empty() <test>
# 
# tests whether the <test> value passed in is an empty string (or is unset)
# and returns 0 when it is NOT empty and 1 when it is.
function not_empty() {
    if [ -z "$1" ] || [[ "$1" == "" ]]; then
        debug "not_empty" "WAS empty, returning 1/false"
        return 1
    else
        debug "not_empty" "was not empty [${#1} chars], returning 0/true"
        return 0
    fi
}


# is_array() <ref:var>
#
# tests whether the passed in variable reference is
# a base array.
#
# Note: this only works on later versions of bash which
# definitely means not v3 but also may exclude parts of v4
#
# Note: this check only works after the variable passed in
# is actually set and set -u is in effect
function is_array() {
    allow_errors
    local -n __var__=$1 2>/dev/null
    local -r test=${__var__@a} 2>/dev/null
    catch_errors

    if is_bound __var__; then
        if not_empty "$test" && [[ $test = a ]]; then
            debug "is_array" "is an array!"
            return 0; # true
        else
            debug "is_array" "' is not an array!"
            return 1; # false
        fi
    else
        debug "is_array" "is_array was called without a reference so returning false!"
        return 1
    fi

}


# is_empty() <test | ref:test>
# 
# tests whether the <test> value passed in is an empty string (or is unset)
# and returns 0 when it is empty and 1 when it is NOT.
function is_empty() {
    allow_errors
    local -n __ref__=$1 2>/dev/null
    catch_errors

    if is_bound __ref__; then
        if is_array __ref__; then
            if [[ ${#__ref__[@]} -eq 0 ]]; then
                debug "is_empty" "found an array with no elements so returning true"
                return 0
            else
                debug "is_empty" "found an array with some elements so returning false"
                return 1
            fi
        elif is_assoc_array __ref__; then
            if [[ ${#!__ref__[@]} -eq 0 ]]; then
                debug "is_empty" "found an associative array with no keys so returning true"
                return 0
            else
                debug "is_empty" "found an associative array with some key/values so returning false"
                return 1
            fi
        else
            allow_errors
            local -r try_pass_by_val="$__ref__" 2>/dev/null
            catch_errors
            if [ -z "$try_pass_by_val" ] || [[ "$try_pass_by_val" == "" ]]; then
                debug "is_empty" "was empty, returning 0/true"
                return 0
            else
                debug "is_empty" "was NOT empty, returning 1/false"
                return 1
            fi
        fi

    else 
        if [ -z "$1" ] || [[ "$1" == "" ]]; then
            debug "is_empty(${1})" "was empty, returning 0/true"
            return 0
        else
            debug "is_empty(${1}))" "was NOT empty, returning 1/false"
            return 1
        fi
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
# checks whether a particular program passed in via $1 is installed 
# on the OS or not (at least within the $PATH)
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
    allow_errors
    local -n __var__=$1 2>/dev/null
    local by_val="$1"

    if is_bound __var__; then
        local -r by_ref="${__var__:-}"
        if  ! [[ "$by_ref" =~ ^[0-9]+$ ]]; then
            debug "is_numeric" "false (${by_ref})"
            catch_errors
            return 1
        else
            debug "is_numeric" "true (${by_ref})"
            catch_errors
            return 0
        fi
    else
        
        if ! [[ "$by_val" =~ ^[0-9]+$ ]]; then
            debug "is_numeric" "false (${by_val})"
            catch_errors
            return 1
        else
            debug "is_numeric" "true (${by_val})"
            catch_errors
            return 0
        fi
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
    allow_errors
    local -n candidate=$1 2>/dev/null
    catch_errors

    if is_bound candidate; then
        if not_empty "$candidate" && starts_with  "${OBJECT_PREFIX}" "${candidate}" ; then
            if not_empty "$candidate" && ends_with "${OBJECT_SUFFIX}" "${candidate}"; then
                debug "is_object" "true"
                return 0
            fi
        fi
    else
        local var="$1"
        if not_empty "$var" && starts_with  "${OBJECT_PREFIX}" "${var}" ; then
            if not_empty "$var" && ends_with "${OBJECT_SUFFIX}" "${var}"; then
                debug "is_object" "true"
                return 0
            fi
        fi
    fi

    debug "is_object" "false"
    return 1
}

# file_contains <filepath> <...matches> 
# 
# will search the contents of the file in the "filepath" passed in for 
# any substring which matches one of the parameters passed in for 
# "find".
function file_contains() {
    local -r filepath="${1:?filepath expression not passed to file_has_content()}"
    local -ra matches=( "${@:2}");

    local -r content="$(get_file "$filepath")"

    for item in "${matches[@]}"; do
        if [[ "${content}" =~ ${item} ] ]; then
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
    allow_errors
    local -n __var__=$1 2>/dev/null
    local -r by_val="$1"

    if is_bound __var__; then

        if  starts_with "${LIST_PREFIX}" "${__var__}" && ends_with "${LIST_SUFFIX}" "${__var__}"; then
            debug "is_list" "true"
            catch_errors
            return 0
        else
            debug "is_list" "false (prefix matched, suffix did not): \"${LIST_SUFFIX}\""
            debug "is_list" "${__var__}"
            catch_errors
            return 1
        fi
    else
        if  starts_with "${LIST_PREFIX}" "${by_val}" && ends_with "${LIST_SUFFIX}" "${by_val}"; then
            debug "is_list" "true"
            catch_errors
            return 0
        else
            debug "is_list" "false (prefix matched, suffix did not): \"${LIST_SUFFIX}\""
            debug "is_list" "${by_val}"
            catch_errors
            return 1

        fi
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

# contains <find> <content>
# 
# given the "content" string, all other parameters passed in
# will be looked for in this content.
function contains() {
    local -r find="${1}"
    local -r content="${2}"

    if is_empty "$find"; then
        error "contains("", ${content}) function did not recieve a FIND string! This is an invalid call!" 1
    fi

    if is_empty "$content"; then
        debug "contains" "contains(${find},"") received empty content so always returns false"
        return 1;
    fi

    if [[ "${content}" =~ ${find} ]]; then
        debug "contains" "found: ${find}"
        return 0 # successful match
    fi

    debug "contains" "not found: ${find}"
    return 1
}

function has_characters() {
    local -r char_str="${1:?has_characters() did not recieve a CHARS string!}"
    local -r content="${2:?content expression not passed to has_characters()}"
    # shellcheck disable=SC2207
    local -ra chars=( $(echo "${char_str}" | grep -o .) )
    local found="false"

    if [[ "$content" == *["$char_str"]* ]]; then
        debug "has_characters" "does have some of these characters: '${char_str}'"
        return 0
    else
        debug "has_characters" "does NOT have any of these characters: '${char_str}'"
        return 1
    fi
}

function avoids_characters() {
    local -r char_str="${1:?has_characters() did not recieve a CHARS string!}"
    local -r content="${2:?content expression not passed to has_characters()}"
    # shellcheck disable=SC2207
    local -ra chars=( $(echo "${char_str}" | grep -o .) )
    local found="false"

    for key in "${!chars[@]}"; do
        if [[  ${content} == *"${chars[${key}]}"* ]]; then
            found="true"
            break
        fi
    done

    if [[ "$found" == "true" ]]; then
        debug "avoids_characters" "failed to avoid some of these characters: '${char_str}'"
        return 1
    else
        debug "avoids_characters" "avoids having any of these characters: '${char_str}'"
        return 0
    fi
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

# has_env <variable name>
#
# checks whether a given ENV variable name is defined
function has_env() {
    local -r var="${1:?has_env() called but no variable name passed in!}"
    allow_errors
    local -r val=${!var}
    catch_errors

    if [[ -z "${val}" ]]; then
        debug "has_env" "ENV variable '${var}' is NOT defined ${val}"
        return 1
    else
        debug "has_env" "ENV variable '${var}' is defined"
        return 0
    fi
}



# is_kv_pair() <test | ref:test>
#
# tests whether passed in <test> is considered a "KV Pair" or a
# reference to a KV Pair
function is_kv_pair() {
    allow_errors
    local -n test_by_ref=$1 2>/dev/null
    local -r test_by_val="$1"

    if is_bound test_by_ref; then
        if starts_with "${KV_PREFIX}" "${test_by_ref}" && ends_with "${KV_SUFFIX}" "${test_by_ref}"; then
            debug "is_kv_pair" "true (\"${DIM}${test_by_ref}${RESET}\")"
            catch_errors
            return 0
        fi
    else
        if starts_with "${KV_PREFIX}" "${test_by_val}" && ends_with "${KV_SUFFIX}" "${test_by_val}"; then
            debug "is_kv_pair" "true (\"${DIM}${test_by_val}${RESET}\")"
            catch_errors
            return 0
        fi
    fi 2>/dev/null

    catch_errors
    debug "is_kv_pair" "false"
    return 1
}

function bash_type() {
    local -r variable="$1"

    if is_function "$variable"; then
        echo "function"
    elif is_numeric "$variable"; then
        echo "number"
    elif is_list "$variable"; then
        echo "list"
    elif is_object "$variable"; then
        echo "object"
    else 
        echo "string"
    fi
}

# starts_with <look-for> <content>
function starts_with() {
    local -r look_for="${1:?No look-for string provided to starts_with}"
    local -r content="${2:-}"

    if is_empty "${content}"; then
        debug "starts_with" "starts_with(${look_for}, "") was passed empty content so will always return false"
        return 1;
    fi

    if [[ "${content}" == "${content#"$look_for"}" ]]; then
        debug "starts_with" "false (\"${DIM}${look_for}${RESET}\")"
        return 1; # was not present
    else
        debug "starts_with" "true (\"${DIM}${look_for}${RESET}\")"
        return 0; #: found "look_for"
    fi
}

# ends_with <look-for> <content>
function ends_with() {
    local -r look_for="${1:?No look-for string provided to ends_with}"
    local -r content="${2}"
    local -r no_suffix="${content%"${look_for}"}"

    if is_empty "${content}"; then
        debug "ends_with" "ends_with(${look_for}, "") was passed empty content so will always return false"
        return 1;
    fi

    if [[ "${content}" == "${no_suffix}" ]]; then
        debug "ends_with" "false (\"${DIM}${look_for}${RESET}\")"
        return 1;
    else
        debug "ends_with" "true (\"${DIM}${look_for}${RESET}\")"
        return 0;
    fi
}



# try <ref:fn> <ref:ok> <arr:params> <ref:err>
#
# Pass in a reference to a function and the parameters you'd like
# to call it with. 
function try() {
    local -r fn_name="$1"
    local -r fn=$($1)
    local -r success=$($2)
    local -r failure=$($3)
    local -ra params=("${@:4}")

    local stdout
    local stderr
    local -i code

    allow_errors

    {
        IFS= read -r -d '' stderr;
        IFS= read -r -d '' code;
        IFS= read -r -d '' stdout;
    } < <((printf '\0%s\n\0' "$($fn "${params[@]}"; printf '\0%d' "${?}" 1>&2)" 1>&2) 2>&1)

    local -rA output=(
        [stdout]="$stdout"
        [stderr]="$stderr"
        [code]=$code
        [fn_name]="$fn_name"
        [success_fn]="$2"
        [failure_fn]="$3"
        [params]="${params[*]}"
    )


    for key in "${!output[@]}"; do
        echo "Key: $key, Value: ${output[$key]}"
    done

    if [ $code -eq 0 ]; then 
        log "${fn_name}(${params[*]}) -> ${output["stdout"]} -> ${output["success_fn"]}()"
        debug "try" "Successful execution of function '${fn_name}' resulting in $(object "${!output[@]}")"
        printf "%s" "$success ${output[*]}"
    else
        debug "try" "Failed execution of function '${fn_name}' resulting in $(object "${!output[@]}")"
        printf "%s" "$failure ${output[*]}"
    fi

    catch_errors
}

