# Slurm Operator

The Slurm operator can be used to deploy Slurm within a tenant, so each tenant
can have a separate instance of Slurm.

## Table of Contents

* [Install the Slurm Operator](#install-the-slurm-operator)
* [Troubleshooting](#troubleshooting)

## Install the Slurm Operator

To create Slurm tenants, the Slurm operator must be installed. The Slurm
Operator runs in a Kubernetes pod and watches for `SlurmCluster` custom
resources.

* (`ncn-mw#`) To install the Slurm operator, run this command in the unpacked
    CPE Slurm release tarball:

    ```sh
    helm upgrade --install -n slurm-operator cray-slurm-operator \
        ./helm/cray-slurm-operator-*.tgz
    ```

## Troubleshooting

* (`ncn-mw#`) To check the Slurm operator logs:

    ```sh
    kubectl logs -n slurm-operator --timestamps --tail=-1 -c slurm-operator \
        -lapp=slurm-operator
    ```

* (`ncn-mw#`) To check the status of a Slurm custom resource:

    ```sh
    kubectl describe slurmcluster -n <namespace> <name>
    ```

* (`ncn-mw#`) To check the `slurmctld` logs for a tenant:

    ```sh
    kubectl logs -n <namespace> --timestamps --tail=-1 -c slurmctld \
        -lapp.kubernetes.io/name=slurmctld
    ```

* (`ncn-mw#`) To check the `slurmdbd` logs for a tenant:

    ```sh
    kubectl logs -n <namespace> --timestamps --tail=-1 -c slurmdbd \
        -lapp.kubernetes.io/name=slurmdbd
    ```

* (`ncn-mw#`) To check the accounting database logs for a tenant:

    ```sh
    kubectl logs -n <namespace> <name>-slurmdb-pxc-0
    kubectl logs -n <namespace> <name>-slurmdb-pxc-1
    kubectl logs -n <namespace> <name>-slurmdb-pxc-2
    ```
