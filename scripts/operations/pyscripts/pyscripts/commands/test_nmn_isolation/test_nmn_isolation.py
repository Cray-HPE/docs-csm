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
import subprocess
import requests
import base64
import json
import ipaddress 
import getpass 
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def get_client_secret():
    try:
        # Get the base64 encoded secret from kubectl
        result = subprocess.check_output(
            ["kubectl", "get", "secrets", "admin-client-auth", "-o", "jsonpath={.data.client-secret}"]
        )
        encoded_secret = result.decode("utf-8")
        decoded_secret = base64.b64decode(encoded_secret).decode("utf-8")
        return decoded_secret
    except Exception as e:
        print(f"Failed to get client secret: {e}")
        return None

def get_access_token(client_secret):
    token_url = "https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token"
    payload = {
        "grant_type": "client_credentials",
        "client_id": "admin-client",
        "client_secret": client_secret
    }

    try:
        response = requests.post(token_url, data=payload, verify=False)
        response.raise_for_status()
        token = response.json().get("access_token")
        return token
    except Exception as e:
        print(f"Failed to get access token: {e}")
        return None

def get_nmn_mtn_network(token):
    url = "https://api-gw-service-nmn.local/apis/sls/v1/networks/NMN_MTN"
    headers = {"Authorization": f"Bearer {token}"}

    try:
        response = requests.get(url, headers=headers, verify=False)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Failed to fetch NMN_MTN network: {e}")
        return None

def get_subnet_ips(subnet):
    """Return all usable IPs in the subnet range."""
    try:
        net = ipaddress.ip_network(subnet['CIDR'], strict=False)
        # Skip gateway & broadcast
        return [str(ip) for ip in net.hosts()]
    except ValueError:
        return []

def is_reachable(node):
    """Check if a node is reachable via ping."""
    try:
        subprocess.check_output(
            ["ping", "-c", "1", "-W", "1", node],
            stderr=subprocess.DEVNULL,
        )
        return True
    except subprocess.CalledProcessError:
        return False

def is_reachable_from_node(node, target_ip):
    """Ping the target IP from a remote node via SSH."""

    if not is_reachable(node):
        return None
    else:
        try:
            cmd = ["ssh", node, f"ping -c 1 -W 1 {target_ip}"]
            subprocess.check_output(cmd, stderr=subprocess.DEVNULL)
            return True
        except subprocess.CalledProcessError:
            return False

def is_ssh_reachable_from_node(from_node, target_ip):
    """
    SSH into `from_node`, then try SSH to `target_ip` from within that node.
    Returns:
        - True if SSH from `from_node` to `target_ip` works.
        - False if outer SSH works but inner SSH fails.
        - None if outer SSH to `from_node` fails.
    """
    # First: verify outer SSH works
    try:
        outer_test_cmd = [
            "ssh",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=3",
            from_node,
            "echo outer_ok"
        ]

        result = subprocess.check_output(outer_test_cmd, stderr=subprocess.STDOUT, timeout=5)
        if b"outer_ok" not in result:
            print(f"[ERROR] Outer SSH to {from_node} succeeded but gave unexpected output: {result.decode().strip()}")
            return None
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return None

    # Second: try SSH from within from_node to target_ip
    try:

        #inner_ssh_cmd = f"ssh -o BatchMode=yes -o ConnectTimeout=2 {target_ip} echo ok"
        inner_ssh_cmd = (
            f"ssh -o StrictHostKeyChecking=no "
            f"-o UserKnownHostsFile=/dev/null "
            f"-o BatchMode=yes -o ConnectTimeout=2 {target_ip} echo ok"
        )

        full_cmd = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=3", from_node, inner_ssh_cmd]
        output = subprocess.check_output(full_cmd, stderr=subprocess.STDOUT, timeout=5)
        if b"ok" in output:
           return True
        else:
           return False
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return False

def test_isolation(node1, node2):
    """
    Test network and SSH isolation between two nodes in both directions.

    For each direction:
    - Checks if the source node can ping the destination node.
    - Checks if the source node can SSH into the destination node.
    - Prints the results with clear pass/fail indicators.
    """
    print(f"\nTesting isolation between {node1} and {node2} (both directions)")

    pairs = [(node1, node2), (node2, node1)]
    for idx, (src, dest) in enumerate(pairs):
        if idx == 1:
            print(f"\nTesting reverse direction: {src} → {dest}")

        # Ping test
        ping_result = is_reachable_from_node(src, dest)
        if ping_result is True:
            ping_msg = f"✅ {src} can ping {dest}"
        elif ping_result is False:
            ping_msg = f"❌ {src} is reachable, but cannot ping {dest}"
        else:
            ping_msg = f"❌ Cannot reach {src} (ping test not possible)"
        print("PING Status:", ping_msg)

        # SSH test
        ssh_result = is_ssh_reachable_from_node(src, dest)
        if ssh_result is True:
            ssh_msg = f"✅ {src} can SSH into {dest}"
        elif ssh_result is False:
            ssh_msg = f"❌ {src} is reachable, but cannot SSH into {dest}"
        else:
            ssh_msg = f"❌ Cannot reach {src} (SSH test not possible)"
        print("SSH Status:", ssh_msg)


def get_ready_mountain_nodes():
    node1 = None
    node2 = None
    seen_cabinets = set()
    all_nodes = []

    try:
        cmd = ["sat", "status", "--hsm-fields", "--filter", "role=compute", "--no-headings", "--no-borders"]
        output = subprocess.check_output(cmd, universal_newlines=True)
        lines = output.strip().splitlines()

        # Filter and sort ready nodes
        ready_nodes = sorted([
            line.strip().split()[0]
            for line in lines
            if len(line.strip().split()) >= 4 and line.strip().split()[3] == "Ready"
        ])

        all_nodes = ready_nodes  # for fallback if needed

        for xname in ready_nodes:
            cabinet = xname[:6]  # adjust if cabinet parsing changes

            if not node1:
                node1 = xname
                seen_cabinets.add(cabinet)
            elif not node2 and cabinet not in seen_cabinets:
                node2 = xname
                break

        # Fallback to second node from same cabinet if needed
        if not node2 and len(all_nodes) >= 2:
            node2 = all_nodes[1]

        return node1, node2

    except Exception as e:
        print(f"Error while selecting nodes: {e}")
        return None, None


def get_user_nodes():
    node1 = input("Enter node from CabinetX (or press Enter to auto-select): ").strip()
    node2 = input("Enter node from CabinetY (or press Enter to auto-select): ").strip()
    return node1 if node1 else None, node2 if node2 else None

def start_test():
    secret = get_client_secret()
    if not secret:
        exit(1)

    token = get_access_token(secret)
    if not token:
        exit(1)

    network_info = get_nmn_mtn_network(token)

    if network_info["Name"] == "NMN_MTN":
        print("NMN_MTN network found in the sls file")
        subnets = network_info.get("ExtraProperties", {}).get("Subnets", [])
        if len(subnets) < 2:
            print(f"Need at least two Mountain cabinets to test isolation, found{subnets}")
            exit(1)

    else:
        print("NMN_MTN network not found in the SLS data.")
        exit(1)

    node1, node2 = get_user_nodes()

    if not node1 or not node2:
        print(f"User did not provide valid nodes: {node1}, {node2} Auto-selecting nodes from cabinets...")
        node1, node2 = get_ready_mountain_nodes()

    if node1 and node2:
        test_isolation(node1, node2)
    else:
        print("❌ No matching One or both Mountain/Ready nodes found.")
        exit(1)
