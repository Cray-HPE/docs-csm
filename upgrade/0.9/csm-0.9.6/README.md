# CSM 0.9.6 Patch

This procedure covers applying a new version of the `cray-dns-unbound` Helm chart to enable this setting in the configmap:

```text
rrset-roundrobin: no
```

Unbound back in April 2020 [changed](https://github.com/NLnetLabs/unbound/blob/master/doc/Changelog) the default of this setting to be `yes` which had the effect of randomizing the records returned from it if more than one entry corresponded (as would be the case for PTR records, for example):

```text
21 April 2020: George
	- Change default value for 'rrset-roundrobin' to yes.
	- Fix tests for new rrset-roundrobin default.
```

Some software is especially sensitive to this and thus requires this setting to be `no`.

Procedures:

- [Preparation](#preparation)
- [Setup Nexus](#setup-nexus)
- [Upgrade Services](#upgrade-services)
- [Rollout Deployment Restart](#rollout-deployment-restart)
- [Verify CSM Version in Product Catalog](#verify-version)
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

<a name="verify-version"></a>
## Verify CSM Version in Product Catalog

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

<a name="exit-typescript"></a>
## Exit Typescript

Remember to exit your typescript.

```bash
ncn-m001# exit
```

It is recommended to save the typescript file for later reference.
