#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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
        self.vrf = None # whether to add a vrf suffix to commands executed on this host
        self.use_extra_params = True # whether to connect to this host using parameters such as '-o LogLevel=error -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

    def get_password(self, reset_cached = False):
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
        newHost = SshHost(self.hostname, self.username, self.rawdata, domain_suffix)
        newHost.original_host = self if not self.original_host else self.original_host
        newHost.vrf = self.vrf
        newHost.use_extra_params = self.use_extra_params
        return newHost

    def get_state(self):
        if self.original_host:
            return self.original_host.state
        else:
            return self.state

    def set_state(self, state):
        if self.original_host:
            self.original_host.state = state
        else:
            self.state = state

    def is_ready(self):
        state = self.get_state()
        return state == "Configured" or state == "Ready" or state == None # if None, state is unknown, so we'll assume it is ready

    def get_full_domain_name(self):
        if self.domain_suffix:
            return "{}.{}".format(self.hostname, self.domain_suffix)
        else:
            return self.hostname

    def get_target_hostname(self, target_ssh_host):
        """
        Normalizes the hostname of a target host to connect to by:

        1. if using nmnlb or hmnlb, then always goes to api.nmnlb.<system-domain> and api.hmnlb.<system-domain> respectively.

        2. When using vrf (i.e., this host is a switch) and going to cmn network, uses the IP instead.

        (2) is a workaround that substitutes the IP of the target host instead of the hostname to connect.
        It is so we can get around the bug https://jira-pro.its.hpecorp.net:8443/browse/CASMNET-1600

        Once that bug is resolved, either this entire method and the logic to use this method in ssh_connection should be removed,
        or everything except the last line in this method that returns target_ssh_host.hostname should be removed.
        """
        if self.vrf and "cmn." in target_ssh_host.domain_suffix and "switch" in target_ssh_host.type:
            return socket.gethostbyname(target_ssh_host.get_full_domain_name())
        elif "hmnlb." in target_ssh_host.domain_suffix:
            return "hmcollector.{}".format(target_ssh_host.domain_suffix)
        elif "nmnlb." in target_ssh_host.domain_suffix:
            return "api.{}".format(target_ssh_host.domain_suffix)
        else:
            return target_ssh_host.get_full_domain_name()

    def get_target_hostname_command_prompt(self):
        """
        Gets the string that is expected when successfully logged into the target host.
        """
        if self.domain_suffix and ("nmnlb." in self.domain_suffix or "hmnlb." in self.domain_suffix):
            # nmnlb and hmnlb only refer to api gateways so we always get redirected to an ncn, although, we don't know which
            # deterministically at compile time (maybe lb is doing round-robin or some other type of load balancing)
            return r"((.|\n)*)(({})|({}))((.|\n)*)".format(re.escape("ncn-"), re.escape("ncn-"))
        else:
            return r"((.|\n)*)(({}\:)|({}\#))((.|\n)*)".format(re.escape(self.hostname), re.escape(self.hostname))
