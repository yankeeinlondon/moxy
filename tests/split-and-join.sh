#!/usr/bin/env bash

function unit_test() {
    # local -r root_path="${1:?unit test did not get the ROOT path of the repo}"
    # local -r test_file="${2:?unit test did not get the test filename}"

    text="foo bar baz"
    csv="foo,bar, baz, foo and bar"

    # shellcheck disable=SC2207
    text_arr=$(split "$text" " ")
    test_result $? "splitting on space, returned without error"
    EQ=$(assert_eq "${#text_arr[@]}" "3")
    test_result $? "splitting on space, produced right result length [${EQ}]"

    test_separator

    # shellcheck disable=SC2207
    csv_arr=( $(split "$csv" "," ) )
    EQ=$(assert_eq "4" "${#csv_arr[@]}")
    test_result $? "splitting on comma, produced right result length [${EQ}]"
    
    EQ=$(assert_contains "foo" "${csv_arr[@]}" )
    test_result $? "splitting on comma, contains element [${EQ}]"
    EQ=$(assert_contains " baz" "${csv_arr[@]}" )
    test_result $? "splitting on comma, contains element [${EQ}]"
    EQ=$(assert_contains "foo and bar" "${csv_arr[@]}" )
    test_result $? "splitting on comma, contains element [${EQ}]"
}
