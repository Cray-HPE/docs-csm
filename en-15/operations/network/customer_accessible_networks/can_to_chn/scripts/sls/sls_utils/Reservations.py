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
"""Class for managing SLS Reservations."""
import ipaddress


class Reservation:
    """Name, IPv4 address and list of aliases to create A Records and CNAMEs."""

    def __init__(self, name, ipv4_address, aliases=list, comment=""):
        """Create a Reservation class.

        Args:
            name (str): Name of the reservation
            ipv4_address (str): IPv4 address of the reservation
            aliases (list): List of strings for reservation alternate names
            comment (str): Arbitrary comment on the reservation
        """
        self.__name = name
        self.__ipv4_address = ipaddress.IPv4Address(ipv4_address)
        self.__aliases = aliases
        self.__comment = comment

    def name(self, reservation_name=None):
        """Hostname or A Record name.

        Args:
            reservation_name (str): Name of the reservation

        Returns:
            name (str): Name of the reservation
        """
        if reservation_name:
            self.__name = reservation_name
        return self.__name

    def ipv4_address(self, reservation_ipv4_address=None):
        """IPv4 Address of the host.

        Args:
            reservation_ipv4_address: IPv4 address of the reservation

        Returns:
            ipv4_address (ipaddress.IPv4Address):  IPv4 CIDR of the reservation.
        """
        if reservation_ipv4_address:
            self.__ipv4_address = ipaddress.IPv4Address(reservation_ipv4_address)
        return self.__ipv4_address

    def comment(self, reservation_comment=None):
        """Arbitrary descriptive text.

        Args:
            reservation_comment (str): Arbitrary comment for a reservation

        Returns:
            comment (str): Arbitrary comment on a reservation.
        """
        if reservation_comment:
            self.__comment = reservation_comment
        return self.__comment

    def aliases(self, reservation_aliases=None):
        """Alternate or CNAMEs for the IP reservation.

        Args:
            reservation_aliases (list): List of reservation dictionaries

        Returns:
            aliases (list): List of sls reservation aliases
        """
        if reservation_aliases:
            self.__aliases = reservation_aliases
        return self.__aliases

    def to_sls(self):
        """Serialize the reservation to an SLS Reservation structure.

        Returns:
            sls: SLS data structure for reservations
        """
        sls = {
            "Name": self.__name,
            "IPAddress": str(self.__ipv4_address),
        }
        if self.__aliases:
            sls.update({"Aliases": [str(a) for a in self.__aliases]})
        if self.__comment is not None:
            sls.update({"Comment": str(self.__comment)})

        return sls
