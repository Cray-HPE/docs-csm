#! /usr/bin/env python3
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
#
#
#  ./gateway-test.py <system-domain> <token-network>
#

import json
import sys
import logging
import requests
import urllib3
import yaml
import base64
import subprocess
import os.path

try:
  from kubernetes import client, config
except:
  client = None
  config = None


# Some very light logging.
LOG_LEVEL=logging.INFO

# Start logging
logging.basicConfig(filename='/tmp/' + sys.argv[0].split('/')[-1] + '.log',  level=LOG_LEVEL)
logging.info("Starting up")

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class GWException(Exception):
    """
    This is the base exception for all custom exceptions that can be raised from
    this application.
    """

def reachable(service):
    ret = os.system("ping -q -c 3 {} >/dev/null".format(service))
    if ret != 0:
        print("{} is NOT reachable".format(service))
        return False
    else:
        print("{} is reachable".format(service))
        return True

def get_admin_secret(k8sClientApi):
    """
    Get the admin secret from k8s for the api gateway - command line equivalent is:
    #`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d`
    """

    try:
        sec = k8sClientApi.read_namespaced_secret("admin-client-auth", "default").data
        adminSecret = base64.b64decode(sec['client-secret'])
    except Exception as err:
        logging.error(f"An unanticipated exception occurred while retrieving k8s secrets {err}")
        raise GWException from None

    return adminSecret

def get_access_token(adminSecret, tokenNet, nmn_override):

    # get an access token from keycloak
    payload = {"grant_type":"client_credentials",
               "client_id":"admin-client",
               "client_secret":adminSecret}

    if tokenNet == "nmnlb" and nmn_override:
        tokendomain = "api-gw-service-nmn.local"
    else:
        tokendomain = "auth.{}.{}".format(tokenNet, SYSTEM_DOMAIN)

    url = "https://{}/keycloak/realms/shasta/protocol/openid-connect/token".format(tokendomain)
 
    if not reachable(tokendomain):
        return None
   
    try: 
      r = requests.post(url, data = payload, verify = False)
    except Exception as err:
        print("{}".format(err))
        logging.error(f"An unanticipated exception occurred while retrieving gateway token {err}")
        raise GWException from None

    # if the token was not provided, log the problem
    if r.status_code != 200:
        print("Error retrieving gateway token:  keycloak return code: {} text: {}".format(r.status_code,r.text))
        logging.error(f"Error retrieving gateway token: keycloak return code: {r.status_code}"
            f" text: {r.text}")
        raise GWException from None

    # pull the access token from the return data
    token = r.json()['access_token']

    print("Token successfully retrieved at {}\n".format(url))

    return token

def get_sls_networks(adminSecret, systemDomain, nets):

    sls_networks = []
    slstok = get_access_token(adminSecret, "cmn", False)

    if not slstok:
      print("Could not get token to get SLS networks")
      return sls_networks

    headers = {
        'Authorization': "Bearer " + slstok
    }

    for n in nets:

        slsurl = "https://api.cmn.{}/apis/sls/v1/networks/{}".format(systemDomain,n['name'].upper())
        try:
            r = requests.request("GET", slsurl, headers=headers, verify = False)
        except Exception as err:
            print("{}".format(err))
            logging.error(f"An unanticipated exception occurred while retrieving SLS {n.upper()} network data {err}")
            raise GWException from None

        if r.status_code == 200:
            sls_networks.append(n['name'])
        else:
            print("Got {} for {}".format(r.status_code,slsurl))

    return sls_networks


def get_vs(service):

    result = None	
    try:
        logging.debug("Getting gateways for service {}.".format(service['name']))
        command_line = ['kubectl', 'get', 'vs', service['name'], '-n', service['namespace'], '-o', 'yaml']
        result = subprocess.check_output(command_line, stderr=subprocess.STDOUT).decode("utf8")
        logging.debug(result)

    except subprocess.CalledProcessError as err:
        logging.error(f"Could not get virtual service. Got exit code {err.returncode}. Msg: {err.output}")

    return result

def get_vs_gateways(vsyaml):

    vs = yaml.safe_load(vsyaml)
    gws = vs['spec']['gateways']
    return gws

if __name__ == '__main__':

    numarg = len(sys.argv)
    test_defn_file = "./gateway-test-defn.yaml"
    TEST_FAILED = 0

    # Process the arguments
    if numarg < 3: 
      print("Usage: {} <system-domain> <token-network>".format(sys.argv[0]))
      logging.critical("Wrong number of arguments passed. Args = {}.".format(sys.argv))
      sys.exit(1)

    if not os.path.exists(test_defn_file):
      print("{} does not exist".format(test_defn_file))
      logging.critical("{} does not exist.".format(test_defn_file))
      sys.exit(1)

    SYSTEM_DOMAIN = (sys.argv[1]).lower() 
    TOKEN_NET = (sys.argv[2]).lower()
    ADMIN_SECRET = os.environ.get("ADMIN_CLIENT_SECRET", "")

    # Load the service definitions
    with open(test_defn_file, 'r') as f:
        svcs = yaml.load(f, Loader=yaml.FullLoader)

    # Validate the TOKEN_NET argument
    if not any(d['name'] == TOKEN_NET for d in svcs['networks']):
      print("{} is not a valid network".format(sys.argv[2]))
      logging.critical("{} is not a valid network".format(sys.argv[2]))
      sys.exit(1)

    # initialize k8s if we are running from an NCN
    if os.path.exists("/bin/craysys"):
      config.load_kube_config()
      k8sClientApi = client.CoreV1Api()
      ADMIN_SECRET = get_admin_secret(k8sClientApi)
    else:
      ADMIN_SECRET = os.environ.get("ADMIN_CLIENT_SECRET", "")
      if ADMIN_SECRET == "":
        print("ADMIN_CLIENT_SECRET not defined")
        sys.exit(1)

    # Determine which user networks are defined
    snets = get_sls_networks(ADMIN_SECRET, SYSTEM_DOMAIN, svcs['networks'])

    mytok = get_access_token(ADMIN_SECRET, TOKEN_NET, svcs['use-api-gw-override'])
 
    if not mytok:
      # If we are not on an NCN and the token net is NMNLB, then it is expected
      # that we cannot get the token
      if TOKEN_NET == "nmnlb" and not os.path.exists("/bin/craysys"):
          sys.exit(0)
      else:
          sys.exit(1)

    for net in svcs['networks']:

      netname = net['name'].lower()
      if netname.lower() == "nmnlb" and svcs['use-api-gw-override']:
         domain = "api-gw-service-nmn.local"
      else:
         domain = "api.{}.{}".format(netname, SYSTEM_DOMAIN)

      print("\n------------- {} -------------------".format(domain))

      if not reachable(domain):
          if netname in snets:
              if netname != "nmnlb" :
                  print("{} is not reachable but defined in SLS".format(netname))
                  TEST_FAILED = 1
          else:
              print("{} is not reachable and not defined in SLS".format(netname))
          continue

      if netname not in snets:
          print("{} is reachable but not defined in SLS".format(netname))
          TEST_FAILED = 1
          continue

      for i in range(len(svcs['ingress_api_services'])):
        svcname = svcs['ingress_api_services'][i]['name']
        svcpath = svcs['ingress_api_services'][i]['path']
        svcport = svcs['ingress_api_services'][i]['port']
        svcexp = svcs['ingress_api_services'][i]['expected-result']
        svcproject = svcs['ingress_api_services'][i]['project']

        if svcport == 443:
            scheme = "https"
        else:
            scheme = "http"

        url = scheme + "://" + domain + "/" + svcpath 

        if os.path.exists("/bin/craysys"):
        # Getting the gateways from the Virtual Service definitions
        # This can only be done if we are running the tests from an NCN
        # The best way I could find to determine if we are running on an NCN is to see if craysys is installed.
        # There may be a better way
            vsyaml = get_vs(svcs['ingress_api_services'][i])
            if vsyaml is None:
               print("SKIP - [" + svcname + "]: " + url + " - virtual service not found")
               continue
        
            svcgws = get_vs_gateways(vsyaml)
        elif svcproject != "CSM":
            print("SKIP - [{}]: {}".format(svcname, url))
            continue

        # Otherwise, we get the gateways from the test definition file (which may become stale)
        else:
            if "gateways" in svcs['ingress_api_services'][i]:
                svcgws = svcs['ingress_api_services'][i]['gateways']
            else:
                print("SKIP - [" + svcname + "]: " + url + " - gateways not found")
                continue

        if net['gateway'] not in svcgws:
          svcexp = 404
        # if the token we have does not match the network we are testing, we expect a 403
        # CMN tokens will work with NMN and vice versa, because they are using the same gateway in 1.2.
        elif TOKEN_NET == "cmn" and netname != TOKEN_NET and netname != "nmnlb":
          svcexp = 403
        elif TOKEN_NET == "nmnlb" and netname != TOKEN_NET and netname != "cmn":
          svcexp = 403
        elif TOKEN_NET not in ["cmn","nmnlb"] and TOKEN_NET != netname:
          svcexp = 403

        headers = {
            'Authorization': "Bearer " + mytok
        }

   
        try:    
            response = requests.request("GET", url, headers=headers, verify = False)
        except Exception as err:
            print("{}".format(err))
            logging.error(f"An unanticipated exception occurred while retrieving {url} {err}")
            break
    
        if response.status_code == svcexp:
            print("PASS - [" + svcname + "]: " + url + " - " + str(response.status_code))
        else:
            print("FAIL - [" + svcname + "]: " + url + " - " + str(response.status_code))
            TEST_FAILED = 1

    sys.exit(TEST_FAILED)

