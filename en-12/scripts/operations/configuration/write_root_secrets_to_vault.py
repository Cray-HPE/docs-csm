#!/usr/bin/env python3
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

# Reads in:
# - the hashed root user password from /etc/shadow
# - the root user SSH private key from /root/.ssh/id_rsa
# - the root user SSH public key from /root/.ssh/id_rsa.pub
#
# Writes these to the secret/csm/users/root in Vault, and then
# reads them back to verify that they match what was written.
#
# Beyond validating the inputs, currently this script does minimal error-checking.
# This is because it is desirable for any errors to be fatal, so catching the
# Python exceptions is only useful inasmuch as it gives the opportunity to translate
# the error into a more user-friendly format. This is certainly something that should
# eventually be implemented, but for the initial version of this tool, it is not
# necessary.

import base64
import kubernetes
import kubernetes.client
import kubernetes.client.api
import kubernetes.config
import requests
import sys
import time

VAULT_SECRET_FIELD_NAMES = [ "password", "ssh_private_key", "ssh_public_key" ]

def stdout_write_flush(msg):
    sys.stdout.write(msg)
    sys.stdout.flush()

def err(msg):
    sys.stderr.write("ERROR: {}\n".format(msg))
    sys.stderr.flush()

def err_exit(msg):
    err(msg)
    sys.exit(1)

def read_file(filename):
    """
    Reads contents of text file, verifies it is more than a few characters long,
    and returns it as a string. The length check could be refined to be
    more precise, but this will suffice.
    """

    print("Reading in file '%s'" % filename, flush=True)
    try:
        with open(filename, "rt") as textfile:
            contents = textfile.read()
    except FileNotFoundError:
        err_exit("File '%s' does not exist" % filename)
    if len(contents) < 4:
        err_exit("File '%s' only contains %d characters" % (filename, len(contents)))
    return contents

def get_root_hash_from_etc_shadow():
    """
    Find the line in /etc/shadow for the root user and return the
    hashed password field from that line.
    """

    for etc_shadow_line in read_file("/etc/shadow").splitlines():
        line_fields = etc_shadow_line.split(":")
        if line_fields[0] != "root":
            continue
        print("Found root user line in /etc/shadow", flush=True)
        # Hash is in the second field of this line
        root_password_hash = line_fields[1]
        if not root_password_hash:
            err_exit("No password hash found on root user line")
        return root_password_hash
    err_exit("No root user line found in /etc/shadow file")

def get_vault_api_endpoint_url(k8s_core_v1_api):
    """
    1. Looks up the vault/cray-vault service in Kubernetes
    2. Retrieves the cluster IP address of the service
    3. Retrieves the port list of the service
    4. Finds the API port.
    5. Assembles the URL for the Vault API endpoint URL for the secret/csm/users/root Vault entry
       and returns it as a string.
    """
    vault_service = k8s_core_v1_api.read_namespaced_service(name="cray-vault", namespace="vault")
    vault_ip = vault_service.spec.cluster_ip
    for vault_port in vault_service.spec.ports:
        if vault_port.name == 'http-api-port':
            return "http://{ip}:{port}/v1/secret/csm/users/root".format(ip=vault_ip, port=vault_port.port)
    err_exit("No 'http-api-port' port found for vault/cray-vault Kubernetes service")

def make_api_request_with_retries(request_method, url, expected_status_code, **request_kwargs):
    """
    Makes request with specified method to specified URL with specified keyword arguments (if any).
    If the expected status code is returned, then the response body is returned (or None, if empty).
    If a 5xx status code is returned, the request will be retried after a brief wait, a limited number
    of times.
    If the expected status code is never returned (or an unexpected and non-5xx status code is
    ever returned), then exit in error.
    """
    count=0
    max_attempts=6
    while count < max_attempts:
        count+=1
        print("Making {method} request to {url}".format(method=request_method.__name__.upper(), url=url), flush=True)
        resp = request_method(url, **request_kwargs)
        print("Response status code = {}".format(resp.status_code), flush=True)
        if resp.status_code == expected_status_code:
            if resp.text:
                return resp.json()
            else:
                return None
        print("Response reason = {}".format(resp.reason), flush=True)
        print("Response text = {}".format(resp.text), flush=True)
        if not 500 <= resp.status_code <= 599:
            err_exit("Unexpect status code received in response to API request")
        elif count >= max_attempts:
            err_exit("API request unsuccessful even after {} attempts".format(max_attempts))
        stdout_write_flush("Sleeping 3 seconds before retrying..")
        for x in range(3):
            stdout_write_flush(".")
            time.sleep(1)
        stdout_write_flush("\n\n")
    err_exit("PROGRAMMING LOGIC ERROR: Should never reach this point in the make_api_request_with_retries function")

def main():
    """
    1. Read in the SSH keys and hashed root password from the system.
    2. Initialize the Kubernetes API client.
    3. Get the Vault token from the cray-vault-unseal-keys secret in Kubernetes.
    4. Write the SSH keys and hashed password into Vault.
    5. Read the SSH keys and hashed password from Vault.
    6. Verify that what was read matches what was written.
    """

    # Read in secrets from the system
    system_secrets = {
        "ssh_private_key": read_file("/root/.ssh/id_rsa"),
        "ssh_public_key": read_file("/root/.ssh/id_rsa.pub"),
        "password": get_root_hash_from_etc_shadow() }

    # Initialize our Kubernetes API client
    print("\nInitializing Kubernetes client", flush=True)
    kubernetes.config.load_kube_config()
    k8s_configuration = kubernetes.client.Configuration().get_default_copy()
    kubernetes.client.Configuration.set_default(k8s_configuration)
    k8s_core_v1_api = kubernetes.client.api.core_v1_api.CoreV1Api()

    # Obtain Vault token string from Kubernetes secret
    print("\nGetting Vault token from vault/cray-vault-unseal-keys Kubernetes secret", flush=True)
    vault_secret = k8s_core_v1_api.read_namespaced_secret(name="cray-vault-unseal-keys", namespace="vault")
    encoded_vault_token = vault_secret.data["vault-root"]
    decoded_token_bytes = base64.standard_b64decode(encoded_vault_token)
    # Convert from bytes to string for API request header
    vault_api_request_headers = { 
        "X-Vault-Request": "true", 
        "X-Vault-Token": decoded_token_bytes.decode() }

    # Obtain Vault API IP address and port from Kubernetes cray-vault service
    print("\nExamining Kubernetes cray-vault service to determine URL for Vault API endpoint of secret/csm/users/root", flush=True)
    vault_api_url = get_vault_api_endpoint_url(k8s_core_v1_api)

    # Create API request session
    with requests.Session() as session:
        # The same headers are used for all requests we'll be making
        session.headers.update(vault_api_request_headers)

        # Write secrets to Vault
        print("\nWriting SSH keys and root password hash to secret/csm/users/root in Vault", flush=True)
        # We do not expect or care about any output of the write request, so no need to save the function return
        make_api_request_with_retries(request_method=session.post, url=vault_api_url, expected_status_code=204, json=system_secrets)

        # Read secrets back from Vault
        print("\nRead back secrets from Vault to verify that the values were correctly saved", flush=True)
        resp_body = make_api_request_with_retries(request_method=session.get, url=vault_api_url, expected_status_code=200)
        if resp_body == None:
            err_exit("Empty body in response to Vault API request")
        vault_secrets = { field: resp_body["data"][field] for field in VAULT_SECRET_FIELD_NAMES }

    # Validate that Vault values match what we wrote
    print("\nValidating that Vault contents match what was written to it", flush=True)
    if vault_secrets == system_secrets:
        print("All secrets successfully written to Vault\n", flush=True)
        print("SUCCESS", flush=True)
        sys.exit(0)

    # Print summary of differences
    for field in VAULT_SECRET_FIELD_NAMES:
        if system_secrets[field] == vault_secrets[field]:
            print("Vault value for {} matches what was written".format(field), flush=True)
        else:
            err("Vault value for {} DOES NOT MATCH what was written".format(field))
    err_exit("Not all secrets successfully written to Vault")

if __name__ == '__main__':
    main()
