#!/usr/bin/env bash


function unit_test() {
    list=$(list)
    test_result $? "can create empty list without error" "$1" "$2"
    EQ=$(assert_eq "${LIST_PREFIX}${LIST_SUFFIX}" "$list")
    test_result $? "the initialized list format is correct → ${EQ}"

    list=$(list "foo" "bar" "baz")
    test_result $? "can initialize list with string values without error"
    EQ=$(assert_eq "list::[ foo${LIST_DELIMITER}bar${LIST_DELIMITER}baz ]" "$list")
    test_result $? "the initialized list is correct → ${EQ}"

    test_separator

    arr=( $(as_array "${list[@]}") )
    test_result $? "as_array(list) call returns successfully"
    EQ=$(assert_eq "${#arr[@]}" "3" )
    test_result $? "the array has correct length [${EQ}]"
    contains "foo" "${arr[@]}"
    test_result $? "array contains value \"foo\""

    test_separator

    # shellcheck disable=SC2016
    t=(
        'get "${list[@]}" "1"'
        "can index a list with get()" 
        "bar"
    )
    try "${t[@]}"

    # shellcheck disable=SC2016
    t=(
        'get "${list[@]}" "5"'
        "indexing beyond range" 
        
    )
    try "${t[@]}"
    
}
