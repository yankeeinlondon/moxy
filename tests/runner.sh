#!/usr/bin/env bash

# shellcheck disable=SC1091
source "${PWD}/tests/test-utils.sh"

set +e

# ctx=$(flags "$@")
# destruct params, flags = ctx

# info "ctx: ${ctx[*]}"
# info "params: ${params}"

# shellcheck disable=2207
files=( $(get_files "$(pwd)" "./tests/*.sh" "--relative" "!runner.sh" "!test-utils" "$1") )
test_count=${#files[@]}

log ""
log "Running ${test_count} Test File(s) 🏃"
log "------------------------------------------"

for f in "${files[@]}"; do

    log "\n- testing file ${GREEN}${f}${RESET}:"
    # shellcheck disable=SC1090
    source "${f}"
    unit_test "${PWD}" "${f}"

done

