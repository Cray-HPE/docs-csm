# Nexus Deployment

Nexus is deployed with the `cray-nexus` chart to the `nexus` namespace as part of the Cray System Management \(CSM\) release. Nexus is deployed
after critical platform services are up and running. Product installers configure and populate Nexus blob stores and repositories using the
`cray-nexus-setup` container image. As a result, there is no singular product that provides all Nexus repositories or assets; instead, individual
products must be installed. However, CSM configures the `charts` Helm repository and the `registry` Docker repository, which all products may use.

- [Customizations](#customizations)
- [Common Nexus deployments](#common-nexus-deployments)
- [Bootstrap registry](#bootstrap-registry)
- [Product installers](#product-installers)

## Customizations

For a complete set of available settings, consult the `values.yaml` file for the `cray-nexus` chart. The most common customizations to set are
specified in the following table. They must be set in the `customizations.yaml` file under the `spec.kubernetes.services.cray-nexus` setting.

|Customization|Default|Description|
|-------------|-------|-----------|
|`istio.ingress.hosts.ui.enabled`|`true`|Enables ingress from the CAN \(default chart value is `false`\)|
|`istio.ingress.hosts.ui.authority`|`nexus.cmn.{{ network.dns.external }}`|Sets the CAN hostname \(default chart value is `nexus.local`\)|
|`sonatype-nexus.persistence.storageSize`|`1000Gi`|Nexus storage size, may be increased after installation; critical if `spec.kubernetes.services.cray-nexus-setup.s3.enabled` is `false`|

(`ncn-mw#`) If modifying the `customizations.yaml` file, be sure to upload the new file to Kubernetes, otherwise the changes will not persist
through future installs or upgrades.

```bash
kubectl delete secret -n loftsman site-init
kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
```

## Common Nexus deployments

(`ncn-mw#`) A typical deployment will look similar to the output of the following command:

```bash
kubectl -n nexus get all
```

Example output:

```text
NAME                             READY   STATUS    RESTARTS   AGE
pod/cray-precache-images-6tp2c   2/2     Running   0          20d
pod/cray-precache-images-dnwdx   2/2     Running   0          20d
pod/cray-precache-images-jgvx8   2/2     Running   0          20d
pod/cray-precache-images-n2clw   2/2     Running   0          20d
pod/cray-precache-images-v8ntg   2/2     Running   0          17d
pod/cray-precache-images-xmg6d   2/2     Running   0          20d
pod/nexus-55d8c77547-xcc2f       2/2     Running   0          19d

NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)           AGE
service/nexus   ClusterIP   10.23.120.95   <none>        80/TCP,5003/TCP   19d

NAME                                  DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/cray-precache-images   6         6         6       6            6           <none>          20d

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nexus   1/1     1            1           19d

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nexus-55d8c77547   1         1         1       19dd
```

The `cray-precache-images` `DaemonSet` is used to keep select container images resident in the image cache on each worker node to ensure Nexus
resiliency. It is deployed as a critical platform component prior to Nexus.

**WARNING:** The `cray-nexus` chart deploys Nexus with a single replica and the corresponding `nexus-data` PVC with `RWX` access mode. Nexus
should **NEVER** be scaled to more than one replica; otherwise, the instance data in `nexus-data` PV will most likely be corrupted. Using `RWX`
access mode enables Nexus to quickly restart on another worker node in the event of a node failure and avoid additional delay because of volume
multi-attach errors.

## Bootstrap registry

During installation, a Nexus instance is run on the PIT node at port 8081 to facilitate cluster bootstrap. It is only configured with a Docker
registry available at `http://pit.nmn:5000`, which is populated with container images included in the CSM release.

On the PIT node, `http://pit.nmn:5000` is the default mirror configured in `/etc/containerd/config.toml`. However, once the PIT node is rebooted as
`ncn-m001`, it will no longer be available.

## Product installers

Product installers vendor the `dtr.dev.cray.com/cray/cray-nexus-setup:0.4.0` container image, which includes helper scripts for working with the Nexus
REST API to update and modify repositories. Product release distributions will include the `nexus-blobstores.yaml` and `nexus-repositories.yaml` files, which
define the Nexus blob stores and repositories required for that version of the product. Also, expect to find directories that include specific types of assets:

- `rpm/` - RPM repositories
- `docker/` - Container images
- `helm/` - Helm charts

Prior to deploying Helm charts to the system management Kubernetes cluster, product installers will set up repositories in Nexus and then upload assets to them.
Typically, all of this is automated in the beginning of a product's `install.sh` script, and will look something like the following:

```bash
ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"source"${ROOTDIR}/lib/version.sh"source"${ROOTDIR}/lib/install.sh"# Load vendored tools into install environment
load-install-deps

# Upload the contents of an RPM repository named $repo
nexus-upload raw "${ROOTDIR}/rpm/${repo}""${RELEASE_NAME}-${RELEASE_VERSION}-${repo}"# Setup Nexus
nexus-setup blobstores   "${ROOTDIR}/nexus-blobstores.yaml"
nexus-setup repositories "${ROOTDIR}/nexus-repositories.yaml"# Upload container images to registry.local
skopeo-sync "${ROOTDIR}/docker"# Upload charts to the "charts" repository
nexus-upload helm "${ROOTDIR}/helm" charts

# Remove vendored tools from install environment
clean-install-deps
```

Product installers also load and clean up the install tools used to facilitate installation. By convention, vendored tools will be in the `vendor` directory.
In case something goes wrong, it may be useful to manually load them into the install environment to help with debugging.
