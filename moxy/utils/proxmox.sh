#!/usr/bin/env bash


# shellcheck source="./env.sh"
. "./utils/env.sh"
# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./info.sh"
. "./utils/info.sh"
# shellcheck source="./mutate.sh"
. "./utils/mutate.sh"
# shellcheck source="./errors.sh"
. "./utils/errors.sh"
# shellcheck source="./fetch.sh"
. "./utils/fetch.sh"

# is_pve_node
#
# Returns an exit code which indicates whether the given machine is
# a PVE node or not.
function is_pve_node() {
    if has_command "pveversion"; then
        debug "is_pve_node" "is a pve node"
        return 0
    else
        debug "is_pve_node" "is NOT a pve node"
        return 1
    fi
}

function call_api() {
    local -r path="${1:?No path passed to call_api()}"
    local -r filter="${2:-}"
    local offset_filter
    if is_pve_node; then
        offset_filter=$(ensure_starting ". " "$(strip_leading ".data " "$filter")")
        debug "call_api" "using pvesh to get '${path}' with filter '${offset_filter}'"
        printf "%s" "$(get_pvesh "${path}" "$offset_filter")"
    else
        offset_filter=$(ensure_starting ".data " "$(strip_leading ". " "$filter")")
        debug "call_api" "using pve API to get '${path}' with filter '${offset_filter}'"
        printf "%s" "$(get_pve "${path}" "$offset_filter")"
    fi
}

# get_pve_url <host> <path>
#
# Combines the base URL, the host and the path
function get_pve_url() {
    local -r host=${1:?$(config_property "DEFAULT_NODE")}

    if is_empty host; then
        panic "Call to get_pve_url() provided no Host information and we were unable to get this from DEFAULT_NODE in your configuration file: ${DIM}${MOXY_CONFIG_FILE}${RESET}"
    fi

    local -r path=${2:-/}
    local -r base="https://${host}:8006/api2/json"

    if starts_with "/" "${path}"; then
        echo "${base}${path}"
    else
        echo "${base}/${path}"
    fi
}

# validate_api_key() <api_key>
#
# checks that a API call to Proxmox with the provided API_KEY
# returns a 200 status code.
function validate_api_key() {
    local -r key="${1:?no URL was passed to fetch_get()}"

    local -rA req=(
        [url]="$(get_pve "/version")"
        [auth]="${key}"
    )

    local -r code=$(validate_api_key "${key}")

    if [[ "$code" == "200" ]]; then
        debug "validate_api_key" "key was valid"
        return 0
    else
        debug "validate_api_key" "invalid key [${code}]: ${key}"
        return 1
    fi
}

function set_default_token() {
    local -r token="${1:?no URL was passed to fetch_get()}"

    replace_line_in_file "${MOXY_CONFIG_FILE}" "DEFAULT_API" "DEFAULT_API=${token}"
}

# get_default_node()
#
# Gets the ip address for the PVE "default host".
function get_default_node() {
    local -r def_node=$(config_property "DEFAULT_NODE")

    if not_empty "$def_node"; then
        echo "${def_node}"
        return 0
    else
        # shellcheck disable=SC2207
        local -ra all_nodes=($(findall_in_file "${MOXY_CONFIG_FILE}" "API_TOKEN"))

        if  [[ $(length "${all_nodes[@]}") -gt 0 ]]; then
            echo "${all_nodes[0]}"
            return 0
        else
            return 1
        fi
    fi
}

# pve_version
#
# Provides the PVE version of the current node (if a PVE node)
# or the DEFAULT_NODE setting in the configuration if a remote
# node.
function pve_version() {
    if is_pve_node; then
        local version
        version="$(pveversion)"
        version="$(strip_before "pve-manager/" "${version}")"
        version="$(strip_after_last "/"  "${version}")"

        echo "${version}"
        return 0
    else
        local -r version="$(get_pve_version)"

        echo "${version}"
        return 0
    fi
}

# get_next_container_id()
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


# get_pve_version() <host::default_host>
#
# Gets the PVE version information via the Proxmox API.
# You may optionally pass in a PVE HOST but if not
# then the "default host" will be used.
# shellcheck disable=SC2120
function get_pve_version() {
    local -r host="${1:-"$(config_property "DEFAULT_NODE")"}"
    local -r url=$(get_pve_url "${host}" "/version")
    if is_empty host; then
        panic "Failed to get a PVE host, including the default node. Please make sure your configuration file has a DEFAULT_NODE set!"
    fi

    local -r resp=$(fetch_get "${url}" "$(pve_auth_header)")
    local -r version="$(echo "${resp}" | jq --raw-output '.data.version')"
    
    printf "%s" "${version}"
}

# get_nodes() <[host]>
#
# Gets the nodes by querying either the <host> passed in
# or the default host otherwise.
function get_pve_nodes() {
    local -r host=${1:?no PVE host passed to get_pve_url()}
    local -r url="$(get_pve_url "${host}" "/nodes")"
    local -r token=""
    local -r outcome=$(curl -X GET -H \"Authorization=PVEAPIToken="${token}"\" "${url}")

    echo "${outcome}"
}

# pve_version_check()
# 
# Validates that the PVE version is the minimum required.
# It uses `pveversion` command when directly no a host 
# but otherwise relies on the API.
function pve_version_check() {
    local -r version="$(pve_version)"
    # shellcheck disable=SC2207
    local -ri major=( $(major_version "${version}") )

    if [[ major -lt 7  ]]; then
        log "You are running version ${version} of Proxmox but the scripts\nin Moxy require at least version 7."
        log ""
        log "Please consider upgrading."
        log ""
        exit
    fi

}



function has_proxmox_api_key() {
    log ""
}

# next_container_id
#
# If executing on a PVE node it will return the lowest available
# PVE ID in the cluster.
function next_container_id() {
    if is_pve_node; then
        local -r cid=$(pvesh get /cluster/nextid)
        echo "$cid"
        return 0
    else
        printf "%s" "$(get_next_container_id "")"
        return 0
    fi
}

function get_pvesh() {
    local -r path=${1:?no path provided to get_pvesh())}
    local -r filter=${2:-}

    local -r request="pvesh get ${path} --output-format=json"

    local response
    debug "get_pvesh(${path})" "got a response, now filtering with: ${filter}"
    # unfiltered response
    response="$(eval "$request")"
    debug "get_pvesh" "got a response from CLI of ${#response} characters"
    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]] || is_empty "$1"; then
        error "CLI call to ${BOLD}${request}${RESET} failed to return successfully (or returned nothing)"
    fi
    # jq filtering applied
    local filtered
    if not_empty "$filter"; then
        filtered="$(printf "%s" "${response}" | jq --raw-output "${filter}")" || error "Problem using jq with filter '${filter}' on the request ${BOLD}${request}${RESET} which produced a response of ${#response} chars:\n\nRESPONSE:\n${response}\n---- END RESPONSE ----\n"
    else
        filtered="${response}"
    fi

    printf "%s" "${filtered}"
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

function pve_resources() {
    local resources
    if is_pve_node; then
        resources="$(get_pvesh "/cluster/resources" ".data")"
    else 
        resources="$(get_pve "/cluster/resources" ".data")"
    fi

    printf "%s" "$(list "${resources}")"
}

function pve_lxc_containers() {
    local -r path="/cluster/resources"
    local resources
    if is_pve_node; then
        resources="$(get_pvesh "${path}" '. | map(select(.type == "lxc"))')"
    else 
        resources="$(get_pve "${path}" '.data | map(select(.type == "lxc"))')"
    fi

    printf "%s" "${resources}"
}

function pve_vm_containers() {
    local -r path="/cluster/resources"
    local -r filter='.data.[] | map(select(.type == "qemu"))'
    local resources
    if is_pve_node; then
        resources=$(get_pvesh "${path}" '. | map(select(.type == "qemu"))')
    else 
        resources=$(get_pve "${path}" '.data | map(select(.type == "qemu"))')
    fi

    printf "%s" "${resources}"
}

function pve_storage() {
    local resources
    if is_pve_node; then
        resources="$(get_pvesh "/storage" '. | map(.)')"
    else 
        resources="$(get_pve "/storage" '.data | map(.)')"
    fi

    printf "%s" "${resources}"
}

function pve_sdn() {
    local -r path="/cluster/resources"
    local -r filter=".data | map(select(.type == \"sdn\"))"
    local resources
    if is_pve_node; then
        resources="$(get_pvesh "${path}" "${filter}")"
    else 
        resources="$(get_pve "${path}" "${filter}")"
    fi

    printf "%s" "$(list "${resources}")"
}

function pve_nodes() {
    local nodes
    if is_pve_node; then
        nodes=$(get_pvesh "/nodes" '. | map(.)')
    else
        nodes=$(get_pve "/nodes" '.data | map(.)')
    fi

    printf "%s" "${nodes}"
}


# pve_cluster_info <ref:name> <ref:nodes>
function pve_cluster_info() {
    local -n __name=$1
    local -n __nodes=$2
    local -r cluster=$(call_api "/cluster/status" '.data | map(select(.type == "cluster"))')

    __name=$(echo "${cluster}" | jq -r '.[] | .name')

    local -r json=$(call_api "/cluster/status" '.data | map(select(.type == "node"))')
    local -a data
    json_list_data json data

    __nodes=()
    for idx in "${!data[@]}"; do
        local -A record
        record="${data[${idx}]}"
        __nodes+=( "${record[@]}" )
    done

}

function pve_cluster_status() {
    local cluster
    if is_pve_node; then
        cluster=$(get_pvesh "/cluster/status" '.data | map(.)')
    else
        cluster=$(get_pve "/cluster/status" '. | map(.)')
    fi

    printf "%s" "${cluster}"
}

function pve_cluster_replication() {
local cluster
    if is_pve_node; then
        cluster=$(get_pvesh "/cluster/replication" '.data | map(.)')
    else
        cluster=$(get_pve "/cluster/replication" '. | map(.)')
    fi

    printf "%s" "${cluster}"
}

function pve_cluster_ha_status() {
local cluster
    if is_pve_node; then
        cluster=$(get_pvesh "/cluster/ha/status/current" '.data | map(.)')
    else
        cluster=$(get_pve "/cluster/ha/status/current" '. | map(.)')
    fi

    printf "%s" "${cluster}"
}

function pve_cluster_ha_manager() {
local cluster
    if is_pve_node; then
        cluster=$(get_pvesh "/cluster/ha/status/manager_status" '.data | map(.)')
    else
        cluster=$(get_pve "/cluster/ha/status/manager_status" '. | map(.)')
    fi

    printf "%s" "${cluster}"
}

function pve_node_config() {
    local nodes
    if is_pve_node; then
        nodes=$(get_pvesh "/cluster/config/nodes" '.data | map(.)')
    else
        nodes=$(get_pve "/cluster/config/nodes" '. | map(.)')
    fi

    printf "%s" "${nodes}"
}

# pve_node_dns() <node>
function pve_node_dns() {
    local -r node="1:?No node name was passed to pve_node_dns()!"
    local resp
    if is_pve_node; then
        resp=$(get_pvesh "/nodes/${node}/dns" '.data | map(.)')
    else
        resp=$(get_pve "/nodes/${node}/dns" '. | map(.)')
    fi

    printf "%s" "${resp}"
}

# pve_node_disks() <node>
function pve_node_disks() {
    local -r node="1:?No node name was passed to pve_node_disks()!"
    local resp
    if is_pve_node; then
        resp=$(get_pvesh "/nodes/${node}/disks/list" '.data | map(.)')
    else
        resp=$(get_pve "/nodes/${node}/disks/list" '. | map(.)')
    fi

    printf "%s" "${resp}"
}

# pve_lxc_status <node> <vmid>
function pve_lxc_status() {
    local -r node="${1:?No node name was passed to pve_lxc_container_status()!}"
    local -r vmid="${2:?No VMID passed to pve_lxc_container_status()}"
    local -A resp
    if is_pve_node; then
        resp=$(get_pvesh "/nodes/${node}/lxc/${vmid}/status/current" '.data | map(.)')
    else
        resp=$(get_pve "/nodes/${node}/lxc/${vmid}/status/current" '. | map(.)')
    fi

    printf "%s" "${resp[@]}"
}

