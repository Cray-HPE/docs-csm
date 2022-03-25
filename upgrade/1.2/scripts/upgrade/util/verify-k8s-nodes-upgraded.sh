#!/bin/sh
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

EXPECTED_VERSION="v1.20.13"
display_output=$(kubectl get nodes)
versions=$(kubectl get nodes -o json | jq -r '.items[].status.nodeInfo.kubeletVersion')
stringarray=($versions)
for version in "${stringarray[@]}"; do
  if [ "$version" != "$EXPECTED_VERSION" ]; then
    echo "FAILURE: Not all NCNs have been updated to ${EXPECTED_VERSION}!"
    echo "         Return to the previous step to ensure all NCNs have been upgraded"
    echo "         before proceeding."
    echo ""
    echo "Node versions:"
    echo ""
    echo "$display_output"
    exit 1
  fi
done

echo "SUCCESS: All NCNs have been updated to ${EXPECTED_VERSION}:"
echo ""
echo "$display_output"
exit 0
