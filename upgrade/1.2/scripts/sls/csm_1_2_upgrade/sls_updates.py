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
"""Functions used to update SLS from CSM 1.0.x to CSM 1.2."""
from collections import defaultdict
import ipaddress
import sys

import click
from sls_utils.ipam import (
    free_ipv4_addresses,
    free_ipv4_subnets,
    hosts_from_prefixlength,
    last_free_ipv4_address,
    next_free_ipv4_address,
    prefixlength,
    prefixlength_from_hosts,
)
from sls_utils.Networks import BicanNetwork
from sls_utils.Networks import Network
from sls_utils.Networks import Subnet
from sls_utils.Reservations import Reservation


def sls_and_input_data_checks(
    networks,
    bican_name,
    can_data,
    chn_data,
    can_subnet_override,
    cmn_subnet_override,
):
    """Check input values and SLS data for proper logic.

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
        bican_name (str): Name of the user network for bifurcated CAN
        can_data (int, ipaddress.IPv4Network): VLAN and IPv4 CIDR for the CAN
        chn_data (int, ipaddress.IPv4Network): VLAN and IPv4 CIDR for the CHN
        can_subnet_override (str, ipaddress.IPv4Network): subnet name and network tuples
        cmn_subnet_override (str, ipaddress.IPv4Network): subnet name and network tuples
    """
    click.secho(
        "Checking input values and SLS data for proper logic.",
        fg="bright_white",
    )

    can = networks.get("CAN")
    if can is not None:
        click.secho(
            "    INFO: A CAN network already exists in SLS.",
            fg="white",
        )
        if can_data[1] == ipaddress.IPv4Network("10.103.6.0/24"):
            click.secho(
                "    WARNING: CAN network found, but command line --customer-access-network values not found. "
                "Using [default: 6, 10.103.6.0/24]",
                fg="bright_yellow",
            )

    cmn = networks.get("CMN")
    if cmn is not None:
        click.secho(
            "    INFO: A CMN network already exists in SLS.  This is unusual except where the "
            "upgrade process has already run or on an existing CSM 1.2 system.",
            fg="white",
        )

    chn = networks.get("CHN")
    if chn is not None:
        click.secho(
            "    INFO: A CHN network already exists in SLS.  This is unusual except where the "
            "upgrade process has already run or on an existing CSM 1.2 system.",
            fg="white",
        )
    if bican_name == "CHN":
        if chn_data[1] == ipaddress.IPv4Network("10.104.7.0/24"):
            click.secho(
                "    WARNING: Command line --customer-highspeed-network values not found. "
                "Using [default: 5, 10.104.7.0/24]",
                fg="bright_yellow",
            )

    nmn = networks.get("NMN")
    if nmn is not None:
        if None not in nmn.bgp():
            click.secho(
                "    WARNING: BGP Peering information exists in the NMN network and will be overwritten.",
                fg="bright_yellow",
            )

    if can_subnet_override:
        click.secho(
            f"    WARNING: The --can-subnet-override flag has been enabled for {[i[0] for i in can_subnet_override]}.\n"
            "         This is EXPERT mode requiring manual subnetting of the CAN and bypasses sanity checks.",
            fg="bright_yellow",
        )

    if cmn_subnet_override:
        click.secho(
            f"    WARNING: The --cmn-subnet-override flag has been enabled for {[i[0] for i in can_subnet_override]}.\n"
            "         This is EXPERT mode requiring manual subnetting of the CMN and bypasses sanity checks.",
            fg="bright_yellow",
        )

    # Old CAN migrates to CMN.  New CAN must not have overlaps.
    if cmn is None:
        old_can_vlan = can.subnets().get("bootstrap_dhcp").vlan()
        old_can_net = can.subnets().get("bootstrap_dhcp").ipv4_network()
        new_can_vlan = can_data[0]
        new_can_net = can_data[1]
        overlap_errors = False
        if old_can_vlan == new_can_vlan:
            click.secho(
                f"    ERROR: New CMN VLAN {old_can_vlan} overlaps with New CAN VLAN {new_can_vlan}.\n"
                "         Please correct the --customer-access-network input values on the command line.",
                fg="red",
            )
            overlap_errors = True

        if old_can_net.overlaps(new_can_net):
            click.secho(
                f"    ERROR: New CMN Network {old_can_net} overlaps with New CAN Network {new_can_net}.\n"
                "         Please correct the --customer-access-network input values on the command line.",
                fg="red",
            )
            overlap_errors = True

        if overlap_errors:
            sys.exit(1)


def migrate_switch_names(networks, hardware):
    """Rename CSM <=1.0.x switches to new CSM 1.2 naming.

    CSM 1.2 changes switch names in the following order:
      1. sw-leaf-xyz -> sw-leaf-bmc-xyz
      2. sw-agg-xyz -> sw-leaf-xyz

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
        hardware (json): Unmanaged SLS Hardware structure in JSON
    """
    # The BICAN network only exists in CSM >=1.2.  If it exists do NOT migrate
    # switch names.
    # WARNING:  If this check is not in place the script is not guaranteed to
    # be idempotent!
    if networks.get("BICAN") is not None:
        return

    subnet = "network_hardware"

    click.secho("Migrating switch naming in Networks.", fg="bright_white")
    for network in networks.values():
        if network.subnets().get(subnet) is None:
            continue
        reservations = network.subnets().get(subnet).reservations()

        click.echo(
            "    Renaming sw-leaf to sw-leaf-bmc in reservations "
            f"for subnet {subnet} in network {network.name()}.",
        )
        for reservation in reservations.values():
            if reservation.name().find("leaf") < 0:
                continue
            reservation.name(reservation.name().replace("leaf", "leaf-bmc"))

        click.echo(
            "    Renaming sw-agg  to sw-leaf     in reservations "
            f"for subnet {subnet} in network {network.name()}.",
        )
        for reservation in reservations.values():
            if reservation.name().find("agg") < 0:
                continue
            reservation.name(reservation.name().replace("agg", "leaf"))

        # Change reservation key names (internal to library)
        for old_key in list(reservations):
            new_key = old_key.replace("leaf", "leaf-bmc")
            reservations[new_key] = reservations.pop(old_key)
        for old_key in list(reservations):
            new_key = old_key.replace("agg", "leaf")
            reservations[new_key] = reservations.pop(old_key)

    click.secho("Migrating switch naming in Hardware.", fg="bright_white")
    for device in hardware.values():
        ep = device.get("ExtraProperties")
        if ep is None:
            continue
        aliases = ep.get("Aliases")
        if aliases is None:
            continue
        for i in range(len(aliases)):
            if aliases[i].find("sw-leaf-") != -1:
                aliases[i] = aliases[i].replace("sw-leaf-", "sw-leaf-bmc-")
                click.echo(
                    f'    Renaming sw-leaf to sw-leaf-bmc in hardware for Xname {device["Xname"]}',
                )
            if aliases[i].find("sw-agg-") != -1:
                aliases[i] = aliases[i].replace("sw-agg-", "sw-leaf-")
                click.echo(
                    f'    Renaming sw-agg  to sw-leaf     in hardware for Xname {device["Xname"]}',
                )


def remove_api_gw_from_hmnlb_reservations(networks):
    """Remove istio ingress (api-gw) from the existing HMNLB network.

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
    """
    click.secho(
        f"Removing any api-gw aliases from HMNLB.",
        fg="bright_white",
    )
    network = "HMNLB"
    subnet = "hmn_metallb_address_pool"
    reservations = networks.get(network).subnets().get(subnet).reservations()
    for delete_reservation in ["istio-ingressgateway", "istio-ingressgateway-local"]:
        if reservations.pop(delete_reservation, None) is not None:
            click.secho(
                f"    Removing api-gw aliases {delete_reservation} from {network} {subnet}",
                fg="white",
            )


def rename_uai_bridge_reservation(networks):
    """Rename the uai_macvlan_bridge reservation to uai_nmn_blackhole

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
    """
    click.secho(
        "Renaming uai_macvlan_bridge reservation to uai_nmn_blackhole",
        fg="bright_white"
    )
    network = "NMN"
    subnet = "uai_macvlan"
    reservations = networks.get(network).subnets().get(subnet).reservations()
    for reservation in reservations.values():
        if reservation.name().find("macvlan_bridge") < 0:
            continue
        reservation.name(reservation.name().replace("macvlan_bridge", "nmn_blackhole"))
        reservation.comment(reservation.comment().replace("macvlan-bridge", "nmn-blackhole"))

        for i, alias in enumerate(reservation.aliases()):
            if alias.find("macvlan-bridge") >= 0:
                click.echo(f"    Found macvlan-bridge in alias {alias}")
                reservation.aliases()[i] = alias.replace("-macvlan-bridge", "-nmn-blackhole")
            elif alias.find("macvlan_bridge") >= 0:
                click.echo(f"    Found macvlan_bridge in alias {alias}")
                reservation.aliases()[i] = alias.replace("_macvlan_bridge", "_nmn_blackhole")


def remove_kube_api_reservations(networks):
    """Remove kube-api from all networks except NMN.

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
    """
    click.secho(
        "Removing kubeapi-vip reservations from all network except NMN",
        fg="bright_white",
    )
    for network in networks.values():
        if network.name() == "NMN":
            continue
        for subnet in network.subnets().values():
            if subnet.reservations().get("kubeapi-vip") is not None:
                subnet.reservations().pop("kubeapi-vip")


def create_bican_network(networks, default_route_network_name):
    """Create a new SLS BICAN network data structure.

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
        default_route_network_name (str): Name of the user network for bifurcated CAN
    """
    if networks.get("BICAN") is None:
        click.secho(
            f"Creating new BICAN network and toggling to {default_route_network_name}.",
            fg="bright_white",
        )
        bican = BicanNetwork(default_route_network_name=default_route_network_name)
        networks.update({bican.name(): bican})


def remove_can_static_pool(networks):
    """Remove MetalLB Static pool in CAN (and CHN).

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
    """
    can = networks.get("CAN")
    if can is None:
        return

    if can.subnets().get("can_metallb_static_pool") is None:
        return

    click.secho(
        "Removing CAN MetalLB static pool",
        fg="bright_white",
    )
    can.subnets().pop("can_metallb_static_pool")


def create_chn_network(networks, chn_data, number_of_chn_edge_switches):
    """Create a new SLS CHN data structure.

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
        chn_data (int, ipaddress.IPv4Network): VLAN and IPv4 CIDR for the CHN
        number_of_chn_edge_switches (int): Number of switches to uplink for CHN
    """
    if networks.get("CHN") is not None:
        return

    chn_vlan = chn_data[0]
    chn_ipv4 = chn_data[1]
    click.secho(
        f"Creating CHN network with VLAN: {chn_vlan} and IPv4 CIDR: {chn_ipv4}",
        fg="bright_white",
    )
    chn = Network("CHN", "ethernet", chn_ipv4)
    chn.full_name("Customer High-Speed Network")
    chn.mtu(9000)

    # Clone CAN subnets for structure
    for can_subnet in networks.get("CAN").subnets().values():
        chn.subnets().update(
            {can_subnet.name(): Subnet.subnet_from_sls_data(can_subnet.to_sls())},
        )

    # Clean up subnet naming
    for subnet in chn.subnets().values():
        subnet.name(subnet.name().replace("can_", "chn_"))
        subnet.full_name(subnet.full_name().replace("CAN", "CHN"))
        click.echo(f"    Updating subnet naming for {subnet.name()}")

        click.echo(f"    Updating reservation names and aliases for {subnet.name()}")
        for reservation in subnet.reservations().values():
            reservation.name(reservation.name().replace("can-", "chn-"))
            reservation.name(reservation.name().replace("-can", "-chn"))

            if reservation.aliases() is None:
                continue

            for i, alias in enumerate(reservation.aliases()):
                reservation.aliases()[i] = alias.replace("-can", "-chn")

    bootstrap = chn.subnets().get("bootstrap_dhcp")
    click.echo(
        f"    Updating subnet IPv4 addresses for {bootstrap.name()} to {chn_ipv4}",
    )
    bootstrap.ipv4_address(chn_ipv4)
    bootstrap.ipv4_gateway(list(chn_ipv4.hosts())[0])
    bootstrap.vlan(chn_vlan)

    pool_subnets = list(bootstrap.ipv4_network().subnets())[
        1
    ]  # Last half of bootstrap.
    pool_subnets = list(pool_subnets.subnets())  # Split it in two.

    click.echo(f"    Updating reservation IPv4 addresses for {bootstrap.name()}")
    for reservation in bootstrap.reservations().values():
        reservation.ipv4_address(next_free_ipv4_address(bootstrap))

    hold_ipv4 = bootstrap.ipv4_network()
    bootstrap.ipv4_address(f"{hold_ipv4.network_address}/{hold_ipv4.prefixlen+1}")

    dhcp_start = next_free_ipv4_address(bootstrap)
    dhcp_end = sorted(free_ipv4_addresses(bootstrap))[-1]
    click.echo(f"    Updating DHCP start-end IPv4 addresses {dhcp_start}-{dhcp_end}")
    bootstrap.dhcp_start_address(dhcp_start)
    bootstrap.dhcp_end_address(dhcp_end)

    bootstrap.ipv4_address(hold_ipv4)

    # Update MetalLB pool subnets
    for subnet in chn.subnets().values():
        if subnet.name() == "bootstrap_dhcp":
            continue
        subnet_ipv4_address = pool_subnets.pop(0)
        subnet_ipv4_gateway = list(subnet_ipv4_address.hosts())[0]
        subnet.ipv4_address(subnet_ipv4_address)
        subnet.ipv4_gateway(subnet_ipv4_gateway)
        subnet.vlan(chn_vlan)

        if subnet.reservations() is None:
            continue

        for reservation in subnet.reservations().values():
            reservation.ipv4_address(next_free_ipv4_address(subnet))

    if number_of_chn_edge_switches != 2:
        # Note that reservation keys above are still "can" so this is a hack
        # This will leave a hole in the reservation IPs, but can be re-used.
        click.echo(
            f"    Adjusting the number of edge switches from 2 to {number_of_chn_edge_switches}",
        )
        del_switches = [
            f"can-switch-{s}" for s in list(range(2, number_of_chn_edge_switches, -1))
        ]
        for switch in del_switches:
            if switch not in bootstrap.reservations().keys():
                continue
            del bootstrap.reservations()[switch]

    networks.update({"CHN": chn})


def migrate_can_to_cmn(networks, preserve=None, overrides=None):
    """Convert an existing CAN network in SLS to the new CMN.

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
        preserve (str): Network to preferentially preserve IP addresses whenc cloning
        overrides (str, ipaddress.IPv4Network): Tuple of tuples forcing subnet addressing
    """
    can_network = networks.get("CAN")
    if can_network is None:
        return

    if networks.get("CMN") is not None:
        return

    click.secho("Converting existing CAN network to CMN.", fg="bright_white")
    source_network_name = "CAN"
    destination_network_name = "CMN"
    destination_network_full_name = "Customer Management Network"
    subnet_names = [
        "network_hardware",
        "bootstrap_dhcp",
        "metallb_address_pool",
        "metallb_static_pool",
    ]
    clone_subnet_and_pivot(
        networks,
        source_network_name,
        destination_network_name,
        destination_network_full_name,
        subnet_names,
        preserve,
        overrides,
    )

    click.echo("    Cleaning up remnant CAN switch reservations in boostrap_dhcp")
    network = networks.get(destination_network_name)
    if network is None:
        return
    bootstrap_subnet = network.subnets().get("bootstrap_dhcp")
    switches = ["cmn-switch-1", "cmn-switch-2"]
    for switch in switches:
        if bootstrap_subnet.reservations().get(switch) is not None:
            del bootstrap_subnet.reservations()[switch]


def convert_can_ips(networks, can_data, preserve=None, overrides=None):
    """Change subnet and IPs on the CAN.

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
        can_data (int, ipaddress.IPv4Network): VLAN and IPv4 CIDR for the CAN
        preserve (str): Network to preferentially preserve IP addresses whenc cloning
        overrides (str, ipaddress.IPv4Network): Tuple of tuples forcing subnet addressing
    """
    can_network = networks.get("CAN")
    if can_network is None:
        return

    if networks.get("BICAN"):
        return

    click.secho(
        "Converting existing CAN network and IPv4 addresses.",
        fg="bright_white",
    )

    source_network_name = "CAN"
    destination_network_name = "CAN"
    destination_network_full_name = "Customer Access Network"
    subnet_names = [
        "bootstrap_dhcp",
        "metallb_address_pool",
    ]

    # Start by resetting CAN reset network and vlans.
    can_vlan = can_data[0]
    can_ipv4_network = can_data[1]
    click.echo(
        f"    Using VLAN {can_vlan} and IPv4 network {can_ipv4_network} from --customer-access-network",
    )
    can = networks.get("CAN")
    can.ipv4_address(can_ipv4_network)
    for subnet in can.subnets().values():
        subnet.vlan(can_vlan)

    # This will overwrite the original CAN in the end
    clone_subnet_and_pivot(
        networks,
        source_network_name,
        destination_network_name,
        destination_network_full_name,
        subnet_names,
        preserve,
        overrides,
    )


def clone_subnet_and_pivot(
    networks,
    source_network_name,
    destination_network_name,
    destination_network_full_name,
    subnet_names=None,
    preserve=None,
    overrides=(),
):
    """Clone a network and swizzle some IPs with IPAM.

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
        source_network_name (str): Name of the network to clone
        destination_network_name (str): Name of the network to create
        destination_network_full_name (str): Long/Full name of the network to create
        subnet_names (list): Subnets in an ordered list to be cloned/expanded
        preserve (str): Network to preferentially preserve IP addresses whenc cloning
        overrides (str, ipaddress.IPv4Network): Tuple of tuples forcing subnet addressing
    """
    #
    # Pin ordering of subnet creation and override based on requested preservation
    # Really if IPAM were good and/or we didn't have to expect wonky data this wouldn't be required
    #
    if subnet_names is None:
        subnet_names = [
            "network_hardware",
            "bootstrap_dhcp",
            "metallb_address_pool",
            "metallb_static_pool",
        ]
    preserve_subnet = None
    if preserve == "external-dns":
        preserve_subnet = "metallb_static_pool"
        subnet_names = [
            s
            for s in subnet_names
            if s != preserve_subnet and s != "metallb_address_pool"
        ]
        subnet_names.insert(0, preserve_subnet)
        subnet_names.insert(1, "metallb_address_pool")
        click.echo(
            "    Attempting to preserve metallb_static pool subnet "
            f"{destination_network_name.lower()}_{preserve_subnet} to pin external-dns IPv4 address",
        )
    elif preserve == "ncns":
        preserve_subnet = "bootstrap_dhcp"
        subnet_names = [s for s in subnet_names if s != preserve_subnet]
        subnet_names.insert(0, preserve_subnet)
        click.echo("    Preserving bootstrap_dhcp subnet to pin NCN IPv4 addresses")

    #
    # Stub out the new network based on old network IPs.
    #
    old_network = networks.get(source_network_name)
    network_ipv4_address = old_network.ipv4_network()
    new_network = Network(destination_network_name, "ethernet", network_ipv4_address)
    new_network.full_name(destination_network_full_name)
    new_network.mtu(9000)
    new_network.ipv4_address(network_ipv4_address)

    #
    # Create new subnets
    #
    click.echo(f"    Creating subnets in the following order {subnet_names}")
    for subnet_name in subnet_names:
        #
        # Subnet naming
        #
        old_subnet_name = subnet_name
        new_subnet_name = subnet_name
        if "metallb" in subnet_name:
            old_subnet_name = f"{source_network_name.lower()}_{subnet_name}"
            new_subnet_name = f"{destination_network_name.lower()}_{subnet_name}"

        old_subnet_base_vlan = None
        old_subnet = old_network.subnets().get(old_subnet_name)
        if old_subnet is None:
            click.echo(
                f"    Subnet {old_subnet_name} not found, using HMN as template",
            )
            old_subnet = networks.get("HMN").subnets().get(old_subnet_name)
            # Grab the bootstrap_dhcp vlan from the original net because HMN is different
            old_subnet_base_vlan = list(
                dict.fromkeys([s.vlan() for s in old_network.subnets().values()]),
            )
            if old_subnet_base_vlan:
                old_subnet_base_vlan = old_subnet_base_vlan[0]

        #
        # Clone the old subnet and change naming
        #
        new_subnet = Subnet.subnet_from_sls_data(old_subnet.to_sls())
        if old_subnet.full_name().find("HMN") != -1:
            new_subnet.full_name(
                old_subnet.full_name().replace("HMN", f"{destination_network_name}"),
            )
        else:
            new_subnet.full_name(
                old_subnet.full_name().replace(
                    f"{source_network_name}",
                    f"{destination_network_name}",
                ),
            )
        new_subnet.name(new_subnet_name)
        for reservation in new_subnet.reservations().values():
            reservation.name(
                reservation.name().replace(
                    f"{source_network_name.lower()}-",
                    f"{destination_network_name.lower()}-",
                ),
            )
            reservation.name(
                reservation.name().replace(
                    f"-{source_network_name.lower()}",
                    f"-{destination_network_name.lower()}",
                ),
            )
            if reservation.aliases() is None:
                continue
            for i, alias in enumerate(reservation.aliases()):
                reservation.aliases()[i] = alias.replace(
                    f"-{source_network_name.lower()}",
                    f"-{destination_network_name.lower()}",
                )

        devices = len(new_subnet.reservations())
        new_subnet_prefixlen = prefixlength_from_hosts(devices)
        total_hosts_in_prefixlen = hosts_from_prefixlength(new_subnet_prefixlen)

        seed_subnet = [i[1] for i in overrides if i[0] == new_subnet_name]
        if not seed_subnet:
            #
            # Cheap trick to seed when subnetting when info is unknown
            #
            remaining_ipv4_addresses = free_ipv4_subnets(new_network)
            remaining_subnets_to_process = len(subnet_names) - len(
                new_network.subnets(),
            )

            seed_subnet = sorted(
                remaining_ipv4_addresses,
                key=prefixlength,
                reverse=False,
            )[0]
            if len(remaining_ipv4_addresses) < remaining_subnets_to_process:
                click.echo(
                    "    Calculating seed/start prefix based on devices in case no further guidance is given\n"
                    "        INFO:  Overrides may be provided on the command line with --<can|cmn>-subnet-override.",
                )
                prefix_delta = new_subnet_prefixlen - seed_subnet.prefixlen
                seed_subnet = list(seed_subnet.subnets(prefix_delta))[0]
        else:
            click.echo(
                f"    Subnet {new_subnet_name} was assigned {seed_subnet[0]} from the command command line.",
            )
            seed_subnet = seed_subnet[0]

        #
        # (Largely) message about what the subnet IPv4 addressing is from.
        #
        if subnet_name == preserve_subnet:
            if new_subnet.ipv4_network() == network_ipv4_address:
                click.secho(
                    f"    WARNING: Subnet {new_subnet_name} takes entire network range (supernet hack). "
                    f"Cannot preserve as requested.",
                    fg="yellow",
                )
                click.echo(
                    "        INFO:  Overrides may be provided on the command line with --<can|cmn>-subnet-override.",
                )
                click.echo(f"    Creating {new_subnet_name} with {seed_subnet}")
                new_subnet.ipv4_address(seed_subnet)
            else:
                click.echo(
                    f"    Preserving {new_subnet_name} with {new_subnet.ipv4_network()}",
                )
        else:
            click.echo(f"    Creating {new_subnet_name} with {devices} devices:")
            click.echo(
                f"        A /{new_subnet_prefixlen} could work and would hold up to "
                f"{total_hosts_in_prefixlen} devices (including gateway)",
            )
            click.echo(
                f"        Using {seed_subnet} from {network_ipv4_address} that can hold up to "
                f"{hosts_from_prefixlength(seed_subnet.prefixlen)} devices (including gateway)",
            )

            # Change vlan if we scavenged subnet info from HMN
            if old_subnet_base_vlan is not None:
                click.echo(
                    f"        Using VLAN {old_subnet_base_vlan} to override templating from HMN",
                )
                new_subnet.vlan(old_subnet_base_vlan)

            # Prepare to re-IP the new subnet
            old_reservations = new_subnet.reservations()
            new_subnet.ipv4_gateway("0.0.0.0")
            new_subnet.reservations(defaultdict())

            # Re-IP the new subnet
            new_subnet.ipv4_address(seed_subnet)
            click.echo("        Adding gateway IP address")
            new_subnet.ipv4_gateway(next_free_ipv4_address(new_subnet))
            click.echo(
                f"        Adding IPs for {len(old_reservations.values())} Reservations",
            )
            for old in old_reservations.values():
                try:
                    new_subnet.reservations().update(
                        {
                            old.name(): Reservation(
                                old.name(),
                                next_free_ipv4_address(new_subnet),
                                list(old.aliases()),
                                old.comment(),
                            ),
                        },
                    )
                except IndexError:
                    click.secho(
                        "        HALTING: Insufficient IPv4 addresses to create Reservations "
                        f"- {devices} devices in a subnet supporting {total_hosts_in_prefixlen} devices.\n"
                        "             Expert mode --<can|cmn>-subnet-override must be used to change this behavior.",
                        fg="bright_yellow",
                    )
                    exit(1)

            # DHCP Ranges to appropriate networks
            try:
                if new_subnet.dhcp_start_address() is not None:
                    click.echo("        Setting DHCP Ranges")
                    new_subnet.dhcp_start_address(next_free_ipv4_address(new_subnet))
                if new_subnet.dhcp_end_address() is not None:
                    new_subnet.dhcp_end_address(last_free_ipv4_address(new_subnet))
            except IndexError:
                click.secho(
                    "        WARNING: Insufficient IPv4 addresses to create DHCP ranges "
                    f"- {devices} devices in a subnet supporting {total_hosts_in_prefixlen} devices.\n"
                    "             Expert mode --<can|cmn>-subnet-override may be used to change this behavior.",
                    fg="bright_yellow",
                )

        #
        # Add the new subnet to the network
        #
        new_network.subnets().update({new_subnet_name: new_subnet})

        remaining_subnets = [
            str(i) for i in sorted(free_ipv4_subnets(new_network), key=prefixlength)
        ]
        click.echo(f"    Remaining subnets: {remaining_subnets}")

    #
    # Grudgingly apply the supernet hack
    #
    for subnet in new_network.subnets().values():
        if subnet.name().find("metallb") != -1:
            continue
        click.echo(f"    Applying supernet hack to {subnet.name()}")
        subnet.ipv4_address(new_network.ipv4_address())
        subnet.ipv4_gateway(
            next_free_ipv4_address(
                Subnet("temp", new_network.ipv4_network(), "0.0.0.0", 1),
            ),
        )

    #
    # Add the new (cloned) network to the list
    #
    networks.update({new_network.name(): new_network})


def update_nmn_uai_macvlan_dhcp_ranges(networks):
    """Update the DHCP Start and End ranges for NMN mac_vlan subnet.

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
    """
    nmn_network = networks.get("NMN")
    uai_macvlan_subnet = nmn_network.subnets().get("uai_macvlan")
    if uai_macvlan_subnet is None:
        return

    click.secho(
        "Updating DHCP Start and End Ranges for uai_macvlan subnet in NMN network",
        fg="bright_white",
    )
    reservations = [
        x.ipv4_address() for x in uai_macvlan_subnet.reservations().values()
    ]
    dhcp_start = max(reservations) + 1
    dhcp_end = sorted(free_ipv4_addresses(uai_macvlan_subnet))[-1]
    uai_macvlan_subnet.reservation_start_address(dhcp_start)
    uai_macvlan_subnet.reservation_end_address(dhcp_end)

    click.secho(
        "Updating uai_macvlan subnet VLAN in NMN network",
        fg="bright_white",
    )
    nmn_vlan = nmn_network.subnets().get("bootstrap_dhcp").vlan()
    uai_macvlan_subnet.vlan(nmn_vlan)


def create_metallb_pools_and_asns(
    networks,
    bgp_asn,
    bgp_chn_asn,
    bgp_cmn_asn,
    bgp_nmn_asn,
):
    """Update the NMN and CMN by creating the BGP peering.

    Args:
        networks (sls_utils.Managers.NetworkManager): Dictionary of SLS networks
        bgp_asn (int): Remote peer BGP ASN
        bgp_chn_asn (int): Local CHN BGP ASN
        bgp_cmn_asn (int): Local CMN BGP ASN
        bgp_nmn_asn (int): Local NMN BGP ASN

    """
    click.secho(
        "Creating BGP peering ASNs and MetalLBPool names",
        fg="bright_white",
    )

    chn = networks.get("CHN")
    if chn is not None and None in chn.bgp():
        click.echo(
            f"    Updating the CHN network with BGP peering info MyASN: {bgp_chn_asn} and PeerASN: {bgp_asn}",
        )
        chn.bgp(bgp_chn_asn, bgp_asn)

    cmn = networks.get("CMN")
    if cmn is not None and None in cmn.bgp():
        click.echo(
            f"    Updating the CMN network with BGP peering info MyASN: {bgp_cmn_asn} and PeerASN: {bgp_asn}",
        )
        cmn.bgp(bgp_cmn_asn, bgp_asn)

    nmn = networks.get("NMN")
    if nmn is not None and None in nmn.bgp():
        click.echo(
            f"    Updating the NMN network with BGP peering info MyASN: {bgp_nmn_asn} and PeerASN: {bgp_asn}",
        )
        nmn.bgp(bgp_nmn_asn, bgp_asn)  # bgp(my_asn, peer_asn)

    metallb_subnet_name_map = {
        "can_metallb_address_pool": "customer-access",
        "chn_metallb_address_pool": "customer-high-speed",
        "cmn_metallb_address_pool": "customer-management",
        "cmn_metallb_static_pool": "customer-management-static",
        "hmn_metallb_address_pool": "hardware-management",
        "nmn_metallb_address_pool": "node-management",
    }

    for network in networks.values():
        for subnet in network.subnets().values():
            pool_name = metallb_subnet_name_map.get(subnet.name())
            if pool_name is None:
                continue
            click.echo(
                f"    Updating {subnet.name()} subnet in the {network.name()} network with MetalLBPoolName {pool_name}",
            )
            subnet.metallb_pool_name(pool_name)
