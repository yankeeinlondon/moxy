#!/usr/bin/env bash

if [[ ${LOCAL_RUNNER} == "true" ]]; then
  # shellcheck disable=SC1091
  source "${PWD}/util/build.fun"
else
  # shellcheck disable=SC1090
  source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
fi

function name() {
  echo "Alpine"
}

function description() {
  echo ""
}

function notes() {
  local -r service_url="${1}"

  echo "# Cronicle 
> ${service_url}

## Resources

- [Github](https://github.com/jhuckaby/Cronicle)
- [Website](http://cronicle.net/)
"
}

function banner() {
  echo "
    ___    __      _          
   /   |  / /___  (_)___  ___ 
  / /| | / / __ \/ / __ \/ _ \
 / ___ |/ / /_/ / / / / /  __/
/_/  |_/_/ .___/_/_/ /_/\___/ 
        /_/                   

"
}

function questions() {
  local -A questions=()

  add_ct_default_questions "${questions[@]}"

  echo "${questions[@]}"
}

function default_values() {
  local -A defaults=()

  add_ct_default "${defaults[@]}" "type" "${ALPINE_CT_TYPE:-1}" "ALPINE_CT_TYPE"
  add_ct_default "${defaults[@]}" "disk" "0.1" "ALPINE_DISK"
  add_ct_default "${defaults[@]}" "cpu" "${ALPINE_CPU:-0.1}" "ALPINE_CPU"
  add_ct_default "${defaults[@]}" "ram" "${ALPINE_RAM:-512}" "ALPINE_RAM"
  add_ct_default "${defaults[@]}" "os" "alpine"
  add_ct_default "${defaults[@]}" "version" "${ALPINE_VERSION:-3.17}" "ALPINE_VERSION"
  add_ct_default "${defaults[@]}" "SSH" "${SSH:-no}" "SSH" "ALPINE_SSH"
  add_ct_default "${defaults[@]}" "bridge" "${ALPINE_BRIDGE:-vmbr0}" "ALPINE_BRIDGE" "BRIDGE" 
  add_ct_default "${defaults[@]}" "gateway" "${ALPINE_GATEWAY:-}" "ALPINE_GATEWAY" "GATEWAY" 
  add_ct_default "${defaults[@]}" "network" "${ALPINE_NETWORK:-dhcp}" "ALPINE_NETWORK" "NETWORK"
  add_ct_default "${defaults[@]}" "disable_ip6" "${ALPINE_IP6:-no}" "IP6" "ALPINE_IP6"
  add_ct_default "${defaults[@]}" "authorized_keys" "${ALPINE_AUTH_KEYS:-}" "ALPINE_AUTHORIZED_KEYS" "AUTHORIZED_KEYS" 

  echo "${defaults[@]}"
}

function installer() {
  # the list of packages which are to be added into the new container
  local -a packages=()
  # returns an API surface for either the native package manager for alpine
  # (aka, apk) or alternatively the **Nix** package manager
  local -a pkg_mngr=$(get_package_manager "alpine")

  # add_gpg_signature

  # add any default packages which a user may have expressed
  # interest in; both for CT's and VM's
  add_default_packages "$pkg_mngr"
  # add packages which a user has expressed they want in CT's
  add_default_ct_packages "$pkg_mngr"

  # add_other_packages


}


function update_script() {
UPD=$(whiptail --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 1 \
  "1" "Check for Alpine Updates" ON \
  3>&1 1>&2 2>&3)

header_info
if [ "$UPD" == "1" ]; then
apk update && apk upgrade
exit;
fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
