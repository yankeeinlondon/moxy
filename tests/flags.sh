#!/usr/bin/env bash

function unit_test() {
    declare -a args=( "foo" "bar" "-v" )
    
    declare -a ctx=$(flags "${args[@]}")
    info "${ctx[*]}"
    test_result $? "calling flags() on a list results in successful return code"
    EQ=$(assert_eq "${OBJECT_PREFIX}${OBJECT_SUFFIX}" "$object")
    test_result $? "the initialized object format is correct → ${EQ}"


}
