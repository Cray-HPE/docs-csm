Copyright 2021 Hewlett Packard Enterprise Development LP


# CSM 0.9 Patch Upgrade Guide

- [About](#about)
  - [Release-Specific Procedures](#release-specific-procedures)
  - [Common Environment Variables](#common-environment-variables)
- [Preparation](#preparation)
- [Update Customizations](#update-customizations)
- [Setup Nexus](#setup-nexus)
- [Deploy Manifests](#deploy-manifests)
- [Upgrade NCN RPMs](#upgrade-ncn-rpms)
- [Post-Upgrade Actions](#post-upgrade-actions)
  - [Switch VCS Configuration Repositories to Private](#switch-vcs-configuration-repositories-to-private)
  - [Configure Prometheus Alert Notifications to Detect Postgres Replication Lag](#configure-prometheus-alert-notifications-to-detect-postgres-replication-lag)
- [Run Validation Checks](#run-validation-checks)


<a name="about"></a>
## About

This guide contains procedures for upgrading systems running CSM 0.9 to the
latest available patch release. It is intended for system installers, system
administrators, and network administrators. It assumes some familiarity with
standard Linux and associated tooling.

See CHANGELOG.md in the root of a CSM release distribution for a summary of
changes in each CSM release.


<a name="release-specific-procedures"></a>
### Release-Specific Procedures

Select procedures are annotated to indicate they are only applicable to
specific Shasta patch releases.

> **`WARNING:`** Follow this procedure only when upgrading to CSM 0.9.1.

> **`WARNING:`** Follow this procedure only when upgrading from CSM 0.9.0.


<a name="common-environment-variables"></a>
### Common Environment Variables

For convenience, these procedures make use of the following environment
variables. Be sure to set them to the appropriate values before proceeding.

- `CSM_RELEASE` - The CSM release version, e.g., `0.9.1`.
- `CSM_DISTDIR` - The directory of the _extracted_ CSM release distribution.
- `SITE_INIT_REPO_URL` - URL to remote `site-init` Git repository.


<a name="preparation"></a>
## Preparation

The remainder of this guide assumes the new CSM release distribution has been
extracted at `$CSM_DISTDIR`.

> **`NOTE`**: Use `--no-same-owner` and `--no-same-permissions` options to
> `tar` when extracting a CSM release distribution as `root` to ensure the
> extracted files are owned by `root` and have permissions based on the current
> `umask` value.

List current CSM versions in the product catalog:

```bash
ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//'
```

Run `${CSM_DISTDIR}/lib/version.sh` to verify that the intended CSM release is
being used for the upgrade.


<a name="update-customizations"></a>
## Update Customizations

Before [deploying upgraded manifests](#deploy-manifests), `customizations.yaml`
in the `site-init` secret in the `loftsman` namespace must be updated.

1. If the [`site-init` repository is available as a remote
   repository](../../067-SHASTA-CFG.md#push-to-a-remote-repository) then clone
   it on the host orchestrating the upgrade:

   ```bash
   ncn-m001# git clone "$SITE_INIT_REPO_URL" site-init
   ```

   Otherwise, create a new `site-init` working tree:

   ```bash
   ncn-m001# ${CSM_DISTDIR}/shasta-cfg/meta/init.sh site-init
   ```

2. Download the sealed secret decryption key:

   ```bash
   ncn-m001# mkdir -p site-init/certs
   ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d > site-init/certs/sealed_secrets.crt
   ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d > site-init/certs/sealed_secrets.key
   ```

3. Download `customizations.yaml`:

   ```bash
   ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

4. Review, add, and commit `customizations.yaml` to the local `site-init`
   repository as appropriate.

   > **`NOTE`**: If `site-init` was cloned from a remote repository in step 1,
   > there may not be any differences and hence nothing to commit. This is
   > okay.

   ```bash
   ncn-m001# cd site-init
   ncn-m001# git diff
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Add customizations.yaml from site-init secret'
   ```

5. Run `${CSM_DISTDIR}/shasta-cfg/meta/init.sh` to update the contents of
   `site-init` from the patch release distribution:

   > **`NOTE:`** If `site-init` was not cloned from a remote repository, this
   > will be the second time running `meta/init.sh`. This is intentional since
   > step 2 will have replaced the sealed secret decryption key and step 3 will
   > have overwritten `customizations.yaml`.

   ```bash
   ncn-m001# ${CSM_DISTDIR}/shasta-cfg/meta/init.sh .
   ```

6. Review the changes to `customizations.yaml` and verify [baseline system
   customizations](../../067-SHASTA-CFG.md#create-baseline-system-customizations)
   are correct.

7. Commit `site-init` changes and push to the remote repository, as
   appropriate.

8. Update `site-init` sealed secret in `loftsman` namespace:

   ```bash
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```


<a name="setup-nexus"></a>
## Setup Nexus

Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
ncn-m001# ${CSM_DISTDIR}/lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output to `OK` on stderr and exit with status
code `0`, e.g.:

```bash
ncn-m001# ${CSM_DISTDIR}/lib/setup-nexus.sh
...
+ Nexus setup complete
setup-nexus.sh: OK
```

In the event of an error, consult the [known
issues](../../006-CSM-PLATFORM-INSTALL.md#known-issues) from the install
documentation to resolve potential problems and then try running
`setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is ok as long as
`setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits with status code `0`.


<a name="deploy-manifests"></a>
## Deploy Manifests

Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m001# ${CSM_DISTDIR}/upgrade.sh
```


## Upgrade NCN RPMs

TODO Use CFS?


<a name="post-upgrade-actions"></a>
## Post-Upgrade Actions


<a name="switch-vcs-configuration-repositories-to-private"></a>
### Switch VCS Configuration Repositories to Private

Previous installs of CSM and other Cray products created git repositories in
the VCS service which were set to be publicly visible. To enhance security,
please follow the instructions in the Admin guide, chapter 12, "Version Control
Service (VCS)" section to switch the visibility of all `*-config-management`
repositories to private.

Future installations of configuration content into Gitea by CSM and other Cray
products will create or patch repositories to private visibility automatically.

As a result of this change, `git clone` operations will now require
credentials. CSM services that clone repositories have been upgraded to use the
`crayvcs` user to clone repositories.


<a name="configure-prometheus-alert-notifications-to-detect-postgres-replication-lag"></a>
### Configure Prometheus Alert Notifications to Detect Postgres Replication Lag

Three new Prometheus alert definitions have been added in CSM 0.9.1 for
monitoring replication across Postgres instances, which are used by some system
management services.  The new alerts are `PostgresqlReplicationLagSMA` (for
Postgres instances in the `sma` namespace), `PostgresqlReplicationLagServices`
(for Postgres instances in all other namespaces), and
`PostgresqlInactiveReplicationSlot`.

In the event that a state of broken Postgres replication persists to the extent
that space allocated for its WAL files fills-up, the affected database will
likely shut down and create a state where it cannot be brought up again.  This
can impact the reliability of the related service and can require that it be
redeployed with data re-population procedures.

To avoid this unexpected, but possible event, it is recommended that all
administrators configure Prometheus alert notifications for the early detection
of Postgres replication lag and, if notified, swiftly follow the suggested
remediation actions (to avoid service down-time).

Please access the relevant sections of the [1.4 HPE Cray EX System
Administration Guide] for information about how to configure Prometheus Alert
Notifications ("System Management Health Checks and Alerts" sub-section under
"Monitor the System") and how to re-initialize a Postgres cluster encountering
signs of replication lag ("About Postgres" sub-section under "Kubernetes
Architecture").

[1.4 HPE Cray EX System Administration Guide]: https://connect.us.cray.com/confluence/download/attachments/186435146/HPE_Cray_EX_System_Administration_Guide_1.4_S-8001_RevA.pdf?version=1&modificationDate=1616193177450&api=v2


<a name="run-validation-checks"></a>
## Run Validation Checks

Wait at least 15 minutes to let the various Kubernetes resources get
initialized and started, and then run the [CSM validation
checks](../../008-CSM-VALIDATION.md).
