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

def resolvable(service):
    ret = os.system("nslookup {} >/dev/null".format(service))
    if ret != 0:
        print("{} is NOT resolvable".format(service))
        return False
    else:
        return True

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
 
    if not resolvable(tokendomain):
        return None

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
    specgws = vs['spec']['gateways']
    gws = ' '.join(specgws).replace('services/','').split()
    return gws

if __name__ == '__main__':

    numarg = len(sys.argv)
    test_defn_file = "{}/gateway-test-defn.yaml".format(os.path.dirname(sys.argv[0]))
    TEST_FAILED = 0

    # Process the arguments
    if numarg < 3:
      print("Usage: {} <system-domain> <node-type> [<user-network>]".format(sys.argv[0]))
      logging.critical("Wrong number of arguments passed. Args = {}.".format(sys.argv))
      sys.exit(1)

    if not os.path.exists(test_defn_file):
      print("{} does not exist".format(test_defn_file))
      logging.critical("{} does not exist.".format(test_defn_file))
      sys.exit(1)

    SYSTEM_DOMAIN = (sys.argv[1]).lower() 
    NODE_TYPE = (sys.argv[2]).lower()
    ADMIN_SECRET = os.environ.get("ADMIN_CLIENT_SECRET", "")

    # Load the service definitions
    with open(test_defn_file, 'r') as f:
        svcs = yaml.load(f, Loader=yaml.FullLoader)

    # initialize k8s if we are running from an NCN
    if NODE_TYPE == "ncn":
      config.load_kube_config()
      k8sClientApi = client.CoreV1Api()
      ADMIN_SECRET = get_admin_secret(k8sClientApi)
    else:
      ADMIN_SECRET = os.environ.get("ADMIN_CLIENT_SECRET", "")
      if ADMIN_SECRET == "":
        print("ADMIN_CLIENT_SECRET not defined")
        sys.exit(1)

    reachnets = []

    # Get the user network
    if numarg == 4:
      USER_NET = (sys.argv[3]).lower()
      if USER_NET not in ["can", "chn"]:
        print("{} is not a valid network".format(USER_NET))
        sys.exit(1)
    else:
      slsnetworks = get_sls_networks(ADMIN_SECRET, SYSTEM_DOMAIN, svcs['test-networks'])
      if "can" in slsnetworks:
        USER_NET = "can"
#      CASMINST-5647: removing CHN test from 1.3 until test case can be redesigned.
#      if "chn" in slsnetworks:
#        USER_NET = "chn"
        reachnets.append(USER_NET)

    if NODE_TYPE == "ncn":
      reachnets.append("nmnlb")
      reachnets.append("hmnlb")
      reachnets.append("cmn")
    elif NODE_TYPE == "cn":
      reachnets.append("nmnlb")
      if "can" in reachnets:
        reachnets.remove("can")
    elif NODE_TYPE == "uan":
      reachnets.append("nmnlb")
    elif NODE_TYPE == "outside":
      reachnets.append("cmn")
    elif NODE_TYPE != "uai":
      print("Invalid node type {}".format(NODE_TYPE))
      logging.critical("Invalid node type {}".format(NODE_TYPE))
      sys.exit(1)

    print("Reachable networks: {}".format(reachnets))

    for tokennet in svcs['test-networks']:

      tokname = tokennet['name']
      print("\nGetting token for {}".format(tokname))
      mytok = get_access_token(ADMIN_SECRET, tokname, svcs['use-api-gw-override'])

      if not mytok:
        # if the network in not in the set of reachable networks then it is expected
        # that we cannot get the token
        if tokname not in reachnets:
          print("Could not retrieve token for {} (expected)".format(tokname))
          continue
        else:
          print("FAIL: Could not retrieve token for {}".format(tokname))
          TEST_FAILED = 1
          continue
      else:
        if tokname not in reachnets:
          print("FAIL: Token retrieved for {} network which should be unreachable".format(tokname))
          TEST_FAILED = 1
          continue

      for net in svcs['test-networks']:

        netname = net['name'].lower()
        if netname == "nmnlb" and svcs['use-api-gw-override']:
           domain = "api-gw-service-nmn.local"
        else:
           domain = "api.{}.{}".format(netname, SYSTEM_DOMAIN)

        print("\n------------- {} -------------------".format(domain))

        if not resolvable(domain) or not reachable(domain):
            if netname in reachnets:
                    print("FAIL: {} is not reachable".format(netname))
                    TEST_FAILED = 1
            else:
                print("{} is not reachable (expected)".format(netname))
                continue

        if netname not in reachnets:
            print("FAIL: {} is reachable".format(netname))
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

          if NODE_TYPE == "ncn":
          # Getting the gateways from the Virtual Service definitions
          # This can only be done if we are running the tests from an NCN
              vsyaml = get_vs(svcs['ingress_api_services'][i])
              if vsyaml is None:
                 print("SKIP - [" + svcname + "]: " + url + " - virtual service not found")
                 continue

              svcgws = get_vs_gateways(vsyaml)
          elif svcproject != "CSM":
              print("SKIP - [{}]: {}".format(svcname, url))
              continue

          # Otherwise, we get the gateways from the test defininition file (which may become stale)
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
          elif tokname == "cmn" and netname != tokname and netname != "nmnlb":
            svcexp = 403
          elif tokname == "nmnlb" and netname != tokname and netname != "cmn":
            svcexp = 403
          elif tokname not in ["cmn","nmnlb"] and tokname != netname:
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
              print("FAIL - [" + svcname + "]: " + url + " - " + str(response.status_code) + " (expecting: " + str(svcexp) + ")")
              TEST_FAILED = 1

    if TEST_FAILED:
        print("\nOverall Gateway Test Status:  FAIL")
    else:
        print("\nOverall Gateway Test Status:  PASS")

    sys.exit(TEST_FAILED)

