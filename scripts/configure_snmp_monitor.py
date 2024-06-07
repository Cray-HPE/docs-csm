#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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
import yaml
from pprint import pprint
import sys
import argparse

parser = argparse.ArgumentParser(
    prog='configure_snmp_monitor',
    description='Configures the cray-sysmgmt-health SNMP exporter using switch data from SLS')

parser.add_argument('-n', '--network',
                    action='store',
                    choices=['HMN', 'NMN'],
                    default='HMN',
                    help='Network to be used for SNMP monitoring')

parser.add_argument('-c', '--customizations-file',
                    action='store',
                    required=True)

parser.add_argument('-s', '--sls-file',
                    action='store',
                    required=True)

args = parser.parse_args()

try:
    with open(args.sls_file) as sls_file:
        sls_data = json.load(sls_file)
except IOError as e:
    print(e)
    sys.exit(1)

print("Switches to monitor for subnet " + args.network)

try:
    if args.network == 'HMN':
        hmn = sls_data['Networks']['HMN']['ExtraProperties']['Subnets']
        subnet = list(filter(lambda x: x["FullName"] == "HMN Management Network Infrastructure", hmn))[0]
    if args.network == 'NMN':
        nmn = sls_data['Networks']['NMN']['ExtraProperties']['Subnets']
        subnet = list(filter(lambda x: x["FullName"] == "NMN Management Network Infrastructure", nmn))[0]
except KeyError:
    print("Unable to read network reservations from SLS data")
    sys.exit(1)

switches_to_monitor = []
for device in subnet['IPReservations']:
    switches_to_monitor.append({'name': device['Name'], 'target': device['IPAddress']})

pprint(switches_to_monitor)

try:
    with open(args.customizations_file, 'r+') as customizations_file:
        customizations = yaml.safe_load(customizations_file)

        print("Enabling prometheus-snmp-exporter serviceMonitor")
        if "prometheus-snmp-exporter" not in customizations:
            customizations['spec']['kubernetes']['services']['cray-sysmgmt-health'].update(
                {"prometheus-snmp-exporter":{'serviceMonitor': {'enabled': True, 'params': []}}})
        else:
            customizations['spec']['kubernetes']['services']['cray-sysmgmt-health']['prometheus-snmp-exporter'][
                'serviceMonitor'].update({'enabled': 'true'})

        print("Adding the targets to the SNMP serviceMonitor configuration")
        customizations['spec']['kubernetes']['services']['cray-sysmgmt-health']['prometheus-snmp-exporter'][
            'serviceMonitor']['params'] = switches_to_monitor

        customizations_file.seek(0)
        yaml.dump(customizations, customizations_file, sort_keys=False)
        customizations_file.truncate()
except IOError as e:
    print(e)
    sys.exit(1)
