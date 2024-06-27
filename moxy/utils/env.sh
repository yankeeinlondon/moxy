#!/usr/bin/env bash

# ENV variable definitions


export MOXY_CONFIG_FILE="${HOME}/.config/moxy/config.toml"


export CANCELLED="CANCELLED"
# APP_ID
# 
# the PID assigned to the original script executed
export APP_ID="${BASHPID}"

export LIST_DELIMITER="${LIST_DELIMITER:-|*|}"
export LIST_PREFIX="list::["
export LIST_SUFFIX="]"
export OBJECT_PREFIX="${OBJECT_PREFIX:-object::{ }"
export OBJECT_SUFFIX="${OBJECT_SUFFIX:- \}::object}"
export OBJECT_DELIMITER="${OBJECT_DELIMITER:-|,|}"
export KV_PREFIX="${KV_PREFIX:-kv(}"
export KV_SUFFIX="${KV_SUFFIX:-)}"
export KV_DELIMITER="${KV_DELIMITER:-→}"

export DEBUG="${DEBUG:-false}"
export DEFAULT_TEMPLATE_ID="${DEFAULT_TEMPLATE_ID:-800}"
export HOST="${HOST:-unknown host}"

# PVE and Cluster Characteristics



# Container Characteristics
export VM_ENV="NETWORK MEMORY CORES CPU DISTRO STORAGE_VOL STORAGE_AMT VM_USER OS_TYPE HOST_TYPE SSH_KEYFILE PASSWORD"

export NETWORK="${NETWORK:-vmbr0}"
export NETWORK_DESC="The network interface (e.g., vmbr0, vmbr1, etc.)"
export MEMORY="${MEMORY:-1024}"
export CORES="${CORES:-2}"
export CPU="${CPU:-host}"
export DISTRO="${DISTRO:-debian/11}"
export STORAGE_VOL="${STORAGE_VOL:-local-zfs}"
export STORAGE_AMT="${STORAGE_AMT:-8G}"
export VM_USER="${VM_USER:-ken}"
export OS_TYPE="${HOST_TYPE:-l26}"
export HOST_TYPE="${HOST_TYPE:-host}"
export SSH_KEYFILE="${SSH_KEYFILE:-${HOME}/.ssh/authorized_keys}"
export HAS_SSD_STORAGE="${HAS_SSD_STORAGE:-true}"
export HAS_SSD_STORAGE_DESC="A flag to indicate whether a container uses SSD storage. If the value is true then the drive configuration will turn on SSD emulation and TRIM support."
export PASSWORD="${PASSWORD:-do-not-use}"
export PASSWORD_DESC="By default it takes the value of \"do-not-use\" which means that the container will NOT have a password and rely on SSH keys instead. If it's set to any other value then that will be the password set on the container."

export DIALOG_OK=0;
export DIALOG_CANCEL=1;
export DIALOG_HELP=2;
export DIALOG_EXTRA=3;
export DIALOG_HELP=4;
export DIALOG_TIMEOUT=5;
# when error occur inside dialog or user presses ESC
export DIALOG_ERR=-1;
