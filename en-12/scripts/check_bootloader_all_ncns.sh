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

workdir=/usr/share/doc/csm/scripts/

if [[ -f /etc/pit-release ]]; then
    # Exclude ncn-m001 if this is run from the PIT node.
    readarray -t EXPECTED_NCNS < <(conman -q | grep -v m001 | sort -u | awk -F - '{print $1"-"$2}')
    if [ ${#EXPECTED_NCNS[@]} = 0 ]; then
        echo >&2 "No NCNs found in 'conman -q', $0 can only be invoked after pit-init.sh has completed successfully."
        exit 1
    fi
else
    readarray -t EXPECTED_NCNS < <(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u)
    if [ ${#EXPECTED_NCNS[@]} = 0 ]; then
        echo >&2 "No NCNs found in /etc/hosts! This NCN is not initialized, /etc/hosts should have content."
        exit 1
    fi
fi

export NCNS=()
for ncn in "${EXPECTED_NCNS[@]}"; do
    if ping -c 1 $ncn >/dev/null 2>&1 ; then
        NCNS+=( "$ncn" )
    else
        echo >&2 "Failed to ping [$ncn]; skipping hotfix for [$ncn]"
    fi
done

for ncn in "${NCNS[@]}"; do
    printf "Uploading check_bootloader.sh to $ncn:/tmp/ ... "
    scp ${workdir}/check_bootloader.sh ${ncn}:/tmp/ >/dev/null
    echo "Done" 
done

# Do not run with -S, let the bootloader check report failures on every node and not exit early.
pdsh -b -w "$(printf '%s,' "${NCNS[@]}")" '
/tmp/check_bootloader.sh
'
echo "Done"
