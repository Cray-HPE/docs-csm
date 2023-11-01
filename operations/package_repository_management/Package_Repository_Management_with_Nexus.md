# Package Repository Management with Nexus

Overview of RPM repositories and container registry in Nexus.

- [RPM repositories](#rpm-repositories)
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

The only way to add images to the container registry is with the Docker API. Use a client \(such as Skopeo, Podman, or Docker\) to push images. By default,
product installers use Podman with a vendor version of the [Skopeo](https://github.com/containers/skopeo) image to sync container images included in a release
distribution to `registry.local`.

The Cray System Management \(CSM\) product adds a recent version of `quay.io/skopeo/stable` to the container registry, and it may be used to copy images into
`registry.local`.

(`ncn-mw#`) For example, to update the version of `quay.io/skopeo/stable`:

```bash
podman run --rm registry.local/skopeo/stable copy --dest-tls-verify=false docker://quay.io/skopeo/stable docker://registry.local/skopeo/stable
```

Example output:

```text
Getting image source signatures
Copying blob sha256:85a74b04b5b84b45c763e9763cc0f62269390bb30058d3e2b2545d820d3558f7
Copying blob sha256:ab9d1e8c4764f52ed5041c38bd3d64b6ae9c27d0f436be50f658ece38440a97b
Copying blob sha256:e5c8e56645c4d70308640ede3f72f76386b466cf5d97010b9c2f31054caf30a5
Copying blob sha256:bcf471c5e964dc3ce3e7249bd2b1493acf3dd103a28af0cfe5af70351ad399d0
Copying blob sha256:d62975d5ffa72581b912ee3e1a850e2ac14435a4238253a8ebf80f5d10f2df4c
Copying blob sha256:8c87d899c1ab2cc2d25708ba0ff9a1726fe6b57bf415c8fdc7de973e6b185f63
Copying config sha256:49f2b6d9790b48aadb2ac29f5bfef56ebb2fccec6319b3981639d04452887848
Writing manifest to image destination
Storing signatures
```

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
