# Configure the Cray Command Line Interface (`cray` CLI)

The `cray` command line interface (CLI) is a framework created to integrate all of the system management REST APIs into easily usable commands.

Later procedures in the installation workflow use the `cray` CLI to interact with multiple services.
The `cray` CLI configuration needs to be initialized for the Linux account, and the Keycloak user running
the procedure needs to be authorized. This section describes how to initialize the `cray` CLI for use by
a user and how to authorize that user.

The `cray` CLI only needs to be initialized once per user on a node.

## Procedure

1. Unset the CRAY_CREDENTIALS environment variable, if previously set.

   Some of the installation procedures leading up to this point use the CLI with a Kubernetes managed service
   account that is normally used for internal operations. There is a procedure for extracting the OAUTH token for
   this service account and assigning it to the `CRAY_CREDENTIALS` environment variable to permit simple CLI operations.

   ```bash
   ncn# unset CRAY_CREDENTIALS
   ```

1. Initialize the `cray` CLI for the root account.

   The `cray` CLI needs to know what host to use to obtain authorization and what user is requesting authorization,
   so it can obtain an OAUTH token to talk to the API Gateway. This is accomplished by initializing the CLI
   configuration. In this example, the 'vers' username and its password are used.

   If LDAP configuration was enabled, then use a valid account in LDAP instead of the example account 'vers'.

   If LDAP configuration was not enabled, or is not working, then a Keycloak local account could be created.
   See [Configure Keycloak Account](CSM_product_management/Configure_Keycloak_Account.md) to create this local account in Keycloak
   and then use it instead of the example account 'vers'.

   ```bash
   ncn# cray init
   ```

   When prompted, remember to use the correct username instead of 'vers'.
   Expected output (including the typed input) should look similar to the following:
   ```
   Cray Hostname: api-gw-service-nmn.local
   Username: vers
   Password:
   Success!

   Initialization complete.
   ```

1. Verify the `cray` CLI is operational.
    ```bash
    ncn# cray artifacts buckets list -vvv
    ```

    Expected output, if an error occurs see the troubleshooting section below in this topic.
    ```
    Loaded token: /root/.config/cray/tokens/api_gw_service_nmn_local.vers
    REQUEST: PUT to https://api-gw-service-nmn.local/apis/sts/token
    OPTIONS: {'verify': False}
    S3 credentials retrieved successfully
    results = [ "alc", "badger", "benji-backups", "boot-images", "etcd-backup", "fw-update", "ims", "install-artifacts", "nmd", "postgres-backup",
    "prs", "sat", "sds", "sls", "sma", "ssd", "ssm", "vbis", "velero", "wlm",]
    ```

## Troubleshooting

**NOTE:**  While resolving these issues is beyond the scope of this section, more information about what is failing can be found by adding `-vvvvv` to the `cray init ...` commands.

   If initialization fails in the above step, there are several common causes:

   * DNS failure looking up `api-gw-service-nmn.local` may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
   * Network connectivity issues with the NMN may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
   * Certificate mismatch or trust issues may be preventing a secure connection to the API Gateway
   * Istio failures may be preventing traffic from reaching Keycloak
   * Keycloak may not yet be set up to authorize the user

   If the initialization fails and the reason output is similar to the following example, restart radosgw on the storage nodes.

   ```bash
   ncn-m002# cray artifacts buckets list -vvv
   Loaded token: /root/.config/cray/tokens/api_gw_service_nmn_local.vers
   REQUEST: PUT to https://api-gw-service-nmn.local/apis/sts/token

   OPTIONS: {'verify': False}

   ERROR: {
    "detail": "The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.",
     "status": 500,
     "title": "Internal Server Error",
     "type": "about:blank"
    }

    Usage: cray artifacts buckets list [OPTIONS]

    Try 'cray artifacts buckets list --help' for help.

    Error: Internal Server Error: The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.
   ```

   1.  SSH to ncn-s001/2/3.
   1.  Restart the Ceph radosgw process.

       ***The expected output will be similar to the following, but it will vary based on the number of nodes running radosgw.***

       ```bash
       ncn-s00(1/2/3)# ceph orch restart rgw.site1.zone1
       restart rgw.site1.zone1.ncn-s001.cshvbb from host 'ncn-s001'
       restart rgw.site1.zone1.ncn-s002.tlegbb from host 'ncn-s002'
       restart rgw.site1.zone1.ncn-s003.vwjwew from host 'ncn-s003'
       ```
   1.  Check to see that the processes restarted.

       ***The "running" time should be in seconds. Restarting all of them could require a couple of minutes depending on how many.***

       ```bash
       ncn-s001# ceph orch ps --daemon_type rgw
       NAME                             HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                        IMAGE ID      CONTAINER ID
       rgw.site1.zone1.ncn-s001.cshvbb  ncn-s001  running (29s)  23s ago    9h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  2a712824adc1
       rgw.site1.zone1.ncn-s002.tlegbb  ncn-s002  running (29s)  28s ago    9h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  e423f22d06a5
       rgw.site1.zone1.ncn-s003.vwjwew  ncn-s003  running (29s)  23s ago    9h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  1e6ad6bc2c62
       ```
   1.  In the event that more than 5 minutes has passed and the radosgw services have not restarted, fail the ceph-mgr process to the standby.

       ***There are cases where an orchestration task gets stuck and our current remediation is to fail the Ceph manager process.***
       ```bash
       # Get active ceph-mgr
       ncn-s00(1/2/3)#ceph mgr dump | jq -r .active_name
       ncn-s002.zozbqp

       # Fail the active ceph-mgr
       ncn-s00(1/2/3)# ceph mgr fail $(ceph mgr dump | jq -r .active_name)

       #Confirm ceph-mgr has moved to a different ceph-mgr container
       ncn-s00(1/2/3)# ceph mgr dump | jq -r .active_name
       ncn-s001.qucrpr
       ```

   1.  Verify that the processes restarted using the command from step 3.

        At this point the processes should restart. If they do not, it is possible that steps 2 and 3 will need to be done again.

