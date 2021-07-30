# Validate CSM Health

Anytime after the installation of the CSM services, the health of the management nodes and all CSM services can be validated.

The following are examples of when to run health checks:
* After CSM install.sh completes
* Before and after NCN reboots
* After the system is brought back up
* Any time there is unexpected behavior observed
* In order to provide relevant information to create support tickets

The areas should be tested in the order they are listed on this page. Errors in an earlier check may cause errors in later checks because of dependencies.

## Topics: 

  - [1. Platform Health Checks](#1-platform-health-checks)
    - [1.1 ncnHealthChecks](#11-ncnhealthchecks)
    - [1.2 ncnPostgresHealthChecks](#12-ncnpostgreshealthchecks)
    - [1.3 BGP Peering Status and Reset](#13-bgp-peering-status-and-reset)
      - [1.3.1 Mellanox Switch](#131-mellanox-switch)
      - [1.3.2 Aruba Switch](#132-aruba-switch)
    - [1.4 Verify that KEA has active DHCP leases](#14-verify-that-kea-has-active-dhcp-leases)
    - [1.5 Verify ability to resolve external DNS](#15-verify-ability-to-resolve-external-dns)
    - [1.6 Verify Spire Agent is Running on Kubernetes NCNs](#16-verify-spire-agent-is-running-on-kubernetes-ncns)
    - [1.7 Verify the Vault Cluster is Healthy](#17-verify-the-vault-cluster-is-healthy)
    - [1.8 Automated Goss Testing](#18-automated-goss-testing)
      - [1.8.1 Known Test Issues](#181-known-test-issues)
  - [2. Hardware Management Services Health Checks](#2-hardware-management-services-health-checks)
    - [2.1 HMS Test Execution](#21-hms-test-execution)
    - [2.2 Hardware State Manager Discovery Validation](#22-hardware-state-manager-discovery-validation)
  - [3 Software Management Services Health Checks](#3-software-management-services-health-checks)
  - [4. Booting CSM Barebones Image](#4-booting-csm-barebones-image)
    - [4.1 Locate CSM Barebones Image in IMS](#41-locate-csm-barebones-image-in-ims)
    - [4.2 Create a BOS Session Template for the CSM Barebones Image](#42-create-a-bos-session-template-for-the-csm-barebones-image)
    - [4.3 Find an available compute node](#43-find-an-available-compute-node)
    - [4.4 Reboot the node using a BOS session template](#44-reboot-the-node-using-a-bos-session-template)
    - [4.6 Connect to the node's console and watch the boot](#46-connect-to-the-nodes-console-and-watch-the-boot)
  - [5. UAS / UAI Tests](#5-uas--uai-tests)
    - [5.1 Initialize and Authorize the CLI](#51-initialize-and-authorize-the-cli)
      - [5.1.1 Stop Using the CRAY_CREDENTIALS Service Account Token](#511-stop-using-the-cray_credentials-service-account-token)
      - [5.1.2 Initialize the CLI Configuration](#512-initialize-the-cli-configuration)
      - [5.1.3 Authorize the CLI for a User](#513-authorize-the-cli-for-a-user)
      - [5.1.4 CLI Troubleshooting](#514-cli-troubleshooting)
    - [5.2 Validate UAS and UAI Functionality](#52-validate-uas-and-uai-functionality)
      - [5.2.1 Validate the Basic UAS Installation](#521-validate-the-basic-uas-installation)
      - [5.2.2 Validate UAI Creation](#522-validate-uai-creation)
      - [5.2.3 UAS/UAI Troubleshooting](#523-uasuai-troubleshooting)
        - [5.2.3.1 Authorization Issues](#5231-authorization-issues)
        - [5.2.3.2 UAS Cannot Access Keycloak](#5232-uas-cannot-access-keycloak)
        - [5.2.3.3 UAI Images not in Registry](#5233-uai-images-not-in-registry)
        - [5.2.3.4 Missing Volumes and other Container Startup Issues](#5234-missing-volumes-and-other-container-startup-issues)
  
<a name="platform-health-checks"></a>
## 1. Platform Health Checks

Scripts do not verify results. Script output includes analysis needed to determine pass/fail for each check. All health checks are expected to pass.

Health Check scripts can be run:
* After CSM install.sh has been run (not before)
* Before and after one of the NCNs reboots
* After the system or a single node goes down unexpectedly
* After the system is gracefully shut down and brought up
* Any time there is unexpected behavior on the system to get a baseline of data for CSM services and components
* In order to provide relevant information to support tickets that are being opened after CSM install.sh has been run


Available Platform Health Checks:
1. [ncnHealthChecks](#pet-ncnhealthchecks)
1. [ncnPostgresHealthChecks](#pet-ncnpostgreshealthchecks)
1. [BGP Peering Status and Reset](#pet-bgp)
1. [KEA / DHCP](#net-kea)
1. [External DNS](#net-extdns)
1. [Spire Agent](#net-spire)
1. [Vault Cluster](#net-vault)
1. [Automated Goss Testing](#automated-goss-testing)

<a name="pet-ncnhealthchecks"></a>
### 1.1 ncnHealthChecks

Health Check scripts can be found and run on any worker or master node (not on PIT node), from any directory.

   ```bash
   ncn# /opt/cray/platform-utils/ncnHealthChecks.sh
   ```

The ncnHealthChecks script reports the following health information:
* Kubernetes status for master and worker NCNs
* Ceph health status
* Health of etcd clusters
* Number of pods on each worker node for each etcd cluster
* Alarms set for any of the Etcd clusters
* Health of Etcd cluster’s database
* List of automated etcd backups for the Boot Orchestration Service (BOS), Boot Script Service (BSS), Compute Rolling Upgrade Service (CRUS), and Domain Name Service (DNS), and Firmware Action Service (FAS) clusters
* NCN node uptimes
* NCN master and worker node resource consumption
* NCN node xnames and metal.no-wipe status
* NCN worker node pod counts
* Pods yet to reach the running state

Execute the ncnHealthChecks script and analyze the output of each individual check. 

**IMPORTANT:** When the PIT node is booted the NCN node metal.no-wipe status is not available and is correctly reported as 'unavailable'. Once ncn-m001 has been booted the NCN metal.no-wipe status is expected to be reported as metal.no-wipe=1.

**IMPORTANT:** Only when ncn-m001 has been booted, if the output of the ncnHealthChecks.sh script shows that there are nodes that do not have the metal.no-wipe=1 status, then do the following:

```bash
ncn# csi handoff bss-update-param --set metal.no-wipe=1 --limit <SERVER_XNAME>
```

**IMPORTANT:** If the output of pod statuses indicates that there are pods in the `Evicted` state, it may be due to the /root file system being filled up on the Kubernetes node in question. Kubernetes will begin evicting pods once the root file system space is at 85% until it is back under 80%. This may commonly happen on ncn-m001 as it is a location that install and doc files may be downloaded to. It may be necessary to clean-up space in the /root directory if this is the root cause of pod evictions. The following commands can be used to determine if analysis of files under /root is needed to free-up space.

```bash
ncn# df -h /root
Filesystem      Size  Used Avail Use% Mounted on
LiveOS_rootfs   280G  245G   35G  88% /
```

```bash
ncn# du -h -s /root/
225G  /root/
```

```bash
ncn# du -ah -B 1024M /root | sort -n -r | head -n 10
```

**Note**: The `cray-crus-` pod is expected to be in the Init state until slurm and munge
are installed. In particular, this will be the case if executing this as part of the validation after completing the [Install CSM Services](../install/install_csm_services.md).
If in doubt, validate the CRUS service using the [CMS Validation Tool](#sms-health-checks). If the CRUS check passes using that tool, do not worry about the `cray-crus-` pod state.

Additionally, hmn-discovery and unbound manager cronjob pods may be in a 'NotReady' state. This is expected as these pods are periodically started and transition to the completed state. 

<a name="pet-ncnpostgreshealthchecks"></a>
### 1.2 ncnPostgresHealthChecks


Postgres Health Check scripts can be found and run on any worker or master node (not on PIT node), from any directory.
The ncnPostgresHealthChecks script reports the following postgres health information:
* The status of each postgresql resource
* The number of cluster members
* The node which is the Leader
* The state of the each cluster member
* Replication Lag for any cluster member
* Kubernetes postgres pod status

Execute ncnPostgresHealthChecks script and analyze the output of each individual check.

   ```bash
   ncn# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
   ```
1. Check the STATUS of the postgresql resources which are managed by the operator:
    ```bash
    NAMESPACE   NAME                         TEAM                VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE   STATUS
    services    cray-sls-postgres            cray-sls            11        3      1Gi                                     12d   Running
    ```
    If any postgresql resources remains in a STATUS other than Running (such as SyncFailed), refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#syncfailed).

1. For a particular Postgres cluster, the expected output is similar to the following:
    ```bash
    --- patronictl, version 1.6.5, list for services leader pod cray-sls-postgres-0 ---
    + Cluster: cray-sls-postgres (6938772644984361037) ---+----+-----------+
    |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
    +---------------------+------------+--------+---------+----+-----------+
    | cray-sls-postgres-0 | 10.47.0.35 | Leader | running |  1 |           |
    | cray-sls-postgres-1 | 10.36.0.33 |        | running |  1 |         0 |
    | cray-sls-postgres-2 | 10.44.0.42 |        | running |  1 |         0 |
    +---------------------+------------+--------+---------+----+-----------+
    ```
    The points below will cover the data in the table above for Member, Role, State, and Lag in MB columns.

    For each Postgres cluster:
      - Verify there are three cluster members (with the exception of sma-postgres-cluster where there should be only two cluster members).
      If the number of cluster members is not correct, refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#missing).

      - Verify there is one cluster member with the Leader Role and log output indicates expected status. Such as:
         ```bash
         i am the leader with the lock
         ```
         For example:
         ```bash
         --- Logs for services Leader Pod cray-sls-postgres-0 ---
            ERROR: get_cluster
            INFO: establishing a new patroni connection to the postgres cluster
            INFO: initialized a new cluster
            INFO: Lock owner: cray-sls-postgres-0; I am cray-sls-postgres-0
            INFO: Lock owner: None; I am cray-sls-postgres-0
            INFO: no action. i am the leader with the lock
            INFO: No PostgreSQL configuration items changed, nothing to reload.
            INFO: postmaster pid=87
            INFO: running post_bootstrap
            INFO: trying to bootstrap a new cluster
         ```
         Errors reported prior to the lock status, such as **ERROR: get_cluster** or **ERROR: ObjectCache.run ProtocolError('Connection broken: IncompleteRead(0 bytes read)', IncompleteRead(0 bytes read))** can be ignored.  
         If there is no Leader, refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#leader).

      - Verify the State of each cluster member is 'running'.
      If any cluster members are found to be in a non 'running' state (such as 'start failed'), refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#diskfull).

      - Verify there is no large or growing Lag.
      If any cluster members are found to have Lag, refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#lag).

1. Check that all Kubernetes Postgres pods have a STATUS of Running.
    ```bash
    NAMESPACE           NAME                                                              READY   STATUS             RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
    services            cray-sls-postgres-0                                               3/3     Running            3          6d      10.38.0.102   ncn-w002   <none>           <none>
    services            cray-sls-postgres-1                                               3/3     Running            3          5d20h   10.42.0.89    ncn-w001   <none>           <none>
    services            cray-sls-postgres-2                                               3/3     Running            0          5d20h   10.36.0.31    ncn-w003   <none>           <none>
    ```

    If any Postgres pods have a STATUS other then Running, gather more information from the pod and refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#missing).

    ```bash
    ncn# kubectl describe pod <pod name> -n <pod namespace>
    ncn# kubectl logs <pod name> -n <pod namespace> -c <pod container name>
    ```

<a name="pet-bgp"></a>
### 1.3 BGP Peering Status and Reset
Verify that Border Gateway Protocol (BGP) peering sessions are established for each worker node on the system. 

Check the Border Gateway Protocol (BGP) status on the Aruba or Mellanox switches.
Verify that all sessions are in an **Established** state. If the state of any
session in the table is **Idle**, reset the BGP sessions.

On an NCN, determine the IP addresses of switches:

```bash
ncn-m001# kubectl get cm config -n metallb-system -o yaml | head -12
```

Expected output looks similar to the following:
```
apiVersion: v1
data:
  config: |
    peers:
    - peer-address: 10.252.0.2
      peer-asn: 65533
      my-asn: 65533
    - peer-address: 10.252.0.3
      peer-asn: 65533
      my-asn: 65533
    address-pools:
    - name: customer-access
```

Using the first peer-address (10.252.0.2 here), log in using `ssh` as the administrator to the first switch and note in the returned output if a Mellanox or Aruba switch is indicated.

```bash
ncn-m001# ssh admin@10.252.0.2
```

* On a Mellanox switch, `Mellanox Onyx Switch Management` or `Mellanox Switch` may be displayed after logging in to the switch with `ssh`. In this case, proceed to the [Mellanox steps](#pet-bgp-mellanox).
* On an Aruba switch, `Please register your products now at: https://asp.arubanetworks.com` may be displayed after logging in to the switch with `ssh`. In this case, proceed to the [Aruba steps](#pet-bgp-aruba).

<a name="pet-bgp-mellanox"></a>
#### 1.3.1 Mellanox Switch 

1. Enable:
   ```
   sw-spine-001# enable
   ```

1. Verify BGP is enabled:
   ```
   sw-spine-001# show protocols | include bgp
   ```
   
   Expected output looks similar to the following:
   ```
   bgp:                    enabled
   ```

1. Check peering status:
   ```
   sw-spine-001# show ip bgp summary
   ```

   Expected output looks similar to the following:
   ```
   VRF name                  : default
   BGP router identifier     : 10.252.0.2
   local AS number           : 65533
   BGP table version         : 3
   Main routing table version: 3
   IPV4 Prefixes             : 59
   IPV6 Prefixes             : 0
   L2VPN EVPN Prefixes       : 0

   ------------------------------------------------------------------------------------------------------------------
   Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
   ------------------------------------------------------------------------------------------------------------------
   10.252.1.10       4    65533        2945      3365      3         0      0      1:00:21:33    ESTABLISHED/20
   10.252.1.11       4    65533        2942      3356      3         0      0      1:00:20:49    ESTABLISHED/19
   10.252.1.12       4    65533        2945      3363      3         0      0      1:00:21:33    ESTABLISHED/20
   ```

1. If one or more BGP session is reported in an **Idle** state, reset BGP to re-establish the sessions:
   ```
   sw-spine-001# clear ip bgp all
   ```

   * It may take several minutes for all sessions to become **Established**. Wait a minute or so, and then verify that all sessions now are all reported as **Established**. If some sessions remain in an **Idle** state, re-run the **clear ip bgp all** command and check again.

   * If after several tries one or more BGP session remains **Idle**, see [Check BGP Status and Reset Sessions](network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

2. Repeat the above **Mellanox** procedure using the second peer-address (10.252.0.3 here).

<a name="pet-bgp-aruba"></a>
#### 1.3.2 Aruba Switch

On an Aruba switch, the prompt may include `sw-spine` or `sw-agg`.

1. Check BGP peering status.
   ```
   sw-agg01# show bgp ipv4 unicast summary
   ```

   Expected output looks similar to the following:
   ```
   VRF : default
   BGP Summary
   -----------
    Local AS               : 65533        BGP Router Identifier  : 10.252.0.4
    Peers                  : 7            Log Neighbor Changes   : No
    Cfg. Hold Time         : 180          Cfg. Keep Alive        : 60
    Confederation Id       : 0

    Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
    10.252.0.5      65533       19579   19588   20h:40m:30s  Established   Up
    10.252.1.7      65533       34137   39074   20h:41m:53s  Established   Up
    10.252.1.8      65533       34134   39036   20h:36m:44s  Established   Up
    10.252.1.9      65533       34104   39072   00m:01w:04d  Established   Up
    10.252.1.10     65533       34105   39029   00m:01w:04d  Established   Up
    10.252.1.11     65533       34099   39042   00m:01w:04d  Established   Up
    10.252.1.12     65533       34101   39012   00m:01w:04d  Established   Up
   ```

1. If one or more BGP session is reported in a **Idle** state, reset BGP to re-establish the sessions:
   ```
   sw-agg01# clear bgp *
   ```

   * It may take several minutes for all sessions to become **Established**. Wait a minute or so, and then
   verify that all sessions now are reported as **Established**. If some sessions remain in an **Idle** state,
   re-run the **clear bgp * ** command and check again.

   * If after several tries one or more BGP session remains **Idle**, see [Check BGP Status and Reset Sessions](network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md)


1. Repeat the above **Aruba** procedure using the second peer-address (10.252.0.5 in this example).

<a name="net-kea"></a>
### 1.4 Verify that KEA has active DHCP leases

Verify that KEA has active DHCP leases. Right after an fresh install of CSM, it is important to verify that KEA is currently handing out DHCP leases on the system. The following commands can be ran on any of the master nodes or worker nodes.

Get an API Token:
```bash
ncn# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                 -d client_id=admin-client \
                 -d client_secret=`kubectl get secrets admin-client-auth \
                 -o jsonpath='{.data.client-secret}' | base64 -d` \
                          https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

Retrieve all the leases currently in KEA:
```bash
ncn# curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
```

If there is an non-zero amount of DHCP leases for air-cooled hardware returned, that is a good indication that KEA is working.

<a name="net-extdns"></a>
### 1.5 Verify ability to resolve external DNS

If unbound is configured to resolve outside hostnames, then the following check should be performed. If this has not been done, then this check may be skipped. 

Run the following on one of the master or worker nodes (not the PIT node):

```bash
ncn# nslookup cray.com ; echo "Exit code is $?"
```

Expected output looks similar to the following:
```
Server:         10.92.100.225
Address:        10.92.100.225#53

Non-authoritative answer:
Name:   cray.com
Address: 52.36.131.229

Exit code is 0
```

Verify that the command has exit code 0, reports no errors, and resolves the address.

<a name="net-spire"></a>
### 1.6 Verify Spire Agent is Running on Kubernetes NCNs

Execute the following command on all Kubernetes NCNs (excluding the PIT):

```bash
ncn# goss -g /opt/cray/tests/install/ncn/tests/goss-spire-agent-service-running.yaml validate
```

Known failures and how to recover:

* K8S Test: Verify spire-agent is enabled and running

  - The `spire-agent` service may fail to start on Kubernetes NCNs, logging errors (via journalctl) similar to "join token does not exist or has already been used" or the last logs containing multiple lines of "systemd[1]: spire-agent.service: Start request repeated too quickly.". Deleting the `request-ncn-join-token` daemonset pod running on the node may clear the issue. Even though the `spire-agent` systemctl service on the Kubernetes node should eventually restart cleanly, the user may have to log in to the impacted nodes and restart the service. The following recovery procedure can be run from any Kubernetes node in the cluster.
     1. Set `NODE` to the NCN which is experiencing the issue. In this example, `ncn-w002`.
        ```bash
          ncn# export NODE=ncn-w002
          ```
     1. Define the following function
        ```bash
        ncn# function renewncnjoin() { for pod in $(kubectl get pods -n spire |grep request-ncn-join-token | awk '{print $1}'); do if kubectl describe -n spire pods $pod | grep -q "Node:.*$1"; then echo "Restarting $pod running on $1"; kubectl delete -n spire pod "$pod"; fi done }
        ```
     1. Run the function as follows:
        ```bash
        ncn# renewncnjoin $NODE
        ```

  - The `spire-agent` service may also fail if an NCN was powered off for too long and its tokens expired. If this happens, delete `/root/spire/agent_svid.der`, `/root/spire/bundle.der`, and `/root/spire/data/svid.key` off the NCN before deleting the `request-ncn-join-token` daemonset pod.

<a name="net-vault"></a>
### 1.7 Verify the Vault Cluster is Healthy

Execute the following commands on ```ncn-m002```:

```bash
ncn-m002# goss -g /opt/cray/tests/install/ncn/tests/goss-k8s-vault-cluster-health.yaml validate
```

Check the output to verify no failures are reported:
```
Count: 2, Failed: 0, Skipped: 0
```

<a name="automated-goss-testing"></a>
### 1.8 Automated Goss Testing

There are multiple [Goss](https://github.com/aelsabbahy/goss) test suites available that cover a variety of sub-systems.

Run the NCN health checks against the three different types of nodes with the following commands:

**IMPORTANT:** These tests may only be successful while booted into the PIT node. Do not run these as part of upgrade testing. This includes the Kubernetes check in the next block.


```bash
pit# /opt/cray/tests/install/ncn/automated/ncn-healthcheck-master
pit# /opt/cray/tests/install/ncn/automated/ncn-healthcheck-worker
pit# /opt/cray/tests/install/ncn/automated/ncn-healthcheck-storage
```

And the Kubernetes test suite via:

```bash
pit# /opt/cray/tests/install/ncn/automated/ncn-kubernetes-checks
```

<a name="autogoss-issues"></a>
#### 1.8.1 Known Test Issues

* These tests can only reliably be executed from the PIT node. Should be addressed in a future release.
* K8S Test: Kubernetes Query BSS Cloud-init for ca-certs
  - May fail immediately after platform install. Should pass after the TrustedCerts Operator has updated BSS (Global cloud-init meta) with CA certificates.
* K8S Test: Kubernetes Velero No Failed Backups
  - Because of a [known issue](https://github.com/vmware-tanzu/velero/issues/1980) with Velero, a backup may be attempted immediately upon the deployment of a backup schedule (for example, vault). It may be necessary to use the ```velero``` command to delete backups from a Kubernetes node to clear this situation.

<a name="hms-health-checks"></a>
## 2. Hardware Management Services Health Checks

Execute the HMS smoke and functional tests after the CSM install to confirm that the Hardware Management Services are running and operational.

<a name="hms-test-execution"></a>
### 2.1 HMS Test Execution

These tests should be executed as root on at least one worker NCN and one master NCN (but **not** ncn-m001 if it is still the PIT node).

1. Run the HMS smoke tests.

```bash
ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_smoke_tests_ncn-resources.sh
```
1. Examine the output for errors or failures.
1. If no failures occur, then run the HMS functional tests. 
```bash
ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_functional_tests_ncn-resources.sh
```
1. Examine the output for errors or failures.

<a name="hms-smd-discovery-validation"></a>
### 2.2 Hardware State Manager Discovery Validation

By this point in the installation process, the Hardware State Manager (HSM) should 
have done its discovery of the system.

The foundational information for this discovery is from the System Layout Service (SLS). Thus, a
comparison needs to be done to see that what is specified in SLS (focusing on 
BMC components and Redfish endpoints) are present in HSM.

The `hpe-csm-scripts` package provides a script called `hsm_discovery_verify.sh`
that can be run at this time to do this validation. This script can be run 
from any Kubernetes master or worker (should also work from a laptop or any 
machine that can get an access token and run `curl` commands to HMS services via 
the API GW):

```
ncn-m001# /opt/cray/csm/scripts/hms_verification/hsm_discovery_verify.sh
```

There are no command line arguments. The output will ideally appear as follows:

```bash
ncn-m001# /opt/cray/csm/scripts/hms_verification/hsm_discovery_verify.sh

Fetching SLS Components...
 
Fetching HSM Components...
 
Fetching HSM Redfish endpoints...
 
=============== BMCs in SLS not in HSM components ===============
ALL OK
 
=============== BMCs in SLS not in HSM Redfish Endpoints =============== 
ALL OK
```

If there are mismatches, these will be displayed in the appropriate section of
the output.

**NOTES:**
* BMCs for management cluster master node 'm001' will not typically be present in HSM component data.
* Chassis Management Controllers (CMC) may show up as not being present in HSM. CMCs for Intel server blades can be ignored. Gigabyte server blade CMCs not found in HSM is not normal and should be investigated. If a Gigabyte CMC is expected to not be connected to the HMN network, then it can be ignored.
* HPE PDUs are not supported at this time and will likely show up as not being found in HSM.
* BMCs having no association with a management switch port will be annotated as such, and should be investigated. Exceptions to this are in Mountain or Hill configurations where Mountain BMCs will show this condition on SLS/HSM mismatches, which is normal.
* In Hill configurations SLS assumes BMCs in chassis 1 and 3 are populated, and in Mountain configurations SLS assumes all BMCs are populated. Any non-populated BMCs will have no HSM data and will show up in the mismatch list.

**Known issues:**
A listing of known hardware discovery issues and workarounds can be found here in the [CSM Troubleshooting Information](../troubleshooting/index.md#known-issues-hardware-discovery) chapter.

* Air cooled hardware is not getting properly discovered with an Aruba leaf switches.

   Symptoms:
   - The System has Aruba leaf switches.
   - Air cooled hardware is reported to not be present under State Components and Inventory Redfish Endpoints in Hardware State Manager by the hsm_discovery_verify.sh script.
   - BMCs have IP addresses given out by DHCP, but in DNS their xname hostname does not resolve. 

   Procedure to determine if the system is affected by this known issue:
   1. Determine the name of the last HSM discovery job that ran.
      ```bash
      ncn# HMS_DISCOVERY_POD=$(kubectl -n services get pods -l app=hms-discovery | tail -n 1 | awk '{ print $1 }')
      ncn# echo $HMS_DISCOVERY_POD 
      hms-discovery-1624314420-r8c49
      ```
   
   2. Look at the logs of the HMS discovery job to find the MAC addresses associated with instances of the `MAC address in HSM not found in any switch!` error messages. The following command will parse the logs are report these MAC addresses.
      > Each of the following MAC address does not contain a ComponentID in Hardware State Manager in the Ethernet interfaces table, which can be viewed with: `cray hsm inventory ethernetInterfaces list`.
      ```bash
      ncn# UNKNOWN_MACS=$(kubectl -n services logs $HMS_DISCOVERY_POD hms-discovery | jq 'select(.msg == "MAC address in HSM not found in any switch!").unknownComponent.ID' -r -c)
      ncn# echo "$UNKNOWN_MACS"
      b42e99dff361
      9440c9376780
      b42e99bdd255
      b42e99dfecf1
      b42e99dfebc1
      b42e99dfec49
      ```

   3. Look at the logs of the HMS discovery job to find the MAC address associated with instances of the `Found MAC address in switch.` log messages. The following command will parse the logs are report these MAC addresses. 
      ```bash
      ncn# FOUND_IN_SWITCH_MACS=$(kubectl -n services logs $HMS_DISCOVERY_POD hms-discovery | jq 'select(.msg == "Found MAC address in switch.").macWithoutPunctuation' -r)
      ncn# echo "$FOUND_IN_SWITCH_MACS"
      b42e99bdd255
      ```
   
   4. Perform a `diff` between the two sets of collected MAC addresses to see if the Aruba leaf switches in the system are affected by a known SNMP issues with Aruba switches. 
      ```bash
      ncn# diff -y <(echo "$UNKNOWN_MACS" | sort -u) <(echo "$FOUND_IN_SWITCH_MACS" | sort -u)
      9440c9376780                                                  <
      b42e99bdd255                                                    b42e99bdd255
      b42e99dfebc1                                                  <
      b42e99dfec49                                                  <
      b42e99dfecf1                                                  <
      b42e99dff361                                                  <
      ```

      If there are any MAC addresses on the left column that are not on the right column, then it is likely the leaf switches in the system are being affected by the SNMP issue. Apply the workaround described in [the following procedure](../install/aruba_snmp_known_issue_10_06_0010.md) to the Aruba leaf switches in the system.

      If all of the MAC addresses on the left column are present in the right column, then the system is not affected by this known issue.

<a name="sms-health-checks"></a>
## 3 Software Management Services Health Checks

Run the Software Management Services health checks. These can be run from any master or worker node (but **not** the PIT).

```bash
ncn# /usr/local/bin/cmsdev test -q all
```

The final line of output will state `SUCCESS` or `FAILURE`. In the case of success, it will exit with return code 0. Otherwise it will exit with non-0 return code.

Additional test execution details can be found in `/opt/cray/tests/cmsdev.log`.

<a name="booting-csm-barebones-image"></a>
## 4. Booting CSM Barebones Image

Included with the Cray System Management (CSM) release is a pre-built node image that can be used
to validate that core CSM services are available and responding as expected. The CSM barebones
image contains only the minimal set of RPMs and configuration required to boot an image and is not
suitable for production usage. To run production work loads, it is suggested that an image from
the Cray OS (COS) product, or similar, be used.

---
**NOTES**

* The CSM Barebones image included with the release will not successfully complete
the beyond the dracut stage of the boot process. However, if the dracut stage is reached the
boot can be considered successful and shows that the necessary CSM services needed to
boot a node are up and available.
   * This inability to fully boot the barebones image will be resolved in future releases of the
   CSM product.
* In addition to the CSM Barebones image, the release also includes an IMS Recipe that
can be used to build the CSM Barebones image. However, the CSM Barebones recipe currently requires
RPMs that are not installed with the CSM product. The CSM Barebones recipe can be built after the
Cray OS (COS) product stream is also installed on to the system.
   * In future releases of the CSM product, work will be undertaken to resolve these dependency issues.
* Use the CLI to complete these tasks. If needed, see the [Initialize and Authorize the CLI](#uas-uai-init-cli) section.
---

1. [Locate CSM Barebones Image in IMS](#locate-csm-barebones-image-in-ims)
1. [Create a BOS Session Template for the CSM Barebones Image](#csm-bos-session-template)
1. [Find an available compute node](#csm-node)
1. [Reboot the node using a BOS session template](#csm-reboot)
1. [Watch Boot on Console](#csm-watch-boot)

<a name="locate-csm-barebones-image-in-ims"></a>
### 4.1 Locate CSM Barebones Image in IMS

Locate the CSM Barebones image and note the path to the image's manifest.json in S3.

```bash
ncn# cray ims images list --format json | jq '.[] | select(.name | contains("barebones"))'
```

Expected output is similar to the following:
```json
{
  "created": "2021-01-14T03:15:55.146962+00:00",
  "id": "293b1e9c-2bc4-4225-b235-147d1d611eef",
  "link": {
    "etag": "6d04c3a4546888ee740d7149eaecea68",
    "path": "s3://boot-images/293b1e9c-2bc4-4225-b235-147d1d611eef/manifest.json",
    "type": "s3"
  },
  "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4"
}
```

<a name="csm-bos-session-template"></a>
### 4.2 Create a BOS Session Template for the CSM Barebones Image

The session template below can be copied and used as the basis for the BOS Session Template. As noted below, make sure the S3 path for the manifest matches the S3 path shown in the Image Management Service (IMS).

1. Create `sessiontemplate.json`
   ```bash
   ncn# vi sessiontemplate.json
   ```

   The session template should contain the following:
   ```json
   {
     "boot_sets": {
       "compute": {
         "boot_ordinal": 2,
         "etag": "6d04c3a4546888ee740d7149eaecea68",// <== This should be set to the etag of the IMS Image
         "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
         "network": "nmn",
         "node_roles_groups": [
           "Compute"
         ],
         "path": "s3://boot-images/293b1e9c-2bc4-4225-b235-147d1d611eef/manifest.json",// <== Make sure this path matches the IMS Image Path
         "rootfs_provider": "cpss3",
         "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
         "type": "s3"
       }
     },
     "cfs": {
       "configuration": "cos-integ-config-1.4.0"
     },
     "enable_cfs": false,
     "name": "shasta-1.4-csm-bare-bones-image"
   }
   ```
2. Create the BOS session template using the following file as input:
   ```
   ncn# cray bos sessiontemplate create --file sessiontemplate.json --name shasta-1.4-csm-bare-bones-image
   ```
   The expected output is:
   ```
   /sessionTemplate/shasta-1.4-csm-bare-bones-image
   ```

<a name="csm-node"></a>
### 4.3 Find an available compute node

```bash
ncn# cray hsm state components list --role Compute --enabled true
```

Example output:
```
[[Components]]
ID = "x3000c0s17b1n0"
Type = "Node"
State = "On"
Flag = "OK"
Enabled = true
Role = "Compute"
NID = 1
NetType = "Sling"
Arch = "X86"
Class = "River"

[[Components]]
ID = "x3000c0s17b2n0"
Type = "Node"
State = "On"
Flag = "OK"
Enabled = true
Role = "Compute"
NID = 2
NetType = "Sling"
Arch = "X86"
Class = "River"
```

Choose a node from those listed and set `XNAME` to its ID. In this example, `x3000c0s17b2n0`:
```bash
ncn# export XNAME=x3000c0s17b2n0
```

<a name="csm-reboot"></a>
### 4.4 Reboot the node using a BOS session template

Create a BOS session to reboot the chosen node using the BOS session template that was created:
```bash
ncn# cray bos session create --template-uuid shasta-1.4-csm-bare-bones-image --operation reboot --limit $XNAME
```

Expected output looks similar to the following:
```
limit = "x3000c0s17b2n0"
operation = "reboot"
templateUuid = "shasta-1.4-csm-bare-bones-image"
[[links]]
href = "/v1/session/8f2fc013-7817-4fe2-8e6f-c2136a5e3bd1"
jobId = "boa-8f2fc013-7817-4fe2-8e6f-c2136a5e3bd1"
rel = "session"
type = "GET"

[[links]]
href = "/v1/session/8f2fc013-7817-4fe2-8e6f-c2136a5e3bd1/status"
rel = "status"
type = "GET"
```

<a name="csm-watch-boot"></a>
### 4.6 Connect to the node's console and watch the boot

See [Manage Node Consoles](conman/Manage_Node_Consoles.md) for information on how to connect to the node's console.

The boot will fail, but should reach the dracut stage. If the dracut stage is reached, the boot
can be considered successful and shows that the necessary CSM services needed to boot a node are
up and available. The boot is considered successful if the console output has something similar
to the following near its end:
```
[    7.876909] dracut: FATAL: Don't know how to handle 'root=craycps-s3:s3://boot-images/e3ba09d7-e3c2-4b80-9d86-0ee2c48c2214/rootfs:c77c0097bb6d488a5d1e4a2503969ac0-27:dvs:api-gw-service-nmn.local:300:nmn0'
[    7.898169] dracut: Refusing to continue
```

<a name="uas-uai-tests"></a>
## 5. UAS / UAI Tests

1. [Initialize and Authorize the CLI](#uas-uai-init-cli)
   1. [Stop Using CRAY_CREDENTIALS Service Account Token](#uas-uai-init-cli-stop)
   1. [Initialize the CLI Configuration](#uas-uai-init-cli-init)
   1. [Authorize the CLI for a User](#uas-uai-init-cli-auth)
   1. [CLI Troubleshooting](#uas-uai-init-cli-debug)
1. [Validate UAS and UAI Functionality](#uas-uai-validate)
   1. [Validate Basic UAS Installation](#uas-uai-validate-install)
   1. [Validate UAI Creation](#uas-uai-validate-create)
   1. [UAS/UAI Troubleshooting](#uas-uai-validate-debug)
      1. [Authorization Issues](#uas-uai-validate-debug-auth)
      1. [UAS Cannot Access Keycloak](#uas-uai-validate-debug-keycloak)
      1. [UAI Images not in Registry](#uas-uai-validate-debug-registry)
      1. [Missing Volumes and Other Container Startup Issues](#uas-uai-validate-debug-container)

<a name="uas-uai-init-cli"></a>
### 5.1 Initialize and Authorize the CLI

The procedures below use the CLI as an authorized user and run on two separate node types. The first part runs on the LiveCD node, while the second part runs on a non-LiveCD Kubernetes master or worker node. When using the CLI on either node, the CLI configuration needs to be initialized and the user running the procedure needs to be authorized. This section describes how to initialize the CLI for use by a user, and how to authorize the CLI as a user to run the procedures on any given node. The following procedures will need to be repeated in both stages of the validation procedure.

<a name="uas-uai-init-cli-stop"></a>
#### 5.1.1 Stop Using the CRAY_CREDENTIALS Service Account Token

Installation procedures leading up to production mode on Shasta use the CLI with a Kubernetes managed service account normally used for internal operations. There is a procedure for extracting the OAUTH token for this service account and assigning it to the `CRAY_CREDENTIALS` environment variable to permit simple CLI operations. The UAS / UAI validation procedure runs as a post-installation procedure and requires an actual user with Linux credentials, not this service account. Unset the `CRAY_CREDENTIALS` environment variable prior to running any of the steps below:

```bash
ncn# unset CRAY_CREDENTIALS
```

<a name="uas-uai-init-cli-init"></a>
#### 5.1.2 Initialize the CLI Configuration

The CLI needs to know what host to use to obtain authorization and what user is requesting authorization so it can obtain an OAUTH token to talk to the API Gateway. This is accomplished by initializing the CLI configuration. In this example, the `vers` username is used. In practice, `vers` and the response to the `password: ` prompt should be replaced with the username and password of the administrator running the validation procedure.

To check whether the CLI needs initialization:

```bash
ncn# cray config describe
```

   * The `cray config describe` output may look similar to this:
      ```
      # cray config describe
      Your active configuration is: default
      [core]
      hostname = "https://api-gw-service-nmn.local"

      [auth.login]
      username = "vers"
      ```
      This means the CLI is initialized and logged in as `vers`.
         * If the user is not logged in as `vers`, authorize the user with their username and password in the next section.  
         * If logged in as `vers`, proceed to the validation procedure on that node.
   * The `cray config describe` output may instead look like this:
      ```
      Usage: cray config describe [OPTIONS]

      Error: No configuration exists. Run `cray init`
      ```
      This means the CLI needs to be initialized. To do so, run the following:
      ```bash
      ncn# cray init
      ```

      When prompted, remember to substitute the username instead of 'vers'.
      Expected output (including the typed input) should look similar to the following:
      ```
      Cray Hostname: api-gw-service-nmn.local
      Username: vers
      Password:
      Success!

      Initialization complete.
      ```

<a name="uas-uai-init-cli-auth"></a>
#### 5.1.3 Authorize the CLI for a User

If there is a CLI that is initialized and authorized for a different user, authorize the CLI for the user account in use. Use the following command to authorize the current user (substitute the username and password for `vers`):

```bash
ncn# cray auth login
```

Verify that the output of the command reports success. The current user is now authorized to use the CLI.

<a name="uas-uai-init-cli-debug"></a>
#### 5.1.4 CLI Troubleshooting

If initialization or authorization fails in one of the above steps, there are several common causes:

* DNS failure looking up `api-gw-service-nmn.local` may be preventing the CLI from reaching the API Gateway and Keycloak for authorization.
* Network connectivity issues with the NMN may be preventing the CLI from reaching the API Gateway and Keycloak for authorization.
* Certificate mismatch or trust issues may be preventing a secure connection to the API Gateway.
* Istio failures may be preventing traffic from reaching Keycloak.
* Keycloak may not yet be set up to authorize the current user.

While resolving these issues is beyond the scope of this section, there may be clues to what is failing by adding `-vvvvv` to the `cray auth...` or `cray init ...` commands.

<a name="uas-uai-validate"></a>
### 5.2 Validate UAS and UAI Functionality

The following procedures run on separate nodes of the system. They are, therefore, separated into separate sub-sections.

<a name="uas-uai-validate-install"></a>
#### 5.2.1 Validate the Basic UAS Installation

This section requires commands to be run on the LiveCD node, and the user must be initialized and authorized for the CLI as described above.

1. Basic UAS installation is validated using the following:
   1. 
      ```bash
      pit# cray uas mgr-info list
      ```

      Expected output looks similar to the following:
      ```
      service_name = "cray-uas-mgr"
      version = "1.11.5"
      ```
      
      In this example output, it shows that UAS is installed and running the `1.11.5` version.
   1.
      ```bash
      pit# cray uas list
      ```
      
      Expected output looks similar to the following:
      ```
      results = []
      ```

     This example output shows that there are no currently running UAIs. It is possible, if someone else has been using the UAS, that there could be UAIs in the list. That is acceptable too from a validation standpoint.
1. Verify that the pre-made UAI images are registered with UAS
   ```bash
   pit# cray uas images list
   ```
   
   Expected output looks similar to the following:
   ```
   default_image = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
   image_list = [ "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest",]
   ```

   This example output shows that the pre-made end-user UAI image (`cray/cray-uai-sles15sp1:latest`) is registered with UAS. This does not necessarily mean this image is installed in the container image registry, but it is configured for use. If other UAI images have been created and registered, they may also show up here, which is acceptable.

<a name="uas-uai-validate-create"></a>
#### 5.2.2 Validate UAI Creation

   > **`IMPORTANT:`** If you are upgrading CSM and your site does not use UAIs, skip UAS and UAI validation.
   > If you do use UAIs, there are products that configure UAS like Cray Analytics and Cray Programming
   > Environment. These must be working correctly with UAIs and should be validated and corrected (the
   > procedures for this are beyond the scope of this document) prior to validating UAS and UAI.  Failures
   > in UAI creation that result from incorrect or incomplete installation of these products will generally
   > take the form of UAIs stuck in 'waiting' state trying to set up volume mounts.  See the
   > [UAI Troubleshooting](#uas-uai-validate-debug) section for more information.

This procedure must run on a master or worker node (and not `ncn-w001`) on the system (or from an external host, but the procedure for that is not covered here). It requires that the CLI be initialized and authorized as the user.

The examples in this procedure are run on `ncn-w003`.

1. Verify that a UAI can be created:
   ```bash
   ncn-w003# cray uas create --publickey ~/.ssh/id_rsa.pub
   ```
   
   Expected output looks similar to the following:
   ```
   uai_connect_string = "ssh vers@10.16.234.10"
   uai_host = "ncn-w001"
   uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
   uai_ip = "10.16.234.10"
   uai_msg = ""
   uai_name = "uai-vers-a00fb46b"
   uai_status = "Pending"
   username = "vers"

   [uai_portmap]
   ```

   This has created the UAI and the UAI is currently in the process of initializing and running.  
2. Set `UAINAME` to the value of the `uai_name` field in the previous command output (`uai-vers-a00fb46b` in our example):
   ```bash
   ncn-w003# export UAINAME=uai-vers-a00fb46b
   ```
3. Check the current status of the UAI:
   ```bash
   ncn-w003# cray uas list
   ```
   
   Expected output looks similar to the following:
   ```
   [[results]]
   uai_age = "0m"
   uai_connect_string = "ssh vers@10.16.234.10"
   uai_host = "ncn-w001"
   uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
   uai_ip = "10.16.234.10"
   uai_msg = ""
   uai_name = "uai-vers-a00fb46b"
   uai_status = "Running: Ready"
   username = "vers"
   ```

   If the `uai_status` field is `Running: Ready`, proceed to the next step. Otherwise, wait and repeat this command until that is the case. It normally should not take more than a minute or two.
4. The UAI is ready for use. Log into it with the command in the `uai_connect_string` field in the previous command output:
   ```bash
   ncn-w003# ssh vers@10.16.234.10
   vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> 
   ```
5. Run a command on the UAI:
   ```bash
   vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> ps -afe
   ```
   
   Expected output looks similar to the following:
   ```
   UID          PID    PPID  C STIME TTY          TIME CMD
   root           1       0  0 18:51 ?        00:00:00 /bin/bash /usr/bin/uai-ssh.sh
   munge         36       1  0 18:51 ?        00:00:00 /usr/sbin/munged
   root          54       1  0 18:51 ?        00:00:00 su vers -c /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
   vers          55      54  0 18:51 ?        00:00:00 /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
   vers          62      55  0 18:51 ?        00:00:00 sshd: vers [priv]
   vers          67      62  0 18:51 ?        00:00:00 sshd: vers@pts/0
   vers          68      67  0 18:51 pts/0    00:00:00 -bash
   vers         120      68  0 18:52 pts/0    00:00:00 ps -afe
   ```
6. Log out from the UAI   
   ```bash
   vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> exit
   ncn-w003# 
   ```
7. Clean up the UAI.
   ```bash
   ncn-w003# cray uas delete --uai-list $UAINAME
   ```
   
   Expected output looks similar to the following:
   ```
   results = [ "Successfully deleted uai-vers-a00fb46b",]
   ```

If the commands ran with similar results, then the basic functionality of the UAS and UAI is working.

<a name="uas-uai-validate-debug"></a>
#### 5.2.3 UAS/UAI Troubleshooting

The following subsections include common failure modes seen with UAS / UAI operations and how to resolve them.

<a name="uas-uai-validate-debug-auth"></a>
##### 5.2.3.1 Authorization Issues

An error will be returned when running CLI commands if the user is not logged in as a valid Keycloak user or is accidentally using the `CRAY_CREDENTIALS` environment variable. This variable is set regardless of the user credentials being used.

For example: 
```bash
ncn# cray uas list
```

The symptom of this problem is output similar to the following:
```
Usage: cray uas list [OPTIONS]
Try 'cray uas list --help' for help.

Error: Bad Request: Token not valid for UAS. Attributes missing: ['gidNumber', 'loginShell', 'homeDirectory', 'uidNumber', 'name']
```

Fix this by logging in as a real user (someone with actual Linux credentials) and making sure that `CRAY_CREDENTIALS` is unset.

<a name="uas-uai-validate-debug-keycloak"></a>
##### 5.2.3.2 UAS Cannot Access Keycloak

When running CLI commands, a Keycloak error may be returned.

For example: 
```bash
ncn# cray uas list
```

The symptom of this problem is output similar to the following:
```
Usage: cray uas list [OPTIONS]
Try 'cray uas list --help' for help.

Error: Internal Server Error: An error was encountered while accessing Keycloak
```

If the wrong hostname was used to reach the API gateway, re-run the CLI initialization steps above and try again to check that. There may also be a problem with the Istio service mesh inside of the system. Troubleshooting this is beyond the scope of this section, but there may be useful information in the UAS pod logs in Kubernetes. There are generally two UAS pods, so the user may need to look at logs from both to find the specific failure. The logs tend to have a very large number of `GET` events listed as part of the liveness checking.  

The following shows an example of looking at UAS logs effectively (this example shows only one UAS manager, normally there would be two):

1. Determine the pod name of the uas-mgr pod
   ```bash
   ncn# kubectl get po -n services | grep "^cray-uas-mgr" | grep -v etcd
   ```

   Expected output looks similar to:
   ```
   cray-uas-mgr-6bbd584ccb-zg8vx                                    2/2     Running            0          12d
   ```
2. Set PODNAME to the name of the manager pod whose logs are being viewed.
   ```bash
   ncn# export PODNAME=cray-uas-mgr-6bbd584ccb-zg8vx
   ```
3. View its last 25 log entries of the cray-uas-mgr container in that pod, excluding `GET` events:
   ```bash
   ncn# kubectl logs -n services $PODNAME cray-uas-mgr | grep -v 'GET ' | tail -25
   ```
   
   Example output:
   ```
   2021-02-08 15:32:41,211 - uas_mgr - INFO - getting deployment uai-vers-87a0ff6e in namespace user
   2021-02-08 15:32:41,225 - uas_mgr - INFO - creating deployment uai-vers-87a0ff6e in namespace user
   2021-02-08 15:32:41,241 - uas_mgr - INFO - creating the UAI service uai-vers-87a0ff6e-ssh
   2021-02-08 15:32:41,241 - uas_mgr - INFO - getting service uai-vers-87a0ff6e-ssh in namespace user
   2021-02-08 15:32:41,252 - uas_mgr - INFO - creating service uai-vers-87a0ff6e-ssh in namespace user
   2021-02-08 15:32:41,267 - uas_mgr - INFO - getting pod info uai-vers-87a0ff6e
   2021-02-08 15:32:41,360 - uas_mgr - INFO - No start time provided from pod
   2021-02-08 15:32:41,361 - uas_mgr - INFO - getting service info for uai-vers-87a0ff6e-ssh in namespace user
   127.0.0.1 - - [08/Feb/2021 15:32:41] "POST /v1/uas?imagename=registry.local%2Fcray%2Fno-image-registered%3Alatest HTTP/1.1" 200 -
   2021-02-08 15:32:54,455 - uas_auth - INFO - UasAuth lookup complete for user vers
   2021-02-08 15:32:54,455 - uas_mgr - INFO - UAS request for: vers
   2021-02-08 15:32:54,455 - uas_mgr - INFO - listing deployments matching: host None, labels uas=managed,user=vers
   2021-02-08 15:32:54,484 - uas_mgr - INFO - getting pod info uai-vers-87a0ff6e
   2021-02-08 15:32:54,596 - uas_mgr - INFO - getting service info for uai-vers-87a0ff6e-ssh in namespace user
   2021-02-08 15:40:25,053 - uas_auth - INFO - UasAuth lookup complete for user vers
   2021-02-08 15:40:25,054 - uas_mgr - INFO - UAS request for: vers
   2021-02-08 15:40:25,054 - uas_mgr - INFO - listing deployments matching: host None, labels uas=managed,user=vers
   2021-02-08 15:40:25,085 - uas_mgr - INFO - getting pod info uai-vers-87a0ff6e
   2021-02-08 15:40:25,212 - uas_mgr - INFO - getting service info for uai-vers-87a0ff6e-ssh in namespace user
   2021-02-08 15:40:51,210 - uas_auth - INFO - UasAuth lookup complete for user vers
   2021-02-08 15:40:51,210 - uas_mgr - INFO - UAS request for: vers
   2021-02-08 15:40:51,210 - uas_mgr - INFO - listing deployments matching: host None, labels uas=managed,user=vers
   2021-02-08 15:40:51,261 - uas_mgr - INFO - deleting service uai-vers-87a0ff6e-ssh in namespace user
   2021-02-08 15:40:51,291 - uas_mgr - INFO - delete deployment uai-vers-87a0ff6e in namespace user
   127.0.0.1 - - [08/Feb/2021 15:40:51] "DELETE /v1/uas?uai_list=uai-vers-87a0ff6e HTTP/1.1" 200 -
   ```

<a name="uas-uai-validate-debug-registry"></a>
##### 5.2.3.3 UAI Images not in Registry

When listing or describing a UAI, an error in the `uai_msg` field may be returned. For example:
```bash
ncn# cray uas list
```

There may be something similar to the following output:
```
[[results]]
uai_age = "0m"
uai_connect_string = "ssh vers@10.103.13.172"
uai_host = "ncn-w001"
uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
uai_ip = "10.103.13.172"
uai_msg = "ErrImagePull"
uai_name = "uai-vers-87a0ff6e"
uai_status = "Waiting"
username = "vers"
```

This means the pre-made end-user UAI image is not in the local registry (or whatever registry it is being pulled from; see the `uai_img` value for details). To correct this, locate and push/import the image to the registry.

<a name="uas-uai-validate-debug-container"></a>
##### 5.2.3.4 Missing Volumes and other Container Startup Issues

Various packages install volumes in the UAS configuration. All of those volumes must also have the underlying resources available, sometimes on the host node where the UAI is running sometimes from with Kubernetes. If a UAI gets stuck with a `ContainerCreating` `uai_msg` field for an extended time, this is a likely cause. UAIs run in the `user` Kubernetes namespace, and are pods that can be examined using `kubectl describe`.

1. Locate the pod.

   ```bash
   ncn# kubectl get po -n user | grep <uai-name>
   ```

2. Investigate the problem using the pod name from the previous step.

   ```bash
   ncn# kubectl describe -n user <pod-name>
   ```

   If volumes are missing they will show up in the `Events:` section of the output. Other problems may show up there as well. The names of the missing volumes or other issues should indicate what needs to be fixed to make the UAI run.
