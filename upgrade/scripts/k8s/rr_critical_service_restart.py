#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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
Do rollout restart of the critical services defined in RR static ConfigMap.
"""

import json
import subprocess
import sys
import base64
import os
from typing import Dict, NoReturn

from typing_extensions import TypedDict
import yaml

CUSTOMIZATIONS="/tmp/customization.yaml"

def print_stderr(msg: str) -> None:
    """
    Write the specified message to stderr with a newline appended.
    Then flush the buffer, to make sure it is written immediately.
    """
    sys.stderr.write(f"{msg}\n")
    sys.stderr.flush()

def err_exit(msg: str) -> NoReturn:
    """
    Prepends "ERROR: " to the message and then prints it to stderr.
    Then exits the script with rc 1
    """
    print_stderr(f"ERROR: {msg}")
    sys.exit(1)

def load_configmap(name: str, namespace: str) -> dict:
    """
    Fetch and return a ConfigMap from the specified namespace as a JSON object.
    Args:
        name (str): Name of the ConfigMap.
        namespace (str): Kubernetes namespace of the ConfigMap.
    Returns:
        dict: Parsed JSON of the ConfigMap contents.
    """
    try:
        result = subprocess.run(
            ["kubectl", "get", "configmap", name, "-n", namespace, "-o", "json"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print_stderr(f"Failed to fetch ConfigMap '{name}' from namespace '{namespace}'")
        err_exit(e.stderr)

class ServiceDetails(TypedDict):
    """
    The type (e.g. "Deployment", "StatefulSet") and namespace (e.g. "services")
    for a critical service in Kubernetes
    """
    type: str
    namespace: str

def rollout_restart_critical_services(critical_services: Dict[str, ServiceDetails]) -> bool:
    """
    Perform a rollout restart for each critical service defined in the static ConfigMap.
    Args:
        critical_services (dict): Dictionary of services with their type and namespace.
    Returns:
        bool: False if successful, True if any service restart failed.
    """
    failed_services = False

    for name, details in critical_services.items():
        resource_type = details["type"].lower()
        namespace = details["namespace"]

        # Get the resource definition
        get_command = ["kubectl", "get", resource_type, name, "-n", namespace, "-o", "json"]
        try:
            result = subprocess.run(get_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
            resource_json = json.loads(result.stdout)
        except subprocess.CalledProcessError as e:
            if f"Error from server (NotFound): {resource_type.lower()}s.apps \"{name}\" not found" in e.stderr:
                print(f"Skipping {resource_type}/{name}: resource not found in namespace {namespace}")
                continue
            print_stderr(f"Failed to get {resource_type}/{name} in namespace {namespace}: {e.stderr}")
            failed_services = True
            continue
        except json.JSONDecodeError as e:
            print_stderr(f"Failed to parse JSON for {resource_type}/{name}: {str(e)}")
            failed_services = True
            continue

        # Check for 'rrflag' label
        labels = resource_json.get("spec", {}).get("template", {}).get("metadata", {}).get("labels", {})
        if "rrflag" in labels:
            print(f"Skipping {resource_type}/{name}: 'rrflag' label is already set in namespace {namespace}")
            continue

        # Restart the service
        restart_command = ["kubectl", "rollout", "restart", f"{resource_type}/{name}", "-n", namespace]
        try:
            subprocess.run(restart_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        except subprocess.CalledProcessError as e:
            print_stderr(f"Failed to restart {resource_type}/{name} in namespace {namespace}: {e.stderr}")
            failed_services = True
            continue

        # Check rollout status
        status_command = ["kubectl", "rollout", "status", resource_type, name, "-n", namespace, "--timeout=3m"]
        try:
            subprocess.run(status_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
            print(f"Restarted {resource_type}/{name} in namespace {namespace}")
        except subprocess.CalledProcessError as e:
            print_stderr(f"Rollout status check failed for {resource_type}/{name} in namespace {namespace}: {e.stderr}")
            failed_services = True

    return failed_services

def set_rollout_complete(configmap_name: str, namespace: str) -> None:
    """
    Set the "rollout_complete" field to "true" in the specified ConfigMap.
    Args:
        configmap_name (str): Name of the ConfigMap to update.
        namespace (str): Kubernetes namespace of the ConfigMap.
    """
    cm_data = load_configmap("rrs-mon-dynamic", "rack-resiliency")
    dynamic_data_str = cm_data["data"]["dynamic-data.yaml"]
    dynamic_data = yaml.safe_load(dynamic_data_str)
    dynamic_data["state"]["rollout_complete"] = True
    updated_dynamic_data_str = yaml.safe_dump(dynamic_data)
    patch_data = {
        "data": {
            "dynamic-data.yaml": updated_dynamic_data_str
        }
    }
    patch_data = json.dumps(patch_data)

    command = [
        "kubectl", "patch", "configmap", configmap_name,
        "-n", namespace,
        "--type=merge",
        "-p", patch_data
    ]
    try:
        subprocess.run(command, check=True)
        print(f"Set rollout_complete=true in ConfigMap '{configmap_name}'")
    except subprocess.CalledProcessError as e:
        print_stderr(f"Failed to patch ConfigMap '{configmap_name}'")
        err_exit(e)

def rr_enabled():
    """
    Check if Rack Resiliency is enabled or not.
    Returns:
        bool: True if RR is enabled, False otherwise.
    """
    namespace = "loftsman"
    secret_name = "site-init"

    kubectl_cmd = ["kubectl", "-n", namespace, "get", "secret", secret_name, "-o", "json"]
    try:
        kubectl_output = subprocess.run(
            kubectl_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            check=True
        )
    except subprocess.CalledProcessError as e:
        print_stderr(f"Error fetching site-init secret: {e.stderr}")
        return False
    except Exception as e:
        print_stderr(f"error: {e}")
        return False

    # Parse JSON output
    secret_data = json.loads(kubectl_output.stdout)

    # Extract and decode the base64 data
    try:
        encoded_yaml = secret_data["data"]["customizations.yaml"]
        decoded_yaml = base64.b64decode(encoded_yaml).decode("utf-8")
        data = yaml.safe_load(decoded_yaml)
    except Exception as e:
        print_stderr(f"Failed to decode or parse customizations.yaml: {e}")
        return False

    enabled = data.get('spec', {}) \
                  .get('kubernetes', {}) \
                  .get('services', {}) \
                  .get('rack-resiliency', {}) \
                  .get('enabled')

    # The csm-config Ansible code uses its built-in `bool` filter when parsing thie field, so we
    # should do the same here. That filter interprets the following values as True:
    # strings (case insensitive): 'true', 't', 'yes', 'y', 'on', '1'
    # int: 1
    # float: 1.0
    # boolean: True
    truthy_values = {"true", "t", "yes", "y", "on", "1"}
    if isinstance(enabled, bool):
        return enabled
    if isinstance(enabled, (int, float)):
        return enabled == 1
    if isinstance(enabled, str):
        return enabled.strip().lower() in truthy_values

    return False

def is_cluster_policy_applied(policy_name: str) -> bool:
    """
    Check if a specific ClusterPolicy is applied in the Kubernetes cluster.
    Args:
        policy_name (str): Name of the ClusterPolicy to check.
        Returns:
        bool: True if the ClusterPolicy is applied, False otherwise.
    """
    try:
        subprocess.run(
            ["kubectl", "get", "clusterpolicy", policy_name],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return True
    except subprocess.CalledProcessError:
        return False

def main() -> None:
    """
    Main function to execute the rollout restart of critical services.
    """
    if not rr_enabled():
        ## RR is not enabled
        print("Rack Resiliency is not enabled. Skipping restart.")
        sys.exit(0)

    # RR is enabled
    # Check cluster policy
    if not is_cluster_policy_applied("insert-labels-topology-constraints"):
        err_exit("Rack Resiliency is enabled but ClusterPolicy 'insert-labels-topology-constraints' is not applied. Skipping restart.")

    # Load critical services
    config = load_configmap("rrs-mon-static", "rack-resiliency")
    try:
        critical_services_json = config['data']['critical-service-config.json']
        critical_services = json.loads(critical_services_json)['critical_services']
    except KeyError as e:
        err_exit(f"Missing expected key in ConfigMap: {e}")

    if rollout_restart_critical_services(critical_services):
        err_exit(f"RR critical services rollout restart failed.")

    print(f"RR critical services rollout restart successful.")
    # Set "rollout_complete" to "true" in RR dynamic ConfigMap
    set_rollout_complete("rrs-mon-dynamic", "rack-resiliency")
    print("Done!")

if __name__ == "__main__":
    main()
