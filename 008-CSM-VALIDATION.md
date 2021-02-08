# CSM Install Validation & Health Checks
This page lists available CSM install and health checks that can be executed to validate the CSM install. They can be run anytime after the install has run to completion, but not before.

Examples of when you may wish to run them are:
* after install.sh completes
* before and after NCN reboots
* after the system is brought back up
* any time there is unexpected behavior observed
* in order to provide relevant information to support tickets

## CMS

### Validation Utility
     /usr/local/bin/cmsdev

### CRAY INTERNAL USE ONLY
This tool is included in the cray-cmstools-crayctldeploy rpm, which comes preinstalled on the ncns. However, the tool is receiving frequent updates in the run up to the release. Because of this, it is highly recommended to download and install the latest version.

You can get the latest version of the rpm from car.dev.cray.com in the [csm/SCMS/sle15_sp2_ncn/x86_64/dev/master/cms-team/](http://car.dev.cray.com/artifactory/webapp/#/artifacts/browse/tree/General/csm/SCMS/sle15_sp2_ncn/x86_64/dev/master/cms-team) folder. Install it on every worker and master ncn (except for ncn-m001 if it is still the PIT node).

At the time of this writing there is a bug ([CASMTRIAGE-553](https://connect.us.cray.com/jira/browse/CASMTRIAGE-553)) which is causing the VCS test to hang about half of the time when it does a git push. If you see this, stop the test with control-C and re-run it. It may take a few tries but so far it has always eventually executed.

### Usage
     cmsdev test [-q | -v] <shortcut>
* The tool logs to /opt/cray/tests/cmsdev.log
* The -q (quiet) and -v (verbose) flags can be used to decrease or increase the amount of information sent to the screen.
  * The same amount of data is written to the log file in either case.

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

Basic installation validation of UAS can be done once Keycloak is running and able to authenticate users.  The following shows commands and expected results, including the necessary setup if the CLI has not yet been initialized.  Notice the the user here is `vers` replace this with any CLI authorized user:

```
ncn-m001-pit:~ # cray init
Cray Hostname: api-gw-service-nmn.local
Username: vers
Password:
Success!

Initialization complete.
ncn-m001-pit:~ # cray uas mgr-info list
service_name = "cray-uas-mgr"
version = "1.11.5"

ncn-m001-pit:~ # cray uas list
results = []

ncn-m001-pit:~ # cray uas images list
default_image = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
image_list = [ "dtr.dev.cray.com/cray/cray-uai-broker:latest", "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest",]
```

From here, move to a real master or worker node (not the LiveCD node) to test basic creation and function of UAIs.  Again, the user is `vers` replace this with any CLI authorized user:

```
ncn-w003:~ # cray init
Cray Hostname: api-gw-service-nmn.local
Username: vers
Password:
Success!

Initialization complete.
ncn-w003:~ # cray uas create --publickey ~/.ssh/id_rsa.pub
uai_connect_string = "ssh vers@10.16.234.10"
uai_host = "ncn-w001"
uai_img = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
uai_ip = "10.16.234.10"
uai_msg = ""
uai_name = "uai-vers-a00fb46b"
uai_status = "Pending"
username = "vers"

[uai_portmap]

ncn-w003:~ # cray uas list
[[results]]
uai_age = "0m"
uai_connect_string = "ssh vers@10.16.234.10"
uai_host = "ncn-w001"
uai_img = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
uai_ip = "10.16.234.10"
uai_msg = ""
uai_name = "uai-vers-a00fb46b"
uai_status = "Running: Ready"
username = "vers"


ncn-w003:~ # ssh vers@10.16.234.10
The authenticity of host '10.16.234.10 (10.16.234.10)' can't be established.
ECDSA key fingerprint is SHA256:BifA2Axg5O0Q9wqESkLqK4z/b9e1usiDUZ/puGIFiyk.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.16.234.10' (ECDSA) to the list of known hosts.
-bash: /usr/bin/tclsh: No such file or directory
Error: Unable to initialize environment modules.
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

Clean up the UAI.  Notice that the UAI name used is the same as the name in the output from `cray uas create ...` above:

```
ncn-w003:~ # cray uas delete --uai-list uai-vers-a00fb46b
results = [ "Successfully deleted uai-vers-a00fb46b",]

```

If you got this far with similar results, then the UAS and UAI basic functionality is working.

## NET

### Verify that KEA has active DHCP leases

Verify that KEA has active DHCP leases. Right after an fresh install of CSM it is important to verify that KEA is currently handing out DHCP leases on the system. The following commands can be ran on any of the ncn masters or workers.

Get a API Token:
```
ncn-w001:~ # export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                          -d client_id=admin-client \
                          -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                          https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

Retrieve all the Leases currently in KEA:
```
ncn-w001:~ # curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all",  "service": [ "dhcp4" ] }' https://api_gw_service.local/apis/dhcp-kea | jq
```

If there is an non-zero amount of DHCP leases for river hardware returned that is a good indication that KEA is working.