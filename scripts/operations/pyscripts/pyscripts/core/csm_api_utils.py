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

"""
Utilities to help retrieve system domain, K8s admin secret, Keycloak access tokens, and API urls, etc.
"""

import logging
import base64
import os
import requests
import urllib3
from pexpect import run

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class CsmApiError(Exception):
    """
    Anything related with fetching
    """

try:
  from kubernetes import client, config
except:
  client = None
  config = None

SYSTEM_NAME = None
SITE_DOMAIN = None
SYSTEM_DOMAIN = None
ADMIN_SECRET = None
ACCESS_TOKEN = None
API_GATEWAY_BASE_DOMAIN = None

def get_system_domain():
    """
    Gets the system domain. Assumes this code is run on a machine with craysys installed or that set_system_domain is called
    """

    global SYSTEM_NAME
    global SITE_DOMAIN
    global SYSTEM_DOMAIN

    if SYSTEM_DOMAIN:
        return SYSTEM_DOMAIN

    if not SYSTEM_NAME:
        __calculate_system_name()

    if not SITE_DOMAIN:
        __calculate_site_domain()

    SYSTEM_DOMAIN = "{}.{}".format(SYSTEM_NAME, SITE_DOMAIN)

    return SYSTEM_DOMAIN

def set_system_domain(system_domain):
    """
    Sets the system domain.
    """

    global SYSTEM_DOMAIN
    SYSTEM_DOMAIN = system_domain

def get_api_gateway_uri():
    """
    Gets the API Gateway base URI
    """
    return "https://{}.{}/apis".format("api", __get_api_gateway_base_domain())

def get_auth_gateway_uri():
    """
    Gets the Auth gateway base URI
    """
    return "https://{}.{}/keycloak".format("auth", __get_api_gateway_base_domain())

def get_admin_secret(force_refresh = False):
    """
    Get the admin secret from k8s for the api gateway - command line equivalent is:
    #`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d`
    """

    global ADMIN_SECRET

    if ADMIN_SECRET and not force_refresh:
        return ADMIN_SECRET

    try:
        config.load_kube_config()
        k8sClientApi = client.CoreV1Api()
        sec = k8sClientApi.read_namespaced_secret("admin-client-auth", "default").data
        ADMIN_SECRET = base64.b64decode(sec["client-secret"])
        return ADMIN_SECRET
    except Exception as err:
        print(f"An unanticipated exception occurred while retrieving k8s secrets {err}")
        logging.error(f"An unanticipated exception occurred while retrieving k8s secrets {err}")
        raise CsmApiError from None

def set_admin_secret(admin_secret):
    """
    Sets the admin secret for k8s.
    """

    global ADMIN_SECRET
    ADMIN_SECRET = admin_secret

def get_access_token(force_refresh = False):
    """
    Gets the API access token to access any Keycloak-protected API.
    """

    global ACCESS_TOKEN

    if ACCESS_TOKEN and not force_refresh:
        return ACCESS_TOKEN

    # get an access token from keycloak
    payload = {"grant_type":"client_credentials",
            "client_id":"admin-client",
            "client_secret": get_admin_secret()}

    url = "{}/realms/shasta/protocol/openid-connect/token".format(get_auth_gateway_uri())

    try:
        r = requests.post(url, data = payload, verify = False)
    except Exception as err:
        print(f"An unanticipated exception occurred while retrieving gateway token {err}")
        logging.error(f"An unanticipated exception occurred while retrieving gateway token {err}")
        raise CsmApiError from None

    # if the token was not provided, log the problem
    if r.status_code != 200:
        print(f"Error retrieving gateway token: keycloak return code: {r.status_code}"
            f" text: {r.text}")
        logging.error(f"Error retrieving gateway token: keycloak return code: {r.status_code}"
            f" text: {r.text}")
        raise CsmApiError from None

    # pull the access token from the return data
    ACCESS_TOKEN = r.json()['access_token']

    return ACCESS_TOKEN

def is_bican_chm():
    headers = {
        'Authorization': "Bearer " + get_access_token()
    }

    sls_networks_url = "{}/sls/v1/networks".format(get_api_gateway_uri())

    try:
        r = requests.request("GET", sls_networks_url, headers = headers, verify = False)
    except Exception as err:
        logging.error(f"An unanticipated exception occurred while retrieving SLS Networks {err}")
        raise CsmApiError from None

    if r.status_code != 200:
        logging.error("Got HTTP {} when accessing {}".format(r.status_code, sls_networks_url))
        raise CsmApiError from None

    networks = r.json()

    for network in networks:
        if network["Name"] == "BICAN":
            if network["ExtraProperties"]["SystemDefaultRoute"] == "CHN":
                return True
            else:
                return False
    
    return False

def __get_api_gateway_base_domain():
    """
    Gets the reachable and resolvable base API Gateway domain
    """
    global API_GATEWAY_BASE_DOMAIN

    if API_GATEWAY_BASE_DOMAIN:
        return API_GATEWAY_BASE_DOMAIN

    system_domain = get_system_domain()

    networks = ["cmn", "can", "chn", "nmnlb"]
    for network in networks:
        API_GATEWAY_BASE_DOMAIN = "{}.{}".format(network, system_domain)
        test_domain = "{}.{}".format("auth", API_GATEWAY_BASE_DOMAIN)

        if __resolvable(test_domain) or __reachable(test_domain):
            return API_GATEWAY_BASE_DOMAIN

    raise CsmApiError

def __resolvable(service):
    ret = os.system("nslookup {} >/dev/null".format(service))
    if ret != 0:
        return False
    else:
        return True

def __reachable(service):
    ret = os.system("ping -q -c 3 {} >/dev/null".format(service))
    if ret != 0:
        return False
    else:
        return True

def __calculate_system_name():
    global SYSTEM_NAME
    SYSTEM_NAME = run("craysys metadata get system-name").decode()[:-2] # output ends with \r\n

def __calculate_site_domain():
    global SITE_DOMAIN
    SITE_DOMAIN = run("craysys metadata get site-domain").decode()[:-2] # output ends with \r\n
