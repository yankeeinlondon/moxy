#!/usr/bin/env bash

DELIMITER=":::"

# shellcheck disable=SC1091
source "${PWD}/utils/local/shared.sh"

# add_question <questions> <param> <value>
# 
# adds a question to an existing question hash without questioning
# the validity of the question (as that's done elsewhere)
function add_question() {
    local -a questions="${1:the dictionary of questions was not provided to add_question}"
    local -r kind="${2:the KIND for the question was not passed to add_question}"
    local -r name="${3:the NAME was not provided to add_question}"
    local -r value="${4:the default value fwas not provided to add_question}"
    local -ra env_vars=( "${@:4}" )
    local -A question=( 
        [param]="${name}" 
        [kind]="${kind}" 
        [default_value]="${value}" 
        [envs]="$(to_csv "${env_vars[@]}")"
    )

    # 1. validate value fits param and kind
    # 2. validate ENV variable is all caps, no dashes, etc.
    # 3. push question -- as a delimited string -- on the questions stack

    local question_str=""
    question_str=$(dict_to_delimited_string "${DELIMITER}" "${question[@]}" )

    # shellcheck disable=SC2190
    questions+=( "${question_str}" )
    
    echo "${questions[@]}"
    return 0
}

# add_ct_default <questions> <param> <value> <env-vars>
#
# 
function add_ct_default() {
    local -rA questions="${1:the dictionary of questions was not provided to ask_ct_default}"
    local -r parameter="${2:the parameter for the new question was not provided to ask_ct_default}"
    local -r value="${3:the default value for the new question was not provided to ask_ct_default}"
    local -ra env_vars=( "${@:4}" )

    if is_valid_parameter "${parameter}" "${value}"; then
        add_question "${questions[@]}" "${parameter}" "${value}"
        echo "${questions[@]}"
        return 0
    else
        error "The parameter \"${parameter}\" "
        return 1
    fi    

}
