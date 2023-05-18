#!/usr/bin/env bash

function unit_test() {
    object=""
    
    object=$(object)
    test_result $? "can create empty object without error" "$1" "$2"
    EQ=$(assert_eq "${OBJECT_PREFIX}${OBJECT_SUFFIX}" "$object")
    test_result $? "the initialized object format is correct → ${EQ}"

    test_separator
    foo=$(kv "foo" "foo")
    bar=$(kv "bar" "bar")
    baz=$(kv "baz" "baz")

    object=$(object "$foo" "$bar" "$baz")
    test_result $? "can initialize object with string values without error"
    EQ=$(assert_eq "${OBJECT_PREFIX}${foo}${OBJECT_DELIMITER}${bar}${OBJECT_DELIMITER}${baz}${OBJECT_SUFFIX}" "$object")
    test_result $? "the initialized object is correct → ${EQ}"
}
