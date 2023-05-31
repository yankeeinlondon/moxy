#!/usr/bin/env bash


function unit_test() {
    test_separator "list()"
    list=$(list)
    test_result $? "can create empty list without error"
    EQ=$(assert_eq "${LIST_PREFIX}${LIST_SUFFIX}" "$list")
    test_result $? "the initialized list format is correct → ${EQ}"

    list=$(list "foo" "bar" "baz")
    test_result $? "call to list() with initial values foo,bar,baz"
    EQ=$(assert_eq "${LIST_PREFIX}foo${LIST_DELIMITER}bar${LIST_DELIMITER}baz${LIST_SUFFIX}" "$list")
    test_result $? "the initialized list is correct → ${EQ}"

    declare -a arr=("foo" "bar" "baz")
    list=$(list "${arr[@]}")
    test_result $? "call to list() with an ${ITALIC}array${RESET} of values"
    EQ=$(assert_eq "${LIST_PREFIX}foo${LIST_DELIMITER}bar${LIST_DELIMITER}baz${LIST_SUFFIX}" "$list")
    test_result $? "the initialized list is correct → ${EQ}"

    test_separator "as_array()"

    declare -ar arr=( $(as_array "${list}") )
    test_result $? "as_array(list) call returns successfully"
    EQ=$(assert_eq "${#arr[@]}" "3" )
    test_result $? "the array has correct length [${EQ}]"
    contains "foo" "${arr[@]}"
    test_result $? "array contains value \"foo\""

    test_separator "get() dereferencing"

    # shellcheck disable=SC2016
    t=(
        'get "1" "${list}"'
        "can index a list with get()" 
        "bar"
    )
    try "${t[@]}"

    # # shellcheck disable=SC2016
    # t2=$(object \
    #     "$(kv "cmd" 'get "5" "${list}"')" \
    #     "$(kv "msg" "indexing beyond range")" \
    #     "$(kv "exit_code" "5")" \
    # )
    
    # try "${t2}"
}
