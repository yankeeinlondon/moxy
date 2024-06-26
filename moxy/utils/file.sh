#!/usr/bin/env bash

# shellcheck source="./env.sh"
. "./utils/env.sh"
# shellcheck source="./logging.sh"
. "./utils/logging.sh"
# shellcheck source="./errors.sh"
. "./utils/errors.sh"
# shellcheck source="./conditionals.sh"
. "./utils/conditionals.sh"
# shellcheck source="./info.sh"
. "./utils/info.sh"

# split_filepath <filepath> <ref:array>
#
# Splits the filepath by the path delimiter character of the 
# underlying operating system.
function split_filepath() {
    local -r filepath="${1:?no filepath was passed to split_filepath()}"
    local -na arr=$2

    if starts_with "windows" "$(os)"; then
        arr=( split_on "\\" "$filepath" )
    else
        arr=( split_on "/" "$filepath" )
    fi
}


function remove_file_from_filepath() {
    local -r dirpath="${1:?no dirpath was passed to ensure_directory()}"
    local -a parts
    split_filepath "$dirpath" parts

    if file_exists "$dirpath"; then
        # we know terminating element is a file
        local -r file="${parts[@:-1]}"
        local -r dir=$(replace "$file" "" "$dirpath")

        if directory_exists "${dir}"; then
            debug "remove_file_from_filepath" "removed filename and replaced with just dir: ${dir}"
            printf "%s" "${dir}"
            return 0
        else 
            debug "remove_file_from_filepath" "removed filename and replaced with just dir: ${dir}; however this path doesn't appear to be a valid directory!"
            printf "%s" "${dir}"
            error "tried to strip filename of '${file}' off of '${dirpath}', leaving '${dir}' but that the OS says this is not a valid directory!"
        fi
    else
        # we know the full path is not a file
        if directory_exists "$dirpath"; then
            debug "remove_file_from_filepath" "no file existed, it was a valid directory: ${dirpath}"
            printf "%s" "$dirpath"
        else
            local -r last=$(pop parts)
            if contains ".toml" "${parts[@:-1]}"; then
                echo "NOT DONE"
            fi
        fi

    fi



}

function ensure_directory() {
    local -r dirpath="${1:?no dirpath was passed to ensure_directory()}"
    local -ra parts=( $(split_on "" "") )

    if directory_exists "${dirpath}"; then
        debug "ensure_directory" "the directory path '${dirpath}' already existed"
    else
        mkdir "${dirpath}"
        debug "ensure_directory" "the directory '${dirpath}' was created"
    fi
}


# save_config() <content>
# 
# saves the configuration file to be whatever is passed
# into <content>. 
#
# WARN: this can be destructive
function save_config() {
    local -r content="${1:?no content was passed to save_config()}"

    if has_env "MOXY_CONFIG_FILE"; then
        printf "%s" "${content}" > "${MOXY_CONFIG_FILE}"
    else
        error "Attempt to save configuration when no MOXY_CONFIG_FILE is set!"
    fi
}


# update_config() <key> <value> <allow-multi>
# 
# updates the configuration file on a line which has the "<key>="
# expression with a new key value pair unless <allow-multi> is
# set to "true" in which case it simply appends a new key/value
# pair (so long as the new key/value don't produce a duplicate).
#
# WARN: this can be destructive
function update_config() {
    local -r key="${1:?no key was passed to update_config()}"
    local -r value="${2:?no value was passed to update_config()}"
    local -r allow_multi="${3:-false}"

    if has_env "MOXY_CONFIG_FILE"; then
        if [[ "$allow_multi" == "true" ]]; then
            echo "NOT DONE"
        else
            replace_line_in_file_or_append "${MOXY_CONFIG_FILE}" "${key}" "${key}=${value}"
        fi

    else
        error "Attempt to save configuration when no MOXY_CONFIG_FILE is set!"
    fi
}

