#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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
upgrade_ntp_timezone_metadata() {
  local ntp_query
  local ntp_payload
  local timezone_query
  local timezone_payload
  local upgrade_file
  # jq -r '.["b8:59:9f:fe:49:f1"]["user-data"]["ntp"]' ntp.json
  for k in $(jq -r 'to_entries[] | "\(.key)"' data.json)
  do
    # if it is not the global key, it is one of the host records we need to manipulate
    if ! [[ "$k" == "Global" ]]; then
      # shellcheck disable=SC2089
      ntp_query=".[\"$k\"][\"user-data\"][\"ntp\"]"
      # shellcheck disable=SC2090
      ntp_payload="$(jq $ntp_query data.json)"

      # shellcheck disable=SC2089
      timezone_query=".[\"$k\"][\"user-data\"][\"timezone\"]"
      # shellcheck disable=SC2090
      timezone_payload="$(jq $timezone_query data.json)"

      # save the payload to a unique file
      upgrade_file="upgrade-metadata-${k//:}.json"
      cat <<EOF>"$upgrade_file"
{
  "user-data": {
    "ntp": $ntp_payload,
    "timezone": $timezone_payload
  }
}
EOF
    fi
  done
}

upgrade_ntp_timezone_metadata
