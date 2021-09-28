#!/bin/bash
#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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

echo "INFO Running k8s upgrade script"
. /etc/cray/upgrade/csm/myenv

set -u

DONE_DIR="/etc/cray/upgrade/csm/${CSM_REL_NAME}"

if [[ -f "$DONE_DIR/upgrade_k8s_1_29.done" ]]; then
  echo "INFO kubernetes upgrade to v1.29 already completed, skipping."
else
  echo "INFO Starting the kubernetes upgrade to v1.29"
  /usr/share/doc/csm/upgrade/scripts/k8s/upgrade_k8s.sh -v "1.27.16 1.28.15 1.29.15"
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to upgrade kubernetes to v1.29"
    exit 1
  fi
  touch "$DONE_DIR/upgrade_k8s_1_29.done"
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to create done file for v1.29 upgrade"
    exit 1
  fi
  echo "INFO Successfully upgraded kubernetes to v1.29"
fi

if [[ -f "$DONE_DIR/deploy_charts_post_k8s_upgrade.done" ]]; then
  echo "INFO deploy manifests for v1.29 already completed, skipping."
else
  echo "INFO Deploying manifests for v1.29"
  /usr/share/doc/csm/upgrade/scripts/k8s/deploy_charts_post_k8s_upgrade.sh
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to deploy manifests for v1.29"
    exit 1
  fi
  touch "$DONE_DIR/deploy_charts_post_k8s_upgrade.done"
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to create done file for v1.29 charts deployment"
    exit 1
  fi
  echo "INFO Successfully deployed manifests for v1.29"
fi

if [[ -f "$DONE_DIR/upgrade_k8s_1_32.done" ]]; then
  echo "INFO kubernetes upgrade to v1.32 already completed, skipping."
else
  echo "INFO Starting the kubernetes upgrade to v1.32"
  /usr/share/doc/csm/upgrade/scripts/k8s/upgrade_k8s.sh -v "1.30.12 1.31.8 1.32.5"
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to upgrade kubernetes to v1.32"
    exit 1
  fi
  touch "$DONE_DIR/upgrade_k8s_1_32.done"
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to create done file for v1.32 upgrade"
  fi
  echo "INFO Successfully upgraded kubernetes to v1.32"
fi

if [[ -f "$DONE_DIR/cleanup_bss.done" ]]; then
  echo "INFO BSS cleanup already completed, skipping."
else
  echo "INFO Remove upgrade and upgrade_version file creation from BSS for masters and workers."
  /usr/share/doc/csm/upgrade/scripts/upgrade/cleanup.sh
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to update BSS to remove upgrade and upgrade_version."
    exit 1
  fi
  touch "$DONE_DIR/cleanup_bss.done"
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to create done file for BSS cleanup"
    exit 1
  fi
  echo "INFO Successfully updated BSS to remove upgrade and upgrade_version."
fi

echo "INFO Deploying manifests for v1.32"

if [[ -f "$DONE_DIR/deploy_manifests.done" ]]; then
  echo "INFO Manifests deployment already completed, skipping."
else
  pushd "${CSM_ARTI_DIR}" || {
    echo "ERROR Failed to change directory to ${CSM_ARTI_DIR}"
    exit 1
  }
  ./upgrade.sh
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to deploy manifests for v1.32"
    exit 1
  fi
  echo "INFO Successfully deployed manifests for v1.32"
  touch "$DONE_DIR/deploy_manifests.done"
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to create done file for v1.32 manifests deployment"
    exit 1
  fi
fi

if [[ -f "$DONE_DIR/remove_psp.done" ]]; then
  echo "INFO Remove unneeded PSP resources already completed, skipping."
else
  echo "INFO Remove unneeded PSP resources."
  /usr/share/doc/csm/upgrade/scripts/k8s/remove_psp.sh
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to remove unneeded PSP resources."
    exit 1
  fi
  touch "$DONE_DIR/remove_psp.done"
  if [[ $? -ne 0 ]]; then
    echo "ERROR Failed to create done file for remove PSP resources"
    exit 1
  fi
  echo "INFO Successfully removed unneeded PSP resources."
fi

if [[ -f "$DONE_DIR/rr_cs_rollout_restart.done" ]]; then
  echo "INFO Rack Resiliency Critical services rollout restart already completed, skipping."
else
  # For each CS in static ConfigMap, perform rollout restart of the critical service
  python3 /usr/share/doc/csm/upgrade/scripts/k8s/rr_critical_service_restart.py || {
    echo "ERROR Critical Services rollout restart failed."
    exit 1
  }
  echo "INFO Critical Services rollout restart successfully completed, if it was necessary"
  touch "$DONE_DIR/rr_cs_rollout_restart.done" || {
    echo "ERROR Failed to create done file for Rack Resiliency critical services rollout restart"
    exit 1
  }
fi

# If all steps succeeded, remove all .done files
rm -f "$DONE_DIR"/*.done
