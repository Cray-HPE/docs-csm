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
xnames_list=$(cray hsm state components list --role Management --type Node --format json | jq -r '[.Components[].ID]') \
  || err_exit "Command failed: cray hsm state components list --role Management --type Node --format json | jq -r '[.Components[].ID]'"
# comma-separated list of xnames to be passed to the updatemany command
xnames=$(echo "$xnames_list" | jq -r 'join(",")') \
  || errr_exit "Command failed: echo '$xnames_list' | jq -r 'join(\",\")'"
echo "Clearing CFS state for ${xnames}"
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
