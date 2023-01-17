#!/bin/bash
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

set -eu

function deploySpire() {
    BUILDDIR="/tmp/build"
    mkdir -p "$BUILDDIR"
    kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > "${BUILDDIR}/customizations.yaml"
    manifestgen -i "${CSM_ARTI_DIR}/manifests/sysmgmt.yaml" -c "${BUILDDIR}/customizations.yaml" -o "${BUILDDIR}/spireupgrade.yaml"
    charts="$(yq r $BUILDDIR/spireupgrade.yaml 'spec.charts[*].name')"
    for chart in $charts; do
        if [[ $chart != "spire" ]]; then 
            yq d -i $BUILDDIR/spireupgrade.yaml "spec.charts.(name==$chart)"
        fi
    done

    yq w -i $BUILDDIR/spireupgrade.yaml "metadata.name" "spireupgrade"
    yq d -i $BUILDDIR/spireupgrade.yaml "spec.sources"

    loftsman ship --charts-path "${CSM_ARTI_DIR}/helm/" --manifest-path $BUILDDIR/spireupgrade.yaml
}

deploySpire
