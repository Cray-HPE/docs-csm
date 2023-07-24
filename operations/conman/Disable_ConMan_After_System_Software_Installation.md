# Disable ConMan After the System Software Installation

The ConMan utility is enabled by default. The first procedure provides instructions for disabling it after the system software has been installed, and the second procedure provides instructions on how to later re-enable it.

## Prerequisites

This procedure requires administrative privileges.

## Disable Procedure

> **`NOTE`** this procedure has changed since the CSM 0.9 release.

1. Log on to a Kubernetes master or worker node.

1. (`ncn-mw#`) Scale the `cray-console-operator` pods to 0 replicas.

    ```bash
    kubectl -n services scale --replicas=0 deployment/cray-console-operator
    ```

    Example output:

    ```text
    deployment.apps/cray-console-operator scaled
    ```

1. (`ncn-mw#`) Verify the `cray-console-operator` service is no longer running.

    The following command will give no output when the service is no longer running.

    ```bash
    kubectl -n services get pods | grep console-operator
    ```

1. (`ncn-mw#`) Scale the `cray-console-node` pods to 0 replicas.

    ```bash
    kubectl -n services scale --replicas=0 statefulset/cray-console-node
    ```

    Example output:

    ```text
    statefulset.apps/cray-console-node scaled
    ```

1. (`ncn-mw#`) Verify the `cray-console-node` service is no longer running.

    The following command will give no output when the service is no longer running.

    ```bash
    kubectl -n services get pods | grep console-node
    ```

## Re-enable Procedure

1. (`ncn-mw#`) Scale the `cray-console-operator` service back to 1 replica. It will scale the `cray-console-node` pods after it starts operation.

    ```bash
    kubectl -n services scale --replicas=1 deployment/cray-console-operator
    ```

    Example output:

    ```text
    deployment.apps/cray-console-operator scaled
    ```

1. (`ncn-mw#`) Verify services are running again.

    ```bash
    kubectl -n services get pods | grep -e console-operator -e console-node
    ```

    Example output:

    ```text
    cray-console-node-0                      3/3     Running      0      8m44s
    cray-console-node-1                      3/3     Running      0      8m18s
    cray-console-operator-79bf95964-lngpz    2/2     Running      0      9m29s
    ```
