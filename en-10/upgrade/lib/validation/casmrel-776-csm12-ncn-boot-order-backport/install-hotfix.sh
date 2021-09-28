#!/bin/bash
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

set -o errexit
set -o pipefail

WORKING_DIR=$(dirname $0)
pitinit_ver='1.2.11-1'
ilorest_ver='3.2.3-1'
# Installs RPMs, or fetches them if possible.
function install_rpms {
    zypper --no-gpg-checks \
        --plus-repo https://packages.local/repository/csm-sle-15sp2 \
        -n in -y \
        "ilorest=$ilorest_ver" \
        "pit-init=$pitinit_ver"
}

# Copies files into place.
function copy {
    if [ -f /etc/pit-release ]; then
        read -r -p "this requires passwordless-SSH; please run this on an NCN or configure the PIT with passwordless-SSH otherwise password prompts will occur. Continue? [y/n]: " response
        case "$response" in
            [yY][eE][sS]|[yY])
                :
                ;;
            *)
                echo 'exiting ...'
                exit 1
                ;;
        esac
    fi
    echo "Copying ${WORKING_DIR}/mini-install.sh and ${WORKING_DIR}/metal-lib.sh ${WORKING_DIR}/lib.sh to ..."
    for ncn in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u); do
        echo "$ncn:/srv/cray/scripts/metal/mini-install.sh"
        if ! scp ${WORKING_DIR}/scripts/mini-install.sh ${ncn}:/srv/cray/scripts/metal/ >/dev/null; then
            echo "WARNING: unable to copy files to $ncn, skipping"
            continue
        fi
        echo "$ncn:/srv/cray/scripts/metal/metal-lib.sh"
        scp ${WORKING_DIR}/scripts/metal-lib.sh ${ncn}:/srv/cray/scripts/metal/ >/dev/null
        echo "$ncn:/srv/cray/scripts/common/lib.sh"
        scp ${WORKING_DIR}/scripts/lib.sh ${ncn}:/srv/cray/scripts/common/ >/dev/null
    done

}

# Runs the scripts
function run {
    if [ -z "$IPMI_PASSWORD" ] ; then
        echo >&2 'Need IPMI_PASSWORD exported to the environment.'
    fi
    echo 'Adjusting BIOS facilitating network booting ... (/root/bin/bios-baseline.sh)'
    export CI='yes' && /root/bin/bios-baseline.sh
    unset CI
    echo 'Adjusting UEFI Boot Order ... '
    for ncn in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u); do
        echo "$ncn - starting mini-install.sh"
        ssh -o StrictHostKeyChecking=no $ncn /srv/cray/scripts/metal/mini-install.sh
        echo "$ncn - done"
    done
}

function main {
    rpm -q ilorest pit-init || install_rpms
    copy
    run
    echo 'Done'
}

main
