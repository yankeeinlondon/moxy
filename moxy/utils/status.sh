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
    local -r json=$(pve_lxc_containers)
    local -a data=()
    local -A query=(
        [sort]="vmid"
    )
    json_list_data json data query
    local -A record

    local -A tag_color=()
    # shellcheck disable=SC2034
    local -a tag_palette=( "${BG_PALLETTE[@]}" )

    # Sort by VMID and display the results
    log ""
    log "🏃${BOLD} Running LxC Containers${RESET}"
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
    log "✋${BOLD} Stopped LxC Containers${RESET}"
    log "-----------------------------------------------------"
    for item in "${!data[@]}"; do
        eval "declare -A record=${data[item]}"
        if [[ "${record[status]}" = "stopped" ]]; then
            # shellcheck disable=SC2207
            local -a tags=( $(split_on ";" "${record["tags"]:-}") )
            local display_tags=""
            
            for t in "${tags[@]}"; do
                local color
                if not_empty "${tag_color["$t"]:-}"; then
                    color="${tag_color["$t"]:-}"
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

            local locked_icon=""

            log "- ${template_icon}${locked_icon}${record["name"]} [${DIM}${record["vmid"]}${RESET}]: ${ITALIC}${DIM}residing on ${RESET}${record["node"]}; ${display_tags}"; 
        fi
    done
}

function vm_status() {
    local -r json=$(pve_vm_containers)
    local -a data=()
    local -A query=(
        [sort]="vmid"
    )
    json_list_data json data query
    local -A record

    local -A tag_color=()
    # shellcheck disable=SC2034
    local -a tag_palette=( "${BG_PALLETTE[@]}" )

    # Sort by VMID and display the results
    log ""
    log "🏃${BOLD} Running VM Containers${RESET}"
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
    log "✋${BOLD} Stopped VM Containers${RESET}"
    log "-----------------------------------------------------"
    for item in "${!data[@]}"; do
        eval "declare -A record=${data[item]}"
        if [[ "${record[status]}" = "stopped" ]]; then
            # shellcheck disable=SC2207
            local -a tags=( $(split_on ";" "${record["tags"]:-}") )
            local display_tags=""
            
            for t in "${tags[@]}"; do
                local color
                if not_empty "${tag_color["$t"]:-}"; then
                    color="${tag_color["$t"]:-}"
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

            local locked_icon=""

            log "- ${template_icon}${locked_icon}${record["name"]} [${DIM}${record["vmid"]}${RESET}]: ${ITALIC}${DIM}residing on ${RESET}${record["node"]}; ${display_tags}"; 
        fi
    done
}
function cluster_status() {
    echo "not ready"
}

function node_status() {
    local name=""
    local -a nodes=()

    pve_cluster_info name nodes

    log "Cluster: ${name}"
    log "Nodes:"
    
    for obj in "${nodes[@]}"; do
        eval "local -A record=${obj}"
        local online
        if [[ "${record[online]}" == "1" ]]; then
            online="${BG_GREEN} online ${RESET}"
        else
            online="${BG_RED} offline ${RESET}"
        fi
        log "  - ${record[name]}${DIM}@${record[ip]} ${online}"

    done

}

report() {
    local -n record=$1
    log "- ${record[name]}"
}
function ha_status() {
    local -a data=()
    local -r json=$(pve_cluster_ha_status)

    # shellcheck disable=SC2207
    json_list json data

    log "${#data[@]}"

    log "${data[1]}"
    # for obj in "${data[@]}"; do
    #     log "keys: $(keys "$obj")"
    # done

    unset report
}

function storage_status() {
    # shellcheck disable=SC2034
    local -r json=$(pve_storage)
    local -a data=()
    # shellcheck disable=SC2034
    local -A query=()
    json_list_data json data query
    local -A record

    log ""
    log "🐘${BOLD} Shared Storage${RESET}"
    log "-----------------------------------------------------"
    for idx in "${!data[@]}"; do
        eval "declare -A record=${data[idx]}"
        local icons=""
        if contains "images" "${record["content"]}"; then
            icons="${icons} 🥏"
        fi
        if contains "backup" "${record["content"]}"; then
            icons="${icons} ⏺️ "
        fi
        if contains "snippets" "${record["content"]}"; then
            icons="${icons} ✄"
        fi
        if contains "rootdir" "${record["content"]}"; then
            icons="${icons} ⋋"
        fi
        if contains "iso" "${record["content"]}"; then
            icons="${icons} 📀"
        fi
        if contains "pbs" "${record["content"]}"; then
            icons="${icons} 👆"
        fi
        if [[ "${record[shared]:-}" == "1" ]]; then
            log "- ${record[storage]}${DIM}@${record[server]:-}${RESET} - ${BOLD}${BLUE}${record[type]:-}${RESET} -${icons} - ${DIM}${record[path]:-}${RESET}"
        fi
    done

    log ""
    log "🛖${BOLD} Local Storage${RESET}"
    log "-----------------------------------------------------"
    allow_errors
    for idx in "${!data[@]}"; do
        eval "declare -A record=${data[idx]}"
        if [[ "${record[shared]:-}" == "0" ]]; then
            log "- ${record[storage]:-} - ${BOLD}${BLUE}${record[type]:-}${RESET} - "

        fi
    done
    catch_errors
}


function moxy_status() {
    local -r focus="${1:-}"

    case $(lc "$focus") in
        nodes) node_status;;
        storage) storage_status;;
        lxc) lxc_status;;
        vm) vm_status;;
        cluster) cluster_status;;
        ha) ha_status;;
        *) status_help;;
    esac
}
