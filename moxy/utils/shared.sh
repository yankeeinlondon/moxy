#!/usr/bin/env bash

# LOADS ALL SHARED FUNCTIONS FOR MOXY
# WHICH ARE KEPT IN OTHER FILES SIMPLY
# FOR ORGANIZATIONAL PURPOSES


# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./env.sh"
. "./utils/env.sh"
# shellcheck source="./errors.sh"
. "./utils/errors.sh"
# shellcheck source="./help.sh"
. "./utils/help.sh"

# shellcheck source="./ready.sh"
# . "./utils/ready.sh"
# shellcheck source="./conditionals.sh"
. "./utils/conditionals.sh"
# shellcheck source="./mutate.sh"
. "./utils/mutate.sh"
# shellcheck source="./info.sh"
. "./utils/info.sh"
# shellcheck source="./interactive/ask.sh"
. "./utils/interactive/ask.sh"
# shellcheck source="./interactive/questions.sh"
. "./utils/interactive/questions.sh"

# shellcheck source="./proxmox.sh"
. "./utils/proxmox.sh"

# shellcheck source="./fetch.sh"
. "./utils/fetch.sh"
# shellcheck source="./status.sh"
. "./utils/status.sh"



# destructer <arr>
#
# syntax:
#   destructer a,b,c = ${my_arr}
#   destructer a, b, c = ${my_arr}
#
# destructering assignment for arrays
function destructer() {
    # all but last two params constitute the variable names
    local -ra initial_inputs=( "${@:1:$#-2}" )
    local -a variable_names=()
    # the input array is the last parameter in $@
    local -ra input_arr=( "${@:-1}" )

    # first, we need to finalize the variable names
    for i in "${initial_inputs[@]}"; do
        if [[ "$i" =~ "," ]]; then
            local -a vars=()
            # shellcheck disable=SC2207
            vars=( $(split "," "$i") )
            variable_names+=( "${vars[@]}" )
        else
            variable_names+=("$i")
        fi
    done

    # now we can 
    idx=0

    for name in "${variable_names[@]}"; do
        local var_value=""
        declare -g "${name}=${var_value}"
    done

    # for ((i=0; i < ${#variable_names[@]}; i++)) do 
    #     local value_name="${!#}[$i]"
    #     declare -g """${var_names[$i]}""=${!value_name}"
    # done
}

_iterator() {
    local payload="${1:?no payload received by _iterator()}"
    # shellcheck disable=SC2317
    function api_surface() {
        local -r cmd="${1:?no command provided to a call of the iterator\'s api }"

        case $cmd in


            "value")
                echo "$payload"
                return 0
                ;;

            "next") echo "TODO";;

            "take") echo "TODO";;

            *)
                error "Unknown command sent to iterable API: ${DIM}${cmd}${RESET}" "$ERR_UNKNOWN_COMMAND"
                ;;
        esac
    }

}


# as_iterable <object|list|array> → <iterable>
function as_iterator() {
    local maybe_iterable="${1:?iterator fn did not receive any parameters}"
    local -xf api

    if is_list "${maybe_iterable}"; then
        debug "iterator" "payload detected as a list"
        
        # shellcheck disable=SC2317
        function api_surface() {
            local -r cmd="${1:?no command provided to a call of the iterator\'s api }"

            case $cmd in

                "value")
                    echo "TODO"
                    ;;

                "next") echo "TODO";;

                "take") echo "TODO";;

                *)
                    error "Unknown command sent to iterable API: ${DIM}${cmd}${RESET}" "$ERR_UNKNOWN_COMMAND"
                    ;;
            esac
        }
        api=api_surface
        echo "${api}"
        return 0
    fi

    if is_kv_pair "${maybe_iterable}"; then
        debug "iterator" "payload detected as KV pair"
        local -ra payload=( "$(as_array "$maybe_iterable")" )
        # shellcheck disable=SC2317
        function api_surface {
            local -r cmd="${1:?no command provided to a call of the iterator\'s api }"
            local 

            case $cmd in 


                *)
                    error "Unknown command sent to iterable API: ${DIM}${cmd}${RESET}" "$ERR_UNKNOWN_COMMAND"
                    ;;
            esac
        }


    fi

    error "Unexpected outcome from calling iterator() fn" "$ERR_UNEXPECTED_OUTCOME"
}

