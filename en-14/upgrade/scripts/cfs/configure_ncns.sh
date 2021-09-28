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
set -euo pipefail

if [ -z "$CSM_RELEASE_VERSION" ]; then
  echo "Set CSM_RELEASE_VERSION before running this script"
  exit 1
fi

COMMIT=$(kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' 2> /dev/null | yq r -j - 2> /dev/null | jq --arg version "$CSM_RELEASE_VERSION" '. [$version].configuration.commit' | tr -d '"')
echo "Found commit: $COMMIT"
echo "{
  \"layers\": [
    {
      \"cloneUrl\": \"https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git\",
      \"commit\": \"$COMMIT\",
      \"name\": \"ncn_nodes\",
      \"playbook\": \"ncn_nodes.yml\"
    }
  ]
}" | sed -e "s/COMMIT/$COMMIT/g" > /tmp/ncn_nodes.yml.json

CONFIG_NAME="ncn_nodes"
SESSION_NAME="ncnnodes"

echo "Creating CFS configuration $CONFIG_NAME"
cray cfs configurations update $CONFIG_NAME --file /tmp/ncn_nodes.yml.json
echo "Configuration created"
# Cleanup temporary file
rm /tmp/ncn_nodes.yml.json
# Launch CFS session
echo "Launching configuration session $SESSION_NAME"
cray cfs sessions create --name $SESSION_NAME --configuration-name $CONFIG_NAME
echo "Session started"
JOB_NAME=$(cray cfs sessions describe $SESSION_NAME --format json | jq -r " .status.session.job")
echo "Run \"kubectl logs -f -n services jobs/$JOB_NAME -c ansible\" to follow the session logs"
