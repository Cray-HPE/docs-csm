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

(`ncn-w#`) Run these checks on each worker node, in order to verify that it was configured correctly.

1. Verify that the SBPS Marshal Agent is running without any errors.

    ```bash
    systemctl status sbps-marshal
    ```

    Beginning of example output:

    ```text
    ● sbps-marshal.service - System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary images similar to PE.
         Loaded: loaded (/usr/lib/systemd/system/sbps-marshal.service; enabled; vendor preset: disabled)
         Active: active (running) since Thu 2024-08-22 11:57:48 UTC; 2 weeks 4 days ago
       Main PID: 2878373 (sbps-marshal)
          Tasks: 1
         CGroup: /system.slice/sbps-marshal.service
                 └─ 2878373 /usr/lib/sbps-marshal/bin/python /usr/lib/sbps-marshal/bin/sbps-marshal
    ```

1. Verify that the images/LUN mappings are created.

    Check to see if the `targetcli ls` output shows that `fileio` backing store are created for `rootfs` images,
    along with corresponding iSCSI LUNs. These should have the `rootfs` ID being mapped and network portals created (HSN and NMN).

    ```bash
    targetcli ls
    ```

    Example output:

    ```text
    o- / ......................................................................................................................... [...]
      o- backstores .............................................................................................................. [...]
      | o- block .................................................................................................. [Storage Objects: 0]
      | o- fileio ................................................................................................. [Storage Objects: 4]
      | | o- 059c573240acc07  [/var/lib/cps-local/boot-images/1681d5d6-bfaf-41e6-9dd4-2cc355314476/rootfs (3.7GiB) write-thru activated]
      | | | o- alua ................................................................................................... [ALUA Groups: 1]
      | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
      | | o- 553a9957f5efcbf  [/var/lib/cps-local/boot-images/c434edc1-8080-43c5-8393-4ab831d9eb00/rootfs (2.1GiB) write-thru activated]
      | | | o- alua ................................................................................................... [ALUA Groups: 1]
      | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
      | | o- ad7d9e9736a1b8a  [/var/lib/cps-local/boot-images/f1d6c8fe-32e2-420a-a051-377e34a8bd8a/rootfs (3.6GiB) write-thru activated]
      | | | o- alua ................................................................................................... [ALUA Groups: 1]
      | | |   o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
      | | o- cd5c6354b0d12d2  [/var/lib/cps-local/boot-images/6e993608-068a-4f6d-8d3f-b904ff7d3602/rootfs (3.7GiB) write-thru activated]
      | |   o- alua ................................................................................................... [ALUA Groups: 1]
      | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
      | o- pscsi .................................................................................................. [Storage Objects: 0]
      | o- ramdisk ................................................................................................ [Storage Objects: 0]
      | o- rbd .................................................................................................... [Storage Objects: 0]
      o- iscsi ............................................................................................................ [Targets: 1]
      | o- iqn.2023-06.csm.iscsi:ncn-w001 .................................................................................... [TPGs: 1]
      |   o- tpg1 .................................................................................................. [gen-acls, no-auth]
      |     o- acls .......................................................................................................... [ACLs: 0]
      |     o- luns .......................................................................................................... [LUNs: 4]
      |     | o- lun0  [fileio/ad7d9e9736a1b8a (/var/lib/cps-local/boot-images/f1d6c8fe-32e2-420a-a051-377e34a8bd8a/rootfs) (default_tg_pt_gp)]
      |     | o- lun1  [fileio/cd5c6354b0d12d2 (/var/lib/cps-local/boot-images/6e993608-068a-4f6d-8d3f-b904ff7d3602/rootfs) (default_tg_pt_gp)]
      |     | o- lun2  [fileio/059c573240acc07 (/var/lib/cps-local/boot-images/1681d5d6-bfaf-41e6-9dd4-2cc355314476/rootfs) (default_tg_pt_gp)]
      |     | o- lun3  [fileio/553a9957f5efcbf (/var/lib/cps-local/boot-images/c434edc1-8080-43c5-8393-4ab831d9eb00/rootfs) (default_tg_pt_gp)]
      |     o- portals .................................................................................................... [Portals: 3]
      |       o- 10.102.193.24:3260 ............................................................................................... [OK]
      |       o- 10.252.1.9:3260 .................................................................................................. [OK]
      |       o- 10.253.0.2:3260 .................................................................................................. [OK]
      o- loopback ......................................................................................................... [Targets: 0]
      o- vhost ............................................................................................................ [Targets: 0]
      o- xen-pvscsi ....................................................................................................... [Targets: 0]
    ```

1. Verify that all the DNS SRV and A records are configured for all the intended worker nodes.

    ```bash
    dig -t SRV +short _sbps-hsn._tcp.odin.hpc.amslabs.hpecorp.net _sbps-nmn._tcp.odin.hpc.amslabs.hpecorp.net
    ```

    Example output:

    ```text
    1 0 3260 iscsi-server-id-001.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-004.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-006.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-002.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-003.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-005.hsn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-004.nmn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-001.nmn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-005.nmn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-003.nmn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-002.nmn.odin.hpc.amslabs.hpecorp.net.
    1 0 3260 iscsi-server-id-006.nmn.odin.hpc.amslabs.hpecorp.net.
    ```

    ```bash
    dig -t A +short iscsi-server-id-005.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-002.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-004.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-006.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-001.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-003.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-006.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-004.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-001.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-005.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-003.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-002.nmn.odin.hpc.amslabs.hpecorp.net.
    ```

    Example output:

    ```text
    10.253.0.6
    10.253.0.16
    10.253.0.18
    10.253.0.20
    10.253.0.2
    10.253.0.4
    10.252.1.7
    10.252.1.9
    10.252.1.12
    10.252.1.8
    10.252.1.10
    10.252.1.11
    ```

1. Run readiness checks.

    After worker node personalization, in order to verify the overall readiness of the iSCSI targets before booting compute nodes or UANs,
    run GOSS tests to do additional verification of the iSCSI targets.

    See [GOSS tests for SBPS](https://github.com/Cray-HPE/sbps-marshal/blob/main/GOSS_tests_for_sbps.md) for more information.
