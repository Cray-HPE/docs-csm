#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -o errexit
set -o pipefail
set -o xtrace

echo 'loading repair script onto each NCN..'
for ncn in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | tr -t '\n' ' '); do
    scp $(dirname $0)/tpm-fix-repair.sh $ncn:/tmp/cast-26421.sh
done
echo 'running repair script..'
pdsh -b -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | tr -t '\n' ',') '/tmp/cast-26421.sh'
