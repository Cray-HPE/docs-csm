#!/usr/bin/python3
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

import yaml
import json
import subprocess
import sys
import base64
import os

def load_configmap(name, namespace):
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
        print(f"Failed to fetch ConfigMap '{name}' from namespace '{namespace}'")
        print(f"Error: {e.stderr}")
        sys.exit(1)


def rollout_restart_critical_services(critical_services):
    """
    Perform a rollout restart for each critical service defined in the static ConfigMap.
    Args:
        critical_services (dict): Dictionary of services with their type and namespace.
    Returns:
        int: 0 if successful, 1 if any service restart failed.
    """
    for name, details in critical_services.items():
        resource_type = details["type"].lower()
        namespace = details["namespace"]

        # Get the resource definition in JSON
        get_command = [
            "kubectl", "get", resource_type, name,
            "-n", namespace, "-o", "json"
        ]

        try:
            result = subprocess.run(get_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
            resource_json = json.loads(result.stdout)

            # Check to if 'rrflag' is set for critical service
            labels = resource_json.get("spec", {}).get("template", {}).get("metadata", {}).get("labels", {})
            if "rrflag" not in labels:
                print(f"Skipping {resource_type}/{name}: 'rrflag' label is not set for {resource_type}/{name} in namespace {namespace}")
                continue

            # Restart the critical service
            restart_command = ["kubectl", "rollout", "restart", f"{resource_type}/{name}", "-n", namespace]
            status_command = ["kubectl", "rollout", "status", resource_type, name, "-n", namespace, "--timeout=3m"]

            subprocess.run(restart_command, check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE, universal_newlines=True)
            subprocess.run(status_command, check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE, universal_newlines=True)
            print(f"Restarted {resource_type}/{name} in namespace {namespace}")
        except subprocess.CalledProcessError as e:
            if "not found" in e.stderr.lower():
                print(f"Skipping {resource_type}/{name}: resource not found in namespace {namespace}")
                continue
            print(f"Failed to restart {resource_type}/{name} in namespace {namespace}")
            print(f"Error: {e.stderr}")
            return 1
    return 0

def set_rollout_complete(configmap_name, namespace):
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
        print(f"Failed to patch ConfigMap '{configmap_name}'")
        print(f"Error: {e}")
        sys.exit(1)


def rr_enabled():
    """
    Check if Rack Resiliency is enabled or not.
    Returns:
        bool: True if RR is enabled, False otherwise.
    """
    namespace = "loftsman"
    secret_name = "site-init"

    kubectl_cmd = ["kubectl", "-n", namespace, "get", "secret", secret_name, "-o", "json"]
    kubectl_output = subprocess.run(kubectl_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, check=True)

    # Parse JSON output
    secret_data = json.loads(kubectl_output.stdout)

    # Extract and decode the base64 data
    encoded_yaml = secret_data["data"]["customizations.yaml"]
    decoded_yaml = base64.b64decode(encoded_yaml).decode("utf-8")

    # Define the key path
    key_path = "spec.kubernetes.services.rack-resiliency.enabled"

    # Run yq command to extract the value
    yq_cmd = ["yq", "r", decoded_yaml, key_path]
    result = subprocess.run(yq_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, check=True)

    # Extract and clean the output
    enabled = result.stdout.strip()
    if any(enabled is tvalue for tvalue in [1, 1.0, True]):
        return True
    if not isinstance(enabled, str):
        return False
    return enabled.lower() in {"true", "t", "yes", "y", "on", "1"}


def is_cluster_policy_applied(policy_name):
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


def main():
    """
    Main function to execute the rollout restart of critical services.
    """
    # Check if RR is enabled and if the cluster policy is applied
    if not (rr_enabled() and is_cluster_policy_applied("insert-labels-topology-constraints")):
        print("Either Rack Resiliency is not enabled or ClusterPolicy 'insert-labels-topology-constraints' not found. Skipping restart.")
        sys.exit(0)
       
    # Load critical services
    config = load_configmap("rrs-mon-static", "rack-resiliency")
    try:
        critical_services_json = config['data']['critical-service-config.json']
        critical_services = json.loads(critical_services_json)['critical_services']
    except KeyError as e:
        print(f"Missing expected key in ConfigMap: {e}")
        sys.exit(1)

    if rollout_restart_critical_services(critical_services) == 0:
        print(f"RR critical services rollout restart successful.")
        # Set "rollout_complete" to "true" in RR dynamic ConfigMap
        set_rollout_complete("rrs-mon-dynamic", "rack-resiliency")
    else:
        print(f"RR critical services rollout restart failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
