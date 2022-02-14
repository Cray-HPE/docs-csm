## External DNS csi config init Input Values

External DNS requires the system-name, site-domain, and cmn-external-dns values that are defined with the `csi config init` command. These values are used to customize the External DNS configuration during installation.

### The system-name and site-domain Values

The system-name and site-domain values specified as part of the csi config init are used together in the system-name.site-domain format, creating the external domain for external hostnames for services accessible from the Customer Management Network \(CMN\). Changing this value requires updating all impacted `external-dns.alpha.kubernetes.io/hostname` annotations, VirtualService and possibly Gateway objects, the CoreDNS configmap, Keycloak settings for valid OAuth callback URLs, Keycloak gatekeeper configuration, and generating new certificates.

**Warning:** Changing the system-name.site-domain value post-installation is not recommended because of the complexity of changes required.

Input for `csi config init`:

```bash
--system-name testsystem
--site-domain example.com
```

### The cmn-external-dns Value

The `cmn-external-dns` value is the IP address that DNS queries under the combined system-name.site-domain values need to be delegated.

This will be the shared IP address for `services/cray-externaldns-coredns-tcp` and services/cray-externaldns-coredns-udp services, which must be an IP address in the `customer_management_static_metallb_address_pool` subnet defined in the `csi config init` input. See [Customer Access Network (CAN)](../customer_access_network/Customer_Access_Network_CAN.md) for more information.

Changing this value requires updating the `loadBalancerIP` value of the `services/cray-externaldns-coredns-tcp` and `services/cray-externaldns-coredns-udp` services.

Input for `csi config init`:

```bash
--cmn-external-dns 10.102.5.30
```

This input is the CMN IP address for resolution of system services.


