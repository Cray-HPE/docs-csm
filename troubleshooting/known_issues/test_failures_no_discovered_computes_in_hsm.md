# Test Failures Due To No Discovered Compute Nodes In HSM

## Table of contents

- [Introduction](#introduction)
- [Check For Discovered Compute Nodes](#check-for-discovered-compute-nodes)
- [Troubleshooting](#troubleshooting)

## Introduction

This document describes how to troubleshoot CSM validation test failures due to no discovered compute nodes in HSM.

## Check For Discovered Compute Nodes

1. (`ncn-mw#`) Confirm that there are no discovered compute nodes in HSM.

    ```bash
    cray hsm state components list --type Node --role compute --format json
    ```

    Example output:

    ```text
    {
      "Components": []
    }
    ```

## Troubleshooting

There are several reasons why there may be no discovered compute nodes in HSM.

The following situations do not warrant additional troubleshooting and related test failures can be safely ignored if:

- There is no compute hardware physically connected to the system
- All compute hardware in the system is powered off

If none of the above cases are applicable, then the test failures warrant additional troubleshooting:

1. (`ncn-mw#`) Run the `hsm_discovery_status_test.sh` script.

    ```bash
    /opt/cray/csm/scripts/hms_verification/hsm_discovery_status_test.sh
    ```

If the script fails, this indicates a discovery issue and further troubleshooting steps to take are printed.

Otherwise, missing compute nodes in HSM with no discovery failures may indicate a problem with a `leaf-bmc` switch.

1. (`ncn-mw#`) Check to see if the `leaf-bmc` switch resolves using the `nslookup` command.

    ```bash
    nslookup <leaf-bmc-switch>
    ```

    Example output:

    ```text
    Server:     10.92.100.225
    Address:    10.92.100.225#53
    Name:   sw-leaf-bmc-001.nmn
    Address: 10.252.0.4
    ```

1. (`ncn-mw#`) Verify connectivity to the `leaf-bmc` switch.

    ```bash
    ssh admin@<leaf-bmc-switch>
    ```

    Example output:

    ```text
    ssh: connect to host sw-leaf-bmc-001 port 22: Connection timed out
    ```

Restoring connectivity, resolving configuration issues, or restarting the relevant ports on the `leaf-bmc` switch should allow the compute hardware to issue DHCP requests and be discovered successfully.
