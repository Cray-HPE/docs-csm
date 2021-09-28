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
"""Wrapper Classes to manage SLS Networks and Subnets as dictionaries."""
from collections import UserDict
import ipaddress
import os

from sls_utils.json_utils import validate as validate_sls_json
from sls_utils.Networks import Network, Subnet


class NetworkManager(UserDict):
    """Provide a means to search and set SLS Network info."""

    def __init__(self, network_dict=[]):
        """Create a Network Manager.

        Args:
            network_dict (dict): A dictionary of networks to manage

        Raises:
            TypeError: When subnet_dict is not a dictionary
        """
        if not isinstance(network_dict, dict):
            raise TypeError(
                "SLSNetworkManager requires an SLS Networks dictionary for initialization.",
            )

        self.__validate(network_dict)
        # TODO: if instance is network do a deep copy!
        self.data = {
            name: (
                network
                if isinstance(network, Network)
                else Network.network_from_sls_data(network)
            )
            for name, network in network_dict.items()
        }

    def get(self, key):
        """Override dict get to search by Name or IP address.

        Args:
            key (str): Name or IPv4 address of the Network to find.

        Returns:
            value (sls_utils.Network): Network or None which has the Name or IPv4 address
        """
        value = self.data.get(key)
        if not value:
            value = self.get_by_ipv4_address(key)
        return value

    def get_by_ipv4_address(self, key):
        """Search List for network by IP address.

        Args:
            key (str): IPv4 address to search for in the network

        Returns:
            value (sls_utils.Network): Network or None which has the IPv4 address
        """
        value = None
        try:
            ipv4_key = ipaddress.IPv4Interface(key)
        except ValueError:
            return value

        for network in self.data.values():
            if network.ipv4_address() == ipv4_key:
                value = network
                break
        return value

    def to_sls(self):
        """Return full SLS Networks Schema-validated JSON.

        Returns:
            sls: SLS data structure for the dictionary of Networks
        """
        sls = {name: network.to_sls() for name, network in self.data.items()}
        self.__validate(sls)
        return sls

    def __validate(self, sls_data):
        """Validate SLS Networks with JSON schema.

        Args:
            sls_data: SLS data structure to schema validate
        """
        schema_file = "sls_networks_schema.json"

        schema_dir = os.path.dirname(os.path.realpath(__file__)) + "/schemas/"
        schema_file = schema_dir + schema_file
        validate_sls_json(schema_file=schema_file, sls_data=sls_data)


class SubnetManager(UserDict):
    """A SubnetManager is a convenience wrapper around Subnets."""

    def __init__(self, subnet_dict=[]):
        """Create a Subnet Manager.

        Args:
            subnet_dict (dict): A dictionary of subnets to manage

        Raises:
            TypeError: When subnet_dict is not a dictionary
        """
        if not isinstance(subnet_dict, dict):
            raise TypeError("SubnetManager requires dictionary for initialization.")

        self.__validate(subnet_dict)
        self.data = {
            name: (
                subnet
                if isinstance(subnet, Subnet)
                else Subnet.subnet_from_sls_data(subnet)
            )
            for (name, subnet) in subnet_dict.items()
        }

    def get(self, key):
        """Override Dict get to search by Name or IP address.

        Args:
            key (str): Name of IPv4 address of the subnet to find

        Returns:
            value (sls_utils.Subnet): Subnet, or None which has the name or IPv4 address
        """
        value = self.data.get(key)
        if not value:
            value = self.get_by_ipv4_address(key)
        return value

    def get_by_ipv4_address(self, key):
        """Search List for network by IP address.

        Args:
            key (str): IPv4 address to find in the subnets

        Returns:
            value (sls_utils.Subnet): Subnet which has the IPv4 address or None
        """
        value = None
        try:
            ipv4_key = ipaddress.IPv4Interface(key)
        except ValueError:
            return value

        for subnet in self.data.values():
            if subnet.ipv4_address() == ipv4_key:
                value = subnet
                break
        return value

    def to_sls(self):
        """Return full SLS Networks JSON.

        Returns:
            sls: SLS subnet data structure
        """
        sls = {name: subnet.to_sls() for name, subnet in self.data.items()}
        self.__validate(sls)
        return sls

    def __validate(self, sls_data):
        """Validate SLS Subnets with JSON schema.

        Args:
            sls_data: SLS Subnet data to schema validate
        """
        schema_file = "sls_subnets_schema.json"

        schema_dir = os.path.dirname(os.path.realpath(__file__)) + "/schemas/"
        schema_file = schema_dir + schema_file
        validate_sls_json(schema_file=schema_file, sls_data=sls_data)
