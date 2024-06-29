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
    # local -A data
    # local -r json="$(pve_lxc_containers)"
    # local -a containers

    # # Parse JSON and convert it into an array of associative arrays
    # mapfile -t containers < <(jq -c '.[]' <<<"$json")

    # declare -A container_data
    # for container in "${containers[@]}"; do
    #     declare -A data
    #     while IFS= read -r -d '' key && IFS= read -r -d '' value; do
    #         data["$key"]="$value"
    #     done < <(jq -j 'to_entries[] | (.key, "\u0000", .value, "\u0000")' <<<"$container")

    #     if [[ -n "${data[vmid]:-}" ]]; then
    #         container_data["${data[vmid]}"]=$(declare -p data | sed 's/^declare -A data=//')
    #     else
    #         echo "Warning: VMID not found in container data: $container" >&2
    #     fi
    # done

    local -r json=$(pve_lxc_containers)
    local -a data=()
    local -A query=(
        [sort]="vmid"
    )
    
    json_list_data json data query

    echo "records: ${#data[@]}"
    echo ""

    local -A record
    allow_errors


    local -A tag_color=()
    # shellcheck disable=SC2034
    local -a tag_palette=( "${BG_PALLETTE[@]}" )

    # Sort by VMID and display the results
    log ""
    log "🏃${BOLD} Running Containers${RESET}"
    log "-----------------------------------------------------"
    for item in "${!data[@]}"; do
        eval "declare -A record=${data[item]}"
        if [[ "${record[status]}" == "running" ]]; then
            # shellcheck disable=SC2207
            local -a tags=( $(split_on ";" "${record["tags"]}") )
            local display_tags=""
            
            for t in "${tags[@]}"; do
                local color
                allow_errors
                if not_empty "${tag_color["$t"]}"; then
                    color="${tag_color["$t"]}"
                else
                    if ! unshift tag_palette color; then
                        tag_palette=( "${BG_PALLETTE[@]}" )
                        unshift tag_palette color
                    fi
                    tag_color["$t"]="$color"
                fi
                catch_errors
                display_tags="${display_tags} ${color}${t}${RESET}"
            done

            log "- ${record[name]} [${DIM}${record[vmid]}${RESET}]: ${ITALIC}${DIM}running on ${RESET}${record[node]}; ${display_tags}"; 
        fi
    done

    log ""
    log "✋${BOLD} Stopped Containers${RESET}"
    log "-----------------------------------------------------"
    for item in "${!data[@]}"; do
        eval "declare -A record=${data[item]}"
        if [[ "${record[status]}" == "stopped" ]]; then
            # shellcheck disable=SC2207
            local -a tags=( $(split_on ";" "${record["tags"]:-}") )
            local display_tags=""
            
            for t in "${tags[@]}"; do
                local color
                allow_errors
                if not_empty "${tag_color["$t"]}"; then
                    color="${tag_color["$t"]}"
                else
                    if ! unshift tag_palette color; then
                        # shellcheck disable=SC2034
                        tag_palette=( "${BG_PALLETTE[@]}" )
                        unshift tag_palette color
                    fi
                    tag_color["$t"]="$color"
                fi
                catch_errors
                display_tags="${display_tags} ${color}${t}${RESET}"
            done

            local template_icon=""
            if [[ "${record["template"]}" == "1" ]]; then
                template_icon="📄 "
            fi

            log "- ${template_icon}${record["name"]} [${DIM}${record["vmid"]}${RESET}]: ${ITALIC}${DIM}residing on ${RESET}${record["node"]}; ${display_tags}"; 
        fi
    done
    catch_errors
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
        local icons=""
        if contains "images" "${data["content"]}"; then
            icons="${icons} 🥏"
        fi
        if contains "backup" "${data["content"]}"; then
            icons="${icons} ⏺️ "
        fi
        if contains "snippets" "${data["content"]}"; then
            icons="${icons} ✄"
        fi
        if contains "rootdir" "${data["content"]}"; then
            icons="${icons} ⋋"
        fi
        if contains "iso" "${data["content"]}"; then
            icons="${icons} 📀"
        fi
        if contains "pbs" "${data["content"]}"; then
            icons="${icons} 👆"
        fi
        if [[ "${data[shared]}" == "1" ]]; then
            log "- ${data["storage"]}${DIM}@${data["server"]}${RESET} - ${BOLD}${BLUE}${data["type"]}${RESET} -${icons} - ${DIM}${data["path"]:-}${RESET}"
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
