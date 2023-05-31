#!/usr/bin/env bash

function unit_test() {
    # test data
    declare -r lst=$(list "foo" "bar" "baz")
    declare -r kv1=$(kv "foo" "foey")
    declare -r kv2=$(kv "bar" "barred")
    declare -r obj=$(object "${kv1}" "${kv2}")
    # shellcheck disable=SC2034
    declare -ra arr=(foo bar baz)

    test_separator "synthetic container detection"

    is_list "$lst"
    test_result $? "is_list detects a valid list"
    assert_error is_list "nope"
    test_result $? "is_list fails when passed a string"

    
    is_kv_pair "${kv1}"
    test_result $? "is_kv_pair detects a valid kv pair"
    assert_error is_kv_pair "${kv1}"
    test_result $? "is_kv_pair fails when given a list"
    assert_error is_kv_pair "nope"
    test_result $? "is_kv_pair fails when given a string"

    is_object "${obj}"
    test_result $? "is_object detect a valid object"
    assert_error is_object "${lst}"
    test_result $? "is_object fails when given a list"
    
    test_separator "core variable detection"

    is_array arr
    test_result $? "is_array detects a valid array"
    is_array obj
    assert_error $? 
    test_result $? "is_array fails when passed an object"

    is_function object
    test_result $? "is_function correctly sees \$(object) as a function"
    is_function "foobar"
    assert_error $?
    test_result $? "is_function fails when passed a string"
    is_function if
    assert_error $?
    test_result $? "is_function fails when passed a keyword"

    is_keyword if
    test_result $? "is_keyword correctly identifies \"if\" as a keyword"
    is_keyword "do"
    test_result $? "is_keyword correctly identifies \"do\" as a keyword"
    is_keyword "object"
    assert_error $?
    test_result $? "is_keyword rejects \"object\" as a keyword"

    is_shell_command ls
    test_result $? "is_shell_command correctly identifies \"ls\" as a shell command"
    is_shell_command ll
    assert_error $?
    test_result $? "is_shell_command rejects \"ll\" as a shell command"

    test_separator "shell alias detection"
    # normally child processes do not get forwarded aliases
    # TODO: see if we can find way to introspect parent shell

    # set a alias manually in current shell
    alias ll="ls -l"

    is_shell_alias "ll"
    test_result $? "is_shell_alias correctly identifies \"ll\" as a shell alias"
    is_shell_alias "not_gonna_happen"
    assert_error $?
    test_result $? "is_shell_command rejects \"not_gonna_happen\" as a shell alias"
}
