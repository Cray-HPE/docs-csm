# CSM 1.0.1 Patch Installation Instructions

## Steps

1. [Preparation](#preparation)
1. [Setup Nexus](#setup-nexus)
1. [Upgrade Services](#upgrade-services)
1. [Rollout Deployment Restart](#rollout-deployment-restart)
1. [Verification](#verification)
1. [Exit Typescript](#exit-typescript)

<a name="preparation"></a>

## Preparation

1. Start a typescript on `ncn-m001` to capture the commands and output from this procedure.

   ```bash
   ncn-m001# script -af csm-update.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and extract the CSM 1.0.1 release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/index.md#download-and-extract).

1. Set `CSM_DISTDIR` to the directory of the extracted files:

   **IMPORTANT**: If necessary, be sure to change this example command to match the actual location of the extracted files.

   ```bash
   ncn-m001# export CSM_DISTDIR="$(pwd)/csm-1.0.1"
   ```

1. Set `CSM_RELEASE_VERSION` to the version reported by `${CSM_DISTDIR}/lib/version.sh`:

   ```bash
   ncn-m001# CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   ncn-m001# echo $CSM_RELEASE_VERSION
   ```

1. Download and install/upgrade the _latest_ documentation and workarounds RPMs on `ncn-m001`.

   See [Check for Latest Workarounds and Documentation Updates](../../update_product_stream/index.md#workarounds).

1. Resets known_hosts on storage nodes. These change during the upgrade procedure and result in invalid known_hosts file that prevents password-less SSH between storage nodes.

```bash
ncn-m001# grep -oP "(ncn-s\w+)" /etc/hosts | sort -u | xargs -t -i ssh {} 'truncate --size=0 ~/.ssh/known_hosts'

ncn-m001# grep -oP "(ncn-s\w+)" /etc/hosts | sort -u | xargs -t -i ssh {} 'grep -oP "(ncn-s\w+|ncn-m\w+|ncn-w\w+)" /etc/hosts | sort -u | xargs -t -i ssh-keyscan -H \{\} >> /root/.ssh/known_hosts'
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
+ Nexus setup complete
setup-nexus.sh: OK
ncn-m001# echo $?
0
```

In the event of an error, consult [Troubleshoot Nexus](../../operations/package_repository_management/Troubleshoot_Nexus.md)
to resolve potential problems and then try running `setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is ok as long as `setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits
with status code `0`.

<a name="upgrade-services"></a>

## Upgrade Services

Run `upgrade.sh` to deploy upgraded CSM applications and services:

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

### Verify CSM Version in Product Catalog

1. Verify that the following command includes the new CSM version:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   0.9.2
   0.9.3
   0.9.4
   0.9.5
   0.9.6
   1.0.0
   1.0.1
   ```

1. Confirm the `import_date` reflects the timestamp of the upgrade:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.0.1".configuration.import_date'
   ```

<a name="exit-typescript"></a>

## Exit Typescript

Remember to exit your typescript.

```bash
ncn-m001# exit
```

It is recommended to save the typescript file for later reference.
