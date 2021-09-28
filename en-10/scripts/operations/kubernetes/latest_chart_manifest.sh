#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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

# Usage: latest_chart_manifest.sh <chart_name>
#
# Given the name of a CSM service chart, looks up the most recent successful Loftsman deployment
# of that chart, and prints the contents of the corresponding chart stanza from that manifest's/-ship-log$//
# 'spec.charts' list

set -e
set -o pipefail

workdir=$(mktemp -d)

function cleanup {
  if [[ -d ${workdir} ]]; then
    rm "${workdir}"/* > /dev/null 2>&1
    rmdir "${workdir}" > /dev/null 2>&1
  fi
}

function err_exit {
  echo "ERROR: $*" >&2
  cleanup
  exit 1
}

function get_deployed_manifest_config_maps {
  # Looks up all loftsman manifest CMs that have associated -ship-log configmaps showing that they deployed successfully.
  # Creates an array of their names, sorted from most recently deployed to least recently deployed.
  # Stores result in array named manifest_cms_sorted

  # Find all loftsman CMs with label app.kubernetes.io/managed-by=loftsman, excluding those with name suffix -ship-log.
  # Convert the list to a regular expression of the form 'name1|name2|name3|..."namen'
  local manifest_cms_regex manifest_cms_chrono cm
  manifest_cms_regex=$(
    kubectl get cm -n loftsman -l app.kubernetes.io/managed-by=loftsman -o custom-columns=':.metadata.name' --no-headers \
      | grep -v "[-]ship-log$" | tr '\n' '|' | sed 's/|$//'
  )

  # Create array of corresponding manifest -ship-log CM names in chronological order, from most recent to least recent, then strip off the -ship-log suffixes.
  readarray -t manifest_cms_chrono < <(
    kubectl get cm -n loftsman -l app.kubernetes.io/managed-by=loftsman --sort-by='.metadata.creationTimestamp' \
      -o custom-columns=':.metadata.name' --no-headers \
      | grep -E "^(${manifest_cms_regex})-ship-log$" | tac | sed 's/-ship-log$//'
  )

  manifest_cms_sorted=()
  for cm in "${manifest_cms_chrono[@]}"; do
    # Did it deploy successfully?
    kubectl get cm -n loftsman "${cm}-ship-log" -o jsonpath='{.data.loftsman\.log}' \
      | jq -r 'select(.message?) | select(.message | startswith("Ship status: success")) | .message' \
      | grep -q "^Ship status: success" || continue
    manifest_cms_sorted+=("${cm}")
  done
}

[[ $# -eq 1 ]] || err_exit "Chart name must be specified"

chart="$1"

# Validate chart name
[[ -n ${chart} ]] || err_exit "Chart name may not be blank"
[[ ! ${chart} =~ ^[^a-z0-9] ]] || err_exit "Invalid starting character in chart name: '${chart}'"
[[ ! ${chart} =~ [^a-z0-9]$ ]] || err_exit "Invalid final character in chart name: '${chart}'"
[[ ! ${chart} =~ [^-a-z0-9] ]] || err_exit "Invalid characters in chart name: '${chart}'"

get_deployed_manifest_config_maps

# If no deployed manifests were found, then there is nothing to do
[[ ${#manifest_cms_sorted[@]} -ne 0 ]] || err_exit "No successfully deployed manifests found for chart '${chart}'"

for cm in "${manifest_cms_sorted[@]}"; do
  chart_file="${workdir}/${chart}.yaml"
  if ! kubectl get cm -n loftsman ${cm} -o jsonpath='{.data.manifest\.yaml}' | yq r -j - | jq -r ".spec?.charts?[] | select(.name? == \"${chart}\")" 2> /dev/null | yq r -P - > "${chart_file}" 2> /dev/null; then
    # This chart was not found
    [[ -e ${chart_file} ]] && rm "${chart_file}"
    continue
  elif [[ ! -s ${chart_file} ]]; then
    # This also means the chart was not found
    [[ -e ${chart_file} ]] && rm "${chart_file}"
    continue
  fi
  echo "Displaying chart manifest for '${chart}' from ${cm}"
  cat "${chart_file}"
  cleanup
  exit 0
done

err_exit "No successfully deployed manifests found for chart '${chart}'"
