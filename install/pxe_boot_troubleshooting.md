

# PXE Boot Troubleshooting

This page is designed to cover various issues that arise when trying to PXE boot nodes in an HPE Cray EX system.

- [PXE Boot Troubleshooting](#pxe-boot-troubleshooting)
  - [Configuration required for PXE booting](#configuration-required-for-pxe-booting)
  - [Switch Configuration](#switch-configuration)
    - [Aruba Configuration](#aruba-configuration)
    - [Mellanox Configuration](#mellanox-configuration)
  - [Next steps](#next-steps)
    - [Restart BSS](#restart-bss)
    - [Restart KEA](#restart-kea)
    - [Missing BSS Data](#missing-bss-data)

In order for PXE booting to work successfully, the management network switches need to be configured correctly.

<a name="#required-configuration"></a>
## Configuration required for PXE booting

To successfully PXE boot nodes, the following is required:

- The IP helper-address must be configured on VLAN 1,2,4,7. This will be where the layer 3 gateway exists (Spine or Leaf)
- The virtual-IP/VSX/MAGP IP address must be configured on VLAN 1,2,4,7.
- spine01/spine02 needs an active gateway on VLAN1 this can be identified from MTL.yaml generated from CSI.
- spine01/spine02 needs an IP helper-address on VLAN1 pointing to 10.92.100.222.


<a name="#switch-configuration"></a>
## Switch Configuration

<a name="#aruba-configuration"></a>
### Aruba Configuration

1.  Check the configuration for `interface vlan x`.

    This configuration will be the same on BOTH Switches (except the `ip address`).
    There will be an `active-gateway` and `ip helper-address` configured.

    ```bash
    sw-spine-001(config)# int vlan 1,2,4,7
    sw-spine-001(config-if-vlan-<1,2,4,7>)# show run current-context
    ```

    Example ouput:

    ```
    interface vlan 1
        ip mtu 9198
        ip address 10.1.0.2/16
        active-gateway ip mac 12:00:00:00:6b:00
        active-gateway ip 10.1.0.1
        ip helper-address 10.92.100.222
    interface vlan 2
        vsx-sync active-gateways
        ip mtu 9198
        ip address 10.252.0.2/17
        active-gateway ip mac 12:01:00:00:01:00
        active-gateway ip 10.252.0.1
        ip helper-address 10.92.100.222
        ip ospf 1 area 0.0.0.0
    interface vlan 4
        vsx-sync active-gateways
        ip mtu 9198
        ip address 10.254.0.2/17
        active-gateway ip mac 12:01:00:00:01:00
        active-gateway ip 10.254.0.1
        ip helper-address 10.94.100.222
        ip ospf 1 area 0.0.0.0
    interface vlan 7
        ip mtu 9198
        ip address 10.103.11.1/24
        active-gateway ip mac 12:01:00:00:01:00
        active-gateway ip 10.103.11.111
        ip helper-address 10.92.100.222
    ```

2.  If any of this configuration is missing, update it to BOTH switches.

    ```bash
    sw-spine-002# conf t
    sw-spine-002(config)# int vlan 1
    sw-spine-002(config-if-vlan)# ip helper-address 10.92.100.222
    sw-spine-002(config-if-vlan)# active-gateway ip mac 12:01:00:00:01:00
    sw-spine-002(config-if-vlan)# active-gateway ip 10.1.0.1

    sw-spine-002# conf t
    sw-spine-002(config)# int vlan 2
    sw-spine-002(config-if-vlan)# ip helper-address 10.92.100.222
    sw-spine-002(config-if-vlan)# active-gateway ip mac 12:01:00:00:01:00
    sw-spine-002(config-if-vlan)# active-gateway ip 10.252.0.1

    sw-spine-002# conf t
    sw-spine-002(config)# int vlan 4
    sw-spine-002(config-if-vlan)# ip helper-address 10.94.100.222
    sw-spine-002(config-if-vlan)# active-gateway ip mac 12:01:00:00:01:00

    sw-spine-002# conf t
    sw-spine-002(config)# int vlan 7
    sw-spine-002(config-if-vlan)# ip helper-address 10.92.100.222
    sw-spine-002(config-if-vlan)# active-gateway ip mac 12:01:00:00:01:00
    sw-spine-002(config-if-vlan)# active-gateway ip xxxxxxx
    sw-spine-002(config-if-vlan)# write mem
    ```


<a name="#mellanox-configuration"></a>
### Mellanox Configuration

1.  Check the configuration for `interface vlan 1`.

    This configuration will be the same on BOTH Switches (except the `ip address`).
    `magp` and `ip dhcp relay` will be configured.

    ```bash
    sw-spine-001 [standalone: master] # show run int vlan 1
    ```

    Example output:

    ```bash
    interface vlan 1
    interface vlan 1 ip address 10.1.0.2/16 primary
    interface vlan 1 ip dhcp relay instance 2 downstream
    interface vlan 1 magp 1
    interface vlan 1 magp 1 ip virtual-router address 10.1.0.1
    interface vlan 1 magp 1 ip virtual-router mac-address 00:00:5E:00:01:01
    ```

1.  If this configuration is missing, add it to BOTH switches.

    ```bash
    sw-spine-001 [standalone: master] # conf t
    sw-spine-001 [standalone: master] (config) # interface vlan 1 magp 1
    sw-spine-001 [standalone: master] (config interface vlan 1 magp 1) # ip virtual-router address 10.1.0.1
    sw-spine-001 [standalone: master] (config interface vlan 1 magp 1) # ip virtual-router mac-address 00:00:5E:00:01:01
    sw-spine-001 [standalone: master] # conf t
    sw-spine-001 [standalone: master] (config) # ip dhcp relay instance 2 vrf default
    sw-spine-001 [standalone: master] (config) # ip dhcp relay instance 2 address 10.92.100.222
    sw-spine-001 [standalone: master] (config) # interface vlan 2 ip dhcp relay instance 2 downstream
    ```

1.  Verify the VLAN 1 MAGP configuration.

    ```bash
    sw-spine-001 [standalone: master] # show magp 1
    ```
    Example output:
    
    ```
    MAGP 1:
      Interface vlan: 1
      Admin state   : Enabled
      State         : Master
      Virtual IP    : 10.1.0.1
      Virtual MAC   : 00:00:5E:00:01:01
    ```

1.  Verify the DHCP relay configuration.

    ```bash
    sw-spine-001 [standalone: master] (config) # show ip dhcp relay instance 2
    ```

    Example output:

    ```
    VRF Name: default

    DHCP Servers:
      10.92.100.222

    DHCP relay agent options:
      always-on         : Disabled
      Information Option: Disabled
      UDP port          : 67
      Auto-helper       : Disabled

    -------------------------------------------
    Interface   Label             Mode
    -------------------------------------------
    vlan1       N/A               downstream
    vlan2       N/A               downstream
    vlan7       N/A               downstream
    ```

1.  Verify that the route to the TFTP server and the route for the ingress gateway are available.

    ```bash
    sw-spine-001 [standalone: master] # show ip route 10.92.100.60
    ```

    Example output:

    ```
    Flags:
      F: Failed to install in H/W
      B: BFD protected (static route)
      i: BFD session initializing (static route)
      x: protecting BFD session failed (static route)
      c: consistent hashing
      p: partial programming in H/W

    VRF Name default:
      ------------------------------------------------------------------------------------------------------
      Destination       Mask              Flag     Gateway           Interface        Source     AD/M
      ------------------------------------------------------------------------------------------------------
      default           0.0.0.0           c        10.101.15.161     eth1/12          static     1/1
      10.92.100.60      255.255.255.255   c        10.252.0.5        vlan2            bgp        200/0
                                          c        10.252.0.6        vlan2            bgp        200/0
                                          c        10.252.0.7        vlan2            bgp        200/0
    ```

    ```bash
    sw-spine-001 [standalone: master] # show ip route 10.92.100.71
    ```

    Example output:

    ```
    Flags:
      F: Failed to install in H/W
      B: BFD protected (static route)
      i: BFD session initializing (static route)
      x: protecting BFD session failed (static route)
      c: consistent hashing
      p: partial programming in H/W

    VRF Name default:
      ------------------------------------------------------------------------------------------------------
      Destination       Mask              Flag     Gateway           Interface        Source     AD/M
      ------------------------------------------------------------------------------------------------------
      default           0.0.0.0           c        10.101.15.161     eth1/12          static     1/1
      10.92.100.71      255.255.255.255   c        10.252.0.5        vlan2            bgp        200/0
                                          c        10.252.0.6        vlan2            bgp        200/0
                                          c        10.252.0.7        vlan2            bgp        200/0
    ```



<a name="#next-steps"></a>
## Next steps

If the configuration looks good, and PXE boot is still not working, there are some other things to try.

<a name="restart-bss"></a>
### Restart BSS

Restart the Boot Script Service (BSS) if the following output is returned on the console during PXE
(specifically the 404 error at the bottom) during an NCN boot attempt:

```text
https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript...X509 chain 0x6d35c548 added X509 0x6d360d68 "eniac.dev.cray.com"
X509 chain 0x6d35c548 added X509 0x6d3d62e0 "Platform CA - L1 (a0b073c8-5c9c-4f89-b8a2-a44adce3cbdf)"
X509 chain 0x6d35c548 added X509 0x6d3d6420 "Platform CA (a0b073c8-5c9c-4f89-b8a2-a44adce3cbdf)"
EFITIME is 2021-02-26 21:55:04
HTTP 0x6d35da88 status 404 Not Found
```
1. Rollout a restart of the BSS deployment from any other NCN (likely `ncn-m002` if you are executing the `ncn-m001` reboot):

    ```bash
    ncn-m002# kubectl -n services rollout restart deployment cray-bss
    deployment.apps/cray-bss restarted
    ```

1. Wait for this command to return (it will block showing status as the pods are refreshed):

    ```bash
    ncn-m002# # kubectl -n services rollout status deployment cray-bss
    Waiting for deployment "cray-bss" rollout to finish: 1 out of 3 new replicas have been updated...
    Waiting for deployment "cray-bss" rollout to finish: 1 out of 3 new replicas have been updated...
    Waiting for deployment "cray-bss" rollout to finish: 1 out of 3 new replicas have been updated...
    Waiting for deployment "cray-bss" rollout to finish: 2 out of 3 new replicas have been updated...
    Waiting for deployment "cray-bss" rollout to finish: 2 out of 3 new replicas have been updated...
    Waiting for deployment "cray-bss" rollout to finish: 2 out of 3 new replicas have been updated...
    Waiting for deployment "cray-bss" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "cray-bss" rollout to finish: 1 old replicas are pending termination...
    deployment "cray-bss" successfully rolled out
    ```

1. Reboot the NCN that failed to PXE boot.

<a name="restart-kea"></a>
### Restart KEA

In some cases, rebooting the KEA pod has resolved PXE issues.

1. Get the KEA pod.
    
    ```bash
    ncn-m002# kubectl get pods -n services | grep kea
    cray-dhcp-kea-6bd8cfc9c5-m6bgw                                 3/3     Running     0          20h
    ```

1. Delete the KEA Pod.
    
    ```bash
    ncn-m002# kubectl delete pods -n services cray-dhcp-kea-6bd8cfc9c5-m6bgw
    ```

<a name="#missing-bss-data"></a>
### Missing BSS Data

If the PXE boot is giving 404 errors, this could be because the necessary information is not in BSS. The
information is uploaded into BSS with the `csi handoff bss-metadata` and `csi handoff bss-update-cloud-init`
commands in the [Deploy Final NCN](deploy_final_ncn.md#csi-handoff-bss-metadata) procedure. If these commands
failed or were skipped accidentally, this will cause the `ncn-m001` PXE boot to fail.

In that case, use the following recovery procedure.

1. Reboot to the PIT.
   
   * If using a USB PIT:
     
     1. Reboot the PIT node, watching the console as it boots.
        
     1. Manually stop it at the boot menu.
        
     2. Select the USB device for the boot.
        
     3. Once booted, log in and mount the data partition.
   
        ```bash
        pit# mount -vL PITDATA
        ```

   * If using a remote ISO PIT, follow the [Bootstrap LiveCD Remote ISO](bootstrap_livecd_remote_iso.md) procedure up through (**and including**) the [Set Up The Site Link](bootstrap_livecd_remote_iso.md#set-up-site-link) step.

1. Set variables for the system name, the CAN IP address for `ncn-m002`. the Kubernetes version, and the Ceph version.

    The CAN IP address for `ncn-m002` is obtained [at this step of the Deploy Final NCN procedure](deploy_final_ncn.md#collect-can-ip-ncn-m002).

    The Kubernetes and Ceph versions are from the output of the [`csi handoff ncn-images` command in the Deploy Final NCN procedure](deploy_final_ncn.md#ncn-boot-artifacts-hand-off). If needed, the typescript file from that procedure should be on `ncn-m002` in the `/metal/bootstrap/prep/admin` directory.

    Substitute the correct values for the system in use in the following commands:

    ```bash
    pit# SYSTEM_NAME=eniac
    pit# CAN_IP_NCN_M002=a.b.c.d
    pit# export KUBERNETES_VERSION=m.n.o
    pit# export CEPH_VERSION=x.y.z
    ```

3. **If using a remote ISO PIT**, run the following commands to finish configuring the network and copy files. 

    **Skip these steps if using a USB PIT**.

    1. Run the following command to copy files from `ncn-m002` to the PIT node.
        
        ```bash
        pit# scp -p ${CAN_IP_NCN_M002}:/metal/bootstrap/prep/${SYSTEM_NAME}/pit-files/* /etc/sysconfig/network/
        ```

    2. Apply the network changes.
        
        ```bash
        pit# wicked ifreload all
        pit# systemctl restart wickedd-nanny && sleep 5
        ```

    3. Copy `data.json` from `ncn-m002` to the PIT node.

        ```bash
        pit# mkdir -p /var/www/ephemeral/configs
        pit# scp ${CAN_IP_NCN_M002}:/metal/bootstrap/prep/${SYSTEM_NAME}/basecamp/data.json /var/www/ephemeral/configs
        ```

4. Copy Kubernetes config file from `ncn-m002`.

    ```bash
    pit# mkdir -pv ~/.kube
    pit# scp ${CAN_IP_NCN_M002}:/etc/kubernetes/admin.conf ~/.kube/config
    ```

5. Set DNS to use unbound.

    ```bash
    pit# echo "nameserver 10.92.100.225" > /etc/resolv.conf
    ```

6. Export the API token.

    ```bash
    pit# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
        -d client_id=admin-client \
        -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

7. Re-run the [BSS handoff commands from the Deploy Final NCN procedure](deploy_final_ncn.md#ncn-boot-artifacts-hand-off).

    **WARNING: These commands should never be run from a node other than the PIT node or `ncn-m001`**
    
    ```bash
    pit# csi handoff bss-metadata --data-file /var/www/ephemeral/configs/data.json || echo "ERROR: csi handoff bss-metadata failed"
    pit# csi handoff bss-update-cloud-init --set meta-data.dns-server=10.92.100.225 --limit Global
    ```

8. Perform the [BSS Restart](#restart-bss) and the [KEA Restart](#restart-kea) procedures.

9.  Reboot the PIT node.

