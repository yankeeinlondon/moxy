#!/usr/bin/env bash


HTTP_HEADERS="-H \"Accept: */*\"}"

# provides a REST API for bash

# shellcheck source="./env.sh"
source "./utils/env.sh"
# shellcheck source="./logging.sh"
source "./utils/logging.sh"

function fetch_get() {
    local -r url=${1:?no URL was passed to fetch_get()}
    local -r auth=${2:?-}
    local -r cmd="curl -X GET --location ${url} ${HTTP_HEADERS} ${auth} --insecure --silent"
    debug "fetch_get()" "${cmd}"
    local -r req=$(eval "$cmd")
    debug "fetch_get()" "response -> ${req}"

    printf "%s" "${req}"
}

# get_html <url>
function get_html() {
    local -r url=${1:?no URL was passed to fetch_get()}
    local -r resp="$(curl --location "${url}" --insecure)"
    
    printf "%s" "${resp}"
}


function http_status_code() {
    local -r url=${1:?no URL was passed to fetch_get()}
    local -r http_code="$(curl -o /dev/null --silent -Iw '%{http_code}' --location "${url}"  --insecure)"

    printf "%s" "$(strip_trailing "%" "${http_code}")"
}

# get_pve_url <host> <path>
#
# Combines the base URL, the host and the path
function get_pve_url() {
    local -r host=${1:?no PVE hose passed to get_pve_url()}
    local -r path=${2:-/}
    local -r base="https://${host}:8006/api2/json"

    if starts_with "/" "${path}"; then
        echo "${base}${path}"
    else
        echo "${base}/${path}"
    fi
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
    local -r def_token=$(find_in_file "${MOXY_CONFIG}" "DEFAULT_TOKEN")

    if not_empty "$def_token"; then
        echo "-H \"Authorization:PVEAPIToken=${def_token}\""
        return 0

    else
        # shellcheck disable=SC2207
        local -ra all_tokens=($(findall_in_file "${MOXY_CONFIG}" "API_TOKEN"))

        if  [[ $(length "${all_tokens[@]}") -gt 0 ]]; then
            echo "-H \"Authorization=PVEAPIToken=${all_tokens[0]}\""
            return 0
        else
            return 1
        fi
    fi
}


# get_pve_version() <host::default_host>
#
# Gets the PVE version information via the Proxmox API.
# You may optionally pass in a PVE HOST but if not
# then the "default host" will be used.
# shellcheck disable=SC2120
function get_pve_version() {
    local -r host="${1:-"$(get_default_node)"}"
    local -r url=$(get_pve_url "${host}" "/version")
    local -r resp=$(fetch_get "${url}" "$(pve_auth_header)")
    local -r version="$(echo "${resp}" | jq --raw-output '.data.version')"
    
    printf "%s" "${version}"
}

# get_nodes() <[host]>
#
# Gets the nodes by querying either the <host> passed in
# or the default host otherwise.
function get_pve_nodes() {
    local -r host=${1:?no PVE hose passed to get_pve_url()}
    local -r url="$(get_pve_url "${host}" "/nodes")"
    local -r token=""
    local -r outcome=$(curl -X GET -H \"Authorization=PVEAPIToken="${token}"\" "${url}")

    echo "${outcome}"
}

function get_pve() {
    local -r path=${1:?no path passed to get_pve()}
    local -r filter=${2:-}
    local -r host=${3:-"$(get_default_node)"}
    local -r url="$(get_pve_url "${host}" "${path}")"
    local response
    response="$(fetch_get "${url}" "$(pve_auth_header)")"

    if not_empty "${response}" && not_empty "${filter}"; then
        debug "get_pve(${path})" "got a response, now filtering with: ${filter}" 
        response="$(printf "%s" "${response}" | jq --raw-output "${filter}")" || error "Problem using jq with filter '${filter}' on a response [${#response} chars] from the URL ${url}"
        printf "%s" "${response}"
    else 
        echo "${response}"
    fi
}

function get_next_container_id() {
    local host
    if not_empty "$1"; then
        host="${1}"
    else
        host="$(get_default_node)"
    fi
    local -r url=$(get_pve_url "${host}" "/cluster/nextid")
    local -r resp=$(fetch_get "${url}" "$(pve_auth_header)")
    local -r id="$(echo "${resp}" | jq --raw-output '.data')"
    
    printf "%s" "${id}"
}
