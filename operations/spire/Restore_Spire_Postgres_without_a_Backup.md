# Restore Spire Postgres without an Existing Backup

Reinstall the Spire helm chart in the
event that `spire-postgres` databases cannot be restored from a backup.

## Uninstall Spire

1. Uninstall the Spire helm chart.

   ```bash
   ncn# helm uninstall -n spire spire
   ```

2. Wait for the pods in the Spire namespace to terminate. Once that is done, remove
   the spire-data-server `PVCs`.

   ```bash
   ncn# kubectl get pvc -n spire | grep spire-data-spire-server | awk '{print $1}' | xargs kubectl delete -n spire pvc
   ```

3. Disable `spire-agent` on all of the Kubernetes NCNs (all worker nodes and
   master nodes) and delete the join data.

   ```bash
   ncn# for ncn in $(kubectl get nodes -o name | cut -d'/' -f2); do ssh "${ncn}" systemctl stop spire-agent; ssh "${ncn}" rm /root/spire/data/svid.key /root/spire/agent_svid.der /root/spire/bundle.der; done
   ```

## Re-install the Spire Helm Chart

1. Get the current cached customizations.

   ```bash
   ncn# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. Get the current cached `sysmgmt` manifest.

   ```bash
   ncn# kubectl get cm -n loftsman loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}' > spire.yaml
   ```

1. Run the following command to remove non-Spire charts from the `spire.yaml`
   file. This will also change the `metadata.name` so that it does not overwrite the
   `sysmgmt.yaml` file that is stored in the `loftsman` namespace.

   ```bash
   ncn# for i in $(yq r spire.yaml 'spec.charts[*].name' | grep -Ev '^spire$'); do yq d -i spire.yaml  'spec.charts(name=='"$i"')'; done
   ncn# yq w -i spire.yaml metadata.name spire
   ncn# yq d -i spire.yaml spec.sources
   ncn# yq w -i spire.yaml spec.sources.charts[0].location 'https://packages.local/repository/charts'
   ncn# yq w -i spire.yaml spec.sources.charts[0].name csm-algol60
   ncn# yq w -i spire.yaml spec.sources.charts[0].type repo
   ```

   Example `spire.yaml` after the command is run:

   ```yaml
   apiVersion: manifests/v1beta1
     metadata:
       name: spire
     spec:
       charts:
         - name: spire
           namespace: spire
           source: csm-algol60
           values:
             server:
               fqdn: spire.local
             trustDomain: shasta
           version: 0.11.5
       charts:
         - location: https://packages.local/repository/charts
           name: csm-algol60
           type: repo
   ```

1. Generate the manifest that will be used to redeploy the chart with the
   modified resources.

   ```bash
   ncn# manifestgen -c customizations.yaml -i spire.yaml -o manifest.yaml
   ```

1. Validate that the `manifest.yaml` file only contains chart information for
   Spire, and that the sources chart location points to
   `https://packages.local/repository/charts`.

1. Redeploy the Spire chart.

   ```bash
   ncn# loftsman ship --manifest-path ${PWD}/manifest.yaml
   ```

1. Verify that all Spire pods have started.

   This step may take a few minutes due to a number of pods requiring other pods
   to be up.

   ```bash
   ncn# kubectl get pods -n spire
   ```

1. Restart all compute nodes and User Access Nodes (UANs).

Compute nodes and UANs get their join token on boot from the Boot Script Service
(BSS). Their old SVID data is no longer valid and a reboot is required in order
for them to re-join Spire.
