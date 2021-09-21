# CSM 0.9.6 Patch Installation Instructions

## Content
1. Non-Deterministic Unbound DNS Results Patch

   This procedure covers applying a new version of the `cray-dns-unbound` Helm chart to enable this setting in the configmap:

   ```text
   rrset-roundrobin: no
   ```

   Unbound back in April 2020 [changed](https://github.com/NLnetLabs/unbound/blob/master/doc/Changelog) the default of this setting to be `yes` which had the effect of randomizing the records returned from it if more than one entry corresponded (as woudl be the case for PTR records, for example):

   ```text
   21 April 2020: George
   	- Change default value for 'rrset-roundrobin' to yes.
   	- Fix tests for new rrset-roundrobin default.
   ```

   Some software is especially sensitive to this and thus requires this setting to be `no`.
1. Update the cray-sysmgmt-health helm chart to address multiple alerts
1. Install/Update node_exporter on storage nodes
1. Update cray-hms-hmnfd helm chart to include timestamp fix

# Procedures

- [Preparation](#preparation)
- [Apply cray-hms-hmcollector scale changes](#apply-cray-hms-hmcollector-scale-changes)
- [Setup Nexus](#setup-nexus)
- [Update NCNs](#update-ncns)
- [Upgrade Services](#upgrade-services)
- [Rollout Deployment Restart](#rollout-deployment-restart)
- [Verification](#verification)
- [Exit Typescript](#exit-typescript)

<a name="preparation"></a>
## Preparation

1. Start a typescript to capture the commands and output from this procedure.
   ```bash
   ncn-m001# script -af csm-update.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

   > **`NOTE:`** Installed CSM versions may be listed from the product catalog using:
   >
   > ```
   > ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   > 0.9.2
   > 0.9.3
   > 0.9.4
   > 0.9.5
   > ```

2. Set `CSM_DISTDIR` to the directory of the extracted release distribution for CSM 0.9.6:

   > **`NOTE:`** Use `--no-same-owner` and `--no-same-permissions` options to `tar` when extracting a CSM release
   > distribution as `root` to ensure the current `umask` value.

   If using a release distribution:
   ```
   ncn-m001# tar --no-same-owner --no-same-permissions -zxvf csm-0.9.6.tar.gz
   ncn-m001# export CSM_DISTDIR="$(pwd)/csm-0.9.6"
   ```

3. Set `CSM_RELEASE_VERSION` to the version reported by `${CSM_DISTDIR}/lib/version.sh`:

   ```
   ncn-m001# CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   ncn-m001# echo $CSM_RELEASE_VERSION
   ```

4. Download and install/upgrade the _latest_ documentation RPM. If this machine does not have direct internet access
   these RPMs will need to be externally downloaded and then copied to be installed.

   ```bash
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/docs-csm/docs-csm-latest.noarch.rpm
   ```

<a name="apply-cray-hms-hmcollector-scale-changes"></a> 
## Apply cray-hms-hmcollector scale changes

If no scaling changes are desired to be made against the `cray-hms-hmcollector` deployment or if they have have not been previously applied, then this section can be skipped and proceed onto the [Setup Nexus](#setup-nexus) section. 

Before [upgrading services](#upgrade-services), `customizations.yaml` in the `site-init` secret in the `loftsman` namespace must be updated to apply or re-apply any manual scaling changes made to the `cray-hms-hmcollector` deployment. 


1. If the [`site-init` repository is available as a remote
   repository](../../../067-SHASTA-CFG.md#push-to-a-remote-repository) then clone
   it on the host orchestrating the upgrade:

   ```bash
   ncn-m001# git clone "$SITE_INIT_REPO_URL" site-init
   ```

   Otherwise, create a new `site-init` working tree:

   ```bash
   ncn-m001# git init site-init
   ```

1. Download `customizations.yaml`:

   ```bash
   ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

1. Review, add, and commit `customizations.yaml` to the local `site-init`
   repository as appropriate.

   > **`NOTE:`** If `site-init` was cloned from a remote repository in step 1,
   > there may not be any differences and hence nothing to commit. This is
   > okay. If there are differences between what is in the repository and what
   > was stored in the `site-init`, then it suggests settings were improperly
   > changed at some point. If that is the case then be cautious, _there may be
   > dragons ahead_.

   ```bash
   ncn-m001# cd site-init
   ncn-m001# git diff
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Add customizations.yaml from site-init secret'
   ```

1. Update `customizations.yaml` with the existing `cray-hms-hmcollector` resource limits and requests settings:

   Persist resource requests and limits from the cray-hms-hmcollector deployment:
   ```bash
   ncn-m001# kubectl -n services get deployments cray-hms-hmcollector \
      -o jsonpath='{.spec.template.spec.containers[].resources}' | yq r -P - | \
      yq w -f - -i ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector.resources
   ```

   Persist annotations manually added to `cray-hms-hmcollector` deployment:
   ```bash
   ncn-m001# kubectl -n services get deployments cray-hms-hmcollector \
      -o jsonpath='{.spec.template.metadata.annotations}' | \
      yq d -P - '"traffic.sidecar.istio.io/excludeOutboundPorts"' | \
      yq w -f - -i ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector.podAnnotations
   ```

   View the updated overrides added to `customizations.yaml`. If the value overrides look different to the sample output below then the resource limits and requests have been manually modified in the past.
   ```bash
   ncn-m001# yq r ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector
   hmcollector_external_ip: '{{ network.netstaticips.hmn_api_gw }}'
   resources:
   limits:
      cpu: "4"
      memory: 5Gi
   requests:
      cpu: 500m
      memory: 256Mi
   podAnnotations: {}
   ```

1. If desired adjust the resource limits and requests for the `cray-hms-hmcollector`. Otherwise this step can be skipped.

   Edit `customizations.yaml` and the value overrides for the `cray-hms-hmcollector` Helm chart are defined at `spec.kubernetes.services.cray-hms-hmcollector`

   Adjust the resource limits and requests for the `cray-hms-hmcollector` deployment in `customizations.yaml`:
   ```yaml
         cray-hms-hmcollector:
            hmcollector_external_ip: '{{ network.netstaticips.hmn_api_gw }}'
            resources:
               limits:
                  cpu: "4"
                  memory: 5Gi
               requests:
                  cpu: 500m
                  memory: 256Mi
   ```

   To specify a non-default memory limit for the Istio proxy used by the `cray-hms-hmcollector` to pod annotation `sidecar.istio.io/proxyMemoryLimit` can added under `podAnnotations`. By default the Istio proxy memory limit is `1Gi`.
   ```yaml
         cray-hms-hmcollector:
            podAnnotations:
               sidecar.istio.io/proxyMemoryLimit: 5Gi
   ```

1. Review the changes to `customizations.yaml` and verify [baseline system
   customizations](../../../067-SHASTA-CFG.md#create-baseline-system-customizations)
   and any customer-specific settings are correct.

   ```
   ncn-m001# git diff
   ```

1. Add and commit `customizations.yaml` if there are any changes:

   ```
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m "Update customizations.yaml consistent with CSM $CSM_RELEASE_VERSION"
   ```

1. Update `site-init` sealed secret in `loftsman` namespace:

   ```bash
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. Push to the remote repository as appropriate:

   ```bash
   ncn-m001# git push
   ```

<a name="setup-nexus"></a>
## Setup Nexus

Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
ncn-m001# cd "$CSM_DISTDIR"
ncn-m001# ./lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output `OK` on stderr and exit with status
code `0`, e.g.:

```bash
ncn-m001# ./lib/setup-nexus.sh
...
+ Nexus setup complete
setup-nexus.sh: OK
ncn-m001# echo $?
0
```

In the event of an error, consult the [known
issues](../../../006-CSM-PLATFORM-INSTALL.md#known-issues) from the install
documentation to resolve potential problems and then try running
`setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is ok as long as
`setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits with status code `0`.

<a name="update-ncns"></a>
## Update NCNs

1. Set `CSM_SCRIPTDIR` to the scripts directory included in the docs-csm RPM
   for the CSM 0.9.6 upgrade:

   ```bash
   ncn-m001# CSM_SCRIPTDIR=/usr/share/doc/metal/upgrade/0.9/csm-0.9.6/scripts
   ```

2. Execute the following script from the scripts directory determined in the previous step to update master and storage nodes:

   ```bash
   ncn-m001# cd "$CSM_SCRIPTDIR"
   ncn-m001# ./update-ncns.sh
   ```

<a name="upgrade-services"></a>
## Upgrade Services

1. Run `upgrade.sh` to deploy upgraded CSM applications and services:

   ```bash
   ncn-m001# cd "$CSM_DISTDIR"
   ncn-m001# ./upgrade.sh
   ```

<a name="rollout-deployment-restart"></a>
## Rollout Deployment Restart

Instruct Kubernetes to gracefully restart the Unbound pods:

```text
ncn-m001:~ # kubectl -n services rollout restart deployment cray-dns-unbound
deployment.apps/cray-dns-unbound restarted
 
ncn-m001:~ # kubectl -n services rollout status deployment cray-dns-unbound
Waiting for deployment "cray-dns-unbound" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "cray-dns-unbound" rollout to finish: 3 old replicas are pending termination...
Waiting for deployment "cray-dns-unbound" rollout to finish: 3 old replicas are pending termination...
Waiting for deployment "cray-dns-unbound" rollout to finish: 3 old replicas are pending termination...
Waiting for deployment "cray-dns-unbound" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "cray-dns-unbound" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "cray-dns-unbound" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "cray-dns-unbound" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "cray-dns-unbound" rollout to finish: 1 old replicas are pending termination...
deployment "cray-dns-unbound" successfully rolled out
```

<a name="verification"></a>
## Verification

### Verify CSM Version in Product Catalog:

1. Verify the CSM version has been updated in the product catalog. Verify that the
   following command includes version `0.9.6`:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   0.9.2
   0.9.3
   0.9.4
   0.9.5
   0.9.6
   ```

2. Confirm the `import_date` reflects the timestamp of the upgrade:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"0.9.6".configuration.import_date'
   ```
### Verify cray-sysmgmt-health changes:

1. Confirm node-exporter is running on each storage node. This command can be run from a master node.  Validate that the result contains `go_goroutines` (replace ncn-s001 below with each storage node):

   ```bash
   curl -s http://ncn-s001:9100/metrics |grep go_goroutines|grep -v "#"
   go_goroutines 8
   ```

1. Confirm manifests were updated on each master node (repeat on each master node):

   ```bash
   ncn-m# grep bind /etc/kubernetes/manifests/*
   kube-controller-manager.yaml:    - --bind-address=0.0.0.0
   kube-scheduler.yaml:    - --bind-address=0.0.0.0
   ```

1. Confirm updated sysmgmt-health chart was deployed.  This command can be executed on a master node -- confirm the `cray-sysmgmt-health-0.12.6` chart version:

   ```bash
   ncn-m# helm ls -n sysmgmt-health
   NAME               	NAMESPACE     	REVISION	UPDATED                               	STATUS  	CHART                     	APP VERSION
   cray-sysmgmt-health	sysmgmt-health	2       	2021-09-10 16:45:12.00113666 +0000 UTC	deployed	cray-sysmgmt-health-0.12.6      8.15.4
   ```

1. Confirm updates to BSS for cloud-init runcmd

   **`IMPORTANT:`** Ensure you replace `XNAME` with the correct xname in the below examples (executing the `/opt/cray/platform-utils/getXnames.sh` script on a master node will display xnames):

   Example for a master node -- this should be checked for each master node.  Validate the three `sed` commands are returned in the output.

   ```bash
   ncn-m# cray bss bootparameters list --name XNAME --format=json | jq '.[]|."cloud-init"."user-data"'
   {
     "hostname": "ncn-m001",
     "local_hostname": "ncn-m001",
     "mac0": {
       "gateway": "10.252.0.1",
       "ip": "",
       "mask": "10.252.2.0/23"
     },
     "runcmd": [
       "/srv/cray/scripts/metal/install-bootloader.sh",
       "/srv/cray/scripts/metal/set-host-records.sh",
       "/srv/cray/scripts/metal/set-dhcp-to-static.sh",
       "/srv/cray/scripts/metal/set-dns-config.sh",
       "/srv/cray/scripts/metal/set-ntp-config.sh",
       "/srv/cray/scripts/metal/set-bmc-bbs.sh",
       "/srv/cray/scripts/metal/disable-cloud-init.sh",
       "/srv/cray/scripts/common/update_ca_certs.py",
       "/srv/cray/scripts/common/kubernetes-cloudinit.sh",
       "sed -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/' /etc/kubernetes/manifests/kube-controller-manager.yaml",
       "sed -i '/--port=0/d' /etc/kubernetes/manifests/kube-scheduler.yaml",
       "sed -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/' /etc/kubernetes/manifests/kube-scheduler.yaml"
     ]
   }
   ```

   Example for a storage node -- this should be checked for each storage node.  Validate the `zypper` command is returned in the output.

   ```bash
   ncn-m001:~ # cray bss bootparameters list --name XNAME --format=json | jq '.[]|."cloud-init"."user-data"'
   {
     "hostname": "ncn-s001",
     "local_hostname": "ncn-s001",
     "mac0": {
       "gateway": "10.252.0.1",
       "ip": "",
       "mask": "10.252.2.0/23"
     },
     "runcmd": [
       "/srv/cray/scripts/metal/install-bootloader.sh",
       "/srv/cray/scripts/metal/set-host-records.sh",
       "/srv/cray/scripts/metal/set-dhcp-to-static.sh",
       "/srv/cray/scripts/metal/set-dns-config.sh",
       "/srv/cray/scripts/metal/set-ntp-config.sh",
       "/srv/cray/scripts/metal/set-bmc-bbs.sh",
       "/srv/cray/scripts/metal/disable-cloud-init.sh",
       "/srv/cray/scripts/common/update_ca_certs.py",
       "zypper --no-gpg-checks in -y https://packages.local/repository/casmrel-755/cray-node-exporter-1.2.2.1-1.x86_64.rpm"
     ]
   }
   ```

### Verify HMNFD timestamp fix:

Once the patch is installed the missing timestamp fix can be validated by taking the following steps:

1. Find an instance of a cluster-kafka pod:

```
   kubectl -n sma get pods | grep kafka
   cluster-kafka-0               2/2     Running     1          30d
   cluster-kafka-1               2/2     Running     1          26d
   cluster-kafka-2               2/2     Running     0          73d
```

2. Exec into one of those pods:

```
   kubectl -n sma exec -it <pod_id> /bin/bash
```

3. cd to the 'bin' directory in the kafka pod.

4. Execute the following command in the kafka pod to run a kafka consumer app:

```
   ./kafka-console-consumer.sh --bootstrap-server=localhost:9092 --topic=cray-hmsstatechange-notifications
```

5. Find a compute node that is booted on the system:

```
   sat status | grep Compute | grep Ready
   ...
   | x1003c7s7b1n1  | Node | 2023     | Ready   | OK   | True    | X86  | Mountain | Compute     | Sling    |
```

NOTE: All examples below will use the node seen in the above example.

6. Send an SCN to HMNFD for that node indicating that it is in the Ready state.  Note that this won't affect anything since the node is already Ready.

```
   TOKEN=`curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=\`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d\` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'`

   curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -d '{"Components":["x1003c7s7b1n1"],"State":"Ready"}' https://api_gw_service.local/apis/hmnfd/hmi/v1/scn
```

7. In the kafka-console-consumer.sh window there should be an SCN sent by HMNFD, which should include a Timestamp field:

```
   {"Components":["x1003c7s7b1n1"],"Flag":"OK","State":"Ready","Timestamp":"2021-09-13T13:00:00"}
```

<a name="exit-typescript"></a>
## Exit Typescript

Remember to exit your typescript.

```bash
ncn-m001# exit
```

It is recommended to save the typescript file for later reference.
