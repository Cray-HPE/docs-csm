# Move Unmanaged Ceph OSDs

**`IMPORTANT:`** This document addresses how to move OSDs that are unmanaged, but should actually
be managed by the Ceph orchestrator. For OSDs that are intentionally unmanaged, do not use
this document to move them.

(`ncn-s#`) Check for unmanaged OSDs.

```bash
ceph orch ls | awk 'NR==1 || /osd/'
```

Example output (the following example shows eight unmanaged OSDs with `osd` service name):

```text
NAME                       PORTS        RUNNING  REFRESHED  AGE  PLACEMENT 
osd                                           8  5m ago     -    <unmanaged>
osd.all-available-devices                    16  5m ago     6d   *
```

In addition, the following command shows that `osd` service has `unmanaged` set to `true`:

```bash
ceph orch ls --service_name osd --export
```

Example output:

```text
service_type: osd
service_name: osd
unmanaged: true  <-----
spec:
  filter_logic: AND
  objectstore: bluestore
```

## Prerequisites

This procedure requires administrative privileges and assumes `osd` as the service name for
unmanaged OSDs, as shown in the example output above.

## Procedure

Perform the following steps on every storage node that has unintentionally unmanaged OSDs,

1. (`ncn-s#`) Create a service specification YAML file with the following content:

    ```yaml
    service_type: osd
    service_name: osd
    unmanaged: false
    placement:
      host_pattern: '*'
    spec:
      data_devices:
        all: true
      filter_logic: AND
      objectstore: bluestore
    ```

1. (`ncn-s#`) Apply the service specification defined in the above YAML file.

    ```bash
    ceph orch apply -i <above_yaml_file>
    ```

1. (`ncn-s#`) Verify that `osd` service name no longer has `unmanaged` set to `true`.

    ```bash
    ceph orch ls --service_name osd --export
    ```

    Example output (no `unmanaged` line):

    ```yaml
    service_type: osd
    service_name: osd
    placement:
      host_pattern: '*'
    spec:
      data_devices:
        all: true
      filter_logic: AND
      objectstore: bluestore
    ```

1. (`ncn-s#`) Verify that there are no unmanaged OSDs.

    ```bash
    ceph orch ls | awk 'NR==1 || /osd/'
    ```

    Example output (`osd` service no longer shows `<unmanaged>` placement):

    ```text
    NAME                       PORTS        RUNNING  REFRESHED  AGE  PLACEMENT 
    osd                                           8  10m ago    -    *
    osd.all-available-devices                    16  10m ago    7d   *
    ```

1. (`ncn-s#`) On each storage node, identify OSDs with `osd` service name.

    The following example shows eight such OSDs on one storage node.

    ```bash
    cephadm ls | jq -r '.[] | select(.service_name=="osd").name'
    ```

    Example output:

    ```text
    osd.12
    osd.15
    osd.18
    osd.19
    osd.20
    osd.21
    osd.22
    osd.23
    ```

1. (`ncn-s#`) For each OSD from the above output, update its service name to
    `osd.all-available-devices` as follows.

    > Be sure to replace the `<CLUSTER_ID>` and `<OSD_ID>` field in the following
    > command with the actual Ceph cluster ID and OSD ID being updated.
    > For example, if the OSD is `osd.12`, the `<OSD_ID>` value would be 12.

    ```bash
    cd /var/lib/ceph/<CLUSTER_ID>
    sed -i '/service_name/s/osd/osd.all-available-devices/g' osd.<OSD_ID>/unit.meta
    ```

1. (`ncn-s#`) After all OSDs from the above list have been updated on the storage node,
    verify no OSDs have the service name other than `osd.all-available-devices`.

    ```bash
    for f in osd.*/unit.meta; do jq -r .service_name "$f"; done | uniq
    ```

    Example output:

    ```text
    osd.all-available-devices
    ```

1. (`ncn-s#`) Repeat the above steps on other storage nodes if they also have unmanaged OSDs.

1. (`ncn-s#`) After all such OSDs have been updated, wait for a minute and verify that `osd`
service name has zero OSDs by running the following command.

    ```bash
    ceph orch ls | awk 'NR==1 || /osd/'
    ```

    Example output:

    ```text
    NAME                       PORTS        RUNNING  REFRESHED  AGE  PLACEMENT 
    osd                                           0  -          31m  *
    osd.all-available-devices                    24  20s ago    7d   *
    ```

    **`NOTE:`** A non-zero count of OSDs under the `osd` service name may indicate that the update was not
    applied to certain OSDs or storage nodes. Ensure that no OSDs are associated with the `osd` service name
    before proceeding.

1. (`ncn-s#`) Remove `osd` service name.

    ```bash
    ceph orch rm osd
    ```

    Example output:

    ```text
    Removed service osd
    ```
