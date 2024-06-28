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

    local -A tag_color=()
    # shellcheck disable=SC2034
    local -a tag_pallette=( "${BG_PALLETTE[@]}" )

    # Sort by VMID and display the results
    log ""
    log "🏃${BOLD} Running Containers${RESET}"
    log "-----------------------------------------------------"
    for vmid in $(echo "${!container_data[@]}" | tr ' ' '\n' | sort -n); do
        eval "declare -A data=${container_data[$vmid]}"
        if [[ "${data[status]}" == "running" ]]; then
            # shellcheck disable=SC2207
            local -a tags=( $(split_on ";" "${data["tags"]}") )
            local display_tags=""
            
            for t in "${tags[@]}"; do
                local color
                allow_errors
                if not_empty "${tag_color["$t"]}"; then
                    color="${tag_color["$t"]}"
                else
                    if ! unshift tag_pallette color; then
                        tag_pallette=( "${BG_PALLETTE[@]}" )
                        unshift tag_pallette color
                    fi
                    tag_color["$t"]="$color"
                fi
                catch_errors
                display_tags="${display_tags} ${color}${t}${RESET}"
            done

            log "- ${data["name"]} [${DIM}${data["vmid"]}${RESET}]: ${ITALIC}${DIM}running on ${RESET}${data["node"]}; ${display_tags}"; 
        fi
    done

    log ""
    log "✋${BOLD} Stopped Containers${RESET}"
    log "-----------------------------------------------------"
    for vmid in $(echo "${!container_data[@]}" | tr ' ' '\n' | sort -n); do
        eval "declare -A data=${container_data[$vmid]}"
        if [[ "${data[status]}" == "stopped" ]]; then
            # shellcheck disable=SC2207
            local -a tags=( $(split_on ";" "${data["tags"]}") )
            local display_tags=""
            
            for t in "${tags[@]}"; do
                local color
                allow_errors
                if not_empty "${tag_color["$t"]}"; then
                    color="${tag_color["$t"]}"
                else
                    if ! unshift tag_pallette color; then
                        tag_pallette=( "${BG_PALLETTE[@]}" )
                        unshift tag_pallette color
                    fi
                    tag_color["$t"]="$color"
                fi
                catch_errors
                display_tags="${display_tags} ${color}${t}${RESET}"
            done

            local template_icon=""
            if [[ "${data["template"]}" == "1" ]]; then
                template_icon="📄 "
            fi

            log "- ${template_icon}${data["name"]} [${DIM}${data["vmid"]}${RESET}]: ${ITALIC}${DIM}residing on ${RESET}${data["node"]}; ${display_tags}"; 
        fi
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

function storage_status() {
    local -A data
    local -r json="$(pve_storage)"
    local -a strorage_devices

    # Parse JSON and convert it into an array of associative arrays
    mapfile -t strorage_devices < <(jq -c '.[]' <<<"$json")

    declare -A storage_data
    for device in "${strorage_devices[@]}"; do
        declare -A data
        while IFS= read -r -d '' key && IFS= read -r -d '' value; do
            data["$key"]="$value"
        done < <(jq -j 'to_entries[] | (.key, "\u0000", .value, "\u0000")' <<<"$device")

        if [[ -n "${data[storage]:-}" ]]; then
            storage_data["${data[storage]}"]=$(declare -p data | sed 's/^declare -A data=//')
        else
            echo "Warning: 'storage' not found in container data: $container" >&2
        fi
    done

    log ""
    log "🐘${BOLD} Shared Storage${RESET}"
    log "-----------------------------------------------------"
    for storage in $(echo "${!storage_data[@]}" | tr ' ' '\n' | sort -n); do
        eval "declare -A data=${storage_data[$storage]}"
        if [[ "${data[shared]}" == "1" ]]; then
            log "- ${data["storage"]}${DIM}@${data["server"]}${RESET} - ${BOLD}${BLUE}${data["type"]}${RESET} - "

        fi
    done

    log ""
    log "🛖${BOLD} Local Storage${RESET}"
    log "-----------------------------------------------------"
    for storage in $(echo "${!storage_data[@]}" | tr ' ' '\n' | sort -n); do
        eval "declare -A data=${storage_data[$storage]}"
        if [[ "${data[shared]}" != "1" ]]; then
            log "- ${data["storage"]}${DIM}@${data["server"]}${RESET} - ${BOLD}${BLUE}${data["type"]}${RESET} - "

        fi
    done
}


function moxy_status() {
    local -r focus="${1:-}"

    case $(lc "$focus") in
        nodes) node_status;;
        storage) storage_status;;
        lxc) lxc_status;;
        vm) vm_status;;
        cluster) cluster_status;;
        *) status_help;;
    esac
}
