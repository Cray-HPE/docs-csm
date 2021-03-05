# CSM Install Validation & Health Checks
This page lists available CSM install and health checks that can be executed to validate the CSM install. They can be run anytime after the install has run to completion, but not before.

* [Platform Health Checks](#platform-health-checks)
* [Network Health Checks](#network-health-checks)
* [Automated Goss Testing](#automated-goss-testing)
* [Hardware Management Services Tests](#hms-tests)
* [Cray Management Services Validation Utility](#cms-validation-utility)
* [Booting CSM Barebones Image](#booting-csm-barebones-image)
* [UAS/UAI Tests](#uas-uai-tests)

Examples of when you may wish to run them are:
* after install.sh completes
* before and after NCN reboots
* after the system is brought back up
* any time there is unexpected behavior observed
* in order to provide relevant information to support tickets

The areas should be tested in the order they are listed on this page. Errors in an earlier check may cause errors in later checks due to dependencies.

For more details on these validations and health checks, see the admin guide (note to docs team: replace this with a reference to the specific section of the admin guide).

<a name="platform-health-checks"></a>
## Platform Health Checks

Scripts do not verify results. Script output includes analysis needed to determine pass/fail for each check. All health checks are expected to pass.
Health Check scripts can be run:
* after install.sh has been run – not before
* before and after one of the NCN's reboot
* after the system or a single node goes down unexpectedly
* after the system is gracefully shut down and brought up
* any time there is unexpected behavior on the system to get a baseline of data for CSM services and components
* in order to provide relevant information to support tickets that are being opened after install.sh has been run

Health Check scripts can be found and run on any worker or master node from any directory.

### ncnHealthChecks
     /opt/cray/platform-utils/ncnHealthChecks.sh
The ncnHealthChecks script reports the following health information:
* Kubernetes status for master and worker NCNs
* Ceph health status
* Health of etcd clusters
* Number of pods on each worker node for each etcd cluster
* List of automated etcd backups for the Boot Orchestration Service (BOS),  Boot Script Service (BSS), Compute Rolling Upgrade Service (CRUS), and Domain Name Service (DNS)
* Management node uptimes
* Pods yet to reach the running state

Execute ncnHealthChecks script and analyze the output of each individual check.

### ncnPostgresHealthChecks
     /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
For each postgres cluster the ncnPostgresHealthChecks script determines the leader pod and then reports the status of all postgres pods in the cluster.

Execute ncnPostgresHealthChecks script. Verify leader for each cluster and status of cluster members.

### BGP Peering Status and Reset
Verify that Border Gateway Protocol (BGP) peering sessions are established for each worker node on the system. 

Check the Border Gateway Protocol (BGP) status on the Aruba/Mellanox switches.
Verify that all sessions are in an **Established** state. If the state of any
session in the table is **Idle**, reset the BGP sessions.

On an NCN node determine IP addresses of switches:

```bash
ncn-m001# kubectl get cm config -n metallb-system -o yaml | head -12
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
ncn-m001#
```

Using the first peer-address (10.252.0.2 here) ssh as the administrator to the first switch and note in the returned output if a Mellanox or Aruba switch is indicated.

#### Mellanox Switch 
Enable, verify BGP is enabled, check peering status:

```bash
ncn-m001# ssh admin@10.252.0.2
Mellanox Onyx Switch Management
Password:
Last login: Tue Feb 23 17:05:21 UTC 2021 from 10.252.1.9 on pts/0
Number of total successful connections since last 1 days: 5

Mellanox Switch

sw-spine-001 [rocket-mlag-domain: master] > enable
sw-spine-001 [rocket-mlag-domain: master] # show protocols | include bgp
 bgp:                    enabled
sw-spine-001 [rocket-mlag-domain: master] # show ip bgp summary

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

sw-spine-001 [rocket-mlag-domain: master] #
```

If one or more BGP session is reported in an **Idle** state, reset BGP to re-establish the sessions:
```bash
sw-spine-001 [standalone: master] # clear ip bgp all
```

It may take several minutes for all sessions to become **Established**. Wait a minute, or so, and then verify that all sessions now are all reported as **Established**. If some sessions remain in an **Idle** state, re-run the **clear ip bgp all** command and check again.

```bash
sw-spine-001 [standalone: master] # show ip bgp summary

VRF name                  : default
BGP router identifier     : 10.252.0.2
local AS number           : 65533
BGP table version         : 2
Main routing table version: 2
IPV4 Prefixes             : 42
IPV6 Prefixes             : 0
L2VPN EVPN Prefixes       : 0

------------------------------------------------------------------------------------------------------------------
Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
------------------------------------------------------------------------------------------------------------------
10.252.1.7        4    65533        18        6         2         0      0      0:00:01:26    ESTABLISHED/14
10.252.1.8        4    65533        18        6         2         0      0      0:00:01:26    ESTABLISHED/14
10.252.1.9        4    65533        18        6         2         0      0      0:00:01:26    ESTABLISHED/14

sw-spine-001 [standalone: master] #
```

If after several tries one or more BGP session remains **Idle**, see Check BGP Status and Reset Sessions, in the HPE Cray EX Administration Guide S-8001.

Repeat the above **Mellanox** procedure using the second peer-address (10.252.0.3 here)

#### Aruba Switch
Check BGP peering status

After ssh'ing as admin to the fist peer-address the returned output indicates an Aruba switch. It may be a sw-spine or sw-agg switch.

```bash
ncn-m001# ssh admin@10.252.0.4

 (C) Copyright 2017-2020 Hewlett Packard Enterprise Development LP

 Please register your products now at: https://asp.arubanetworks.com

admin@10.252.0.4 password:

Last login: 2021-01-12 09:51:14 from 10.252.1.15
User "admin" has logged in 84 times in the past 30 days
sw-agg01#

sw-agg01# show bgp ipv4 unicast summary
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

sw-agg01#
```

If one or more BGP session is reported in a **Idle** state, reset BGP to re-establish the sessions:

```bash
sw-agg01# clear bgp *
```

It may take several minutes for all sessions to become
**Established**. Wait a minute, or so, and then verify that all sessions now are reported as **Established**. If some sessions remain in an **Idle** state, re-run the **clear bgp * ** command and check again.

```bash
sw-agg01# show bgp ipv4 unicast summary
VRF : default
BGP Summary
-----------
 Local AS               : 65533        BGP Router Identifier  : 10.252.0.4
 Peers                  : 7            Log Neighbor Changes   : No
 Cfg. Hold Time         : 180          Cfg. Keep Alive        : 60
 Confederation Id       : 0

 Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
 10.252.0.5      65533       19584   19594   20h:44m:58s  Established   Up
 10.252.1.7      65533       34146   39085   20h:46m:21s  Established   Up
 10.252.1.8      65533       34143   39046   20h:41m:12s  Established   Up
 10.252.1.9      65533       34113   39082   00m:01w:04d  Established   Up
 10.252.1.10     65533       34114   39039   00m:01w:04d  Established   Up
 10.252.1.11     65533       34108   39052   00m:01w:04d  Established   Up
 10.252.1.12     65533       34110   39022   00m:01w:04d  Established   Up

sw-agg01#
```

If after several tries one or more BGP session remains **Idle**, see Check BGP Status and Reset Sessions, in the HPE Cray EX Administration Guide S-8001.

Repeat the above **Aruba** procedure using the second peer-address (10.252.0.5 in this example)


<a name="network-health-checks"></a>
## Network Health Checks

### Verify that KEA has active DHCP leases

Verify that KEA has active DHCP leases. Right after an fresh install of CSM it is important to verify that KEA is currently handing out DHCP leases on the system. The following commands can be ran on any of the master nodes or worker nodes.

Get a API Token:
```
# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                 -d client_id=admin-client \
                 -d client_secret=`kubectl get secrets admin-client-auth \
                 -o jsonpath='{.data.client-secret}' | base64 -d` \
                          https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

Retrieve all the Leases currently in KEA:
```
# curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq
```

If there is an non-zero amount of DHCP leases for river hardware returned that is a good indication that KEA is working.

### Verify ability to resolve external DNS

If you have configured unbound to resolve outside hostnames, then the following check should be performed. If you have not done this, then this check may be skipped. 

Run the following on one of the master or worker nodes (not the pit):

```bash
ncn:~ # nslookup cray.com
Server:         10.92.100.225
Address:        10.92.100.225#53

Non-authoritative answer:
Name:   cray.com
Address: 52.36.131.229

ncn:~ # echo $?
ncn:~ # 0
```

Verify that the command has exit code 0, reports no errors, and resolves the address.

### Verify Spire Agent is Running on Kuberetes NCNs

Execute the following command on all Kubernetes NCNs (excluding the PIT):

```bash
ncn:~ # goss -g /opt/cray/tests/install/ncn/tests/goss-spire-agent-service-running.yaml validate
..

Total Duration: 0.011s
```

Known failures and how to recover:

* K8S Test: Verify spire-agent is enabled and running

  - The `spire-agent` service may fail to start on Kubernetes NCNs, logging errors (via journalctl) similar to "join token does not exist or has already been used" or the last logs containing multiple lines of "systemd[1]: spire-agent.service: Start request repeated too quickly.". Deleting the `request-ncn-join-token` daemonset pod running on the node may clear the issue. While the `spire-agent` systemctl service on the Kubernetes node should eventually restart cleanly, you may have to login to the impacted nodes and restart the service. The easiest way to delete the appropriate pod is to create the following function and run `renewncnjoin NODE`

  ```
  function renewncnjoin() { for pod in $(kubectl get pods -n spire |grep request-ncn-join-token | awk '{print $1}'); do if kubectl describe -n spire pods $pod | grep -q "Node:.*$1"; then echo "Restarting $pod running on $1"; kubectl delete -n spire pod "$pod"; fi done }
  ```

  - The `spire-agent` service may also fail if a NCN was powered off for too long and its tokens expired. If this happens then delete /root/spire/agent_svid.der, /root/spire/bundle.der, and /root/spire/data/svid.key off the NCN before deleting the `request-ncn-join-token` daemonset pod.

### Verify the Vault Cluster is Healthy

Execute the following commands on ```ncn-m002```:

```bash
ncn-m002:~ # goss -g /opt/cray/tests/install/ncn/tests/goss-k8s-vault-cluster-health.yaml validate
..

Total Duration: 0.849s
Count: 2, Failed: 0, Skipped: 0
```

<a name="automated-goss-testing"></a>
## Automated Goss Testing

There are multiple [Goss](https://github.com/aelsabbahy/goss) test suites available that cover a variety of sub-systems.

You can execute the general NCN test suite via:

```bash
ncn# /opt/cray/tests/install/ncn/automated/ncn-run-time-checks
```

And the Kubernetes test suite via:

```bash
ncn# /opt/cray/tests/install/ncn/automated/ncn-kubernetes-checks
```

### Known Goss Test Issues

* Tests can only reliably be executed from the PIT node. Should be addressed in a future release.
* K8S Test: Kubernetes Query BSS Cloud-init for ca-certs
  - May fail immediately after platform install. Should pass after the TrustedCerts Operator has updated BSS (Global cloud-init meta) with CA certificates.
* K8S Test: Kubernetes Velero No Failed Backups
  - Due to a [known issue](https://github.com/vmware-tanzu/velero/issues/1980) with Velero, a backup may be attempted immediately upon the deployment of a backup schedule (for example, vault). It may be necessary to use the ```velero``` command to delete backups from a Kubernetes node to clear this situation.

<a name="hms-tests"></a>
## Hardware Management Services Tests

Execute the HMS smoke and functional tests after the CSM install to confirm that the HMS services are running and operational.

### CRAY INTERNAL USE ONLY
The HMS tests are provided by the hms-ct-test-crayctldeploy RPM which comes preinstalled on the NCNs. However, the tests receive frequent updates so it is recommended to check and see if a newer version of the RPM is available for the applicable software installation and if so, to download and install the latest version of the RPM prior to executing the tests. The latest versions of the hms-ct-test-crayctldeploy RPM can be retrieved from car.dev.cray.com in the following folders:
* Master: [ct-tests/HMS/sle15_sp2_ncn/x86_64/dev/master/hms-team/](http://car.dev.cray.com/artifactory/ct-tests/HMS/sle15_sp2_ncn/x86_64/dev/master/hms-team)
* 1.4 Release: [ct-tests/HMS/sle15_sp2_ncn/x86_64/release/shasta-1.4/hms-team/](http://car.dev.cray.com/artifactory/ct-tests/HMS/sle15_sp2_ncn/x86_64/release/shasta-1.4/hms-team/)

Install the RPM on every worker and master NCN (except for ncn-m001 if it is still the PIT node).

### Test Execution
Run the HMS smoke tests. If no failures occur, then run the HMS functional tests. The tests should be executed as root on at least one worker NCN and one master NCN (but **not** ncn-m001 if it is still the PIT node).

    ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_smoke_tests_ncn-resources.sh
    ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_functional_tests_ncn-resources.sh

<a name="cms-validation-utility"></a>
## Cray Management Services Validation Utility
     /usr/local/bin/cmsdev

### CRAY INTERNAL USE ONLY
This tool is included in the cray-cmstools-crayctldeploy rpm, which comes preinstalled on the ncns. However, the tool is receiving frequent updates in the run up to the release. Because of this, it is highly recommended to download and install the latest version.

You can get the latest version of the rpm from car.dev.cray.com in the [csm/SCMS/sle15_sp2_ncn/x86_64/release/shasta-1.4/cms-team/](http://car.dev.cray.com/artifactory/webapp/#/artifacts/browse/tree/General/csm/SCMS/sle15_sp2_ncn/x86_64/release/shasta-1.4/cms-team) folder. The [corresponding folder in the master branch](http://car.dev.cray.com/artifactory/webapp/#/artifacts/browse/tree/General/csm/SCMS/sle15_sp2_ncn/x86_64/release/master/cms-team) may have an even more recent version of the tool, which has not yet been synced to the release branch. At this time no changes have been included in the master branch which are not intended to work on the 1.4 release. Install it on every worker and master ncn (except for ncn-m001 if it is still the PIT node).

At the time of this writing there is a bug ([CASMTRIAGE-553](https://connect.us.cray.com/jira/browse/CASMTRIAGE-553)) which causes some git pushes to VCS to hang. Prior to cmsdev version 0.8.21, this would result in the VCS test hanging. Starting in cmsdev version 0.8.21, the test was modified to try to avoid this issue. **If you see the VCS test hang on cmsdev version 0.8.21 or later**, please record this in ([CASMTRIAGE-553](https://connect.us.cray.com/jira/browse/CASMTRIAGE-553)) and include the cmsdev version. If you do see the test hang, stop the test with control-C and re-run it. It may take a few tries but so far it has always eventually executed.

### Usage
     cmsdev test [-q | -v] <shortcut>
* The shortcut determines which component will be tested. See the table in the next section for the list of shortcuts.
* The tool logs to /opt/cray/tests/cmsdev.log
* The -q (quiet) and -v (verbose) flags can be used to decrease or increase the amount of information sent to the screen.
  * The same amount of data is written to the log file in either case.

#### Interpreting Results

* If a test passes:
  * The last line of output from the tool reports SUCCESS
  * The return code is 0.
* If a test fails:
  * The last line of output from the tool reports FAILURE
  * The return code is non-0.
* Unless the test was run in verbose mode, the log file will contain additional information about the execution.
* For more detailed information on the tests, please see the CSM Validation section of the admin guide (note to docs writers: replace this with the actual document name and section number/title once available).

### Checks To Run

You should run a check for each of the following services after an install. These should be run on at least one worker ncn and at least one master ncn (but **not** ncn-m001 if it is still the PIT node).

| Services  | Shortcut |
| ---  | --- |
| BOS (Boot Orchestration Service) | bos |
| CFS (Configuration Framework Service) | cfs |
| ConMan (Console Manager) | conman |
| CRUS (Compute Rolling Upgrade Service) | crus |
| IMS (Image Management Service) | ims |
| iPXE, TFTP (Trivial File Transfer Protocol) | ipxe* |
| VCS (Version Control Service) | vcs |

\* The ipxe shortcut runs a check of both the iPXE service and the TFTP service.

The following is a convenient way to run all of the tests and see if they passed:

```bash
for S in bos cfs conman crus ims ipxe vcs ; do
    LOG=/root/cmsdev-$S-$(date +"%Y%m%d_%H%M%S").log
    echo -n "$(date) Starting $S check ... "
    START=$SECONDS
    /usr/local/bin/cmsdev test -v $S > $LOG 2>&1
    rc=$?
    let DURATION=SECONDS-START
    if [ $rc -eq 0 ]; then
        echo "PASSED (duration: $DURATION seconds)"
    else
        echo "FAILED (duration: $DURATION seconds)"
        echo " # See $LOG for details"
    fi
done
```

<a name="booting-csm-barebones-image"></a>
## Booting CSM Barebones Image

Included with the Cray System Management (CSM) release is a pre-built node image that can be used
to validate that core CSM services are available and responding as expected. The CSM barebones
image contains only the minimal set of RPMS and configuration required to boot an image and is not
suitable for production usage. To run production work loads, it is suggested that an image from
the Cray OS (COS) product, or similar, be used.

---
**NOTE**

The CSM Barebones image included with the Shasta 1.4 release will not successfully complete
the beyond the dracut stage of the boot process. However, if the dracut stage is reached the
boot can be considered successful and shows that the necessary CSM services needed to
boot a node are up and available.

This inability to fully boot the barebones image will be resolved in future releases of the
CSM product.

---

---
**NOTE**

In addition to the CSM Barebones image, the Shasta 1.4 release also includes an IMS Recipe that
can be used to build the CSM Barebones image. However, the CSM Barebones recipe currently requires
rpms that are not installed with the CSM product. The CSM Barebones recipe can be built after the
Cray OS (COS) product stream is also installed on to the system.

In future releases of the CSM product, work will be undertaken to resolve these dependency issues.

---

---
**NOTE**

You will need to use the CLI in order to complete these tasks. If needed, see the
[Initialize and Authorize the CLI](#uas-uai-init-cli) section.

---

### Locate the CSM Barebones Image in IMS

Locate the CSM Barebones image and note the path to the image's manifest.json in S3.

```json
// cray ims images list --format json | jq '.[] | select(.name | contains("barebones"))'
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

### Create a BOS Session Template for the CSM Barebones Image

The session template below can be copied and used as the basis for the BOS Session Template. As noted below, make sure the S3 path for the manifest matches the S3 path shown in IMS.

```json
// vi sessiontemplate.json
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

// cray bos sessiontemplate create --file sessiontemplate.json --name shasta-1.4-csm-bare-bones-image
// /sessionTemplate/shasta-1.4-csm-bare-bones-image
```

### Find an available compute node and boot the session template

```ini
# cray hsm state components list --role Compute --enabled true
...
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

```bash
ncn# cray bos session create --template-uuid shasta-1.4-csm-bare-bones-image --operation reboot --limit <xname>
```

### Verify console connections

Sometimes the compute nodes and uan are not up yet when cray-conman is initialized and will not be 
monitored  yet.  This is a good time to verify that all nodes are being monitored for console logging
or re-initialze cray-conman if needed. 

Use kubectl to exec into the running cray-conman pod, then check the existing connections.
``` bash
cray-conman-b69748645-qtfxj:/ # conman -q
x9000c0s1b0n0
x9000c0s20b0n0
x9000c0s22b0n0
x9000c0s24b0n0
x9000c0s27b1n0
x9000c0s27b2n0
x9000c0s27b3n0
```

If the compute nodes and uans are not included in the list of nodes being monitored, the 
conman process can be re-initialized by killing the conmand process:
``` bash
cray-conman-b69748645-qtfxj:/ # ps -ax | grep conmand
     13 ?        Sl     0:45 conmand -F -v -c /etc/conman.conf
  56704 pts/3    S+     0:00 grep conmand
cray-conman-b69748645-qtfxj:/ # kill 13
```

This will regenerate the conman configuration file and restart the conmand process, now
including all nodes that are included in state manager.

``` bash
cray-conman-b69748645-qtfxj:/ # conman -q
x9000c1s7b0n1
x9000c0s1b0n0
x9000c0s20b0n0
x9000c0s22b0n0
x9000c0s24b0n0
x9000c0s27b1n0
x9000c0s27b2n0
x9000c0s27b3n0
```

### Connect to the node's console and watch the boot

Run conman from inside the conman pod to access the console. The boot will fail, but should reach the dracut stage. If the dracut stage is reached, the boot
can be considered successful and shows that the necessary CSM services needed to boot a node are
up and available.
```bash
ncn# kubectl get pods -n services | grep conman
cray-conman-b69748645-qtfxj                                    3/3     Running     2          46m
ncn# kubectl exec -it -n services cray-conman-b69748645-qtfxj -c cray-conman -- bash
cray-conman-b69748645-qtfxj:/ # conman -j x9000c1s7b0n1
...
[    7.876909] dracut: FATAL: Don't know how to handle 'root=craycps-s3:s3://boot-images/e3ba09d7-e3c2-4b80-9d86-0ee2c48c2214/rootfs:c77c0097bb6d488a5d1e4a2503969ac0-27:dvs:api-gw-service-nmn.local:300:nmn0'
[    7.898169] dracut: Refusing to continue
[    7.952291] systemd-shutdow: 13 output lines suppressed due to ratelimiting
[    7.959842] systemd-shutdown[1]: Sending SIGTERM to remaining processes...
[    7.975211] systemd-journald[1022]: Received SIGTERM from PID 1 (systemd-shutdow).
[    7.982625] systemd-shutdown[1]: Sending SIGKILL to remaining processes...
[    7.999281] systemd-shutdown[1]: Unmounting file systems.
[    8.006767] systemd-shutdown[1]: Remounting '/' read-only with options ''.
[    8.013552] systemd-shutdown[1]: Remounting '/' read-only with options ''.
[    8.019715] systemd-shutdown[1]: All filesystems unmounted.
[    8.024697] systemd-shutdown[1]: Deactivating swaps.
[    8.029496] systemd-shutdown[1]: All swaps deactivated.
[    8.036504] systemd-shutdown[1]: Detaching loop devices.
[    8.043612] systemd-shutdown[1]: All loop devices detached.
[    8.059239] reboot: System halted
```

<a name="uas-uai-tests"></a>
## UAS / UAI Tests

<a name="uas-uai-init-cli"></a>
### Initialize and Authorize the CLI

The procedures below use the CLI as an authorized user and run on two separate node types.  The first part runs on the LiveCD node while the second part runs on a non-LiveCD kubernetes master or worker node.  When using the CLI on either node, the CLI configuration needs to be initialized and the user running the procedure needs to be authorized.  This section describes how to initialize the CLI for use by a user and authorize the CLI as a user to run the procedures on any given node.  The procedures will need to be repeated in both stages of the validation procedure.

#### Stop Using the CRAY_CREDENTIALS Service Account Token

Installation procedures leading up to production mode on Shasta use the CLI with a Kubernetes managed service account normally used for internal operations.  There is a procedure for extracting the OAUTH token for this service account and assigning it to the `CRAY_CREDENTIALS` environment variable to permit simple CLI operations.  The UAS / UAI validation procedure runs as a post-installation procedure and requires an actual user with Linux credentials, not this service account. Prior to running any of the steps below you must unset the `CRAY_CREDENTIALS` environment variable:

```
# unset CRAY_CREDENTIALS
```

#### Initialize the CLI Configuration

The CLI needs to know what host to use to obtain authorization and what user is requesting authorization so it can obtain an OAUTH token to talk to the API Gateway.  This is accomplished by initializing the CLI configuration.  In this example, I am using the `vers` username.  In practice, `vers` and the response to the `password: ` prompt should be replaced with the username and password of the administrator running the validation procedure.

To check whether the CLI needs initialization, run:

```
# cray config describe
```

If the result looks like this:

```
# cray config describe
Usage: cray config describe [OPTIONS]

Error: No configuration exists. Run `cray init`
```

the CLI needs initialization.  If it looks more like this:

```
# cray config describe
Your active configuration is: default
[core]
hostname = "https://api-gw-service-nmn.local"

[auth.login]
username = "vers"
```

then the CLI is initialized and logged in as `vers`.  If you are not `vers` you will want to authorize yourself using your username and password in the next section.  If you are `vers` you are ready to move on to the validation procedure on that node.

Assuming you need to initialize the CLI, run the following (again, remembering to substitute your username and password for `vers` and the password response):

```
# cray init
Cray Hostname: api-gw-service-nmn.local
Username: vers
Password:
Success!

Initialization complete.
```

#### Authorize the CLI for Your User

If, when you check for an initialized CLI you find it is initialized but authorized for a user different from you, you will want to authorize the CLI for your self.  Do this with the following (remembering to substitute your username and password for `vers`):

```
# cray auth login
Username: vers
Password:
Success!
```

You are now authorized to use the CLI.

#### Troubleshooting

If initialization or authorization fails in one of the above steps, there are several common causes:

* DNS failure looking up `api-gw-service-nmn.local` may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
* Network connectivity issues with the NMN may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
* Certificate mismatch or trust issues may be preventing a secure connection to the API Gateway
* Istio failures may be preventing traffic from reaching Keycloak
* Keycloak may not yet be set up to authorize you as a user

While resolving these issues is beyond the scope of this section, you may get clues to what is failing by adding `-vvvvv` to the `cray auth...` or `cray init ...` commands.

### Validate UAS and UAI Functionality

The following procedures run on separate nodes of the Shasta system.  They are, therefore, separated into separate sub-sections.

#### Validate the Basic UAS Installation

Make sure you are running on the LiveCD node and have initialized and authorized yourself in the CLI as described above.

Basic UAS installation is validated using the following:

```
ncn-m001-pit# cray uas mgr-info list
service_name = "cray-uas-mgr"
version = "1.11.5"

ncn-m001-pit# cray uas list
results = []
```

This shows that UAS is installed and running the `1.11.5` version.  It also shows that there are no currently running UAIs.  It is possible, if someone else has been using the UAS that there could be actual UAIs in the list.  That is acceptable too from a validation standpoint.

To verify that the pre-made UAI images are registered with UAS, use:

```
ncn-m001-pit:~ # cray uas images list
default_image = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
image_list = [ "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest",]
```

This shows that the pre-made end-user UAI image (`cray/cray-uai-sles15sp1:latest`) is registered with UAS. This does not necessarily mean this image is installed in the container image registry, but it is configured for use.  If other UAI images have been created and registered, they may also show up here -- that is acceptable.

#### Validate UAI Creation

This procedure must run on a master or worker node (and not ncn-w001) on the Shasta system (or from an external host, but the procedure for that is not covered here).  It requires that the CLI be initialized and authorized as you.

To verify that you can create a UAI, use the following command:

```
ncn-w003# cray uas create --publickey ~/.ssh/id_rsa.pub
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

This has created the UAI and the UAI is currently in the process of initializing and running.  The following can be repeated as needed to watch the UAIs state.  When the results look like the following:

```
ncn-w003# cray uas list
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

The UAI is ready for use.  You can then log into it (without a password) as follows:

```
ncn-w003# ssh vers@10.16.234.10
The authenticity of host '10.16.234.10 (10.16.234.10)' can't be established.
ECDSA key fingerprint is SHA256:BifA2Axg5O0Q9wqESkLqK4z/b9e1usiDUZ/puGIFiyk.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.16.234.10' (ECDSA) to the list of known hosts.
vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> ps -afe
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 18:51 ?        00:00:00 /bin/bash /usr/bin/uai-ssh.sh
munge         36       1  0 18:51 ?        00:00:00 /usr/sbin/munged
root          54       1  0 18:51 ?        00:00:00 su vers -c /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
vers          55      54  0 18:51 ?        00:00:00 /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
vers          62      55  0 18:51 ?        00:00:00 sshd: vers [priv]
vers          67      62  0 18:51 ?        00:00:00 sshd: vers@pts/0
vers          68      67  0 18:51 pts/0    00:00:00 -bash
vers         120      68  0 18:52 pts/0    00:00:00 ps -afe
vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> exit
logout
Connection to 10.16.234.10 closed.
```

Finally, clean up the UAI.  Notice that the UAI name used is the same as the name in the output from `cray uas create ...` above:

```
ncn-w003# cray uas delete --uai-list uai-vers-a00fb46b
results = [ "Successfully deleted uai-vers-a00fb46b",]

```

If you got this far with similar results, then the UAS and UAI basic functionality is working.

#### Troubleshooting

Here are some common failure modes seen with UAS / UAI operations and how to resolve them.

##### Authorization Issues

If you are not logged in as a valid Keycloak user or are accidentally using the `CRAY_CREDENTIALS` environment variable (i.e. the variable is set regardless of whether you are logged in as you), you should see something like this:
```
# cray uas list
Usage: cray uas list [OPTIONS]
Try 'cray uas list --help' for help.

Error: Bad Request: Token not valid for UAS. Attributes missing: ['gidNumber', 'loginShell', 'homeDirectory', 'uidNumber', 'name']
```

Fix this by logging in as a real user (someone with actual Linux credentials) and making sure that `CRAY_CREDENTIALS` is unset.

##### UAS Cannot Access Keycloak

If you see something that looks like:

```
# cray uas list
Usage: cray uas list [OPTIONS]
Try 'cray uas list --help' for help.

Error: Internal Server Error: An error was encountered while accessing Keycloak
```

You may be using the wrong hostname to reach the API gateway, re-run the CLI initialization steps above and try again to check that.  There may also be a problem with the Istio service mesh inside of your Shasta system.  Troubleshooting this is beyond the scope of this section, but you may find more useful information by looking at the UAS pod logs in Kubernetes.  There are, generally, two UAS pods, so you may need to look at logs from both to find the specific failure.  The logs tend to have a very large number of `GET ` events listed as part of the aliveness checking.  The following shows an example of looking at UAS logs effectively (the example shows only one UAS manage, normally there would be two):

```
# kubectl get po -n services | grep uas-mgr | grep -v etcd
cray-uas-mgr-6bbd584ccb-zg8vx                                    2/2     Running            0          12d
# kubectl logs -n services cray-uas-mgr-6bbd584ccb-zg8vx cray-uas-mgr | grep -v 'GET ' | tail -25
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

##### UAI Images not in Registry

If you see something like:

```
# cray uas list
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

the pre-made end-user UAI image is not in your local registry (or whatever registry it is being pulled from, see the `uai_img` value for details).  Locate and push / import the image to the registry.

##### Missing Volumes and other Container Startup Issues

Various packages install volumes in the UAS configuration.  All of those volumes must also have the underlying resources available, sometimes on the host node where the UAI is running sometimes from with Kubernetes.  If your UAI gets stuck with a `ContainerCreating` `uai_msg` field for an extended time, this is a likely cause.  UAIs run in the `user` Kubernetes namespace, and are pods that can be examined using `kubectl describe`.  Use

```
# kubectl get po -n user | grep <uai-name>
```

to locate the pod, and then use

```
# kubectl describe -n user <pod-name>
```

to investigate the problem.  If volumes are missing they will show up in the `Events:` section of the output.  Other problems may show up there as well.  The names of the missing volumes or other issues should indicate what needs to be fixed to make the UAI run.
