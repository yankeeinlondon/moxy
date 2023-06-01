#!/usr/bin/env bash

# shellcheck disable=SC1091
source "${MOXY}/utils/shared.sh"
source "${MOXY}/utils/proxmox.sh"
source "${MOXY}/utils/interactive/ask.sh"
catch_errors

DEBIAN_10="${DEBIAN_10:-debian-10-generic-amd64.qcow2}"
DEBIAN_11="${DEBIAN_11:-debian-11-generic-amd64.qcow2}"
DEBIAN_12="${DEBIAN_12:-debian-12-generic-amd64-daily.qcow2}"
UBUNTU_20_4="${UBUNTU_20_4:-ubuntu-20.04-server-cloudimg-amd64.img}"
UBUNTU_22_4="${UBUNTU_22_4:-ubuntu-22.04-server-cloudimg-amd64.img}"
UBUNTU_23_4="${UBUNTU_23_4:-lunar-server-cloudimg-amd64.img}"
FEDORA_37="${FEDORA_37:-Fedora-Cloud-Base-37-1.7.x86_64.raw.xz}"
CENTOS_8="${CENTOS_8:-CentOS-Stream-GenericCloud-8-latest.x86_64.qcow2}"
CENTOS_9="${CENTOS_9:-CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2}"

function cloud_img_exists() {
    local -r file="${1:?no filename passed to cloud_img_exists}"

    if [[ -f "$(pwd)/${file}" ]]; then
        return 0
    else
        return 1
    fi
}

function download_cloud_image() {
    local -r distro="${1:?no distro was passed to get_cloud_image}"

    case $distro in 

        "debian/10") 
            if ! cloud_img_exists "${DEBIAN_10}"; then
                log "Downloading cloud image"
                wget "https://cloud.debian.org/images/cloud/buster/latest/${DEBIAN_10}"
            fi
            echo "${DEBIAN_10}"
            return 0
            ;;
        "debian/11")
            if ! cloud_img_exists "${DEBIAN_11}"; then
                log "Downloading cloud image"
                wget "https://cloud.debian.org/images/cloud/bullseye/latest/${DEBIAN_11}"
            fi
            echo "${DEBIAN_11}"
            return 0
            ;;

        "debian/12")
            if ! cloud_img_exists "${DEBIAN_12}"; then
                log "Downloading cloud image"
                wget "https://cloud.debian.org/images/cloud/bookworm/daily/latest/${DEBIAN_12}"
            fi
            echo "${DEBIAN_12}"
            return 0
            ;;

        "ubuntu/20_04")
            if ! cloud_img_exists "${UBUNTU_20_4}"; then
                log "Downloading cloud image"
                wget "https://cloud-images.ubuntu.com/releases/focal/release/${UBUNTU_20_4}"
            fi
            echo "${UBUNTU_20_4}"
            return 0
            ;;

        "ubuntu/22_04")
            if ! cloud_img_exists "${UBUNTU_22_4}"; then
                log "Downloading cloud image"
                wget "https://cloud-images.ubuntu.com/releases/22.04/release/${UBUNTU_22_4}"
            fi
            echo "${UBUNTU_22_4}"
            return 0
            ;;

        "ubuntu/23_04")
            if ! cloud_img_exists "${UBUNTU_23_4}"; then
                log "Downloading cloud image"
                wget "https://cloud-images.ubuntu.com/lunar/current/${UBUNTU_23_4}"
            fi
            echo "${UBUNTU_23_4}"
            return 0
            ;;

        "fedora/37")
            if ! cloud_img_exists "${FEDORA_37}"; then
                wget "https://download.fedoraproject.org/pub/fedora/linux/releases/37/Cloud/x86_64/images/${FEDORA_37}"
            fi
            echo "${FEDORA_37}"
            return 0
            ;;

        "centos/8")
            if ! cloud_img_exists "${CENTOS_8}"; then
                log "Downloading cloud image"
                wget "https://cloud.centos.org/centos/8-stream/x86_64/images/${CENTOS_8}"
            fi
            echo "${CENTOS_8}"
            return 0
            ;;        

        "centos/9")
            if ! cloud_img_exists "${CENTOS_9}"; then
                log "Downloading cloud image"
                wget "https://cloud.centos.org/centos/9-stream/x86_64/images/${CENTOS_9}"
            fi
            echo "${CENTOS_9}"
            return 0
            ;;

        *)
            error "\"${1}\" is an unknown distribution"
            return 1
            ;;
    esac
}

function vm_name() {
    local -r distro="${1:?no distro was passed to vm_name}"
    local name=""
    name="${distro//\//-}"
    name="${name//_/-}"
    echo "${name}-template"
}

# create_template <[id]> <[distro]>
#
# Creates a reusable VM template on a given PVE host. The ID and distro can be passed in but
# if not present will be solicited interactively.
function create_template() {
    local vm_id="${1:-undefined}"
    local distro="${2:-undefined}"

    if [[ "${vm_id}" == "undefined" ]]; then
        allow_errors
        SUGGEST=$(next_container_id) || "800"
        catch_errors

        vm_id=$(ask_for_text "" "VM ID" "What ID will you use for the template?" 8 58 "${SUGGEST}")

        # vm_id=$(whiptail --inputbox "What ID will you use for the template?" 8 58 "${SUGGEST}" --title "VM ID" )

        exit_status=$?
        if [[ $exit_status != 0 ]]; then
            log "exiting ..."
            exit 1
        fi
    fi

    if [[ "${distro}" == "undefined" ]]; then
        allow_errors
        local -A options=(
            [debian/10]="current stable release"
            [debian/11]="current stable release"
            [debian/12]="daily release"
            [ubuntu/20_04]="current stable release"
            [ubuntu/22_04]="current stable release"
            [ubuntu/23_04]="daily release"
            [fedora/37]="current stable release"
            [centos/8]="current stable release"
            [centos/9]="current stable release"
        )
        local -r choices=$(as_object "${options[@]}")


        distro=$(ask_from_menu "Distro" "What distro do you want?" "$choices" )



        distro=$(whiptail --title "Distro" --menu "What distro do you want to use?" 15 58 9 \
            "debian/10" "current stable release" \
            "debian/11" "current stable release"  \
            "debian/12" "daily release"  \
            "ubuntu/20_04" "current stable release"  \
            "ubuntu/22_04" "current stable release"  \
            "ubuntu/23_04" "daily release"  \
            "fedora/37" "current stable release"  \
            "centos/8" "current stable release"  \
            "centos/9" "current stable release"  \
            3>&1 1>&2 2>&3 \
        )
        exit_status=$?
        if [[ $exit_status != 0 ]]; then
            log "exiting ..."
            exit 1
        fi
        catch_errors
    fi

    set +e
    name=$(whiptail --inputbox "The name for the VM" 12 58 "$(vm_name "$distro")" --title "VM Name" 3>&1 1>&2 2>&3)
    exit_status=$?
    if [[ $exit_status != 0 ]]; then
        log "exiting ..."
        exit 1
    fi
    catch_errors

    #Print all of the configuration
    local -r f_cmd="${BOLD}${GREEN}"
    local -r f_env="${DIM}"
    local -r f_point="${BOLD}☞${RESET}"

    log "Creating template ${BOLD}${name}${RESET} [id:${DIM}$vm_id${RESET}]"
    log ""
    log "- template ${ITALIC}defaults${RESET} are:"
    log ""
    log "  ${f_point}  memory: ${f_cmd}${MEMORY}${RESET} [${f_env}MEMORY${RESET}], cores: ${f_cmd}${CORES}${RESET} [${f_env}CORES${RESET}], STORAGE_VOL vol: ${f_cmd}${STORAGE_VOL}${RESET} [${f_env}STORAGE_VOL${RESET}], STORAGE_VOL amt: ${f_cmd}${STORAGE_AMT}${RESET} [${f_env}STORAGE_AMT${RESET}]"
    log "  ${f_point}  Host type: ${f_cmd}${HOST_TYPE}${RESET} [${f_env}NETWORK${RESET}], OS type: ${f_cmd}${OS_TYPE}${RESET} [${f_env}OS_TYPE${RESET}]"
    log "  ${f_point}  SSH Keyfile: ${f_cmd}${SSH_KEYFILE}${RESET} [${f_env}SSH_KEYFILE${RESET}], Password: ${f_cmd}${PASSWORD}${RESET}  [${f_env}PASSWORD${RESET}]"
    log ""
    log "- validate that this base for the template is acceptable (${f_env}dimmed values${RESET} are the ENV variables "
    log "  you can change for different defaults)"
    log ""

    ask_to_continue "yes"

    #Create new VM 
    #Feel free to change any of these to your liking
    qm create "${vm_id}" --name "${name}" --ostype "${OS_TYPE}" 
    #Set networking to default bridge
    qm set "${vm_id}" --net0 "virtio,bridge=${NETWORK}"
    #Set display to serial
    qm set "${vm_id}" --serial0 socket --vga serial0
    #Set memory, cpu, type defaults
    #If you are in a cluster, you might need to change cpu type
    qm set "${vm_id}" --memory "${MEMORY}" --cores "${CORES}" --cpu "${HOST_TYPE}"

    # download the cloud image file if not already present
    local -r filename=$(download_cloud_image "${distro}")
    #Set boot device to new file
    qm set "${vm_id}" --scsi0 "${STORAGE_VOL}:0,import-from=$(pwd)/${filename},discard=on"

    #Set scsi hardware as default boot disk using virtio scsi single
    qm set "${vm_id}" --boot order=scsi0 --scsihw virtio-scsi-single
    #Enable Qemu guest agent in case the guest has it available
    qm set "${vm_id}" --agent enabled=1,fstrim_cloned_disks=1
    #Add cloud-init device
    qm set "${vm_id}" --ide2 "${STORAGE_VOL}":cloudinit
    #Set CI ip config
    #IP6 = auto means SLAAC (a reliable default with no bad effects on non-IPv6 networks)
    #IP = DHCP means what it says, so leave that out entirely on non-IPv4 networks to avoid DHCP delays
    qm set "${vm_id}" --ipconfig0 "ip6=auto,ip=dhcp"
    #Import the ssh keyfile

    if [[ "${SSH_KEYFILE}" == "" ]]; then
        log "- the SSH ${ITALIC}authorized keys${RESET} will NOT be set because the SSH_KEYFILE was"
        log "  set to an empty string."
    else
        log ""
        log "- adding SSH ${ITALIC}authorized keys${RESET} for the VM template from the file: ${SSH_KEYFILE}"
        qm set "${vm_id}" --sshkeys "${SSH_KEYFILE}" > /dev/null
    fi
    # If you want to do password-based auth instaed
    # Then use this option and comment out the line above
    if [[ "${PASSWORD}" != "do-not-use" ]]; then
        log "- the PASSWORD environment variable was set; using this to provide the VM with a"
        log "  password for the user \"${VM_USER}\"."
        qm set "${vm_id}" --cipassword password
        log ""
    else
        log "- the user \"${VM_USER}\" has been created but without a password so you will need"
        log "  to use SSH keys to access the VM's based on this template"
        log ""
    fi

    #Add the user
    qm set "${vm_id}" --ciuser "${VM_USER}"

    #Resize the disk to 8G, a reasonable minimum. You can expand it more later.
    #If the disk is already bigger than 8G, this will fail, and that is okay.
    qm disk resize "${vm_id}" scsi0 "${STORAGE_AMT}"

    log "- disk resized ... making VM ID ${GREEN}${vm_id}${RESET} into a template"
    #Make it a template
    qm template "${vm_id}"
    log "Done! 🎉"
    log ""

}

# main
create_template "${1:-}" "${2-}"
