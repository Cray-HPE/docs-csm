# Cilium and Hubble Monitoring

Cilium is an eBPF powered platform for networking, observability, and security which is used as the
Container Network Interface (CNI) in CSM. Using eBPF allows Cilium to enforce the security policies
without making any changes to the application code or configuration. Hubble is a network and observability
platform built over Cilium and eBPF. It allows visibility into the communication and behavior of services
as well as the networking infrastructure.

Three new dashboards have been created for monitoring Cilium and Hubble. These are as follows:

- Cilium Agent Metrics - Visualizes the metrics exposed by cilium-agent. cilium-agent runs on each node and accepts configuration describing network policies, visibility and other monitoring requirements from Kubernetes.
- Cilium Hubble Metrics - Visualizes the metrics exposed by Hubble. Hubble is integrated into cilium-agent and retrieves the visibility from Cilium.
- Cilium Policy Verdicts - Visualizes the Network Policy application in a Cilium cluster. It displays the outcome(connection forwarded or dropped) of applying the network policies.
