# Validate CSM Health

Anytime after the installation of the CSM services, the health of the management nodes and all CSM services can be validated.

The following are examples of when to run health checks:

- After completing the [Install CSM Services](../install/index.md#install_csm_services) step of the CSM install (**not** before)
- Before and after NCN reboots
- After the system is brought back up
- Any time there is unexpected behavior observed
- In order to provide relevant information to create support tickets

The areas should be tested in the order they are listed on this page. Errors in an earlier check may cause errors in later checks because of dependencies.

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
    - [4.2.1 Known issues with internal SSH access test execution](#421-known-issues-with-internal-ssh-access-test-execution)
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

<a name="platform-health-checks"></a>

## 1. Platform health checks

All platform health checks are expected to pass. Each check has been implemented as a [Goss](https://github.com/aelsabbahy/goss) test which reports a `PASS` or `FAIL`.

Available platform health checks:

1. [NCN health checks](#pet-ncnhealthchecks)
    1. [Known issues with NCN health checks](#autogoss-issues)
1. [OPTIONAL Check of `ncnHealthChecks` resources](#pet-optional-ncnhealthchecks-resources)
    1. [Known issues with NCN resource checks](#pet-resource-checks-known-issues)
1. [Check of system management monitoring tools](#check-of-system-management-monitoring-tools)

<a name="pet-ncnhealthchecks"></a>

### 1.1 NCN health checks

These checks require that the [Cray CLI is configured](#cray-command-line-interface) on all worker NCNs.

If `ncn-m001` is the PIT node, then run these checks on `ncn-m001`; otherwise run them from any master NCN.

1. Specify the `admin` user password for the management switches in the system.

    This is required for the `ncn-healthcheck` tests.

    > `read -s` is used to prevent the password from being written to the screen or the shell history.

    ```bash
    ncn-m/pit# read -s SW_ADMIN_PASSWORD
    ncn-m/pit# export SW_ADMIN_PASSWORD
    ```

1. Run the NCN health checks.

    ```bash
    ncn-m/pit# /opt/cray/tests/install/ncn/automated/ncn-healthcheck | tee ncn-healthcheck.log
    ```

    The following command will extract the test totals for the various nodes:

    ```bash
    ncn-m/pit# grep "Total Test" ncn-healthcheck.log
    ```

1. Run the Kubernetes checks.

    ```bash
    ncn-m/pit# /opt/cray/tests/install/ncn/automated/ncn-kubernetes-checks | tee ncn-kubernetes-checks.log
    ```

    The following command will extract the test totals for the various nodes:

    ```bash
    ncn-m/pit# grep "Total Test" ncn-kubernetes-checks.log
    ```

1. Review results.

    Review the output for `Result: FAIL` and follow the instructions provided to resolve any such test failures. With the exception of the [Known Test Issues](#autogoss-issues), all health checks are expected to pass.

<a name="autogoss-issues"></a>

#### 1.1.1 Known issues with NCN health checks

- It is possible that the first pass of running these tests may fail due to `cloud-init` not being completed on the storage nodes.
  In this case, please wait five minutes and re-run the tests.
- For any failures related to SSL certificates, see the [Platform CA Issues](../troubleshooting/known_issues/platform_ca_issues.md) troubleshooting guide.
- `Kubernetes Query BSS Cloud-init for ca-certs`
  - This test may fail immediately after platform install. It should pass after the TrustedCerts operator has updated BSS
    (Global `cloud-init` meta) with CA certificates.
- `Kubernetes Velero No Failed Backups`
  - Because of a [known issue  with Velero](https://github.com/vmware-tanzu/velero/issues/1980), a backup may be attempted immediately
    upon the deployment of a backup schedule (for example, Vault). It may be necessary to delete backups from a Kubernetes node to
    clear this situation. See the output of the test for more details on how to cleanup backups that have failed due to a known
    interruption. For example:
     1. Find the failed backup.

        ```bash
        ncn-mw/pit# kubectl get backups -A -o json | jq -e '.items[] | select(.status.phase == "PartiallyFailed") | .metadata.name'
        ```

     1. Delete the backup.

        > In the following command, replace `<backup>` with a backup returned in the previous step.
        >
        > This command will not work on the PIT node.

        ```bash
        ncn-mw# velero backup delete <backup> --confirm
        ```

- `Verify spire-agent is enabled and running`
  - The `spire-agent` service may fail to start on Kubernetes NCNs (all worker and master nodes). In this case, it may log errors
    (using `journalctl`) similar to `join token does not exist or has already been used`, or the last log entries may contain multiple
    instances of `systemd[1]: spire-agent.service: Start request repeated too quickly.`. Deleting the `request-ncn-join-token` `daemonset` pod
    running on the node may clear the issue. Even though the `spire-agent` `systemctl` service on the Kubernetes node should eventually
    restart cleanly, the user may have to log in to the impacted nodes and restart the service. The following recovery procedure can
    be run from any Kubernetes node in the cluster.
     1. Define the following function

        ```bash
        ncn-mw/pit# function renewncnjoin() {
            for pod in $(kubectl get pods -n spire |grep request-ncn-join-token | awk '{print $1}'); do
                if kubectl describe -n spire pods $pod | grep -q "Node:.*$1"; then
                    echo "Restarting $pod running on $1"
                    kubectl delete -n spire pod "$pod"
                fi
            done }
        ```

     1. Run the function as follows (substituting the name of the impacted NCN):

        ```bash
        ncn-mw/pit# renewncnjoin ncn-xxxx
        ```

  - The `spire-agent` service may also fail if an NCN was powered off for too long and its tokens expired. If this happens, then delete
    `/root/spire/agent_svid.der`, `/root/spire/bundle.der`, and `/root/spire/data/svid.key` off the NCN before deleting the
    `request-ncn-join-token` `daemonset` pod.
- `cfs-state-reporter service ran successfully`
  - If this test is failing, it could be due to SSL certificate issues on that NCN.
     1. Run the following command on the node where the test is failing.

        ```bash
        ncn# systemctl status cfs-state-reporter | grep HTTPSConnectionPool
        ```

     1. If the previous command gives any output, this indicates possible SSL certificate problems on that NCN.

        - See the [Platform CA Issues](../troubleshooting/known_issues/platform_ca_issues.md) troubleshooting guide.

  - If this test is failing on a storage node, it could be an issue with the node's Spire token. The following procedure may resolve the problem:
     1. Run the following script on `ncn-m002`:

        ```bash
        ncn-m002# /opt/cray/platform-utils/spire/fix-spire-on-storage.sh
        ```

     1. Then re-run the check to see if the problem has been resolved.

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

### 1.2 NCN resource checks (optional)

These optional checks display the NCN uptimes, the node resource consumptions, and/or the list of pods not in a running state.
If `ncn-m001` is the PIT node, then run these checks on `ncn-m001`; otherwise run them from any master NCN.

```bash
ncn-m/pit# /opt/cray/platform-utils/ncnHealthChecks.sh -s ncn_uptimes
ncn-m/pit# /opt/cray/platform-utils/ncnHealthChecks.sh -s node_resource_consumption
ncn-m/pit# /opt/cray/platform-utils/ncnHealthChecks.sh -s pods_not_running
```

<a name="pet-resource-checks-known-issues"></a>

#### 1.2.1 Known issues with NCN resource checks

- `pods_not_running`
  - If the output of `pods_not_running` indicates that there are pods in the `Evicted` state, it may be due to the root file system
    being filled up on the Kubernetes node in question. Kubernetes will begin evicting pods once the root file system space is at 85%
    full until it is back under 80%. This commonly happens on `ncn-m001`, because it is a location where install and documentation files
    may have been downloaded. It may be necessary to clean up space in the `/` directory if this is the root cause of pod evictions.
    Listing the top 10 files that are 1024M or larger is one way to start the analysis.

    ```bash
    ncn-mw# df -h /
    Filesystem      Size  Used Avail Use% Mounted on
    LiveOS_rootfs   280G  245G   35G  88% /
    ```

    ```bash
    ncn-mw# du -h -s /root/
    225G  /root/
    ```

    ```bash
    ncn-mw# du -ah -B 1024M /root | sort -n -r | head -n 10
    ```

  - The `cray-crus-` pod is expected to be in the `Init` state until Slurm and MUNGE
    are installed. In particular, this will be the case if executing this as part of the validation after completing the [Install CSM Services](../install/install_csm_services.md).
    If in doubt, validate the CRUS service using the [CMS Validation Tool](#sms-health-checks). If the CRUS check passes using that tool, do not worry about the `cray-crus-` pod state.

  - The `hmn-discovery` and `cray-dns-unbound-manager` cronjob pods may be in various transitional states such as `Pending`, `Init`, `PodInitializing`,
    `NotReady`, or `Terminating`. This is expected because these pods are periodically started and often can be caught in intermediate states.

  - If some `*postgresql-db-backup` cronjob pods are in `Error` state, they can be ignored if the most recent pod `Completed`.
    The `Error` pods are cleaned up over time but are left to troubleshoot issues in the case that all retries for the `postgresql-db-backup` job fail.

<a name="check-of-system-management-monitoring-tools"></a>

### 1.3 Check of system management monitoring tools

If all designated prerequisites are met, the availability of system management health services may optionally be validated by accessing the URLs listed in
[Access System Management Health Services](system_management_health/Access_System_Management_Health_Services.md).
It is very important to check the `Prerequisites` section of this document.

If one or more of the the URLs listed in the procedure are inaccessible, it does not necessarily mean that system is not healthy. It may simply mean that not all of the
prerequisites have been met to allow access to the system management health tools via URL.

Information to assist with troubleshooting some of the components mentioned in the prerequisites can be accessed here:

- [Troubleshoot CMN Issues](network/customer_accessible_networks/Troubleshoot_CMN_Issues.md)
- [Troubleshoot DNS Configuration Issues](network/external_dns/Troubleshoot_DNS_Configuration_Issues.md)
- [Check BGP Status and Reset Sessions](network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md)
- [Troubleshoot BGP not Accepting Routes from MetalLB](network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)
- [Troubleshoot Services without an Allocated IP Address](network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
- [Troubleshoot Prometheus Alerts](system_management_health/Troubleshoot_Prometheus_Alerts.md)

<a name="hms-health-checks"></a>

## 2. Hardware Management Services health checks

The checks in this section require that the [Cray CLI is configured](#cray-command-line-interface) on nodes where the checks are executed.

Execute the HMS tests to confirm that the Hardware Management Services are running and operational.

Note: Do not run HMS tests concurrently on multiple nodes. They may interfere with one another and cause false failures.

1. [HMS CT test execution](#hms-test-execution)
1. [Hardware State Manager discovery validation](#hms-smd-discovery-validation)
    1. [Interpreting HSM discovery results](#hms-smd-discovery-validation-interpreting-results)
    1. [Known issues with HSM discovery validation](#hms-smd-discovery-validation-known-issues)

<a name="hms-test-execution"></a>

### 2.1 HMS CT test execution

These tests may be executed on any one worker or master NCN (but **not** `ncn-m001` if it is still the PIT node).

Run the HMS CT tests. This is done by running the `run_hms_ct_tests.sh` script:

```bash
ncn# /opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh
```

The return value of the script is 0 if all CT tests ran successfully, non-zero
if not. On CT test failures the script will instruct the admin to look at the
CT test log files. If one or more failures occur, investigate the cause of
each failure. See the [Interpreting HMS Health Check Results](../troubleshooting/interpreting_hms_health_check_results.md) documentation for more information.

<a name="hms-smd-discovery-validation"></a>

### 2.2 Hardware State Manager discovery validation

By this point in the installation process, the Hardware State Manager (HSM) should
have done its discovery of the system.

The foundational information for this discovery is from the System Layout Service (SLS). Thus, a
comparison needs to be done to see that what is specified in SLS (focusing on
BMC components and Redfish endpoints) are present in HSM.

To perform this comparison execute the `verify_hsm_discovery.py` script on a Kubernetes master or worker NCN. The result is pass/fail (returns 0 or non-zero):

```bash
ncn# /opt/cray/csm/scripts/hms_verification/verify_hsm_discovery.py
```

The output will ideally appear as follows, if there are mismatches these will be displayed in the appropriate section of
the output. Refer to [2.2.1 Interpreting results](#hms-smd-discovery-validation-interpreting-results) and
[2.2.2 Known Issues](#hms-smd-discovery-validation-known-issues) below to troubleshoot any mismatched BMCs.

```text
HSM Cabinet Summary
===================
x1000 (Mountain)
  Discovered Nodes:          50
  Discovered Node BMCs:      25
  Discovered Router BMCs:    32
  Discovered Chassis BMCs:    8
x3000 (River)
  Discovered Nodes:          23 (12 Mgmt, 7 Application, 4 Compute)
  Discovered Node BMCs:      24
  Discovered Router BMCs:     2
  Discovered Cab PDU Ctlrs:   0

River Cabinet Checks
====================
x3000
  Nodes: PASS
  NodeBMCs: PASS
  RouterBMCs: PASS
  ChassisBMCs: PASS
  CabinetPDUControllers: PASS

Mountain/Hill Cabinet Checks
============================
x1000 (Mountain)
  ChassisBMCs: PASS
  Nodes: PASS
  NodeBMCs: PASS
  RouterBMCs: PASS
```

The script will have an exit code of 0 if there are no failures. If there is
any FAIL information displayed, the script will exit with a non-zero exit
code. Failure information interpretation is described in the next section.

<a name="hms-smd-discovery-validation-interpreting-results"></a>

#### 2.2.1 Interpreting HSM discovery results

The Cabinet Checks output is divided into three sections:

- Summary information for each cabinet
- Detail information for River cabinets
- Detail information for Mountain/Hill cabinets.

In the River section, any hardware found in SLS and not discovered by HSM is
considered a failure, with the exception of PDU controllers, which is a
warning. Also, the BMC of one of the management NCNs (typically `ncn-m001`)
will not be connected to the HSM HW network and thus will show up as being not
discovered and/or not having any `mgmt` network connection. This is treated as
a warning.

In the Mountain section, the only thing considered a failure are Chassis BMCs
that are not discovered in HSM. All other items (nodes, node BMCs and router
BMCs) which are not discovered are considered warnings.

Any failures need to be investigated by the admin for rectification. Any
warnings should also be examined by the administrator to ensure they are accurate and
expected.

For each of the BMCs that show up as not being present in HSM components or
Redfish Endpoints use the following notes to determine whether the issue with the
BMC can be safely ignored or needs to be addressed before proceeding.

- The node BMC of `ncn-m001` will not typically be present in HSM component data, as it is typically connected to the site network instead of the HMN network.
- The node BMCs for HPE Apollo XL645D nodes may report as a mismatch depending on the state of the system when the `verify_hsm_discovery.py` script is run. If the system is currently going through the
  process of installation, then this is an expected mismatch as the [Prepare Compute Nodes](../install/prepare_compute_nodes.md) procedure required to configure the BMC of the HPE Apollo 6500 XL645D node
  may not have been completed yet.
   > For more information refer to [Configure HPE Apollo 6500 XL645D Gen10 Plus Compute Nodes](../install/prepare_compute_nodes.md#configure-hpe-apollo-6500-x645d-gen10-plus-compute-nodes) for additional required configuration for this type of BMC.

   Example mismatch for the BMC of an HPE Apollo XL654D:

   ```text
     Nodes: FAIL
       - x3000c0s30b1n0 (Compute, NID 5) - Not found in HSM Components.
     NodeBMCs: FAIL
       - x3000c0s19b1 - Not found in HSM Components; Not found in HSM Redfish Endpoints.
   ```

- Chassis Management Controllers (CMC) may show up as not being present in HSM. CMCs for Intel node blades can be ignored. Gigabyte node blade CMCs not found in HSM is not normal and should be investigated.
  If a Gigabyte CMC is expected to not be connected to the HMN network, then it can be ignored. Otherwise, verify that the root service account is configured for the CMC and add it if needed by following
  the steps outlined in [Add Root Service Account for Gigabyte Controllers](security_and_authentication/Add_Root_Service_Account_for_Gigabyte_Controllers.md).
   > CMCs have component names (xnames) in the form of `xXc0sSb999`, where `X` is the cabinet and `S` is the rack U of the compute node chassis.

   Example mismatch for a CMC an Intel node blade:

   ```text
     ChassisBMCs/CMCs: FAIL
       - x3000c0s10b999 - Not found in HSM Components; Not found in HSM Redfish Endpoints; No mgmt port connection.
   ```

- Cabinet PDU Controllers have component names (xnames) in the form of `xXmM`, where `X` is the cabinet and `M` is the ordinal of the Cabinet PDU Controller.

   Example mismatch for a PDU:

   ```text
     CabinetPDUControllers: WARNING
       - x3000m0 - Not found in HSM Components ; Not found in HSM Redfish Endpoints
   ```

  If the PDU is accessible over the network, the following can be used to determine the vendor of the PDU.

   ```bash
  ncn-m001# PDU=x3000m0
  ncn-m001# curl -k -s --compressed  https://$PDU -i | grep Server:
  ```

  - Example ServerTech output:

     ```text
     Server: ServerTech-AWS/v8.0v
     ```

  - Example HPE output:

     ```text
     Server: HPE/1.4.0
     ```

  - ServerTech PDUs may need passwords changed from their defaults to become functional. See [Change Credentials on ServerTech PDUs](security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md).

  - HPE PDUs are supported and should show up as being found in HSM.
  If they are not, they should be investigated since that may indicate that configuration steps have not yet been executed which are required for the PDUs to be discovered.
  Refer to [HPE PDU Admin Procedures](hpe_pdu/hpe_pdu_admin_procedures.md) for additional configuration for this type of PDU.
  The steps to run will depend on if the PDU has been set up yet, and whether or not an upgrade or fresh install of CSM is being performed.

- BMCs having no association with a management switch port will be annotated as such, and should be investigated. Exceptions to this are in Mountain or Hill configurations where Mountain BMCs will show this condition on SLS/HSM mismatches, which is normal.
- In Hill configurations SLS assumes BMCs in chassis 1 and 3 are fully populated (32 Node BMCs), and in Mountain configurations SLS assumes all BMCs are fully populated (128 Node BMCs). Any non-populated
  BMCs will have no HSM data and will show up in the mismatch list.

If it was determined that the mismatch can not be ignored, then proceed onto the the [2.2.2 Known Issues](#hms-smd-discovery-validation-known-issues) below to troubleshoot any mismatched BMCs.

<a name="hms-smd-discovery-validation-known-issues"></a>

#### 2.2.2 Known issues with HSM discovery validation

Known issues that may prevent hardware from getting discovered by Hardware State Manager:

- [HMS Discovery job not creating Redfish Endpoints in Hardware State Manager](../troubleshooting/known_issues/discovery_job_not_creating_redfish_endpoints.md)

<a name="sms-health-checks"></a>

## 3 Software Management Services health checks

1. [SMS test execution](#sms-checks)
1. [Interpreting `cmsdev` Results](#cmsdev-results)
1. [Known issues with SMS tests](#cmsdev-known-issues)

<a name="sms-checks"></a>

### 3.1 SMS test execution

The test in this section requires that the [Cray CLI is configured](#cray-command-line-interface) on nodes where the test is executed.

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

#### `persistentvolumeclaims` not found

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

#### BOS subtest hangs

On systems where too many BOS sessions exist, the `cmsdev` test will hang when trying to list them. See
[Hang Listing BOS Sessions](../troubleshooting/known_issues/Hang_Listing_BOS_Sessions.md) for more information.

## 4. Gateway health and SSH access checks

### 4.1 Gateway health tests

#### 4.1.1 Gateway health tests overview

The gateway tests check the health of the API Gateway on all of the relevant networks. The gateway tests check that the gateway is accessible on all networks where it should be accessible,
and NOT accessible on all networks where it should NOT be accessible. They also check several service endpoints to verify that they return the proper response
on each accessible network.

The test will complete with an overall test status based on the result of the individual health checks on all of the networks.

```text
Overall Gateway Test Status:  PASS
```

For more detailed information on the tests results and examples, see [Gateway Testing](network/gateway_testing.md).

The gateway tests can be run from various locations. For this part of the CSM validation, check gateway access from the NCNs and from outside the system.
Externally, the API gateway is accessible on the CMN and either the CAN or CHN, depending on the configuration of the system.
On NCNs, the API gateway is accessible on the same networks (CMN and CAN/CHN) and it is also accessible on the NMNLB network.

#### 4.1.2 Gateway health tests on an NCN

The gateway tests may be run on any NCN with the `docs-csm` RPM installed. For details on installing the `docs-csm` RPM, see [Check for Latest Documentation](../update_product_stream/index.md#check-for-latest-documentation).

To execute the tests, see [Running Gateway Tests on an NCN Management Node](network/gateway_testing.md#running-gateway-tests-on-an-ncn-management-node).

#### 4.1.3 Gateway health tests from outside the system

To execute the tests, see [Running Gateway Tests on a Device Outside the System](network/gateway_testing.md#running-gateway-tests-on-a-device-outside-the-system).

### 4.2 Internal SSH access test execution

The internal SSH access tests may be run on any NCN with the `docs-csm` RPM installed. For details on installing the `docs-csm` RPM,
see [Check for Latest Documentation](../update_product_stream/index.md#check-for-latest-documentation).

Execute the tests by running the following command:

```bash
ncn# /usr/share/doc/csm/scripts/operations/pyscripts/start.py test_bican_internal
```

By default, SSH access will be tested on all relevant networks between master nodes and spine switches.
It is possible to customize which nodes and networks will be tested. For example, it is possible to include UANs, to exclude
master nodes, or to exclude the HMN. See the test usage statement for details. The test usage statement is displayed by calling the
test with the `--help` argument:

```bash
ncn# /usr/share/doc/csm/scripts/operations/pyscripts/start.py test_bican_internal --help
```

The test will complete with an overall pass/failure status such as the following:

```text
Overall status: PASSED (Passed: 40, Failed: 0)
```

#### 4.2.1 Known issues with internal SSH access test execution

- It is possible this test will fail if the procedure to deploy the final NCN has not been performed.

  Before running this procedure, the static IP address reservation data has not yet been loaded into the
  Hardware State Manager (HSM), so DNS records may be missing.

- After deploying the final NCN, this test may fail with an `UnresolvedHostname` error or a `CannotLoginException`.

  To work around this issue, perform the following procedure:

  1. Inspect the `cray-powerdns-manager` pod log for `Failed to patch RRsets` errors.

     ```bash
     ncn-mw# kubectl -n services logs -l app.kubernetes.io/name=cray-powerdns-manager -c cray-powerdns-manager
     ```

     Example output:

     ```text
     {"level":"error","ts":1644510069.0068583,"msg":"Failed to patch RRsets!",  "zone":"nmn.hela.dev.cray.com.",
     "error":"RRset x3000c0s6b0n0.nmn.hela.dev.cray.com. IN CNAME: Conflicts with   pre-existing RRset",
     "zone":"nmn.hela.dev.cray.com."}
     ```

  1. Identify the `cray-dns-powerdns` pod.

     ```bash
     ncn-mw# kubectl -n services get pod -l app.kubernetes.io/name=cray-dns-powerdns
     ```

     Example output:

     ```text
     NAME                                 READY   STATUS    RESTARTS   AGE
     cray-dns-powerdns-86c9685d78-bxz2z   2/2     Running   0          13d
     ```

  1. Delete the zone reported in the `cray-powerdns-manager` log output.

     In the following example command, be sure to replace `nmn.hela.dev.cray.com` with
     the actual zone identified in the earlier step.

     ```bash
     ncn-mw# kubectl -n services exec -it cray-dns-powerdns-86c9685d78-bxz2z \
                 -c cray-dns-powerdns -- pdnsutil delete-zone nmn.hela.dev.cray.com
     ```

  The `cray-powerdns-manager` reconciliation loop runs every 30 seconds, and the next run will recreate the zone with the correct records.

### 4.3 External SSH access test execution

The external SSH access tests may be run on any system external to the cluster. The tests should not be run from another system
running the Cray System Management software if that system was configured with the same internal network ranges as the system
being tested as this will cause some tests to fail.

1. Python version 3 must be installed (if it is not already).

1. Obtain the test code.

   There are two options for doing this:

    - Install the `docs-csm` RPM.

      See [Check for Latest Documentation](../update_product_stream/index.md#check-for-latest-documentation).

    - Copy over the following folder from a system where the `docs-csm` RPM is installed:

        - `/usr/share/doc/csm/scripts/operations/pyscripts`

1. Install the Python dependencies

   Run the following command from the `pyscripts` directory in order to install the required Python dependencies:

    ```bash
    external:/usr/share/doc/csm/scripts/operations/pyscripts# pip install .
    ```

1. Obtain the `admin` client secret.

   Because `kubectl` will not work outside of the cluster, obtain the `admin` client secret by running the
   following command on an NCN.

    ```bash
    ncn# kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d
    ```

    Example output:

    ```text
    26947343-d4ab-403b-14e937dbd700
    ```

1. On the external system, execute the tests.

    ```bash
    external:/usr/share/doc/csm/scripts/operations/pyscripts# ./start.py test_bican_external
    ```

    By default, SSH access will be tested on all relevant networks between master nodes and spine switches.
    It is possible to customize which nodes and networks will be tested. For example, it is possible to include compute nodes, to exclude
    spine switches, or to exclude the NMN. See the test usage statement for details. The test usage statement is displayed by calling the
    test with the `--help` argument:

    ```bash
    external:/usr/share/doc/csm/scripts/operations/pyscripts# ./start.py test_bican_external --help
    ```

1. When prompted by the test, enter the system domain and the `admin` client secret.

   The test will complete with an overall pass/failure status such as the following:

    ```text
    Overall status: PASSED (Passed: 20, Failed: 0)
    ```

<a name="booting-csm-barebones-image"></a>

## 5. Booting CSM `barebones` image

Included with the Cray System Management (CSM) release is a pre-built node image that can be used
to validate that core CSM services are available and responding as expected. The CSM Barebones
image contains only the minimal set of RPMs and configuration required to boot an image and is not
suitable for production usage. To run production work loads, it is suggested that an image from
the Cray OS (COS) product, or similar, be used.

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

<a name="csm-run-script"></a>

### 5.1 Run the test script

The script is executable and can be run without any arguments. It returns zero on success and
non-zero on failure.

```bash
ncn# /opt/cray/tests/integration/csm/barebonesImageTest
```

A successful run would generate output like the following:

```text
cray.barebones-boot-test: INFO     Barebones image boot test starting
cray.barebones-boot-test: INFO       For complete logs look in the file /tmp/cray.barebones-boot-test.log
cray.barebones-boot-test: INFO     Creating bos session with template:csm-barebones-image-test, on node:x3000c0s10b1n0
cray.barebones-boot-test: INFO     Starting boot on compute node: x3000c0s10b1n0
cray.barebones-boot-test: INFO     Found dracut message in console output - success!!!
cray.barebones-boot-test: INFO     Successfully completed barebones image boot test.
```

The script will choose an enabled compute node that is listed in the Hardware State Manager (HSM) for
the test, unless the user passes in a specific node using the `--xname` argument. If a compute node is
specified but unavailable, an available node will be used instead and a warning will be logged.

```bash
ncn# /opt/cray/tests/integration/csm/barebonesImageTest --xname x3000c0s10b4n0
```

<a name="uas-uai-tests"></a>

## 6. UAS/UAI tests

The commands in this section require that the [Cray CLI is configured](#cray-command-line-interface) on nodes where the commands are being executed.

The procedures below use the CLI as an authorized user and run on two separate node types. The first part runs on the LiveCD node, while the second part runs on a non-LiveCD
Kubernetes master or worker node.
In either case, the CLI configuration needs to be initialized on the node and the user running the procedure needs to be authorized.

The following procedures run on separate nodes of the system.

1. [Validate the basic UAS installation](#61-validate-the-basic-uas-installation)
2. [Validate UAI creation](#62-validate-uai-creation)
3. [Test UAI gateway health](#63-test-uai-gateway-health)
4. [UAS/UAI troubleshooting](#64-uas-uai-validate-debug)
   1. [Authorization issues](#641-authorization-issues)
   2. [UAS cannot access Keycloak](#642-uas-cannot-access-keycloak)
   3. [UAI images not in registry](#643-uai-images-not-in-registry)
   4. [Missing volumes and other container startup issues](#644-missing-volumes-and-other-container-startup-issues)

<a name="uas-uai-validate-install"></a>

### 6.1 Validate the basic UAS installation

This section can be run on any NCN or the PIT node.

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

1. Verify that the pre-made UAI images are registered with UAS

   ```bash
   ncn# cray uas images list --format toml
   ```

   Expected output looks similar to the following:

   ```toml
   default_image = "artifactory.algol60.net/csm-docker/stable/cray-uai-sles15sp3:1.6.0"
   image_list = [ "artifactory.algol60.net/csm-docker/stable/cray-uai-sles15sp3:1.6.0", "artifactory.algol60.net/csm-docker/stable/cray-uai-gateway-test:1.6.0", "artifactory.algol60.net/csm-docker/stable/cray-uai-broker:1.6.0",]
   ```

   This example output shows that the pre-made end-user UAI images (`artifactory.algol60.net/csm-docker/stable/cray-uai-sles15sp3:1.6.0`, `artifactory.algol60.net/csm-docker/stable/cray-uai-gateway-test:1.6.0`, and
   `artifactory.algol60.net/csm-docker/stable/cray-uai-broker:1.6.0`) are registered with UAS. This does not necessarily mean these images are installed in the container image registry, but they are configured for use.
   If other UAI images have been created and registered, they may also show up here, which is acceptable.

<a name="uas-uai-validate-create"></a>

### 6.2 Validate UAI creation

   > **IMPORTANT:** If the site does not use UAIs, skip UAS and UAI validation. If UAIs are used, there are
   > products that configure UAS like Cray Analytics and Cray Programming Environment that
   > must be working correctly with UAIs, and should be validated (the procedures for this are
   > beyond the scope of this document) prior to validating UAS and UAI. Failures in UAI creation that result
   > from incorrect or incomplete installation of these products will generally take the form of UAIs stuck in
   > waiting state trying to set up volume mounts. See the
   > [UAI Troubleshooting](#uas-uai-validate-debug) section for more information.

This procedure must run on a master or worker node (**not the PIT node**).

1. Verify that a UAI can be created:

   ```bash
   ncn# cray uas create --publickey ~/.ssh/id_rsa.pub --format toml
   ```

   Expected output looks similar to the following:

   ```toml
   uai_connect_string = "ssh vers@10.16.234.10"
   uai_host = "ncn-w001"
   uai_img = "registry.local/cray/cray-uai-sles15sp3:1.0.11"
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
   uai_img = "registry.local/cray/cray-uai-sles15sp3:1.0.11"
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

<a name="uas-uai-validate-debug"></a>

### 6.4 UAS/UAI troubleshooting

The following subsections include common failure modes seen with UAS / UAI operations and how to resolve them.

<a name="uas-uai-validate-debug-auth"></a>

#### 6.4.1 Authorization issues

An error will be returned when running CLI commands if the user is not logged in as a valid Keycloak user or is accidentally using the `CRAY_CREDENTIALS` environment variable. This variable is set regardless of the user credentials being used.

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

#### 6.4.2 UAS cannot access Keycloak

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

If the wrong hostname was used to reach the API gateway, re-run the CLI initialization steps above and try again to check that. There may also be a problem with the Istio service mesh inside of the system.
Troubleshooting this is beyond the scope of this section, but there may be useful information in the UAS pod logs in Kubernetes. There are generally two UAS pods, so the user may need to look at logs from
both to find the specific failure. The logs tend to have a very large number of `GET` events listed as part of the liveness checking.

The following shows an example of looking at UAS logs effectively (this example shows only one UAS manager, normally there would be two):

1. Determine the pod name of the `uas-mgr` pod

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

#### 6.4.3 UAI images not in registry

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
uai_img = "registry.local/cray/cray-uai-sles15sp3:1.0.11"
uai_ip = "10.103.13.172"
uai_msg = "ErrImagePull"
uai_name = "uai-vers-87a0ff6e"
uai_status = "Waiting"
username = "vers"
```

This means the pre-made end-user UAI image is not in the local registry (or whatever registry it is being pulled from; see the `uai_img` value for details). To correct
this, locate and push/import the image to the registry.

<a name="uas-uai-validate-debug-container"></a>

#### 6.4.4 Missing volumes and other container startup issues

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
