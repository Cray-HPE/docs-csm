## Troubleshoot DNS Configuration Issues

Troubleshoot issues when DNS is not properly configured to delegate name resolution to the core DNS instance on a specific cluster. Although the CAN IP address may still be routable using the IP address directly, it may not work because Istio's ingress gateway depends on the hostname \(or SNI\) to route traffic. For command line tools like cURL, using the --resolve option to force correct resolution can be used to work around this issue.

To get names to resolve correctly in a browser, modifying /etc/hosts to map the external hostname to the appropriate CAN IP address may be necessary. In either case, knowing the correct CAN IP address is required to use the cURL `--resolve` option or to update /etc/hosts.

Assuming CAN, BGP, MetalLB, and external DNS are properly configured on a system, name resolution requests can be sent directly to the desired DNS server.

Gain access to system services when external DNS is not configured properly.

### Prerequisites

The Domain Name Service \(DNS\) is not configured properly.

### Procedure

1.  View the DNS configuration on the system.

    ```bash
    ncn-w001# kubectl -n services get svc cray-externaldns-coredns-udp
    ```

    Example output:

    ```
    NAME                           TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
    cray-externaldns-coredns-udp   LoadBalancer   10.25.156.88   10.102.14.113   53:32674/UDP   45h
    ```

2.  Confirm that DNS is configured properly.

    Run the following command from a laptop or workstation.

    ```bash
    $ dig SERVICE.SYSTEM_DOMAIN_NAME +short
    ```

    If an IP address is returned, DNS is configured properly and the remaining steps in this procedure can be skipped. If an IP address is not returned, proceed to the next step.

3.  Use the IP address to direct DNS requests directly to the `cray-externaldns-coredns-udp` service.

    Replace the example IP address \(10.102.14.131\) with the EXTERNAL-IP value returned in step 1. If an IP address is returned, it means upstream IT DNS is not configured correctly.

    ```bash
    $ dig SERVICE.SYSTEM_DOMAIN_NAME +short @10.102.14.113
    ```

4.  Direct DNS requests to the cluster IP address from an NCN.

    Replace the example cluster IP address \(10.25.156.88\) with the CLUSTER-IP value returned in step 1. If an IP address is returned, external DNS is configured on the cluster and something is likely wrong with CAN/BGP.

    ```bash
    ncn-w001# dig SERVICE.SYSTEM_DOMAIN_NAME +short @10.25.156.88
    ```

5.  Access services in the event that external DNS is down, the backing etcd database is having issues, or something was configured incorrectly.

    Search through Kubernetes service objects for `external-dns.alpha.kubernetes.io/hostname` annotations to find the corresponding external IP. The kubectl command makes it easy to generate an /etc/hosts compatible listing of IP addresses to hostnames using the go-template output format shown below.

    ```bash
    ncn-m001# kubectl get svc --all-namespaces -o go-template --template \
    '{{ range .items }}{{ $lb := .status.loadBalancer }}{{ with .metadata.annotations }}
    {{ with (index . "external-dns.alpha.kubernetes.io/hostname") }}
    {{ $hostnames := . }}{{ with $lb }}{{ range .ingress }}
    {{ printf "%s\t%s\n" .ip $hostnames }}{{ end }}{{ end }}
    {{ end }}{{ end }}{{ end }}' | sort -u | tr , ' '
    ```

    Example output:

    ```
    10.101.5.128    opa-gpm.SYSTEM_DOMAIN_NAME nexus.SYSTEM_DOMAIN_NAME jaeger-istio.SYSTEM_DOMAIN_NAME kiali-istio.SYSTEM_DOMAIN_NAME prometheus.SYSTEM_DOMAIN_NAME alertmanager.SYSTEM_DOMAIN_NAME grafana.SYSTEM_DOMAIN_NAME vcs.SYSTEM_DOMAIN_NAME sma-grafana.SYSTEM_DOMAIN_NAME sma-kibana.SYSTEM_DOMAIN_NAME csms.SYSTEM_DOMAIN_NAME
    10.101.5.129    api.SYSTEM_DOMAIN_NAME auth.SYSTEM_DOMAIN_NAME
    10.101.5.130    s3.SYSTEM_DOMAIN_NAME
    10.92.100.222   cray-dhcp-kea
    10.92.100.225   cray-dns-unbound
    10.94.100.222   cray-dhcp-kea
    10.94.100.225   cray-dns-unbound
    ```


