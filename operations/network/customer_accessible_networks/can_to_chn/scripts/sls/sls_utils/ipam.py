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
"""Extremely rudimentary and purpose-driven IPAM."""
import ipaddress
import math

from sls_utils.Networks import Network, Subnet

# TODO: better log flagging
DEBUG = False


def free_ipv4_subnets(network):
    """Return available subnets not currently in used by the network.

    WARNING:  Use only in and around the CAN.  Other networks have untested corner cases!

    Args:
        network (sls_utils.Network): SLS Networks object

    Returns:
        free_subnets (list): Remaining subnets not used out of the network

    Raises:
        ValueError: If input is not a Network
        Exception: If subnets overlap or intersections are not found
    """
    if not isinstance(network, Network):
        raise ValueError(f"{free_ipv4_subnets.__name__} argument must be a Network")

    subnets = network.subnets()
    if subnets is None:
        return None

    if DEBUG:
        print("NETWORK: ", network.name(), network.ipv4_network())
    available_subnets = [ipaddress.IPv4Network(network.ipv4_network())]

    # Ensure smallest sized subnets are first (and thus first matched)
    subnets = sorted(subnets.values(), key=prefixlength, reverse=True)
    if DEBUG:
        print("SORTED SUBNETS: ", [x.ipv4_network() for x in subnets])

    for subnet in subnets:
        used_subnet = subnet.ipv4_network()

        temp_subnet = is_supernet_hacked(network.ipv4_network(), subnet)
        if temp_subnet is not None:
            used_subnet = temp_subnet
        if DEBUG:
            print(
                "Subnet:  ",
                subnet.name(),
                used_subnet,
                "orig:",
                subnet.ipv4_address(),
                subnet.ipv4_network(),
            )

        found = False
        for i in range(len((available_subnets))):
            try:
                if not used_subnet.subnet_of(available_subnets[i]):
                    found = False
                    continue
            except AttributeError:
                if not temp_is_subnet_of(used_subnet, available_subnets[i]):
                    found = False
                    continue

            found = True
            if DEBUG:
                print("FOUND:  ", used_subnet, "is subnet of", available_subnets[i])
            new_subnets = list(available_subnets[i].address_exclude(used_subnet))
            if DEBUG:
                print("    new_subnets: ", new_subnets)
            available_subnets.pop(i)
            available_subnets += new_subnets
            available_subnets.sort(
                key=prefixlength,
                reverse=True,
            )  # Use the smallest block possible
            if DEBUG:
                print("    final:  ", available_subnets)
            break
        if not found:
            raise Exception(
                "An appropriate subnet could not be found. "
                "Often this is overlapping subnets or a subnet outside the network.",
            )

    if DEBUG:
        print("Remaining: ", available_subnets)

    return available_subnets


def free_ipv4_addresses(subnet):
    """Return a set of available IPv4 addresses not currently used in a subnet.

    NOTICE:  This function ignores DHCP Ranges / Pools in the subnet which likely
             need recalculation.

    Args:
        subnet (sls_utils.Subnet): SLS Subnet object

    Returns:
        free_ips (set): Remaining IP addresses not used in the network (unordered)

    Raises:
        ValueError: If input is not a Subnet
    """
    if not isinstance(subnet, Subnet):
        raise ValueError(f"{__name__} argument must be a Subnet")

    subnet_ipv4_network = subnet.ipv4_network()

    # Every available IPv4 address in the subnet
    all_hosts_in_subnet = list(subnet_ipv4_network.hosts())
    all_hosts_in_subnet = set(all_hosts_in_subnet)

    # All the IPv4 addresses used in the subnet by Reservations
    reservations = subnet.reservations().values()
    all_used_hosts_in_subnet = set({r.ipv4_address() for r in reservations})
    all_used_hosts_in_subnet.add(subnet.ipv4_gateway())

    # Available IPv4 addresses in the subnet
    unused_hosts_in_subnet = all_hosts_in_subnet.difference(all_used_hosts_in_subnet)

    return unused_hosts_in_subnet


def next_free_ipv4_address(subnet, requested_ipv4_address=None):
    """Return a set of available IPv4 addresses not currently used in a subnet.

    Args:
        subnet (sls_utils.Subnet): An SLS Subnet object
        requested_ipv4_address (str): A requested IPv4 address

    Returns:
        next_free_ip (ipaddress.IPv4Network): Remaining IP addresses not used in the network

    Raises:
        ValueError: If input is not a Subnet
    """
    if not isinstance(subnet, Subnet):
        raise ValueError(f"{__name__} argument must be a Subnet")

    if isinstance(requested_ipv4_address, str):
        requested_ipv4_address = ipaddress.IPv4Address(requested_ipv4_address)

    next_free_ip = None
    free_ips = free_ipv4_addresses(subnet)
    if requested_ipv4_address is not None:
        pass
    else:
        next_free_ip = sorted(free_ips)[0]

    return next_free_ip


def last_free_ipv4_address(subnet, requested_ipv4_address=None):
    """Return a set of available IPv4 addresses not currently used in a subnet.

    Args:
        subnet (sls_utils.Subnet): An SLS Subnet object
        requested_ipv4_address (str): A requested IPv4 address

    Returns:
        next_free_ip (ipaddress.IPv4Network): Remaining IP addresses not used in the network

    Raises:
        ValueError: If input is not a Subnet
    """
    if not isinstance(subnet, Subnet):
        raise ValueError(f"{__name__} argument must be a Subnet")

    if isinstance(requested_ipv4_address, str):
        requested_ipv4_address = ipaddress.IPv4Address(requested_ipv4_address)

    last_free_ip = None
    free_ips = free_ipv4_addresses(subnet)
    if requested_ipv4_address is not None:
        pass
    else:
        last_free_ip = sorted(free_ips)[-1]

    return last_free_ip


def is_supernet_hacked(network_address, subnet):
    """Determine if a subnet has the supernet hack applied.

    Args:
        network_address (ipaddress.IPv4Network): Address of the network the subnet is in
        subnet (sls_utils.Subnet): The subnet in question

    Returns:
        None if the supernet hack has not been applied, or an "unhacked" subnet IPv4 network.

    This is some mix of heuristics from cray-site-init and black magic.  The supernet hack was
    applied to subnets in order for NCNs to be on the same "subnet" as the network hardware.  The
    hack is to apply the network prefix (CIDR mask) and gateway to the subnet.

    Once the supernet hack is applied there is a fundamental loss of information, so detecting and
    correcting a supernet hack in a subnet is very difficult unless other information can be found.

    Additional information is found from cray-site-init:
    * The supernet hack is only applied to the HMN, NMN, CMN and MTL networks.
    * A supernet-like hack is applied to the CAN.
    * The supernet hack is only applied to bootstrap_dhcp, network_hardware, can_metallb_static_pool,
     and can_metallb_address_pool subnets
    * default network hardware netmask = /24
    * default bootstrap dhcp netmask = /24

    The most important heuristic indicator of the supernet hack is if a subnet has the same netmask
    as its containing network then the supernet.

    With all this information applied it is still hard to reverse the hack - particularly selecting
    the original network prefix (CIDR mask).  NOTE: This function may pick a subnet that is too small.
    """
    # A clear clue as to the application of the supernet hack is where the subnet
    # mask is the same as the network mask.
    if subnet.ipv4_network().prefixlen != network_address.prefixlen:
        return None

    used_addrs = [r.ipv4_address() for r in subnet.reservations().values()]

    if subnet.dhcp_start_address() is not None:
        used_addrs.append(subnet.dhcp_start_address())
    if subnet.dhcp_end_address() is not None:
        used_addrs.append(subnet.dhcp_end_address())

    if not used_addrs:
        return None

    min_ipv4 = min(used_addrs)
    max_ipv4 = max(used_addrs)
    print("ORIG SUBNET: ", subnet.name(), subnet.ipv4_address(), subnet.ipv4_network())
    print("MIN and MAX IP: ", min_ipv4, max_ipv4)
    print(
        "PREFIXES SAME: ",
        subnet.ipv4_network().prefixlen == network_address.prefixlen,
    )
    # The following are from cray-site-init where the supernet hack is applied.
    core_subnets = ["bootstrap_dhcp", "network_hardware"]
    static_pool_subnets = ["can_metallb_static_pool"]
    dynamic_pool_subnets = ["can_metallb_address_pool"]
    supernet_hacked_pools = core_subnets + static_pool_subnets + dynamic_pool_subnets

    # Do not apply the reverse hackology for subnets in CSI it is not applied
    if subnet.name() not in supernet_hacked_pools:
        return None

    # Subnet masks found in CSI for different subnets. This prevents reverse
    # engineering very small subnets based on number of hosts and dhcp ranges alone.
    prefix_diff = 30
    if subnet.name() in core_subnets:
        prefix_diff = 24
    elif subnet.name() in static_pool_subnets:
        prefix_diff = 28
    elif subnet.name() in dynamic_pool_subnets:
        prefix_diff = 27
    print("PREFIXLEN: ", prefix_diff)
    prefix_diff -= network_address.prefixlen

    subnet_ipv4_address = None
    for level in range(prefix_diff, 0, -1):
        if subnet_ipv4_address is not None:
            break
        blocks = list(network_address.subnets(prefixlen_diff=level))
        for block in blocks:
            if min_ipv4 in block and max_ipv4 in block:
                subnet_ipv4_address = block
                subnet_gateway = list(block.hosts())[0]
                print("CATCH: ", subnet_ipv4_address, "in", blocks)
                print("    address: ", subnet_ipv4_address)
                print("    gateway: ", subnet_gateway)
                break

    if subnet_ipv4_address != network_address:
        print("SUPERNET HACK FOUND!!!")

    return subnet_ipv4_address


def prefixlength(network):
    """CIDR mask or Prefix from a Network, Subnet or address.

    Args:
        network (ipaddress.IPv4Network|sls_utils.Networks.Network): Object to find the prefix length

    Returns:
        Prefix length or None
    """
    if isinstance(network, ipaddress.IPv4Network):
        return network.prefixlen
    if isinstance(network, Network):
        return network.ipv4_network().prefixlen


def temp_is_subnet_of(a, b):
    """Test if a is a subnet of b.

    Workaround for python versions < 3.7

    Args:
        a (ipaddress.IPv4Network): The proposed inside network
        b (ipaddress.IPv4Network): The outside network

    Returns:
        True if a is a subnet of b, else False

    Raises:
        TypeError: If both addresses are not IPv4 or both are not IPv6
    """
    try:
        # Always false if one is v4 and the other is v6.
        if a._version != b._version:
            raise TypeError(f"{a} and {b} are not of the same version")
        return (
            b.network_address <= a.network_address
            and b.broadcast_address >= a.broadcast_address  # noqa W503
        )
    except AttributeError:  # noqa
        raise TypeError(
            f"Unable to test subnet containment " f"between {a} and {b}",
        )  # noqa


def prefixlength_from_hosts(num_hosts):
    """Calculate the minimum prefix length of a network that can contain a given number of hosts.

    Args:
        num_hosts (int): Number of hosts to find the encapsulating prefix length.

    Returns:
        prefixlength (int):  The minimum prefix length encapsulating the given number of hosts
    """
    prefixlen = 32 - math.ceil(math.log2(num_hosts + 2))
    return prefixlen


def hosts_from_prefixlength(prefixlength):
    """Calculate the number of hosts supported for a given prefix length.

    Args:
        prefixlength (int): CIDR mask to find the number of supported hosts.

    Returns:
        hosts (int):  The number of hosts in a subnet the size of a given prefix length (minus net and bcast).
    """
    hosts = math.pow(2, 32 - prefixlength) - 2
    return int(hosts)
