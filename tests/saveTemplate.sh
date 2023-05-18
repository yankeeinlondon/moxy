#!/usr/bin/env bash


function unit_test() {
    local -r root_path="${1:?unit test did not get the ROOT path of the repo}"
    local -r _test_file="${2:?unit test did not get the test filename}"

    # shellcheck disable=SC1091
    source "${root_path}/utils/saveTemplate.sh"

    # load the monitor-all template without the ".sh" extension
    saveTemplate "pve-monitoring" "/tmp/monitor-all-test"
    test_result $? "call returned without error (without specifying .sh)"

    saveTemplate "pve-monitoring" "/tmp/monitor-all-test"
    test_result $? "call returned without error (while specifying .sh)"

    # ensure that file actually exists
    test -f "/tmp/monitor-all-test" && rm "/tmp/monitor-all-test" # test & cleanup
    test_result $? "the file -- ${BOLD}/tmp/monitor-all-test${RESET} -- actually does exist in filesystem"
    
}
