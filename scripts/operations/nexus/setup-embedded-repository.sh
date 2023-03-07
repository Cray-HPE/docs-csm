#!/usr/bin/env bash
# MIT License
#
# (C) Copyright [2023] Hewlett Packard Enterprise Development LP
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

set -exo pipefail

#two required inputs
#1 RELEASE_VERSION
#2 ROOTDIR of extracted CSM tarball

#RELEASE_VERSION
RELEASE_VERSION="$1"
#ROOTDIR is the root directory of the extracted CSM release tarball
ROOTDIR="$2"

if [[ -z "${RELEASE_VERSION}" ]] || [[ -z "${ROOTDIR}" ]]; then
    echo "usage: setup-embedded-repository.sh \$RELEASE_VERSION \$PATH_TO_ROOT_OF_EXTRACTED_CSM_TARBALL_CONTENT"
    exit 1
fi

BUILDDIR="$(dirname "${BASH_SOURCE[0]}")"
TEMPLATEDIR="${BUILDDIR}/repo_templates"
source "${ROOTDIR}/lib/version.sh"
source "${ROOTDIR}/lib/install.sh"

# Check for required resources for Nexus setup
nexus_resources_ready=0
counter=1
counter_max=10
sleep_time=30
url=packages.local

while [[ $nexus_resources_ready -eq 0 ]] && [[ "$counter" -le "$counter_max" ]]; do
    nexus_check_configmap=$(kubectl -n services get cm cray-dns-unbound -o json 2>&1 | jq '.binaryData."records.json.gz"' -r 2>&1 | base64 -d 2>&1| gunzip - 2>&1|jq 2>&1|grep $url|wc -l)
    nexus_check_dns=$(dig $url +short |wc -l)
    nexus_check_pod=$(kubectl get pods -n nexus| grep nexus | grep -v Completed | awk '{ print $3 }')

    if [[ "$nexus_check_dns" -eq "1" ]] && [[ "$nexus_check_pod" == "Running" ]]; then
        echo "$url is in dns."
        echo "Nexus pod $nexus_check_pod."
        echo "Moving forward with Nexus setup."
        nexus_resources_ready=1
    fi
    if [[ "$nexus_check_pod" != "Running" ]]; then
        echo "Nexus pod not ready yet."
        echo "Nexus pod status is: $nexus_check_pod."
    fi

    if [[ "$nexus_check_dns" -eq "0" ]]; then
        echo "$url is not in DNS yet."
        if [ "$nexus_check_configmap" -lt "1" ]; then
            echo "$url is not loaded into unbound configmap yet."
            echo "Waiting for DNS and nexus pod to be ready. Retry in $sleep_time seconds. Try $counter out of $counter_max."
        fi
    fi
    if [[ "$counter" -eq "$counter_max" ]]; then
        echo "Max number of checks reached, exiting."
        echo "Please check the status of nexus, cray-dns-unbound and cray-sls."
        exit 1
    fi
    ((counter++))
done

# Set podman --dns flags to unbound IP
podman_run_flags+=(--dns "$(kubectl get -n services service cray-dns-unbound-udp-nmn -o jsonpath='{.status.loadBalancer.ingress[0].ip}')")

load-install-deps

# Update repository names based on the release version
sed -e "s/-0.0.0/-${RELEASE_VERSION}/g" "${TEMPLATEDIR}/embedded-repository.yaml" \
> "${BUILDDIR}/embedded-repository.yaml"


# Setup Nexus
nexus-setup repositories "${BUILDDIR}/embedded-repository.yaml"

# Upload repository contents
nexus-upload raw "${ROOTDIR}/rpm/embedded" "csm-${RELEASE_VERSION}-embedded"

clean-install-deps

set +x
cat >&2 <<EOF
+ Nexus setup complete
setup-embedded-repository.sh: OK
EOF