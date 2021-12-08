# #!/usr/bin/env python3
# Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# (MIT License)

# NOTE: on mug needed to install python-dateutil to get this to work!

"""
This script will set up a new 'temporary' user in keycloak and use that
account to initialize the cray cli on all master and worker nodes of the
kubernetes cluster.  Call the script with the '--run' option to do this.

When the install is complete, this script can also remove the temporary
user and uninitialize the cray cli on all master and worker node in the
cluster.  Call the script with the '--cleanup' option to do this.

During the cleanup operation, it is possible to initialze the cray cli with
a different existing keycloak user account.  To do this add a valid username
and password to the cleanup call:
python3 craycli_init.py --cleanup --username MY_USER --password MY_PASSWORD

The --nodeinit and --nodecleanup options are intended primarily to be called
automatically during the 'run' or 'cleanup' operations, but may be used on
individual nodes to replicate the initialization or cleanup operation on
a specific individual node.  Just ssh to that node, then call it from there.
"""

import argparse
import base64
import errno
import logging
import oauthlib.oauth2
import os
import pexpect
import time
import requests
import requests_oauthlib
import secrets
import string
import subprocess
import sys
from threading import Thread, Lock
from kubernetes import client, config, dynamic

# defaults
REMOTE_FILE_DIR = "/tmp/"
CRAYCLI_CONFIG_FILE = "/root/.config/cray/configurations/default"
DEFAULT_HOSTNAME = 'api-gw-service-nmn.local'
DEFAULT_KEYCLOAK_BASE = 'https://' + DEFAULT_HOSTNAME + '/keycloak'
DEFAULT_SLS_BASE = 'https://' + DEFAULT_HOSTNAME + '/apis/sls/v1'

# group name that exists in keycloak with permission to execute cray cli
DEFAULT_KEYCLOAK_GROUP = "craydev"

# Global file names and locations
THIS_FILE_FULL_PATH = __file__
REMOTE_FILE_NAME = REMOTE_FILE_DIR + os.path.basename(__file__)

# Logger for this script
LOGGER = logging.getLogger('craycli-init')

# dictionary of [host]:(return code, full remote call output string)
remote_init_results = dict()
rir_mutex = Lock()

# error codes for remote initialization
# NOTE: process return codes are 8 bit so keep these small
MSG_USER_SECRET = 101
MSG_REMOTE_COPY_FAILURE = 102
MSG_CRAY_INIT = 103
MSG_CRAY_AUTH = 104
MSG_CRAY_VERIFY = 105
MSG_MISSING_SCRIPT = 106
MSG_CONFIGFILE_NOT_PRESENT = 107
MSG_PYTHON_SCRIPT_ERROR = 108
MSG_LAST = 109
INIT_FAILURE_MSG = {
    MSG_USER_SECRET : "Failed to obtain user secret",
    MSG_REMOTE_COPY_FAILURE : "Failed to copy script to remote host",
    MSG_CRAY_INIT : "Call to cray init failed",
    MSG_CRAY_AUTH : "Call to cray auth login failed",
    MSG_CRAY_VERIFY : "Verification that cray cli is operational failed",
    MSG_MISSING_SCRIPT : "Script missing on remote node",
    MSG_CONFIGFILE_NOT_PRESENT : "Initialization file not present",
    MSG_PYTHON_SCRIPT_ERROR : "Python script failed",
}

# Class to hold/access information about the temporary user created for craycli
# use during install
class CliUserAuth(object):
    # defaults - make settable later if needed
    CLI_USER_AUTH_SECRET_NAME = "craycli-install-tmp-user-auth"
    CLI_USER_PASSWORD_LENGTH = 40
    CLI_USER_USERNAME = "craycli_tmp_user"

    def __init__(
            self,
            k8sClientApi,
            createIfNeeded,
            username = None,
            password = None
            ):
        self._k8sClientApi = k8sClientApi
        self._createIfNeeded = createIfNeeded
        self._tu_username = ""
        self._tu_password = ""
        self._newUser = username
        self._newPassword = password

    @property
    def tu_username(self):
        if self._tu_username == "":
            self._getOrCreateUser()
        return self._tu_username

    @property
    def tu_password(self):
        if self._tu_password == "":
            self._getOrCreateUser()
        return self._tu_password

    def deleteSecret(self):
        # get the secret if it exists
        sec = None
        try: 
            sec = self._k8sClientApi.read_namespaced_secret(self.CLI_USER_AUTH_SECRET_NAME, "services").data
        except client.exceptions.ApiException:
            LOGGER.info(f"Secret not present - no need to delete")

        # delete the secret
        if sec != None:
            try:
                self._k8sClientApi.delete_namespaced_secret(name=self.CLI_USER_AUTH_SECRET_NAME, namespace="services", body=sec)
            except client.exceptions.ApiException:
                LOGGER.error(f"Error attempting to delete cli user secret: {err}")

    def _getOrCreateUser(self):
        # if the secret already exists, read the username and password
        sec = None
        try: 
            sec = self._k8sClientApi.read_namespaced_secret(self.CLI_USER_AUTH_SECRET_NAME, "services")
            LOGGER.debug(f"Read existing tmp cli user secret")
        except client.exceptions.ApiException:
            LOGGER.debug(f"Temp cli user secret not present")

        # if the secret does not exist, create a new one
        if sec == None and self._createIfNeeded:
            LOGGER.debug(f"Creating new tmp cli user secret")

            # get username and password to use - defaults or specified
            newUser = self.CLI_USER_USERNAME
            if self._newUser != None:
                newUser = self._newUser

            newPassword = self._newPassword
            if newPassword == None:
                # generate a random 20 char password
                alphabet = string.ascii_letters + string.digits
                newPassword = ''.join(secrets.choice(alphabet) for i in range(self.CLI_USER_PASSWORD_LENGTH))

            # create a secret with the new password and default username
            sec  = client.V1Secret()
            sec.metadata = client.V1ObjectMeta(name=self.CLI_USER_AUTH_SECRET_NAME)
            sec.type = "Opaque"
            sec.data = {"user": base64.b64encode(newUser.encode('ascii')).decode('ascii'), 
                        "password": base64.b64encode(newPassword.encode('ascii')).decode('ascii')}
            try:
                self._k8sClientApi.create_namespaced_secret(namespace="services", body=sec)
            except client.exceptions.ApiException as err:
                # if we can't create the secret, bail
                LOGGER.error(f"Error attempting to create cli user secret: {err}")
                sys.exit(1)

        # pull the values from the secret if present
        if sec != None:
            self._tu_username = base64.b64decode(sec.data['user']).decode('ascii')
            self._tu_password = base64.b64decode(sec.data['password']).decode('ascii')
        return

# Class to wrap keycloak authentication with calls to the keycloak rest api
class KeycloakSetup(object):
    MASTER_REALM_NAME = 'master'
    SHASTA_REALM_NAME = 'shasta'

    def __init__(
            self,
            keycloak_base,
            kc_master_admin_client_id,
            kc_master_admin_username,
            kc_master_admin_password):
        self.keycloak_base = keycloak_base
        self.kc_master_admin_client_id = kc_master_admin_client_id
        self.kc_master_admin_username = kc_master_admin_username
        self.kc_master_admin_password = kc_master_admin_password

        self._kc_master_admin_client_cache = None

    # creates/gets a client object with the correct auth tokens present
    @property
    def _kc_master_admin_client(self):
        if self._kc_master_admin_client_cache:
            return self._kc_master_admin_client_cache

        kc_master_token_endpoint = (
            '{}/realms/{}/protocol/openid-connect/token'.format(
                self.keycloak_base, self.MASTER_REALM_NAME))

        kc_master_client = oauthlib.oauth2.LegacyApplicationClient(
            client_id=self.kc_master_admin_client_id)

        client = requests_oauthlib.OAuth2Session(
            client=kc_master_client, auto_refresh_url=kc_master_token_endpoint,
            auto_refresh_kwargs={
                'client_id': self.kc_master_admin_client_id,
            },
            token_updater=lambda t: LOGGER.info("Refreshed Keycloak master admin token"))
        LOGGER.debug("Fetching initial KC master admin token.")
        client.fetch_token(
            token_url=kc_master_token_endpoint,
            client_id=self.kc_master_admin_client_id,
            username=self.kc_master_admin_username,
            password=self.kc_master_admin_password)

        self._kc_master_admin_client_cache = client
        return self._kc_master_admin_client_cache

    # Create the user in keycloak with the given password
    def create_user(self, username, password, group):
        # check for valid input
        if username == "" or password == "":
            LOGGER.error(f"May not create user with empty name or password")
            return

        # construct the url and request body to create the user
        createUserUrl = f"{self.keycloak_base}/admin/realms/{self.SHASTA_REALM_NAME}/users"
        req_body = {
            'username': username,
            'enabled': True,
            'credentials': [
                {
                    'type': 'password',
                    'value': password,
                },
            ],
            'groups': [group,]
        }

        # make the call and parse response
        response = self._kc_master_admin_client.post(createUserUrl, json=req_body)
        if response.status_code == 409:
            LOGGER.debug("User %r already exists", username)
            return
        response.raise_for_status()

        # for craycli to work, the user must be a member of a group with
        # the correct permissions
        userId = self.get_cli_user_id(username)
        if userId == "":
            LOGGER.error(f"Unable to get keycloak user: {username} - user creation failed")
            sys.exit(1)
        groupId = self.get_grp_id(group)
        if groupId == "":
            LOGGER.error(f"Unable to get keycloak group id for group: {group} - user creation failed")
            sys.exit(1)

        # put together the required url to add the user to the group
        addGrpUrl = (f"{self.keycloak_base}/admin/realms/{self.SHASTA_REALM_NAME}"
                    f"/users/{userId}/groups/{groupId}")
        response = self._kc_master_admin_client.put(addGrpUrl)
        response.raise_for_status()

        LOGGER.info(f"Created user {username} in group {group}")

    # delete the given user from keycloak
    def delete_user(self, username):
        # check the input
        if username == "":
            LOGGER.error("Attempting to delete empty username")
            return

        # get the user id of the desired user
        userId = self.get_cli_user_id(username)
        if userId == "":
            LOGGER.debug(f"Specified user {username} does not exist in keycloak")
            return

        # user exists, so delete this user from keycloak
        url = f"{self.keycloak_base}/admin/realms/{self.SHASTA_REALM_NAME}/users/{userId}"
        response = self._kc_master_admin_client.delete(url)
        response.raise_for_status()
        LOGGER.info("Deleted user %r", username)

    # get the keycloak user id for a given username
    def get_cli_user_id(self, username):
        LOGGER.debug(f"Looking for id of user: {username}")
        # check the input
        if username == "":
            LOGGER.error("Attempting to find the user id of an empty username")
            return ""

        # search for the users that match the expected user
        url = (f"{self.keycloak_base}/admin/realms"
               f"/{self.SHASTA_REALM_NAME}/users/?username={username}")
        response = self._kc_master_admin_client.get(url)
        response.raise_for_status()

        # parse through the responses - returns a list of json objects
        user_id = ""
        items = response.json()
        for item in items:
            if item["username"] == username:
                user_id = item["id"]

        # report what we found
        LOGGER.debug(f"Keycloak user id: {user_id}")
        return user_id

    # get the keycloak user id for a given username
    def get_grp_id(self, groupname):
        # check the input
        if groupname == "":
            LOGGER.error("Attempting to find the group id of an empty groupname")
            return ""

        # search for the users that match the expected user
        url = (f"{self.keycloak_base}/admin/realms/{self.SHASTA_REALM_NAME}/"
                f"groups?search={groupname}")
        response = self._kc_master_admin_client.get(url)
        response.raise_for_status()

        # parse through the responses - returns a list of json objects
        group_id = ""
        items = response.json()
        for item in items:
            if item["name"] == groupname:
                group_id = item["id"]

        # report what we found
        LOGGER.debug(f"Group id: {group_id}")
        return group_id

def read_keycloak_master_admin_secrets(k8sClientApi):
    # read the secrets from the k8s client
    try:
        sec = k8sClientApi.read_namespaced_secret("keycloak-master-admin-auth",
                "services").data
        return {
            'client_id': base64.b64decode(sec['client-id']),
            'user': base64.b64decode(sec['user']),
            'password': base64.b64decode(sec['password'])
        }
    except client.exceptions.ApiException:
        LOGGER.error(f"Keycloak master admin secret not present")
        sys.exit(1)

def run_remote_command(host, cmdOpt):
    # copy the script file to the remote host
    fileCpCmd = ["scp", THIS_FILE_FULL_PATH, f"{host}:{REMOTE_FILE_NAME}"]
    cpOut = subprocess.run(fileCpCmd, shell=False, stdout=subprocess.PIPE, 
        stderr=subprocess.STDOUT)

    # check for copy failure
    outStr = cpOut.stdout.decode().rstrip()
    rc = cpOut.returncode
    if rc == 0:
        # copying the script was successful - run the script command on the
        # remote host using ssh - capture output
        cmdStr = f"python3 {REMOTE_FILE_NAME} {cmdOpt}"
        exeOut = subprocess.run(["ssh","-oStrictHostKeyChecking=no", host, cmdStr], 
            shell=False, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

        # if the script file is not present on the remote machine, we need to
        # interpret that and intercept the error message here
        outStr = exeOut.stdout.decode().rstrip()
        rc = exeOut.returncode
        if rc == 1 and "python3: can't open file" in outStr:
            rc = MSG_MISSING_SCRIPT
        elif rc == 1 and "Traceback" in outStr:
            rc = MSG_PYTHON_SCRIPT_ERROR
    else:
        # failed to copy the script to the remote host
        rc = MSG_REMOTE_COPY_FAILURE

    # report results for this host in a thread safe manner
    report_remote_init_results(host, rc, outStr)

# mechanism for reporting remote initialization results
def report_remote_init_results(host, retCode, message):
    # add the item to the results list
    global remote_init_results
    global rir_mutex
    with rir_mutex:
        remote_init_results[host] = (retCode, message)

# get the access token to use the k8s gateway
def getToken(k8sClientApi):
    # get the secret to request a token for gateway access
    LOGGER.debug(f"Getting k8s gateway access token")
    cs = ""
    try:
        sec = k8sClientApi.read_namespaced_secret("admin-client-auth","services").data
        cs = base64.b64decode(sec["client-secret"])
        LOGGER.debug(f"Read client auth secret")
    except client.exceptions.ApiException as err:
        LOGGER.error(f"Unable to read keycloak client auth secret: {err}")
        raise SystemExit(err)

    # construct the http call information
    keycloak_endpoint = DEFAULT_KEYCLOAK_BASE + "/realms/shasta/protocol/openid-connect/token"
    req_body = {
        'grant_type': 'client_credentials',
        'client_id': 'admin-client',
        'client_secret': cs 
    }

    # make the call and parse response
    token = ""
    try:
        LOGGER.debug(f"Querying keycloak for access token")
        response = requests.post(keycloak_endpoint, data=req_body)
        response.raise_for_status()
        token = response.json()["access_token"]
    except requests.exceptions.ConnectionError as err:
        LOGGER.error(f"Unable to connect to keycloak endpoint: {err}")
        raise SystemExit(err)
    except requests.exceptions.HTTPError as err:
        LOGGER.error(f"Unable to obtain gateway token: {err}")
        raise SystemExit(err)

    return token

# get the management nodes from sls
def getSlsNodes(k8sClientApi):
    # TODO: with powerDNS changes, need to add '.hmn' or '.nmn' to the hostnames

    LOGGER.debug(f"Finding ncn nodes on the cluster through SLS")

    # mimic the call: 
    # cray sls hardware list --format json | jq '.[]|select(.ExtraProperties.Role=="Management")|.ExtraProperties.Aliases[0]' | sort

    # get the gateway access token
    token = getToken(k8sClientApi)

    # search for the users that match the expected user
    sls_url = f"{DEFAULT_SLS_BASE}/hardware"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    response = requests.get(sls_url, headers=headers)
    response.raise_for_status()

    # parse through the responses - returns a list of json objects
    nodes = []
    for item in response.json():
        # filter out the management nodes
        if 'TypeString' in item and item['TypeString']=="Node" and 'ExtraProperties' in item:
            # have a node with extra properties defined - see if this is a management node
            ep = item['ExtraProperties']
            if 'Role' in ep and ep['Role'] == "Management" and 'Aliases' in ep:
                nodes.append(ep['Aliases'][0])

    # sort the node names just for fun
    if len(nodes) > 1:
        nodes.sort()

    LOGGER.debug(f"Nodes found: {nodes}")
    return nodes

def doRun(k8sClientApi, kcGroup):
    # Read or create the cli user secret
    tmpUser = CliUserAuth(
            createIfNeeded = True,
            k8sClientApi = k8sClientApi)

    # initialize the keycloak access helper
    LOGGER.info("Loading keycloak secrets.")
    kc_master_admin_secrets = read_keycloak_master_admin_secrets(k8sClientApi)
    keycloak_base = os.environ.get('KEYCLOAK_BASE', DEFAULT_KEYCLOAK_BASE)
    ks = KeycloakSetup(
        keycloak_base=keycloak_base,
        kc_master_admin_client_id=kc_master_admin_secrets['client_id'],
        kc_master_admin_username=kc_master_admin_secrets['user'],
        kc_master_admin_password=kc_master_admin_secrets['password'],
    )

    # create the user in keycloak
    ks.create_user(tmpUser.tu_username, tmpUser.tu_password, kcGroup)

    # call the initialization on the set of nodes
    LOGGER.info("Initializing nodes:")
    nodes = getSlsNodes(k8sClientApi)
    cmdOpt = "--initnode"
    callRemoteFunc(nodes, cmdOpt)

def callRemoteFunc(nodes, cmdOpt):
    # reset the remote call results
    global remote_init_results
    remote_init_results = dict()

    # call remoteFunc on each host in a separate thread
    runThreads = []
    for node in nodes:
        t = Thread(target=run_remote_command, args=(node,cmdOpt))
        runThreads.append(t)
        t.start()

    # wait for all threads to finish
    for t in runThreads:
        t.join()

    # report successful initializations first, collecting failed nodes
    failedNodes = []
    for host, results in sorted(remote_init_results.items()):
        if results[0]==0:
            LOGGER.info(f"{host}: Success")
        else:
            failedNodes.append(host)

    # report errors
    for fn in failedNodes:
        results = remote_init_results[fn]
        if results[0] >= MSG_USER_SECRET and results[0]<MSG_LAST:
            # given a failure code we know - log the message
            LOGGER.error(f"{fn}: ERROR: {INIT_FAILURE_MSG[results[0]]}")
            # log the entire call output if debug logging requested
            LOGGER.debug(f"{fn}: {results[1]}")
        else:
            # unknown message, display the entire thing
            LOGGER.error(f"{fn}: {results[1]}")

# Do initialization of cray cli on an individual node
def doIndividualInit(k8sClientApi):
    """
    This will only read the user secret and use it to initialize and
    authorize the cray cli, it will not create the user secret.  That
    must be done before calling this function.

    Return codes signify the following:
    0 - success
    MSG_USER_SECRET - failed to get user secret
    MSG_CRAY_INIT - calling 'cray init' failed
    MSG_CRAY_AUTH - calling 'cray auth login' failed
    MSG_CRAY_VERIFY - cli usage verification failed
    """
    # get the cli user secret - should not need to be created
    tmpUser = CliUserAuth(
            createIfNeeded = False,
            k8sClientApi = k8sClientApi)
    if tmpUser.tu_username == "":
        LOGGER.error(f"User not found")
        sys.exit(MSG_USER_SECRET)

    # call cray init with user
    LOGGER.info("Calling cray init")
    callExpect("cray init --overwrite",
        [('Hostname: ', DEFAULT_HOSTNAME),
        ('Username: ', tmpUser.tu_username),
        ('Password: ', tmpUser.tu_password)], MSG_CRAY_INIT)

    # call cray init with user
    LOGGER.info("Calling cray auth login")
    callExpect("cray auth login",
        [('Username: ', tmpUser.tu_username),
        ('Password: ', tmpUser.tu_password)], MSG_CRAY_AUTH)

    # verify cray cli is working
    checkCrayCli(MSG_CRAY_VERIFY)

# Helper function to try a cray cli call to verify it works
def checkCrayCli(exitErr):
    # check that the cray cli works using the below command:
    # cray artifacts buckets list -vvv
    output = subprocess.run(["cray","artifacts","buckets", "list", "-vvv"], 
        stdout=subprocess.PIPE)
    outStr = output.stdout.decode()
    s3Pass = "S3 credentials retrieved successfully" in outStr
    imsPass = "ims" in outStr
    slsPass = "sls" in outStr
    if s3Pass and imsPass and slsPass:
        LOGGER.info(f"Verified - cray cli working correctly")
    else:
        LOGGER.error(f"FAILED: Cray cli check failed with: {outStr}")
        sys.exit(exitErr)

# Helper function to call expect script with command and input pairs
def callExpect(cmdStr, inputPairs, exitErr):
    # Use expect to call cray init with the temporary user
    child = pexpect.spawn(cmdStr)

    # loop through the expected input/output args
    for i, elem in enumerate(inputPairs):
        child.expect(elem[0])
        child.sendline(elem[1])

    # capture the rest of the output and wait for the process to exit
    child.expect(pexpect.EOF)
    child.wait()

    # check on the status and exit program on failure
    if child.exitstatus != 0:
        # something went wrong - pull info out and bail
        LOGGER.error(f"Error detected")
        bStr = child.before.decode()
        errPos = bStr.find("Error")
        if errPos != -1:
            LOGGER.error(f"During cray init: {bStr[errPos:].rstrip()}")
        sys.exit(exitErr)

# Clear the initialization on this node
def doIndividualCleanup():
    # remove the config file to 'uninitialize' the cray cli
    # NOTE: suppress 'file does not exist' error and re-raise any other errors
    try:
        os.remove(CRAYCLI_CONFIG_FILE)
    except OSError as e:
        if e.errno == errno.ENOENT:
            sys.exit(MSG_CONFIGFILE_NOT_PRESENT)
        else:
            raise

def doCleanup(k8sClientApi):
    LOGGER.info("Removing temporary user and uninitializaing the cray cli")
    # get the cli user information - should not need to be created
    tmpUser = CliUserAuth(
            createIfNeeded = False,
            k8sClientApi = k8sClientApi)
    if tmpUser.tu_username != "":
        # remove the user from keycloak
        kc_master_admin_secrets = read_keycloak_master_admin_secrets(k8sClientApi)
        keycloak_base = os.environ.get('KEYCLOAK_BASE', DEFAULT_KEYCLOAK_BASE)
        ks = KeycloakSetup(
            keycloak_base=keycloak_base,
            kc_master_admin_client_id=kc_master_admin_secrets['client_id'],
            kc_master_admin_username=kc_master_admin_secrets['user'],
            kc_master_admin_password=kc_master_admin_secrets['password'],
        )
        ks.delete_user(tmpUser.tu_username)
    else:
        LOGGER.error("During cleanup no CLI User Auth Secret present")

    # remove the secret from k8s
    tmpUser.deleteSecret()

    # remove the individual configuration files to 'uninitialize' cray cli
    LOGGER.info("Uninitializing nodes:")
    nodes = getSlsNodes(k8sClientApi)
    cmdOpt = "--cleanupnode"
    callRemoteFunc(nodes, cmdOpt)

def doReinitCleanup(k8sClientApi, username, password):
    # clean out the temporary user initialization
    doCleanup(k8sClientApi)

    LOGGER.info(f"Re-initializing the cray cli with existing keycloak user {username}")

    # create a new secret with the new username and password - used
    # by individual node initialization
    reinitUser = CliUserAuth(
            createIfNeeded = True,
            k8sClientApi = k8sClientApi,
            username = username,
            password = password)
    if reinitUser.tu_username != "":
        # the initnode function pulls user/password from secret we just created
        LOGGER.info("Initializing nodes:")
        nodes = getSlsNodes(k8sClientApi)
        cmdOpt = "--initnode"
        callRemoteFunc(nodes, cmdOpt)
    else:
        LOGGER.error("Failed to create new reinitialization user secret")

    # remove the secret from k8s
    reinitUser.deleteSecret()


def main():
    # get the command line arguments
    # NOTE: user must specify one of the following
    parser = argparse.ArgumentParser()
    parser.add_argument("--run", action="store_true", 
        help="Run the script to create keycloak user and initialize craycli on all ncn hosts")
    parser.add_argument("--cleanup", action="store_true", 
        help="Remove craycli initialization and clean up keycloak user")
    parser.add_argument("--initnode", action="store_true", 
        help="Initiailze craycli on this host")
    parser.add_argument("--cleanupnode", action="store_true", 
        help="Cleanup craycli on this host")
    parser.add_argument("--debug", action="store_true", 
        help="Display debug level log messages")
    parser.add_argument('-u', "--username", nargs='?', 
        help='Optional new user for re-init on cleanup')
    parser.add_argument('-p', "--password", nargs='?', 
        help='Optional password for re-init on cleanup')
    parser.add_argument('-g', "--group", nargs='?',
        help='Optional group for new keycloak user permissions')
    args = parser.parse_args()

    # set up logging
    logLevel = logging.INFO
    if args.debug == True:
        logLevel = logging.DEBUG
    log_format = "%(asctime)-15s - %(levelname)-7s - %(message)s"
    logging.basicConfig(level=logLevel, format=log_format)

    # make sure a selection has been chosen
    if not args.run and not args.initnode and not args.cleanup and not args.cleanupnode:
        LOGGER.error("Incorrect input syntax")
        parser.print_help()
        sys.exit(1)

    # Load K8s configuration
    k8sConfig = config.load_kube_config()
    k8sClientApi = client.CoreV1Api()

    # figure out which part we are running
    if args.run == True:
        # see if the user supplied a group
        grp = DEFAULT_KEYCLOAK_GROUP
        if args.group != None:
            grp = args.group

        doRun(k8sClientApi, grp)
    elif args.cleanup == True:
        # see if there is a re-init or just cleanup
        if args.username != None and args.password != None:
            doReinitCleanup(k8sClientApi, args.username, args.password)
        elif args.username != None and args.password == None:
            LOGGER.error("Must supply a password with username for reinitialization")
        else:
            doCleanup(k8sClientApi)
    elif args.initnode == True:
        doIndividualInit(k8sClientApi)
    elif args.cleanupnode == True:
        doIndividualCleanup()

if __name__ == '__main__':
    main()
