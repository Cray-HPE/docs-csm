#!/bin/bash
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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

locOfScript=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Inform ShellCheck about the file we are sourcing
# shellcheck source=./bash_lib/common.sh
. "${locOfScript}/bash_lib/common.sh"

set -uo pipefail

function usage {
  echo "Usage: restore_cpc.sh cpc_dump_file.yaml" >&2
}

if [[ $# -eq 1 ]] && [[ $1 == "-h" || $1 == "--help" ]]; then
  usage
  exit 2
fi

if [[ $# -gt 1 ]]; then
  usage_err_exit "Too many arguments"
elif [[ $# -eq 0 ]]; then
  usage_err_exit "Missing required argument"
elif [[ -z $1 ]]; then
  usage_err_exit "Backup file may not be blank"
elif [[ ! $1 =~ [.][yY]([aA][mM]|[mM])[lL]$ ]]; then
  usage_err_exit "Backup file should have extension yml or yaml"
elif [[ ! -e $1 ]]; then
  usage_err_exit "Specified backup file ($1) does not exist"
elif [[ ! -f $1 ]]; then
  usage_err_exit "Specified backup file ($1) exists but is not a regular file"
fi

BACKUP="$1"

# Make a backup of the product catalog before overwriting it
echo "Backing up current product catalog before restoring backup"
run_cmd "${locOfScript}/dump_cpc.sh"

echo "Delete product catalog"
run_cmd kubectl delete cm -n services cray-product-catalog

echo "Restore exported product catalog"
run_cmd kubectl apply -n services -f "${BACKUP}"

echo "Product catalog import completed"
