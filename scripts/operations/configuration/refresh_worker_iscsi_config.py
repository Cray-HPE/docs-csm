#!/usr/bin/env python3
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

"""
Usage: refresh_worker_iscsi_config.py

This script modifies the CFS component status of worker NCNs to clear out
the iSCSI playbook entry. It also sets the error count for the component to 0.

This will cause CFS batcher to schedule new CFS sessions to run that playbook
on the workers. This is needed because changes to the iSCSI HSM group do not
take effect until the playbook is re-run.

The script will abort without doing any of the above if any of the CFS components
for the NCN workers has a configuration status of pending. This indicates that
a CFS session is currently underway for that component, or may be starting
imminently.
"""

import argparse
from functools import partial
import sys

from python_lib.cfs import list_components, update_components_by_list
from python_lib.common import ScriptException, print_err
from python_lib.hsm import get_management_ncn_xnames
from python_lib.types import JsonDict


ISCSI_PLAYBOOK = "config_sbps_iscsi_targets.yml"

get_worker_ncn_xnames = partial(get_management_ncn_xnames, subrole="Worker")

def cfs_comp_has_no_iscsi_status(comp: JsonDict) -> bool:
    """
    Returns False if the iscsi playbook is listed in any of the state layers
    Returns True otherwise
    """
    return all(layer["playbook"] != ISCSI_PLAYBOOK for layer in comp.get("state", []))


def main() -> None:
    """
    Parses the command line arguments, does the stuff.
    But since there are no arguments, it just makes sure of that.

    Raises ScriptException if there is an error
    """
    parser = argparse.ArgumentParser(
        description="Clears iSCSI layer from CFS component status of NCN worker nodes")
    parser.parse_args()

    worker_ncn_xnames = get_worker_ncn_xnames()
    if not worker_ncn_xnames:
        raise ScriptException("No worker NCNs found in HSM")

    worker_cfs_comps = list_components(id_list=worker_ncn_xnames,
                                       include_state_details=True)

    # First check to make sure we got back one component for every worker
    worker_cfs_comp_ids = sorted([ comp["id"] for comp in worker_cfs_comps ])
    missing_xnames = set(worker_ncn_xnames).difference(worker_cfs_comp_ids)
    if missing_xnames:
        raise ScriptException(
            f"No CFS component found for following worker NCNs: {sorted(missing_xnames)}")

    # Make sure we did not get back more than one component for any worker
    if len(worker_cfs_comp_ids) != len(set(worker_cfs_comp_ids)):
        raise ScriptException("CFS returned multiple worker NCN components with the same id")

    # Map worker xnames to their CFS components
    worker_comp_map = { comp['id']: comp
                       for comp in worker_cfs_comps
                       if comp['id'] in worker_ncn_xnames }

    # Make sure no worker components have pending status
    pending_workers = sorted([ xname for xname, comp in worker_comp_map.items()
                               if comp.get("configuration_status") == "pending" ])

    if pending_workers:
        raise ScriptException(
            f"One or more workers have CFS components with 'pending' status: {pending_workers}")

    # Warn if any workers have no iSCSI layer in their status
    no_iscsi_status = sorted(
        [ xname for xname, comp in worker_comp_map.items()
          if cfs_comp_has_no_iscsi_status(comp)
        ]
    )

    if no_iscsi_status:
        print("WARNING: The following workers have no iSCSI layer in their CFS "
              f"component states; Only their error counts will be reset: {no_iscsi_status}")
    print("The following workers will have their CFS states updated and error "
          f"counts reset: {sorted(set(worker_comp_map).difference(no_iscsi_status))}")

    comp_patches = []
    for xname, comp in worker_comp_map.items():
        patch = { "error_count": 0, "id": xname }
        comp_patches.append(patch)
        if xname in no_iscsi_status:
            continue
        patch["state"] = []
        for layer in comp["state"]:
            if layer["playbook"] == ISCSI_PLAYBOOK:
                continue
            # Cannot patch the last_updated field
            del layer["last_updated"]
            patch["state"].append(layer)

    print("Updating CFS components...")
    update_components_by_list(comp_patches)
    print("Update successful. CFS batcher should soon start sessions to "
          "configure the nodes whose states were updated")


if __name__ == '__main__':
    try:
        main()
        print("SUCCESS")
    except ScriptException as exc:
        print_err(str(exc))
        sys.exit(1)
