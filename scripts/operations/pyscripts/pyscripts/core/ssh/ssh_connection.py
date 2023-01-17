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

import json
import sys
import logging
import requests
import yaml
import base64
import subprocess
import os.path
import subprocess
import pexpect
from pyscripts.core.ssh.ssh_host import SshHost
from pyscripts.core.log_config import get_logging_level
import time
import re

try:
    raw_input
except NameError:
    raw_input = input

PASSWORD_PROMPT = r"((.|\n)*)password\:"
COMMAND_PROMPT_ONE_LINE = r"((.|\n)*)\:\~ \#"
SSH_NEWKEY = r"((.|\n)*)Are you sure you want to continue connecting((.|\n)*)"
UNRESOLVED_HOSTNAME = r"((.|\n)*)Could not resolve hostname((.|\n)*)"
IDENTIFICATION_CHANGED = r"((.|\n)*)offending key can be removed using the below command((.|\n)*)"

DEFAULT_TIMEOUT = 5

class TimeoutException(Exception):
    """
    Timed out while trying to SSH into host.
    """

class SshConnectionException(Exception):
    """
    An unexpected SSH connection error occurred.
    """

class CannotLoginException(Exception):
    """
    Cannot login.
    """

class UnresolvedHostname(Exception):
    """
    Could not resolve the hostname.
    """

class RemoteHostIdentificationChanged(Exception):
    """
    Remote host identification changed.
    """

class UnexpectedRunCommandOutput(Exception):
    """
    Output of run command did not match what was expected.
    """


class SshConnection:
    def __init__(self, ssh_host, ssh_conn = None):
        self.ssh_host = ssh_host
        self.ssh_conn = ssh_conn
        self.child_process = None if not ssh_conn else ssh_conn.child_process
        self.connected = False
        self.command_prompt_host_pattern = ssh_host.get_hostname_command_prompt()

    def connect(self):
        if self.connected:
            return # return silently because we are already connected

        if not self.ssh_conn:
            self.child_process = pexpect.spawn(self.ssh_host.get_ssh_command_to_connect_to_self(), encoding="utf-8")

            if get_logging_level() == logging.INFO:
                self.child_process.logfile = sys.stdout
        else:
            if not self.ssh_conn.connected:
                # the base ssh connection hasn't connected yet
                self.ssh_conn.connect()
                self.child_process = self.ssh_conn.child_process

            self.child_process.sendline(self.ssh_conn.ssh_host.get_ssh_command_to_connect_to_target(self.ssh_host))

        self.__open_connection_dance()

    def close_connection(self, recursive = True):
        """
        Closes the connection. If recursive, then will close the original ssh_conn as well.
        """

        self.__close_connection_dance()
        if recursive and self.ssh_conn:
            self.ssh_conn.close_connection()

    def run_test_command(self, command_to_run, expected):
        self.__check_connected()
        logging.info("Running command '{}' and expecting {} on {}".format(command_to_run, expected, self.ssh_host.get_full_domain_name()))
        self.child_process.sendline(command_to_run)
        i = self.__expect([r"{}((.|\n)*){}{}".format(re.escape(command_to_run), re.escape(expected), self.command_prompt_host_pattern), pexpect.TIMEOUT], timeout=DEFAULT_TIMEOUT)

        if i != 0:
            logging.info("Unexpected run_test_command output. See above for actual and expected outputs.")
            raise UnexpectedRunCommandOutput

    def __check_child_process(self):
        if not self.child_process:
            logging.info("No SSH child process has been spawned off yet.")
            raise SshConnectionException

    def __check_connected(self):
        self.__check_child_process()
        if not self.connected:
            logging.info("Not connected yet.")
            raise SshConnectionException

    def __expect(self, regex_list, timeout=DEFAULT_TIMEOUT):
        """
        Ironically, pexpect.spawn.expect method is a really slow implementation. Most likely it is in O(m*n^2) as it matches
        every item in the pattern list to each input character as it comes in. Sadly, using maxread and searchwindowsize has
        no effect. As such, I have written an expect below that reads as much data as possible first and then just does a O(nm) search.
        """

        output = ""
        try:
            while True:
                output += self.child_process.read_nonblocking(size=10240, timeout = timeout)
        except Exception as err:
            pass

        logging.info("Expecting the following '{}' and actual '{}'".format(regex_list, output))

        if output == "Timeout exceeded.":
            # if all there is in output is timeout exceeded, then it is truly timeout exceeded
            for i in range(len(regex_list)):
                if regex_list[i] == pexpect.TIMEOUT:
                    return i

            raise TimeoutException

        output = output.replace("Timeout exceeded.", "")

        for i in range(len(regex_list)):
            if regex_list[i] != pexpect.TIMEOUT and regex_list[i] != pexpect.EOF and re.match(regex_list[i], output, re.IGNORECASE):
                return i

    def __open_connection_dance(self):
        self.__check_child_process()

        logging.info("Connecting to {}".format(self.ssh_host.get_full_domain_name()))

        pattern_list = [PASSWORD_PROMPT, pexpect.TIMEOUT, SSH_NEWKEY, IDENTIFICATION_CHANGED, UNRESOLVED_HOSTNAME, self.command_prompt_host_pattern]
        if self.ssh_conn:
            pattern_list.append(self.ssh_conn.command_prompt_host_pattern)

        i = self.__expect(pattern_list)

        if i == 5:
            logging.info("Connected to {}".format(self.ssh_host.get_full_domain_name()))
            self.connected = True
            return
        elif i == 4:
            raise UnresolvedHostname
        elif i == 3:
            # Note: we don't want to modify the host system ourselves. So just signal this and fail the test.
            raise RemoteHostIdentificationChanged
        elif i == 2:
            self.child_process.sendline("yes")
            i = self.__expect([PASSWORD_PROMPT, pexpect.TIMEOUT], timeout=DEFAULT_TIMEOUT)
            # fall through below...

        # fall through code...
        if i == 1:
            raise TimeoutException

        num_tries = 0
        while i == 0 and num_tries < 3:
            num_tries += 1
            password = self.ssh_host.get_password(False if num_tries == 1 else True)
            self.child_process.sendline(password)
            i = self.__expect([PASSWORD_PROMPT, self.command_prompt_host_pattern, pexpect.TIMEOUT], timeout=DEFAULT_TIMEOUT)

            if i == 1:
                self.connected = True
                return

        logging.info("Could not login to {}.".format(self.ssh_host.get_full_domain_name()))
        raise CannotLoginException

    def __close_connection_dance(self):
        # don't use self.__check_connected() or self.__check_child_process because this function is noop
        # if there is no connection established
        if self.connected and self.child_process:
            logging.info("Exiting from {}".format(self.ssh_host.get_full_domain_name()))
            self.child_process.sendline("exit")

            if (self.ssh_conn):
                self.__expect([pexpect.EOF, COMMAND_PROMPT_ONE_LINE, pexpect.TIMEOUT])
            else:
                self.__expect([pexpect.EOF, pexpect.TIMEOUT])
                try:
                    self.child_process.close(force=True)
                except Exception as err:
                    pass
