#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2021-2026 Hewlett Packard Enterprise Development LP
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

"""
This script is introduced to fix CAST-39537 and is to be used only if Rack Resiliency (RR) is enabled.
It performs four main functions:
  1. Waits for any ongoing Ceph orchestrator operations to complete before syncing the updated
     monitor configuration to other nodes and kubernetes cluster.
  2. Updates the monitors list in all Ceph CSI ConfigMaps across relevant namespaces using the
     current Ceph monitor map.
  3. Copies the updated /etc/ceph/ceph.conf file from the storage node to all Kubernetes master nodes.
  4. Updates the customizations.yaml file and loftsman-cray-sysmgmt-health ConfigMap with the new
     monitor information.

Note: This script should be executed only after the first storage node rollout on the first Ceph
      node (ncn-s001) where kubernetes access is available.
"""


import base64
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

import yaml


# Assume logger is defined elsewhere or add a basic one
import logging
logger = logging.getLogger(__name__)
if not logger.hasHandlers():
    logging.basicConfig(level=logging.INFO)


def run_command(command: str) -> str:
    """
    Helper function to run a shell command.
    Args:
        command (str): The shell command to run.
    Returns:
        str: The output of the command.
    """
    logger.info(f"Running command: {command}")
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        raise ValueError(f"Command {command} errored out with : {e.stderr}") from e
    return result.stdout


def run_cmd(cmd, check=True, capture_output=True, text=True):
    """Run a shell command and return the CompletedProcess result."""
    result = subprocess.run(cmd, shell=True, check=check, capture_output=capture_output, text=text)
    return result


def wait_for_ceph_orch(timeout=600, interval=15):
    """
    Wait for Ceph orchestrator operations to complete.
    Checks that all daemons are running, MONs are in quorum,
    and cluster health does not report monitor-related issues.
    """
    elapsed = 0
    logger.info("Waiting for ceph orchestrator operations to complete...")

    while True:
        # Check for any non-running ceph daemons
        try:
            orch_ps = run_command("ceph orch ps")
        except Exception:
            orch_ps = ""
        if re.search(r"starting|stopped|error|unknown", orch_ps):
            logger.info("Daemons still transitioning...")

        # Ensure all MONs are in quorum
        quorum_status = run_command("ceph quorum_status --format json")
        if not re.search(r'"quorum_names"', quorum_status):
            logger.info("Waiting for MON quorum...")

        # Ensure cluster is not reporting monitor-related health issues
        try:
            ceph_health = run_command("ceph health")
        except Exception:
            ceph_health = ""
        if re.search(r"MON_DOWN|MON_LEFT_QUORUM|MON_JOINED_QUORUM", ceph_health):
            logger.info("Waiting for monitor health to stabilize...")

        elif not (re.search(r"starting|stopped|error|unknown", orch_ps)
                  or not re.search(r'"quorum_names"', quorum_status)
                  or re.search(r"MON_DOWN|MON_LEFT_QUORUM|MON_JOINED_QUORUM", ceph_health)):
            logger.info("Ceph orchestrator operations completed successfully.")
            return True

        time.sleep(interval)
        elapsed += interval

        if elapsed >= timeout:
            logger.info("Timed out waiting for ceph orchestrator to finish.")
            return False


def get_new_monitors():
    """Get the current list of Ceph monitor addresses from the monitor map."""
    result = run_command("ceph mon dump -f json")
    mon_dump = json.loads(result)
    return [mon["public_addr"].split("/")[0] for mon in mon_dump["mons"]]


def update_ceph_csi_configmaps():
    """
    Update the monitors list in all Ceph CSI ConfigMaps across relevant
    namespaces using the current Ceph monitor map.
    """
    new_monitors = get_new_monitors()

    # Namespaces ceph-rbd, ceph-cephfs, default, services contain ceph-csi-config configmap
    for ns in ["ceph-rbd", "ceph-cephfs", "default", "services"]:
        try:
            run_command(f"kubectl -n {ns} get cm ceph-csi-config")
        except Exception:
            print(f"Skipping {ns} (ceph-csi-config not found)")
            continue
        print(f"Updating ceph-csi-config in namespace {ns}")
        result = run_command(f"kubectl -n {ns} get cm ceph-csi-config -o json")
        cm = json.loads(result)

        config = json.loads(cm.get("data", {}).get("config.json", "[]"))
        for entry in config:
            entry["monitors"] = new_monitors
        cm["data"]["config.json"] = json.dumps(config)

        subprocess.run(
            ["kubectl", "apply", "-f", "-"],
            input=json.dumps(cm),
            check=True,
            capture_output=True,
            text=True,
        )

    # Handle ceph-etc configmap in backups namespace separately
    try:
        run_command("kubectl -n backups get cm ceph-etc")
    except Exception:
        print("Skipping backups (ceph-etc not found)")
        return
    print("Updating ceph-etc in namespace backups")
    result = run_command("kubectl -n backups get cm ceph-etc -o json")
    cm = json.loads(result)

    config = json.loads(cm.get("data", {}).get("config.json", "[]"))
    for entry in config:
        entry["monitors"] = new_monitors
    cm["data"]["config.json"] = json.dumps(config)

    subprocess.run(
        ["kubectl", "apply", "-f", "-"],
        input=json.dumps(cm),
        check=True,
        capture_output=True,
        text=True,
    )


def update_customizations():
    """
    Update the Ceph monitor addresses in the loftsman site-init secret
    (customizations.yaml) and the loftsman-cray-sysmgmt-health ConfigMap
    (cephExporter.endpoints).
    """
    new_mons = get_new_monitors()
    tmpdir = tempfile.mkdtemp(dir=os.path.expanduser("~"))

    try:
        logger.info("Extracting customizations.yaml from secret...")

        result = run_command(
            "kubectl get secret -n loftsman site-init -o jsonpath='{.data.customizations\\.yaml}'"
        )
        customizations_b64 = result.strip().strip("'")
        customizations_raw = base64.b64decode(customizations_b64).decode("utf-8")

        customizations_path = os.path.join(tmpdir, "customizations.yaml")
        with open(customizations_path, "w") as f:
            f.write(customizations_raw)

        print("Updating monitor list...")

        with open(customizations_path, "r") as f:
            customizations = yaml.safe_load(f)

        # Update nmn_ncn_storage_mons
        customizations.setdefault("spec", {}).setdefault("network", {}).setdefault(
            "netstaticips", {}
        )["nmn_ncn_storage_mons"] = new_mons

        with open(customizations_path, "w") as f:
            yaml.dump(customizations, f, default_flow_style=False)

        print("Recreating secret...")

        run_command("kubectl delete secret -n loftsman site-init --ignore-not-found")
        run_command(
            f"kubectl create secret -n loftsman generic site-init "
            f"--from-file={customizations_path}"
        )

        print("customizations secret updated successfully")
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

    print("Updating cephExporter endpoints in loftsman-cray-sysmgmt-health...")

    result = run_command(
        "kubectl get cm -n loftsman loftsman-cray-sysmgmt-health "
        "-o jsonpath='{.data.manifest\\.yaml}'"
    )
    manifest_raw = result.strip().strip("'")
    manifest = yaml.safe_load(manifest_raw)

    # Update cephExporter.endpoints in all charts
    for chart in manifest.get("spec", {}).get("charts", []):
        chart.setdefault("values", {}).setdefault("cephExporter", {})[
            "endpoints"
        ] = new_mons

    updated_manifest = yaml.dump(manifest, default_flow_style=False)

    patch_payload = json.dumps({"data": {"manifest.yaml": updated_manifest}})
    subprocess.run(
        [
            "kubectl", "patch", "cm", "-n", "loftsman",
            "loftsman-cray-sysmgmt-health",
            "--type", "merge",
            "-p", patch_payload,
        ],
        check=True,
        capture_output=True,
        text=True,
    )

    print("loftsman-cray-sysmgmt-health ConfigMap updated successfully")


def copy_ceph_conf_to_masters():
    """
    Copy the updated /etc/ceph/ceph.conf file to all Kubernetes master/control-plane
    nodes to ensure they have the latest Ceph configuration.
    """
    result = run_command(
        "kubectl get nodes --selector='node-role.kubernetes.io/control-plane' "
        "-o jsonpath='{.items[*].metadata.name}'"
    )
    masters = result.strip().strip("'").split()

    for master in masters:
        print(f"Copying ceph.conf to {master}...")
        run_command(
            f"scp -o StrictHostKeyChecking=no /etc/ceph/ceph.conf {master}:/etc/ceph/ceph.conf"
        )


def main():
    if not wait_for_ceph_orch():
        print("Ceph did not stabilize. Exiting.")
        sys.exit(1)

    update_ceph_csi_configmaps()
    update_customizations()
    copy_ceph_conf_to_masters()


if __name__ == "__main__":
    main()
