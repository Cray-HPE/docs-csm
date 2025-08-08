# Keycloak IPv6 Support

## IPv6 support

The `cray-keycloak` service can be configured to access an external LDAP server using IPv6. CSM does not deploy Kubernetes in dual stack mode so this is achieved
by using a network attachment definition to allow the `cray-keycloak` Pods direct access to an IPv6 network.

The following `cray-keycloak` Helm chart values must be set to enable IPv6 support.

| Property          | Default value | Description                                                                                                 |
| ----------------- | ------------- | ----------------------------------------------------------------------------------------------------------- |
| `ipv6.enabled`    | false         | Enable/Disable IPv6 support                                                                                 |
| `ipv6.gateway`    | None          | The default gateway to use for IPv6 traffic. Must be set if `ipv6.enabled=true`                             |
| `ipv6.subnet`     | None          | The IPv6 subnet to use in CIDR form. Must be set if `ipv6.enabled=true`                                     |
| `ipv6.rangeStart` | None          | Start address of an IPv6 address pool to be used for `cray-keycloak`. Must be set if `ipv6.enabled=true`    |
| `ipv6.rangeEnd`   | None          | End address of an IPv6 address pool to be used for `cray-keycloak`. Must be set if `ipv6.enabled=true`      |

The values used for `ipv6.gateway` and `ipv6.subnet` should match those used for the Customer Management Network (CMN). The `ipv6.rangeStart` and `ipv6.rangeEnd` values
should describe an unused range within the subnet declared in `ipv6.subnet`. The number of IP addresses in this range should equal the desired number of `cray-keycloak`
replicas (the default is 3). If `cray-dns-unbound` has also been configured to use IPv6, this range *must not* overlap with the range used there.

Prerequisites:

- CSM must have been configured to support IPv6 on the CMN. See the [IPv6 Configuration Guide](../customer_accessible_networks/ipv6_configuration_guide.md) for more information.

**NOTE:** This procedure assumes that CSM has already been installed and a running system is being modified. If the system is undergoing a fresh install then simply update `${SITE_INIT}/customizations.yaml` with the desired values and skip
steps one, three, and four.

1. (`ncn-m#`) Extract `customizations.yaml` from the `site-init` secret in the `loftsman` namespace.

   ```bash
   kubectl -n loftsman get secret site-init -o json | jq -r '.data."customizations.yaml"' | base64 -d > customizations.yaml
   ```

1. (`ncn-m#`) Update the `spec.kubernetes.services.cray-keycloak` path in `customizations.yaml` with the IPv6 configuration.

   Example configuration:

   ```yaml
      cray-keycloak:
        sealedSecrets:
        - '{{ kubernetes.sealed_secrets[''cray-keycloak''] | toYaml }}'
        - '{{ kubernetes.sealed_secrets.keycloak_master_admin_auth | toYaml }}'
        setup:
          keycloak:
            customerAccessUrl: https://auth.cmn.{{ network.dns.external }}/keycloak
            gatekeeper:
              proxiedHosts: '{{ proxiedWebAppExternalHostnames.customerManagement
                }}'
            clients:
              oauth2-proxy-customer-management:
                proxiedHosts: '{{ proxiedWebAppExternalHostnames.customerManagement
                  }}'
              oauth2-proxy-customer-access:
                proxiedHosts: '{{ proxiedWebAppExternalHostnames.customerAccess }}'
              oauth2-proxy-customer-high-speed:
                proxiedHosts: '{{ proxiedWebAppExternalHostnames.customerHighSpeed
                  }}'
            service: keycloak.services
            clusterGw:
              route: /keycloak
              dnsName: '{{ network.dns.internal_api }}'
        internalTokenUrl: https://{{ network.dns.internal_api }}/keycloak/realms/master/protocol/openid-connect/token
        keycloak:
          resources:
            requests:
              cpu: "20m"
        ipv6:
          enabled: true
          gateway: 2001:db8:100:200::1
          subnet: 2001:db8:100:200::/64
          rangeStart: 2001:db8:100:200::300
          rangeEnd: 2001:db8:100:200::310
   ```

1. (`ncn-m#`) Update the `site-init` secret in the `loftsman` namespace.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. (`ncn-m#`) Reinstall the `cray-keycloak` Helm chart using the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure.

   - Name of chart to be redeployed: `cray-keycloak`
   - Base name of manifest: `platform`
