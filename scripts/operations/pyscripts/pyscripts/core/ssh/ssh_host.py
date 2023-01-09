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

import getpass
import socket
import re

class SshHost:
    """
    Maintains details about an SSH Host.
    """

    def __init__(self, hostname, username, rawdata = None, domain_suffix = None):
        if rawdata:
            self.parent = rawdata["Parent"]
            self.xname = rawdata["Xname"]
            self.type = rawdata["Type"]
            self.clazz = rawdata["Class"]
            self.type_string = rawdata["TypeString"]
            self.last_updated = rawdata["LastUpdated"]
            self.last_updated_time = rawdata["LastUpdatedTime"]
            self.rawdata = rawdata;

        self.hostname = hostname
        self.username = username
        self.password = None
        self.state = None
        self.no_password_needed = False
        self.domain_suffix = domain_suffix
        self.original_host = None

    def get_password(self, reset_cached = False):
        """
        Gets the cached password, and if not cached, asks the user using getpass.
        """
        password = self.password
        no_password_needed = self.no_password_needed
        if self.original_host:
            password = self.original_host.password
            no_password_needed = self.original_host.no_password_needed

        if reset_cached or (not password and not no_password_needed):
            password = getpass.getpass('%s password (leave blank and hit Enter if not using password): ' % self.hostname)

            if self.original_host:
                self.original_host.password = password

                if not password:
                    self.original_host.no_password_needed = True
            else:
                self.password = password

                if not password:
                    self.no_password_needed = True

        return password

    def with_domain_suffix(self, domain_suffix):
        """
        Returns another SSH host object with domain suffix as specified.

        Note that the domain_suffix MUST start with the network as the first part. E.g. cmn.hello.world.com
        """
        newHost = SshHost(self.hostname, self.username, self.rawdata, domain_suffix)
        newHost.original_host = self if not self.original_host else self.original_host
        return newHost

    def get_state(self):
        """
        Gets the HSM state of this host that was set with self.set_state(state)
        """
        if self.original_host:
            return self.original_host.state
        else:
            return self.state

    def set_state(self, state):
        """
        Sets the HSM state of this host
        """
        if self.original_host:
            self.original_host.state = state
        else:
            self.state = state

    def is_ready(self):
        """
        Whether this host is marked as ready for use
        """
        state = self.get_state()
        return state == "Configured" or state == "Ready" or state == None # if None, state is unknown, so we'll assume it is ready

    def get_full_domain_name(self):
        """
        Gets the full domain name of this host using self.domain_suffix
        """
        if self.domain_suffix:
            return "{}.{}".format(self.hostname, self.domain_suffix)
        else:
            return self.hostname

    def get_network_type(self):
        """
        Gets the network type of this host. Extracted from domain_suffix. See with_domain_suffix(..)
        """
        if self.domain_suffix:
            return self.domain_suffix.split(".")[0].lower().strip()
        else:
            return ""

    def get_ssh_command_to_connect_to_self(self):
        """
        Gets the SSH command to connect to this host. This assumes no underlying SSH connection.
        """
        return "ssh -o LogLevel=error -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s@%s" % (self.username, self.get_full_domain_name())

    def get_ssh_command_to_connect_to_target(self, target_ssh_host):
        """
        Gets the SSH command to connect to the target host. This assumes this host is the underlying SSH connection.
        """
        if self.is_switch():
            target_host_network = target_ssh_host.get_network_type()

            uses_vrf_Customer = "can" == target_host_network or "chn" == target_host_network or "cmn" == target_host_network

            vrf = " vrf Customer" if uses_vrf_Customer else ""

            if self.is_mellanox_switch():
                return "slogin%s %s@%s" % (vrf, target_ssh_host.username, self.get_target_hostname(target_ssh_host))
            else:
                return "ssh %s@%s%s" % (target_ssh_host.username, self.get_target_hostname(target_ssh_host), vrf)

        else:
            return "ssh -o LogLevel=error -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s@%s" % (target_ssh_host.username, self.get_target_hostname(target_ssh_host))

    def get_target_hostname(self, target_ssh_host):
        """
        Normalizes the hostname of a target host to connect to by:

        1. When using a switch and targeting another switch via the CMN network, uses the IP instead of the target switch instead of its hostname

        It is so we can get around the bug https://jira-pro.its.hpecorp.net:8443/browse/CASMNET-1599. When we resolve that bug, then remove this workaround.

        2. If using nmnlb or hmnlb, then always goes to api.nmnlb.<system-domain> and api.hmnlb.<system-domain> respectively.
        """

        target_host_network = target_ssh_host.get_network_type()

        if ("cmn" == target_host_network or "chn" == target_host_network or "can" == target_host_network) and self.is_aruba_switch():
            # Condition 1 from above docs
            return socket.gethostbyname(target_ssh_host.get_full_domain_name())
        elif "hmnlb" == target_host_network and target_ssh_host.is_management_node():
            # Condition 2a from above docs
            return "hmcollector.{}".format(target_ssh_host.domain_suffix)
        elif "nmnlb" == target_host_network and target_ssh_host.is_management_node():
            # Condition 2b from above docs
            return "api.{}".format(target_ssh_host.domain_suffix)
        else:
            return target_ssh_host.get_full_domain_name()

    def get_hostname_command_prompt(self):
        """
        Gets the string that is expected when successfully logged into this host.
        """
        host_network = self.get_network_type()

        if self.is_management_node() and ("nmnlb" == host_network or "hmnlb" == host_network):
            # nmnlb and hmnlb only refer to api gateways so we always get redirected to an ncn, although, we don't know which
            # deterministically at compile time (maybe lb is doing round-robin or some other type of load balancing)
            return r"((.|\n)*)(({})|({}))((.|\n)*)".format(re.escape("ncn-"), re.escape("ncn-"))
        else:
            return r"((.|\n)*)(({hostname}\:)|({hostname}(.*)\#)|({hostname}(.*)\>))((.|\n)*)".format(hostname = re.escape(self.hostname))

    def is_management_node(self):
        """
        Whether this is a management node
        """
        return self.rawdata and "ExtraProperties" in self.rawdata and "Role" in self.rawdata["ExtraProperties"] and self.rawdata["ExtraProperties"]["Role"] == "Management"

    def is_switch(self):
        """
        Whether this is a switch
        """
        return "switch" in self.type

    def is_mellanox_switch(self):
        """
        Whether this is a Mellnox brand switch
        """
        return self.is_switch() and self.rawdata and "ExtraProperties" in self.rawdata and "Brand" in self.rawdata["ExtraProperties"] and self.rawdata["ExtraProperties"]["Brand"] == "Mellanox"

    def is_aruba_switch(self):
        """
        Whether this is a Aruba brand switch
        """
        return self.is_switch() and self.rawdata and "ExtraProperties" in self.rawdata and "Brand" in self.rawdata["ExtraProperties"] and self.rawdata["ExtraProperties"]["Brand"] == "Aruba"
