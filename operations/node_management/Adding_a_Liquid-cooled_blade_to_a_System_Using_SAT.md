# Adding a Liquid-cooled blade to a System Using SAT

This procedure will add a liquid-cooled blade to an HPE Cray EX system.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray Command Line Interface](../configure_cray_cli.md).

- Knowledge of whether DVS is operating over the Node Management Network (NMN) or the High Speed Network (HSN).

- Blade is being added to an existing liquid-cooled cabinet in the system.

- The Slingshot fabric must be configured with the desired topology for desired state of the blades in the system.

- The System Layout Service (SLS) must have the desired HSN configuration.

- Check the status of the high-speed network (HSN) and record link status before the procedure.

- The System Admin Toolkit \(SAT\) is installed and configured on the system.

- The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.
  - Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*
  - Review the *HPE Cray EX Hand Pump User Guide H-6200*

## Use SAT to add the blade to hardware management

1. Begin discovery for the blade.

   Use the `sat swap` command to map the nodes' Ethernet interface MAC addresses to the appropriate IP addresses and component names (xnames), and begin discovery for the blade.

   The `--src-mapping` and `--dst-mapping` arguments may be used to pass in the Ethernet interface mapping files containing the IP
   addresses, MAC addresses, and component xnames for the nodes on the blade. If the slot was previously populated, the file passed into the
   `--src-mapping` argument should be the mapping file saved during the
   [Removing a Liquid-cooled Blade from a System Using SAT](Removing_a_Liquid-cooled_blade_from_a_System_Using_SAT.md) procedure, and the
   `--dst-mapping` argument should be a mappings file of the MAC addresses, IP addresses, and component xnames from the new blade. If the new
   blade was removed from another system, the mappings file was saved while performing the
   [Removing a Liquid-cooled Blade from a System Using SAT](Removing_a_Liquid-cooled_blade_from_a_System_Using_SAT.md) procedure on the other system.
   If the blade is a new blade, (that is, not from another running system), do not use either `--src-mapping` or `--dst-mapping`.

   ```bash
   sat swap blade --src-mapping <SRC_MAPPING> --dst-mapping <DST_MAPPING> --action enable <SLOT_XNAME>
   ```

   If the slot was not previously populated, the `--src-mapping` and `--dst-mapping` arguments should be omitted.

   ```bash
   sat swap blade --action enable <SLOT_XNAME>
   ```

1. (`ncn#`) Clear out the existing Redfish event subscriptions from the BMCs on the blade.

    1. Set the environment variable `SLOT` to the blade's location.

        ```bash
        SLOT=<SLOT_XNAME>
        ```

    1. Clear the Redfish event subscriptions.

        ```bash
        export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                -d client_id=admin-client \
                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

        for BMC in $(cray hsm inventory  redfishEndpoints list --type NodeBMC --format json | jq .RedfishEndpoints[].ID -r | grep ${SLOT}); do
            /usr/share/doc/csm/scripts/operations/node_management/delete_bmc_subscriptions.py $BMC
        done
        ```

        Each BMC on the blade will have output like the following:

        ```text
        Clearing subscriptions from NodeBMC x3000c0s9b0
        Retrieving BMC credentials from SCSD
        Retrieving Redfish Event subscriptions from the BMC: https://x3000c0s9b0/redfish/v1/EventService/Subscriptions
        Deleting event subscription: https://x3000c0s9b0/redfish/v1/EventService/Subscriptions/1
        Successfully deleted https://x3000c0s9b0/redfish/v1/EventService/Subscriptions/1
        ```

## Power on and boot the nodes

1. Determine which Boot Orchestration Service \(BOS\) templates to use to shut down nodes on the target blade.

   There will be separate session templates for UANs and computes nodes.

   1. List all the session templates.

      If it is unclear which session template is in use, proceed to the next substep.

      ```bash
      cray bos v1 sessiontemplate list
      ```

   1. Find the node xnames with `sat status`. In this example, the target blade is in slot `x9000c3s0`.

      ```bash
      sat status --filter 'xname=x9000c3s0*'
      ```

      Example output:

      ```text
      +---------------+------+----------+-------+------+---------+------+-------+-------------+----------+
      | xname         | Type | NID      | State | Flag | Enabled | Arch | Class | Role        | Net      |
      +---------------+------+----------+-------+------+---------+------+-------+-------------+----------+
      | x9000c3s0b1n0 | Node | 1        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      | x9000c3s0b2n0 | Node | 2        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      | x9000c3s0b3n0 | Node | 3        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      | x9000c3s0b4n0 | Node | 4        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      +---------------+------+----------+-------+------+---------+------+-------+-------------+----------+
      ```

   1. Find the `bos_session` value for each node via the Configuration Framework Service (CFS).

      ```bash
      cray cfs components describe x9000c3s0b1n0 | grep bos_session
      ```

      Example output:

      ```toml
      bos_session = "e98cdc5d-3f2d-4fc8-a6e4-1d301d37f52f"
      ```

   1. Find the required `templateName` value with BOS.

      ```bash
      cray bos v1 session describe BOS_SESSION | grep templateName
      ```

      Example output:

      ```toml
      templateName = "compute-nid1-4-sessiontemplate"
      ```

   1. Determine the list of xnames associated with the desired session template.

      ```bash
      cray bos v1 sessiontemplate describe SESSION_TEMPLATE_NAME | grep node_list
      ```

      Example output:

      ```toml
      node_list = [ "x9000c3s0b1n0", "x9000c3s0b2n0", "x9000c3s0b3n0", "x9000c3s0b4n0",]
      ```

1. Power on and boot the nodes.

   Use `sat bootsys` to power on and boot the nodes. Specify the appropriate component name (xname) for the slot, and
   a comma-separated list of the BOS session templates determined in the previous step.

   ```bash
   BOS_TEMPLATES=cos-2.0.30-slurm-healthy-compute
   sat bootsys boot --stage bos-operations --bos-limit x9000c3s0 --recursive --bos-templates $BOS_TEMPLATES
   ```

## Check firmware

1. Validate the firmware.

   Verify that the correct firmware versions are present for the node BIOS, node controller (nC), NIC mezzanine card (NMC), GPUs, and so on.

    1. Review [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md) to perform a dry run using FAS to verify firmware versions.

    1. If necessary, update firmware with FAS. See [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md) for more information.

## Check DVS

There should be a `cray-cps` pod (the broker), three `cray-cps-etcd` pods and their waiter, and at least one `cray-cps-cm-pm` pod. Usually there are two `cray-cps-cm-pm` pods: one on `ncn-w002` and one on another worker node.

1. Check the `cray-cps` pods on worker nodes and verify they are `Running`.

   ```bash
   kubectl get pods -Ao wide | grep cps
   ```

   Example output:

   ```text
   services   cray-cps-75cffc4b94-j9qzf    2/2  Running   0   42h 10.40.0.57  ncn-w001
   services   cray-cps-cm-pm-g6tjx         5/5  Running   21  41h 10.42.0.77  ncn-w003
   services   cray-cps-cm-pm-kss5k         5/5  Running   21  41h 10.39.0.80  ncn-w002
   services   cray-cps-etcd-knt45b8sjf     1/1  Running   0   42h 10.42.0.67  ncn-w003
   services   cray-cps-etcd-n76pmpbl5h     1/1  Running   0   42h 10.39.0.49  ncn-w002
   services   cray-cps-etcd-qwdn74rxmp     1/1  Running   0   42h 10.40.0.42  ncn-w001
   services   cray-cps-wait-for-etcd-jb95m 0/1  Completed
   ```

1. SSH to each worker node running CPS/DVS and run `dmesg -T`.

   Ensure that there are no recurring `"DVS: merge_one"` error messages shown. These error messages indicate that DVS is detecting an IP address change for one of the client nodes.

   ```bash
   dmesg -T | grep "DVS: merge_one"
   ```

   Example output:

   ```text
   [Tue Jul 21 13:09:54 2020] DVS: merge_one#351: New node map entry does not match the existing entry
   [Tue Jul 21 13:09:54 2020] DVS: merge_one#353:   nid: 8 -> 8
   [Tue Jul 21 13:09:54 2020] DVS: merge_one#355:   name: 'x3000c0s19b1n0' -> 'x3000c0s19b1n0'
   [Tue Jul 21 13:09:54 2020] DVS: merge_one#357:   address: '10.252.0.26@tcp99' -> '10.252.0.33@tcp99'
   [Tue Jul 21 13:09:54 2020] DVS: merge_one#358:   Ignoring.
   ```

1. SSH to the node and check each DVS mount.

   ```bash
   mount | grep dvs | head -1
   ```

   Example output:

   ```text
   /var/lib/cps-local/0dbb42538e05485de6f433a28c19e200 on /var/opt/cray/gpu/nvidia-squashfs-21.3 type dvs (ro,relatime,blksize=524288,statsfile=/sys/kernel/debug/dvs/mounts/1/stats,attrcache_timeout=14400,cache,nodatasync,noclosesync,retry,failover,userenv,noclusterfs,killprocess,noatomic,nodeferopens,no_distribute_create_ops,no_ro_cache,loadbalance,maxnodes=1,nnodes=6,nomagic,hash_on_nid,hash=modulo,nodefile=/sys/kernel/debug/dvs/mounts/1/nodenames,nodename=x3000c0s6b0n0:x3000c0s5b0n0:x3000c0s4b0n0:x3000c0s9b0n0:x3000c0s8b0n0:x3000c0s7b0n0)
   ```

## Check the HSN for the affected nodes

1. Determine the pod name for the Slingshot fabric manager pod and check the status of the fabric.

   ```bash
   kubectl exec -it -n services \
     $(kubectl get pods --all-namespaces |grep slingshot | awk '{print $2}') \
     -- fmn_status
   ```

## Check for duplicate IP address entries

1. Check for duplicate IP address entries in the Hardware State Management Database (HSM). Duplicate entries will cause DNS operations to fail.

   1. Verify that each node hostname resolves to a single IP address.

      ```bash
      nslookup x9000c3s0b0n1
      ```

      Example output with only one IP address resolving:

      ```text
      Server:         10.92.100.225
      Address:        10.92.100.225#53

      Name:   x9000c3s0b0n1
      Address: 10.100.0.26
      ```

   1. Reload the KEA configuration.

      ```bash
      curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
                -d '{ "command": "config-reload",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
      ```

      If there are no duplicate IP addresses within HSM, the following response is expected:

      ```json
      [
        {
          "result": 0,
          "text": "Configuration successful."
        }
      ]
      ```

      If there is a duplicate IP address, then an error message similar to the message below is expected. This example message indicates a duplicate IP address (`10.100.0.105`) in the HSM:

      ```json
      [{'result': 1, 'text': "Config reload failed: configuration error using file '/usr/local/kea/cray-dhcp-kea-dhcp4.conf': failed to add new host using the HW address '00:40:a6:83:50:a4 and DUID '(null)' to the IPv4 subnet id '0' for the address 10.100.0.105: There's already a reservation for this address"}]
      ```

1. Delete the duplicate entries, if there are any.

   If there are duplicate entries in the HSM as a result of this procedure, then delete the duplicate entries (`10.100.0.105` in this example).

   1. Show the `EthernetInterfaces` for the duplicate IP address:

      ```bash
      cray hsm inventory ethernetInterfaces list --ip-address 10.100.0.105 --format json | jq
      ```

      Example output for an IP address that is associated with two MAC addresses:

      ```json
      [
        {
          "ID": "0040a68350a4",
          "Description": "Node Maintenance Network",
          "MACAddress": "00:40:a6:83:50:a4",
          "IPAddresses": [
            {
              "IPAddress": "10.100.0.105"
            }
          ],
          "LastUpdate": "2021-08-24T20:24:23.214023Z",
          "ComponentID": "x9000c3s0b0n1",
          "Type": "Node"
        },
        {
          "ID": "0040a683639a",
          "Description": "Node Maintenance Network",
          "MACAddress": "00:40:a6:83:63:9a",
          "IPAddresses": [
            {
              "IPAddress": "10.100.0.105"
            }
          ],
          "LastUpdate": "2021-08-27T19:15:53.697459Z",
          "ComponentID": "x9000c3s0b0n1",
          "Type": "Node"
        }
      ]
      ```

   1. Delete the older entry.

      ```bash
      cray hsm inventory ethernetInterfaces delete 0040a68350a4
      ```

1. Use the following example `curl` command to check for active DHCP leases.

   If there are zero DHCP leases, then there is a configuration error.

   ```bash
   curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
             -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
   ```

   Example output with no active DHCP leases:

   ```json
   [
     {
       "arguments": {
         "leases": []
       },
       "result": 3,
       "text": "0 IPv4 lease(s) found."
     }
   ]
   ```

1. Check DNS using `nslookup`.

   ```bash
   nslookup 10.100.0.105
   ```

   Example output:

   ```text
   105.0.100.10.in-addr.arpa        name = nid001032-nmn.
   105.0.100.10.in-addr.arpa        name = nid001032-nmn.local.
   105.0.100.10.in-addr.arpa        name = x1005c3s0b0n0.
   105.0.100.10.in-addr.arpa        name = x1005c3s0b0n0.local.
   ```

1. Verify the ability to connect using SSH.

   ```bash
   ssh x9000c3s0b0n1
   ```

   Example output:

   ```text
   The authenticity of host 'x9000c3s0b0n1 (10.100.0.105)' can't be established.
   ECDSA key fingerprint is SHA256:wttHXF5CaJcQGPTIq4zWp0whx3JTwT/tpx1dJNyyXkA.
   Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
   Warning: Permanently added 'x1005c3s0b0n0' (ECDSA) to the list of known hosts.
   Last login: Tue Aug 31 10:45:49 2021 from 10.252.1.9
   ```
