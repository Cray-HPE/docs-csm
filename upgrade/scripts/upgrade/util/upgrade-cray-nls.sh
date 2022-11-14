#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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

function deployNLS() {
    BUILDDIR="/tmp/build"
    mkdir -p "$BUILDDIR"
    kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > "${BUILDDIR}/customizations.yaml"
    kubectl get configmap -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}' > "${BUILDDIR}/iuf.yaml"
    manifestgen -i "${BUILDDIR}/iuf.yaml" -c "${BUILDDIR}/customizations.yaml" -o "${BUILDDIR}/platform.yaml"
    yq w -i "${BUILDDIR}/platform.yaml" 'spec.charts[0].version' "$2"
    charts="$(yq r /tmp/build/platform.yaml 'spec.charts[*].name')"
    for chart in $charts; do
        if [[ $chart != "cray-iuf" ]] && [[ $chart != "cray-nls" ]]; then 
            yq d -i /tmp/build/platform.yaml "spec.charts.(name==$chart)"
        fi
    done

    yq d -i /tmp/build/platform.yaml "spec.sources"

    loftsman ship --charts-path "$1" --manifest-path /tmp/build/platform.yaml
}

if [[ -z $1 ]]; then
    CHART_PATH="${CSM_ARTI_DIR}/helm/"
else
    CHART_PATH="$1"
fi

echo "Get NLS chart version"
tarFileName=$(ls -l "$CHART_PATH" | awk '{print $9}' | grep "cray-nls")
tarFileName=${tarFileName#"cray-nls-"}
version=${tarFileName%".tgz"}
echo "Version: $version"


deployNLS "$CHART_PATH" "$version"