#!/usr/bin/env bash

#shellcheck disable=SC1091
source "${MOXY}/tests/test-utils.sh"
set +e

declare -ra files=( $(get_files "${MOXY}/tests" "*.sh" "--relative" "${@}") )
test_count=${#files[@]}

log ""
log "Running ${test_count} Test File(s) 🏃"
log "${DIM}just test ${ITALIC}${1}${RESET}"
log "------------------------------------------"
cd "${MOXY}/tests" > /dev/null || exit 1
for f in "${files[@]}"; do

    log "\n- testing file ${GREEN}${f}${RESET}:"
    # shellcheck disable=SC1090
    source "${f}"
    unit_test "${PWD}" "${f}"
done
cd "-" > /dev/null || exit 1
