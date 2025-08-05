# iSCSI SBPS Worker Node Personalization

The iSCSI SBPS solution requires worker nodes to be configured as iSCSI targets (servers) with necessary
provisioning, configuration, and enablement of required components. This is done using
[CFS](../../glossary.md#configuration-framework-service-cfs)-based Ansible plays which do the following things:

* Provision iSCSI targets and LIO services.
* Present the LIO network service on the HSN and [NMN](../../glossary.md#node-management-network-nmn)
  IP networks (TCP port 3260 by default), via iSCSI Portals.
* Enable SBPS Marshal Agent by installing the agent RPM and starting the respective `systemd` service (`sbps-marshal`).
* Enable Spire for authentication used for [IMS](../../glossary.md#image-management-service-ims) and
  [S3](../../glossary.md#simple-storage-service-s3) access.
* Create DNS records in order to discover iSCSI targets from iSCSI initiators/clients (passed as boot parameter).
* Mount S3 images (`boot-images` bucket) read-only with new, dedicated S3 user (`ISCSI-SBPS`)
* Apply Kubernetes label (`iscsi=sbps`), to be consumed by the Goss test suit and LIO Metrics, for identification of
  nodes on which these have to run.

Target worker node selection is via dynamic inventory stored in [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm).
The default is all worker nodes (`Management_Worker` group).

The LUN projection is over either HSN or NMN.

* [Prerequisites](#prerequisites)
* [Procedure](#procedure)
    * [Create new CFS configuration](#create-new-cfs-configuration)
    * [Create new CFS session](#create-new-cfs-session)
    * [Monitor CFS session](#monitor-cfs-session)
        * [Check status of CFS session](#check-status-of-cfs-session)
        * [Track the status of Ansible playbooks](#track-the-status-of-ansible-playbooks)
    * [Post-personalization verification](#post-personalization-verification)

## Prerequisites

* CSM 1.6 or higher
* CSM documentation installed on the node where the procedure is being followed.
  See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).
* Cray CLI must be configured on the node where the procedure is being followed.
  See [Configure the Cray CLI](../configure_cray_cli.md).

## Procedure

(`ncn-mw#`) Below is the procedure (with examples) that need to be followed for worker node personalization for iSCSI SBPS.

### Create new CFS configuration

1. Determine the latest commit in the `csm-config-management` [VCS](../../glossary.md#version-control-service-vcs) repository.

    ```bash
    COMMIT=$(/usr/share/doc/csm/scripts/operations/configuration/get_git.py | awk '{ print $NF }'); echo "$COMMIT"
    ```

    Example output:

    ```text
    3bb1fce7d7de4c2cce237ab19dd6f239158d6d07
    ```

1. Create an input file for the CFS configuration.

    ```bash
    cat << EOF > iscsi-sbps-targets-config.json
    {
      "layers": [
        {
          "clone_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
          "commit": "${COMMIT}",
          "name": "iscsi-sbps-iscsi-targets-config",
          "playbook": "config_sbps_iscsi_targets.yml"
        }
      ]
    }
    EOF
    ```

1. Create a CFS configuration.

    See [CFS Configuration](CFS_Configurations.md) for more information.

    ```bash
    cray cfs v3 configurations update iscsi-sbps-targets-config --file ./iscsi-sbps-targets-config.json --format json
    ```

    Example output:

    ```json
    {
      "last_updated": "2024-08-31T21:05:52Z",
      "layers": [
        {
          "clone_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
          "commit": "3bb1fce7d7de4c2cce237ab19dd6f239158d6d07",
          "name": "iscsi-sbps-iscsi-targets-config",
          "playbook": "config_sbps_iscsi_targets.yml"
        }
      ],
      "name": "iscsi-sbps-targets-config"
    }
    ```

### Create new CFS session

1. Choose a name for the new CFS session.

    ```bash
    SESSION=iscsi-config-$(date +%Y%m%d%H%M%S)
    ```

1. Create CFS session with new CFS configuration.

    See [CFS Sessions](CFS_Sessions.md) for more information.

    ```bash
    cray cfs v3 sessions create --name "${SESSION}" --configuration-name iscsi-sbps-targets-config --format json
    ```

    Example output:

    ```json
    {
      "ansible": {
        "config": "cfs-default-ansible-cfg",
        "limit": "",
        "passthrough": "",
        "verbosity": 0
      },
      "configuration": {
        "limit": "",
        "name": "iscsi-sbps-targets-config"
      },
      "debug_on_failure": false,
      "logs": "ara.cmn.surtur.hpc.amslabs.hpecorp.net/?label=iscsi-sbps-targets-config",
      "name": "iscsi-config-20240831210845",
      "status": {
        "artifacts": [],
        "session": {
          "completion_time": null,
          "ims_job": null,
          "job": null,
          "start_time": "2024-08-31T21:08:47",
          "status": "pending",
          "succeeded": "none"
        }
      },
      "tags": {},
      "target": {
        "definition": "dynamic",
        "groups": [],
        "image_map": []
      }
    }
    ```

Note:
For specific target worker nodes selection for node personalization (instead of default: to all workers)
use CFS option `--ansible-limit` with xnames of the worker nodes while creating a session.

```bash
cray cfs v3 sessions create --name <session_name> --configuration-name <config_name> --ansible-limit <xname1,xname2,...>
```

### Monitor CFS session

#### Check status of CFS session

See [View CFS Sessions](CFS_Sessions.md) for more information.

```bash
cray cfs v3 sessions describe "${SESSION}" --format toml
```

```toml
debug_on_failure = false
logs = "ara.cmn.surtur.hpc.amslabs.hpecorp.net/?label=iscsi-sbps-targets-config"
name = "iscsi-config-20240831210845"

[ansible]
config = "cfs-default-ansible-cfg"
limit = ""
passthrough = ""
verbosity = 0

[configuration]
limit = ""
name = "iscsi-sbps-targets-config"

[status]
artifacts = []

[tags]

[target]
definition = "dynamic"
groups = []
image_map = []

[status.session]
completion_time = "2024-08-31T21:09:19"
job = "cfs-b840455c-e919-4656-b64a-44d433f082dc"
start_time = "2024-08-31T21:08:47"
status = "complete"
succeeded = "True"
```

#### Track the status of Ansible playbooks

Make sure that all the CFS play books have completed successfully.
Look for the message "All playbooks completed successfully" in the CFS Ansible container log.

See [Troubleshooting](Track_the_Status_of_a_Session.md) for more information.

1. Get name of CFS pod.

    ```bash
    CFSPOD=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" -n services -l cfsession=${SESSION}) ; echo $CFSPOD
    ```

    Example output:

    ```text
    cfs-b840455c-e919-4656-b64a-44d433f082dc-5d4jp
    ```

1. View the last line of Ansible container log.

    ```bash
    kubectl logs -n services "${CFSPOD}" -c ansible --tail=1
    ```

    Example of output if CFS was successful:

    ```text
    All playbooks completed successfully
    ```

### Post-personalization verification

After personalization has completed successfully, it is recommended to validate the iSCSI configuration.
See [iSCSI SBPS Verification](../iscsi_sbps/iSCSI_SBPS_Verification.md).
