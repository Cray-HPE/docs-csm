# CSM Validation

This page will guide you through validating the CSM install. 

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

> **THIS IS A STUB** There are no instructions on this page, this page is place-holder.
