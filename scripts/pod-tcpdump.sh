#!/bin/bash
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
#
# pod-tcpdump.sh - Capture network traffic for a Kubernetes pod
#
# This script finds a pod running on the current node and executes
# tcpdump within its network namespace using nsenter.
#

set -euo pipefail

# Default values
NAMESPACE=""
POD_NAME=""
LABEL_SELECTOR=""
INTERFACE="eth0"
TCPDUMP_ARGS=""
FILTER_EXPRESSION=""
PACKET_COUNT=""
WRITE_FILE=""
CUSTOM_ARGS=false

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Capture network traffic for a Kubernetes pod running on this node using tcpdump.

OPTIONS:
    -n, --namespace NAMESPACE       Kubernetes namespace (required)
    -p, --pod POD_NAME             Specific pod name
    -l, --label SELECTOR           Label selector (e.g., app=nginx)
    -i, --interface INTERFACE      Network interface to capture
                                   (default: "eth0")
    -c, --count NUMBER             Number of packets to capture
    -w, --write FILE               Write raw packets to file
    -f, --filter EXPRESSION        BPF filter expression (e.g., "port 80")
    -t, --tcpdump-args ARGS        Full tcpdump arguments (overrides defaults)
    -h, --help                     Show this help message

DEFAULT BEHAVIOR:
    Without -t, tcpdump is invoked with: -i eth0 -en -vv
    The -i, -c, -w, and -f options modify this default command.

EXAMPLES:
    # Capture on default eth0 interface
    $(basename "$0") -n opa -l app.kubernetes.io/name=cray-opa-ingressgateway

    # Capture 100 packets from specific pod
    $(basename "$0") -n default -p nginx-abc123 -c 100

    # Capture HTTP traffic only
    $(basename "$0") -n kube-system -l app=nginx -f "port 80"

    # Capture on specific interface with filter
    $(basename "$0") -n default -p my-pod -i net1 -f "tcp and port 443"

    # Save to pcap file
    $(basename "$0") -n opa -l app=ingress -w /tmp/capture.pcap -c 1000

    # Custom tcpdump arguments (full control)
    $(basename "$0") -n default -p my-pod -t "-i any -nn -vv icmp"

    # Capture DNS traffic
    $(basename "$0") -n kube-system -l k8s-app=kube-dns -f "port 53" -c 50

NOTES:
    - This script must be run on the node where the pod is running
    - Requires root/sudo access to use crictl, nsenter, and tcpdump
    - Either --pod or --label must be specified
    - Press Ctrl+C to stop capture (unless -c is specified)
    - When using -w, tcpdump will be less verbose (use -v in filter for details)
EOF
    exit 1
}

# Error handling
error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -p|--pod)
            POD_NAME="$2"
            shift 2
            ;;
        -l|--label)
            LABEL_SELECTOR="$2"
            shift 2
            ;;
        -i|--interface)
            INTERFACE="$2"
            shift 2
            ;;
        -c|--count)
            PACKET_COUNT="$2"
            shift 2
            ;;
        -w|--write)
            WRITE_FILE="$2"
            shift 2
            ;;
        -f|--filter)
            FILTER_EXPRESSION="$2"
            shift 2
            ;;
        -t|--tcpdump-args)
            TCPDUMP_ARGS="$2"
            CUSTOM_ARGS=true
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
done

# Validate required arguments
[[ -z "$NAMESPACE" ]] && error "Namespace is required. Use -n to specify."
[[ -z "$POD_NAME" && -z "$LABEL_SELECTOR" ]] && error "Either --pod or --label must be specified."

# Check required commands
for cmd in kubectl crictl jq nsenter tcpdump; do
    if ! command -v "$cmd" &> /dev/null; then
        error "Required command not found: $cmd"
    fi
done

# Get the current node name
NODE_NAME=$(uname -n)
echo "Running on node: $NODE_NAME"

# Find the pod
if [[ -n "$POD_NAME" ]]; then
    echo "Looking for pod: $POD_NAME in namespace: $NAMESPACE"
    POD=$(kubectl get pod -n "$NAMESPACE" "$POD_NAME" -o json 2>/dev/null | \
          jq -r "select(.spec.nodeName == \"$NODE_NAME\") | .metadata.name" || true)
    
    if [[ -z "$POD" ]]; then
        error "Pod '$POD_NAME' not found in namespace '$NAMESPACE' on this node"
    fi
else
    echo "Looking for pods with label: $LABEL_SELECTOR in namespace: $NAMESPACE"
    POD=$(kubectl get pod -n "$NAMESPACE" -l "$LABEL_SELECTOR" -o json 2>/dev/null | \
          jq -r ".items[] | select(.spec.nodeName == \"$NODE_NAME\") | .metadata.name" | head -n1 || true)
    
    if [[ -z "$POD" ]]; then
        error "No pods found matching label '$LABEL_SELECTOR' in namespace '$NAMESPACE' on this node"
    fi
fi

echo "Found pod: $POD"

# Get container IDs for the pod
echo "Finding container IDs..."
CONTAINER_IDS=$(crictl ps -o json | \
                jq -r ".containers[] | select(.labels.\"io.kubernetes.pod.name\" == \"$POD\") | .id")

if [[ -z "$CONTAINER_IDS" ]]; then
    error "No running containers found for pod '$POD'"
fi

echo "Found containers:"
echo "$CONTAINER_IDS" | while read -r cid; do
    CONTAINER_NAME=$(crictl inspect "$cid" 2>/dev/null | \
                     jq -r '.status.metadata.name // "unknown"')
    echo "  - $cid ($CONTAINER_NAME)"
done

# Get PID for the first container (all containers in pod share network namespace)
echo ""
echo "Getting network namespace PID..."
FIRST_CID=$(echo "$CONTAINER_IDS" | head -n1)
PID=$(crictl inspect --output go-template --template '{{.info.pid}}' "$FIRST_CID" 2>/dev/null || true)

if [[ -z "$PID" ]]; then
    error "Could not retrieve PID for container in pod '$POD'"
fi

echo "PID: $PID"
echo ""

# Build tcpdump command
if [[ "$CUSTOM_ARGS" == "true" ]]; then
    # Use custom arguments directly
    TCPDUMP_CMD="tcpdump $TCPDUMP_ARGS"
else
    # Build command from individual options with defaults
    TCPDUMP_CMD="tcpdump -i $INTERFACE -en -vv"
    
    [[ -n "$PACKET_COUNT" ]] && TCPDUMP_CMD="$TCPDUMP_CMD -c $PACKET_COUNT"
    [[ -n "$WRITE_FILE" ]] && TCPDUMP_CMD="$TCPDUMP_CMD -w $WRITE_FILE"
    [[ -n "$FILTER_EXPRESSION" ]] && TCPDUMP_CMD="$TCPDUMP_CMD $FILTER_EXPRESSION"
fi

echo "========================================"
echo "Network Capture for pod: $POD"
echo "Namespace: $NAMESPACE"
echo "Node: $NODE_NAME"
echo "PID: $PID"
echo "Command: $TCPDUMP_CMD"
echo "========================================"
echo ""

if [[ -z "$PACKET_COUNT" && -z "$WRITE_FILE" ]]; then
    echo "Press Ctrl+C to stop capture..."
    echo ""
fi

# Execute tcpdump in the container's network namespace
# Note: We don't redirect stderr so user can see tcpdump's output
if ! nsenter --target "$PID" --net $TCPDUMP_CMD; then
    error "Failed to execute tcpdump in network namespace for PID $PID"
fi

echo ""
echo "========================================"
echo "Capture complete"
[[ -n "$WRITE_FILE" ]] && echo "Output written to: $WRITE_FILE"
echo "========================================"
