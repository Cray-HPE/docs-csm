# Configure the Cray Command Line Interface (`cray` CLI)

The `cray` command line interface (CLI) is a framework created to integrate all of the system management REST APIs into easily usable commands.

Later procedures in the installation workflow use the `cray` CLI to interact with multiple services.
The `cray` CLI configuration needs to be initialized for the Linux account, and the Keycloak user running
the procedure needs to be authorized. This section describes how to initialize the `cray` CLI for use by
a user and how to authorize that user.

The `cray` CLI only needs to be initialized once per user on a node.

There are two ways to initialize the `cray` CLI:

1. [Single User Already Configured in Keycloak](#single-user-already-configured-in-keycloak)

1. [Configure All NCNs With Temporary Keycloak User](#configure-all-ncns-with-temporary-keycloak-user)

## Single User Already Configured in Keycloak

   There are times in normal operation that a particular user must be authenticated on the `cray` CLI. In
   this case, the user must already be present in Keycloak and have the correct permissions to access the
   system.

### Procedure For Existing Keycloak User

1. If a Keycloak user needs to be created, see [Keycloak User Management](security_and_authentication/Access_the_Keycloak_User_Management_UI.md)

1. (`ncn-mws#`) Initialize the `cray` CLI

    ```bash
    cray init
    ```

    Expect the following prompts:

    ```bash
    Overwrite configuration file at: MY_HOME_DIR/.config/cray/configurations/default ? [y/N]: y
    Cray Hostname: api-gw-service-nmn.local
    Username: MY_KEYCLOAK_USER_NAME
    Password: MY_PASSWORD
    Success!

    Initialization complete.
    ```

1. (`ncn-mws#`) The `cray` CLI may need to be authenticated to complete the setup.

    Use the same Keycloak username and password from the above initialization command. To authenticate to the `cray` CLI:

    ```bash
    cray auth login
    ```

    Expect the following prompts:

    ```bash
    Username: MY_KEYCLOAK_USER_NAME
    Password: MY_PASSWORD
    Success!
    ```

## Configure All NCNs With Temporary Keycloak User

This script will create a new Keycloak account that is authorized for the `cray` CLI and use that account
to initialize and authorize the `cray` CLI on all master and worker nodes in the cluster. This account is
only intended to be used for the duration of the install and should be removed when the install is complete.

### Procedure For Temporary Keycloak User

1. (`ncn-mws#`) Unset the `CRAY_CREDENTIALS` environment variable, if previously set.

    Some of the installation procedures leading up to this point use the CLI with a Kubernetes managed service
    account that is normally used for internal operations. There is a procedure for extracting the OAUTH token for
    this service account and assigning it to the `CRAY_CREDENTIALS` environment variable to permit simple CLI
    operations. This needs to be removed prior to `cray` CLI initialization.

    ```bash
    unset CRAY_CREDENTIALS
    ```

1. (`ncn-mws#`) Initialize the `cray` CLI for the root account on all master and worker nodes.

    The script will handle creation of the temporary Keycloak user and initialize all master and
    worker nodes that are in a ready state. Call the script with the `--run` option:

    ```bash
    python3 /usr/share/doc/csm/install/scripts/craycli_init.py --run
    ```

    Expect output showing the results of the operation on each node:

    ```bash
    2021-12-21 15:50:47,814 - INFO    - Loading Keycloak secrets.
    2021-12-21 15:50:48,095 - INFO    - Created user 'craycli_tmp_user'
    2021-12-21 15:50:52,714 - INFO    - Initializing nodes:
    2021-12-21 15:50:52,714 - INFO    - ncn-m001: Success
    2021-12-21 15:50:52,714 - INFO    - ncn-m002: Success
    2021-12-21 15:50:52,714 - INFO    - ncn-m003: Success
    2021-12-21 15:50:52,714 - INFO    - ncn-s001: Success
    2021-12-21 15:50:52,714 - INFO    - ncn-s002: Success
    2021-12-21 15:50:52,714 - INFO    - ncn-s003: Success
    2021-12-21 15:50:52,714 - INFO    - ncn-w001: Success
    2021-12-21 15:50:52,714 - INFO    - ncn-w002: Success
    2021-12-21 15:50:52,714 - INFO    - ncn-w003: Success
    ```

    The `cray` CLI is now operational on all nodes where success was reported. If a node was
    unsuccessful with initialization, there will be an error reported. See the
    [troubleshooting](#troubleshooting-results-of-the-automated-script) section for additional information.

1. (`ncn-mws#`) Remove the temporary user after the install is complete.

    **IMPORTANT:** If this section is not followed the temporary user will remain as a valid
    account in Keycloak. Be sure to clean this up when this user is no longer required.

    When the install is complete and Keycloak is fully populated with the correct end users,
    call this script again with the `--cleanup` option to remove the temporary user from Keycloak
    and uninitialize the `cray` CLI on all master and worker nodes in the cluster.

    ```bash
    python3 /usr/share/doc/csm/install/scripts/craycli_init.py --cleanup
    ```

    Expect output showing the results of the operation on each node:

    ```bash
    2021-12-21 15:52:31,611 - INFO    - Removing temporary user and uninitializing the cray CLI
    2021-12-21 15:52:31,783 - INFO    - Deleted user 'craycli_tmp_user'
    2021-12-21 15:52:31,798 - INFO    - Uninitializing nodes:
    2021-12-21 15:52:32,714 - INFO    - ncn-m001: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-m002: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-m003: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-s001: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-s002: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-s003: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-w001: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-w002: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-w003: Success
    ```

    At this point the `cray` CLI will no longer be operational on these nodes until they are
    initialized and authorized again with a valid Keycloak user.

    Optionally, the `cray` CLI may be initialized with a valid Keycloak user during the cleanup
    operation so that it is left operational. To do this pass in a user and password with the
    cleanup command:

    ```bash
    python3 /usr/share/doc/csm/install/scripts/craycli_init.py --cleanup -u MY_USERNAME -p MY_PASSWORD
    ```

    Expect output showing the cleanup of the temporary user on each node, then the results of
    using the input user to initialize and authorize the `cray` CLI on each node:

    ```bash
    2021-12-21 15:52:31,611 - INFO    - Removing temporary user and uninitializing the cray CLI
    2021-12-21 15:52:31,783 - INFO    - Deleted user 'craycli_tmp_user'
    2021-12-21 15:52:31,798 - INFO    - Uninitializing nodes:
    2021-12-21 15:52:32,714 - INFO    - ncn-m001: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-m002: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-m003: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-s001: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-s002: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-s003: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-w001: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-w002: Success
    2021-12-21 15:52:32,714 - INFO    - ncn-w003: Success
    2021-12-21 15:52:33,079 - INFO    - Re-initializing the cray CLI with existing Keycloak user MY_USERNAME
    2021-12-21 15:52:33,131 - INFO    - Initializing nodes:
    2021-12-21 15:52:37,714 - INFO    - ncn-m001: Success
    2021-12-21 15:52:37,714 - INFO    - ncn-m002: Success
    2021-12-21 15:52:37,714 - INFO    - ncn-m003: Success
    2021-12-21 15:52:37,714 - INFO    - ncn-s001: Success
    2021-12-21 15:52:38,714 - INFO    - ncn-s002: Success
    2021-12-21 15:52:38,714 - INFO    - ncn-s003: Success
    2021-12-21 15:52:38,714 - INFO    - ncn-w001: Success
    2021-12-21 15:52:38,714 - INFO    - ncn-w002: Success
    2021-12-21 15:52:38,714 - INFO    - ncn-w003: Success
    ```

    At this point the `cray` CLI will be operational on all successful nodes and authenticated with
    the input Keycloak account.

## Troubleshooting Results of the Automated Script

Each node will have `Success` reported if everything worked and the node was initialized
and the `cray` CLI is operational for that node. For nodes with problems, there will be a
brief error message that reports what the problem is on that node.

Results with problems on some nodes may look like the following:

```bash
2021-12-21 15:50:47,814 - INFO    - Loading Keycloak secrets.
2021-12-21 15:50:48,095 - INFO    - Created user 'craycli_tmp_user'
2021-12-21 15:50:52,714 - INFO    - Initializing nodes:
2021-12-21 15:50:52,714 - INFO    - ncn-m001: Success
2021-12-21 15:50:52,714 - INFO    - ncn-m002: Success
2021-12-21 15:50:52,714 - INFO    - ncn-w001: Success
2021-12-21 15:50:52,714 - ERROR   - ncn-m003: ERROR: Call to cray init failed
2021-12-21 15:50:52,714 - ERROR   - ncn-s001: ERROR: Python script failed
2021-12-21 15:50:52,714 - ERROR   - ncn-w002: ERROR: Failed to copy script to remote host
2021-12-21 15:50:52,714 - ERROR   - ncn-w003: ERROR: Verification that cray CLI is operational failed
```

At this point the entire operation may be repeated with the `--debug` flag added for
debug level log messages displayed or each failing node may be looked at individually.

### Debugging an Individual Node

1. (`ncn-mws#`) Log into the node that failed
    To try re-running the initialization on only a single node, `ssh` to that node, then run
    the script with the `--initnode` option and `--debug` option to enable increased logging:

    **NOTE:** Part of the script is copying itself to the `/tmp/` directory on each target node.
    The script should still be there, but if not just copy the script somewhere accessible.

    ```bash
    ssh NODE_THAT_FAILED
    python3 /tmp/craycli_init.py --initnode --debug
    ```

    Now use the enhanced messages to determine what is wrong on this node.

    1. (`ncn-mws#`) Check for missing Python Modules

        It is possible that some Python modules required for the script are missing on individual
        nodes - particularly on the `PIT` node if that is still active. This script could run from
        any of the NCNs, so if it fails on one node, copy it to any location on another node
        and try to run it from there.

        In the following example the script fails on 'ncn' due to the missing Python module 'oauthlib'
        so it is copied to 'ncn-m002' and successfully runs from that node:

        ```bash
        python3 /usr/share/doc/csm/install/scripts/craycli_init.py --run
        ```

        Error output:

        ```bash
        Traceback (most recent call last):
            File "craycli_init.py", line 50, in <module>
            import oauthlib.oauth2
        ModuleNotFoundError: No module named 'oauthlib'
        ```

        Copy the script to the `ncn-m002` node and run from there:

        ``` bash
        scp /usr/share/doc/csm/install/scripts/craycli_init.py ncn-m002:'~/my_dir/'
        ssh ncn-m002 'cd my_dir && python3 ./craycli_init.py --run'
        ```

        At this point expect it to proceed as documented, but it will fail again on the node
        originally attempted on due to the lack of critical Python modules on that node, but
        may complete successfully on the rest of the nodes.

        Alternatively, the modules could be installed using 'pip' or 'pip3' if that is available on the node.

    1. (`ncn-mws#`) Check for Kubernetes setup on the node

        The script relies on Kubernetes Secrets to store the credentials of the temporary Keycloak user. If
        a does not have Kubernetes initialized on it, the user must manually initialize the `cray` CLI with a
        valid Keycloak user.

        Run the following command:

        ```bash
        kubectl get nodes
        ```

        If Kubernetes is configured and operating correctly you should see a list of the master and worker nodes:

        ```bash
        NAME       STATUS   ROLES                  AGE    VERSION
        ncn-m001   Ready    control-plane,master   120d   v1.20.13
        ncn-m002   Ready    control-plane,master   120d   v1.20.13
        ncn-m003   Ready    control-plane,master   120d   v1.20.13
        ncn-w001   Ready    <none>                 120d   v1.20.13
        ncn-w002   Ready    <none>                 120d   v1.20.13
        ncn-w003   Ready    <none>                 120d   v1.20.13
        ```

        If Kubernetes is not configured or operating correctly you will see an error:

        ```bash
        W0902 16:06:38.726121   61796 loader.go:223] Config not found: /etc/kubernetes/admin.conf
        error: the server doesn't have a resource type "nodes"
        ```

        If Kubernetes is not operational on this node, the `cray` CLI may still be initialized and authorized manually
        with a valid existing Keycloak user following the process
        [Single User Already Configured in Keycloak](#single-user-already-configured-in-keycloak).

### Debugging Problems with Initialization or Authorization

**NOTE:**  While resolving the following issues is beyond the scope of this section, more information about what is failing can be found by adding `-vvvvv` to the `cray init ...` commands.

1. (`ncn-mws#`) Troubleshoot Failed Initialization

    If initialization fails in the above step, there are several common causes:

    * DNS failure looking up `api-gw-service-nmn.local` may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
    * Network connectivity issues with the NMN may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
    * Certificate mismatch or trust issues may be preventing a secure connection to the API Gateway
    * Istio failures may be preventing traffic from reaching Keycloak
    * Keycloak may not yet be set up to authorize the user

    If the initialization fails and the reason output is similar to the following example, restart `radosgw` on the storage nodes.

    ```bash
    cray artifacts buckets list -vvv
    ```

    The output may look something like:

    ```bash
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

    1. SSH to ncn-s001/2/3.

    1. (`ncn-s#`) Restart the Ceph radosgw process.

        ```bash
        ceph orch restart rgw.site1.zone1
        ```

        The expected output will be similar to the following, but it will vary based on the number of nodes running radosgw:

        ```bash
        restart rgw.site1.zone1.ncn-s001.cshvbb from host 'ncn-s001'
        restart rgw.site1.zone1.ncn-s002.tlegbb from host 'ncn-s002'
        restart rgw.site1.zone1.ncn-s003.vwjwew from host 'ncn-s003'
        ```

    1. (`ncn-s#`) Check to see that the processes restarted.

       ```bash
       ceph orch ps --daemon_type rgw
       ```

        The "running" time should be in seconds. Restarting all of them could require a couple of minutes depending on how many.

        ```bash
        NAME                             HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                        IMAGE ID      CONTAINER ID
        rgw.site1.zone1.ncn-s001.cshvbb  ncn-s001  running (29s)  23s ago    9h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  2a712824adc1
        rgw.site1.zone1.ncn-s002.tlegbb  ncn-s002  running (29s)  28s ago    9h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  e423f22d06a5
        rgw.site1.zone1.ncn-s003.vwjwew  ncn-s003  running (29s)  23s ago    9h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  1e6ad6bc2c62
        ```

    1. (`ncn-s#`) In the event that more than 5 minutes has passed and the `radosgw` services have not restarted, fail the `ceph-mgr` process to the standby.

        There are cases where an orchestration task gets stuck and the current remediation is to fail the Ceph manager process.

        Get active `ceph-mgr`:

        ```bash
        ceph mgr dump | jq -r .active_name
        ```

        Expected output will be something similar to:

        ```bash
        ncn-s002.zozbqp
        ```

        Fail the active ceph-mgr:

        ```bash
        ceph mgr fail $(ceph mgr dump | jq -r .active_name)
        ```

        Confirm ceph-mgr has moved to a different ceph-mgr container:

        ```bash
        ceph mgr dump | jq -r .active_name
        ```

        Expect the output to be a different manager than was prevoiusly reported:

        ```bash
        ncn-s001.qucrpr
        ```

    1. Verify that the processes restarted using the command from step 3.

        At this point the processes should restart. If they do not, it is possible that steps 2 and 3 will need to be done again.
