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

from pyscripts.core.csm_api_utils import get_api_gateway_uri, get_access_token, CsmApiError
from pyscripts.core.ssh.ssh_host import SshHost
import requests
import urllib3
import json
import sys
import logging

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class SshTargets:
    """
    Maintains categorized lists of hardware that we can SSH into. Populated with SLS dumpstate.

    Each item in an array is an SshHost that can be used with SshConnection.
    """

    def __init__(self):
        self.ncn_master = []
        self.ncn_worker = []
        self.ncn_storage = []
        self.cn = []
        self.uan = []
        self.uai = []
        self.spine_switch = []
        self.leaf_switch = []
        self.leaf_BMC = []
        self.CDU = []
        self.byHostname = {}
        self.byXname = {}

    def refresh(self):
        """
        Refreshes the hardware state in memory
        """

        # first sync using the dumpstate API from SLS
        self.__sync_sls_dump_state()

        # now match up the actual state
        self.__sync_hsm_state_component_list()

    def __sync_hsm_state_component_list(self):
        headers = {
            'Authorization': "Bearer " + get_access_token()
        }

        hsm_state_list_url = "{}/smd/hsm/v2/State/Components".format(get_api_gateway_uri())

        try:
            r = requests.request("GET", hsm_state_list_url, headers = headers, verify = False)
        except Exception as err:
            logging.error(f"An unanticipated exception occurred while retrieving HSM State Components {err}")
            raise CsmApiError from None

        if r.status_code != 200:
            logging.error("Got HTTP {} when accessing {}".format(r.status_code, hsm_state_list_url))
            raise CsmApiError from None

        data = r.json()["Components"]

        for i in range(len(data)):
            hsm_state = data[i]
            xname = hsm_state["ID"]

            if xname in self.byXname:
                host = self.byXname[xname]
                host.set_state(hsm_state["State"])

    def __sync_sls_dump_state(self):
        headers = {
            'Authorization': "Bearer " + get_access_token()
        }

        dumpstate_url = "{}/sls/v1/dumpstate".format(get_api_gateway_uri())

        try:
            r = requests.request("GET", dumpstate_url, headers = headers, verify = False)
        except Exception as err:
            logging.error(f"An unanticipated exception occurred while dumping SLS hardware state {err}")
            raise CsmApiError from None

        if r.status_code != 200:
            logging.error("Got HTTP {} when accessing {}".format(r.status_code, dumpstate_url))
            raise CsmApiError from None

        data = r.json()["Hardware"]

        self.ncn_master = []
        self.ncn_worker = []
        self.ncn_storage = []
        self.cn = []
        self.uan = []
        self.uai = []
        self.spine_switch = []
        self.leaf_switch = []
        self.leaf_BMC = []
        self.CDU = []
        self.byHostname = {}
        self.byXname = {}

        # Comment out to debug the retrieved data
        # with open('data.json', 'w', encoding='utf-8') as f:
        #     json.dump(data, f, ensure_ascii=False, indent=4)

        for xname in data:
            x = data[xname]
            if x["Type"] == "comptype_node" and x["ExtraProperties"]["Role"] == "Compute":
                host = SshHost(x["ExtraProperties"]["Aliases"][0], "root", x)
                self.cn.append(host)
                self.byHostname[host.hostname] = host
                self.byXname[xname] = host
            elif x["Type"] == "comptype_node" and x["ExtraProperties"]["Role"] == "Management" and x["ExtraProperties"]["SubRole"] == "Master":
                host = SshHost(x["ExtraProperties"]["Aliases"][0], "root", x)
                self.ncn_master.append(host)
                self.byHostname[host.hostname] = host
                self.byXname[xname] = host
            elif x["Type"] == "comptype_node" and x["ExtraProperties"]["Role"] == "Management" and x["ExtraProperties"]["SubRole"] == "Storage":
                host = SshHost(x["ExtraProperties"]["Aliases"][0], "root", x)
                self.ncn_storage.append(host)
                self.byHostname[host.hostname] = host
                self.byXname[xname] = host
            elif x["Type"] == "comptype_node" and x["ExtraProperties"]["Role"] == "Management" and x["ExtraProperties"]["SubRole"] == "Worker":
                host = SshHost(x["ExtraProperties"]["Aliases"][0], "root", x)
                self.ncn_worker.append(host)
                self.byHostname[host.hostname] = host
                self.byXname[xname] = host
            elif x["Type"] == "comptype_node" and x["ExtraProperties"]["Role"] == "Application" and ("SubRole" in x["ExtraProperties"] and x["ExtraProperties"]["SubRole"] == "UAN"):
                host = SshHost(x["ExtraProperties"]["Aliases"][0], "root", x)
                self.uan.append(host)
                self.byHostname[host.hostname] = host
                self.byXname[xname] = host
            elif x["Type"] == "comptype_hl_switch" and len(x["ExtraProperties"]["Aliases"]) > 0 and "leaf" in x["ExtraProperties"]["Aliases"][0]:
                host = SshHost(x["ExtraProperties"]["Aliases"][0], "admin", x)
                self.leaf_switch.append(host)
                self.byHostname[host.hostname] = host
                self.byXname[xname] = host
            elif x["Type"] == "comptype_hl_switch" and len(x["ExtraProperties"]["Aliases"]) > 0 and "spine" in x["ExtraProperties"]["Aliases"][0]:
                host = SshHost(x["ExtraProperties"]["Aliases"][0], "admin", x)
                self.spine_switch.append(host)
                self.byHostname[host.hostname] = host
                self.byXname[xname] = host
            elif x["Type"] == "comptype_mgmt_switch" and len(x["ExtraProperties"]["Aliases"]) > 0 and "leaf-bmc" in x["ExtraProperties"]["Aliases"][0]:
                host = SshHost(x["ExtraProperties"]["Aliases"][0], "admin", x)
                self.leaf_BMC.append(host)
                self.byHostname[host.hostname] = host
                self.byXname[xname] = host
            elif x["Type"] == "comptype_cdu_mgmt_switch":
                host = SshHost(x["ExtraProperties"]["Aliases"][0], "admin", x)
                self.CDU.append(host)
                self.byHostname[host.hostname] = host
                self.byXname[xname] = host
