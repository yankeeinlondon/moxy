#!/usr/bin/env bash


HTTP_HEADERS="-H \"Accept: */*\"}"

# provides a REST API for bash

# shellcheck source="./env.sh"
source "./utils/env.sh"
# shellcheck source="./logging.sh"
source "./utils/logging.sh"
# shellcheck source="./errors.sh"
source "./utils/errors.sh"

function fetch_get() {
    local -r url="${1}"
    if is_empty "$url"; then
        error "fetch_get() was called without providing a URL!" 1
    fi
    local -r auth=${2:?-}
    local -r cmd="curl -X GET --location ${url} ${HTTP_HEADERS} ${auth} --insecure --silent"
    debug "fetch_get()" "${cmd}"
    local -r req=$(eval "$cmd")
    debug "fetch_get()" "response -> ${req}"

    printf "%s" "${req}"
}

# get_html <url>
function get_html() {
    local -r url=${1:?no URL was passed to get_html()}
    local -r resp="$(curl --location "${url}" --insecure)"
    
    printf "%s" "${resp}"
}

# http_status_code() <assoc: url,auth,head[] >
function http_status_code() {
    local -rAn req=$1
    local -r url=${req["url"]}
    local -r auth=${req["auth"]}
    local Authorization
    if not_empty "$auth"; then
        Authorization="-H \"Authorization:PVEAPIToken=${auth}\""
    else
        Authorization=""
    fi

    local -r http_code="$(curl -o /dev/null --silent -Iw '%{http_code}' "${Authorization}" --location "${url}"  --insecure)"

    printf "%s" "$(strip_trailing "%" "${http_code}")"
}



function reverse_lookup() {
    local -r address="${1:?no address passed into reverse_lookup()}"

    if has_command "dig"; then
        local -r name=$(remove_trailing "." "$(dig -x "${address}" +short)")

        echo "${name}"
        return 0
    else
        if has_command "host"; then
            local -r name=$(last "$(split_on " " "$(host "${address}")")")

            printf "%s" "$(remove_trailing "." "${name}")"
            return 0
        else
            debug "reverse_lookup(${address})" "dig and host are not installed on the system!"
            error "can not do a reverse lookup unless dig or host are installed on the host system"
        fi
    fi
}

# pve_auth_header()
#
# Returns all the required text to add an Authentication header
# to curl.
function pve_auth_header() {
    local -r def_token=$(find_in_file "${MOXY_CONFIG_FILE}" "DEFAULT_TOKEN")

    if not_empty "$def_token"; then
        echo "-H \"Authorization:PVEAPIToken=${def_token}\""
        return 0

    else
        # shellcheck disable=SC2207
        local -ra all_tokens=($(findall_in_file "${MOXY_CONFIG_FILE}" "API_TOKEN"))

        if  [[ $(length "${all_tokens[@]}") -gt 0 ]]; then
            echo "-H \"Authorization=PVEAPIToken=${all_tokens[0]}\""
            return 0
        else
            return 1
        fi
    fi
}


# json_list_data <ref:json> <ref:data> <ref: query>
function json_list_data() {
    allow_errors
    local -n __json=$1
    local -n __data=$2
    local -n __query=$3 2>/dev/null # sorting, filtering, etc.
    local -n __fn=$4 2>/dev/null
    catch_errors
    local -A record

    if is_not_typeof __json "string"; then
        error "Invalid JSON passed into json_list_data(); expected a reference to string data but instead got $(typeof __json)"
    fi

    if is_not_typeof __data "array"; then
        error "Invalid data structure passed into json_list_data() for data array. Expected an array got $(typeof data)"
    else
        # start with empty dataset
        __data=()
    fi

    local json_array
    mapfile -t json_array < <(jq -c '.[]' <<<"$__json")

    for json_obj in "${json_array[@]}"; do
        record=()
        while IFS= read -r -d '' key && IFS= read -r -d '' value; do
            record["$key"]="$value"
        done < <(jq -j 'to_entries[] | (.key, "\u0000", .value, "\u0000")' <<<"$json_obj")

        __data+=("$(declare -p record | sed 's/^declare -A record=//')")
    done
}

function json_list() {
    local -n __json=$1
    local -n __arr=$2

    if is_not_typeof __json "string"; then
        error "Invalid JSON passed into json_list(); expected a reference to string data but instead got $(typeof __json)"
    fi

    # if ! is_function __fn; then
    #     error "Invalid call to json_list(json, fn); the second parameter is meant to be a function reference and instead was a $(typeof __fn)"
    # fi

    local json_array
    local -r kvs=$(jq -j '.[][] | to_entries' <<<"$__json")
    local -ra s=$(split_on "\u0000" "$(replace "]" "]\u0000\n" "$kvs")")

    log "${#s[@]}"

    # for json_obj in "${json_array[@]}"; do


    #     # local -a kv_arr
    #     # local jq_cmd="jq -j '. | (\"${KV_PREFIX}\", .key, \"${KV_DELIMITER}\", .value, \"${KV_SUFFIX}\", \"\n\")'"
    #     # kv_arr=( 
    #     #     "$(echo "$json_obj" | eval "${jq_cmd}")"
    #     # )
    #     # local obj
    #     # obj=$(object "${kv_arr[@]}")

        # log "${json_obj}"


    #     # data+=( "$obj" )
    # done

    # __arr=( "${data[@]}" )

    # local -a arr=()
    # for idx in "${!data[@]}"; do
    #     local -a kvs=()
    #     for key in "${!record[@]}"; do
    #         kvs+=( "$(kv "${key}" "${record["${key}"]}")" )
    #     done
    #     local obj
    #     obj=$(object "${kvs[@]}" )
    #     arr+=( "${obj}" )
    # done

    # __arr=( "${arr[@]}" )
}
