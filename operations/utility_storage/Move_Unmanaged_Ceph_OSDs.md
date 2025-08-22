# Move Unmanaged Ceph OSDs

**`IMPORTANT:`** This document addresses how to move OSDs that are unmanaged, but should actually
be managed by the Ceph orchestrator. For OSDs that are intentionally unmanaged, DO NOT use
this document to move them.

* [Checking for unmanaged OSDs](#checking-for-unmanaged-osds)
* [Prerequisites](#prerequisites)
* [Procedure](#procedure)

## Checking for unmanaged OSDs

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
unintentionally unmanaged OSDs, as shown in the example output above.

## Procedure

Perform the following steps on only one storage node.

1. (`ncn-s#`) Create a service specification YAML file with the following content (replace the
   `service_name` field with the actual service name. Do not replace the `service_type` field,
   as it should be `osd` regardless of the service name):

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
    ceph orch apply -i <path_to_yaml_file>
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

1. (`ncn-s#`) Verify that there are no unmanaged OSDs for `osd` service name.

    ```bash
    ceph orch ls | awk 'NR==1 || /osd/'
    ```

    Example output (`osd` service no longer shows `<unmanaged>` placement):

    ```text
    NAME                       PORTS        RUNNING  REFRESHED  AGE  PLACEMENT 
    osd                                           8  10m ago    -    * <--- no longer <unmanaged>
    osd.all-available-devices                    16  10m ago    7d   *
    ```
