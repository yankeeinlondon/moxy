#!/usr/bin/env bash

export ERR_UNKNOWN_CONTAINER_TYPE=5
export ERR_INVALID_DEREF_KEY=10
export ERR_UNKNOWN_COMMAND=50
export ERR_UNEXPECTED_OUTCOME=100

# when a text question is returned with an invalid response
# based on the "validator" function passed in
export ERR_INVALID_TEXT_RESPONSE=101
# when a user "cancels" an interactive question
export ERR_USER_CANCEL=102

# when testing for being a PVE node; this is the return code
# for it NOT being one
export ERR_NOT_PVE_NODE=103

export ERR_MENU_NOT_OBJECT=120
export ERR_MENU_INVALID_CHOICES=121
