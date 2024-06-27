#!/usr/bin/env bash

# LOADS ALL SHARED FUNCTIONS FOR MOXY
# WHICH ARE KEPT IN OTHER FILES SIMPLY
# FOR ORGANIZATIONAL PURPOSES


# shellcheck source="./env.sh"
. "./utils/env.sh"
# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./errors.sh"
. "./utils/errors.sh"
# shellcheck source="./help.sh"
. "./utils/help.sh"
# shellcheck source="./conditionals.sh"
. "./utils/conditionals.sh"
# shellcheck source="./mutate.sh"
. "./utils/mutate.sh"
# shellcheck source="./info.sh"
. "./utils/info.sh"
# shellcheck source="./interactive/ask.sh"
. "./utils/interactive/ask.sh"
# shellcheck source="./interactive/questions.sh"
. "./utils/interactive/questions.sh"

# shellcheck source="./proxmox.sh"
. "./utils/proxmox.sh"

# shellcheck source="./fetch.sh"
. "./utils/fetch.sh"
# shellcheck source="./status.sh"
. "./utils/status.sh"

# shellcheck source="./ready.sh"
. "./utils/ready.sh"
