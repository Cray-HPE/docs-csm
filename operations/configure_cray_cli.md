# Configure the Cray Command Line Interface (`cray` CLI)

The `cray` command line interface (CLI) is a framework created to integrate all of the system management REST APIs into easily usable commands.

Later procedures in the installation workflow use the `cray` CLI to interact with multiple services.
The `cray` CLI configuration needs to be initialized for the Linux account, and the Keycloak user running
the procedure needs to be authorized. This section describes how to initialize the `cray` CLI for use by
a user and how to authorize that user.

The `cray` CLI only needs to be initialized once per user on a node.

This script will create a new keycloak account that is authorized for the `cray` CLI and use that account
to initialize and authorize the `cray` CLI on all master and worker nodes in the cluster. This account is
only intended to be used for the duration of the install and should be removed when the install is complete.

## Procedure

1. Unset the CRAY_CREDENTIALS environment variable, if previously set.

   Some of the installation procedures leading up to this point use the CLI with a Kubernetes managed service
   account that is normally used for internal operations. There is a procedure for extracting the OAUTH token for
   this service account and assigning it to the `CRAY_CREDENTIALS` environment variable to permit simple CLI operations.

   ```bash
   ncn# unset CRAY_CREDENTIALS
   ```

1. Initialize the `cray` CLI for the root account on all master and worker nodes.

   The script will handle creation of the temporary keycloak user and initialize all master and
   worker nodes that are in a ready state.  Call the script with the run option:
   ```bash
   ncn# python3 /usr/share/doc/csm/install/scripts/craycli_init.py --run
   2021-12-21 15:50:47,814 - INFO    - Loading keycloak secrets.
   2021-12-21 15:50:48,095 - INFO    - Created user 'craycli_tmp_user'
   2021-12-21 15:50:52,714 - INFO    - Initiailizing nodes:
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

   Now the `cray` CLI is operational on all nodes where success was reported. If a node was
   unsuccessful with initialization, there will be an error reported. See the troubleshooting
   section for additional information.

1. Remove the temporary user after the install is complete.

   When the install is complete and keycloak is fully populated with the correct end users,
   call this script again with the cleanup option to remove the temporary user from keycloak
   and uninitialize the `cray` CLI on all master and worker nodes in the cluster.
   ```bash
   ncn# python3 /usr/share/doc/csm/install/scripts/craycli_init.py --cleanup
   2021-12-21 15:52:31,611 - INFO    - Removing temporary user and uninitializaing the cray cli
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
   initialized and authorized again with a valid keycloak user.

   Optionally the `cray` CLI may be initialized with a valid keycloak user during the cleanup
   operation so that it is left operational. To do this pass in a user and password with the
   cleanup command:
   ```bash
   ncn# python3 /usr/share/doc/csm/install/scripts/craycli_init.py --cleanup -u MY_USERNAME -p MY_PASSWORD
   2021-12-21 15:52:31,611 - INFO    - Removing temporary user and uninitializaing the cray cli
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
   2021-12-21 15:52:33,079 - INFO    - Re-initializing the cray cli with existing keycloak user MY_USERNAME
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
   the input keycloak account.

1. Initialize the `cray` CLI on a single node with an existing keycloak user account.

   To initialize the `cray` CLI on a single node with an existing keycloak account use the
   `cray init` command with the correct API Gateway hostname and keycloak account and password.
   Expected output should look something like the following:
   ```bash
   ncn# cray init
   Cray Hostname: api-gw-service-nmn.local
   Username: MY_KEYCLOAK_USER_NAME
   Password: MY_PASSWORD
   Success!

   Initialization complete.
   ```

   The `cray` CLI may need to be authenticated to complete the setup. With the same keycloak username
   and password that was used for initialization above, do the following:
   ```bash
   ncn# cray auth login
   Username: MY_KEYCLOAK_USER_NAME
   Password: MY_PASSWORD
   Success!
   ```

## Troubleshooting

   Each node will have `Success` reported if everything worked and the node was initialized
   and the `cray` CLI is operational for that node. For nodes with problems, there will be a
   brief error message that reports what the problem is on that node.

   ```bash
   ncn# python3 /usr/share/doc/csm/install/scripts/craycli_init.py --run
   2021-12-21 15:50:47,814 - INFO    - Loading keycloak secrets.
   2021-12-21 15:50:48,095 - INFO    - Created user 'craycli_tmp_user'
   2021-12-21 15:50:52,714 - INFO    - Initiailizing nodes:
   2021-12-21 15:50:52,714 - INFO    - ncn-m001: Success
   2021-12-21 15:50:52,714 - INFO    - ncn-m002: Success
   2021-12-21 15:50:52,714 - INFO    - ncn-w001: Success
   2021-12-21 15:50:52,714 - ERROR   - ncn-m003: ERROR: Call to cray init failed
   2021-12-21 15:50:52,714 - ERROR   - ncn-s001: ERROR: Python script failed
   2021-12-21 15:50:52,714 - ERROR   - ncn-w002: ERROR: Failed to copy script to remote host
   2021-12-21 15:50:52,714 - ERROR   - ncn-w003: ERROR: Verification that cray cli is operational failed
   ```

   At this point the entire operation may be repeated with the `--debug` flag added for
   debug level log messages displayed or each failing node may be looked at individually.

   To try re-running the initialization on only a single node, ssh to that node, then run
   the script with the individual initialization option and debug level logging enabled:
   ```bash
   ncn# ssh ncn-m003
   ncn-m003# python3 /tmp/craycli_init.py --initnode --debug
   ```

   Now use the enhanced messages to determine what is wrong on this node.

1. Keycloak user group membership

   The keycloak user that is used to initialize and authorize the `cray` CLI must belong to
   a group that has permissions to run the `cray` CLI. In a default install the group `craydev`
   is set up in keycloak with the correct permissions and the temporary user created by this
   process will be added as a member of that group. If there is a different group that has the
   correct permissions the `--group` option can be used on the `--run` step to use that group
   instead:

   ```bash
   ncn# python3 /usr/share/doc/csm/install/scripts/craycli_init.py --run --group my_grp
   2021-12-21 15:50:47,814 - INFO    - Loading keycloak secrets.
   2021-12-21 15:50:48,095 - INFO    - Created user 'craycli_tmp_user' in 'my_grp'
   2021-12-21 15:50:52,714 - INFO    - Initiailizing nodes:
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

1. Missing Python Modules

   It is possible that some Python modules required for the script are missing on individual
   nodes - particularly on the `PIT` node if that is still active. This script could run from
   any of the NCN nodes, so if it fails on one node, copy it to any location on another node
   and try to run it from there.

   In the below example the script fails on 'ncn' due to the missing Python module 'oauthlib'
   so it is copied to 'ncn-m002' and successfully runs from that node:
   ```bash
   ncn# python3 /usr/share/doc/csm/install/scripts/craycli_init.py --run
   Traceback (most recent call last):
     File "craycli_init.py", line 50, in <module>
       import oauthlib.oauth2
   ModuleNotFoundError: No module named 'oauthlib'
   ncn# scp /usr/share/doc/csm/install/scripts/craycli_init.py ncn-m002:~/my_dir/
   ncn# ssh ncn-m002
   ncn-m002# cd my_dir
   ncn-m002# python3 ./craycli_init.py --run
   ```

   At this point expect it to proceed as documented, but it will fail again on the node
   originally attempted on due to the lack of critical Python modules on that node, but
   may complete successfully on the rest of the nodes.

   Alternatively the modules could be installed using 'pip' or 'pip3' if that is available on the node.

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

