# Selective Node Personalization

The `iscsi_worker` is the HSM group name needs to be created for iSCSI SBPS selective node personalization.

* [Steps to create HSM group](#steps-to-create-hsm-group)
* [CFS configuration and component update](#cfs-configuration-and-component-update)

## Steps to create HSM group

Example:

```text
ncn-m001:~ # cray hsm groups create --label iscsi_worker --description "iscsi node personalization" --members-ids x3000c0s5b0n0
[[results]]
URI = "/hsm/v2/groups/iscsi_worker"
```

HSM group `iscsi_worker` created with xname `x3000c0s5b0n0` added. Adding one more xname of worker node is as below:

```text
ncn-m001:~ # cray hsm groups members create --id x3000c0s18b0n0 iscsi_worker
[[results]]
URI = "/hsm/v2/groups/iscsi_worker/members/x3000c0s18b0n0"
```

The group members of `iscsi_worker` can be listed as below:

```text
ncn-m001:~ # cray hsm groups members list iscsi_worker
ids = [ "x3000c0s5b0n0", "x3000c0s18b0n0",]
```

## CFS configuration and component update

In scenarios such as an upgraded system where HSM groups were not created, then the following steps can be used for selective node personalization post HSM groups creation.

Example:

```text
ncn-m001:~ # XNAME=$( ssh ncn-m001 cat /etc/cray/xname )
ncn-m001:~ # echo $XNAME
x3000c0s1b0n0
ncn-m001:~ # CONFIG=$( cray cfs components describe $XNAME --format json | jq -r '.desiredConfig' )
ncn-m001:~ # echo $CONFIG
management-main-1874509.1
ncn-m001:~ # craycfs configurations describe $CONFIG --format json | jq -r '. | del(.name) | del(.lastUpdated)' > ${CONFIG}.json
ncn-m001:~ # cat management-main-1874509.1.json
{
  "layers": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
      "commit": "67098595b52d0739382611ef6fe15a918978910d",
      "name": "csm-sbps_iscsi_targets-1.6.1-rc.7",
      "playbook": "config_sbps_iscsi_targets.yml"
    }
  ]
}

ncn-m001:~ # cray cfs configurations update --file ${CONFIG}.json ${CONFIG}
lastUpdated = "2025-05-27T11:17:51Z"
name = "management-main-1874509.1"
[[layers]]
cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
commit = "67098595b52d0739382611ef6fe15a918978910d"
name = "csm-sbps_iscsi_targets-1.6.1-rc.7"
playbook = "config_sbps_iscsi_targets.yml"


ncn-m001:~ # cray cfs components update $XNAME --state []
desiredConfig = "management-main-1874509.1"
enabled = true
errorCount = 0
id = "x3000c0s1b0n0"
state = []

[tags]

ncn-m001:~ # cray cfs components describe $XNAME
configurationStatus = "pending"
desiredConfig = "management-main-1874509.1"
enabled = true
errorCount = 0
id = "x3000c0s1b0n0"
state = []

[tags]

......

ncn-m001:~ # cray cfs components describe $XNAME
configurationStatus = "configured"
desiredConfig = "management-main-1874509.1"
enabled = true
errorCount = 0
id = "x3000c0s1b0n0"
[[state]]
cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
commit = "67098595b52d0739382611ef6fe15a918978910d_skipped"
lastUpdated = "2025-05-27T11:20:52Z"
playbook = "config_sbps_iscsi_targets.yml"
sessionName = "batcher-66eee897-aa2a-4d92-9a2c-565e9bde3665"

[tags]

ncn-m001:~ # kubectl get pods --no-headers -o custom-columns=":metadata.name" -n services -l cfsession=batcher-66eee897-aa2a-4d92-9a2c-565e9bde3665
cfs-19e2e4f7-aae8-4847-b4b3-288888b24769-dx75v
ncn-m001:~ # CFS_POD_NAME=cfs-19e2e4f7-aae8-4847-b4b3-288888b24769-dx75v
ncn-m001:~ # kubectl logs -n services "${CFS_POD_NAME}" ansible
Waiting for Inventory
Inventory generation completed
SSH keys migrated to /root/.ssh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 200 OK
content-type: text/html; charset=UTF-8
cache-control: no-cache, max-age=0
x-content-type-options: nosniff
date: Tue, 27 May 2025 11:19:11 GMT
server: envoy
transfer-encoding: chunked

Sidecar available
Running config_sbps_iscsi_targets.yml from repo https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git

PLAY [iscsi_worker] ************************************************************

TASK [csm.sbps.apply_label : Apply k8s label on worker nodes] ******************
changed: [x3000c0s18b0n0]
changed: [x3000c0s5b0n0]

TASK [csm.sbps.enable_spire : restart_spire_agent] *****************************
changed: [x3000c0s18b0n0]
changed: [x3000c0s5b0n0]

TASK [csm.sbps.lio_config : provision_iscsi_server] ****************************
changed: [x3000c0s18b0n0]
changed: [x3000c0s5b0n0]

TASK [csm.sbps.dns_srv_records : Remove previous /tmp/hsn_nmn_info.txt] ********
changed: [x3000c0s18b0n0]

TASK [csm.sbps.dns_srv_records : Get Host Name, HSN and NMN details of each worker node] ***
changed: [x3000c0s18b0n0 -> x3000c0s18b0n0]

TASK [csm.sbps.dns_srv_records : Update Host Name, HSN and NMN details for each worker node] ***
changed: [x3000c0s18b0n0 -> x3000c0s18b0n0]

TASK [csm.sbps.dns_srv_records : Create DNS "SRV" and "A" records of HSN and NMN for each worker node] ***
changed: [x3000c0s18b0n0 -> x3000c0s18b0n0]

PLAY RECAP *********************************************************************
x3000c0s18b0n0             : ok=10   changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
x3000c0s5b0n0              : ok=7    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

All playbooks completed successfully
```

Note:- This indicates that iSCSI SBPS node personalisation playbooks have been applied on
selected nodes and iSCSI SBPS is enabled.
