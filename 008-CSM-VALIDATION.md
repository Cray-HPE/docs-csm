# CSM Install Validation & Health Checks
This page lists available CSM install and health checks that can be executed to validate the CSM install. They can be run anytime after the install has run to completion, but not before.

Examples of when you may wish to run them are:
* after install.sh completes
* before and after NCN reboots
* after the system is brought back up
* any time there is unexpected behavior observed
* in order to provide relevant information to support tickets

## CMS

### Booting CSM Barebones Image

Included with the Cray System Manaement (CSM) release is a pre-built node image that can be used 
to validate that core CSM services are available and responding as expected. The CSM barebones 
image contains only the minimal set of RPMS and configuation required to boot an image and is not
suitable for production usage. To run production work loads, it is suggested that an image from 
the Cray OS (COS) product, or similar, be used.

---
**NOTE** 

The CSM Barebones image included with the Shasta 1.4 release will not successfully complete
the beyond the dracut stage of the boot process. However, if the dracut stage is reached the 
boot can be considered successful and shows that the necessary CSM services needed to 
boot a node are up and available.

This inability to fully boot the barebones image will be resolved in future releases of the
CSM product.

---

---
**NOTE**

In addition to the CSM Barebones image, the Shasta 1.4 release also includes an IMS Recipe that
can be used to build the CSM Barebones image. However, the CSM Barebones recipe currently requires
rpms that are not installed with the CSM product. The CSM Barebones recipe can be built after the
Cray OS (COS) product stream is also installed on to the system. 

In future releases of the CSM product, work will be undertaken to resolve these dependency issues.

---

#### Locate the CSM Barebones Image in IMS

Locate the CSM Barebones image and note the path to the image's manifest.json in S3.

    # cray ims images list --format json | jq '.[] | select(.name | contains("barebones"))'
    {
      "created": "2021-01-14T03:15:55.146962+00:00",
      "id": "293b1e9c-2bc4-4225-b235-147d1d611eef",
      "link": {
        "etag": "6d04c3a4546888ee740d7149eaecea68",
        "path": "s3://boot-images/293b1e9c-2bc4-4225-b235-147d1d611eef/manifest.json",
        "type": "s3"
      },
      "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4"
    }

#### Create a BOS Session Template for the CSM Barebones Image

The session template below can be copied and used as the basis for the BOS Session Template. As noted below, make sure the S3 path for the manifest matches the S3 path shown in IMS.

    # vi sessiontemplate.json
    {
      "boot_sets": {
        "compute": {
          "boot_ordinal": 2,
          "etag": "6d04c3a4546888ee740d7149eaecea68",  <== This should be set to the etag of the IMS Image
          "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
          "network": "nmn",
          "node_roles_groups": [
            "Compute"
          ],
          "path": "s3://boot-images/293b1e9c-2bc4-4225-b235-147d1d611eef/manifest.json",  <== Make sure this path matches the IMS Image Path
          "rootfs_provider": "cpss3",
          "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
          "type": "s3"
        }
      },
      "cfs": {
        "configuration": "cos-integ-config-1.4.0"
      },
      "enable_cfs": false,
      "name": "shasta-1.4-csm-bare-bones-image"
    }
     
    # cray bos v1 sessiontemplate create --file sessiontemplate.json --name shasta-1.4-csm-bare-bones-image
    /sessionTemplate/shasta-1.4-csm-bare-bones-image

#### Find an available node and boot the session template

    # cray hsm state components list
    ...
    [[Components]]
    ID = "x3000c0s6b0"
    Type = "NodeBMC"
    State = "Ready"
    Flag = "OK"
    Enabled = true
    NetType = "Sling"
    Arch = "X86"
    Class = "River"
     
    [[Components]]
    ID = "x3000c0s5e0"
    Type = "NodeEnclosure"
    State = "On"
    Flag = "OK"
    Enabled = true
    NetType = "Sling"
    Arch = "X86"
    Class = "River"
     
    # cray bos v1 session create --template-uuid shasta-1.4-csm-bare-bones-image --operation reboot --limit <xname>

#### Connect to the node's console nad watch the boot

The boot will fail, but should reach the dracut stage. If the dracut stage is reached, the boot 
can be considered successful and shows that the necessary CSM services needed to boot a node are 
up and available.

    cray-conman-b69748645-qtfxj:/ # conman -j x9000c1s7b0n1
    ...
    [    7.876909] dracut: FATAL: Don't know how to handle 'root=craycps-s3:s3://boot-images/e3ba09d7-e3c2-4b80-9d86-0ee2c48c2214/rootfs:c77c0097bb6d488a5d1e4a2503969ac0-27:dvs:api-gw-service-nmn.local:300:nmn0'
    [    7.898169] dracut: Refusing to continue
    [    7.952291] systemd-shutdow: 13 output lines suppressed due to ratelimiting
    [    7.959842] systemd-shutdown[1]: Sending SIGTERM to remaining processes...
    [    7.975211] systemd-journald[1022]: Received SIGTERM from PID 1 (systemd-shutdow).
    [    7.982625] systemd-shutdown[1]: Sending SIGKILL to remaining processes...
    [    7.999281] systemd-shutdown[1]: Unmounting file systems.
    [    8.006767] systemd-shutdown[1]: Remounting '/' read-only with options ''.
    [    8.013552] systemd-shutdown[1]: Remounting '/' read-only with options ''.
    [    8.019715] systemd-shutdown[1]: All filesystems unmounted.
    [    8.024697] systemd-shutdown[1]: Deactivating swaps.
    [    8.029496] systemd-shutdown[1]: All swaps deactivated.
    [    8.036504] systemd-shutdown[1]: Detaching loop devices.
    [    8.043612] systemd-shutdown[1]: All loop devices detached.
    [    8.059239] reboot: System halted

### Validation Utility
     /usr/local/bin/cmsdev

### CRAY INTERNAL USE ONLY
This tool is included in the cray-cmstools-crayctldeploy rpm, which comes preinstalled on the ncns. However, the tool is receiving frequent updates in the run up to the release. Because of this, it is highly recommended to download and install the latest version.

You can get the latest version of the rpm from car.dev.cray.com in the [csm/SCMS/sle15_sp2_ncn/x86_64/release/shasta-1.4/cms-team/](http://car.dev.cray.com/artifactory/webapp/#/artifacts/browse/tree/General/csm/SCMS/sle15_sp2_ncn/x86_64/release/shasta-1.4/cms-team) folder. Install it on every worker and master ncn (except for ncn-m001 if it is still the PIT node).

At the time of this writing there is a bug ([CASMTRIAGE-553](https://connect.us.cray.com/jira/browse/CASMTRIAGE-553)) which is causing the VCS test to hang about half of the time when it does a git push. If you see this, stop the test with control-C and re-run it. It may take a few tries but so far it has always eventually executed.

### Usage
     cmsdev test [-q | -v] <shortcut>
* The shortcut determines which component will be tested. See the table in the next section for the list of shortcuts.
* The tool logs to /opt/cray/tests/cmsdev.log
* The -q (quiet) and -v (verbose) flags can be used to decrease or increase the amount of information sent to the screen.
  * The same amount of data is written to the log file in either case.

#### Interpreting Results

* If a test passes:
  * The last line of output from the tool reports SUCCESS
  * The return code is 0.
* If a test fails:
  * The last line of output from the tool reports FAILURE
  * The return code is non-0.
* Unless the test was run in verbose mode, the log file will contain additional information about the execution.
* For more detailed information on the tests, please see the CSM Validation section of the admin guide (note to docs writers: replace this with the actual document name and section number/title once available).

### Checks To Run

You should run a check for each of the following services after an install. These should be run on at least one worker ncn and at least one master ncn (but **not** ncn-m001 if it is still the PIT node).

| Services  | Shortcut |
| ---  | --- |
| BOS (Boot Orchestration Service) | bos |
| CFS (Configuration Framework Service) | cfs |
| ConMan (Console Manager) | conman |
| CRUS (Compute Rolling Upgrade Service) | crus |
| IMS (Image Management Service) | ims |
| iPXE, TFTP (Trivial File Transfer Protocol) | ipxe* |
| VCS (Version Control Service) | vcs |

\* The ipxe shortcut runs a check of both the iPXE service and the TFTP service.

Next, run automated run-time checks against all nodes with the following command:

```
ncn:~ # /opt/cray/tests/install/ncn/automated/ncn-run-time-checks
```

Take note of any failed tests and correct the errors.

## HMS

### HMS Service Tests
Execute the HMS smoke and functional tests after the CSM install to confirm that the HMS services are running and operational.

### CRAY INTERNAL USE ONLY
The HMS tests are provided by the hms-ct-test-crayctldeploy RPM which comes preinstalled on the NCNs. However, the tests receive frequent updates so it is highly recommended to download and install the latest version of the RPM prior to executing the tests. The latest version of the RPM can be retrieved from car.dev.cray.com in the [ct-tests/HMS/sle15_sp2_ncn/x86_64/dev/master/hms-team/](http://car.dev.cray.com/artifactory/ct-tests/HMS/sle15_sp2_ncn/x86_64/dev/master/hms-team) folder. Install it on every worker and master NCN (except for ncn-m001 if it is still the PIT node).

### Test Execution
Run the HMS smoke tests. If no failures occur, then run the HMS functional tests. The tests should be executed as root on at least one worker NCN and one master NCN (but **not** ncn-m001 if it is still the PIT node).

    ncn:~ # /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_smoke_tests_ncn-resources.sh
    ncn:~ # /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_functional_tests_ncn-resources.sh

## PET

### Platform Health Checks

Scripts do not verify results. Script output includes analysis needed to determine pass/fail for each check. All health checks are expected to pass.
Health Check scripts can be run:
* after install.sh has been run – not before
* before and after one of the NCN's reboot
* after the system or a single node goes down unexpectedly
* after the system is gracefully shut down and brought up
* any time there is unexpected behavior on the system to get a baseline of data for CSM services and components
* in order to provide relevant information to support tickets that are being opened after sysmgmt manifest has been installed

Health Check scripts can be found and run on any worker or master node from any directory.

#### ncnHealthChecks
     /opt/cray/platform-utils/ncnHealthChecks.sh
The ncnHealthChecks script reports the following health information:
* Kubernetes status for master and worker NCNs
* Ceph health status
* Health of etcd clusters
* Number of pods on each worker node for each etcd cluster
* List of automated etcd backups for the Boot Orchestration Service (BOS),  Boot Script Service (BSS), Compute Rolling Upgrade Service (CRUS), and Domain Name Service (DNS)
* NCN node uptimes
* Pods yet to reach the running state

Execute ncnHealthChecks script and analyze the output of each individual check.

Verify that Border Gateway Protocol (BGP) peering sessions are established for each worker node on the system. See CSM Health Checks section of the Admin Guide.

#### ncnPostgresHealthChecks
     /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
For each postgres cluster the ncnPostgresHealthChecks script determines the leader pod and then reports the status of all postgres pods in the cluster. 

Execute ncnPostgresHealthChecks script. Verify leader for each cluster and status of cluster members.

### Shasta Health Services - Prometheus
In a browser access https://prometheus.SYSTEM_DOMAIN_NAME/ 
For example: https://prometheus.NAMEofSYSTEM.dev.cray.com/
Select the Alerts tab to view current alerts.

Pay attention to any KubeCronJobRunning alerts. Unexpected behavior on the system can result if cron jobs are not firing appropriately. See the System Management Health Architecture section of the Admin Guide for more information about system management monitoring. 

## UAS / UAI

### Initialize and Authorize the CLI

The procedures below use the CLI as an authorized user and run on two separate node types.  The first part runs on the LiveCD node while the second part runs on a non-LiveCD kubernetes master or worker node.  When using the CLI on either node, the CLI configuration needs to be initialized and the user running the procedure needs to be authorized.  This section describes how to initialize the CLI for use by a user and authorize the CLI as a user to run the procedures on any given node.  The procedures will need to be repeated in both stages of the validation procedure.

#### Stop Using the CRAY_CREDENTIALS Service Account Token

Installation procedures leading up to production mode on Shasta use the CLI with a Kubernetes managed service account normally used for internal operations.  There is a procedure for extracting the OAUTH token for this service account and assigning it to the `CRAY_CREDENTIALS` environment variable to permit simple CLI operations.  The UAS / UAI validation procedure runs as a post-installation procedure and requires an actual user with Linux credentials, not this service account. Prior to running any of the steps below you must unset the `CRAY_CREDENTIALS` environment variable:

```
# unset CRAY_CREDENTIALS
```

#### Initialize the CLI Configuration

The CLI needs to know what host to use to obtain authorization and what user is requesting authorization so it can obtain an OAUTH token to talk to the API Gateway.  This is accomplished by initializing the CLI configuration.  In this example, I am using the `vers` username.  In practice, `vers` and the response to the `password: ` prompt should be replaced with the username and password of the administrator running the validation procedure.

To check whether the CLI needs initialization, run:

```
# cray config describe
```

If the result looks like this:

```
# cray config describe
Usage: cray config describe [OPTIONS]

Error: No configuration exists. Run `cray init`
```

the CLI needs initialization.  If it looks more like this:

```
# cray config describe
Your active configuration is: default
[core]
hostname = "https://api-gw-service-nmn.local"

[auth.login]
username = "vers"
```

then the CLI is initialized and logged in as `vers`.  If you are not `vers` you will want to authorize yourself using your username and password in the next section.  If you are `vers` you are ready to move on to the validation procedure on that node.

Assuming you need to initialize the CLI, run the following (again, remembering to substitute your username and password for `vers` and the password response):

```
# cray init
Cray Hostname: api-gw-service-nmn.local
Username: vers
Password:
Success!

Initialization complete.
```

#### Authorize the CLI for Your User

If, when you check for an initialized CLI you find it is initialized but authorized for a user different from you, you will want to authorize the CLI for your self.  Do this with the following (remembering to substitute your username and password for `vers`):

```
# cray auth login
Username: vers
Password: 
Success!
```

You are now authorized to use the CLI.

#### Troubleshooting

If initialization or authorization fails in one of the above steps, there are several common causes:

* DNS failure looking up `api-gw-service-nmn.local` may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
* Network connectivity issues with the NMN may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
* Certificate mismatch or trust issues may be preventing a secure connection to the API Gateway
* Istio failures may be preventing traffic from reaching Keycloak
* Keycloak may not yet be set up to authorize you as a user

While resolving these issues is beyond the scope of this section, you may get clues to what is failing by adding `-vvvvv` to the `cray auth...` or `cray init ...` commands.

### Validate UAS and UAI Functionality

The following procedures run on separate nodes of the Shasta system.  They are, therefore, separated into separate sub-sections.

#### Validate the Basic UAS Installation

Make sure you are running on the LiveCD node and have initialized and authorized yourself in the CLI as described above.

Basic UAS installation is validated using the following:

```
ncn-m001-pit:~ # cray uas mgr-info list
service_name = "cray-uas-mgr"
version = "1.11.5"

ncn-m001-pit:~ # cray uas list
results = []
```

This shows that UAS is installed and running the `1.11.5` version.  It also shows that there are no currently running UAIs.  It is possible, if someone else has been using the UAS that there could be actual UAIs in the list.  That is acceptable too from a validation standpoint.

To verify that the pre-made UAI images are registered with UAS, use:

```
ncn-m001-pit:~ # cray uas images list
default_image = "registry.local/cray/cray-uai-sles15sp1:latest"
image_list = [ "registry.local/cray/cray-uai-broker:latest", "registry.local/cray/cray-uai-sles15sp1:latest",]

```

This shows that the pre-made end-user UAI image (`cray/cray-uai-sles15sp1:latest`) and the broker UAI image (`cray/cray-uai-broker:latest`) are registered with UAS. This does not necessarily mean these images are installed in the container image registry, but they are configured for use.  If other UAI images have been created and registered, they may also show up here, that is acceptable.

#### Validate UAI Creation

This procedure must run on a master or worker node (and not ncn-w001) on the Shasta system (or from an external host, but the procedure for that is not covered here).  It requires that the CLI be initialized and authorized as you.

To verify that you can create a UAI, use the following command:

```
ncn-w003:~ # cray uas create --publickey ~/.ssh/id_rsa.pub
uai_connect_string = "ssh vers@10.16.234.10"
uai_host = "ncn-w001"
uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
uai_ip = "10.16.234.10"
uai_msg = ""
uai_name = "uai-vers-a00fb46b"
uai_status = "Pending"
username = "vers"

[uai_portmap]
```

This has created the UAI and the UAI is currently in the process of initializing and running.  The following can be repeated as needed to watch the UAIs state.  When the results look like the following:

```
ncn-w003:~ # cray uas list
[[results]]
uai_age = "0m"
uai_connect_string = "ssh vers@10.16.234.10"
uai_host = "ncn-w001"
uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
uai_ip = "10.16.234.10"
uai_msg = ""
uai_name = "uai-vers-a00fb46b"
uai_status = "Running: Ready"
username = "vers"
```

The UAI is ready for use.  You can then log into it (without a password) as follows:

```
ncn-w003:~ # ssh vers@10.16.234.10
The authenticity of host '10.16.234.10 (10.16.234.10)' can't be established.
ECDSA key fingerprint is SHA256:BifA2Axg5O0Q9wqESkLqK4z/b9e1usiDUZ/puGIFiyk.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.16.234.10' (ECDSA) to the list of known hosts.
vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> ps -afe
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 18:51 ?        00:00:00 /bin/bash /usr/bin/uai-ssh.sh
munge         36       1  0 18:51 ?        00:00:00 /usr/sbin/munged
root          54       1  0 18:51 ?        00:00:00 su vers -c /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
vers          55      54  0 18:51 ?        00:00:00 /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
vers          62      55  0 18:51 ?        00:00:00 sshd: vers [priv]
vers          67      62  0 18:51 ?        00:00:00 sshd: vers@pts/0
vers          68      67  0 18:51 pts/0    00:00:00 -bash
vers         120      68  0 18:52 pts/0    00:00:00 ps -afe
vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> exit
logout
Connection to 10.16.234.10 closed.
```

Finally, clean up the UAI.  Notice that the UAI name used is the same as the name in the output from `cray uas create ...` above:

```
ncn-w003:~ # cray uas delete --uai-list uai-vers-a00fb46b
results = [ "Successfully deleted uai-vers-a00fb46b",]

```

If you got this far with similar results, then the UAS and UAI basic functionality is working.

#### Troubleshooting

Here are some common failure modes seen with UAS / UAI operations and how to resolve them.

##### Authorization Issues

If you are not logged in as a valid Keycloak user or are accidentally using the `CRAY_CREDENTIALS` environment variable (i.e. the variable is set regardless of whether you are logged in as you), you should see something like this:
```
# cray uas list
Usage: cray uas list [OPTIONS]
Try 'cray uas list --help' for help.

Error: Bad Request: Token not valid for UAS. Attributes missing: ['gidNumber', 'loginShell', 'homeDirectory', 'uidNumber', 'name']
```

Fix this by logging in as a real user (someone with actual Linux credentials) and making sure that `CRAY_CREDENTIALS` is unset.

##### UAS Cannot Access Keycloak

If you see something that looks like:

```
# cray uas list
Usage: cray uas list [OPTIONS]
Try 'cray uas list --help' for help.

Error: Internal Server Error: An error was encountered while accessing Keycloak
```

You may be using the wrong hostname to reach the API gateway, re-run the CLI initialization steps above and try again to check that.  There may also be a problem with the Istio service mesh inside of your Shasta system.  Troubleshooting this is beyond the scope of this section, but you may find more useful information by looking at the UAS pod logs in Kubernetes.  There are, generally, two UAS pods, so you may need to look at logs from both to find the specific failure.  The logs tend to have a very large number of `GET ` events listed as part of the aliveness checking.  The following shows an example of looking at UAS logs effectively (the example shows only one UAS manage, normally there would be two):

```
# kubectl get po -n services | grep uas-mgr | grep -v etcd
cray-uas-mgr-6bbd584ccb-zg8vx                                    2/2     Running            0          12d
# kubectl logs -n services cray-uas-mgr-6bbd584ccb-zg8vx cray-uas-mgr | grep -v 'GET ' | tail -25
2021-02-08 15:32:41,211 - uas_mgr - INFO - getting deployment uai-vers-87a0ff6e in namespace user
2021-02-08 15:32:41,225 - uas_mgr - INFO - creating deployment uai-vers-87a0ff6e in namespace user
2021-02-08 15:32:41,241 - uas_mgr - INFO - creating the UAI service uai-vers-87a0ff6e-ssh
2021-02-08 15:32:41,241 - uas_mgr - INFO - getting service uai-vers-87a0ff6e-ssh in namespace user
2021-02-08 15:32:41,252 - uas_mgr - INFO - creating service uai-vers-87a0ff6e-ssh in namespace user
2021-02-08 15:32:41,267 - uas_mgr - INFO - getting pod info uai-vers-87a0ff6e
2021-02-08 15:32:41,360 - uas_mgr - INFO - No start time provided from pod
2021-02-08 15:32:41,361 - uas_mgr - INFO - getting service info for uai-vers-87a0ff6e-ssh in namespace user
127.0.0.1 - - [08/Feb/2021 15:32:41] "POST /v1/uas?imagename=registry.local%2Fcray%2Fno-image-registered%3Alatest HTTP/1.1" 200 -
2021-02-08 15:32:54,455 - uas_auth - INFO - UasAuth lookup complete for user vers
2021-02-08 15:32:54,455 - uas_mgr - INFO - UAS request for: vers
2021-02-08 15:32:54,455 - uas_mgr - INFO - listing deployments matching: host None, labels uas=managed,user=vers
2021-02-08 15:32:54,484 - uas_mgr - INFO - getting pod info uai-vers-87a0ff6e
2021-02-08 15:32:54,596 - uas_mgr - INFO - getting service info for uai-vers-87a0ff6e-ssh in namespace user
2021-02-08 15:40:25,053 - uas_auth - INFO - UasAuth lookup complete for user vers
2021-02-08 15:40:25,054 - uas_mgr - INFO - UAS request for: vers
2021-02-08 15:40:25,054 - uas_mgr - INFO - listing deployments matching: host None, labels uas=managed,user=vers
2021-02-08 15:40:25,085 - uas_mgr - INFO - getting pod info uai-vers-87a0ff6e
2021-02-08 15:40:25,212 - uas_mgr - INFO - getting service info for uai-vers-87a0ff6e-ssh in namespace user
2021-02-08 15:40:51,210 - uas_auth - INFO - UasAuth lookup complete for user vers
2021-02-08 15:40:51,210 - uas_mgr - INFO - UAS request for: vers
2021-02-08 15:40:51,210 - uas_mgr - INFO - listing deployments matching: host None, labels uas=managed,user=vers
2021-02-08 15:40:51,261 - uas_mgr - INFO - deleting service uai-vers-87a0ff6e-ssh in namespace user
2021-02-08 15:40:51,291 - uas_mgr - INFO - delete deployment uai-vers-87a0ff6e in namespace user
127.0.0.1 - - [08/Feb/2021 15:40:51] "DELETE /v1/uas?uai_list=uai-vers-87a0ff6e HTTP/1.1" 200 -
```

##### UAI Images not in Registry

If you see something like:

```
# cray uas list
[[results]]
uai_age = "0m"
uai_connect_string = "ssh vers@10.103.13.172"
uai_host = "ncn-w001"
uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
uai_ip = "10.103.13.172"
uai_msg = "ErrImagePull"
uai_name = "uai-vers-87a0ff6e"
uai_status = "Waiting"
username = "vers"
```

the pre-made end-user UAI image is not in your local registry (or whatever registry it is being pulled from, see the `uai_img` value for details).  Locate and push / import the image to the registry.

##### Missing Volumes and other Container Startup Issues

Various packages install volumes in the UAS configuration.  All of those volumes must also have the underlying resources available, sometimes on the host node where the UAI is running sometimes from with Kubernetes.  If your UAI gets stuck with a `ContainerCreating` `uai_msg` field for an extended time, this is a likely cause.  UAIs run in the `user` Kubernetes namespace, and are pods that can be examined using `kubectl describe`.  Use

```
# kubectl get po -n user | grep <uai-name>
```

to locate the pod, and then use

```
# kubectl describe -n user <pod-name>
```

to investigate the problem.  If volumes are missing they will show up in the `Events:` section of the output.  Other problems may show up there as well.  The names of the missing volumes or other issues should indicate what needs to be fixed to make the UAI run.

## NET

### Verify that KEA has active DHCP leases

Verify that KEA has active DHCP leases. Right after an fresh install of CSM it is important to verify that KEA is currently handing out DHCP leases on the system. The following commands can be ran on any of the ncn masters or workers.

Get a API Token:
```
# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                 -d client_id=admin-client \
                 -d client_secret=`kubectl get secrets admin-client-auth \
                 -o jsonpath='{.data.client-secret}' | base64 -d` \
                          https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

Retrieve all the Leases currently in KEA:
```
# curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq
```

If there is an non-zero amount of DHCP leases for river hardware returned that is a good indication that KEA is working.
