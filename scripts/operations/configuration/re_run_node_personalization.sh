#!/usr/bin/bash
#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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

################################################################################
#
# The script will clear the CFS state for the selected nodes and re-run the
# configuration
#
# Usage: re_run_node_personalization.sh
#
################################################################################
locOfScript=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Inform ShellCheck about the file we are sourcing
# shellcheck source=./bash_lib/common.sh
. "${locOfScript}/bash_lib/common.sh"

set -o pipefail

DIFF_SCRIPT="${locOfScript}/json_str_list_diff.py"

get_xnames_list() {
  cray hsm state components list --role Management --type Node --format json | jq -r '[.Components[].ID]'
}

get_rpm_version() {
  rpm -q --qf "%{VERSION}" "$1"
}

xnames_list=$(get_xnames_list) \
  || err_exit "Command failed: cray hsm state components list --role Management --type Node --format json | jq -r '[.Components[].ID]'"
xnames=$(echo "$xnames_list" | jq -r 'join(",")') \
  || err_exit "Command failed: echo '$xnames_list' | jq -r 'join(\",\")'"
xnames_arr=$(echo "$xnames_list" | jq -r '.[]') \
  || err_exit "Command failed: echo '$xnames_list' | jq -r '.[]'"
craycli_version=$(get_rpm_version "craycli") \
  || err_exit "Command failed: rpm -q --qf '%{VERSION}' craycli"

echo "Cray CLI version: ${craycli_version}"
echo "Clearing CFS state for ${xnames}"

if [ "$(printf '%s\n' "$craycli_version" "0.90.0" | sort -V | head -n1)" = "$craycli_version" ]; then
  # Cray CLI RPM version < 0.90.1, so we cannot use the updatemany subcommand
  FAILED=""
  COUNT=0
  for xname in "${xnames_arr[@]}"; do
    echo "Clearing CFS state of ${xname}"
    cray cfs v3 components update --error-count 0 --state '[]' --format json "${xname}" && let COUNT+=1 || FAILED+=" ${xname}"
  done
  echo "Cleared CFS state on ${COUNT} nodes"
  [[ -z ${FAILED} ]] || err_exit "There were errors clearing the CFS state for the following nodes:${FAILED}"
  echo "No errors"
  exit 0
fi

# Cray CLI RPM version >= 0.90.1, so we can use the updatemany subcommand
output=$(cray cfs v3 components updatemany --filter-ids "${xnames}" --error-count 0 --state '[]' --format json) \
  || err_exit "Command failed: cray cfs v3 components updatemany --filter-ids '${xnames}' --error-count 0 --state '[]' --format json"

component_list=$(echo "$output" | jq -r '[.component_ids[]]') \
  || err_exit "Command failed: echo '$output' | jq -r '[.component_ids[]]'"
no_of_updated_components=$(echo "$component_list" | jq 'length') \
  || err_exit "Command failed: echo '$component_list' | jq 'length'"
echo "Cleared CFS state on ${no_of_updated_components} nodes: ${component_list}"

difference=$("${DIFF_SCRIPT}" "${xnames_list}" "${component_list}") \
  || err_exit "Command failed: '{DIFF_SCRIPT}' '${xnames_list}' '${component_list}'"

[[ -z $difference ]] || err_exit "Unable to clear CFS state for ${difference}"
echo "Cleared CFS state for all the selected nodes"
