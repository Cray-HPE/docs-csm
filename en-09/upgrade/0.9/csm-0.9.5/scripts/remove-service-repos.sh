#!/bin/bash

set -e

NCNS=$("$CSM_DISTDIR"/lib/list-ncns.sh | paste -sd,)

pdsh -w "$NCNS" 'zypper ms -d Basesystem_Module_15_SP2_x86_64'
pdsh -w "$NCNS" 'zypper ms -d Public_Cloud_Module_15_SP2_x86_64'
pdsh -w "$NCNS" 'zypper ms -d SUSE_Linux_Enterprise_Server_15_SP2_x86_64'
pdsh -w "$NCNS" 'zypper ms -d Server_Applications_Module_15_SP2_x86_64'
