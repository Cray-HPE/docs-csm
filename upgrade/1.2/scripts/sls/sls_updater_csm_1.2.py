#!/usr/bin/env python3
# MIT License
#
# (C) Copyright [2022] Hewlett Packard Enterprise Development LP
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
"""Upgrade an SLS file from any CSM 1.0.x version to CSM 1.2 idempotently."""
import ipaddress
import json
import sys

import click
from csm_1_2_upgrade.sls_updates import convert_can_ips
from csm_1_2_upgrade.sls_updates import create_bican_network
from csm_1_2_upgrade.sls_updates import create_chn_network
from csm_1_2_upgrade.sls_updates import create_metallb_pools_and_asns
from csm_1_2_upgrade.sls_updates import migrate_can_to_cmn
from csm_1_2_upgrade.sls_updates import migrate_switch_names
from csm_1_2_upgrade.sls_updates import remove_api_gw_from_hmnlb_reservations
from csm_1_2_upgrade.sls_updates import rename_uai_bridge_reservation
from csm_1_2_upgrade.sls_updates import remove_can_static_pool
from csm_1_2_upgrade.sls_updates import remove_kube_api_reservations
from csm_1_2_upgrade.sls_updates import sls_and_input_data_checks
from csm_1_2_upgrade.sls_updates import update_nmn_uai_macvlan_dhcp_ranges
from sls_utils.Managers import NetworkManager


help = """Upgrade a system SLS file from CSM 1.0 to CSM 1.2.

    1. Migrate switch naming (in order):  leaf to leaf-bmc and agg to leaf.\n
    2. Remove api-gateway entries from HMLB subnets for CSM 1.2 security.\n
    3. Remove kubeapi-vip reservations for all networks except NMN.\n
    4. Create the new BICAN "toggle" network.\n
    5. Migrate the existing CAN to CMN.\n
    7. Create the CHN network.\n
    7. Convert IPs of the CAN network.\n
    8. Create MetalLB Pools and ASN entries on CMN and NMN networks.\n
    9. Update uai_macvlan in NMN dhcp ranges and uai_macvlan VLAN.\n
   10. Rename uai_macvlan_bridge reservation to uai_nmn_blackhole
   11. Remove unused user networks (CAN or CHN) if requested [--retain-unused-user-network to keep].\n
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
    "--bican-user-network-name",
    required=True,
    help="Name of the network over which non-admin users access the system",
    type=click.Choice(["CAN", "CHN", "HSN"], case_sensitive=True),
)
@click.option(
    "--customer-access-network",
    required=False,
    help="CAN - VLAN and IPv4 network CIDR block",
    type=(click.IntRange(0, 4094), ipaddress.IPv4Network),
    default=(6, "10.103.6.0/24"),
    show_default=True,
)
@click.option(
    "--customer-highspeed-network",
    required=False,
    help="CHN - VLAN and IPv4 network CIDR block",
    type=(click.IntRange(0, 4094), ipaddress.IPv4Network),
    default=(5, "10.104.7.0/24"),
    show_default=True,
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
    "--bgp-cmn-asn",
    required=False,
    help="The autonomous system number for CMN BGP clients",
    type=click.IntRange(64512, 65534),
    default=65532,
    show_default=True,
)
@click.option(
    "--bgp-nmn-asn",
    required=False,
    help="The autonomous system number for NMN BGP clients (preserve <= CSM 1.0 defaults)",
    type=click.IntRange(64512, 65534),
    default=65533,
    show_default=True,
)
@click.option(
    "--preserve-existing-subnet-for-cmn",
    required=False,
    help="When creating the CMN from the CAN, preserve the metallb_static_pool for external-dns IP, or "
    "bootstrap_dhcp for NCN IPs.  By default no subnet IPs from CAN will be preserved.",
    type=click.Choice(["external-dns", "ncns"]),
    default=None,
    show_default=True,
)
@click.option(
    "--can-subnet-override",
    required=False,
    help="[EXPERT] Manually/Statically assign CAN subnets to your choice of network_hardware, "
    "bootstrap_dhcp, can_metallb_address_pool, and/or can_metallb_static_pool subnets.",
    type=(
        click.Choice(
            [
                "network_hardware",
                "bootstrap_dhcp",
                "can_metallb_address_pool",
                "can_metallb_static_pool",
            ],
            case_sensitive=True,
        ),
        ipaddress.IPv4Network,
    ),
    multiple=True,
)
@click.option(
    "--cmn-subnet-override",
    required=False,
    help="[EXPERT] Manually/Statically assign CMN subnets to your choice of network_hardware, "
    "bootstrap_dhcp, cmn_metallb_address_pool, and/or cmn_metallb_static_pool subnets.",
    type=(
        click.Choice(
            [
                "network_hardware",
                "bootstrap_dhcp",
                "cmn_metallb_address_pool",
                "cmn_metallb_static_pool",
            ],
            case_sensitive=True,
        ),
        ipaddress.IPv4Network,
    ),
    multiple=True,
)
@click.option(
    "--retain-unused-user-network",
    help="If a CHN is selected, remove the CAN.  For development systems you probably want this enabled.",
    is_flag=True,
    default=True,
    show_default=True,
)
@click.option(
    "--number-of-chn-edge-switches",
    help="Allow specification of the number of edge switches.  Typically a dev-only option.",
    default=2,
    type=click.IntRange(0, 2),
    show_default=True,
)
@click.pass_context
def main(
    ctx,
    sls_input_file,
    sls_output_file,
    bican_user_network_name,
    customer_access_network,
    customer_highspeed_network,
    bgp_asn,
    bgp_chn_asn,
    bgp_cmn_asn,
    bgp_nmn_asn,
    preserve_existing_subnet_for_cmn,
    can_subnet_override,
    cmn_subnet_override,
    number_of_chn_edge_switches,
    retain_unused_user_network,
):
    """Upgrade a system SLS file from CSM 1.0 to CSM 1.2.

    Args:
        ctx: Click context
        sls_input_file (str): Name of the SLS input file
        sls_output_file (str): Name of the updated SLS output file
        bican_user_network_name (str): Name of the BiCAN user network [CAN, CHN]
        customer_access_network (int, ipaddress.IPv4Network): VLAN and IPv4 CIDR of the CAN
        customer_highspeed_network (int, ipaddress.IPv4Network): VLAN and IPv4 CIDR of the CHN
        bgp_asn (int): Remote peer ASN
        bgp_chn_asn (int): CHN local ASN
        bgp_cmn_asn (int): CMN local ASN
        bgp_nmn_asn (int): NMN local ASN
        preserve_existing_subnet_for_cmn (str|None): Whether to preserve static pool or bootstrap_dhcp (or neither)
        can_subnet_override (str, ipaddress.IPv4Network): Manually override CAN subnetting
        cmn_subnet_override (str, ipaddress.IPv4Network): Manually override CMN subnetting
        number_of_chn_edge_switches (str): Flat to override default edge switch (Arista usually) qty of 2
        retain_unused_user_network (flag): Flag to remove unused user network (e.g. remove CAN if CHN)

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
    hardware = sls_json["Hardware"]

    #
    # Perform SLS and input data checks.
    #
    sls_and_input_data_checks(
        networks,
        bican_user_network_name,
        customer_access_network,
        customer_highspeed_network,
        can_subnet_override,
        cmn_subnet_override,
    )

    #
    # Migrate switch names
    #   (not order dependent)
    migrate_switch_names(networks, hardware)

    #
    # Remove api-gw aliases from HMNLB reservations
    #   (not order dependent)
    remove_api_gw_from_hmnlb_reservations(networks)

    #
    # Create BICAN network
    #   (not order dependent)
    create_bican_network(networks, default_route_network_name=bican_user_network_name)

    #
    # Clone (existing) CAN network to CMN
    #   (ORDER DEPENDENT!!!)
    #   Use CAN as a template and create the CMN (leaves CAN in-place)
    #   On any pre-CSM-1.2 system there WILL/MUST be a CAN in SLS
    migrate_can_to_cmn(
        networks,
        preserve=preserve_existing_subnet_for_cmn,
        overrides=cmn_subnet_override,
    )

    #
    # Remove CAN static pool
    #   (ORDER DEPENDENT!!!)
    #   Must be run after CMN, but before CHN.
    remove_can_static_pool(networks)

    #
    # Remove kube-api reservations from all networks except NMN.
    remove_kube_api_reservations(networks)

    #
    # Create (new) CHN network
    #   (not order dependent)
    create_chn_network(
        networks,
        customer_highspeed_network,
        number_of_chn_edge_switches,
    )

    #
    # Re-IP the (existing) CAN network
    #   (ORDER DEPENDENT!!! - Must be run after CMN creation)
    convert_can_ips(networks, customer_access_network, overrides=can_subnet_override)

    #
    # Add BGP peering data to CMN and NMN
    #   (ORDER DEPENDENT!!! - Must be run after CMN creation)
    create_metallb_pools_and_asns(
        networks,
        bgp_asn,
        bgp_chn_asn,
        bgp_cmn_asn,
        bgp_nmn_asn,
    )

    #
    # Update uai_macvlan dhcp ranges in the NMN network.
    #   (not order dependent)
    update_nmn_uai_macvlan_dhcp_ranges(networks)

    #
    # Rename uai_macvlan_bridge reservation to uai_nmn_blackhole
    #   (not order dependent)
    rename_uai_bridge_reservation(networks)

    #
    # Remove superfluous user network if requested
    #   (ORDER DEPENDENT!!! - Must be run at end)
    #   NEVER REMOVE THE HSN!!!
    if retain_unused_user_network:
        if bican_user_network_name == "CAN":
            click.secho("Removing unused CHN (if it exists) as requested", fg="bright_white")
            networks.pop("CHN", None)
        if bican_user_network_name == "CHN":
            click.secho("Removing unused CAN (if it exists) as requested", fg="bright_white")
            networks.pop("CAN", None)
        if bican_user_network_name == "HSN":
            click.secho("Removing unused CAN and CHN (if they exist) as requested", fg="bright_white")
            networks.pop("CAN", None)
            networks.pop("CHN", None)

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
