#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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
"""Add Compute node IPs to the CHN"""
import json
import sys
import re

import click

from sls_utils.ipam import next_free_ipv4_address
from sls_utils.Managers import NetworkManager
from sls_utils.Reservations import Reservation


help = """Add Compute Nodes to the CHN

This procedure adds all Compute nodes to the Customer Highspeed Network (CHN).  In *many* cases this is
not required.  Generalized User access to computes over the CHN is only required in the following cases:

1. **Ingress** Users need to access *all* computes from the site (ssh or otherwise).
2. **Egress** The HSN has no NAT device in place and the CHN subnet is both large enough and site-routable.

Processing of SLS records will only occur if both the BICAN network exists (CSM >= 1.2) and the
SystemDefaultRoute values has been set to "CHN".  If these conditions are not met, running the
script is a no-op.

Script processing involves:
* Ensuring CHN is large enough to fit all HSN Reservations.
  * If not it's possible that either a NAT device is in place, or
  * This procedure is not required, or
  * The CHN was truly not large enough to accommodate all the compute nodes (typical).

NOTE:  Typically you will want a NAT device instead of running this, unless a very large CHN is allocated.

"""


@click.command(help=help)
@click.option(
    "--sls-input-file",
    required=True,
    help="Input SLS JSON file",
    type=click.File("r"),
)
@click.option(
    "--sls-output-file",
    help="Upgraded SLS JSON file name",
    type=click.File("w"),
    default="chn_with_computes_added_sls_file.json",
)
@click.pass_context
def main(
    ctx,
    sls_input_file,
    sls_output_file,
):
    """Upgrade a system SLS file to work with CHN.

    Args:
        ctx: Click context
        sls_input_file (str): Name of the SLS input file
        sls_output_file (str): Name of the updated SLS output file

    """
    click.secho("Loading SLS JSON file.", fg="bright_white")
    try:
        sls_json = json.load(sls_input_file)
    except (json.JSONDecodeError, UnicodeDecodeError):
        click.secho(
            f"The file {sls_input_file.name} is not valid JSON.",
            fg="red",
        )
        sys.exit(1)

    click.secho(
        "Extracting existing Networks from SLS file and schema validating.",
        fg="bright_white",
    )
    networks = NetworkManager(sls_json["Networks"])

    bican = networks.get("BICAN")
    if bican is None:
        click.secho(
            "INFO: The BICAN network does not exist in SLS.  This script has nothing to process for CSM < 1.2.",
            fg="bright_white",
        )
        sys.exit(1)

    if bican.system_default_route() != "CHN":
        click.secho(
            "INFO: The BICAN toggle (SystemDefaultRoute) is not set to CHN. This script has nothing to process.",
            fg="bright_white",
        )
        sys.exit(1)

    chn = networks.get("CHN")
    if chn is None:
        click.secho(
            "ERROR:  The BICAN toggle (SystemDefaultRoute)is set to CHN, but the CHN Network does not exist.\n"
            "        This should never happen.  Look at CSI output or sls_upgrader output for the root cause.",
            fg="red",
        )
        sys.exit(1)

    chn_subnet = chn.subnets().get("bootstrap_dhcp")
    if chn_subnet is None:
        click.secho(
            "ERROR:  The CHN Subnet bootrap_dhcp does not exist and is required.\n"
            "        Look at CSI output or sls_upgrader output for the root cause.",
            fg="red",
        )
        sys.exit(1)

    hsn = networks.get("HSN")
    if hsn is None:
        click.secho(
            "ERROR:  The HSN network does not exist, but the CHN Network exists.\n"
            "        HSN is pre-requisite for CHN.  Look at CSI output or sls_upgrader output for the root cause.",
            fg="red",
        )
        sys.exit(1)

    hsn_subnet = hsn.subnets().get("hsn_base_subnet")
    if hsn_subnet is None:
        click.secho(
            "ERROR:  The HSN Subnet hsn_base_subnet does not exist and is required.\n"
            "        Look at CSI output or sls_upgrader output for the root cause.",
            fg="red",
        )
        sys.exit(1)

    hsn_ipv4_network = hsn_subnet.ipv4_network()
    hsn_size = hsn_ipv4_network.num_addresses
    hsn_used = len(hsn_subnet.reservations()) + 1
    click.secho(
        f"INFO:  The HSN {hsn_ipv4_network} supports {hsn_size} addresses "
        f"of which {hsn_used} are currently used.",
        fg="bright_white",
    )

    xname_pattern = re.compile(
        "^x([0-9]{1,4})c([0-7])s([0-9]+)b([0-9]+)n([0-9]+)h0$"
    )  # HSN Node NIC xXcCsSbBnNhH but only the h0 one
    xname_pattern_chn = re.compile(
        "^x([0-9]{1,4})c([0-7])s([0-9]+)b([0-9]+)n([0-9]+)h([0-3])$"
    )  # HSN Node NIC xXcCsSbBnNhH

    hsn_reservations = hsn_subnet.reservations().values()
    hsn_xnames = set(
        [r.name() for r in hsn_reservations if xname_pattern.match(r.name())]
    )

    chn_ipv4_network = chn_subnet.ipv4_network()
    chn_xnames = set(
        [
            r.name()
            for r in chn_subnet.reservations().values()
            if xname_pattern_chn.match(r.name())
        ]
    )
    chn_size = chn_ipv4_network.num_addresses
    chn_used = len(chn_subnet.reservations()) + 1

    hsn_to_be_added = (
        hsn_xnames - chn_xnames
    )  # xnames in hsn but not in chn (these will be added to chn)
    chn_to_be_removed = (
        chn_xnames - hsn_xnames
    )  # xnames in chn but not in hsn, also any h[1-3] nodes in chn (these will be removed from chn)

    chn_available_ips = chn_size - chn_used + len(chn_to_be_removed)
    net_chn_add_count = len(hsn_to_be_added) - len(chn_to_be_removed)
    click.secho(
        f"INFO:  The CHN {chn_ipv4_network} supports {chn_size} addresses "
        f"of which {chn_used} are currently used. {len(hsn_to_be_added)} "
        f"will be added and {len(chn_to_be_removed)} will be removed.",
        fg="bright_white",
    )
    if chn_available_ips < net_chn_add_count:
        click.secho(
            f"ERROR:  The CHN with {chn_available_ips} IPs available is too small to add {net_chn_add_count} HSN IPs.\n"
            "        This can be for two reasons:\n"
            "        1. A NAT device is in place to provides HSN egress access for Computes.\n"
            "        2. The CHN size allocated during installation or upgrade is indeed to small and needs resizing.",
            fg="red",
        )
        sys.exit(1)

    for xname in chn_to_be_removed:
        if xname in chn_subnet.reservations():
            click.secho(
                f"    Removing {xname} from CHN because it is not in HSN or is not an h0 node",
                fg="white",
            )
            del chn_subnet.reservations()[xname]

    for hsn_reservation in hsn_reservations:
        new_name = hsn_reservation.name()
        if not xname_pattern.match(new_name):
            click.secho(
                f"    Skipping {new_name} because it is not an xname for HSN h0 Node NIC",
                fg="white",
            )
            continue
        if new_name in chn_xnames:
            click.secho(
                f"    Skipping {new_name} because it is already in the CHN", fg="white"
            )
            continue

        new_ipv4_address = next_free_ipv4_address(chn_subnet)
        click.secho(f"    Adding Reservation {new_name} {new_ipv4_address}", fg="white")
        chn_subnet.reservations().update(
            {
                new_name: Reservation(
                    new_name,
                    new_ipv4_address,
                    [],
                    comment=None,
                ),
            },
        )

    click.secho(
        f"CHN now has {len(chn_subnet.reservations()) + 1} IP reservations",
        fg="bright_white",
    )

    click.secho(
        f"Writing upgraded and schema validated SLS file to {sls_output_file.name}",
        fg="bright_white",
    )

    if sls_output_file:
        sls_json.pop("Networks")
        sls_json.update({"Networks": networks.to_sls()})
        new_json = json.dumps(sls_json, indent=2, sort_keys=True)
        click.echo(new_json, file=sls_output_file)


if __name__ == "__main__":
    main()
