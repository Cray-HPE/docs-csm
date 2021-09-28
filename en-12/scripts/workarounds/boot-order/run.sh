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
# Origin of workaround: https://jira-pro.its.hpecorp.net:8443/browse/MTL-1872

set -euo pipefail

workdir=$(dirname $0)

if [[ $(hostname) == *-pit ]]; then
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
        echo >&2 "Failed to ping [$ncn]; skipping workaround for [$ncn]"
    fi
done

for ncn in "${NCNS[@]}"; do
    printf "Uploading new metal-lib.sh to $ncn:/srv/cray/scripts/metal/ ... "
    scp ${workdir}/metal-lib.sh ${ncn}:/srv/cray/scripts/metal/metal-lib.sh >/dev/null
    printf "Uploading lib.sh to $ncn:/srv/cray/scripts/common/ ... "
    scp ${workdir}/lib.sh ${ncn}:/srv/cray/scripts/common/lib.sh >/dev/null
    echo "Done" 
done

printf "Refreshing the bootorder on [${#NCNS[@]}] NCNs ... "
if ! pdsh -S -b -w "$(printf '%s,' "${NCNS[@]}")" '
. /srv/cray/scripts/metal/metal-lib.sh
install_grub2 > /var/log/metal-boot-order-workarounds.log 2>/var/log/metal-boot-order-workarounds.error.log
'; then
    # This failure is not important.
    :
fi

if ! pdsh -S -b -w "$(printf '%s,' "${NCNS[@]}")" '
. /srv/cray/scripts/metal/metal-lib.sh
setup_uefi_bootorder >> /var/log/metal-boot-order-workarounds.log 2>>/var/log/metal-boot-order-workarounds.error.log
'; then
    echo >&2 'Failed to fix boot order on one or more nodes. Check /var/log/metal-boot-order-workarounds*.log on each node for more information.'
    exit 1
fi
echo "Done"

echo "The following NCNs contain the boot-order patch:"
printf "\t%s\n" "${NCNS[@]}"
echo "This workaround has completed."

