# Package Repository Management with Nexus

Overview of RPM repositories and container registry in Nexus.

- [RPM repositories](#rpm-repositories)
    - [Creating a new RPM repository](#creating-a-new-rpm-repository)
- [Container registry](#container-registry)
    - [Adding images](#adding-images)
    - [Registry mirror configuration](#registry-mirror-configuration)
    - [Pull example using CRI](#pull-example-using-cri)
    - [Pull example using `containerd`](#pull-example-using-containerd)
    - [Pull example using Podman](#pull-example-using-podman)

## RPM repositories

(`ncn#`) Repositories are available at `https://packages.local/repository/REPO_NAME`. For example, to configure the `csm-sle-15sp2` repository on a
non-compute node \(NCN\):

```bash
zypper addrepo -fG https://packages.local/repository/csm-sle-15sp2 csm-sle-15sp2
```

Example output:

```text
Adding repository 'csm-sle-15sp2' .................................................................................................[done]
Warning: GPG checking is disabled in configuration of repository 'csm-sle-15sp2'. Integrity and origin of packages cannot be verified.
Repository 'csm-sle-15sp2' successfully added

URI         : https://packages.local/repository/csm-sle-15sp2
Enabled     : Yes
GPG Check   : No
Autorefresh : Yes
Priority    : 99 (default priority)

Repository priorities are without effect. All enabled repositories share the same priority.
zypper ref csm-sle-15sp2
Retrieving repository 'csm-sle-15sp2' metadata ....................................................................................[done]
Building repository 'csm-sle-15sp2' cache .........................................................................................[done]
Specified repositories have been refreshed.
```

The `-G` option is used in this example to disable GPG checks. However, if the named repository is properly signed, it is not recommended to use the
`-G` option.

### Creating a new RPM repository

This section will create a new repo called `sample-repo` in Nexus and add a single rpm `example.rpm` to it.  

#### Authenticating to Nexus

(`ncn-mw#`) Use the following function to get the Nexus local admin account after a fresh install:

```bash
function nexus-get-credential() {

    if ! command -v kubectl 1>&2 >/dev/null; then
      echo "Requires kubectl"
      return 1
    fi
    if ! command -v base64 1>&2 >/dev/null ; then
      echo "Requires base64"
      return 1
    fi

    [[ $# -gt 0 ]] || set -- -n nexus nexus-admin-credential

    kubectl get secret "${@}" >/dev/null || return $?

    NEXUS_USERNAME="$(kubectl get secret "${@}" --template {{.data.username}} | base64 -d)"
    NEXUS_PASSWORD="$(kubectl get secret "${@}" --template {{.data.password}} | base64 -d)"
}
```

#### Creating a repo

1. (`ncn-mw#`) Create and export the repository name:

   ```bash
   export REPO=sample-repo
   ```

1. (`ncn-mw#`) Create a Nexus Zypper repository on the Nexus system that will contain the content necessary content:

   ```bash
   nexus-get-credential
   
   curl -u $NEXUS_USERNAME:$NEXUS_PASSWORD \
   https://packages.local/service/rest/v1/repositories/yum/hosted \
   --header "Content-Type: application/json" --request POST --data-binary \
   @- << EOF
   {
     "name": "$REPO",
     "online": true ,
     "storage": {
       "blobStoreName": "default",
       "strictContentTypeValidation": true ,
       "writePolicy": "ALLOW"
     },
     "cleanup": null ,
     "yum": {
       "repodataDepth": 0,
       "deployPolicy": "STRICT"
     },
     "format": "yum",
     "type": "hosted"
   }
   EOF
   ```

1. (`ncn-mw#`) Verify the new repository is available:

   ```bash
   REPOURL=https://packages.local/service/rest/v1/repositories
   curl -u $NEXUS_USERNAME:$NEXUS_PASSWORD ${REPOURL} -s --header "Content -type: application/json"  \
   --http1.1 | grep $REPO
   ```

1. (`ncn-mw#`) Upload the `example` rpm to the new repo:

   ```bash
   curl -u $NEXUS_USERNAME:$NEXUS_PASSWORD -v --upload-file ./example*.rpm --max-time 600 \
   https://packages.local/repository/$REPO/
   ```

1. (`ncn-mw#`) Build the repository index:

   ```bash
   NEXUSRI=https://packages.local/service/rest/v1
   NEXUSRI=${NEXUSRI}/repositories/$REPO/rebuild-index
   curl -u $NEXUS_USERNAME:$NEXUS_PASSWORD --request POST $NEXUSRI
   ```

#### Adding/Removing a repo from Zypper

1. (`ncn-mw#`) Add the repository with the Zypper command to the current node:

   ```bash
   NXSREPO=https://packages.local/repository/$REPO
   zypper ar --no-gpgcheck $NXSREPO $REPO
   ```

1. (`ncn-mw#`) List the defined Zypper repositories filtered by the new Nexus repo:

   ```bash
   zypper lr -u | grep $REPO
   ```

1. (`ncn-mw#`) Refresh the Zypper repository cache:

   ```bash
   zypper ref
   ```

1. (`ncn-mw#`) Confirm the new rpm can be found by Zypper:

   ```bash
   zypper pa $REPO
   ```

1. (`ncn-mw#`) Remove the Zypper repo from the current node:

   ```bash
   zypper rr $REPO
   ```

#### Removing a Repo from Nexus

(`ncn-mw#`) Use the following function to remove a repo from Nexus:

```bash
function nexus-delete-repo() {
    local name="${1:-}"
    local error
    echo >&2 "Deleting $name ..."
    if ! curl \
    -f \
    -L \
    -v \
    -u "${NEXUS_USERNAME}":"${NEXUS_PASSWORD}" \
    -X DELETE \
    "${NEXUS_URL}/service/rest/v1/repositories/${name}" ; then
        error=1
    fi
    if [ "$error" -ne 0 ]; then
        echo >&2 'Errors found.'
    else
        echo 'Done'
    fi
    return "$error"
}
```

```bash
NEXUS_URL=https://packages.local
nexus-delete-repo sample-repo
```

## Container registry

(`ncn-mw#`) The container registry is available at `https://registry.local` on the NCNs or compute nodes. By default, access to the container registry
is not available over the Customer Access Network \(CAN\). If desired, a corresponding route may be added to the `nexus` `VirtualService` resource in the
`nexus` namespace:

**WARNING:** If access to the container registry in Nexus is exposed over CAN, it is strongly recommended to setup and configure fine-grained access control.
However, the default setup assumes the OPA policy only permits administrative users access.

```bash
kubectl -n nexus get vs nexus
```

Example output:

```text
NAME    GATEWAYS                      HOSTS                                                     AGE
nexus   [services/services-gateway]   [packages.local registry.local nexus.odin.dev.cray.com]   21d
```

### Adding images

Images can only be added to the container registry through the Docker API. To push images, product installers will need to use a compatible client, such as Skopeo, Podman, or Docker.

By default, product installers depend on Podman, paired with a vendor-specific Skopeo image, to synchronize container images from a release distribution to `registry.local`.
The Cray System Management \(CSM\) product adds a recent version of `quay.io/skopeo/stable` to the container registry, and it may be used to copy images into
`registry.local`.

From CSM `1.6.0`, the container images are signed and signatures are available along with the images. These signatures must be copied to Nexus along with the container images.

#### Ensure that you have the following prerequisites in place before adding images

- Valid credentials for both Artifactory and Nexus:
    - `ARTIFACTORY_USERNAME` & `ARTIFACTORY_TOKEN`
    - `NEXUS_USERNAME` & `NEXUS_PASSWORD`
- The Nexus registry is up & running.
- CSM Docker images have already been pushed to Artifactory.

Example: Upload the image `artifactory.algol60.net/csm-docker/stable/amazon/aws-cli:latest` using following command.

```bash
podman run --rm \
  registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/skopeo/stable:v1 \
  sync --all \
    --src-tls-verify=false \
    --src-creds "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_TOKEN}" \
    --dest-creds "${NEXUS_USERNAME}:${NEXUS_PASSWORD}" \
    --dest-tls-verify=false \
    --src docker \
    --dest docker \
    --format oci \
    artifactory.algol60.net/csm-docker/stable/amazon/aws-cli\:latest \
    registry.local/artifactory.algol60.net/csm-docker/stable/amazon
```

Corresponding output:

```text
Getting image source signatures
Checking if image destination supports signatures
Copying blob sha256:12ad2aecf25ecc57687aabc01ea39fa31c5e2feca6d83cb7910c5400e26e231a
Copying blob sha256:dae20f1e149603a860c328aed919c488e37a2d510d7eced1479a92b230b54fd7
Copying blob sha256:5988150955c78d228263e2ee75db073f251cbbae8b9879e036f5271b1d66523f
Copying blob sha256:37373184fe69e0fc20370c26317bf4c5b9b843c60b375563d4ee1c7766a89782
Copying blob sha256:3cf2d07cbbca11902445f57e6365c9fb5a31e92fe8f525d3ef9fc7a3232ad2e1
Copying blob sha256:50942d897f992e94b4685b904f45bd52b76bea9a4ef57c61e7592674d596a8dd
Copying config sha256:74bd2f6f62afddb128691920e64818dac6fad1a07ca1ad8f4ad861047cbb7447
Writing manifest to image destination
Storing signatures
time="2025-07-02T06:41:57Z" level=info msg="Synced 1 images from 1 sources"

```

This ensures that both the image and its signature (if available) are successfully uploaded to Nexus.

### Registry mirror configuration

Kubernetes pods are expected to rely on the registry mirror configuration in `/etc/containerd/config.toml` to automatically fetch container images from it
using upstream references. By default, the following upstream registries are automatically redirected to `registry.local`:

- `dtr.dev.cray.com`
- `docker.io` \(and `registry-1.docker.io`\)
- `quay.io`
- `gcr.io`
- `k8s.gcr.io`

**WARNING:** The registry mirror configuration in `/etc/containerd/config.toml` only applies to the CRI. When using the `ctr` command or another
container runtime \(For example, `podman` or `docker`\), the administrator must explicitly reference `registry.local`.

### Pull example using CRI

(`ncn-mw#`) The following is an example of pulling `dtr.dev.cray.com/baseos/alpine:3.12.0` using CRI:

```bash
crictl pull dtr.dev.cray.com/baseos/alpine:3.12.0
```

Example output:

```text
Image is up to date for sha256:5779738096ecb47dd7192d44ceef7032110edd38204f66c9ca4e35fca952975c
```

### Pull example using `containerd`

Using `containerd` or Podman requires changing `dtr.dev.cray.com` to `registry.local` in order to guarantee that the runtime fetches the image from the
container registry in Nexus.

(`ncn-mw#`) The following is an example for `containerd`:

```bash
ctr image pull registry.local/baseos/alpine:3.12.0
```

Example output:

```text
registry.local/baseos/alpine:3.12.0:                                              resolved       |++++++++++++++++++++++++++++++++++++++|
manifest-sha256:e25f4e287fad9c0ee0a47af590e999f9ff1f043fb636a9dc7a61af6d13fc40ca: done           |++++++++++++++++++++++++++++++++++++++|
layer-sha256:3ab6766f6281be4c2349e2122bab3b4d1ba1b524236b85fce0784453e759b516:    done           |++++++++++++++++++++++++++++++++++++++|
layer-sha256:df20fa9351a15782c64e6dddb2d4a6f50bf6d3688060a34c4014b0d9a752eb4c:    done           |++++++++++++++++++++++++++++++++++++++|
layer-sha256:62694d7552ccd2338f8a4d775bef09ea56f6d2bcfdfafb9e2a4e0241f360fca5:    done           |++++++++++++++++++++++++++++++++++++++|
config-sha256:5779738096ecb47dd7192d44ceef7032110edd38204f66c9ca4e35fca952975c:   done           |++++++++++++++++++++++++++++++++++++++|
elapsed: 0.2 s                                                                    total:   0.0 B (0.0 B/s)
unpacking linux/amd64 sha256:e25f4e287fad9c0ee0a47af590e999f9ff1f043fb636a9dc7a61af6d13fc40ca...
done
```

### Pull example using Podman

(`ncn-mw#`) The following is an example for Podman:

```bash
podman pull registry.local/baseos/alpine:3.12.0
```

Example output:

```text
Trying to pull registry.local/baseos/alpine:3.12.0...
Getting image source signatures
Copying blob df20fa9351a1 [--------------------------------------] 0.0b / 0.0b
Copying blob 3ab6766f6281 [--------------------------------------] 0.0b / 0.0b
Copying blob 62694d7552cc [--------------------------------------] 0.0b / 0.0b
Copying config 5779738096 done
Writing manifest to image destination
Storing signatures
5779738096ecb47dd7192d44ceef7032110edd38204f66c9ca4e35fca952975c
```
