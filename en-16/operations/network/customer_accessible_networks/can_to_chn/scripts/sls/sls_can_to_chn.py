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
"""Upgrade an SLS file from using the CAN to the CHN idempotently."""
import ipaddress
import json
import sys

import click

from csm_can_to_chn.sls_updates import create_chn_network
from csm_can_to_chn.sls_updates import sls_and_input_data_checks
from csm_can_to_chn.sls_updates import remove_uai_nmn_dhcp_ranges
from sls_utils.Managers import NetworkManager


help = """Upgrade a system SLS file to use the CHN.

    1. Create the CHN network.\n
    2. Change the BICAN "toggle" network to CHN.\n

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
    default="migrated_sls_file.json",
)
@click.option(
    "--customer-highspeed-network",
    required=True,
    help="CHN - VLAN and IPv4 network CIDR block",
    type=(click.IntRange(0, 4094), ipaddress.IPv4Network),
)
@click.option(
    "--bgp-asn",
    required=False,
    help="The autonomous system number for BGP router",
    type=click.IntRange(64512, 65534),
    default=65533,
    show_default=True,
)
@click.option(
    "--bgp-chn-asn",
    required=False,
    help="The autonomous system number for CHN BGP clients",
    type=click.IntRange(64512, 65534),
    default=65530,
    show_default=True,
)
@click.option(
    "--number-of-chn-edge-switches",
    required=True,
    help="Allow specification of the number of edge switches.  Typically a dev-only option.",
    type=click.IntRange(0, 2),
)
@click.pass_context
def main(
    ctx,
    sls_input_file,
    sls_output_file,
    customer_highspeed_network,
    bgp_asn,
    bgp_chn_asn,
    number_of_chn_edge_switches,
):
    """Upgrade an SLS file from using the CAN to the CHN.

    Args:
        ctx: Click context
        sls_input_file (str): Name of the SLS input file
        sls_output_file (str): Name of the updated SLS output file
        bican_user_network_name (str): Name of the BiCAN user network [CAN, CHN]
        customer_highspeed_network (int, ipaddress.IPv4Network): VLAN and IPv4 CIDR of the CHN
        bgp_asn (int): Remote peer ASN
        bgp_chn_asn (int): CHN local ASN
        number_of_chn_edge_switches (str): Flat to override default edge switch (Arista usually) qty of 2


    """
    bican_user_network_name = "CHN"

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
    #
    # Perform SLS and input data checks.
    sls_and_input_data_checks(
        networks,
        bican_user_network_name,
        customer_highspeed_network,
    )
    #
    # Create (new) CHN network
    #   (not order dependent)
    create_chn_network(
        networks,
        customer_highspeed_network,
        number_of_chn_edge_switches,
        bgp_asn,
        bgp_chn_asn,
    )

    #
    # remove the UAI NMN DHCP ranges
    remove_uai_nmn_dhcp_ranges(networks)

    #
    # Create BICAN network
    #   (not order dependent)
    bican = networks.get("BICAN")
    bican.system_default_route(bican_user_network_name)
    click.secho(
        f"Writing CSM 1.2 upgraded and schema validated SLS file to {sls_output_file.name}",
        fg="bright_white",
    )

    if sls_output_file:
        sls_json.pop("Networks")
        sls_json.update({"Networks": networks.to_sls()})
        new_json = json.dumps(sls_json, indent=2, sort_keys=True)
        click.echo(new_json, file=sls_output_file)


if __name__ == "__main__":
    main()
