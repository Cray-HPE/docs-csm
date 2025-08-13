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
import tempfile

CUSTOMIZATIONS="/tmp/customization.yaml"

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
    failed_services = []

    for name, details in critical_services.items():
        resource_type = details["type"].lower()
        namespace = details["namespace"]

        # Get the resource definition
        get_command = ["kubectl", "get", resource_type, name, "-n", namespace, "-o", "json"]
        try:
            result = subprocess.run(get_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
            resource_json = json.loads(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"Failed to get {resource_type}/{name} in namespace {namespace}: {e.stderr}")
            failed_services.append(f"{resource_type}/{name}")
            continue
        except json.JSONDecodeError as e:
            print(f"Failed to parse JSON for {resource_type}/{name}: {str(e)}")
            failed_services.append(f"{resource_type}/{name}")
            continue

        # Check for 'rrflag' label
        labels = resource_json.get("spec", {}).get("template", {}).get("metadata", {}).get("labels", {})
        if "rrflag" not in labels:
            print(f"Skipping {resource_type}/{name}: 'rrflag' label is not set in namespace {namespace}")
            continue

        # Restart the service
        restart_command = ["kubectl", "rollout", "restart", f"{resource_type}/{name}", "-n", namespace]
        try:
            subprocess.run(restart_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        except subprocess.CalledProcessError as e:
            if "not found" in e.stderr.lower():
                print(f"Skipping {resource_type}/{name}: resource not found in namespace {namespace}")
                continue
            print(f"Failed to restart {resource_type}/{name} in namespace {namespace}")
            print(f"Error: {e.stderr}")
            failed_services.append(f"{resource_type}/{name}")
            continue

        # Check rollout status
        status_command = ["kubectl", "rollout", "status", resource_type, name, "-n", namespace, "--timeout=3m"]
        try:
            subprocess.run(status_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
            print(f"Restarted {resource_type}/{name} in namespace {namespace}")
        except subprocess.CalledProcessError as e:
            print(f"Rollout status check failed for {resource_type}/{name} in namespace {namespace}")
            print(f"Error: {e.stderr}")
            failed_services.append(f"{resource_type}/{name}")

    return 0 if not failed_services else 1

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
    try:
        kubectl_output = subprocess.run(kubectl_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, check=True)
        if kubectl_output.returncode != 0:
            raise ValueError(f"Error fetching site-init secret: {kubectl_output.stderr}")
        return json.loads(kubectl_output.stdout)
    except Exception as e:
        return {"error": str(e)}

    # Parse JSON output
    secret_data = json.loads(kubectl_output.stdout)

    # Extract and decode the base64 data
    encoded_yaml = secret_data["data"]["customizations.yaml"]
    decoded_yaml = base64.b64decode(encoded_yaml).decode("utf-8")

    # Write the yaml output to a file
    output_file = CUSTOMIZATIONS
    with open(output_file, "w") as f:
        f.write(decoded_yaml)

    # Define the key path
    key_path = "spec.kubernetes.services.rack-resiliency.enabled"

    # Run yq command to extract the value
    yq_cmd = ["yq", "r", decoded_yaml, key_path]
    try:
        result = subprocess.run(yq_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, check=True)
        if result.returncode != 0:
            raise ValueError(f"Error fetching site-init secret: {result.stderr}")
        return json.loads(result.stdout)
    except Exception as e:
        return {"error": str(e)}

    # The csm-config Ansible code uses its built-in `bool` filter when parsing thie field, so we
    # should do the same here. That filter interprets the following values as True:
    # strings (case insensitive): 'true', 't', 'yes', 'y', 'on', '1'
    # int: 1
    # float: 1.0
    # boolean: True
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
    # Check if RR is enabled and cluster policy is applied
    if rr_enabled() and not is_cluster_policy_applied("insert-labels-topology-constraints"):
        print("Rack Resiliency is enabled but ClusterPolicy 'insert-labels-topology-constraints' is not applied. Skipping restart.")
        sys.exit(1)
    # Check if RR is not enabled and cluster policy is not applied
    elif not rr_enabled() and not is_cluster_policy_applied("insert-labels-topology-constraints"):
        print("Rack Resiliency is not enabled and ClusterPolicy 'insert-labels-topology-constraints' is not applied.Skipping restart.")
        sys.exit(1)
    # Check if RR is not enabled but cluster policy is applied
    elif not rr_enabled() and is_cluster_policy_applied("insert-labels-topology-constraints"):
        print("Rack Resiliency is not enabled  but ClusterPolicy 'insert-labels-topology-constraints' is applied. Skipping restart.")
        sys.exit(1)
       
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
