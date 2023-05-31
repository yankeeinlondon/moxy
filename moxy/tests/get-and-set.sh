#!/usr/bin/env bash


function unit_test() {
    test_separator "get() an object"
    foo=$(kv "foo" "foey")
    bar=$(kv "bar" "barred")
    obj=$(object "${foo}" "${bar}")

    r=$(get "foo" "$obj")
    test_result $? "valid index value -- foo -- results in successful return code"
    EQ=$(assert_eq "$r" "foey")
    test_result $? "value returned is correct → ${EQ}"

    
}
