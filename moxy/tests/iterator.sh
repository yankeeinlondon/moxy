#!/usr/bin/env bash

# function inner {
#     echo "This is from an embedded function: $1"
# }

# function outer {
#     echo "This is the first line."
#     $1 "$2"
#     echo "This is the third line."
# }

# inline=$(outer inner 1 2)    
# partial=$(inner 1 2)
# complete=$(outer "$partial")

# printf "%s\n\n%s\n\n" "inline:" "$inline"
# printf "%s\n\n%s\n\n" "partial:" "$partial"
# printf "%s\n\n%s\n\n" "complete:" "$complete"

function unit_test() {
    test_separator "kv as iterator"
    echo "TODO"
    test_separator "list as iterator"
    echo "TODO"

    test_separator "array as iterator"
    echo "TODO"

    test_separator "object as iterator"
    echo "TODO"
}
