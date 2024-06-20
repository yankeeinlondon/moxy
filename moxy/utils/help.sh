#!/usr/bin/env bash

# shellcheck source="./logging.sh"
. "./utils/logging.sh"

function moxy_help() {
    log ""
    log "${GREEN}${BOLD}MOXY Help${RESET}"
    log "${GREEN}${BOLD}----------------------------------------------------------${RESET}"
    log "${BOLD}Syntax:${RESET} moxy [cmd] [${DIM}options${RESET}] [${DIM}flags${RESET}]"
    log ""
    log "${BOLD}Commands:${RESET}"
    log " ${GREEN}◦${RESET} ${BOLD}lxc${RESET} [ ${DIM}distro${RESET} ] - ${ITALIC}${DIM}create a new LXC container${RESET}"
    log " ${GREEN}◦${RESET} ${BOLD}vm${RESET} [ ${DIM}distro${RESET} ] - ${ITALIC}${DIM}create a new Virtual Machine${RESET}"
    log " ${GREEN}◦${RESET} ${BOLD}service${RESET} [ ${DIM}name${RESET} ] - ${ITALIC}${DIM}adds a new service/pkg based container${RESET}"
    log " ${GREEN}◦${RESET} ${BOLD}script${RESET} [ ${DIM}name${RESET} ]"
    log " ${GREEN}◦${RESET} ${BOLD}status${RESET} [ ${DIM}nodes|lxc|vm|cluster${RESET} ]"
    log " ${GREEN}◦${RESET} list [ ${DIM}lxc|vm|service|script${RESET} ] - ${ITALIC}${DIM}lists variants of the specified command${RESET}"
    log " ${GREEN}◦${RESET} set [ ${DIM}key|distro|ssh${RESET} ] - ${ITALIC}${DIM}set defaults for various properties${RESET}"
    log " ${GREEN}◦${RESET} update - ${ITALIC}${DIM}check online for any updates${RESET}"
    
    log ""
    log "${BOLD}CLI Flags:${RESET}"
    log "  --id=<${DIM}vmid${RESET}>  - ${ITALIC}${DIM}set the VM ID for the new container${RESET}"
    log "  --node=<${DIM}name${RESET}>  - ${ITALIC}${DIM}target a specific node${RESET}"
    log "  --ssh  - ${ITALIC}${DIM}ensure ssh is enabled${RESET}"
    log "  --no-ssh  - ${ITALIC}${DIM}ensure ssh is disable${RESET}"
    log "  --ip=<${DIM}ip-address${RESET}>  - ${ITALIC}${DIM}the ipv4 address for the new container${RESET}"
    log "  --ip6=<${DIM}ip-address${RESET}>  - ${ITALIC}${DIM}the ipv6 address for the new container${RESET}"
    log ""
}

