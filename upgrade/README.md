# Upgrade CSM

The process for upgrading Cray Systems Management (CSM) has many steps in multiple procedures which should be done in a specific order.

After the upgrade of CSM software, the CSM health checks will validate the system before doing any other operational
tasks like the check and update of firmware on system components. Once the CSM upgrade has completed, other
product streams for the HPE Cray EX system can be installed or upgraded.

- [Known Issues](#known-issues)
- [1. Prepare for upgrade](#1-prepare-for-upgrade)
- [2. Upgrade management nodes and CSM services](#2-upgrade-management-nodes-and-csm-services)
- [3. Validate CSM health](#3-validate-csm-health)
- [4. Apply security hardening](#4-apply-security-hardening)
- [5. Next topic](#5-next-topic)

Note: If problems are encountered during the upgrade, some of the topics do have their own troubleshooting
sections, but there is also a general troubleshooting topic.

## Known Issues

- The boot order on NCNs may not be correctly set. Because of a bug, the disk entries may be listed ahead of the PXE entries. During the upgrade, a workaround is applied to fix this.

## 1. Prepare for upgrade

See [Prepare for Upgrade](prepare_for_upgrade.md).

## 2. Upgrade management nodes and CSM services

The upgrade of CSM software will do a controlled, rolling reboot of all management nodes before updating the CSM services.

The upgrade is a guided process starting with [Upgrade Management Nodes and CSM Services](Upgrade_Management_Nodes_and_CSM_Services.md).

## 3. Validate CSM health

- Before performing the health validation, be sure that at least 15 minutes have elapsed
  since the CSM services were upgraded. This allows the various Kubernetes resources to
  initialize and start.
- If the site does not use UAIs, then skip UAS and UAI validation. If UAIs are used, then
  before validating UAS and UAI, first validate any products that configure UAS (such as
  Cray Analytics and Cray Programming Environment); the procedures for this are
  beyond the scope of this document. Failures in UAI creation that result
  from incorrect or incomplete installation of these products will generally take the form of UAIs stuck in
  `waiting` state, trying to set up volume mounts.
- Although it is not recommended, the [Booting CSM `barebones` image](../operations/validate_csm_health.md#5-booting-csm-barebones-image)
  test may be skipped if all compute nodes are active running application workloads.

1. (`ncn-m002#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m002#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).post_upgrade_health_validation.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

    If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
    after a break, always be sure that a typescript is running before proceeding.

1. Validate CSM health.

    See [Validate CSM Health](../operations/validate_csm_health.md).

1. (`ncn-m002#`) Stop typescripts.

    For any typescripts that were started during the health validation procedure, stop them with the `exit` command.

1. (`ncn-m002#`) Backup upgrade logs and typescript files to a safe location.

    1. If any typescript files are on different NCNs, then copy them to `/root` on `ncn-m002`.

    1. Create tar file containing the logs and typescript files.

        > If any typescript file names are not of the form `csm_upgrade.*.txt`, then append their names
        > to the following `tar` command in order to include them.

        ```bash
        TARFILE="csm_upgrade.$(date +%Y%m%d_%H%M%S).logs.tgz"
        tar -czvf "/root/${TARFILE}" /root/csm_upgrade.*.txt /root/output.log
        ```

    1. Upload the tar file into S3.

        This step requires that the Cray Command Line Interface is configured on the node. This should have already
        been done on `ncn-m002` during the upgrade process. If needed, see [Configure the Cray CLI](../operations/configure_cray_cli.md).

        ```bash
        cray artifacts create config-data "${TARFILE}" "/root/${TARFILE}"
        ```

## 4. Apply security hardening

Review the security hardening guide, apply non-optional procedures, and review optional procedures.

See [Security Hardening](../operations/CSM_product_management/Apply_Security_Hardening.md).

## 5. Next topic

After completion of the validation of CSM health, the CSM product stream has been fully upgraded and
configured. Refer to the [HPE Cray EX System Software Getting Started Guide S-8000](https://www.hpe.com/support/ex-S-8000)
on the HPE Customer Support Center for more information on other product streams to be upgraded and configured after CSM.

> **`NOTE`** If a newer version of the HPE Cray EX HPC Firmware Pack (HFP) is available, then the next step
is to install HFP. This will inform the Firmware Action Services (FAS) of the newest firmware
available. Once FAS is aware that new firmware is available, then see
[Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md).
