# Update NCN BIOS TPM State

## Description

Enable Trusted Platform Module (TPM) in the BIOS on the new NCN if TPM is being used on the other NCNs.
**Skip this step if TPM is not being used in the system** and proceed to the next step to [Boot NCN and Configure](Boot_NCN.md).

Using TPM involves both enabling the hardware and configuring TPM.
This document only details how to enable TPM on the hardware.
The state of the other NCNs in the system can be checked using steps 1 and 2 of the [procedure](#procedure) in this document.

Disabling TPM is not required when not using it. Many types of hardware come with TPM enabled by default.

## Current capabilities

The following table lists the type of hardware where the TPM State can be enabled. Not all models from a given manufacturer support TPM.

| **Manufacturer** | **Type**     |
| ---------------- | ------------ |
| Gigabyte         | `nodeBMC`    |
| HPE              | `nodeBMC`    |

SCSD does not support setting the TPM state on Intel hardware.
With Intel hardware skip these steps and proceed to the next step to [Boot NCN and Configure](Boot_NCN.md).

## Procedure

1. (`ncn-mw#`) Select the component name (xname) of the BMC node. <a name="step1"></a>

    ```bash
    export XNAME_BMC=x3000c0s4b0n0
    ```

1. (`ncn-mw#`) Check the TPM state. <a name="step2"></a>

    ```bash
    cray scsd bmc bios describe tpmstate $XNAME_BMC --format json
    ```

    Example output for the `Disabled` case:

    ```json
    {
        "Current" : "Disabled",
        "Future" : "Disabled"
    }
    ```

    If the response is `NotPresent`, then setting TPM is not supported.
    The remaining steps should be skipped. Proceed to the next step to [Boot NCN and Configure](Boot_NCN.md).

    ```json
    {
        "Current" : "NotPresent",
        "Future" : "NotPresent"
    }
    ```

    If the response is an error, then setting TPM is not supported by SCSD or is not supported by the hardware.
    This includes any usage errors from the `cray` command.
    The remaining steps should be skipped. Proceed to the next step to [Boot NCN and Configure](Boot_NCN.md).

1. (`ncn-mw#`) Enable the TPM state if it is `Disabled`.

    If the previous step showed that TPM was `Disabled`, then `Enable` it with the following request.

    ```bash
    cray scsd bmc bios update tpmstate $XNAME_BMC --future Enabled
    ```

1. (`ncn-mw#`) Check that the `Future` value is set.

    ```bash
    cray scsd bmc bios describe tpmstate $XNAME_BMC --format json
    ```

    Example output:

    ```json
    {
        "Current" : "Disabled",
        "Future" : "Enabled"
    }
    ```

    The new TPM state will take effect the next time the node is booted.

## Next Step

Proceed to the next step to [Boot NCN and Configure](Boot_NCN.md) or return to the main [Add, Remove, Replace, or Move NCNs](Add_Remove_Replace_NCNs.md) page.
