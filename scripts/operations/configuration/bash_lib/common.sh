#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

# Common functions

# Returns 0 if argument is a defined Bash function, 1 otherwise
is_function()
{
    [[ $(LC_ALL=C type -t "$1") == function ]] && return 0 || return 1
}

# Print an error message to stderr
err()
{
    echo "ERROR: $*" >&2
}

# Print a provided error message to stderr and exit the script with return code 1
err_exit()
{
    err "$@"
    exit 1
}

# Call script usage function (if defined), then exit in error with the provided message
usage_err_exit()
{
    # If a usage function is defined, call it to print the usage message first
    if is_function usage; then
        usage
    fi
    err_exit "usage: $*"
}

# Calls mktemp to create a file or directory. If unsuccessful, the script exits in error.
# Otherwise, some checks are made on what was created. If they pass, the path to the file or directory
# is printed to stdout
run_mktemp()
{
    local tmpfile
    tmpfile=$(mktemp "$@") || err_exit "Command failed with rc $?: mktemp $*"
    [[ -n ${tmpfile} ]] || err_exit "mktemp command passed but gave no output"
    [[ -e ${tmpfile} ]] || err_exit "mktemp command passed but '${tmpfile}' does not exist"
    if [[ $# -gt 0 && "$1" == "-d" ]]; then
        [[ -d ${tmpfile} ]] || err_exit "mktemp -d command passed and '${tmpfile}' exists, but is not a directory"
    else
        [[ -f ${tmpfile} ]] || err_exit "mktemp command passed and '${tmpfile}' exists, but is not a regular file"
    fi
    echo "${tmpfile}"
    return 0
}

run_cmd()
{
    "$@" || err_exit "Command failed with rc $?: $*"
}
