#!/usr/bin/env bash


HTTP_HEADERS="-H \"Accept: */*\"}"

# provides a REST API for bash

# shellcheck source="./env.sh"
source "./utils/env.sh"
# shellcheck source="./logging.sh"
source "./utils/logging.sh"

function fetch_get() {
    called "fetch_get" "??"
    local -r url="${1}"
    if is_empty "$url"; then
        returned 1 "fetch_get() was called without providing a URL!"
    fi
    local -r auth=${2:?-}
    local -r cmd="curl -X GET --location ${url} ${HTTP_HEADERS} ${auth} --insecure --silent"
    debug "fetch_get()" "${cmd}"
    local -r req=$(eval "$cmd")
    debug "fetch_get()" "response -> ${req}"

    printf "%s" "${req}"

    returned 0
}

# get_html <url>
function get_html() {
    local -r url=${1:?no URL was passed to fetch_get()}
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

