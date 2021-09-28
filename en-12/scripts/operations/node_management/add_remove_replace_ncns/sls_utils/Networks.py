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
"""Classes for management of SLS Networks and Subnets."""
from collections import defaultdict
import ipaddress

from .Reservations import Reservation

# A Subnet is a Network inside a Network CIDR range.
# A Subnet has IP reservations, a network does not
# https://mypy.readthedocs.io/en/stable/cheat_sheet_py3.html


class Network:
    """Represent a Network from and SLS data structure."""

    def __init__(self, name, network_type, ipv4_address):
        """Create a Network.

        Args:
            name (str): Short name of the network
            network_type (str): Type of the network: ethernet, etc.
            ipv4_address: (str): IPv4 CIDR of the network
        """
        self._name = name
        self._full_name = ""
        self._ipv4_address = ipaddress.IPv4Interface(ipv4_address)  # IPRanges

        self.__type = network_type
        self.__mtu = None
        self.__subnets = defaultdict()
        self.__bgp_asns = [None, None]  # [MyASN, PeerASN]

    @classmethod
    def network_from_sls_data(cls, sls_data):
        """Construct Network and any data-associated Subnets from SLS data.

        Args:
            sls_data: SLS data structure used to construct the network

        Returns:
            cls: Network object constructed from the SLS data structure
        """
        # "Promote" any ExtraProperties in Networks to ease initialization.
        if sls_data.get("ExtraProperties"):
            for key, value in sls_data["ExtraProperties"].items():
                sls_data[key] = value
            del sls_data["ExtraProperties"]

        # Cover specialty network(s)
        if sls_data.get("Name") == "BICAN":
            sls_network = BicanNetwork(
                default_route_network_name=sls_data.get("SystemDefaultRoute", "CMN"),
            )
        else:
            # Cover regular networks
            sls_network = cls(
                name=sls_data.get("Name"),
                network_type=sls_data.get("Type"),
                ipv4_address=sls_data.get("CIDR"),
            )

        sls_network.full_name(sls_data.get("FullName"))

        # Check that the CIDR is in the IPRange, if IPRange exists.
        ipv4_range = sls_data.get("IPRanges")
        if ipv4_range and len(ipv4_range) > 0:
            temp_address = ipaddress.IPv4Interface(ipv4_range[0])
            if temp_address != sls_network.ipv4_address():
                print(f"WARNING: CIDR not in IPRanges from input {sls_network.name()}.")

        sls_network.mtu(sls_data.get("MTU"))

        subnets = sls_data.get("Subnets", defaultdict())
        for subnet in subnets:
            new_subnet = Subnet.subnet_from_sls_data(subnet)
            sls_network.subnets().update({new_subnet.name(): new_subnet})

        sls_network.bgp(sls_data.get("MyASN", None), sls_data.get("PeerASN"))

        return sls_network

    def name(self, network_name=None):
        """Short name of the network.

        Args:
            network_name (str): Short name of the network for the setter

        Returns:
            name (str): Short name of the network for the getter
        """
        if network_name is not None:
            self._name = network_name
        return self._name

    def full_name(self, network_name=None):
        """Long, descriptive name of the network.

        Args:
            network_name (str): Full Name of the network for the setter

        Returns:
            full_name (str): Full name of the network for the getter
        """
        if network_name is not None:
            self._full_name = network_name
        return self._full_name

    def ipv4_address(self, network_address=None):
        """IPv4 network addressing.

        Args:
            network_address: IPv4 address of the network for the setter

        Returns:
            ipv4_address: IPv4 address of the network for the getter
        """
        if network_address is not None:
            self._ipv4_address = ipaddress.IPv4Interface(network_address)
        return self._ipv4_address

    def ipv4_network(self):
        """IPv4 network of the CIDR, Ranges, etc.

        Returns:
            ipv4_address.network: IPv4 network address of the Network.
        """
        return self._ipv4_address.network

    def mtu(self, network_mtu=None):
        """MTU of the network.

        Args:
            network_mtu (int): MTU of the network for the setter

        Returns:
            mtu (int): MTU of the network for the getter
        """
        if network_mtu is not None:
            self.__mtu = network_mtu
        return self.__mtu

    def type(self, network_type=None):
        """Ethernet or specialty type of the network.

        Args:
            network_type (str): Type of the network (ethernet or otherwise) for the setter

        Returns:
            type (str): Type of the network for the getter
        """
        if network_type is not None:
            self.__type = network_type
        return self.__type

    def subnets(self, network_subnets=None):
        """List of subnet objects in the network.

        Args:
            network_subnets: A dict of subnets in the network for the setter

        Returns:
            subnets: A dict of subnets in the network for the getter
        """
        if network_subnets is not None:
            self.__subnets = network_subnets
        return self.__subnets

    def bgp(self, my_bgp_asn=None, peer_bgp_asn=None):
        """Network BGP peering properties (optional).

        Args:
            my_bgp_asn (int): Local BGP ASN for setter
            peer_bgp_asn (int): Remote BGP ASN for setter

        Returns:
            bgp_asns (list): List containing local and peer BGP ASNs [MyASN, PeerASN]
        """
        if my_bgp_asn is not None:
            self.__bgp_asns[0] = my_bgp_asn
        if peer_bgp_asn is not None:
            self.__bgp_asns[1] = peer_bgp_asn
        return self.__bgp_asns

    def to_sls(self):
        """Serialize the Network to SLS Networks format.

        Returns:
            sls: SLS data structure for the network
        """
        subnets = [x.to_sls() for x in self.__subnets.values()]
        # TODO:  Is the VlanRange a list of used or a min/max?
        # x vlans = [min(vlans_list), max(vlans_list)]
        vlans_list = list(dict.fromkeys([x.vlan() for x in self.__subnets.values()]))
        vlans = vlans_list
        sls = {
            "Name": self._name,
            "FullName": self._full_name,
            "Type": self.__type,
            "IPRanges": [str(self._ipv4_address)],
            "ExtraProperties": {
                "CIDR": str(self._ipv4_address),
                "MTU": self.__mtu,
                "VlanRange": vlans,
                "Subnets": subnets,
            },
        }

        if self.__bgp_asns[0] and self.__bgp_asns[1]:
            sls["ExtraProperties"]["MyASN"] = self.__bgp_asns[0]
            sls["ExtraProperties"]["PeerASN"] = self.__bgp_asns[1]

        return sls


class BicanNetwork(Network):
    """A customized BICAN Network."""

    def __init__(self, default_route_network_name="CMN"):
        """Create a new BICAN network.

        Args:
            default_route_network_name (str): Name of the user network for BICAN
        """
        super().__init__(
            name="BICAN",
            network_type="ethernet",
            ipv4_address="0.0.0.0/0",
        )
        self._full_name = "System Default Route Network Name for Bifurcated CAN"
        self.__system_default_route = default_route_network_name
        self.mtu(network_mtu=9000)

    def system_default_route(self, default_route_network_name):
        """Retrieve or set the default route network name.

        Args:
            default_route_network_name (str): Name of the BICAN network path [CMN, CAN, CHN] for setter

        Returns:
            system_default_route (str): Name of the BICAN network path
        """
        if default_route_network_name in ["CMN", "CAN", "CHN"]:
            self.__system_default_route = default_route_network_name
        return self.__system_default_route

    def to_sls(self):
        """Serialize the Network to SLS Networks format.

        Returns:
            sls: BICAN SLS Network structure
        """
        sls = super().to_sls()
        sls["ExtraProperties"]["SystemDefaultRoute"] = self.__system_default_route
        return sls


class Subnet(Network):
    """Subnets are Networks with extra metadata: DHCP info, IP reservations, etc..."""

    def __init__(self, name, ipv4_address, ipv4_gateway, vlan):
        """Create a new Subnet.

        Args:
            name (str): Name of the subnet
            ipv4_address (str): IPv4 CIDR of the subnet
            ipv4_gateway (str): IPv4 address of the network gateway
            vlan (int): VLAN ID of the subnet
        """
        super().__init__(name=name, network_type=None, ipv4_address=ipv4_address)
        self.__ipv4_gateway = ipaddress.IPv4Address(ipv4_gateway)
        self.__vlan = int(vlan)
        self.__ipv4_dhcp_start_address = None
        self.__ipv4_dhcp_end_address = None
        self.__ipv4_reservation_start_address = None
        self.__ipv4_reservation_end_address = None
        self.__pool_name = None
        self.__reservations = {}

    @classmethod
    def subnet_from_sls_data(cls, sls_data):
        """Create a Subnet from SLS data via a factory method.

        Args:
            sls_data (dict): Dictionary of Subnet SLS data

        Returns:
            cls (sls_utils.Subnet): Subnet constructed from SLS data
        """
        sls_subnet = cls(
            name=sls_data.get("Name"),
            ipv4_address=sls_data.get("CIDR"),
            ipv4_gateway=sls_data.get("Gateway"),
            vlan=sls_data.get("VlanID"),
        )

        sls_subnet.ipv4_gateway(ipaddress.IPv4Address(sls_data.get("Gateway")))
        if sls_subnet.ipv4_gateway() not in sls_subnet.ipv4_network():
            print(
                f"WARNING: Gateway not in Subnet for {sls_subnet.name()} (possibly supernetting).",
            )

        sls_subnet.full_name(sls_data.get("FullName"))
        sls_subnet.vlan(sls_data.get("VlanID"))

        dhcp_start = sls_data.get("DHCPStart")
        if dhcp_start:
            dhcp_start = ipaddress.IPv4Address(dhcp_start)
            if dhcp_start not in sls_subnet.ipv4_network():
                print("ERROR: DHCP start not in Subnet.")
            sls_subnet.dhcp_start_address(dhcp_start)

        dhcp_end = sls_data.get("DHCPEnd")
        if dhcp_end:
            dhcp_end = ipaddress.IPv4Address(dhcp_end)
            if dhcp_end not in sls_subnet.ipv4_network():
                print("ERROR: DHCP end not in Subnet.")
            sls_subnet.dhcp_end_address(dhcp_end)

        reservation_start = sls_data.get("ReservationStart")
        if reservation_start is not None:
            reservation_start = ipaddress.IPv4Address(reservation_start)
            sls_subnet.reservation_start_address(reservation_start)

        reservation_end = sls_data.get("ReservationEnd")
        if reservation_end is not None:
            reservation_end = ipaddress.IPv4Address(reservation_end)
            sls_subnet.reservation_end_address(reservation_end)

        pool_name = sls_data.get("MetalLBPoolName")
        if pool_name is not None:
            sls_subnet.metallb_pool_name(pool_name)

        reservations = sls_data.get("IPReservations", {})
        for reservation in reservations:
            sls_subnet.reservations().update(
                {
                    reservation.get("Name"): Reservation(
                        name=reservation.get("Name"),
                        ipv4_address=reservation.get("IPAddress"),
                        aliases=list(reservation.get("Aliases", [])),
                        comment=reservation.get("Comment"),
                    ),
                },
            )

        return sls_subnet

    def vlan(self, subnet_vlan=None):
        """VLAN of the subnet.

        Args:
            subnet_vlan (int): Subnet VLAN ID for the setter

        Returns:
            vlan (int): Subnet VLAN ID for the getter
        """
        if subnet_vlan is not None:
            self.__vlan = subnet_vlan
        return self.__vlan

    def ipv4_gateway(self, subnet_ipv4_gateway=None):
        """IPv4 Gateway of the subnet.

        Args:
            subnet_ipv4_gateway (str): IPv4 gateway of the subnet for the setter

        Returns:
            ipv4_gateway (xxx): IPv4 gateway of the subnet for the getter
        """
        if subnet_ipv4_gateway is not None:
            self.__ipv4_gateway = subnet_ipv4_gateway
        return self.__ipv4_gateway

    def dhcp_start_address(self, subnet_dhcp_start_address=None):
        """IPv4 starting address if DHCP is used in the subnet.

        Args:
            subnet_dhcp_start_address (str): IPv4 start of the DHCP range for setter

        Returns:
            ipv4_dhcp_start_address (ipaddress.IPv4Address): Start DHCP address for getter
        """
        if subnet_dhcp_start_address is not None:
            self.__ipv4_dhcp_start_address = ipaddress.IPv4Address(
                subnet_dhcp_start_address,
            )
        return self.__ipv4_dhcp_start_address

    def dhcp_end_address(self, subnet_dhcp_end_address=None):
        """IPv4 ending address if DHCP is used in the subnet.

        Args:
            subnet_dhcp_end_address (str): IPv4 end of the DHCP range for setter

        Returns:
            ipv4_dhcp_end_address (ipaddress.IPv4Address): End DHCP address for getter
        """
        if subnet_dhcp_end_address is not None:
            self.__ipv4_dhcp_end_address = ipaddress.IPv4Address(
                subnet_dhcp_end_address,
            )
        return self.__ipv4_dhcp_end_address

    def reservation_start_address(self, reservation_start=None):
        """IPv4 starting address used in uai_macvlan subnet.

        Args:
            reservation_start (ipaddress.IPv4Address): Start address of the reservations

        Returns:
            ipv4_reservation_start_address (ipaddress.IPv4Address): Start address of the reservation
        """
        if reservation_start is not None:
            self.__ipv4_reservation_start_address = ipaddress.IPv4Address(
                reservation_start,
            )
        return self.__ipv4_reservation_start_address

    def reservation_end_address(self, reservation_end=None):
        """IPv4 ending address used in uai_macvlan subnet.

        Args:
            reservation_end (ipaddress.IPv4Address): Start address of the reservations

        Returns:
            ipv4_reservation_end_address (ipaddress.IPv4Address): Start address of the reservation
        """
        if reservation_end is not None:
            self.__ipv4_reservation_end_address = ipaddress.IPv4Address(reservation_end)
        return self.__ipv4_reservation_end_address

    def metallb_pool_name(self, pool_name=None):
        """Retrieve or set the MetalLBPool name for the network (optional).

        Args:
            pool_name (str): Name of the MetalLBPool (optional)

        Returns:
            pool_name (str|None): Name of the MetalLBPool (or None)
        """
        if pool_name is not None:
            self.__pool_name = pool_name
        return self.__pool_name

    def reservations(self, subnet_reservations=None):
        """List of reservations for the subnet.

        Args:
            subnet_reservations (list): List of reservations for setter

        Returns:
            reservations (list): Lit of reservations for getter
        """
        if subnet_reservations is not None:
            self.__reservations = subnet_reservations
        return self.__reservations

    def to_sls(self):
        """Return SLS JSON for each Subnet.

        Returns:
            sls: SLS subnet data structure
        """
        sls = {
            "Name": self._name,
            "FullName": self._full_name,
            "CIDR": str(self._ipv4_address),
            "Gateway": str(self.__ipv4_gateway),
            "VlanID": self.__vlan,
        }

        if self.__ipv4_dhcp_start_address and self.__ipv4_dhcp_end_address:
            dhcp = {
                "DHCPStart": str(self.__ipv4_dhcp_start_address),
                "DHCPEnd": str(self.__ipv4_dhcp_end_address),
            }
            sls.update(dhcp)

        if (
            self.__ipv4_reservation_start_address is not None
            and self.__ipv4_reservation_end_address is not None  # noqa W503
        ):
            range = {
                "ReservationStart": str(self.__ipv4_reservation_start_address),
                "ReservationEnd": str(self.__ipv4_reservation_end_address),
            }
            sls.update(range)

        if self.__pool_name is not None:
            sls.update({"MetalLBPoolName": self.__pool_name})

        if self.__reservations:
            reservations = {
                "IPReservations": [x.to_sls() for x in self.__reservations.values()],
            }
            sls.update(reservations)
        return sls
