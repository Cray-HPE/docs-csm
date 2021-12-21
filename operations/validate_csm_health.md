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

- [Validate CSM Health](#validate-csm-health)
  - [Topics:](#topics)
  - [1. Platform Health Checks](#platform-health-checks)
    - [1.1 ncnHealthChecks](#pet-ncnhealthchecks)
      - [1.1.1 Known Test Issues](#autogoss-issues)
    - [1.2 OPTIONAL Check of ncnHealthChecks Resources](#pet-ncnhealthchecks-resources)
      - [1.2.1 Known Issues](#known-issues)
    - [1.3 Check of System Management Monitoring Tools](#check-of-system-management-monitoring-tools)
  - [2. Hardware Management Services Health Checks](#hms-health-checks)
    - [2.1 HMS CT Test Execution](#hms-test-execution)
    - [2.2 Aruba Switch SNMP Fixup](#hms-aruba-fixup)
    - [2.3 Hardware State Manager Discovery Validation](#hms-smd-discovery-validation)
      - [2.3.1 Interpreting results](#hms-smd-discovery-validation-interpreting-results)
      - [2.3.2 Known Issues](#hms-smd-discovery-validation-known-issues)
  - [3 Software Management Services Health Checks](#sms-health-checks)
    - [3.1 SMS Test Execution](#sms-checks)
    - [3.2 Interpreting cmsdev Results](#cmsdev-results)
  - [4. Booting CSM Barebones Image](#booting-csm-barebones-image)
    - [4.1 Running the script](#csm-run-script)
  - [5. UAS / UAI Tests](#uas-uai-tests)
    - [5.1 Validate the Basic UAS Installation](#uas-uai-validate-install)
    - [5.2 Validate UAI Creation](#uas-uai-validate-create)
    - [5.3 UAS/UAI Troubleshooting](#uas-uai-validate-debug)
      - [5.3.1 Authorization Issues](#uas-uai-validate-debug-auth)
      - [5.3.2 UAS Cannot Access Keycloak](#uas-uai-validate-debug-keycloak)
      - [5.3.3 UAI Images not in Registry](#uas-uai-validate-debug-registry)
      - [5.3.4 Missing Volumes and other Container Startup Issues](#uas-uai-validate-debug-container)

<a name="platform-health-checks"></a>
## 1. Platform Health Checks

All platform health checks are expected to pass. Each check has been implemented as a [Goss](https://github.com/aelsabbahy/goss) test which reports a PASS or FAIL.

Health Check scripts can be run:
* After CSM install.sh has been run (not before)
* Before and after one of the NCNs reboots
* After the system or a single node goes down unexpectedly
* After the system is gracefully shut down and brought up
* Any time there is unexpected behavior on the system to get a baseline of data for CSM services and components
* In order to provide relevant information to support tickets that are being opened after CSM install.sh has been run

Available Platform Health Checks:
1. [ncnHealthChecks](#pet-ncnhealthchecks)
1. [OPTIONAL Check of ncnHealthChecks Resources](#pet-optional-ncnhealthchecks-resources)
1. [Check of System Management Monitoring Tools](#check-of-system-management-monitoring-tools)

<a name="pet-ncnhealthchecks"></a>
### 1.1 ncnHealthChecks

There are multiple Goss test suites available that cover a variety of subsystems. The platform health checks are defined in the test suites `ncn-healthcheck` and `ncn-kubernetes-checks`.

Run the NCN health checks with the following command (If m001 is the PIT node, run on the PIT, otherwise run from any NCN):

**IMPORTANT:** Do not run these as part of upgrade testing. This includes the Kubernetes check in the next block.

```bash
# /opt/cray/tests/install/ncn/automated/ncn-healthcheck
```

And the Kubernetes test suite via:

```bash
# /opt/cray/tests/install/ncn/automated/ncn-kubernetes-checks
```

Review the output for `Result: FAIL` and follow the instructions provided to resolve any such test failures. With the exception of the [Known Test Issues](#autogoss-issues), all health checks are expected to pass.

<a name="autogoss-issues"></a>
#### 1.1.1 Known Test Issues

* Kubernetes Query BSS Cloud-init for ca-certs
  - This test may fail immediately after platform install. It should pass after the TrustedCerts Operator has updated BSS (Global cloud-init meta) with CA certificates.
* Kubernetes Velero No Failed Backups
  - Because of a [known issue](https://github.com/vmware-tanzu/velero/issues/1980) with Velero, a backup may be attempted immediately upon the deployment of a backup schedule (for example, vault). It may be necessary to use the `velero` command to delete backups from a Kubernetes node to clear this situation. See the output of the test for more details on how to cleanup backups that have failed due to a known interruption.
* Verify spire-agent is enabled and running

  - The `spire-agent` service may fail to start on Kubernetes NCNs (all worker nodes and master nodes), logging errors (via journalctl) similar to "join token does not exist or has already been used" or the last logs containing multiple lines of "systemd[1]: spire-agent.service: Start request repeated too quickly.". Deleting the `request-ncn-join-token` daemonset pod running on the node may clear the issue. Even though the `spire-agent` systemctl service on the Kubernetes node should eventually restart cleanly, the user may have to log in to the impacted nodes and restart the service. The following recovery procedure can be run from any Kubernetes node in the cluster.
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


<a name="pet-optional-ncnhealthchecks-resources"></a>
### 1.2 OPTIONAL Check of ncnHealthChecks Resources

To dump the ncn uptimes, the node resource consumptions and/or the list of pods not in a running state, run the following:

```bash
ncn# /opt/cray/platform-utils/ncnHealthCheck.sh -s ncn_uptimes
ncn# /opt/cray/platform-utils/ncnHealthCheck.sh -s node_resource_consumption
ncn# /opt/cray/platform-utils/ncnHealthCheck.sh -s pods_not_running
```
<a name="known-issues"></a>
#### 1.2.1 Known Issues

* pods_not_running
  - If the output of `pods_not_running` indicates that there are pods in the `Evicted` state, it may be due to the root file system being filled up on the Kubernetes node in question. Kubernetes will begin evicting pods once the root file system space is at 85% until it is back under 80%. This may commonly happen on ncn-m001 as it is a location that install and doc files may be downloaded to. It may be necessary to clean up space in the / directory if this is the root cause of pod evictions. The following commands can be used to determine if analysis of files under / is needed to free-up space. Listing the top 10 files that are 1024M or larger is one way to start the analysis.

    ```bash
    ncn# df -h /
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
  - The `cray-crus-` pod is expected to be in the Init state until Slurm and MUNGE
are installed. In particular, this will be the case if executing this as part of the validation after completing the [Install CSM Services](../install/install_csm_services.md).
If in doubt, validate the CRUS service using the [CMS Validation Tool](#sms-health-checks). If the CRUS check passes using that tool, do not worry about the `cray-crus-` pod state.
  - The `hmn-discovery` and `cray-dns-unbound-manager` cronjob pods may be in a 'NotReady' state. This is expected as these pods are periodically started and transition to the completed state.


<a name="check-of-system-management-monitoring-tools"></a>
### 1.3 Check of System Management Monitoring Tools

If all designated prerequisites are met, the availability of system management health services may optionally be validated by accessing the URLs listed in [Access System Management Health Services](system_management_health/Access_System_Management_Health_Services.md).
It is very important to check the `Prerequisites` section of this document.

If one or more of the the URLs listed in the procedure are inaccessible, it does not necessarily mean that system is not healthy. It may simply mean that not all of the prerequisites have been met to allow access to the system management health tools via URL.

Information to assist with troubleshooting some of the components mentioned in the prerequisites can be accessed here:
* [Troubleshoot CAN Issues](network/customer_access_network/Troubleshoot_CAN_Issues.md)
* [Troubleshoot DNS Configuration Issues](network/external_dns/Troubleshoot_DNS_Configuration_Issues.md)
* [Check BGP Status and Reset Sessions](network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md)
* [Troubleshoot BGP not Accepting Routes from MetalLB](network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)
* [Troubleshoot Services without an Allocated IP Address](network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
* [Troubleshoot Prometheus Alerts](system_management_health/Troubleshoot_Prometheus_Alerts.md)


<a name="hms-health-checks"></a>
## 2. Hardware Management Services Health Checks

Execute the HMS smoke and functional tests after the CSM install to confirm that the Hardware Management Services are running and operational.

Note: Do not run HMS tests concurrently on multiple nodes. They may interfere with one another and cause false failures.

<a name="hms-test-execution"></a>
### 2.1 HMS CT Test Execution

These tests should be executed as root on at least one worker NCN and one master NCN (but **not** ncn-m001 if it is still the PIT node).

Run the HMS CT smoke tests.  This is done by running the `run_hms_ct_tests.sh` script:

```
ncn# /opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh
```

The return value of the script is 0 if all CT tests ran successfully, non-zero
if not.  On CT test failures the script will instruct the admin to look at the
CT test log files.  If one or more failures occur, investigate the cause of
each failure. See the [interpreting_hms_health_check_results](../troubleshooting/interpreting_hms_health_check_results.md) documentation for more information.

<a name="hms-aruba-fixup"></a>
### 2.2 Aruba Switch SNMP Fixup

Systems with Aruba leaf switches sometimes have issues with a known SNMP bug
which prevents HSM discovery from discovering all HW.  At this stage of the
installation process, a script can be run to detect if this issue is 
currently affecting the system, and if so, correct it.

Refer to [Air cooled hardware is not getting properly discovered with Aruba leaf switches](../troubleshooting/known_issues/discovery_aruba_snmp_issue.md) for 
details.

<a name="hms-smd-discovery-validation"></a>
### 2.3 Hardware State Manager Discovery Validation

By this point in the installation process, the Hardware State Manager (HSM) should
have done its discovery of the system.

The foundational information for this discovery is from the System Layout Service (SLS). Thus, a
comparison needs to be done to see that what is specified in SLS (focusing on
BMC components and Redfish endpoints) are present in HSM.

To perform this comparison execute the `verify_hsm_discovery.py` script on a Kubernetes master or worker NCN.  The result is pass/fail (returns 0 or non-zero):

```
ncn# /opt/cray/csm/scripts/hms_verification/verify_hsm_discovery.py
```

The output will ideally appear as follows, if there are mismatches these will be displayed in the appropriate section of
the output. Refer to [2.3.1 Interpreting results](#hms-smd-discovery-validation-interpreting-results) and
[2.3.2 Known Issues](#hms-smd-discovery-validation-known-issues) below to troubleshoot any mismatched BMCs.
```bash
ncn# /opt/cray/csm/scripts/hms_verification/verify_hsm_discovery.py

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

The script will have an exit code of 0 if there are no failures.  If there is
any FAIL information displayed, the script will exit with a non-zero exit
code.  Failure information interpretation is described in the next section.

<a name="hms-smd-discovery-validation-interpreting-results"></a>
#### 2.3.1 Interpreting results

The Cabinet Checks output is divided into three sections:

* Summary information for for each cabinet
* Detail information for for River cabinets
* Detail information for Mountain/Hill cabinets.

In the River section, any hardware found in SLS and not discovered by HSM is
considered a failure, with the exception of PDU controllers, which is a
warning.  Also, the BMC of one of the management NCNs (typically 'ncn-m001')
will not be connected to the HSM HW network and thus will show up as being not
discovered and/or not having any mgmt network connection.  This is treated as
a warning.

In the Mountain section, the only thing considered a failure are Chassis BMCs
that are not discovered in HSM.   All other items (nodes, node BMCs and router
BMCs) which are not discovered are considered warnings.

Any failures need to be investigated by the admin for rectification.  Any
warnings should also be examined by the admin to insure they are accurate and
expected.

For each of the BMCs that show up as not being present in HSM components or
Redfish Endpoints use the following notes to determine if the issue with the
BMC can be safely ignored, or if there is a legitimate issue with the BMC.

* The node BMC of 'ncn-m001' will not typically be present in HSM component data, as it is typically connected to the site network instead of the HMN network.

* The node BMCs for HPE Apollo XL645D nodes may report as a mismatch depending on the state of the system when the `hsm_discovery_verify.sh` script is run. If the system is currently going through the process of installation, then this is an expected mismatch as the [Prepare Compute Nodes](../install/prepare_compute_nodes.md) procedure required to configure the BMC of the HPE Apollo 6500 XL645D node may not have been completed yet. 
   > For more information refer to [Configure HPE Apollo 6500 XL645d Gen10 Plus Compute Nodes](../install/prepare_compute_nodes.md#configure-hpe-apollo-6500-x645d-gen10-plus-compute-nodes) for additional required configuration for this type of BMC.

   Example mismatch for the BMC of a HPE Apollo XL654D:
   ```bash
   ...
     Nodes: FAIL
       - x3000c0s30b1n0 (Compute, NID 5) - Not found in HSM Components.
     NodeBMCs: FAIL
       - x3000c0s19b1 - Not found in HSM Components; Not found in HSM Redfish Endpoints.
   ...
   ```

* Chassis Management Controllers (CMC) may show up as not being present in HSM. CMCs for Intel server blades can be ignored. Gigabyte server blade CMCs not found in HSM is not normal and should be investigated. If a Gigabyte CMC is expected to not be connected to the HMN network, then it can be ignored.
   > CMCs have xnames in the form of `xXc0sSb999`, where `X` is the cabinet and `S` is the rack U of the compute node chassis.

   Example mismatch for a CMC an Intel server blade:
```bash
...
  ChassisBMCs/CMCs: FAIL
    - x3000c0s10b999 - Not found in HSM Components; Not found in HSM Redfish Endpoints; No mgmt port connection.
...
```

* HPE PDUs are not supported at this time and will likely show up as not being found in HSM. They can be ignored.
   > Cabinet PDU Controllers have xnames in the form of `xXmM`, where `X` is the cabinet and `M` is the ordinal of the Cabinet PDU Controller.

   Example mismatch for HPE PDU:
```bash
...
  CabinetPDUControllers: WARNING
    - x3000m0 - Not found in HSM Components ; Not found in HSM Redfish Endpoints
...
```

* BMCs having no association with a management switch port will be annotated as such, and should be investigated. Exceptions to this are in Mountain or Hill configurations where Mountain BMCs will show this condition on SLS/HSM mismatches, which is normal.

* In Hill configurations SLS assumes BMCs in chassis 1 and 3 are fully populated (32 Node BMCs), and in Mountain configurations SLS assumes all BMCs are fully populated (128 Node BMCs). Any non-populated BMCs will have no HSM data and will show up in the mismatch list.

If it was determined that the mismatch can not be ignored, then proceed onto the the [2.3.2 Known Issues](#hms-smd-discovery-validation-known-issues) below to troubleshoot any mismatched BMCs.

<a name="hms-smd-discovery-validation-known-issues"></a>
#### 2.3.2 Known Issues

Known issues that may prevent hardware from getting discovered by Hardware State Manager:
* [Air cooled hardware is not getting properly discovered with Aruba leaf switches](../troubleshooting/known_issues/discovery_aruba_snmp_issue.md)
* [HMS Discovery job not creating RedfishEndpoints in Hardware State Manager](../troubleshooting/known_issues/discovery_job_not_creating_redfish_endpoints.md)

<a name="sms-health-checks"></a>
## 3 Software Management Services Health Checks

The Software Management Services health checks are run using `/usr/local/bin/cmsdev`.

* The tool logs to `/opt/cray/tests/cmsdev.log`
* The -q (quiet) and -v (verbose) flags can be used to decrease or increase the amount of information sent to the screen.
  * The same amount of data is written to the log file in either case.

1. [SMS Test Execution](#sms-checks)
1. [Interpreting cmsdev Results](#cmsdev-results)

<a name="sms-checks"></a>
### 3.1 SMS Test Execution

The following test can be run on any Kubernetes node (any master or worker node, but **not** the PIT node).

```bash
ncn# /usr/local/bin/cmsdev test -q all
```

<a name="cmsdev-results"></a>
### 3.2 Interpreting cmsdev Results

If all checks passed:
   * The return code will be 0
   * The final line of output will begin with `SUCCESS`
   * For example:
        ```bash
        ncn# /usr/local/bin/cmsdev test -q all
        ...
        SUCCESS: All 7 service tests passed: bos, cfs, conman, crus, ims, tftp, vcs
        ncn# echo $?
        0
        ```

If one or more checks failed:
   * The return code will be non-0
   * The final line of output will begin with `FAILURE` and will list which checks failed
   * For example:
        ```bash
        ncn# /usr/local/bin/cmsdev test -q all
        ...
        FAILURE: 2 service tests FAILED (conman, ims), 5 passed (bos, cfs, crus, tftp, vcs)
        ncn# echo $?
        1
        ```

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

* This test is **very important to run** during the CSM install prior to redeploying the PIT node
because it validates all of the services required for that operation.
* The CSM Barebones image included with the release will not successfully complete
beyond the dracut stage of the boot process. However, if the dracut stage is reached, the
boot can be considered successful and shows that the necessary CSM services needed to
boot a node are up and available.
   * This inability to boot the barebones image fully will be resolved in future releases of the
CSM product.
* In addition to the CSM Barebones image, the release also includes an IMS Recipe that
can be used to build the CSM Barebones image. However, the CSM Barebones recipe currently requires
RPMs that are not installed with the CSM product. The CSM Barebones recipe can be built after the
Cray OS (COS) product stream is also installed on to the system.
   * In future releases of the CSM product, work will be undertaken to resolve these dependency issues.
* This procedure can be followed on any NCN or the PIT node.
* This script uses the Kubernetes API Gateway to access CSM services. This gateway must be properly
configured to allow an access token to be generated by the script.
* This script is installed as part of the 'cray-cmstools-crayctldeploy' RPM.
* For additional information on the script and for troubleshooting help look at the document
[Barebones Image Boot](../troubleshooting/cms_barebones_image_boot.md).
---

1. [Running the script](#csm-run-script)

<a name="csm-run-script"></a>
### 4.1 Run the Test Script

The script is executable and can be run without any arguments. It returns 0 on success and
non-zero on failure.

```bash
ncn# /opt/cray/tests/integration/csm/barebonesImageTest
```

A successful run would generate output like the following:
```bash
ncn# /opt/cray/tests/integration/csm/barebonesImageTest
cray.barebones-boot-test: INFO     Barebones image boot test starting
cray.barebones-boot-test: INFO       For complete logs look in the file /tmp/cray.barebones-boot-test.log
cray.barebones-boot-test: INFO     Creating bos session with template:csm-barebones-image-test, on node:x3000c0s10b1n0
cray.barebones-boot-test: INFO     Starting boot on compute node: x3000c0s10b1n0
cray.barebones-boot-test: INFO     Found dracut message in console output - success!!!
cray.barebones-boot-test: INFO     Successfully completed barebones image boot test.
```

The script will choose an enabled compute node that is listed in the Hardware State Manager (HSM) for
the test unless the user passes in a specific node using the `--xname` argument. If a compute node is
specified but unavailable, an available node will be used instead and a warning will be logged.

```bash
ncn# /opt/cray/tests/integration/csm/barebonesImageTest --xname x3000c0s10b4n0
```

<a name="uas-uai-tests"></a>
## 5. UAS / UAI Tests

The procedures below use the CLI as an authorized user and run on two separate node types. The first part runs on the LiveCD node, while the second part runs on a non-LiveCD Kubernetes master or worker node. When using the CLI on either node, the CLI configuration needs to be initialized and the user running the procedure needs to be authorized.

The following procedures run on separate nodes of the system. They are, therefore, separated into separate sub-sections.

1. [Validate Basic UAS Installation](#uas-uai-validate-install)
1. [Validate UAI Creation](#uas-uai-validate-create)
1. [UAS/UAI Troubleshooting](#uas-uai-validate-debug)
   1. [Authorization Issues](#uas-uai-validate-debug-auth)
   1. [UAS Cannot Access Keycloak](#uas-uai-validate-debug-keycloak)
   1. [UAI Images not in Registry](#uas-uai-validate-debug-registry)
   1. [Missing Volumes and Other Container Startup Issues](#uas-uai-validate-debug-container)

<a name="uas-uai-validate-install"></a>
### 5.1 Validate the Basic UAS Installation

This section can be run on any NCN or the PIT node.

1. Initialize the Cray CLI on the node where you are running this section. See [Configure the Cray Command Line Interface](configure_cray_cli.md) for details on how to do this.

1. Basic UAS installation is validated using the following:
   1.
      ```bash
      ncn# cray uas mgr-info list
      ```

      Expected output looks similar to the following:
      ```
      service_name = "cray-uas-mgr"
      version = "1.11.5"
      ```

      In this example output, it shows that UAS is installed and running the `1.11.5` version.
   1.
      ```bash
      ncn# cray uas list
      ```

      Expected output looks similar to the following:
      ```
      results = []
      ```

     This example output shows that there are no currently running UAIs. It is possible, if someone else has been using the UAS, that there could be UAIs in the list. That is acceptable too from a validation standpoint.
1. Verify that the pre-made UAI images are registered with UAS
   ```bash
   ncn# cray uas images list
   ```

   Expected output looks similar to the following:
   ```
   default_image = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
   image_list = [ "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest",]
   ```

   This example output shows that the pre-made end-user UAI image (`cray/cray-uai-sles15sp1:latest`) is registered with UAS. This does not necessarily mean this image is installed in the container image registry, but it is configured for use. If other UAI images have been created and registered, they may also show up here, which is acceptable.

<a name="uas-uai-validate-create"></a>
### 5.2 Validate UAI Creation

   > **`IMPORTANT:`** If you are upgrading CSM and your site does not use UAIs, skip UAS and UAI validation.
   > If you do use UAIs, there are products that configure UAS like Cray Analytics and Cray Programming
   > Environment. These must be working correctly with UAIs and should be validated and corrected (the
   > procedures for this are beyond the scope of this document) prior to validating UAS and UAI. Failures
   > in UAI creation that result from incorrect or incomplete installation of these products will generally
   > take the form of UAIs stuck in 'waiting' state trying to set up volume mounts. See the
   > [UAI Troubleshooting](#uas-uai-validate-debug) section for more information.

This procedure must run on a master or worker node (not the PIT node and not `ncn-w001`) on the system. (It is also possible to do from an external host, but the procedure for that is not covered here).

1. Initialize the Cray CLI on the node where you are running this section. See [Configure the Cray Command Line Interface](configure_cray_cli.md) for details on how to do this.

1. Verify that a UAI can be created:
   ```bash
   ncn# cray uas create --publickey ~/.ssh/id_rsa.pub
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

1. Set `UAINAME` to the value of the `uai_name` field in the previous command output (`uai-vers-a00fb46b` in our example):
   ```bash
   ncn# UAINAME=uai-vers-a00fb46b
   ```

1. Check the current status of the UAI:
   ```bash
   ncn# cray uas list
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

1. Log out from the UAI
   ```bash
   vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> exit
   ncn#
   ```

1. Clean up the UAI.
   ```bash
   ncn# cray uas delete --uai-list $UAINAME
   ```

   Expected output looks similar to the following:
   ```
   results = [ "Successfully deleted uai-vers-a00fb46b",]
   ```

If the commands ran with similar results, then the basic functionality of the UAS and UAI is working.

<a name="uas-uai-validate-debug"></a>
### 5.3 UAS/UAI Troubleshooting

The following subsections include common failure modes seen with UAS / UAI operations and how to resolve them.

<a name="uas-uai-validate-debug-auth"></a>
#### 5.3.1 Authorization Issues

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
#### 5.3.2 UAS Cannot Access Keycloak

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
#### 5.3.3 UAI Images not in Registry

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
#### 5.3.4 Missing Volumes and other Container Startup Issues

Various packages install volumes in the UAS configuration. All of those volumes must also have the underlying resources available, sometimes on the host node where the UAI is running sometimes from with Kubernetes. If a UAI gets stuck with a `ContainerCreating` `uai_msg` field for an extended time, this is a likely cause. UAIs run in the `user` Kubernetes namespace, and are pods that can be examined using `kubectl describe`.

1. Locate the pod.

   ```bash
   ncn# kubectl get po -n user | grep <uai-name>
   ```

2. Investigate the problem using the pod name from the previous step.

   ```bash
   ncn# kubectl describe pod -n user <pod-name>
   ```

   If volumes are missing they will show up in the `Events:` section of the output. Other problems may show up there as well. The names of the missing volumes or other issues should indicate what needs to be fixed to make the UAI run.
