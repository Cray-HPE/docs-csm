#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP
set -euo pipefail

RETRY=0
MAX_RETRIES=30
RETRY_SECONDS=10

until kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server healthcheck | grep -q 'Server is healthy'; do
    if [[ "$RETRY" -lt "$MAX_RETRIES" ]]; then
        RETRY="$((RETRY + 1))"
        echo "spire-server is not ready. Will retry after $RETRY_SECONDS seconds. ($RETRY/$MAX_RETRIES)"
    else
        echo "spire-server did not start after $(echo "$RETRY_SECONDS" \* "$MAX_RETRIES" | bc) seconds."
        exit 1
    fi
    sleep "$RETRY_SECONDS"
done

URL="https://spire-tokens.spire:54440/api/token"
POD=$(kubectl get pods -n spire | grep spire-server | grep Running | awk 'NR==1{print $1}')
LOADBALANCERIP=$(kubectl get service -n spire spire-lb --no-headers --output=jsonpath='{.spec.loadBalancerIP}')

function sshnh() {
    /usr/bin/ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" "$@"
}

if hostname | grep -q 'pit'; then
    echo "This script is not supported on pit nodes. Please run it on ncn-m002."
    exit 1
fi

nodes=$(ceph node ls | jq -r '.[] | keys[]' | sort -u)

for node in $nodes; do
    if sshnh "$node" spire-agent healthcheck -socketPath=/root/spire/agent.sock 2>&1 | grep -q "healthy"; then
        echo "$node is already joined to spire and is healthy."
    else
        if sshnh "$node" ls /root/spire/data/ | grep -q svid.key; then
		echo "$node was once joined to spire. Cleeaning up old files"
                sshnh "$node" rm /root/spire/data/svid.key /root/spire/bundle.der /root/spire/agent_svid.der
        fi
        echo "$node is being joined to spire."
        XNAME="$(ssh "$node" cat /proc/cmdline | sed 's/.*xname=\([A-Za-z0-9]*\).*/\1/')"
        TOKEN="$(kubectl exec -n spire "$POD" --container spire-registration-server -- curl -k -X POST -d type=storage\&xname="$XNAME" "$URL" | tr ':' '=' | tr -d '"{}')"
        sshnh "$node" "echo $TOKEN > /root/spire/conf/join_token"
        kubectl get configmap -n spire spire-ncn-config -o jsonpath='{.data.spire-agent\.conf}' | sed "s/server_address.*/server_address = \"$LOADBALANCERIP\"/" | sshnh "$node" "cat > /root/spire/conf/spire-agent.conf"
        kubectl get configmap -n spire spire-bundle -o jsonpath='{.data.bundle\.crt}' | sshnh "$node" "cat > /root/spire/conf/bundle.crt"
        sshnh "$node" systemctl enable spire-agent
        sshnh "$node" systemctl start spire-agent
    fi
done
