# Restore Spire Postgres without an Existing Backup

Reinstall the Spire Helm chart in the event that `spire-postgres` databases cannot be restored from a backup.

## Uninstall Spire

1. (`ncn-mw#`) Uninstall the Spire Helm chart.

   ```bash
   helm uninstall -n spire spire
   ```

1. (`ncn-mw#`) Wait for the pods in the `spire` namespace to terminate. Once that is done, remove
   the `spire-data-server` `PVCs`.

   ```bash
   kubectl get pvc -n spire | grep spire-data-spire-server | awk '{print $1}' | xargs kubectl delete -n spire pvc
   ```

1. (`ncn-mw#`) Disable `spire-agent` on all of the Kubernetes NCNs (all worker nodes and
   master nodes) and delete the join data.

   ```bash
   for ncn in $(kubectl get nodes -o name | cut -d'/' -f2); do ssh "${ncn}" systemctl stop spire-agent; ssh "${ncn}" rm /root/spire/data/svid.key /root/spire/agent_svid.der /root/spire/bundle.der; done
   ```

## Re-install the Spire Helm Chart

1. (`ncn-mw#`) Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

   * Name of chart to be redeployed: `spire`
   * Base name of manifest: `sysmgmt`
   * When reaching the step to update customizations, no edits need to be made to the customizations file.
   * When reaching the step to validate that the redeploy was successful, perform the following step:

      **Only follow this step as part of the previously linked chart redeploy procedure.**

      1. Verify that all Spire pods have started.

         This step may take a few minutes due to a number of pods requiring other pods to be up.

         ```bash
         kubectl get pods -n spire
         ```

1. Restart all compute nodes and User Access Nodes (UANs).

   Compute nodes and UANs get their join token on boot from the Boot Script Service
   (BSS). Their old SVID data is no longer valid and a reboot is required in order
   for them to re-join Spire.
