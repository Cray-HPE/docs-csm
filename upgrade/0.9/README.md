Copyright 2021 Hewlett Packard Enterprise Development LP


# CSM 0.9 Patch Upgrade Guide

- [About](#about)
  - [Common Environment Variables](#common-environment-variables)
  - [Version-Specific Procedures](#version-specific-procedures)
- [Preparation](#preparation)
- [Update Customizations](#update-customizations)
- [Setup Nexus](#setup-nexus)
- [Deploy Manifests](#deploy-manifests)
- [Upgrade NCN RPMs](#upgrade-ncn-rpms)
- [Post-Upgrade Actions](#post-upgrade-actions)
- [Update BGP Configuration](#update-bgp-configuration)
- [Configure LAG for CMMs](#config-cmm-lag)
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


<a name="common-environment-variables"></a>
### Common Environment Variables

For convenience, these procedures make use of the following environment
variables. Be sure to set them to the appropriate values before proceeding.

- `CSM_SYSTEM_VERSION` - The version of CSM installed on the system, e.g., `0.9.0`.
- `CSM_RELEASE_VERSION` - The CSM release version, e.g., `0.9.1`.
- `CSM_DISTDIR` - Absolute path to the directory of the _extracted_ CSM release distribution.
- `SITE_INIT_REPO_URL` - URL to remote `site-init` Git repository.


<a name="version-specific-procedures"></a>
### Version-Specific Procedures

Procedures may be annotated to indicate they are only applicable to specific
CSM versions using [version
specifiers](https://www.python.org/dev/peps/pep-0440/#version-specifiers)
matching against `$CSM_SYSTEM_VERSION` or `$CSM_RELEASE_VERSION`. The following
comparison operators may be used:

| Operator   | Meaning                                                           | Example                                                                                                                                                                                                          |
| --------   | -------                                                           | -------                                                                                                                                                                                                          |
| `==`       | Version matching clause                                           | `$CSM_SYSTEM_VERSION == 0.9.0` is true if the version of CSM installed on the system is 0.9.0                                                                                                                    |
| `!=`       | Version exclusion clause                                          | `$CSM_SYSTEM_VERSION != 0.9.0` is true if the version of CSM installed on the system is **not** 0.9.0                                                                                                            |
| `<=`, `>=` | Inclusive ordered comparison clauses                              | `$CSM_RELEASE_VERSION <= 0.9.5` is true if the version of the CSM release distribution is at or before 0.9.5                                                                                                     |
| `<`, `>`   | Exclusive ordered comparison clauses                              | `$CSM_SYSTEM_VERSION > 0.9.5` is true if the version of CSM installed on the system is strictly after 0.9.5                                                                                                      |
| `,`        | Separates version clauses; equivalent to logical **and** operator | `$CSM_SYSTEM_VERSION < 0.9.5, $CSM_RELEASE_VERSION >= 1.0.0` is true if the version of CSM installed on the system is strictly before 0.9.5 and the version of the CSM release distribution is at or after 1.0.0 |


<a name="preparation"></a>
## Preparation

This guide assumes the release distribution for the new version of CSM has been
extracted at `$CSM_DISTDIR`.

> **`NOTE`**: Use `--no-same-owner` and `--no-same-permissions` options to
> `tar` when extracting a CSM release distribution as `root` to ensure the
> extracted files are owned by `root` and have permissions based on the current
> `umask` value.

Set `CSM_RELEASE_VERSION` to the version reported by `${CSM_DISTDIR}/lib/version.sh`:

```bash
ncn-m001# CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
```

Set `CSM_SYSTEM_VERSION` to the latest version listed in the catalog:

```bash
ncn-m001# CSM_SYSTEM_VERSION="$(kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -Vr | head -n 1 | sed 's/_$//')"
```

> **`NOTE`**: List all CSM versions in the product catalog using:
>
> ```bash
> ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//'
> ```


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
   ncn-m001# git init site-init
   ```

2. Download `customizations.yaml`:

   ```bash
   ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

3. Review, add, and commit `customizations.yaml` to the local `site-init`
   repository as appropriate.

   > **`NOTE`**: If `site-init` was cloned from a remote repository in step 1,
   > there may not be any differences and hence nothing to commit. This is
   > okay. If there are differences between what's in the repository and what
   > was stored in the `site-init`, then it suggest settings were improperly
   > changed at some point. If that's the case then be cautious, _there may be
   > dragons ahead_.

   ```bash
   ncn-m001# cd site-init
   ncn-m001# git diff
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Add customizations.yaml from site-init secret'
   ```

4. Update `customizations.yaml`. Perform the following procedures in order if
   the version specifier is satisfied:

   - `$CSM_SYSTEM_VERSION == 0.9.0`

     ```bash
     ncn-m001# yq d -i customizations.yaml spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources
     ```

5. Review the changes to `customizations.yaml` and verify [baseline system
   customizations](../../067-SHASTA-CFG.md#create-baseline-system-customizations)
   and any customer-specific settings are correct.

   ```
   ncn-m001# git diff
   ```

6. Add and commit `customimzations.yaml` if there are any changes:

   ```
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m "Update customizations.yaml consistent with CSM $CSM_RELEASE_VERSION"
   ```

7. Update `site-init` sealed secret in `loftsman` namespace:

   ```bash
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

8. Push to the remote repository as appropriate:

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

On success, `setup-nexus.sh` will output to `OK` on stderr and exit with status
code `0`, e.g.:

```bash
ncn-m001# ./lib/setup-nexus.sh
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
ncn-m001# ./upgrade.sh
```

<a name="upgrade-ncn"></a>
## Upgrade NCN RPMs

Some CSM upgrades will require a new RPM.  To get updated RPMs.
Run
```bash
ncn-w001:~ # for node in $(kubectl get nodes| awk '{print $1}'|grep -v NAME);do pdsh -w $node "zypper ar -fG https://packages.local/repository/csm-sle-15sp2 csm-sle-15sp2;zypper in -y hpe-csm-scripts";done
```

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

<a name="update-bgp-configuration"></a>
### Update BGP Configuration

If your Shasta system is using Aruba Management Switches you will need to run
an updated BGP script.


Below is an example. `10.252.0.2` & `10.252.0.3` being the switches running BGP.

```bash
ncn-w001:/opt/cray/csm/scripts/networking/BGP # ./Aruba_BGP_Peers.py 10.252.0.2 10.252.0.3
```

Once that's complete, the static routes configured in [LAYER3-CONFIG](../../411-MGMT-NET-LAYER3-CONFIG.md) will need to
be removed. Log into the switches running BGP (Spines/Aggs) and remove them.

```bash
sw-spine-001(config)# no ip route 10.92.100.60/32 10.252.1.10
sw-spine-001(config)# no ip route 10.94.100.60/32 10.252.1.10
```

Once that's complete verify the BGP configuration [BGP](../../400-SWITCH-BGP-NEIGHBORS.md)


<a name="config-cmm-lag"></a>
## Configure LAG for CMMs

If your Shasta system is using Aruba CDU switches you should follow the steps labeled
"CMM Port Configuration" located at the bottom of [MGMT-PORT-CONFIG](../../405-MGMT-NET-PORT-CONFIG.md) .  These 
instructions show how to setup Link Aggregation from the CMM Switch to the Aruba 
CDU switches.  This change will require physical access to the CEC and remote access
to the CDU Switches.

<a name="run-validation-checks"></a>
## Run Validation Checks

> **`IMPORTANT`** Wait at least 15 minutes after
> [`upgrade.sh`](#deploy-manifests) completes to let the various Kubernetes
> resources get initialized and started.

Run the [CSM validation checks](../../008-CSM-VALIDATION.md).

**Note**: The following HMS functional tests may fail due to locked components in HSM:

1. test_bss_bootscript_ncn-functional_remote-functional.tavern.yaml
2. test_smd_components_ncn-functional_remote-functional.tavern.yaml

```bash
        Traceback (most recent call last):
          File "/usr/lib/python3.8/site-packages/tavern/schemas/files.py", line 106, in verify_generic
            verifier.validate()
          File "/usr/lib/python3.8/site-packages/pykwalify/core.py", line 166, in validate
            raise SchemaError(u"Schema validation failed:\n - {error_msg}.".format(
        pykwalify.errors.SchemaError: <SchemaError: error code 2: Schema validation failed:
         - Key 'Locked' was not defined. Path: '/Components/0'.
         - Key 'Locked' was not defined. Path: '/Components/5'.
         - Key 'Locked' was not defined. Path: '/Components/6'.
         - Key 'Locked' was not defined. Path: '/Components/7'.
         - Key 'Locked' was not defined. Path: '/Components/8'.
         - Key 'Locked' was not defined. Path: '/Components/9'.
         - Key 'Locked' was not defined. Path: '/Components/10'.
         - Key 'Locked' was not defined. Path: '/Components/11'.
         - Key 'Locked' was not defined. Path: '/Components/12'.: Path: '/'>
```

Failures of these tests due to locked components as shown above can be safely ignored.
