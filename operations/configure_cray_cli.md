# Configure the Cray Command Line Interface (`cray` CLI)

The `cray` command line interface (CLI) is a framework created to integrate all of the system management REST APIs into easily usable commands.

Procedures in the CSM installation workflow use the `cray` CLI to interact with multiple services.
The `cray` CLI configuration needs to be initialized for the Linux account, and the Keycloak user running
the procedure needs to be authorized. This section describes how to initialize the `cray` CLI for use by
a user and how to authorize that user.

The `cray` CLI only needs to be initialized once per user on a node.

## Procedure

1. Unset the `CRAY_CREDENTIALS` environment variable, if previously set.

   Some CSM installation procedures use the CLI with a Kubernetes managed service
   account that is normally used for internal operations. There is a procedure for extracting the OAUTH token for
   this service account and assigning it to the `CRAY_CREDENTIALS` environment variable to permit simple CLI operations.
   It must be unset in order to validate that the CLI is working with user authentication.

   ```bash
   ncn# unset CRAY_CREDENTIALS
   ```

1. Initialize the `cray` CLI for the `root` account.

   The `cray` CLI needs to know what host to use to obtain authorization and what user is requesting authorization,
   so it can obtain an OAUTH token to talk to the API gateway. This is accomplished by initializing the CLI
   configuration.

   In this example, the `vers` username is used. It should be replaced with an appropriate user account:

   - If LDAP configuration was enabled, then use a valid account in LDAP.
   - If LDAP configuration was not enabled, or is not working, then a Keycloak local account may be created.
     See [Configure Keycloak Account](CSM_product_management/Configure_Keycloak_Account.md) to create this local account in Keycloak.

   ```bash
   ncn# cray init --hostname api-gw-service-nmn.local
   ```

   Expected output (including the typed input) should look similar to the following:

   ```text
   Username: vers
   Password:
   Success!

   Initialization complete.
   ```

1. Verify that the `cray` CLI is operational.

    ```bash
    ncn# cray artifacts buckets list -vvv
    ```

    Expected output looks similar to the following:

    ```text
    Loaded token: /root/.config/cray/tokens/api_gw_service_nmn_local.vers
    REQUEST: PUT to https://api-gw-service-nmn.local/apis/sts/token
    OPTIONS: {'verify': False}
    S3 credentials retrieved successfully
    results = [ "alc", "badger", "benji-backups", "boot-images", "etcd-backup", "fw-update", "ims", "install-artifacts", "nmd", "postgres-backup",
    "prs", "sat", "sds", "sls", "sma", "ssd", "ssm", "vbis", "velero", "wlm",]
    ```

    If an error occurs, then continue to the troubleshooting section below.

## Troubleshooting

More information about what is failing can be found by adding `-vvvvv` to the `cray init ...` commands.

### Initialization fails

If CLI initialization fails, there are several common causes:

- DNS failure looking up `api-gw-service-nmn.local` may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
- Network connectivity issues with the NMN may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
- Certificate mismatch or trust issues may be preventing a secure connection to the API Gateway
- Istio failures may be preventing traffic from reaching Keycloak
- Keycloak may not yet be set up to authorize the user

### Internal error

If an error similar to the following is seen, then restart `radosgw` on the storage nodes.

```text
The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.
```

Restart `radosgw` using the following steps. These steps must be run on one of the storage nodes running the Ceph `radosgw` process.
By default these nodes are `ncn-s001`, `ncn-s002`, and `ncn-s003`.

1. Restart the Ceph `radosgw` process.

    > The expected output will be similar to the following, but it will vary based on the nodes running `radosgw`.

    ```bash
    ncn-s# ceph orch restart rgw.site1.zone1
    ```

    Example output:

    ```text
    restart rgw.site1.zone1.ncn-s001.cshvbb from host 'ncn-s001'
    restart rgw.site1.zone1.ncn-s002.tlegbb from host 'ncn-s002'
    restart rgw.site1.zone1.ncn-s003.vwjwew from host 'ncn-s003'
    ```

1. Check to see that the processes restarted.

    ```bash
    ncn-s# ceph orch ps --daemon_type rgw
    ```

    Example output:

    ```text
    NAME                             HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                        IMAGE ID      CONTAINER ID
    rgw.site1.zone1.ncn-s001.cshvbb  ncn-s001  running (29s)  23s ago    9h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  2a712824adc1
    rgw.site1.zone1.ncn-s002.tlegbb  ncn-s002  running (29s)  28s ago    9h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  e423f22d06a5
    rgw.site1.zone1.ncn-s003.vwjwew  ncn-s003  running (29s)  23s ago    9h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  1e6ad6bc2c62
    ```

    > A process which has restarted should have an `AGE` in seconds. Restarting all of them could require a couple of minutes depending on how many.

1. In the event that more than five minutes have passed and the `radosgw` processes have not restarted, then fail the `ceph-mgr` process.

    1. Determine the active `ceph-mgr`.

        ```bash
        ncn-s#ceph mgr dump | jq -r .active_name
        ```

        Example output:

        ```text
        ncn-s002.zozbqp
        ```

    1. Fail the active `ceph-mgr`.

        ```bash
        ncn-s# ceph mgr fail $(ceph mgr dump | jq -r .active_name)
        ```

    1. Confirm that `ceph-mgr` has moved to a different `ceph-mgr` container.

        ```bash
        ncn-s# ceph mgr dump | jq -r .active_name
        ```

        Example output:

        ```text
        ncn-s001.qucrpr
        ```

    1. Verify that the `radosgw` processes restarted using the command from the previous step.

        At this point the processes should restart. If they do not, then attempt this remediation procedure a second time.
