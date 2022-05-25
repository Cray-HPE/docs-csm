# Restore Spire Postgres without an Existing Backup

Reinstall the Spire helm chart in the
event that spire-postgres databases cannot be restored from a backup.


### Uninstall Spire

1. Uninstall the Spire helm chart.

   ```bash
   ncn# helm uninstall -n spire spire
   ```

2. Wait for the pods in the Spire namespace to terminate. Once that is done, remove
   the spire-data-server pvcs.

   ```bash
   ncn# kubectl get pvc -n spire | grep spire-data-spire-server | awk '{print $1}' | xargs kubectl delete -n spire pvc
   ```

3. Disable spire-agent on all of the Kubernetes NCNs (all worker nodes and master nodes) and delete the join data.

   ```bash
   ncn# for ncn in $(kubectl get nodes -o name | cut -d'/' -f2); do ssh "${ncn}" systemctl stop spire-agent; ssh "${ncn}" rm /
   root/spire/data/svid.key /root/spire/agent_svid.der /root/spire/bundle.der; done
   ```


### Re-install the Spire Helm Chart

The CSM release tarball is required as it contains the Spire helm chart.

1. Extract the current release tarball.

   ```bash
   ## This example assumes the csm-1.0.0 release is currently running and the csm-1.0.0.tar.gz has been pulled down under /root
   ncn# cd /root
   ncn# tar -xzf csm-1.0.0.tar.gz
   ncn# rm csm-1.0.0.tar.gz
   ncn# PATH_TO_RELEASE=/root/csm-1.0.0
   ```

2. Get the current cached customizations.

   ```bash
   ncn# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

3. Get the current cached sysmgmt manifest.

   ```bash
   ncn# kubectl get cm -n loftsman loftsman-sysmgmt  -o jsonpath='{.data.manifest\.yaml}' -o sysmgmt.yaml
   ```

4. Edit the `sysmgmt.yaml` spec.charts section to only include the `spire` chart and all its current data. (The resources specified above will be updated in the next step and the version may differ, because this is an example).

   ```bash
   apiVersion: manifests/v1beta1
   metadata:
     name: sysmgmt
   spec:
     charts:
     - name: spire
       namespace: spire
       source: csm
       values:
         server:
           fqdn: spire.local
         trustDomain: shasta
       version: 0.11.3
       version: 0.12.0
     sources:
       charts:
       - location: ./helm
         name: csm
         type: directory
       - location: ./helm
         name: csm-algol60
         type: directory
   ```

5. Generate the manifest that will be used to redeploy the chart with the modified resources.

   ```bash
   ncn# manifestgen -c customizations.yaml -i sysmgmt.yaml -o manifest.yaml
   ```

6. Update the helm chart path in the manifest.yaml file.

   ```bash
   ncn# sed -i "s|./helm|${PATH_TO_RELEASE}/helm|" manifest.yaml
   ```

7. Validate that the manifest.yaml file only contains chart information for Spire,
and that the sources charts location points to the directory the helm chart was extracted from to prepend to /helm.

8. Redeploy the Spire chart.

   ```bash
   ncn# loftsman ship --manifest-path ${PWD}/manifest.yaml
   ```

9. Verify that all Spire pods have started.

   This step may take a few minutes due to a number of pods requiring other pods to be up.

   ```bash
   ncn# kubectl get pods -n spire
   ```

10. Restart all compute nodes and User Access Nodes (UANs).

   Compute nodes and UANs get their join token on boot from the Boot Script Service (BSS).
   Their old SVID data is no longer valid and a reboot is required in order for them to re-join Spire.

