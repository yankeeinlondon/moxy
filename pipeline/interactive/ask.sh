#!/usr/bin/env bash

# responsible for handling the interactive parts of the process, including:
# - gathering a pipeline of questions and default answers
# - validating that all default values are valid

function ask_yes_no() {
    local -rA answers="${1:the dictionary of answers was not provided to ask_yes_no}"
    local -r question="${2:the question text was not provided to ask_yes_no}"
    local default_value="${3:-yes}"

    echo "TODO"
}

function ask_select_one() {
    local -rA answers="${1:the dictionary of answers was not provided to ask_select_one}"
    local -r question="${2:the question text was not provided to ask_select_one}"
    local -r options="${3:the list of options was not provided to ask_select_one}"
    local default_value="${4}"

    echo "TODO"
}

function ask_select_many() {
    local -rA answers="${1:the dictionary of answers was not provided to ask_select_many}"
    local -r question="${2:the question text was not provided to ask_select_many}"
    local -r options="${3:the list of options was not provided to ask_select_many}"
    local default_value="${4}"

    echo "TODO"
}
