#!/usr/bin/env bash

function unit_test() {
    # local -r root_path="${1:?unit test did not get the ROOT path of the repo}"
    # local -r test_file="${2:?unit test did not get the test filename}"

    text="foo bar baz"
    quoted='"foo" "bar" "baz"'
    csv='foo,bar, baz, foo and bar'

    catch_errors

    declare -a arr=()

    test_separator "split on space"
    # shellcheck disable=SC2207
    arr=( $(split " " "$text") )
    test_result $? "simple space delimited string returned without error"
    EQ=$(assert_eq "${#arr[@]}" "3")
    test_result $? "produced expected length [${EQ}]"

    # shellcheck disable=SC2207
    arr=( $(split " " "$quoted") )
    test_result $? "splitting on a quoted string"
    EQ="$(assert_eq "${#arr[@]}" "3")"
    test_result $? "produced expected length [${EQ}]"

    test_separator "split on the object delimiter"

    # shellcheck disable=SC2016
    object_def='object::{ kv[cmd→get "${obj}" "foo"]|,|kv[msg→indexing an object with valid key]|,|kv[exit_code→0]|,|kv[return_eq→foo] }'
    # shellcheck disable=SC2207
    arr=( $(split "${OBJECT_DELIMITER}" "$object_def") )
    test_result $? "split() returns successful exit code when splitting an object definition"
    EQ=$(assert_eq "${#arr[@]}" "4")
    test_result $? "split() returns the expected length [${EQ}]"

    test_separator "split on comma"

    # shellcheck disable=SC2207
    arr=( $(split "," "$csv" ) )

    EQ=$(assert_eq "4" "${#arr[@]}")
    test_result $? "splitting on comma, produced right result length [${EQ}]"
    
    EQ=$(assert_contains "foo" "${arr[@]}" )
    test_result $? "contains element [${EQ}]"
    EQ=$(assert_contains "bar" "${arr[@]}" )
    test_result $? "contains element [${EQ}]"
    EQ=$(assert_contains " baz" "${arr[@]}" )
    test_result $? "contains element [${EQ}]"
    EQ=$(assert_contains "foo and bar" "${arr[@]}" )
    test_result $? "contains element [${EQ}]"
}
