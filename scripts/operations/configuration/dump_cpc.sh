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
  echo "Usage: dump_cpc.sh [output_directory]" >&2
  echo
  echo "If no output directory is specified, it defaults to the user's home directory" >&2
}

OUTDIR=""

if [[ $# -eq 1 ]] && [[ $1 == "-h" || $1 == "--help" ]]; then
  usage
  exit 2
fi

if [[ $# -gt 1 ]]; then
  usage_err_exit "Too many arguments"
elif [[ $# -eq 0 ]]; then
  OUTDIR=~
elif [[ -z $1 ]]; then
  usage_err_exit "Output directory argument may not be blank"
elif [[ ! -e $1 ]]; then
  usage_err_exit "Specified output directory ($1) does not exist"
elif [[ ! -d $1 ]]; then
  usage_err_exit "Specified output directory ($1) exists but is not a directory"
else
  OUTDIR="$1"
fi

OUTFILE=$(run_mktemp "${OUTDIR}/cray-product-catalog-$(date +%Y%m%d%H%M%S)-XXXXXX.yaml") || err_exit
echo "Dumping Cray Product Catalog to '${OUTFILE}'"

run_cmd kubectl get cm -n services cray-product-catalog -o yaml > "${OUTFILE}" || err_exit "Error writing to '${OUTFILE}'"

echo "Cray Product Catalog dumped to '${OUTFILE}'"
