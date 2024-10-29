# Validate CSM Health

Anytime after the installation of the CSM services, the health of the management nodes and all CSM services can be validated.

The following are examples of when to run health checks:

- After completing the [Install CSM Services](../install/README.md#2-install-csm-services) step of the CSM install (**not** before)
- Before and after NCN reboots
- After the system is brought back up
- Any time there is unexpected behavior observed
- In order to provide relevant information to create support tickets

The areas should be tested in the order they are listed on this page. Errors in an earlier check may cause errors in later checks because of dependencies.

Each section of this health check document provides links to relevant troubleshooting procedures. If additional help is needed, see
[CSM Troubleshooting Information](../troubleshooting/README.md).

## Topics

- [0. Cray command line interface](#0-cray-command-line-interface)
- [1. Platform health checks](#1-platform-health-checks)
    - [1.1 NCN health checks](#11-ncn-health-checks)
    - [1.2 NCN resource checks (optional)](#12-ncn-resource-checks-optional)
    - [1.3 Check of system management monitoring tools](#13-check-of-system-management-monitoring-tools)
- [2. Hardware Management Services health checks](#2-hardware-management-services-health-checks)
    - [2.1 HMS CT test execution](#21-hms-ct-test-execution)
    - [2.2 Hardware State Manager discovery validation](#22-hardware-state-manager-discovery-validation)
        - [2.2.1 Interpreting HSM discovery results](#221-interpreting-hsm-discovery-results)
        - [2.2.2 Known issues with HSM discovery validation](#222-known-issues-with-hsm-discovery-validation)
    - [2.3 Hardware checks (optional)](#23-hardware-checks-optional)
- [3. Software Management Services health checks](#3-software-management-services-sms-health-checks)
- [4. Gateway health and SSH access checks](#4-gateway-health-and-ssh-access-checks)
    - [4.1 Gateway health tests](#41-gateway-health-tests)
        - [4.1.1 Gateway health tests overview](#411-gateway-health-tests-overview)
        - [4.1.2 Gateway health tests on an NCN](#412-gateway-health-tests-on-an-ncn)
        - [4.1.3 Gateway health tests from outside the system](#413-gateway-health-tests-from-outside-the-system)
    - [4.2 Internal SSH access test execution](#42-internal-ssh-access-test-execution)
    - [4.3 External SSH access test execution](#43-external-ssh-access-test-execution)
- [5. Booting CSM `barebones` image](#5-booting-csm-barebones-image)
    - [5.1 Run the test script](#51-run-the-test-script)

## 0. Cray command line interface

Some of the health check tests will fail if the Cray Command Line Interface (CLI) is not configured on the management NCNs.
Tests with this dependency are noted in their descriptions below. These tests may be skipped but **this is not recommended**.

If running these checks during an initial CSM install, then to find details on configuring the Cray CLI, see
[Configure the Cray command line interface](../install/configure_administrative_access.md#1-configure-the-cray-command-line-interface)
from the install documentation.

If running these checks after the initial CSM install, then to find details on configuring the Cray CLI, see
[Configure the Cray CLI](configure_cray_cli.md) from the operational documentation.

## 1. Platform health checks

All platform health checks are expected to pass. Each check has been implemented as a [Goss](https://github.com/aelsabbahy/goss) test which reports a `PASS` or `FAIL`.

If the CSM version is 1.6.0 or lower, then before running health checks, restart the `goss-servers` service on all NCNs to ensure the correct tests are run on each node. This is necessary because of a timing issue that is fixed in CSM 1.6.1.

> Skip the `goss-servers` service restart if the CSM version is 1.6.1 or above.
> The restart will cause no harm if done on CSM 1.6.1 or higher, but it is unnecessary.

Run one of the two commands below depending on if it is being executed from `ncn-m001` or from the PIT node.

- (`ncn-m001#`) Run the following from `ncn-m001` to restart `goss-servers`.

    ```bash
    ncn_nodes=$(grep -oP "(ncn-s\w+|ncn-m\w+|ncn-w\w+)" /etc/hosts | sort -u | tr -t '\n' ',')
    ncn_nodes=${ncn_nodes%,}
    pdsh -S -b -w $ncn_nodes 'systemctl restart goss-servers'
    ```

- (`pit#`) Run the following from the PIT node to restart `goss-servers`.

    ```bash
    mtoken='ncn-m(?!001)\w+-mgmt' ; stoken='ncn-s\w+-mgmt' ; wtoken='ncn-w\w+-mgmt'
    ncn_nodes=$(grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u | sed -e "s/-mgmt//" | tr -t '\n' ',')
    ncn_nodes=${ncn_nodes%,}
    pdsh -S -b -w $ncn_nodes 'systemctl restart goss-servers'
    ```

Available platform health checks:

1. [NCN health checks](#11-ncn-health-checks)
1. [OPTIONAL Check of `ncnHealthChecks` resources](#12-ncn-resource-checks-optional)
1. [Check of system management monitoring tools](#13-check-of-system-management-monitoring-tools)

### 1.1 NCN health checks

These checks require that the [Cray CLI is configured](#0-cray-command-line-interface) on all worker NCNs.

If `ncn-m001` is the PIT node, then run these checks on `ncn-m001`; otherwise run them from any master NCN.

1. (`ncn-m#` or `pit#`) Run the automated tests.

    1. If it has not been done previously, record in Vault the `admin` user password for the management switches in the system.

        See [Adding switch admin password to Vault](network/management_network/README.md#adding-switch-admin-password-to-vault).

    1. Run the combined health check script.

        This script runs a variety of health checks including:

        - Kubernetes health checks
        - NCN health checks
        - [Hardware Management Service CT tests](#21-hms-ct-test-execution)
        - [Software Management Services health checks](#3-software-management-services-sms-health-checks).

        ```bash
        /opt/cray/tests/install/ncn/automated/ncn-k8s-combined-healthcheck
        ```

1. Review results.

    Review the output and follow the instructions provided to resolve any test failures. With the exception of
    [Known issues with NCN health checks](../troubleshooting/known_issues/issues_with_ncn_health_checks.md),
    all health checks are expected to pass.

### 1.2 NCN resource checks (optional)

(`ncn-m#` or `pit#`) These optional checks display the NCN uptimes, the node resource consumptions, and/or the list of pods not in a running state.
If `ncn-m001` is the PIT node, then run these checks on `ncn-m001`; otherwise run them from any master NCN.

```bash
/opt/cray/platform-utils/ncnHealthChecks.sh -s ncn_uptimes
/opt/cray/platform-utils/ncnHealthChecks.sh -s node_resource_consumption
/opt/cray/platform-utils/ncnHealthChecks.sh -s pods_not_running
```

See [Known issues with NCN resource checks](../troubleshooting/known_issues/ncn_resource_checks.md).

### 1.3 Check of system management monitoring tools

If all designated prerequisites are met, the availability of system management health services may optionally be validated by accessing the URLs listed in
[Access System Management Health Services](system_management_health/Access_System_Management_Health_Services.md).
It is very important to check the `Prerequisites` section of this document.

If one or more of the URLs listed in the procedure are inaccessible, it does not necessarily mean that system is not healthy. It may simply mean that not all of the
prerequisites have been met to allow access to the system management health tools via URL.

Information to assist with troubleshooting some of the components mentioned in the prerequisites can be accessed here:

- [Troubleshoot CMN Issues](network/customer_accessible_networks/Troubleshoot_CMN_Issues.md)
- [Troubleshoot DNS Configuration Issues](network/external_dns/Troubleshoot_DNS_Configuration_Issues.md)
- [Check BGP Status and Reset Sessions](network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md)
- [Troubleshoot BGP not Accepting Routes from MetalLB](network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)
- [Troubleshoot Services without an Allocated IP Address](network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
- [Troubleshoot Prometheus Alerts](system_management_health/Troubleshoot_Prometheus_Alerts.md)

## 2. Hardware Management Services health checks

> The checks in this section do not require that the [Cray CLI is configured](#0-cray-command-line-interface),
> but in the case of failures, some of the tests will provide troubleshooting suggestions that involve using the CLI.

Execute the HMS tests to confirm that the Hardware Management Services are running and operational.

Note: Do not run multiple instances of the HMS tests concurrently as they may interfere with one another and cause false failures.

1. [HMS CT test execution](#21-hms-ct-test-execution)
1. [Hardware State Manager discovery validation](#22-hardware-state-manager-discovery-validation)
    1. [Interpreting HSM discovery results](#221-interpreting-hsm-discovery-results)
    1. [Known issues with HSM discovery validation](#222-known-issues-with-hsm-discovery-validation)
1. [Hardware checks (optional)](#23-hardware-checks-optional)

### 2.1 HMS CT test execution

The HMS CT tests are run automatically by the test script run in [1.1 NCN health checks](#11-ncn-health-checks).
If any failures occur, investigate the cause of each and take remediation steps if needed.

See [Interpreting HMS Health Check Results](../troubleshooting/interpreting_hms_health_check_results.md) for more information
on the tests and how to interpret their results.

### 2.2 Hardware State Manager discovery validation

By the time the CSM health validation is first performed on a system, the Hardware State Manager (HSM)
should have completed its discovery of the system. This section provides steps to verify
that discovery has completed successfully and consists of two steps.

1. Verify that all hardware attempted to be discovered by HSM was successfully discovered.

    (`ncn-mw#`) To verify that discovery completed successfully and that Redfish endpoints for the
    system hardware have been populated in HSM, run the following script:

    ```bash
    /opt/cray/csm/scripts/hms_verification/hsm_discovery_status_test.sh
    ```

    The script will return an exit code of zero if there are no failures. Otherwise, the
    script will return a non-zero exit code along with output indicating which components
    failed discovery and troubleshooting steps for determining why discovery failed.

1. Verify that all hardware that is expected to be in the system is present in HSM.

    To verify this, a comparison is made between HSM and the System Layout Service (SLS), which
    provides the foundational information for the hardware that makes up the system.

    (`ncn-mw#`) To perform this comparison, run the following script:

    ```bash
    /opt/cray/csm/scripts/hms_verification/verify_hsm_discovery.py
    ```

    The script will have an exit code of 0 if there are no failures. If there is
    any FAIL information displayed, the script will exit with a non-zero exit
    code.

    Example of successful output:

    ```text
    HSM Cabinet Summary
    ===================
    x1000 (Mountain)
      Discovered Nodes:          16
      Discovered Node BMCs:       5
      Discovered Router BMCs:    16
      Discovered Chassis BMCs:    8
      Compute Module slots
        Populated:   5
        Empty:      59
      Router Module slots
        Populated:  16
        Empty:      48
    x3000 (River)
      Discovered Nodes:          12 (10 Mgmt, 2 Application, 0 Compute)
      Discovered Node BMCs:      11
      Discovered Router BMCs:     2
      Discovered Chassis BMCs:    0
      Discovered Cab PDU Ctlrs:   2
      Discovered CMCs:            0

    River Cabinet Checks
    ============================
    x3000 (River)
      Nodes: PASS
      NodeBMCs: PASS
      RouterBMCs: PASS
      CMCs: PASS
      CabinetPDUControllers: PASS

    Mountain/Hill Cabinet Checks
    ============================
    x1000 (Mountain)
      ChassisBMCs: PASS
      Nodes: PASS
      NodeBMCs: PASS
      RouterBMCs: PASS

    EX2500 Cabinet Checks
    ============================
    None Found.
    ```

    Refer to [2.2.1 Interpreting results](#221-interpreting-hsm-discovery-results) and
    [2.2.2 Known Issues](#222-known-issues-with-hsm-discovery-validation) in order to
    troubleshoot any errors or warnings.

#### 2.2.1 Interpreting HSM discovery results

The Cabinet Checks output is divided into four sections:

- Summary information for each cabinet.
- Detail information for River cabinets.
- Detail information for Mountain/Hill cabinets.
- Detail information for EX2500 cabinets.

In the River section, any hardware found in SLS and not discovered by HSM is
considered a failure.

In the Mountain/Hill section, the only thing considered a failures are Chassis BMCs
that are not discovered in HSM, and undiscovered BMCs from populated slots.

In the EX2500 section, performs checks for both air-cooled and liquid-cooled hardware
based on the chassis. For the liquid-cooled chassis the only thing considered a failures
are Chassis BMCs that are not discovered in HSM, and undiscovered BMCs from populated slots.
In the air-cooled chassis (if present) any hardware found in SLS and not discovered by HSM is
considered a failure.

Any failures need to be investigated by the admin for rectification. Any
warnings should also be examined by the administrator to ensure they are accurate and
expected.

For each of the BMCs that show up as not being present in HSM components or
Redfish Endpoints use the following notes to determine whether the issue with the
BMC can be safely ignored or needs to be addressed before proceeding.

- The node BMCs for HPE Apollo XL645D nodes may report as a mismatch depending on the state of the system when the `verify_hsm_discovery.py` script is run. If the system is currently going through the
  process of installation, then this is an expected mismatch as the [Prepare Compute Nodes](../install/prepare_compute_nodes.md) procedure required to configure the BMC of the HPE Apollo 6500 XL645D node
  may not have been completed yet.
   > For more information refer to [Configure HPE Apollo 6500 XL645D Gen10 Plus Compute Nodes](../install/prepare_compute_nodes.md#configure-hpe-apollo-6500-xl645d-gen10-plus-compute-nodes) for additional required configuration for this type of BMC.

   Example mismatch for the BMC of an HPE Apollo XL654D:

   ```text
     Nodes: FAIL
       - x3000c0s30b1n0 (Compute, NID 5) - Not found in HSM Components.
     NodeBMCs: FAIL
       - x3000c0s19b1 - Not found in HSM Components; Not found in HSM Redfish Endpoints.
   ```

- Chassis Management Controllers (CMC) may show up as not being present in HSM. Gigabyte node blade CMCs not found in HSM is not normal and should be investigated.
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

    (`ncn#`) If the PDU is accessible over the network, the following can be used to determine the vendor of the PDU.

    ```bash
    PDU=x3000m0
    curl -k -s --compressed  https://$PDU -i | grep Server:
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

- River BMCs having no association with a management switch port will be annotated as such, and should be investigated.

- In Hill configurations SLS assumes BMCs in chassis 1 and 3 are fully populated (32 Node BMCs), and in Mountain configurations SLS assumes all BMCs are fully populated (128 Node BMCs). For EX2500 cabinets will have either 1, 2, or 3 fully populated
  chassis depending on how the cabinet is configured. BMCs from non-populated chassis slots will not show up in the mismatch list. Any BMCs missing in populated chassis slots with no HSM data and will show up in the mismatch list.

If it was determined that the mismatch can not be ignored, then proceed onto the [2.2.2 Known Issues](#222-known-issues-with-hsm-discovery-validation) below to troubleshoot any mismatched BMCs.

#### 2.2.2 Known issues with HSM discovery validation

Known issues that may prevent hardware from getting discovered by Hardware State Manager:

- All management network switches including Spine switches, CDU switches, and those with River cabinets, require SNMP to be enabled for discovery to work.
  For configuring SNMP, see [Configure SNMP](network/management_network/configure_snmp.md).
- [HMS Discovery job not creating Redfish Endpoints in Hardware State Manager](../troubleshooting/known_issues/discovery_job_not_creating_redfish_endpoints.md)

### 2.3 Hardware checks (optional)

Optionally, these checks may be executed to detect problems with hardware in the system. Hardware check failures
are **not** blockers for system installations and upgrades, and it is typically safe to postpone the investigation
and resolution of any such failures until after the CSM installation or upgrade has completed.

These checks may be executed on any one worker or master NCN (but **not** `ncn-m001` if it is still the PIT node).

(`ncn-mw#`) Run the hardware checks.

```bash
/opt/cray/csm/scripts/hms_verification/run_hardware_checks.sh
```

The return code of the script is zero if all hardware checks run and pass, non-zero if not.
On errors or failures, the script will print the path to the hardware checks log file for the administrator to inspect.
See the [Flags Set For Nodes In HSM](../troubleshooting/known_issues/flags_set_for_nodes_in_hsm.md) documentation for more information about common types of hardware check failures.

## 3 Software Management Services (SMS) health checks

The SMS health checks are run automatically by the test script run in [1.1 NCN health checks](#11-ncn-health-checks).
If any failures occur, investigate the cause of each and take remediation steps if needed.

See [Software Management Services health checks](../troubleshooting/known_issues/sms_health_check.md) for more information
on the tests and how to interpret their results.

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

For more detailed information on the tests results and examples, see [Gateway Testing](network/Gateway_Testing.md).

The gateway tests can be run from various locations. For this part of the CSM validation, check gateway access from the NCNs and from outside the system.
Externally, the API gateway is accessible on the CMN and either the CAN or CHN, depending on the configuration of the system.
On NCNs, the API gateway is accessible on the same networks (CMN and CAN/CHN) and it is also accessible on the NMNLB network.

#### 4.1.2 Gateway health tests on an NCN

The gateway tests may be run on any NCN with the `docs-csm` RPM installed. For details on installing the `docs-csm` RPM,
see [Check for Latest Documentation](../update_product_stream/README.md#check-for-latest-documentation).

To execute the tests, see [Running Gateway Tests on an NCN Management Node](network/Gateway_Testing.md#running-gateway-tests-on-an-ncn-management-node).

#### 4.1.3 Gateway health tests from outside the system

To execute the tests, see [Running Gateway Tests on a Device Outside the System](network/Gateway_Testing.md#running-gateway-tests-on-a-device-outside-the-system).

### 4.2 Internal SSH access test execution

The internal SSH access tests may be run on any NCN with the `docs-csm` RPM installed. For details on installing the `docs-csm` RPM,
see [Check for Latest Documentation](../update_product_stream/README.md#check-for-latest-documentation).

(`ncn#`) Execute the tests by running the following command:

```bash
/usr/share/doc/csm/scripts/operations/pyscripts/start.py test_bican_internal
```

By default, SSH access will be tested on all relevant networks between master nodes and spine switches.
It is possible to customize which nodes and networks will be tested. For example, it is possible to include UANs, to exclude
master nodes, or to exclude the HMN. See the test usage statement for details.

(`ncn#`) The test usage statement is displayed by calling the test with the `--help` argument:

```bash
/usr/share/doc/csm/scripts/operations/pyscripts/start.py test_bican_internal --help
```

The test will complete with an overall pass/failure status such as the following:

```text
Overall status: PASSED (Passed: 40, Failed: 0)
```

### 4.3 External SSH access test execution

The external SSH access tests may be run on any system external to the cluster. The tests should not be run from another system
running the Cray System Management software if that system was configured with the same internal network ranges as the system
being tested as this will cause some tests to fail.

1. (`external#`) Python version 3 must be installed (if it is not already).

1. (`external#`) Obtain the test code.

   There are two options for doing this:

    - Install the `docs-csm` and `libcsm` RPMs.

      See [Check for Latest Documentation](../update_product_stream/README.md#check-for-latest-documentation).

    - Copy over the following folder from a system where the `docs-csm` and `libcsm` RPMs are installed:

        - `/usr/share/doc/csm/scripts/operations/pyscripts`

1. (`external#`) Install the Python dependencies.

   Run the following command from the `pyscripts` directory in order to install the required Python dependencies:

    ```bash
    cd /usr/share/doc/csm/scripts/operations/pyscripts && pip install .
    ```

1. (`ncn#` or `pit#`) Obtain the `admin` client secret.

   Because `kubectl` will not work outside of the cluster, obtain the `admin` client secret by running the
   following command on an NCN or the PIT node.

    ```bash
    kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d
    ```

    Example output:

    ```text
    26947343-d4ab-403b-14e937dbd700
    ```

1. (`external#`) On the external system, execute the tests.

    ```bash
    cd /usr/share/doc/csm/scripts/operations/pyscripts && ./start.py test_bican_external
    ```

    By default, SSH access will be tested on all relevant networks between master nodes and spine switches.
    It is possible to customize which nodes and networks will be tested. For example, it is possible to include compute nodes, to exclude
    spine switches, or to exclude the NMN. See the test usage statement for details.

    The test usage statement is displayed by calling the test with the `--help` argument:

    ```bash
    cd /usr/share/doc/csm/scripts/operations/pyscripts && ./start.py test_bican_external --help
    ```

1. When prompted by the test, enter the system domain and the `admin` client secret.

   The test will complete with an overall pass/failure status such as the following:

    ```text
    Overall status: PASSED (Passed: 20, Failed: 0)
    ```

## 5. Booting CSM barebones image

This test is **very important to run**, particularly during the CSM install prior to rebooting the PIT node,
because it validates all of the services required for nodes to PXE boot from the cluster.

By default the test automatically chooses an enabled x86 compute node and an x86 barebones compute image.
This image is customized and used to boot the chosen node. This default behavior can be overridden, however.
For additional details and troubleshooting information, see
[Barebones Image Boot Test](../troubleshooting/cms_barebones_image_boot.md).

### 5.1 Run the test script

This test can be run on any master or worker NCN, but not the PIT node.

(`ncn-mw#`) The script is executable and can be run without any arguments. It returns zero on success and
non-zero on failure.

```bash
/opt/cray/tests/integration/csm/barebones_image_test
```

The end of successful test output will resemble the following:

```text
cray.barebones-boot-test: INFO     Successfully completed barebones image boot test.
```
