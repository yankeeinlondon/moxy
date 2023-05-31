#!/usr/bin/env bash

# responsible for handling the interactive parts of the process, including:
# - gathering a pipeline of questions and default answers
# - validating that all default values are valid

function ask_to_continue() {
    local -r default_answer="${1:-yes}"
    local -r exit_msg="${2:-Exiting...}"
    local -r continue_msg="${1:-}"
    local prompt=""

    lc "${default_answer}" | grep -Eq "^(y|yes)"
    DEFAULT_YES=$?

    if $DEFAULT_YES; then 
        read -r -p "Continue? <Y/n> " prompt
        if echo "$prompt" | grep -Eq "^(n|no)$"; then
            log "${exit_msg}"
            return 1
        else
            log "${continue_msg}"
            log ""
        fi

    else
        read -r -p "Continue? <y/N> " prompt
        if echo "$prompt" | grep -Eq "^(y|yes)$"; then
            log "${exit_msg}"
            return 1
        else
            log "${continue_msg}"
            log ""
        fi
    fi

}

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
