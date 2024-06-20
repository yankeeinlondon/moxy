#!/usr/bin/env bash


HTTP_HEADERS="${HTTP_HEADERS:- -H \"Accept=*/*\" -H \"User-Agent=PostmanRuntime/7.39.0\" -H \"Accept-Encoding=gzip,deflate,br\"}"

# provides a REST API for bash

# shellcheck source="./shared.sh"
source "./utils/shared.sh"

function fetch_get() {
    local -r url=${1:?no URL was passed to fetch_get()}

}

# get_html <url>
function get_html() {
    local -r url=${1:?no URL was passed to fetch_get()}

    local -r resp="$(curl --location "${url} --insecure")"

    debug "get_html(${url})" "headers are ${HTTP_HEADERS}"
    
    printf "%s" "${resp}"
}

function http_status_code() {
    local -r url=${1:?no URL was passed to fetch_get()}
    local -r http_code="$(curl -o /dev/null --silent -Iw '%{http_code}' --location "${url}"  --insecure)"

    printf "%s" "$(strip_trailing "%" "${http_code}")"
}


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

function server_available() {
    local -r host=${1:?no PVE hose passed to get_pve_url()}

}

function get_nodes() {
    local -r host=${1:?no PVE hose passed to get_pve_url()}
    local -r url="$(get_pve_url "${host}" "/nodes")"
    local -r token=""
    local -r outcome=$(curl -X GET -H \"Authorization=PVEAPIToken="${token}"\" "${url}")

    echo "${outcome}"
}


