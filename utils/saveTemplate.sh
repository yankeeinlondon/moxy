#!/usr/bin/env bash

# saveTemplate <template-name> <location> <key-values>
function saveTemplate() {
    local template="${1:?No template name provided to saveTemplate}"
    local location="${2:?No file location provided to saveTemplate}"
    local keyValues="${3}"

    local content=""
    local hasKeyValues="true"

    if [[ -z "${keyValues}" ]]; then
        hasKeyValues="false"
    fi

    # load template
    template=$(ensure_trailing ".sh" "${template}")
    template_file="${PWD}/templates/${template}"
    if file_exists "${template_file}"; then
        content=$(cat "${template_file}")
    else
        MSG="Was asked to load a template from \"${template_file}\" but this file does not exist!"
        error "$MSG"
        echo 10
        return 10
    fi

    # mutate content where keyValues passed in
    if [[ "${hasKeyValues}" == "true" ]]; then
        info "key value detected"
    fi

    # save to file
    echo "${content}" > "${location}"

    return 0
}
