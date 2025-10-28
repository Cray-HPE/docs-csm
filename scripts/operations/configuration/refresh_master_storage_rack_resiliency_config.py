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
refresh_master_storage_rack_resiliency_config.py

This script refreshes the Rack Resiliency playbook layer
(`rack_resiliency_for_mgmt_nodes.yml`) for all Master and Storage NCNs.

This script modifies the CFS component status of master and storage NCNs to clear out
the Rack Resiliency playbook entry. It also sets the error count for the component to 0.
This will cause CFS batcher to schedule new CFS sessions to run that playbook
on the master and storage nodes.

It checks if any Master or Storage NCN has the Rack Resiliency layer configured
in CFS. If at least one node in either category has the layer, it proceeds to
remove that layer from all Master and Storage NCNs’ CFS states so that CFS can
automatically reapply it, ensuring the configuration is refreshed.

Behavior:
  - If none of the Master or Storage NCNs have the Rack Resiliency layer → abort.
  - If any Master or Storage NCN has the layer → refresh the CFS state for both roles.
"""


import argparse
import sys
from functools import partial
from typing import List
from python_lib.cfs import list_components, update_components_by_list
from python_lib.hsm import get_management_ncn_xnames
from python_lib.common import ScriptException, print_err
from python_lib.types import JsonDict


# Rack Resiliency playbook name
RACK_RESILIENCY_PLAYBOOK = "rack_resiliency_for_mgmt_nodes.yml"


# Convenience partials for fetching NCN xnames
get_master_ncn_xnames = partial(get_management_ncn_xnames, subrole="Master")
get_storage_ncn_xnames = partial(get_management_ncn_xnames, subrole="Storage")


def cfs_comp_has_rack_resiliency_layer(comp: JsonDict) -> bool:
    """Return True if the Rack Resiliency playbook layer exists in the component state."""
    return any(layer.get("playbook") == RACK_RESILIENCY_PLAYBOOK for layer in comp.get("state", []))


def validate_any_master_has_layer(master_xnames: List[str]) -> None:
    """Ensure at least one master NCN has the Rack Resiliency layer before continuing."""
    comps = list_components(id_list=master_xnames, include_state_details=True)
    masters_with_layer = [c["id"] for c in comps if cfs_comp_has_rack_resiliency_layer(c)]
    masters_without_layer = [c["id"] for c in comps if not cfs_comp_has_rack_resiliency_layer(c)]

    if not masters_with_layer:
        raise ScriptException("None of the Master NCNs have the Rack Resiliency playbook layer. Aborting.")

    print(f"{len(masters_with_layer)} Master NCN(s) have the Rack Resiliency playbook layer.")
    if masters_without_layer:
        print(f"Masters without layer (for info): {masters_without_layer}")


def validate_any_storage_has_layer(storage_xnames: List[str]) -> None:
    """Ensure at least one storage NCN has the Rack Resiliency layer before continuing."""
    comps = list_components(id_list=storage_xnames, include_state_details=True)
    storage_with_layer = [c["id"] for c in comps if cfs_comp_has_rack_resiliency_layer(c)]
    storage_without_layer = [c["id"] for c in comps if not cfs_comp_has_rack_resiliency_layer(c)]

    if not storage_with_layer:
        raise ScriptException("None of the Storage NCNs have the Rack Resiliency playbook layer. Aborting.")

    print(f"{len(storage_with_layer)} Storage NCN(s) have the Rack Resiliency playbook layer.")
    if storage_without_layer:
        print(f"Storage nodes without layer (for info): {storage_without_layer}")


def update_rack_resiliency_layer(ncn_role: str, ncn_xnames: List[str]) -> None:
    """Perform the Rack Resiliency layer refresh for a given NCN role."""
    print(f"\n=== Processing {ncn_role} NCNs ===")

    if not ncn_xnames:
        raise ScriptException(f"No {ncn_role.lower()} NCNs found in HSM.")

    comps = list_components(id_list=ncn_xnames, include_state_details=True)
    comp_ids = sorted([c["id"] for c in comps])
    missing = set(ncn_xnames).difference(comp_ids)

    if missing:
        raise ScriptException(f"No CFS component found for {ncn_role.lower()} NCNs: {sorted(missing)}")

    if len(comp_ids) != len(set(comp_ids)):
        raise ScriptException(f"CFS returned duplicate {ncn_role.lower()} NCN components.")

    comp_map = {c["id"]: c for c in comps}

    pending = [x for x, comp in comp_map.items() if comp.get("configuration_status") == "pending"]
    if pending:
        raise ScriptException(f"{ncn_role} NCNs with pending CFS components: {pending}")

    comp_patches = []
    for xname, comp in comp_map.items():
        new_state = []
        for layer in comp.get("state", []):
            # Remove the Rack Resiliency layer if present
            if layer.get("playbook") == RACK_RESILIENCY_PLAYBOOK:
                continue
            layer.pop("last_updated", None)
            new_state.append(layer)

        comp_patches.append({
            "id": xname,
            "error_count": 0,
            "state": new_state
        })

    if not comp_patches:
        print(f"No {ncn_role.lower()} NCNs required modification; skipping.")
        return

    print(f"Updating {len(comp_patches)} {ncn_role.lower()} CFS components...")
    update_components_by_list(comp_patches)
    print(f"{ncn_role} NCNs successfully updated.\n")


def main() -> None:
    """Main entry point for refreshing Rack Resiliency layers."""
    parser = argparse.ArgumentParser(
        description="Refresh Rack Resiliency CFS component states for Master and Storage NCNs."
    )
    parser.parse_args()

    master_ncn_xnames = get_master_ncn_xnames()
    storage_ncn_xnames = get_storage_ncn_xnames()

    # Validate if any Masters or Storages have the playbook
    print("Validating Rack Resiliency layer presence...")
    validate_any_master_has_layer(master_ncn_xnames)
    validate_any_storage_has_layer(storage_ncn_xnames)

    # Perform updates
    update_rack_resiliency_layer("Master", master_ncn_xnames)
    update_rack_resiliency_layer("Storage", storage_ncn_xnames)

    print("All updates completed successfully. CFS batcher should soon reconfigure these NCNs.")


# All the exceptions are handled here
if __name__ == "__main__":
    try:
        main()
        print("SUCCESS")
    except ScriptException as exc:
        print_err(str(exc))
        sys.exit(1)
    except Exception as exc:
        print_err(f"Unexpected error: {exc}")
        sys.exit(1)
