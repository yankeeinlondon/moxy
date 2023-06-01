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

declare -f object;
declare foo;
declare bar;
declare obj;
declare value;

# Test Data
foo=$(kv "foo" "foey")
bar=$(kv "bar" "barred")
obj=$(object "${foo}" "${bar}")
lst=$(list "$foo" "$bar")

function unit_test() {
    test_separator "kv as iterator"

    value=$(assert_success "kv pair passed to iterator returns successfully" as_iterator "${foo}")

    test_separator "list as iterator"
    echo "TODO"

    test_separator "array as iterator"
    echo "TODO"

    test_separator "object as iterator"
    echo "TODO"
}
