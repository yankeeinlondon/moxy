#!/usr/bin/env bash

# shellcheck source="./env.sh"
source "./utils/env.sh"
# shellcheck source="./logging.sh"
source "./utils/logging.sh"


function status_help() {
    log ""
    log "${BOLD}Status Help${RESET}"
    log " - specify the area you want to get status on:"
    log " - choices are: ${GREEN}lxc${RESET}, ${GREEN}vm${RESET}, ${GREEN}nodes${RESET}, ${GREEN}storage${RESET},"
    log ""
}

function lxc_status_old() {
    local -A data
    local -r json="$(pve_lxc_containers)"

    log "${json}"

    while IFS= read -r -d '' key && IFS= read -r -d '' value; do
        # shellcheck disable=SC2034
        data[$key]=$value
    done < <(jq -j 'to_entries[] | (.key, "\u0000", .value, "\u0000")' <<<"$json")
    log "${GREEN}◦${RESET} [${data["vmid"]}] ${data["name"]} on ${data["node"]} is ${data["status"]}"

    # for key in "${!data[@]}"; do
    #     log "$key => ${data[$key]}"
    # done

}

function lxc_status() {
    local -A data
    local -r json="$(pve_lxc_containers)"
    local -a containers

    # Parse JSON and convert it into an array of associative arrays
    mapfile -t containers < <(jq -c '.[]' <<<"$json")

    declare -A container_data
    for container in "${containers[@]}"; do
        declare -A data
        while IFS= read -r -d '' key && IFS= read -r -d '' value; do
            data["$key"]="$value"
        done < <(jq -j 'to_entries[] | (.key, "\u0000", .value, "\u0000")' <<<"$container")

        if [[ -n "${data[vmid]:-}" ]]; then
            container_data["${data[vmid]}"]=$(declare -p data | sed 's/^declare -A data=//')
        else
            echo "Warning: VMID not found in container data: $container" >&2
        fi
    done

    # Sort by VMID and display the results
    for vmid in $(echo "${!container_data[@]}" | tr ' ' '\n' | sort -n); do
        eval "declare -A data=${container_data[$vmid]}"
        echo "VMID: ${data[vmid]}"
        for key in "${!data[@]}"; do
            echo "  $key: ${data[$key]}"
        done
        echo ""
    done
}

function vm_status() {
    echo "not ready"
}
function cluster_status() {
    echo "not ready"
}

function node_status() {
    echo "not ready"
}


function moxy_status() {
    local -r focus="$1"

    case $(lc "$focus") in
        nodes) node_status;;
        lxc) lxc_status;;
        vm) vm_status;;
        cluster) cluster_status;;
        *) status_help;;
    esac
}
