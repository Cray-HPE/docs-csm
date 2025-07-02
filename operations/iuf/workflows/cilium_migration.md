# Migrating Kubernetes CNI from Weave to Cilium

This section describes how to migrate your Kubernetes CNI from Weave to Cilium during a CSM upgrade.

## Steps

1. **Run the migration script:**

    ```bash
    /usr/share/doc/csm/scripts/cilium_migration.sh
    ```

    This script will:
    - Create and execute the migration workflow in the `argo` namespace.
    - Migrate the CNI from Weave to Cilium.
    - Continuously monitor the workflow status using `kubectl`.

1. **Monitor the migration workflow:**

    The workflow status can also be tracked using the Argo CLI:

    ```bash
    argo watch <workflow-name> -n argo
    ```

    Replace `<workflow-name>` with the actual name of the workflow created by the
