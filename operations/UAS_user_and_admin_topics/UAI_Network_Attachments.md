# UAI Network Attachment Customization

The UAI network attachment configuration flows from the Cray Site Initializer (CSI) localization data through `customizations.yaml` into the UAS Helm chart and, ultimately, into Kubernetes in the form of a "network-attachment-definition".

This section describes the data at each of those stages to show how the final network attachment gets created.
Customization of the network attachments may be needed by some sites to, for example, increase the size of the reserved sub-net used for UAI `macvlan` attachments.

## CSI Localization Data

The details of CSI localization are beyond the scope of this guide, but here are the important settings, and the values used in the following examples:

* The interface name on which the Kubernetes worker nodes reach their Node Management Network (NMN) subnet: `bond0.nmn0`
* The network and CIDR configured on that interface: `10.252.0.0/17`
* The IP address of the gateway to other NMN subnets found on that network: `10.252.0.1`
* The subnets where compute nodes reside on this system:
  * `10.92.100.0/24`
  * `10.106.0.0/17`
  * `10.104.0.0/17`

## Contents of `customizations.yaml`

When CSI runs, it produces the following data structure in the `spec` section of `customizations.yaml`:

```yaml
spec:

  [...]

  wlm:

    [...]

    macvlansetup:
      nmn_subnet: 10.252.2.0/23
      nmn_supernet: 10.252.0.0/17
      nmn_supernet_gateway: 10.252.0.1
      nmn_vlan: bond0.nmn0
      # NOTE: the term DHCP here is misleading, this is merely
      #       a range of reserved IP addresses for UAIs that should not
      #       be handed out to others because the network
      #       attachment will hand them out to UAIs.
      nmn_dhcp_start: 10.252.2.10
      nmn_dhcp_end: 10.252.3.254
      routes:
      - dst: 10.92.100.0/24
        gw:  10.252.0.1
      - dst: 10.106.0.0/17
        gw:  10.252.0.1
      - dst: 10.104.0.0/17
        gw: 10.252.0.1
```

The `nmn_subnet` value shown here is not relevant for this section.

These values, in turn, feed into the following translation to UAS Helm chart settings:

```yaml
      cray-uas-mgr:
        uasConfig:
          uai_macvlan_interface: '{{ wlm.macvlansetup.nmn_vlan }}'
          uai_macvlan_network: '{{ wlm.macvlansetup.nmn_supernet }}'
          uai_macvlan_range_start: '{{ wlm.macvlansetup.nmn_dhcp_start }}'
          uai_macvlan_range_end: '{{ wlm.macvlansetup.nmn_dhcp_end }}'
          uai_macvlan_routes: '{{ wlm.macvlansetup.routes }}'
```

## UAS Helm Chart

The inputs in the previous section tell the UAS Helm chart how to install the network attachment for UAIs.
While the [actual template](https://github.com/Cray-HPE/uas-mgr/blob/master/kubernetes/cray-uas-mgr/templates/macvlan.yaml) used for this is more complex, the following is a simplified view of the template used to generate the network attachment.

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition

[...]

spec:
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "{{ .Values.uasConfig.uai_macvlan_interface }}",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "{{ .Values.uasConfig.uai_macvlan_network }}",
        "rangeStart": "{{ .Values.uasConfig.uai_macvlan_range_start }}",
        "rangeEnd": "{{ .Values.uasConfig.uai_macvlan_range_end }}",
        "routes": [
{{- range $index, $route := .Values.uasConfig.uai_macvlan_routes }}
  {{- range $key, $value := $route }}
           {
              "{{ $key }}": "{{ $value }}",
           },
  {{- end }}
{{- end }}
        ]
      }
  }'
```

The `range` templating in the `routes` section expands the routes from `customizations.yaml` into the network attachment routes.

## UAI Network Attachment in Kubernetes

All of this produces a network attachment definition in Kubernetes called `macvlan-uas-nmn-conf` which is used by UAS.

The following contents would result from the above data:

```yaml
apiVersion: v1
items:
- apiVersion: k8s.cni.cncf.io/v1
  kind: NetworkAttachmentDefinition
  ...
  spec:
    config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "bond0.nmn0",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "10.252.0.0/17",
        "rangeStart": "10.252.124.10",
        "rangeEnd": "10.252.125.244",
        "routes": [
          {
            "dst": "10.92.100.0/24",
            "gw":  "10.252.0.1"
          },
          {
            "dst": "10.106.0.0/17",
            "gw":  "10.252.0.1"
          },
          {
            "dst": "10.104.0.0/17",
            "gw": "10.252.0.1"
          }
        ]
      }
    }'

[...]
```

In this example, Kubernetes will assign UAI IP addresses in the range `10.252.2.10` through `10.252.3.244` on the network attachment, and will permit those UAIs to reach compute nodes on any of four possible NMN subnets:

* Directly through the NMN subnet hosting the UAI host node itself (`10.252.0.0/17` here)
* Through the gateway in the local NMN subnet (`10.252.0.1` here) to:
  * `10.92.100.0/24`
  * `10.106.0.0/17`
  * `10.104.0.0/17`

[Top: User Access Service (UAS)](index.md)

[Next Topic: Configure UAIs in UAS](Configure_UAIs_in_UAS.md)
