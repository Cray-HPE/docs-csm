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

def is_reachable_from_node(node, target_ip):
    """Ping the target IP from a remote node via SSH."""
    try:
        cmd = [
            "ssh",
            node,
            f"ping -c 1 -W 1 {target_ip}"
        ]
        subprocess.check_output(cmd, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def is_ssh_reachable_from_node(from_node, target_ip):
    """
    SSH into `from_node`, then try SSH to `target_ip` from within that node.
    Assumes key-based auth and no password prompts at either level.
    """
    try:
        # Command to run on from_node
        inner_ssh_cmd = f"ssh -o BatchMode=yes -o ConnectTimeout=2 {target_ip} echo ok"
        
        # Outer SSH: go to from_node and run the inner SSH command
        full_cmd = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=3", from_node, inner_ssh_cmd]

        subprocess.check_output(full_cmd, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def test_isolation(sls_data, node1, node2):
    
    subnets = sls_data.get("ExtraProperties", {}).get("Subnets", [])

    if len(subnets) < 2:
        print("Need at least two subnets to test isolation.")
        return
    else: 
        cab_a, cab_b = subnets[0], subnets[1]
        print(f"cab_a: {cab_a['Name']} - {cab_a['CIDR']}")
        print(f"cab_b: {cab_b['Name']} - {cab_b['CIDR']}")

    # Get IPs from the two subnets
    ips_a = get_subnet_ips(cab_a)
    ips_b = get_subnet_ips(cab_b)

    print(f"\nTesting isolation between {cab_a['Name']} and {cab_b['Name']}")
    print(f"\nPerforming ping checks from {cab_a['Name']} node {node1}")

    for src_ip in ips_a[:1]:  # Test first 3 IPs from cabinet A
        for dst_ip in ips_b[:253]:  # Test first 3 IPs from cabinet B
            ping_result = is_reachable_from_node(node1, dst_ip)
            ssh_result = is_ssh_reachable_from_node(node1, dst_ip)
            print(f"  To {dst_ip} -> ping: {'✅' if ping_result else '❌'}, ssh: {'✅' if ssh_result else '❌'}")
    
    print("=======================================================")
    print(f"\nTesting isolation between {cab_b['Name']} and {cab_a['Name']}")
    print(f"\nPerforming ping checks from  {cab_b['Name']} node {node2}")
    
    for src_ip in ips_b[:1]:  # Test first 3 IPs from cabinet B
        print(f"\nFrom {cab_b['Name']} node {src_ip}:")

        for dst_ip in ips_a[:253]:  # Test first 3 IPs from cabinet A
            ping_result = is_reachable_from_node(node2, dst_ip)
            ssh_result = is_ssh_reachable_from_node(node2, dst_ip)
            #print(f"  To {dst_ip} -> ping: {'✅' if ping_result else '❌'}")
            print(f"  To {dst_ip} -> ping: {'✅' if ping_result else '❌'}, ssh: {'✅' if ssh_result else '❌'}")
   
def get_ready_mountain_nodes():
    try:
        # Run the sat status command and capture output
        cmd = ["sat", "status", "--hsm-fields", "--filter", "role=compute", "--no-headings", "--no-borders"]
        #output = subprocess.check_output(cmd, text=True)
        output = subprocess.check_output(cmd, universal_newlines=True)

        x1000_node = None
        x1001_node = None

        for line in output.strip().splitlines():
            fields = line.split()
            if len(fields) < 4:
                continue  # Skip malformed lines

            xname = fields[0]
            status = fields[3]

            if status == "Ready":
                if xname.startswith("x1000") and not x1000_node:
                    x1000_node = xname
                elif xname.startswith("x1001") and not x1001_node:
                    x1001_node = xname

            # Break early if both found
            if x1000_node and x1001_node:
                break

        return x1000_node, x1001_node

    except subprocess.CalledProcessError as e:
        print("Error running `sat status`:", e)
        return None, None

def start_test():
    secret = get_client_secret()
    if not secret:
        exit(1)

    token = get_access_token(secret)
    if not token:
        exit(1)

    network_info = get_nmn_mtn_network(token)
    #if network_info:
    #    print(json.dumps(network_info, indent=2))

    #print("DBG", network_info["Name"])
    if network_info["Name"] == "NMN_MTN":
        print("NMN_MTN network found in the sls file")
    else:
        print("NMN_MTN network not found in the SLS data.")
        exit(1)

    node1, node2 = get_ready_mountain_nodes()
    print("x1000 Ready node:", node1)
    print("x1001 Ready node:", node2)
    
    #node2 = "x1000c5s5b1n0"

    if node1 and node2:
        print(f"Found nodes: node1 = {node1}, node2 = {node2}")
        test_isolation(network_info, node1, node2)
    else:
        print("❌ No matching One or both Mountain/Ready nodes found.")
        exit(1)
