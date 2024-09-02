# iSCSI SBPS worker node(s) personalization

As part of the iSCSI SBPS solution, we need to setup/ configure worker nodes as iSCSI targets (servers) with necessary provisioning, configuration and enablement of required components.
In order to achieve this, CFS based Ansible plays (`csm-config`) are created and deployed in order to

* provision `iSCSI targets`/`LIO services` and present the `LIO network` service via the HSN and NMN IP networks (TCP port 3260 by default), via iSCSI Portals.

* enable SBPS Marshal Agent by installing the agent rpm and starting the respective `systemd` service (`sbps-marshal`).

* enable `spire` for authentication used for `IMS/ S3` access.

* create `DNS SRV and A records` in order to discover iSCSI targets from iSCSI initiators/clients (passed as boot parameter).

* mount S3 images (`boot-images` bucket) with new, dedicated S3 user (`ISCSI-SBPS`) read only bucket policy via `s3fs`.

* apply K8S label (`iscsi=sbps`), to be consumed by the Goss test suit and LIO Metrics for identification of nodes on which these have to run.

Target worker node selection is via dynamic inventory stored in HSM (Hardware State Manager) - the default is all worker nodes (`Management_Worker` group).
CFS Ansible plays here refers to `Management_Worker` group in the HSM.

The LUN projection is over either HSN or NMN.

## Prerequisites

* Respective `csm-config` version CFS Ansible plays are available at VCS (Version Control Service)
* On cluster nodes, the VCS can be accessed through the gateway. VCS credentials for the `crayvcs` user are required before cloning a repository.
  See [VCS Administrative User](Version_Control_Service_VCS.md#vcs-administrative-user) in
  [Version Control Service (VCS)](Version_Control_Service_VCS.md) for more information.

Below is the procedure (with examples) that need to be followed for worker node personalization for iSCSI SBPS. Please note that the "Optional" steps mentioned below
are only to get the latest version of the `csm-config` or to check if the known/ intended version of the `csm-config` is available before proceeding with node personalization
with creating the CFS config/ CFS session.

## Procedure

### Check the VCS availability

```text
ncn-m001:/home # /usr/local/bin/cmsdev test -q vcs
Starting main run, version: 1.22.0, tag: hMUDa
Starting sub-run, tag: hMUDa-vcs
Ended sub-run, tag: hMUDa-vcs (duration: 3.982640351s)
Ended run, tag: hMUDa (duration: 3.994254571s)
SUCCESS: All 1 service tests passed: vcs
```

### Get VCS credentials to login (Optional)

```text
ncn-m001:/home # echo $(kubectl get secret -n services vcs-user-credentials  --template={{.data.vcs_username}} | base64 -d)
crayvcs
```

```text
ncn-m001:/home # echo $(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 -d)
4ZKffXVZl97Zep3kLo0BJ-hSUzsIN0v6P95XjvjWV_4=
```

### Clone VCS repo and check the latest `csm-config` version (Optional)

```text
ncn-m001:/home # git clone https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git
Cloning into 'csm-config-management'...
Username for 'https://api-gw-service-nmn.local': crayvcs
Password for 'https://crayvcs@api-gw-service-nmn.local':
remote: Enumerating objects: 248, done.
remote: Counting objects: 100% (248/248), done.
remote: Compressing objects: 100% (92/92), done.
remote: Total 248 (delta 91), reused 234 (delta 84), pack-reused 0
Receiving objects: 100% (248/248), 55.31 KiB | 9.22 MiB/s, done.
Resolving deltas: 100% (91/91), done.
```

```text
ncn-m001:/home # cd csm-config-management/
```

```text
ncn-m001:/home/rk/csm-config-management # git branch -r

  origin/HEAD -> origin/main
  origin/cray/csm/1.22.0
  origin/integration-1.22.0
  origin/iscsi-sbps-test
  origin/main
```

### Create CFS config file as below

See [CFS Configuration](CFS_Configurations.md) for more information.

**E.g.**

```text
nc-m001:/home/csm-config-management # cat iscsi-sbps-targets-config.json
{
  "layers": [
    {
      "name": "iscsi-sbps-iscsi-targets-config",
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
      "playbook": "ansible/config_sbps_iscsi_targets.yml",
      "branch": "origin/iscsi-sbps-test"
    }
  ]
}
```

### Create CFS config

See [CFS Configuration](CFS_Configurations.md) for more information.

**E.g.**

```text
ncn-m001:/home/csm-config-management #  cray cfs v3 configurations update iscsi-sbps-targets-config --file ./iscsi-sbps-targets-config.json --format json
{
  "last_updated": "2024-08-31T21:05:52Z",
  "layers": [
    {
      "branch": "origin/iscsi-sbps-test",
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
      "commit": "0181c80aaf3e6ea2784ae57de2e02a0e940dc726",
      "name": "iscsi-sbps-iscsi-targets-config",
      "playbook": "ansible/config_sbps_iscsi_targets.yml"
    }
  ],
  "name": "iscsi-sbps-targets-config"
}
```

### Create CFS session with CFS config

See [CFS Sessions](CFS_Sessions.md) for more information.

**E.g.**

```text
ncn-m001:/home/csm-config-management # cray cfs v3 sessions create --name iscsi-sbps-targets-config --configuration-name iscsi-sbps-targets-config --format json
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
  "name": "iscsi-sbps-targets-config",
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

### To delete any old/ stale session with similar name

When you want to recreate the new CFS session with same name with that of an existing session for any reason
it may not allow it with the error _"Error: Conflicting session name: A session with the name iscsi-sbps-targets-config already exists"._

You can delete the old/ stale CFS session before creating the new CFS session again.

**E.g.**

```text
ncn-m001:/home/csm-config-management # cray cfs v3 sessions delete iscsi-sbps-targets-config
```

### View CFS session / check status

See [View CFS Sessions](CFS_Sessions.md) for more info.

**E.g.**

```text
ncn-m001:/home/csm-config-management # cray cfs v3 sessions describe  iscsi-sbps-targets-config
debug_on_failure = false
logs = "ara.cmn.surtur.hpc.amslabs.hpecorp.net/?label=iscsi-sbps-targets-config"
name = "iscsi-sbps-targets-config"

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

### Track the Status of Ansible playbooks

Make sure that all the CFS play books have completed successfully.
Look for the message "All playbooks completed successfully" in the CFS Ansible container log.

See [Troubleshooting](Track_the_Status_of_a_Session.md) for more info.

**E.g.**

```text
ncn-m001:/home/csm-config-management #  kubectl get pods --no-headers -o custom-columns=":metadata.name" -n services -l cfsession=iscsi-sbps-targets-config
cfs-b840455c-e919-4656-b64a-44d433f082dc-5d4jp
```

```text
ncn-m001:/home/csm-config-management #  kubectl logs -n services  cfs-b840455c-e919-4656-b64a-44d433f082dc-5d4jp ansible
Waiting for Inventory
Inventory generation completed
SSH keys migrated to /root/.ssh
...
Sidecar available
Running ansible/config_sbps_iscsi_targets.yml from repo https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git
....
All playbooks completed successfully
```

### Important things to check after worker node(s) personalization

#### Check to see if the SBPS Marshal Agent is running without any errors

**E.g.**

```text
ncn-w001:/home # systemctl status sbps-marshal
● sbps-marshal.service - System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary images similar to PE.
     Loaded: loaded (/usr/lib/systemd/system/sbps-marshal.service; enabled; vendor preset: disabled)
     Active: active (running) since Thu 2024-08-22 11:57:48 UTC; 2 weeks 4 days ago
   Main PID: 2878373 (sbps-marshal)
      Tasks: 1
     CGroup: /system.slice/sbps-marshal.service
             └─ 2878373 /usr/lib/sbps-marshal/bin/python /usr/lib/sbps-marshal/bin/sbps-marshal
...
```

#### Check to see if the images/ LUN mappings are created with the `targetcli ls` command

Check to see if the `targetcli ls` output shows that fileio backing store are created for `rootfs` images along with corresponding iSCSI LUNs
which has the `rootfs` id being mapped and also network portals created (HSN and NMN).

**E.g.**

```text
ncn-w001:~ # targetcli ls
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

#### Check to see if all the DNS SRV and A records are configured for all the intended worker nodes

**E.g.**

```text
ncn-w001:/home # dig -t SRV +short _sbps-hsn._tcp.odin.hpc.amslabs.hpecorp.net _sbps-nmn._tcp.odin.hpc.amslabs.hpecorp.net
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

```text
ncn-w001:/home # dig -t A +short iscsi-server-id-005.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-002.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-004.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-006.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-001.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-003.hsn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-006.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-004.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-001.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-005.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-003.nmn.odin.hpc.amslabs.hpecorp.net. iscsi-server-id-002.nmn.odin.hpc.amslabs.hpecorp.net.
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

### Perform sanity checks

After worker nodes  personalization,  in order to verify the overall readiness of the iSCSI targets before initiating the procedure for compute nodes/ UAN's booting
we need to run GOSS tests to do some sanity checks on iSCSI targets.

See [GOSS tests for SBPS](https://github.com/Cray-HPE/sbps-marshal/blob/main/GOSS_tests_for_sbps.md) for more info.
