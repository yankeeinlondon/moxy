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
# shellcheck source="./mutate.sh"
. "./utils/mutate.sh"

# file_exists <filepath>
#
# tests whether a given filepath exists in the filesystem
function file_exists() {
    local filepath="${1:?filepath is missing}"

    if [ -f "${filepath}" ]; then
        debug "file_exists(${filepath})" "exists"
        return 0;
    else
        debug "file_exists(${filepath})" "does not exists"
        return 1;
    fi
}

# directory_exists() <filepath>
#
# tests whether the filepath represents a valid directory
function directory_exists() {
    local dir="${1:?directory is missing}"

    if [[ -d "${dir}" ]]; then
        return 0;
    else
        return 1;
    fi    
}

# parent_directory() <filepath>
#
# splits the filepath by delimiters and then pops off the last
# one to arrive at the "parent directory"
# 
# Note: there is no gaurentee that this is a valid directory
# on the system (yet)
function parent_directory() {
    local -r filepath="${1:?no filepath was passed to split_filepath()}"
    local -ar paths=( "$(split_on "$(os_path_delimter)" "${filepath}" )" )
    pop paths VOID
    local -r subdir=$(join_with "$(os_path_delimeter)" "${paths[*]}")

    printf "%s" "${subdir}"

}

# split_filepath <filepath> <ref:array>
#
# Splits the filepath by the path delimiter character of the 
# underlying operating system.
function split_filepath() {
    local -r filepath="${1:?no filepath was passed to split_filepath()}"
    local -r delimiter=$(os_path_delimiter)
    allow_errors
    # shellcheck disable=SC2178
    local -n __array__=$2
    debug "split_filepath" "ready to split '${filepath}' with '${delimiter}'; array type '$(typeof __array__)'."

    if is_array __array__; then
        split_on "${delimiter}" "${filepath}" __array__

        debug "split_filepath" "split '${filepath}' on '$delimiter' into ${#__array__[@]} parts"
        catch_errors
    else
        debug "split_filepath" "array parameter passed in was wrong type: $(typeof __array__)"
        error "split_filepath() expects an array to passed in as $2"
    fi
}



function is_fully_qualified_path() {
    local -r path="${1:?is_fully_qualified_path() did not receive a path!}"

    if starts_with "$(os_path_delimiter)" "$path"; then
        debug "is_full_qualified_path" "the path '${path}' IS a fully qualified path"
        return 0
    else
        debug "is_full_qualified_path" "the path '${path}' IS NOT a fully qualified path"
        return 1
    fi
}

function rejoin_file_parts() {
    local -r original_path="${1:?the original filepath was passed to rejoin_file_parts()}"
    local -nr __parts__=$2

    if ! is_array __parts__; then
        error "rejoin_file_parts(original_path,parts) expects parts to be reference to a bash array but it was not!"
    fi

    local result

    if is_fully_qualified_path "$original_path"; then
        result=""
        for key in "${!__parts__[@]}"; do
            result="${result}$(os_path_delimiter)${__parts__[${key}]}"
        done
    else
        result="./${__parts__[0]}"
        for key in "${!__parts__[@]:1}"; do
            result="${result}$(os_path_delimiter)${__parts__[${key}]}"
        done
    fi

    printf "%s" "${result}"
}


# remove_file_from_filepath() <dirpath>
#
# attempts to ensure that the passed in path is a valid
# directory path (not a file path)
function remove_file_from_filepath() {
    allow_errors
    local -r dirpath="${1:?no dirpath was passed to remove_file_from_filepath()}"
    local -r delimiter=$(os_path_delimiter)
    local -a parts
    debug "remove_file_from_filepath" "about to split the initial $dirpath with '${delimiter}'"
    local -r temp="$(split_on "$delimiter" "$dirpath")"
    # shellcheck disable=SC2206
    parts=(  ${temp[@]} )
    catch_errors

    debug "remove_file_from_filepath" "split filepath into ${#parts[@]} parts"

    if file_exists "$dirpath"; then
        # we know terminating element is a file
        local file
        pop parts file
        debug "remove_file_from_filepath" "reduced original path of '${dirpath}' by extracting the file '${file}' to make the path $(rejoin_file_parts "$dirpath" parts)"
        local -r dir=$(rejoin_file_parts "$dirpath" parts)

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
            debug "remove_file_from_filepath" "no file existed and it was a valid directory: ${dirpath}"
            printf "%s" "$dirpath"
            return 0
        else
            local last
            pop parts last
            if contains ".toml" "${last}" || contains ".txt" "${last}" || contains ".pdf" "${last}" || contains ".json" "${last}"; then
                debug "remove_file_from_filepath" "removed TOML file ($last), path now $(rejoin_file_parts "$dirpath" parts)"
                local new_dir
                new_dir=$(remove "$last" "$dirpath")
                new_dir=$(strip_trailing "/" "${new_dir}")
                printf "%s" "${new_dir}"
                return 0
            else
                if [[ "${#parts}" -gt 1 ]] && directory_exists "$(parent_directory)"; then
                    printf "%s" "$(parent_directory "$dirpath")"
                    debug "remove_file_from_filepath" "the parent directory above that passed is valid so using that"
                    return 0
                else
                    error "uncertain how to effectively remove a filename to achieve a valid directory path" 1
                fi
            fi
        fi
    fi
}


# ensure_directory() <dirpath>
function ensure_directory() {
    local -r dirpath="${1}"

    if is_empty "$dirpath"; then
        error "ensure_directory(dirpath) called with no \$dirpath!"
        return 1
    fi

    # shellcheck disable=SC2207
    local -a parts=()
    split_filepath "$dirpath" parts

    if directory_exists "${dirpath}"; then
        debug "ensure_directory" "the directory path '${dirpath}' already existed"
    else
        if mkdir "${dirpath}"; then
            debug "ensure_directory" "the directory '${dirpath}' was created"
        else
            error "Failed to create directory $dirpath" 1
        fi
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
            if ! file_contains "${MOXY_CONFIG_FILE}" "${key}=${value}"; then
                if printf "%s\n" "${key}=${value}" >> "${MOXY_CONFIG_FILE}"; then 
                    return 0
                else
                    error "Problems adding '${key}' key/value to configuration file" 1
                fi
            fi
        else
            replace_line_in_file_or_append "${MOXY_CONFIG_FILE}" "${key}" "${key}=${value}"
        fi

    else
        error "Attempt to save configuration when no MOXY_CONFIG_FILE is set!"
    fi
}

function config_file_exists() {
    if file_exists "${MOXY_CONFIG_FILE}"; then
        debug "config_file_exists" "does exist"
        return 0
    else
        debug "config_file_exists" "does NOT exist"
        return 1
    fi
}


function make_config_secure() {
    if has_env "MOXY_CONFIG_FILE"; then
        if ! chmod 600 "${MOXY_CONFIG_FILE}"; then
            warn "was unable to set the configuration file's permissions; you may have only readonly access to the file"
        fi
    else
        error "call to make_config_secure() when MOXY_CONFIG_FILE env variable is not set!"
    fi
}


# config_has() <find>
function config_has() {
    local -r find="${1}"

    if is_empty "$find"; then
        panic "call to config_has(find) with no FIND variable!"
    fi

    if has_env "MOXY_CONFIG_FILE"; then
        if file_contains "$MOXY_CONFIG_FILE" "${find}"; then
            debug "config_has" "config has '${find}'"
            return 0
        else
            debug "config_has" "config does not have '${find}'"
            return 1
        fi
    else
        panic "call to config_has() without the MOXY_CONFIG_FILE environment variable being set ${MOXY_CONFIG_FILE}!"
    fi
}

function config_property() {
    local -r property="${1}"

    if is_empty "$property"; then
        panic "Call to config_property(property) did NOT supply a property name!" 1
    fi

    if starts_with "DEFAULT_" "$property"; then
        # shellcheck disable=SC2178
        local -r found=$(find_in_file "${MOXY_CONFIG_FILE}" "$property")

        # shellcheck disable=SC2128
        if is_empty "${found}"; then
            error "${property} property not found in config file: ${DIM}${MOXY_CONFIG_FILE}${RESET}" 1
        else
            printf "%s" "${found}"
        fi
    fi
}
