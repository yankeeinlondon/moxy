#!/usr/bin/env bash


# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./interactive/ask.sh"
. "./utils/interactive/ask.sh"
# shellcheck source="./interactive/questions.sh"
. "./utils/interactive/questions.sh"


function preferred_distro() {

    local -A radio=( [msg]="What should be your default distro choice?" [backmsg]="Moxy Preferences (distro)" [width]=60 [height]=23  [radio_height]=8 [choices]=DISTRO_CHOICES)

    log "Assoc Array: ${radio[*]}"

    # radio["msg"]="What should be your default distro choice?"
    # radio["backmsg"]="Moxy Preferences (distro)"

    # DISTRO=$(ask_radiolist "${msg}" 23 60 8 "${DISTRO_CHOICES[@]}")

}
