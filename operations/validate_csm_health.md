# Validate CSM Health

Anytime after the installation of the CSM services, the health of the management nodes and all CSM services can be validated.

The following are examples of when to run health checks:

- After CSM `install.sh` completes
- Before and after NCN reboots
- After the system is brought back up
- Any time there is unexpected behavior observed
- In order to provide relevant information to create support tickets

The areas should be tested in the order they are listed on this page. Errors in an earlier check may cause errors in later checks because of dependencies.

<<<<<<< HEAD
- [1. Platform health checks](#platform-health-checks)
  - [1.1 `ncnHealthChecks`](#pet-ncnhealthchecks)
  - [1.2 `ncnPostgresHealthChecks`](#pet-ncnpostgreshealthchecks)
  - [1.3 BGP peering status and reset](#pet-bgp)
    - [1.3.1 Mellanox switch](#pet-bgp-mellanox)
    - [1.3.2 Aruba switch](#pet-bgp-aruba)
  - [1.4 Verify that KEA has active DHCP leases](#net-kea)
  - [1.5 Verify the ability to resolve external DNS](#net-extdns)
  - [1.6 Verify that the Spire agent is running on Kubernetes NCNs](#net-spire)
  - [1.7 Verify that the Vault cluster is healthy](#net-vault)
  - [1.8 Automated Goss testing](#automated-goss-testing)
    - [1.8.1 Known test issues](#autogoss-issues)
  - [1.9 Check of system management monitoring tools](#check-of-system-management-monitoring-tools)
- [2. Hardware Management Services health checks](#hms-health-checks)
  - [2.1 HMS test execution](#hms-test-execution)
  - [2.2 Hardware State Manager discovery validation](#hms-smd-discovery-validation)
    - [2.2.1 Interpreting HSM discovery results](#hms-smd-discovery-validation-interpreting-results)
    - [2.2.2 Known issues with HSM discovery validation](#hms-smd-discovery-validation-known-issues)
- [3 Software Management Services health checks](#sms-health-checks)
  - [3.1 SMS test execution](#sms-checks)
  - [3.2 Interpreting `cmsdev` results](#cmsdev-results)
  - [3.3 Known issues with SMS tests](#sms-checks-known-issues)
- [4. Booting CSM `barebones` image](#booting-csm-barebones-image)
  - [4.1 Locate CSM `barebones` image in IMS](#locate-csm-barebones-image-in-ims)
  - [4.2 Create a BOS session template for the CSM `barebones` image](#csm-bos-session-template)
  - [4.3 Find an available compute node](#csm-node)
  - [4.4 Reboot the node using a BOS session template](#csm-reboot)
  - [4.5 Connect to the node's console and watch the boot](#csm-watch-boot)
- [5. UAS / UAI tests](#uas-uai-tests)
  - [5.1 Validate the basic UAS installation](#uas-uai-validate-install)
  - [5.2 Validate UAI creation](#uas-uai-validate-create)
  - [5.3 UAS/UAI troubleshooting](#uas-uai-validate-debug)
    - [5.3.1 Authorization issues](#uas-uai-validate-debug-auth)
    - [5.3.2 UAS cannot access Keycloak](#uas-uai-validate-debug-keycloak)
    - [5.3.3 UAI images not in registry](#uas-uai-validate-debug-registry)
    - [5.3.4 Missing volumes and other container startup issues](#uas-uai-validate-debug-container)

<a name="platform-health-checks"></a>

## 1. Platform health checks

Scripts do not verify results. Script output includes analysis needed to determine pass/fail for each check. All health checks are expected to pass.

Health check scripts can be run:

- After CSM `install.sh` has been run (not before)
- Before and after one of the NCNs reboots
- After the system or a single node goes down unexpectedly
- After the system is gracefully shut down and brought up
- Any time there is unexpected behavior on the system to get a baseline of data for CSM services and components
- In order to provide relevant information to support tickets that are being opened after CSM `install.sh` has been run

Available platform health checks:

1. [`ncnHealthChecks`](#pet-ncnhealthchecks)
1. [`ncnPostgresHealthChecks`](#pet-ncnpostgreshealthchecks)
1. [BGP peering status and reset](#pet-bgp)
    1. [Mellanox switch](#pet-bgp-mellanox)
    1. [Aruba switch](#pet-bgp-aruba)
1. [KEA / DHCP](#net-kea)
1. [External DNS](#net-extdns)
1. [Spire agent](#net-spire)
1. [Vault cluster](#net-vault)
1. [Automated Goss testing](#automated-goss-testing)
    1. [Known test issues](#autogoss-issues)
1. [System management monitoring tools](#check-of-system-management-monitoring-tools)

<a name="pet-ncnhealthchecks"></a>

### 1.1 `ncnHealthChecks`

NCN health check scripts can be found and run on any worker or master node (**not on the PIT node**), from any directory.

```bash
ncn-mw# /opt/cray/platform-utils/ncnHealthChecks.sh
```

The `ncnHealthChecks` script reports the following health information:

- Kubernetes status for master and worker NCNs
- Ceph health status
- Health of Etcd clusters
- Number of pods on each worker node for each Etcd cluster
- Alarms set for any of the Etcd clusters
- Health of Etcd cluster's database
- List of automated Etcd backups for the Boot Orchestration Service (BOS), Boot Script Service (BSS), Compute Rolling Upgrade Service (CRUS), and Domain Name Service (DNS), and Firmware Action Service (FAS) clusters
- NCN node uptimes
- NCN master and worker node resource consumption
- NCN node xnames and `metal.no-wipe` status
- NCN worker node pod counts
- Pods yet to reach the running state

Execute the `ncnHealthChecks` script and analyze the output of each individual check.

**IMPORTANT:** When the PIT node is booted the NCN node `metal.no-wipe` status is not available and is correctly reported as 'unavailable'. Once `ncn-m001` has been booted,
the NCN `metal.no-wipe` status is expected to be reported as `metal.no-wipe=1`.

**IMPORTANT:** Only when `ncn-m001` has been booted, if the output of the `ncnHealthChecks.sh` script shows that there are nodes that do not have the `metal.no-wipe=1` status, then do the following:

```bash
ncn-mw# csi handoff bss-update-param --set metal.no-wipe=1 --limit <SERVER_XNAME>
```

**IMPORTANT:** If the output of pod statuses indicates that there are pods in the `Evicted` state, it may be due to the `/root` file system being filled up on the Kubernetes
node in question. Kubernetes will begin evicting pods once the root file system space is at 85% until it is back under 80%. This may commonly happen on `ncn-m001` as it is a
location that install and documentation files may be downloaded to. It may be necessary to clean-up space in the `/root` directory if this is the cause of pod evictions. The
following commands can be used to determine if analysis of files under `/root` is needed to free-up space.
=======
## Topics

- [0. Cray command line interface](#0-cray-command-line-interface)
- [1. Platform health checks](#1-platform-health-checks)
  - [1.1 NCN health checks](#11-ncn-health-checks)
    - [1.1.1 Known issues with NCN health checks](#111-known-issues-with-ncn-health-checks)
  - [1.2 NCN resource checks (optional)](#12-ncn-resource-checks-optional)
    - [1.2.1 Known issues with NCN resource checks](#121-known-issues-with-ncn-resource-checks)
  - [1.3 Check of system management monitoring tools](#13-check-of-system-management-monitoring-tools)
- [2. Hardware Management Services health checks](#2-hardware-management-services-health-checks)
  - [2.1 HMS CT test execution](#21-hms-ct-test-execution)
  - [2.2 Hardware State Manager discovery validation](#22-hardware-state-manager-discovery-validation)
    - [2.2.1 Interpreting HSM discovery results](#221-interpreting-hsm-discovery-results)
    - [2.2.2 Known issues with HSM discovery validation](#222-known-issues-with-hsm-discovery-validation)
- [3. Software Management Services health checks](#3-software-management-services-health-checks)
  - [3.1 SMS test execution](#31-sms-test-execution)
  - [3.2 Interpreting `cmsdev` results](#32-interpreting-cmsdev-results)
  - [3.3 Known issues with SMS tests](#33-known-issues-with-sms-tests)
- [4. Gateway health and SSH access checks](#4-gateway-health-and-ssh-access-checks)
  - [4.1 Gateway health tests](#41-gateway-health-tests)
    - [4.1.1 Gateway health tests overview](#411-gateway-health-tests-overview)
    - [4.1.2 Gateway health tests on an NCN](#412-gateway-health-tests-on-an-ncn)
    - [4.1.3 Gateway health tests from outside the system](#413-gateway-health-tests-from-outside-the-system)
  - [4.2 Internal SSH access test execution](#42-internal-ssh-access-test-execution)
  - [4.3 External SSH access test execution](#43-external-ssh-access-test-execution)
- [5. Booting CSM `barebones` image](#5-booting-csm-barebones-image)
  - [5.1 Run the test script](#51-run-the-test-script)
- [6. UAS/UAI tests](#6-uasuai-tests)
  - [6.1 Validate the basic UAS installation](#61-validate-the-basic-uas-installation)
  - [6.2 Validate UAI creation](#62-validate-uai-creation)
  - [6.3 Test UAI gateway health](#63-test-uai-gateway-health)
  - [6.4 UAS/UAI troubleshooting](#64-uasuai-troubleshooting)
    - [6.4.1 Authorization issues](#641-authorization-issues)
    - [6.4.2 UAS cannot access Keycloak](#642-uas-cannot-access-keycloak)
    - [6.4.3 UAI images not in registry](#643-uai-images-not-in-registry)
    - [6.4.4 Missing volumes and other container startup issues](#644-missing-volumes-and-other-container-startup-issues)

<a name="cray-command-line-interface"></a>

## 0. Cray command line interface

The first time these checks are performed during a CSM install, the Cray Command Line Interface (CLI) has not yet been configured.
Some of the health check tests cannot be run without the Cray CLI being configured. Tests with this dependency are noted in their
descriptions below. These tests may be skipped but **this is not recommended**.

The Cray CLI must be configured on all NCNs and the PIT node. The following procedures explain how to do this:

1. [Configure Keycloak Account](../install/configure_administrative_access.md#configure_keycloak_account)
1. [Configure the Cray Command Line Interface (CLI)](../install/configure_administrative_access.md#configure_cray_cli)
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

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

**Note**: The `cray-crus-` pod is expected to be in the `Init` state until Slurm and `munge`
are installed. In particular, this will be the case if executing this as part of the validation after completing the [Install CSM Services](../install/install_csm_services.md).
If in doubt, validate the CRUS service using the [CMS Validation Tool](#sms-health-checks). If the CRUS check passes using that tool, do not worry about the `cray-crus-` pod state.

Additionally, `hms-discovery` and `cray-dns-unbound-manager` `cronjob` pods may be in a `NotReady` state. This is expected as these pods are periodically started and should
eventually transition to the `Completed` state.

**IMPORTANT:** If `ncn-s001` is down when running the `ncnHealthChecks` script, status from the `ceph -s` command will be unavailable. In this case, the `ceph -s` command can
be executed on any available master or storage node to determine the status of the Ceph cluster.

<a name="pet-ncnpostgreshealthchecks"></a>

### 1.2 `ncnPostgresHealthChecks`

Postgres health check scripts can be found and run on any worker or master node (**not on the PIT node**), from any directory.
The `ncnPostgresHealthChecks` script reports the following Postgres health information:

- The status of each `postgresql` resource
- The number of cluster members
- The node which is the Leader
- The state of the each cluster member
- Replication lag for any cluster member
- Kubernetes `postgres` pod status

Execute `ncnPostgresHealthChecks` script and analyze the output of each individual check.

```bash
ncn# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
```

1. Check the `STATUS` of the `postgresql` resources which are managed by the operator:

    ```text
    NAMESPACE   NAME                         TEAM                VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE   STATUS
    services    cray-sls-postgres            cray-sls            11        3      1Gi                                     12d   Running
    ```

    If any `postgresql` resources remains in a `STATUS` other than `Running` (such as `SyncFailed`), refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#syncfailed).

1. For a particular Postgres cluster, the expected output is similar to the following:

    ```text
    --- patronictl, version 1.6.5, list for services leader pod cray-sls-postgres-0 ---
    + Cluster: cray-sls-postgres (6938772644984361037) ---+----+-----------+
    |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
    +---------------------+------------+--------+---------+----+-----------+
    | cray-sls-postgres-0 | 10.47.0.35 | Leader | running |  1 |           |
    | cray-sls-postgres-1 | 10.36.0.33 |        | running |  1 |         0 |
    | cray-sls-postgres-2 | 10.44.0.42 |        | running |  1 |         0 |
    +---------------------+------------+--------+---------+----+-----------+
    ```

    The points below will cover the data in the table above for `Member`, `Role`, `State`, and `Lag in MB` columns.

    For each Postgres cluster:

    1. Verify that there are three cluster members (with the exception of `sma-postgres-cluster`, where there should be only two cluster members).

       If the number of cluster members is not correct, refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#missing).

    1. Verify that there is one cluster member with the `Leader` `Role`.

       If there is no `Leader`, refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#leader).

    1. Verify that the `State` of each cluster member is `running`.

       If any cluster members are found not to be in `running` state (such as `start failed`), refer to
       [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#diskfull).

    1. Verify there is no large or growing lag.

       If any cluster members are found to have lag or lag is `unknown`, refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#lag).

    **If all the above four checks indicate that Postgres clusters are healthy, then the log output for the `postgres` pods can be ignored.** If possible health issues exist,
    then re-check the health by re-running the `ncnPostgresHealthChecks` script after waiting for 15 minutes. If health issues persist, then review the log output and consult
    [Troubleshoot Postgres Database](kubernetes/Troubleshoot_Postgres_Database.md). During NCN reboots, temporary errors related to re-election are common but should resolve
    upon the re-check.

1. Check that all Kubernetes Postgres pods have a `STATUS` of `Running`.

    ```bash
    ncn# kubectl get pods -A -o wide -l application=spilo
    NAMESPACE           NAME                                                              READY   STATUS             RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
    services            cray-sls-postgres-0                                               3/3     Running            3          6d      10.38.0.102   ncn-w002   <none>           <none>
    services            cray-sls-postgres-1                                               3/3     Running            3          5d20h   10.42.0.89    ncn-w001   <none>           <none>
    services            cray-sls-postgres-2                                               3/3     Running            0          5d20h   10.36.0.31    ncn-w003   <none>           <none>
    ```

    If any Postgres pods have a `STATUS` other then `Running`, gather more information from the pod and refer to [Troubleshoot Postgres Database](./kubernetes/Troubleshoot_Postgres_Database.md#missing).

    ```bash
    ncn# kubectl describe pod <pod name> -n <pod namespace>
    ncn# kubectl logs <pod name> -n <pod namespace> -c <pod container name>
    ```

<a name="pet-bgp"></a>

### 1.3 BGP peering status and reset

Verify that Border Gateway Protocol (BGP) peering sessions are established for each worker node on the system.

Check the Border Gateway Protocol (BGP) status on the Aruba or Mellanox switches.
Verify that all sessions are in an `Established` state. If the state of any
session in the table is `Idle`, reset the BGP sessions.

On an NCN, determine the IP addresses of switches:

```bash
ncn# kubectl get cm config -n metallb-system -o yaml | head -12
```

Expected output looks similar to the following:

```yaml
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

Using the first `peer-address` (`10.252.0.2` here), log in using `ssh` as the administrator to the switch and note in the returned output if Mellanox or Aruba is indicated.

```bash
ncn-m001# ssh admin@10.252.0.2
```

- On a Mellanox switch, `Mellanox Onyx Switch Management` or `Mellanox Switch` may be displayed after logging in to the switch with `ssh`. In this case, proceed to the [Mellanox steps](#pet-bgp-mellanox).
- On an Aruba switch, `Please register your products now at: https://asp.arubanetworks.com` may be displayed after logging in to the switch with `ssh`. In this case, proceed to the [Aruba steps](#pet-bgp-aruba).

<a name="pet-bgp-mellanox"></a>

#### 1.3.1 Mellanox switch

1. Enable:

   ```console
   sw-spine-001# enable
   ```

1. Verify BGP is enabled:

   ```console
   sw-spine-001# show protocols | include bgp
   ```

   Expected output looks similar to the following:

   ```text
   bgp:                    enabled
   ```

1. Check peering status:

   ```console
   sw-spine-001# show ip bgp summary
   ```

   Expected output looks similar to the following:

   ```text
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

1. If one or more BGP session is reported in an `Idle` state, reset BGP to re-establish the sessions:

   ```console
   sw-spine-001# clear ip bgp all
   ```

   - It may take several minutes for all sessions to become `Established`. Wait a minute or so, and then verify that all sessions now are all reported as `Established`. If some
     sessions remain in an `Idle` state, re-run the `clear ip bgp all` command and check again.
   - If after several tries one or more BGP session remains `Idle`, see [Check BGP Status and Reset Sessions](network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

1. Repeat the above Mellanox procedure using the second `peer-address` (`10.252.0.3` here).

<a name="pet-bgp-aruba"></a>

#### 1.3.2 Aruba switch

On an Aruba switch, the prompt may include `sw-spine` or `sw-agg`.

1. Check BGP peering status.

   ```console
   sw-agg01# show bgp ipv4 unicast summary
   ```

   Expected output looks similar to the following:

   ```text
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

1. If one or more BGP session is reported in a `Idle` state, reset BGP to re-establish the sessions:

   ```console
   sw-agg01# clear bgp *
   ```

   - It may take several minutes for all sessions to become `Established`. Wait a minute or so, and then
   verify that all sessions now are reported as `Established`. If some sessions remain in an `Idle` state,
   re-run the `clear bgp *` command and check again.
   - If after several tries one or more BGP session remains `Idle`, see [Check BGP Status and Reset Sessions](network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md)

1. Repeat the above **Aruba** procedure using the second `peer-address` (`10.252.0.5` in this example).

<a name="net-kea"></a>

### 1.4 Verify that KEA has active DHCP leases

Verify that KEA has active DHCP leases. After an fresh install of CSM, it is important to verify that KEA is currently handing out DHCP leases on the system. The following
commands can be run on any of the master or worker nodes.

1. Get an API token:

   ```bash
   ncn# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                 -d client_id=admin-client \
                 -d client_secret=`kubectl get secrets admin-client-auth \
                 -o jsonpath='{.data.client-secret}' | base64 -d` \
                          https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

1. Retrieve all the leases currently in KEA:

   ```bash
   ncn# curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
            -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
   ```

   If there is a non-zero amount of DHCP leases for air-cooled hardware returned, then that is a good indication that KEA is working.

<a name="net-extdns"></a>

### 1.5 Verify the ability to resolve external DNS

If `unbound` is configured to resolve outside hostnames, then the following check should be performed. If this has not been done, then this check may be skipped.

Run the following on one of the master or worker nodes (not the PIT node):

```bash
ncn# nslookup cray.com ; echo "Exit code is $?"
```

Expected output looks similar to the following:

```text
Server:         10.92.100.225
Address:        10.92.100.225#53

Non-authoritative answer:
Name:   cray.com
Address: 52.36.131.229

Exit code is 0
```

Verify that the command has exit code zero, reports no errors, and resolves the address.

<a name="net-spire"></a>

### 1.6 Verify that the Spire agent is running on Kubernetes NCNs

Execute the following command on all Kubernetes NCNs (all worker nodes and master nodes), excluding the PIT node:

```bash
ncn# goss -g /opt/cray/tests/install/ncn/tests/goss-spire-agent-service-running.yaml validate
```

Known failures and how to recover:

- K8S Test: Verify `spire-agent` is enabled and running

  - The `spire-agent` service may fail to start on Kubernetes NCNs (all worker and master nodes). In this case, it may log errors
    (using `journalctl`) similar to `join token does not exist or has already been used`, or the last log entries may contain multiple
    instances of `systemd[1]: spire-agent.service: Start request repeated too quickly.`. Deleting the `request-ncn-join-token` `daemonset` pod
    running on the node may clear the issue. Even though the `spire-agent` `systemctl` service on the Kubernetes node should eventually
    restart cleanly, the user may have to log in to the impacted nodes and restart the service. The following recovery procedure can
    be run from any Kubernetes node in the cluster.

     1. Set `NODE` to the NCN which is experiencing the issue. In this example, `ncn-w002`.

        > This command will not work on the PIT node.

        ```bash
          ncn# export NODE=ncn-w002
          ```

     1. Define the following function

        ```bash
        ncn# function renewncnjoin() { for pod in $(kubectl get pods -n spire |grep request-ncn-join-token | awk '{print $1}'); do
                if kubectl describe -n spire pods $pod | grep -q "Node:.*$1"; then echo "Restarting $pod running on $1"; kubectl delete -n spire pod "$pod"; fi
             done }
        ```

     1. Run the function as follows:

        ```bash
        ncn# renewncnjoin $NODE
        ```

  - The `spire-agent` service may also fail if an NCN was powered off for too long and its tokens expired. If this happens, delete `/root/spire/agent_svid.der`,
    `/root/spire/bundle.der`, and `/root/spire/data/svid.key` off the NCN before deleting the `request-ncn-join-token` `daemonset` pod.

<a name="net-vault"></a>

### 1.7 Verify that the Vault cluster is healthy

Execute the following commands on `ncn-m002`:

```bash
ncn-m002# goss -g /opt/cray/tests/install/ncn/tests/goss-k8s-vault-cluster-health.yaml validate
```

<<<<<<< HEAD
Check the output to verify no failures are reported:
=======
- Clock skew test failures

   It can take up to 15 minutes, and sometimes longer, for NCN clocks to synchronize after an upgrade or when a system is brought back up. If a clock skew test
   fails, wait 15 minutes and try again. To check status, run the following command, preferably on `ncn-m001`:

   ```bash
   ncn-m001# chronyc sources -v
   ```

   ```text
   210 Number of sources = 9

     .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
    / .- Source state '*' = current synced, '+' = combined , '-' = not combined,
   | /   '?' = unreachable, 'x' = time may be in error, '~' = time too variable.
   ||                                                 .- xxxx [ yyyy ] +/- zzzz
   ||      Reachability register (octal) -.           |  xxxx = adjusted offset,
   ||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
   ||                                \     |          |  zzzz = estimated error.
   ||                                 |    |           \
   MS Name/IP address         Stratum Poll Reach LastRx Last sample
   ===============================================================================
   ^* ntp.hpecorp.net               2  10   377   650   -421us[ -571us] +/-   30ms
   =? ncn-m002.nmn                 10   4   377   213    +82us[  +82us] +/-  367us
   =- ncn-m003.nmn                  3   1   377     1  -2033us[-2033us] +/-   28ms
   =- ncn-s001.nmn                  6   5   377    20    +53us[  +53us] +/-  193us
   =- ncn-s002.nmn                  5   5   377    25    +29us[  +29us] +/-  275us
   =- ncn-s003.nmn                  6   6   377    27    +47us[  +47us] +/-  237us
   =- ncn-w001.nmn                  5   9   377  234m  +8305us[  +10ms] +/-   38ms
   =- ncn-w002.nmn                  3   5   377     8  -1910us[-1910us] +/-   27ms
   =- ncn-w003.nmn                  3   8   377   74m  -1122us[-1002us] +/-   31ms
   ```

<a name="pet-optional-ncnhealthchecks-resources"></a>
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

```text
Count: 2, Failed: 0, Skipped: 0
```

<a name="automated-goss-testing"></a>

### 1.8 Automated Goss testing

There are multiple [Goss](https://github.com/aelsabbahy/goss) test suites available that cover a variety of sub-systems.

Run the NCN health checks against the three different types of nodes with the following commands:

**IMPORTANT:** These tests should only be run while booted into the PIT node. Do not run these as part of upgrade testing. This includes the Kubernetes check in the next block.

**IMPORTANT:** It is possible that the first pass of running these tests may fail due to `cloud-init` not being completed on the storage nodes. In this case please wait 5 minutes and re-run the tests.

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

#### 1.8.1 Known test issues

- These tests can only reliably be executed from the PIT node.
- Kubernetes Test: `Kubernetes Query BSS Cloud-init for ca-certs`
  - May fail immediately after platform install. Should pass after the `TrustedCerts` operator has updated BSS with CA certificates.
- Kubernetes Test: `Kubernetes Velero No Failed Backups`
  - Because of a [known issue  with Velero](https://github.com/vmware-tanzu/velero/issues/1980), a backup may be attempted immediately
    upon the deployment of a backup schedule (for example, Vault). It may be necessary to delete backups from a Kubernetes node to
    clear this situation. For example:

     1. Find the failed backup.

        ```bash
        ncn/pit# kubectl get backups -A -o json | jq -e '.items[] | select(.status.phase == "PartiallyFailed") | .metadata.name'
        ```

     1. Delete the backup.

        > In the following command, replace `<backup>` with a backup returned in the previous step.
        >
        > This command will not work on the PIT node.

        ```bash
        ncn# velero backup delete <backup> --confirm
        ```

<a name="check-of-system-management-monitoring-tools"></a>

### 1.9 Check of system management monitoring tools

If all designated prerequisites are met, the availability of system management health services may be validated by accessing the URLs listed in
[Access System Management Health Services](system_management_health/Access_System_Management_Health_Services.md).
It is very important to check the `Prerequisites` section for this topic.

If one or more of the the URLs listed in the procedure are inaccessible, it does not necessarily mean that system is not healthy. It may simply mean that not all of the
prerequisites have been met to allow access to the system management health tools via URL.

Information to assist with troubleshooting some of the components mentioned in the prerequisites can be accessed here:

- [Troubleshoot CAN Issues](network/customer_access_network/Troubleshoot_CAN_Issues.md)
- [Troubleshoot DNS Configuration Issues](network/external_dns/Troubleshoot_DNS_Configuration_Issues.md)
- [Check BGP Status and Reset Sessions](network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md)
- [Troubleshoot BGP not Accepting Routes from MetalLB](network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)
- [Troubleshoot Services without an Allocated IP Address](network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
- [Troubleshoot Prometheus Alerts](system_management_health/Troubleshoot_Prometheus_Alerts.md)

<a name="hms-health-checks"></a>

## 2. Hardware Management Services health checks

Execute the HMS smoke and functional tests after the CSM install to confirm that the Hardware Management Services are running and operational.

Note: Do not run HMS tests concurrently on multiple nodes. They may interfere with one another and cause false failures.

1. [HMS test execution](#hms-test-execution)
1. [Hardware State Manager discovery validation](#hms-smd-discovery-validation)
    1. [Interpreting HSM discovery results](#hms-smd-discovery-validation-interpreting-results)
    1. [Known issues with HSM discovery validation](#hms-smd-discovery-validation-known-issues)

<a name="hms-test-execution"></a>

### 2.1 HMS test execution

These tests should be executed as root on any worker or master NCN (but **not** the PIT node).

Run the HMS smoke tests.

```bash
ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_smoke_tests_ncn-resources.sh
```

Examine the output. If one or more failures occur, investigate the cause of each failure.
See the [Interpreting HMS Health Check Results](../troubleshooting/interpreting_hms_health_check_results.md) documentation for more information.

If no failures occur, then run the HMS functional tests.

```bash
ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_functional_tests_ncn-resources.sh
```

Examine the output. If one or more failures occur, investigate the cause of each failure.
See the [Interpreting HMS Health Check Results](../troubleshooting/interpreting_hms_health_check_results.md) documentation for more information.

<a name="hms-smd-discovery-validation"></a>

### 2.2 Hardware State Manager discovery validation

> **NOTE**: The Cray CLI must be configured in order to complete this task. See [Configure the Cray Command Line Interface](configure_cray_cli.md) for details on how to do this.

By this point in the installation process, the Hardware State Manager (HSM) should
have done its discovery of the system.

The foundational information for this discovery is from the System Layout Service (SLS). Thus, a
comparison needs to be done to see that what is specified in SLS (focusing on
BMC components and Redfish endpoints) are present in HSM.

Execute the `hsm_discovery_verify.sh` script on a Kubernetes master or worker NCN:

```bash
ncn# /opt/cray/csm/scripts/hms_verification/hsm_discovery_verify.sh
```

The output will ideally appear as follows. If there are mismatches these will be displayed in the appropriate section of
the output. Refer to [2.2.1 Interpreting results](#hms-smd-discovery-validation-interpreting-results) and
[2.2.2 Known Issues](#hms-smd-discovery-validation-known-issues) below to troubleshoot any mismatched BMCs.

```text
Fetching SLS Components...

Fetching HSM Components...

Fetching HSM Redfish endpoints...

=============== BMCs in SLS not in HSM components ===============
ALL OK

=============== BMCs in SLS not in HSM Redfish Endpoints ===============
ALL OK
```

<a name="hms-smd-discovery-validation-interpreting-results"></a>

#### 2.2.1 Interpreting HSM discovery results

Both sections `BMCs in SLS not in HSM components` and `BMCs in SLS not in HSM Redfish Endpoints` have the same format for mismatches between SLS and HSM. Each row starts with
the component name (xname) of the BMC. If the BMC does not have an associated `MgmtSwitchConnector` in SLS, then `# No mgmt port association` will be displayed alongside the BMC xname.

> `MgmtSwitchConnector`s in SLS are used to represent the switch port on a leaf switch that is connected to the BMC of an air-cooled device.

```text
=============== BMCs in SLS not in HSM components ===============
x3000c0s1b0  # No mgmt port association
```

**For each** of the BMCs that show up in either of mismatch lists use the following notes to determine if the issue with the BMC can be safely ignored, or if there is a legitimate issue with the BMC.

- The node BMC of `ncn-m001` will not typically be present in HSM component data, as it is typically connected to the site network instead of the HMN network.
   > The following can be used to determine the friendly name of the Node that the `NodeBMC` controls:
   >
   > ```bash
   > ncn# cray sls search hardware list --parent <NODE_BMC_XNAME> --format json | \
   >   jq '.[] | { Xname: .Xname, Aliases: .ExtraProperties.Aliases }' -c
   > ```

   Example mismatch for the BMC of `ncn-m001`:

   ```text
   =============== BMCs in SLS not in HSM components ===============
   x3000c0s1b0  # No mgmt port association
   ```

- The node BMCs for HPE Apollo XL645D nodes may report as a mismatch depending on the state of the system when the `hsm_discovery_verify.sh` script is run. If the system is
  currently going through the process of installation, then this is an expected mismatch as the [Prepare Compute Nodes](../install/prepare_compute_nodes.md) procedure required
  to configure the BMC of the HPE Apollo 6500 XL645D node may not have been completed yet.

   > Refer to [Configure HPE Apollo 6500 XL645D Gen10 Plus Compute Nodes](../install/prepare_compute_nodes.md#configure-hpe-apollo-6500-x645d-gen10-plus-compute-nodes) for additional required configuration for this type of BMC.

   Example mismatch for the BMC of an HPE Apollo XL654D:

   ```text
   =============== BMCs in SLS not in HSM components ===============
   x3000c0s30b1

   =============== BMCs in SLS not in HSM Redfish Endpoints ===============
   x3000c0s30b1
   ```

- Chassis Management Controllers (CMC) may show up as not being present in HSM. CMCs for Intel node blades can be ignored. Gigabyte node blade CMCs not found in HSM is not
  normal and should be investigated. If a Gigabyte CMC is expected to not be connected to the HMN network, then it can be ignored.

   > CMCs have component names (xnames) in the form of `xXc0sSb999`, where `X` is the cabinet and `S` is the rack U of the compute node chassis.

   Example mismatch for a CMC an Intel node blade:

   ```text
   =============== BMCs in SLS not in HSM components ===============
   x3000c0s10b999  # No mgmt port association

   =============== BMCs in SLS not in HSM Redfish Endpoints ===============
   x3000c0s10b999  # No mgmt port association
   ```

- Cabinet PDU Controllers have component names (xnames) in the form of `xXmM`, where `X` is the cabinet and `M` is the ordinal of the Cabinet PDU Controller.

   Example mismatch for a PDU:

   ```text
   =============== BMCs in SLS not in HSM components ===============
   x3000m0

   =============== BMCs in SLS not in HSM Redfish Endpoints ===============
   x3000m0
   ```

   If the PDU is accessible over the network, the following can be used to determine the vendor of the PDU.

   ```bash
   ncn-m001# PDU=x3000m0
   ncn-m001# curl -k -s --compressed  https://$PDU -i | grep Server:
   ```

  - Example ServerTech PDU output:

     ```text
     Server: ServerTech-AWS/v8.0v
     ```
  
  - Example HPE PDU output:

     ```text
     Server: HPE/1.4.0
     ```

  - ServerTech PDUs may need passwords changed from their defaults to become functional. See [Change Credentials on ServerTech PDUs](security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md).
  - HPE PDUs are not supported at this time and will likely show up as not being found in HSM. They can be ignored.

- BMCs having no association with a management switch port will be annotated as such, and should be investigated. Exceptions to this are in Mountain or Hill configurations where
  Mountain BMCs will show this condition on SLS/HSM mismatches, which is normal.
- In Hill configurations SLS assumes BMCs in chassis 1 and 3 are fully populated (32 Node BMCs), and in Mountain configurations SLS assumes all BMCs are fully populated (128
  Node BMCs). Any non-populated BMCs will have no HSM data and will show up in the mismatch list.

If it was determined that the mismatch can not be ignored, then proceed onto the the [2.2.2 Known Issues](#hms-smd-discovery-validation-known-issues) below to troubleshoot any mismatched BMCs.

<a name="hms-smd-discovery-validation-known-issues"></a>

#### 2.2.2 Known issues with HSM discovery validation

Known issues that may prevent hardware from getting discovered by Hardware State Manager:

- [Air-cooled hardware is not getting properly discovered with Aruba leaf switches](../troubleshooting/known_issues/discovery_aruba_snmp_issue.md)
- [HMS Discovery job not creating `RedfishEndpoints` in Hardware State Manager](../troubleshooting/known_issues/discovery_job_not_creating_redfish_endpoints.md)

<a name="sms-health-checks"></a>

## 3 Software Management Services health checks

1. [SMS test execution](#sms-checks)
1. [Interpreting `cmsdev` Results](#cmsdev-results)
1. [Known issues with SMS tests](#cmsdev-known-issues)

<a name="sms-checks"></a>

### 3.1 SMS test execution
<<<<<<< HEAD
=======

The test in this section requires that the [Cray CLI is configured](#cray-command-line-interface) on nodes where the test is executed.
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

The following test can be run on any Kubernetes node (any master or worker node, but **not** the PIT node).

```bash
ncn# /usr/local/bin/cmsdev test -q all
```

- The `cmsdev` tool logs to `/opt/cray/tests/cmsdev.log`
- The -q (quiet) and -v (verbose) flags can be used to decrease or increase the amount of information sent to the screen.
  - The same amount of data is written to the log file in either case.

<a name="cmsdev-results"></a>

### 3.2 Interpreting `cmsdev` results

- If all checks passed, then the following will be true:
  - The return code will be zero.
  - The final line of output will begin with `SUCCESS`.
    - For example: `SUCCESS: All 7 service tests passed: bos, cfs, conman, crus, ims, tftp, vcs`
- If one or more checks failed, then the following will be true:
  - The return code will be non-zero.
  - The final line of output will begin with `FAILURE` and will list which checks failed.
    - For example: `FAILURE: 2 service tests FAILED (conman, ims), 5 passed (bos, cfs, crus, tftp, vcs)`
  - After remediating a test failure for a particular service, just that single service test can be re-run by replacing
    `all` in the `cmsdev` command line with the name of the service. For example: `/usr/local/bin/cmsdev test -q cfs`

Additional test execution details can be found in `/opt/cray/tests/cmsdev.log`.

<a name="cmsdev-known-issues"></a>

### 3.3 Known issues with SMS tests

<<<<<<< HEAD
#### `Failed to create vcs organization`

On a fresh install, it is possible that `cmsdev` reports an error similar to the following:
=======
If an Etcd restore has been performed on one of the SMS services (such as BOS or CRUS), then the first Etcd pod that
comes up after the restore will not have a PVC (Persistent Volume Claim) attached to it (until the pod is restarted).
The Etcd cluster is in a healthy state at this point, but the SMS health checks will detect the above condition and
may report test failures similar to the following:

```text
ERROR (run tag 1khv7-bos): persistentvolumeclaims "cray-bos-etcd-ncchqgnczg" not found
ERROR (run tag 1khv7-crus): persistentvolumeclaims "cray-crus-etcd-ffmszl7bvh" not found
```

In this case, these errors can be ignored, or the pod with the same name as the PVC mentioned in the output can be restarted
(as long as the other two Etcd pods are healthy).

## 4. Gateway health and SSH access checks

### 4.1 Gateway health tests

#### 4.1.1 Gateway health tests overview

The gateway tests check the health of the API Gateway on all of the relevant networks. The gateway tests check that the gateway is accessible on all networks where it should be accessible,
and NOT accessible on all networks where it should NOT be accessible. They also check several service endpoints to verify that they return the proper response
on each accessible network.

The test will complete with an overall test status based on the result of the individual health checks on all of the networks.
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

```text
ERROR (run tag zl7ak-vcs): POST https://api-gw-service-nmn.local/vcs/api/v1/orgs: expected status code 201, got 401
ERROR (run tag zl7ak-vcs): Failed to create vcs organization
```

In this case, follow the [Gitea/VCS 401 Errors](../troubleshooting/known_issues/gitea_vcs_401_errors.md) troubleshooting procedure.

The gateway tests can be run from various locations. For this part of the CSM validation, check gateway access from the NCNs and from outside the system.
Externally, the API gateway is accessible on the CMN and either the CAN or CHN, depending on the configuration of the system.
On NCNs, the API gateway is accessible on the same networks (CMN and CAN/CHN) and it is also accessible on the NMNLB network.

#### 4.1.2 Gateway health tests on an NCN

The gateway tests may be run on any NCN with the `docs-csm` RPM installed. For details on installing the `docs-csm` RPM, see [Check for Latest Documentation](../update_product_stream/index.md#check-for-latest-documentation).

To execute the tests, see [Running Gateway Tests on an NCN Management Node](network/gateway_testing.md#running-gateway-tests-on-an-ncn-management-node).

#### 4.1.3 Gateway health tests from outside the system

To execute the tests, see [Running Gateway Tests on a Device Outside the System](network/gateway_testing.md#running-gateway-tests-on-a-device-outside-the-system).

## 4. Booting CSM `barebones` image

<<<<<<< HEAD
Included with the Cray System Management (CSM) release is a pre-built node image that can be used
to validate that core CSM services are available and responding as expected. The CSM `barebones`
image contains only the minimal set of RPMs and configuration required to boot an image and is not
suitable for production usage. To run production work loads, it is suggested that an image from
the Cray OS (COS) product, or similar, be used.
=======
The internal SSH access tests may be run on any NCN with the `docs-csm` RPM installed. For details on installing the `docs-csm` RPM,
see [Check for Latest Documentation](../update_product_stream/index.md#check-for-latest-documentation).
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

- This test is **very important to run** during the CSM install prior to redeploying the PIT node
because it validates all of the services required for that operation.
- The CSM Barebones image included with the release will not successfully complete
beyond the `dracut` stage of the boot process. However, if the `dracut` stage is reached the
boot can be considered successful and shows that the necessary CSM services needed to
boot a node are up and available.
  - This inability to boot the `barebones` image fully will be resolved in future releases of the
   CSM product.
- In addition to the CSM Barebones image, the release also includes an IMS Recipe that
can be used to build the CSM Barebones image. However, the CSM Barebones recipe currently requires
RPMs that are not installed with the CSM product. The CSM Barebones recipe can be built after the
Cray OS (COS) product stream is also installed on to the system.
  - In future releases of the CSM product, work will be undertaken to resolve these dependency issues.
- This procedure can be followed on any NCN or the PIT node.
- The Cray CLI must be configured on the node where this procedure is being performed. See [Configure the Cray Command Line Interface](configure_cray_cli.md) for details on how to do this.

1. [Locate CSM Barebones Image in IMS](#locate-csm-barebones-image-in-ims)
1. [Create a BOS Session Template for the CSM Barebones Image](#csm-bos-session-template)
1. [Find an available compute node](#csm-node)
1. [Reboot the node using a BOS session template](#csm-reboot)
1. [Watch Boot on Console](#csm-watch-boot)

<a name="locate-csm-barebones-image-in-ims"></a>

<<<<<<< HEAD
### 4.1 Locate CSM `barebones` image in IMS

Locate the CSM Barebones image and note the `etag` and `path` fields in the output.
=======
By default, SSH access will be tested on all relevant networks between master nodes, spine switches, compute nodes, and UANs.
It is possible to customize which nodes and networks will be tested. For example, it is possible to include storage nodes, to exclude
UANs, or to exclude the HMN. See the test usage statement for details. The test usage statement is displayed by calling the
test with the `--help` argument:
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

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
  "name": "cray-shasta-csm-sles15sp2-barebones.x86_64-shasta-1.5"
}
```

<a name="csm-bos-session-template"></a>

### 4.2 Create a BOS session template for the CSM `barebones` image

<<<<<<< HEAD
The session template below can be copied and used as the basis for the BOS session template. As noted below, make sure the S3 path for the manifest matches the S3 path shown in
the Image Management Service (IMS).
=======
1. Python version 3 must be installed (if it is not already).
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

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
         "etag": "etag_value_from_cray_ims_command",
         "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
         "network": "nmn",
         "node_roles_groups": [
           "Compute"
         ],
         "path": "path_value_from_cray_ims_command",
         "rootfs_provider": "cpss3",
         "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
         "type": "s3"
       }
     },
     "cfs": {
       "configuration": "cos-integ-config-1.4.0"
     },
     "enable_cfs": false,
     "name": "shasta-1.5-csm-bare-bones-image"
   }
   ```

<<<<<<< HEAD
   **NOTE**: Be sure to replace the values of the `etag` and `path` fields with the ones you noted earlier in the `cray ims images list` command.
=======
      See [Check for Latest Documentation](../update_product_stream/index.md#check-for-latest-documentation).
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

2. Create the BOS session template using the file as input:

   ```bash
   ncn# cray bos sessiontemplate create --file sessiontemplate.json --name shasta-1.5-csm-bare-bones-image
   ```

   The expected output is:

   ```text
   /sessionTemplate/shasta-1.5-csm-bare-bones-image
   ```

<a name="csm-node"></a>

### 4.3 Find an available compute node

```bash
ncn# cray hsm state components list --role Compute --enabled true
```

Example output:

```toml
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

> If it is observed that expected compute nodes are missing from Hardware State Manager, then refer to
> [Known issues with HSM discovery validation](#hms-smd-discovery-validation-known-issues)
> in order to troubleshoot any node BMCs that have not been discovered.

Choose a node from those listed and set `XNAME` to its ID. In this example, `x3000c0s17b2n0`:

```bash
ncn# export XNAME=x3000c0s17b2n0
```

<<<<<<< HEAD
<a name="csm-reboot"></a>
=======
    By default, SSH access will be tested on all relevant networks between master nodes, spine switches, compute nodes, and UANs.
    It is possible to customize which nodes and networks will be tested. For example, it is possible to include storage nodes, to exclude
    UANs, or to exclude the HMN. See the test usage statement for details. The test usage statement is displayed by calling the
    test with the `--help` argument:
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

### 4.4 Reboot the node using a BOS session template

Create a BOS session to reboot the chosen node using the BOS session template that was created:

```bash
ncn# cray bos session create --template-uuid shasta-1.5-csm-bare-bones-image --operation reboot --limit $XNAME
```

Expected output looks similar to the following:

<<<<<<< HEAD
```toml
limit = "x3000c0s17b2n0"
operation = "reboot"
templateUuid = "shasta-1.5-csm-bare-bones-image"
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
=======
<a name="booting-csm-barebones-image"></a>

## 5. Booting CSM `barebones` image
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

<a name="csm-watch-boot"></a>

<<<<<<< HEAD
### 4.5 Connect to the node's console and watch the boot
=======
- This test is **very important to run**, particularly during the CSM install prior to rebooting the PIT node,
because it validates all of the services required for nodes to PXE boot from the cluster.
- The CSM Barebones image included with the release will not successfully complete
beyond the `dracut` stage of the boot process. However, if the `dracut` stage is reached, the
boot can be considered successful and shows that the necessary CSM services needed to
boot a node are up and available.
  - This inability to boot the Barebones image fully will be resolved in future releases of the
CSM product.
- In addition to the CSM Barebones image, the release also includes an IMS Recipe that
can be used to build the CSM Barebones image. However, the CSM Barebones recipe currently requires
RPMs that are not installed with the CSM product. The CSM Barebones recipe can be built after the
Cray OS (COS) product stream is also installed on to the system.
  - In future releases of the CSM product, work will be undertaken to resolve these dependency issues.
- This test can be run on any NCN, but not the PIT node.
- This script uses the Kubernetes API Gateway to access CSM services. This gateway must be properly
configured to allow an access token to be generated by the script.
- This script is installed as part of the `cray-cmstools-crayctldeploy` RPM.
- For additional information on the script and for troubleshooting help look at the document
  [Barebones Image Boot](../troubleshooting/cms_barebones_image_boot.md).
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

See [Manage Node Consoles](conman/Manage_Node_Consoles.md) for information on how to connect to the node's console (and for
instructions on how to close it later).

The boot may take up to 10 or 15 minutes. The image being booted does not support a complete boot, so the node will not
boot fully into an operating system. This test is merely to verify that the CSM services needed to boot a node are available and
working properly.

This boot test is considered successful if the boot reaches the `dracut` stage. You know this has happened if the console output has
something similar to the following somewhere within the final 20 lines of its output:

```text
[    7.876909] dracut: FATAL: Don't know how to handle 'root=craycps-s3:s3://boot-images/e3ba09d7-e3c2-4b80-9d86-0ee2c48c2214/rootfs:c77c0097bb6d488a5d1e4a2503969ac0-27:dvs:api-gw-service-nmn.local:300:nmn0'
[    7.898169] dracut: Refusing to continue
```

**NOTE**: As long as the preceding text is found near the end of the console output, the test is considered successful. It is normal
(and **not** indicative of a test failure) to see something similar to the following at the very end of the console output:

```text
         Starting Dracut Emergency Shell...
[   11.591948] device-mapper: uevent: version 1.0.3
[   11.596657] device-mapper: ioctl: 4.40.0-ioctl (2019-01-18) initialised: dm-devel@redhat.com
Warning: dracut: FATAL: Don't know how to handle
Press Enter for maintenance
(or press Control-D to continue):
```

After the node has reached this point, close the console session. The test is complete.

<a name="uas-uai-tests"></a>

<<<<<<< HEAD
## 5. UAS / UAI tests
=======
## 6. UAS/UAI tests

The commands in this section require that the [Cray CLI is configured](#cray-command-line-interface) on nodes where the commands are being executed.
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

The procedures below use the CLI as an authorized user and run on two separate node types. The first part runs on the LiveCD node, while the second part runs on a non-LiveCD
Kubernetes master or worker node.
In either case, the CLI configuration needs to be initialized on the node and the user running the procedure needs to be authorized.

The following procedures run on separate nodes of the system. They are, therefore, separated into separate sub-sections.

<<<<<<< HEAD
1. [Validate Basic UAS Installation](#uas-uai-validate-install)
1. [Validate UAI Creation](#uas-uai-validate-create)
1. [UAS/UAI Troubleshooting](#uas-uai-validate-debug)
   1. [Authorization Issues](#uas-uai-validate-debug-auth)
   1. [UAS Cannot Access Keycloak](#uas-uai-validate-debug-keycloak)
   1. [UAI Images not in Registry](#uas-uai-validate-debug-registry)
   1. [Missing Volumes and Other Container Startup Issues](#uas-uai-validate-debug-container)
=======
1. [Validate the basic UAS installation](#61-validate-the-basic-uas-installation)
2. [Validate UAI creation](#62-validate-uai-creation)
3. [Test UAI gateway health](#63-test-uai-gateway-health)
4. [UAS/UAI troubleshooting](#64-uas-uai-validate-debug)
   1. [Authorization issues](#641-authorization-issues)
   2. [UAS cannot access Keycloak](#642-uas-cannot-access-keycloak)
   3. [UAI images not in registry](#643-uai-images-not-in-registry)
   4. [Missing volumes and other container startup issues](#644-missing-volumes-and-other-container-startup-issues)
>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)

<a name="uas-uai-validate-install"></a>

### 5.1 Validate the basic UAS installation

This section can be run on any NCN or the PIT node.

1. Initialize the Cray CLI on the node where you are running this section. See [Configure the Cray Command Line Interface](configure_cray_cli.md) for details on how to do this.

1. Show information about `cray-uas-mgr`.

    ```bash
    ncn# cray uas mgr-info list --format toml
    ```

    Expected output looks similar to the following:

    ```toml
    service_name = "cray-uas-mgr"
    version = "1.11.5"
    ```

    In this example output, it shows that UAS is installed and running the `1.11.5` version.

1. List UAIs on the system.

    ```bash
    ncn# cray uas list --format toml
    ```

    Expected output looks similar to the following:

    ```toml
    results = []
    ```

    This example output shows that there are no currently running UAIs. It is possible, if someone else has been using the UAS, that there could be UAIs
    in the list. That is acceptable too from a validation standpoint.

1. Verify that the pre-made UAI images are registered with UAS.

   ```bash
   ncn# cray uas images list --format toml
   ```

   Expected output looks similar to the following:

   ```toml
   default_image = "registry.local/cray/cray-uai-sles15sp2:1.0.11"
   image_list = [ "registry.local/cray/cray-uai-sles15sp2:1.0.11",]
   ```

   This example output shows that the pre-made end-user UAI image (`cray/cray-uai-sles15sp2:1.0.11`) is registered with UAS. This does not necessarily mean this image is
   installed in the container image registry, but it is configured for use. If other UAI images have been created and registered, they may also show up here, which is acceptable.

<a name="uas-uai-validate-create"></a>

### 5.2 Validate UAI creation

> **IMPORTANT:** If the site does not use UAIs, skip UAS and UAI validation. If UAIs are used, there are
> products that configure UAS like Cray Analytics and Cray Programming Environment that
> must be working correctly with UAIs, and should be validated (the procedures for this are
> beyond the scope of this document) prior to validating UAS and UAI. Failures in UAI creation that result
> from incorrect or incomplete installation of these products will generally take the form of UAIs stuck in
> waiting state trying to set up volume mounts. See the
> [UAI Troubleshooting](#uas-uai-validate-debug) section for more information.

This procedure must run on a master or worker node (**not the PIT node**).

1. Initialize the Cray CLI on the node where you are running this section. See [Configure the Cray Command Line Interface](configure_cray_cli.md) for details on how to do this.

1. Verify that a UAI can be created:

   ```bash
   ncn# cray uas create --publickey ~/.ssh/id_rsa.pub --format toml
   ```

   Expected output looks similar to the following:

   ```toml
   uai_connect_string = "ssh vers@10.16.234.10"
   uai_host = "ncn-w001"
   uai_img = "registry.local/cray/cray-uai-sles15sp2:1.0.11"
   uai_ip = "10.16.234.10"
   uai_msg = ""
   uai_name = "uai-vers-a00fb46b"
   uai_status = "Pending"
   username = "vers"
   
   [uai_portmap]
   ```

   This has created the UAI and the UAI is currently in the process of initializing and running. The `uai_status` in
   the output from this command may instead be `Waiting`, which is also acceptable.

1. Set `UAINAME` to the value of the `uai_name` field in the previous command output (`uai-vers-a00fb46b` in our example):

   ```bash
   ncn# UAINAME=uai-vers-a00fb46b
   ```

1. Check the current status of the UAI:

   ```bash
   ncn# cray uas list --format toml
   ```

   Expected output looks similar to the following:

   ```toml
   [[results]]
   uai_age = "0m"
   uai_connect_string = "ssh vers@10.16.234.10"
   uai_host = "ncn-w001"
   uai_img = "registry.local/cray/cray-uai-sles15sp2:1.0.11"
   uai_ip = "10.16.234.10"
   uai_msg = ""
   uai_name = "uai-vers-a00fb46b"
   uai_status = "Running: Ready"
   username = "vers"
   ```

   If the `uai_status` field is `Running: Ready`, proceed to the next step. Otherwise, wait and repeat this command until that is the case. It normally should not take more than a minute or two.

1. The UAI is ready for use. Log into it with the command in the `uai_connect_string` field in the previous command output:

   ```bash
   ncn# ssh vers@10.16.234.10
   vers@uai-vers-a00fb46b-6889b666db-4dfvn:~>
   ```

1. Run a command on the UAI:

   ```bash
   vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> ps -afe
   ```

   Expected output looks similar to the following:

   ```text
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

1. Log out from the UAI

   ```bash
   vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> exit
   ncn#
   ```

1. Clean up the UAI.

   ```bash
   ncn# cray uas delete --uai-list $UAINAME --format toml
   ```

   Expected output looks similar to the following:

   ```toml
   results = [ "Successfully deleted uai-vers-a00fb46b",]
   ```

If the commands ran with similar results, then the basic functionality of the UAS and UAI is working.

<<<<<<< HEAD
=======
### 6.3 Test UAI gateway health

Like the NCN gateway health check, the gateway tests check the health of the API Gateway on all of the relevant networks.
On UAIs, the API gateway should only be accessible on the user network (either CAN or CHN depending on the configuration of the system).
The gateway tests check that the gateway is accessible on all networks where it should be accessible, and NOT accessible on all
networks where it should NOT be accessible. They also check several service endpoints to verify that they return the proper response
on each accessible network.

#### 6.3.1 Gateway test execution

The UAI gateway tests may be run on any NCN with the `docs-csm` RPM installed. For details on installing the `docs-csm` RPM, see [Check for Latest Documentation](../update_product_stream/index.md#check-for-latest-documentation).

The UAI gateway tests are executed by running the following command.

```bash
ncn# /usr/share/doc/csm/scripts/operations/gateway-test/uai-gateway-test.sh
```

The test will launch a UAI with the `gateway-test image`, execute the gateway tests, and then delete the UAI that was launched.
The test will complete with an overall test status based on the result of the individual health checks on all of the networks.

```text
Overall Gateway Test Status:  PASS
```

For more detailed information on the tests results and examples, see [Gateway Testing](network/gateway_testing.md).

>>>>>>> bde1a1d5ee9 (CASMINST-4847: Minor improvements related to CSM health validation)
<a name="uas-uai-validate-debug"></a>

### 5.3 UAS/UAI troubleshooting

The following subsections include common failure modes seen with UAS / UAI operations and how to resolve them.

<a name="uas-uai-validate-debug-auth"></a>

#### 5.3.1 Authorization issues

An error will be returned when running CLI commands if the user is not logged in as a valid Keycloak user or is accidentally using the `CRAY_CREDENTIALS` environment variable.
This variable is set regardless of the user credentials being used.

For example:

```bash
ncn# cray uas list
```

The symptom of this problem is output similar to the following:

```text
Usage: cray uas list [OPTIONS]
Try 'cray uas list --help' for help.

Error: Bad Request: Token not valid for UAS. Attributes missing: ['gidNumber', 'loginShell', 'homeDirectory', 'uidNumber', 'name']
```

Fix this by logging in as a real user (someone with actual Linux credentials) and making sure that `CRAY_CREDENTIALS` is unset.

<a name="uas-uai-validate-debug-keycloak"></a>

#### 5.3.2 UAS cannot access Keycloak

When running CLI commands, a Keycloak error may be returned.

For example:

```bash
ncn# cray uas list
```

The symptom of this problem is output similar to the following:

```text
Usage: cray uas list [OPTIONS]
Try 'cray uas list --help' for help.

Error: Internal Server Error: An error was encountered while accessing Keycloak
```

If the wrong hostname was used to reach the API gateway, re-run the CLI initialization steps above and try again to check that. There may also be a problem with the Istio
service mesh inside of the system. Troubleshooting this is beyond the scope of this section, but there may be useful information in the UAS pod logs in Kubernetes. There are
generally two UAS pods, so the user may need to look at logs from both to find the specific failure. The logs tend to have a very large number of `GET` events listed as part
of the liveness checking.

The following shows an example of looking at UAS logs effectively (this example shows only one UAS manager, normally there would be two):

1. Determine the pod name of the `uas-mgr` pod.

   ```bash
   ncn-mw# kubectl get po -n services | grep "^cray-uas-mgr" | grep -v etcd
   ```

   Expected output looks similar to:

   ```text
   cray-uas-mgr-6bbd584ccb-zg8vx                                    2/2     Running            0          12d
   ```

1. Set `PODNAME` to the name of the manager pod whose logs are going to be viewed.

   ```bash
   ncn-mw# export PODNAME=cray-uas-mgr-6bbd584ccb-zg8vx
   ```

1. View the last 25 log entries of the `cray-uas-mgr` container in that pod, excluding `GET` events:

   ```bash
   ncn-mw# kubectl logs -n services $PODNAME cray-uas-mgr | grep -v 'GET ' | tail -25
   ```

   Example output:

   ```text
   2021-02-08 15:32:41,211 - uas_mgr - INFO - getting deployment uai-vers-87a0ff6e in namespace user
   2021-02-08 15:32:41,225 - uas_mgr - INFO - creating deployment uai-vers-87a0ff6e in namespace user
   2021-02-08 15:32:41,241 - uas_mgr - INFO - creating the UAI service uai-vers-87a0ff6e-ssh
   2021-02-08 15:32:41,241 - uas_mgr - INFO - getting service uai-vers-87a0ff6e-ssh in namespace user
   2021-02-08 15:32:41,252 - uas_mgr - INFO - creating service uai-vers-87a0ff6e-ssh in namespace user
   2021-02-08 15:32:41,267 - uas_mgr - INFO - getting pod info uai-vers-87a0ff6e
   2021-02-08 15:32:41,360 - uas_mgr - INFO - No start time provided from pod
   2021-02-08 15:32:41,361 - uas_mgr - INFO - getting service info for uai-vers-87a0ff6e-ssh in namespace user
   127.0.0.1 - - [08/Feb/2021 15:32:41] "POST /v1/uas?imagename=registry.local%2Fcray%2Fno-image-registered%3A1.0.11 HTTP/1.1" 200 -
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

#### 5.3.3 UAI images not in registry

When listing or describing a UAI, an error in the `uai_msg` field may be returned. For example:

```bash
ncn# cray uas list --format toml
```

There may be something similar to the following output:

```toml
[[results]]
uai_age = "0m"
uai_connect_string = "ssh vers@10.103.13.172"
uai_host = "ncn-w001"
uai_img = "registry.local/cray/cray-uai-sles15sp2:1.0.11"
uai_ip = "10.103.13.172"
uai_msg = "ErrImagePull"
uai_name = "uai-vers-87a0ff6e"
uai_status = "Waiting"
username = "vers"
```

This means the pre-made end-user UAI image is not in the local registry (or whatever registry it is being pulled from; see the `uai_img` value for details). To correct
this, locate and push/import the image to the registry.

<a name="uas-uai-validate-debug-container"></a>

#### 5.3.4 Missing volumes and other container startup issues

Various packages install volumes in the UAS configuration. All of those volumes must also have the underlying resources available, sometimes on the host node where the UAI is running sometimes from with
Kubernetes. If a UAI gets stuck with a `ContainerCreating` `uai_msg` field for an extended time, this is a likely cause. UAIs run in the `user` Kubernetes namespace, and are pods that can be examined
using `kubectl describe`.

1. Locate the pod.

   ```bash
   ncn-mw# kubectl get po -n user | grep <uai-name>
   ```

1. Investigate the problem using the pod name from the previous step.

   ```bash
   ncn-mw# kubectl describe pod -n user <pod-name>
   ```

   If volumes are missing they will show up in the `Events:` section of the output. Other problems may show up there as well. The names of the missing volumes or other issues
   should indicate what needs to be fixed to make the UAI run.
