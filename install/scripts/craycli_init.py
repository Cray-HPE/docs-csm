#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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
This script will set up a new 'temporary' user in Keycloak and use that
account to initialize the cray CLI on all master, worker, and storage
nodes of the Kubernetes cluster.  Call the script with the '--run'
option to do this.

If any of the nodes do not have the correct Python modules installed,
or do have have Kubernetes configured, the script will fail on that node.

When the install is complete, this script can also remove the temporary
user and uninitialize the cray CLI on all master and worker nodes in the
cluster.  Call the script with the '--cleanup' option to do this.

During the cleanup operation, it is possible to initialize the cray CLI with
a different existing Keycloak user account.  To do this, add a valid username
and password to the cleanup call:
python3 craycli_init.py --cleanup --username MY_USER --password MY_PASSWORD

The --nodeinit and --nodecleanup options are intended primarily to be called
automatically during the 'run' or 'cleanup' operations, but may be used on
individual nodes to replicate the initialization or cleanup operation on
that specific individual node.  Just ssh to that node, then call it from there.
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
from kubernetes import client, config

# defaults
REMOTE_FILE_DIR = "/tmp/"
CRAYCLI_CONFIG_FILE = "/root/.config/cray/configurations/default"
DEFAULT_HOSTNAME = 'api-gw-service-nmn.local'
DEFAULT_KEYCLOAK_BASE = 'https://' + DEFAULT_HOSTNAME + '/keycloak'
DEFAULT_SLS_BASE = 'https://' + DEFAULT_HOSTNAME + '/apis/sls/v1'

# Global file names and locations
THIS_FILE_FULL_PATH = os.path.abspath(__file__)
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
MSG_K8S_NOT_CONFIGURED = 109
MSG_SSH_ERROR = 110
MSG_LAST = 111
INIT_FAILURE_MSG = {
    MSG_USER_SECRET : "Failed to obtain user secret",
    MSG_REMOTE_COPY_FAILURE : "Failed to copy script to remote host",
    MSG_CRAY_INIT : "Call to cray init failed",
    MSG_CRAY_AUTH : "Call to cray auth login failed",
    MSG_CRAY_VERIFY : "Verification that cray CLI is operational failed",
    MSG_MISSING_SCRIPT : "Script missing on remote node",
    MSG_CONFIGFILE_NOT_PRESENT : "Initialization file not present",
    MSG_PYTHON_SCRIPT_ERROR : "Python script failed",
    MSG_K8S_NOT_CONFIGURED : "Kubernetes not configured on this node",
    MSG_SSH_ERROR : "Error using passwordless ssh with this node",
}

class CliUserAuth(object):
    """
    Class to manage access to the secret that holds the username and password
    being used for cray CLI authentication/initialization.

    The information is stored in a k8s secret so that it can be accessed from multiple
    nodes at different times to get the same information.
    """

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
        # delete the secret if it exists
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
                LOGGER.error(f"Error attempting to delete CLI user secret: {err}")

    def _getOrCreateUser(self):
        # if the secret already exists, read the username and password
        sec = None
        try: 
            sec = self._k8sClientApi.read_namespaced_secret(self.CLI_USER_AUTH_SECRET_NAME, "services")
            LOGGER.debug(f"Read existing tmp CLI user secret")
        except client.exceptions.ApiException:
            LOGGER.debug(f"Temp CLI user secret not present")

        # if the secret does not exist, create a new one
        if sec == None and self._createIfNeeded:
            LOGGER.debug(f"Creating new tmp CLI user secret")

            # get username and password to use - defaults or specified
            newUser = self.CLI_USER_USERNAME
            if self._newUser != None:
                newUser = self._newUser

            newPassword = self._newPassword
            if newPassword == None:
                # generate a random password
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
                LOGGER.error(f"Error attempting to create CLI user secret: {err}")
                sys.exit(1)

        # pull the values from the secret if present
        if sec != None:
            self._tu_username = base64.b64decode(sec.data['user']).decode('ascii')
            self._tu_password = base64.b64decode(sec.data['password']).decode('ascii')
        return

class KeycloakSetup(object):
    """
    Class to wrap Keycloak authentication with calls to the Keycloak rest api.
    """

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

    # Create the user in Keycloak with the given password
    def create_user(self, username, password):
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
            ]
        }

        # make the call and parse response
        response = self._kc_master_admin_client.post(createUserUrl, json=req_body)
        if response.status_code == 409:
            LOGGER.debug("User %r already exists", username)
            return
        response.raise_for_status()

        # get the id of the user just created
        userId = self.get_cli_user_id(username)
        if userId == "":
            LOGGER.error(f"Unable to get Keycloak user: {username} - user creation failed")
            sys.exit(1)

        # add the following roles to allow correct permissions to run cray CLI
        addedShastaRole = self.add_role(userId, "shasta", "admin")
        addedCrayRole = self.add_role(userId, "cray", "admin")

        # make sure adding at least one role succeeded
        if not addedShastaRole and not addedCrayRole:
            LOGGER.warning(f"Did not add user roles, this user may not have the correct permissions required.")

        LOGGER.info(f"Created user {username}")

    # delete the given user from Keycloak
    def delete_user(self, username):
        # check the input
        if username == "":
            LOGGER.error("Attempting to delete empty username")
            return

        # get the user id of the desired user
        userId = self.get_cli_user_id(username)
        if userId == "":
            LOGGER.debug(f"Specified user {username} does not exist in Keycloak")
            return

        # user exists, so delete this user from Keycloak
        url = f"{self.keycloak_base}/admin/realms/{self.SHASTA_REALM_NAME}/users/{userId}"
        response = self._kc_master_admin_client.delete(url)
        response.raise_for_status()
        LOGGER.info("Deleted user %r", username)

    # get the Keycloak user id for a given username
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
                break

        # report what we found
        LOGGER.debug(f"Keycloak user id: {user_id}")
        return user_id

    # get the Keycloak client id for a given client name
    def add_role(self, user_id, clientName, roleName):
        # search for the users that match the expected user
        url = (f"{self.keycloak_base}/admin/realms/{self.SHASTA_REALM_NAME}/"
                f"clients?search={clientName}")
        response = self._kc_master_admin_client.get(url)
        response.raise_for_status()

        # parse through the responses - returns a list of json objects
        client_id = ""
        items = response.json()
        for item in items:
            if item["clientId"] == clientName:
                client_id = item["id"]

        # make sure we found something
        if client_id == "":
            LOGGER.error(f"Unable to find client: {clientName} - unable to add role:{clientName}:{roleName}")
            return False

        # find the requested role under the client
        role_id = ""
        role_name = ""
        url = (f"{self.keycloak_base}/admin/realms/{self.SHASTA_REALM_NAME}/clients/{client_id}/roles")
        response = self._kc_master_admin_client.get(url)
        response.raise_for_status()
        roles = response.json()
        for role in roles:
            if role["name"] == roleName:
                role_id = role["id"]
                role_name = role["name"]
                LOGGER.debug(f"  Found: {role_id}:{role_name}")
        
        # make sure we found one
        if role_id == "":
            LOGGER.error(f"Unable to find client role: {roleName} - unable to add role:{clientName}:{roleName}")
            return False

        # add the role to the user
        addRoleUrl = (f"{self.keycloak_base}/admin/realms/{self.SHASTA_REALM_NAME}/users/{user_id}/role-mappings/clients/{client_id}")
        req_body = [
            {
                "id": role_id,
                "name": role_name
            }
        ]
        response = self._kc_master_admin_client.post(addRoleUrl, json=req_body)
        if response.status_code > 399:
            LOGGER.info(f"Unable to add role: {clientName}:{roleName}")
            return False

        LOGGER.debug(f"Added role: {clientName}:{roleName}")
        return True

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
    except client.exceptions.ApiException as err:
        LOGGER.error(f"Keycloak master admin secret not present: {err}")
        sys.exit(1)

def checkSsh(host):
    LOGGER.debug(f"Ensuring passwordless ssh set up for {host}")

    # spawn the ssh command to the host
    child = pexpect.spawn(f"ssh {host}")

    # we expect either a prompt that the key has not been added yet, or
    # a command prompt if it is present
    idx = child.expect_exact(['#', '?', pexpect.EOF, pexpect.TIMEOUT])
    if idx==0:
        # good - all is well
        LOGGER.debug(  "ssh key already present")
    elif idx==1:
        # not added as key yet, say 'yes'
        child.sendline("yes")
        LOGGER.debug(  "ssh key added for host")

        # now we should get the command prompt
        child.expect("#")
    elif idx==2:
        # should not have exited yet
        msg = "Should not have recieved EOF from ssh"
        LOGGER.warning(  f"{host}: " + msg)
        return MSG_SSH_ERROR, msg
    elif idx==3:
        msg = "Timeout waiting for ssh"
        LOGGER.warning(  f"{host}: " + msg)
        return MSG_SSH_ERROR, msg

    # logout, capture the rest of the output, and wait for the process to exit
    child.sendline("exit")
    idx = child.expect([pexpect.EOF, pexpect.TIMEOUT])
    child.wait()
    return 0, ""

def run_remote_command(host, cmdOpt):
    # make sure passwordless ssh is set up without return prompts to
    # mess up the scripts
    rc, outStr = checkSsh(host)

    # only run the rest of the commands if the ssh key is established correctly
    if rc==0:
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
            exeOut = subprocess.run(["ssh", host, f"python3 {REMOTE_FILE_NAME} {cmdOpt}"],
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
        LOGGER.error(f"Unable to read Keycloak client auth secret: {err}")
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
        LOGGER.debug(f"Querying Keycloak for access token")
        response = requests.post(keycloak_endpoint, data=req_body)
        response.raise_for_status()
        token = response.json()["access_token"]
    except requests.exceptions.ConnectionError as err:
        LOGGER.error(f"Unable to connect to Keycloak endpoint: {err}")
        raise SystemExit(err)
    except requests.exceptions.HTTPError as err:
        LOGGER.error(f"Unable to obtain gateway token: {err}")
        raise SystemExit(err)

    return token

# get the management nodes from sls
def getSlsNodes(k8sClientApi):
    # TODO: with powerDNS changes, need to add '.hmn' or '.nmn' to the hostnames
    # https://jira-pro.its.hpecorp.net:8443/browse/CASMCMS-7474

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

def doRun(k8sClientApi, makeUserOnly):
    # Read or create the CLI user secret
    tmpUser = CliUserAuth(
            createIfNeeded = True,
            k8sClientApi = k8sClientApi)

    # initialize the Keycloak access helper
    LOGGER.info("Loading Keycloak secrets.")
    kc_master_admin_secrets = read_keycloak_master_admin_secrets(k8sClientApi)
    keycloak_base = os.environ.get('KEYCLOAK_BASE', DEFAULT_KEYCLOAK_BASE)
    ks = KeycloakSetup(
        keycloak_base=keycloak_base,
        kc_master_admin_client_id=kc_master_admin_secrets['client_id'],
        kc_master_admin_username=kc_master_admin_secrets['user'],
        kc_master_admin_password=kc_master_admin_secrets['password'],
    )

    # create the user in Keycloak
    ks.create_user(tmpUser.tu_username, tmpUser.tu_password)

    # call the initialization on the set of nodes
    if makeUserOnly:
        LOGGER.info("Set to only make user, not initializing nodes")
    else:
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
            LOGGER.warning(f"{fn}: WARNING: {INIT_FAILURE_MSG[results[0]]}")
            # log the entire call output if debug logging requested
            LOGGER.debug(f"{fn}: {results[1]}")
        else:
            # unknown message, display the entire thing
            LOGGER.warning(f"{fn}: {results[1]}")

# Do initialization of cray CLI on an individual node
def doIndividualInit(k8sClientApi):
    """
    This will only read the user secret and use it to initialize and
    authorize the cray CLI, it will not create the user secret.  That
    must be done before calling this function.

    Return codes signify the following:
    0 - success
    MSG_USER_SECRET - failed to get user secret
    MSG_CRAY_INIT - calling 'cray init' failed
    MSG_CRAY_AUTH - calling 'cray auth login' failed
    MSG_CRAY_VERIFY - CLI usage verification failed
    MSG_K8S_NOT_CONFIGURED - k8s not configured on this node
    """
    # get the CLI user secret - should not need to be created
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

    # call cray auth with user
    LOGGER.info("Calling cray auth login")
    callExpect("cray auth login",
        [('Username: ', tmpUser.tu_username),
        ('Password: ', tmpUser.tu_password)], MSG_CRAY_AUTH)

    # verify cray CLI is working
    checkCrayCli(MSG_CRAY_VERIFY)

# Helper function to try a cray CLI call to verify it works
def checkCrayCli(exitErr):
    # check that the cray CLI works using the below command:
    # cray artifacts buckets list -vvv
    output = subprocess.run(["cray","artifacts","buckets", "list", "-vvv"], 
        stdout=subprocess.PIPE)
    outStr = output.stdout.decode()
    s3Pass = "S3 credentials retrieved successfully" in outStr
    imsPass = "ims" in outStr
    slsPass = "sls" in outStr
    if s3Pass and imsPass and slsPass:
        LOGGER.info(f"Verified - cray CLI working correctly")
    else:
        LOGGER.warning(f"WARNING: Cray CLI check failed with: {outStr}")
        sys.exit(exitErr)

# Helper function to call expect script with command and input pairs
def callExpect(cmdStr, inputPairs, exitErr):
    # Use expect to call cray init with the temporary user
    child = pexpect.spawn(cmdStr)

    # loop through the expected input/output args
    for elem in inputPairs:
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
    # remove the config file to 'uninitialize' the cray CLI
    # NOTE: suppress 'file does not exist' error and re-raise any other errors
    try:
        os.remove(CRAYCLI_CONFIG_FILE)
    except OSError as e:
        if e.errno == errno.ENOENT:
            sys.exit(MSG_CONFIGFILE_NOT_PRESENT)
        else:
            raise

def doCleanup(k8sClientApi):
    LOGGER.info("Removing temporary user and uninitializing the cray CLI")
    # get the CLI user information - should not need to be created
    tmpUser = CliUserAuth(
            createIfNeeded = False,
            k8sClientApi = k8sClientApi)
    if tmpUser.tu_username != "":
        # remove the user from Keycloak
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

    # remove the individual configuration files to 'uninitialize' cray CLI
    LOGGER.info("Uninitializing nodes:")
    nodes = getSlsNodes(k8sClientApi)
    cmdOpt = "--cleanupnode"
    callRemoteFunc(nodes, cmdOpt)

def doReinitCleanup(k8sClientApi, username, password):
    # clean out the temporary user initialization
    doCleanup(k8sClientApi)

    LOGGER.info(f"Re-initializing the cray CLI with existing Keycloak user {username}")

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
        help="Run the script to create Keycloak user and initialize craycli on all ncn hosts")
    parser.add_argument("--cleanup", action="store_true", 
        help="Remove craycli initialization and clean up Keycloak user")
    parser.add_argument("--initnode", action="store_true", 
        help="Initialize cray CLI on this host")
    parser.add_argument("--cleanupnode", action="store_true", 
        help="Cleanup craycli on this host")
    parser.add_argument("--debug", action="store_true", 
        help="Display debug level log messages")
    parser.add_argument('-u', "--username", nargs='?', 
        help='Optional new user for re-init on cleanup')
    parser.add_argument('-p', "--password", nargs='?', 
        help='Optional password for re-init on cleanup')
    parser.add_argument('-userOnly', action="store_true",
        help='Only create a new user and exit - used with --run')
    args = parser.parse_args()

    # set up logging
    logLevel = logging.INFO
    if args.debug:
        logLevel = logging.DEBUG
    log_format = "%(asctime)-15s - %(levelname)-7s - %(message)s"
    logging.basicConfig(level=logLevel, format=log_format)

    # make sure a selection has been chosen
    if not args.run and not args.initnode and not args.cleanup and not args.cleanupnode:
        LOGGER.error("Incorrect input syntax")
        parser.print_help()
        sys.exit(1)

    # Load K8s configuration
    k8sConfig = None
    k8sClientApi = None
    try:
        k8sConfig = config.load_kube_config()
        k8sClientApi = client.CoreV1Api()
    except Exception as err:
        LOGGER.error(f"Error initializing k8s: {err}")
        sys.exit(MSG_K8S_NOT_CONFIGURED)

    # figure out which part we are running
    if args.run:
        doRun(k8sClientApi, args.userOnly)
    elif args.cleanup:
        # see if there is a re-init or just cleanup
        if args.username != None and args.password != None:
            doReinitCleanup(k8sClientApi, args.username, args.password)
        elif args.username != None and args.password == None:
            LOGGER.error("Must supply a password with username for reinitialization")
        else:
            doCleanup(k8sClientApi)
    elif args.initnode:
        doIndividualInit(k8sClientApi)
    elif args.cleanupnode:
        doIndividualCleanup()

if __name__ == '__main__':
    main()
