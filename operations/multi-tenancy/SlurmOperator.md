# Slurm Operator

* [Overview](#overview)
* [Troubleshooting](#troubleshooting)

## Overview

The Slurm operator can be used to deploy Slurm within a tenant, so each tenant can have a separate instance of Slurm.
The Slurm operator is distributed as part of USS, and is installed if `uss.deploy_slurm` is enabled in `site_vars.yaml` during IUF installation.

## Troubleshooting

(`ncn-mw#`) The following commands can provide information to assist in troubleshooting.

* Check the Slurm operator logs.

    ```bash
    kubectl logs -n slurm-operator --timestamps --tail=-1 -c slurm-operator -lapp=slurm-operator
    ```

* Check the status of a Slurm custom resource.

    ```bash
    kubectl describe slurmcluster -n <namespace> <name>
    ```

* Check the `slurmctld` logs for a tenant.

    ```bash
    kubectl logs -n <namespace> --timestamps --tail=-1 -c slurmctld -lapp.kubernetes.io/name=slurmctld
    ```

* Check the `slurmdbd` logs for a tenant.

    ```bash
    kubectl logs -n <namespace> --timestamps --tail=-1 -c slurmdbd -lapp.kubernetes.io/name=slurmdbd
    ```

* Check the accounting database logs for a tenant.

    ```bash
    kubectl logs -n <namespace> <name>-slurmdb-pxc-0
    kubectl logs -n <namespace> <name>-slurmdb-pxc-1
    kubectl logs -n <namespace> <name>-slurmdb-pxc-2
    ```
