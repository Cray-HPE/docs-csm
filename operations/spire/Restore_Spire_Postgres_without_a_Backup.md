# Restore Spire Postgres without an existing backup

This procedure will walk you through reinstalling the spire helm chart in the
event that you cannot restore the spire-postgres databases from a backup.

## Uninstall spire

1. uninstall the spire helm chart

```bash
ncn# helm uninstall -n spire spire
```

2. Wait for the pods in the spire namespace to terminate. Once that is done remove
   the spire-data-server pvcs.

```bash
ncn# kubectl get pvc -n spire | grep spire-data-spire-server | awk '{print $1}' | xargs kubectl delete -n spire pvc
```

3. Disable spire-agent on all of the kubernetes NCNs and delete the join data

```bash
ncn# for ncn in $(kubectl get nodes -o name | cut -d'/' -f2); do ssh "${ncn}" systemctl stop spire-agent; ssh "${ncn}" rm /root/spire/data/svid.key /root/spire/agent_svid.der /root/spire/bundle.der; done
```

## Re-install spire helm chart

You will need the csm release tarball, as that contains the spire helm chart.

1. Extract the current release tarball

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

3. Get the current cached sysmgnt manifest.

```bash
ncn# kubectl get cm -n loftsman loftsman-sysmgmt  -o jsonpath='{.data.manifest\.yaml}' -o sysmgmt.yaml
```

4. Edit the `sysmgmt.yaml` spec.charts section to only include the `spire` chart and all its current data. (The resources specified above will be updated in the next step and the version may differ, because this is an example).

```
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

6. Update the helm chart path in manifest.yaml

```bash
ncn# sed -i "s|./helm|${PATH_TO_RELEASE}/helm|" manifest.yaml
```

7. Validate that the manifest.yaml only contains chart information for spire and that the sources charts location points to the directory where you extracted the helm chart to prepended to /helm.

8. Redeploy the spire chart

```bash
ncn# loftsman ship --manifest-path ${PWD}/manifest.yaml
```

9. Verify that all spire pods have started

This step may take a few minutes due to a number of pods requiring other pods to be up

```bash
ncn# kubectl get pods -n spire
```

10. Restart all compute and UANs

Computes and UANs get their join token on boot from BSS. Their old SVID data is no longer valid and a reboot is required in order for them to re-join spire.
