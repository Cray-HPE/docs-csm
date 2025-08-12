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
import tempfile
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
    patch_data = '{"data":{"rollout_complete":"true"}}'
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

def main():

    # Load critical services
    config = load_configmap("rrs-mon-static", "rack-resiliency")
    try:
        critical_services_json = config['data']['critical-service-config.json']
        critical_services = json.loads(critical_services_json)['critical_services']
    except KeyError as e:
        print(f"Missing expected key in ConfigMap: {e}")
        sys.exit(1)

    # Extract critical services names
    service_names = list(critical_services.keys())

    if rollout_restart_critical_services(critical_services) == 0:
        print(f"RR critical services rollout restart successful.")
        # Set "rollout_complete" to "true" in RR dynamic ConfigMap
        set_rollout_complete("rrs-mon-dynamic", "rack-resiliency")
    else:
        print(f"RR critical services rollout restart failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
