#!/usr/bin/env bash

function unit_test() {
    # test data
    foo=$(kv "foo" "foo")
    bar=$(kv "bar" "bar")
    baz=$(kv "baz" "baz")

    test_separator "object initialiation"

    obj=$(object)
    test_result $? "can create ${ITALIC}empty${RESET} object without error"
    EQ=$(assert_eq "${OBJECT_PREFIX}${OBJECT_SUFFIX}" "$obj")
    test_result $? "the initialized object is correct → ${EQ}"
    obj=$(object "$foo")
    test_result $? "can initialize an object with a key"
    EQ=$(assert_eq "${OBJECT_PREFIX}${foo}${OBJECT_SUFFIX}" "$obj")
    test_result $? "the initialized object is correct → ${EQ}"

    test_separator "keys and values"
    obj=$(object "$foo" "$bar" "$baz")
    declare -a k=( )
    k=( $(keys "${obj}") )
    test_result $? "calling keys(obj) returns successfully"
    EQ=$(assert_eq "${k[*]}" "foo bar baz")
    test_result $? "values from keys() are correct → ${EQ}"


    test_separator "adding keys"

    obj=$(push "test" "value" "${obj}")
    test_result $? "calling push(key,val,obj) returns without exit code"


    test_separator "detecting objects"

    obj=$(object)
    is_object "${obj}"
    test_result $? "an empty object is detected as an object by is_object"

    obj=$(object "$foo" "$bar")
    is_object "${obj}"
    test_result $? "an object with keys is detected as an object by is_object"

    test_separator


    obj=$(object "$foo" "$bar" "$baz")

    t1=$(object \
        "$(kv "cmd" 'get "${obj}" "foo"')" \
        "$(kv "msg" "indexing an object with valid key")" \
        "$(kv "exit_code" "0")" \
        "$(kv "return_eq" "foo")"
    )

    try "$t1"

}
