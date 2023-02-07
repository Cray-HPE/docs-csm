#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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
import argparse
import http
import sys
import requests
import json
import os
import urllib3

urllib3.disable_warnings()

# Check to make sure we have a token.
token = os.environ.get('TOKEN')
if token is None:
    print("TOKEN environment variable must be set!")
    sys.exit(1)

parser = argparse.ArgumentParser(description='CEPH runcmd utility.')
parser.add_argument('--api_gateway_address', action='store', default='api-gw-service-nmn.local',
                    help='Address of the API gateway.')

args = parser.parse_args()

session = requests.Session()
session.verify = False

# Get the storage nodes.
components_response = session.get('https://{}/apis/smd/hsm/v2/State/Components?role=Management&subrole=Storage'.format(
        args.api_gateway_address),
        headers={'Authorization': 'Bearer {}'.format(token)})
components_json = components_response.json()

for storage_component in components_json['Components']:
    body = {'hosts': [storage_component['ID']]}
    bss_response = session.get('https://{}/apis/bss/boot/v1/bootparameters'.format(args.api_gateway_address),
                               headers={'Authorization': 'Bearer {}'.format(token),
                                        "Content-Type": "application/json"},
                               data=json.dumps(body))
    bss_json = bss_response.json()[0]

    run_cmd = bss_json['cloud-init']['user-data']['runcmd']

    # Out with the old (if it exists)...
    cloudinit_script = "/srv/cray/scripts/common/storage-ceph-cloudinit.sh"
    if cloudinit_script in run_cmd:
        run_cmd.remove(cloudinit_script)

    # ...and in with the new (if it is not already there)
    enable_script = "/srv/cray/scripts/common/ceph-enable-services.sh"
    if enable_script not in run_cmd:
        run_cmd.append(enable_script)
    
    preLoadImages_script="/srv/cray/scripts/common/pre-load-images.sh"
    if preLoadImages_script in run_cmd:
        run_cmd.remove(preLoadImages_script)

    # Now patch BSS.
    patch_response = session.patch('https://{}/apis/bss/boot/v1/bootparameters'.format(args.api_gateway_address),
                               headers={'Authorization': 'Bearer {}'.format(token),
                                        "Content-Type": "application/json"},
                               data=json.dumps(bss_json))
    if patch_response.status_code != http.HTTPStatus.OK:
        print('Failed to patch BSS entry for {}/{}!'.format(storage_component['ID'],
                                                            bss_json['cloud-init']['user-data']['hostname']))
    else:
        print('BSS entry for {}/{} patched.'.format(storage_component['ID'],
                                                    bss_json['cloud-init']['user-data']['hostname']))
