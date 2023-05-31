#!/usr/bin/env bash


function unit_test() {
    test_separator "is_array()"

    declare -a arr=(one two)
    declare not_arr="one two"


    # shellcheck disable=SC2016
    t1=$(object \
        "$(kv "cmd" 'is_array "${arr[@]}"')" \
        "$(kv "msg" "using valid array passed with @")" \
        "$(kv "exit_code" "0")" \
    )
    
    try "${t1}"
}
