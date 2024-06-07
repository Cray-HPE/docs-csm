# Validate CSM Health During a CSM Upgrade

- Before performing the health validation, be sure that at least 15 minutes have elapsed
  since the CSM services were upgraded. This allows the various Kubernetes resources to
  initialize and start.
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

    Run the combined health check script, which runs a variety of health checks that should pass at this stage of the upgrade:

    - Kubernetes health checks
    - NCN health checks

    ```bash
    /opt/cray/tests/install/ncn/automated/ncn-k8s-combined-healthcheck-post-service-upgrade
    ```

    Review the output and follow the instructions provided to resolve any test failures. With the exception of
    [Known issues with NCN health checks](../troubleshooting/known_issues/issues_with_ncn_health_checks.md),
    all health checks are expected to pass.

1. (`ncn-m002#`) Stop typescripts.

    For any typescripts that were started during the health validation procedure, stop them with the `exit` command.

1. (`ncn-m002#`) Backup upgrade logs and typescript files to a safe location.

    1. If any typescript files are on different NCNs, then copy them to `/root` on `ncn-m002`.

    1. Create a `tar` file containing the logs and typescript files.

        > If any typescript file names are not of the form `csm_upgrade.*.txt`, then append their names
        > to the following `tar` command in order to include them.

        ```bash
        TARFILE="csm_upgrade.$(date +%Y%m%d_%H%M%S).logs.tgz"
        tar -czvf "/root/${TARFILE}" /root/csm_upgrade.*.txt /root/output.log
        ```

    1. Upload the `tar` file into S3.

        This step requires that the Cray Command Line Interface is configured on the node. This should have already
        been done on `ncn-m002` during the upgrade process. If needed, see [Configure the Cray CLI](../operations/configure_cray_cli.md).

        ```bash
        cray artifacts create config-data "${TARFILE}" "/root/${TARFILE}"
        ```
1. Update ceph node-exporter config for SNMP counters.

    > **OPTIONAL:** This is an optional step.

    This uses `netstat` collector form node-exporter and enables all the SNMP counters monitoring in `/proc/net/snmp` on `ncn` nodes.

    See [Update ceph node-exporter configuration](../operations/utility_storage/update_ceph_node_exporter_config.md) to update the ceph node-exporter configuration to monitor SNMP counters.
