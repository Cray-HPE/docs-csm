# Resiliency Testing Procedure

This document and the procedures contained within it are for the purposes of communicating the kind of testing done by the internal Cray System Management (CSM) team to ensure a basic level of system resiliency in the event of
the loss of a single non-compute node (NCN).

It is assumed that some procedures are already known by admins and thus does not go into great detail or attempt to encompass every command necessary for execution. It is intended to be higher level guidance (with some command
examples) to inform internal users and customers about our process.

* [Prepare for resiliency testing](#prepare-for-resiliency-testing)
* [Establish system health before beginning](#establish-system-health-before-beginning)
* [Monitor for changes](#monitor-for-changes)
* [Launch a non-interactive batch job](#launch-a-non-interactive-batch-job)
* [Shut down an NCN](#shut-down-an-ncn)
* [Conduct testing](#conduct-testing)
* [Power on the downed NCN](#power-on-the-downed-ncn)
* [Execute post-boot health checks](#execute-post-boot-health-checks)

## Prepare for resiliency testing

* Confirm the component name (xname) mapping for each node on the system by running the `/opt/cray/platform-utils/ncnGetXnames.sh` script on each node.

* Verify that `metal.no-wipe=1` is set for each of the NCNs using output from running the `ncnGetXnames.sh` script.

* (`ncn-mw#`) Ensure the user account in use is an authorized user on the Cray CLI.

  Log in as a user account where the credentials are known:

   ```bash
   export CRAY_CONFIG_DIR=$(mktemp -d); echo $CRAY_CONFIG_DIR; cray init --configuration default --hostname https://api-gw-service-nmn.local
   ```

   Then, validate the authorization by executing the `cray uas list` command, for example. For more information, see the `Validate UAI Creation` section of [Validate CSM Health](../validate_csm_health.md).

* (`ncn-mw#`) Verify that `kubectl get nodes` reports all master and worker nodes are `Ready`.

   ```bash
   kubectl get nodes -o wide
   ```

* (`ncn-mw#`) Get a current list of pods that have a status of anything other than `Running` or `Completed`. Investigate any of concern.
  Save the list of pods for comparison once resiliency testing is completed and the system has been restored.

   ```bash
   kubectl get pods -o wide -A | grep -Ev 'Running|Completed'
   ```

* (`ncn-mw#`) Note which pods are running on an NCN that will be taken down (as well as the total number of pods running). The following is an example that shows the listing of pods running on `ncn-w001`:

   ```bash
   kubectl get pods -o wide -A | grep ncn-w001 | awk '{print $2}'
   ```

   Note that the above would only apply to Kubernetes nodes, such as master and worker nodes.

* (`linux#`) Verify `ipmitool` can report power status for the NCN to be shut down.

   ```bash
   ipmitool -I lanplus -U root -P <password> -H <ncn-node-name> chassis power status
   ```

   If `ncn-m001` is the node to be brought down, then note that it has the external network connection. Therefore it is important to establish that `ipmitool` commands are able to be run from a node external to the system, in
   order to get the power status of `ncn-m001`.

* If `ncn-m001` is the node to be brought down, then establish Customer Access Network (CAN) links to bypass `ncn-m001` (because it will be down) in order to enable an external connection to one of the other master NCNs before,
  during, and after `ncn-m001` is brought down.

* Verify Boot Orchestration Service (BOS) templates and create a new one if needed (to be set-up for booting a specific compute nodes after the targeted NCN has been shutdown).

   Before shutting down the NCN and beginning resiliency testing, verify that compute nodes identified for reboot validation can be successfully rebooted and configured.

   (`ncn-mw#`) To see a list of BOS templates that exist on the system:

   ```bash
   cray bos v1 sessiontemplate list
   ```

   For more information regarding management of BOS session templates, refer to [Manage a Session Template](../boot_orchestration/Manage_a_Session_Template.md).

* If a UAN is present on the system, log onto it and verify that the workload manager (WLM) is configured by running a command.

   (`uan#`) The following is an example for Slurm:

   ```bash
   srun -N 4 hostname | sort
   ```

## Establish system health before beginning

In order to ensure that the system is healthy before taking an NCN node down, run the `Platform Health Checks` section of [Validate CSM Health](../validate_csm_health.md).

If health issues are noted, it is best to address those before proceeding with the resiliency testing procedure. If it is believed (in the case of an internal Cray-HPE testing environment) that the issue is known/understood
and will not impact the testing to be performed, then those health issues just need to be noted (so that it does not appear that they were caused by inducing the fault, in this case, powering off the NCN). There is an optional
section of the platform health validation that deals with using the System Management monitoring tools to survey system health. If that optional validation is included, note that the Prometheus alert manager may show
various alerts that would not prevent or block moving forward with this testing. For more information about Prometheus alerts (and some that can be safely ignored), see
[Troubleshooting Prometheus Alerts](../system_management_health/Troubleshoot_Prometheus_Alerts.md).

Part of the data being returned via execution of the `Platform Health Checks` includes `patronictl` information for each Postgres cluster. Each of the Postgres clusters has a leader pod, and in the case of a resiliency test
that involves bringing an NCN worker node down, it may be useful to take note of the Postgres clusters that have their leader pods running on the NCN worker targeted for shutdown. The `postgres-operator` should handle
re-establishment of a leader on another pod running in the cluster, but it is worth taking note of where leader re-elections are expected to occur so special attention can be given to those Postgres clusters.

(`ncn-mw#`) The Postgres health check is included in [Validate CSM Health](../validate_csm_health.md), but the script for dumping Postgres data can be run at any time:

```bash
/opt/cray/platform-utils/ncnPostgresHealthChecks.sh
```

## Monitor for changes

In order to keep watch on various items during and after the fault has been introduced (in this case, the shutdown of a single NCN), the steps listed below can help give insight into changing health conditions.

1. (`ncn-mw#`) Set up a `watch` command to repeatedly run with the Cray CLI (that will hit the service API) to ensure that critical services can ride through a fault. Note that there is not more than a window of 5-10 minutes where a
   service would intermittently fail to respond.

   In the examples below, the CLI commands are checking the BOS and CPS APIs. It may be desired to choose additional Cray CLI commands to run in this manner. The ultimate proof of system resiliency lies in the ability to
   perform system level use cases and to, further, prove that can be done at scale. If there are errors being returned consistently (and without recovery) with respect to these commands, then it is likely that business critical
   use cases (that utilize the same APIs) will also fail.

   It may be useful to reference instructions for [Configuring the Cray CLI](../configure_cray_cli.md).

   ```bash
   watch -n 5 "date; cray cps contents"
   ```

   ```bash
   watch -n 5 "date; cray bos v1 session list"
   ```

1. Monitor Ceph health, in a window, during and after a single NCN is taken down.

   ```bash
   watch -n 5 "date; ceph -s"
   ```

1. (`ncn-mw#`) Identify when pods on a downed master or worker NCN are no longer responding.

   This takes around 5-6 minutes, and Kubernetes will begin terminating pods so that new pods to replace them can start-up on another NCN. Pods that had been running on the downed NCN will remain in `Terminated` state until
   the NCN is back up. Pods that need to start-up on other nodes will be `Pending` until they start-up. Some pods that have anti-affinity configurations or that run as `daemonsets` will not be able to start up on another NCN.
   Those pods will remain in Pending state until the NCN is back up.

   Finally, it is helpful to have a window tracking the list of pods that are not in `Completed` or `Running` state to be able to determine how that list is changing once the NCN is downed and pods begin shifting around. This
   step offers a view of what is going on at the time that the NCN is brought down and once Kubernetes detects an issue and begins remediation. It is not so important to capture everything that is happening during this step. It
   may be helpful for debugging. The output of these windows/commands becomes more interesting once the NCN is down for a period of time and then it is brought back up. At that point, the expectation is that everything can
   recover.

   Run the following commands in separate windows:

   ```bash
   watch -n 5 "date; kubectl get pods -o wide -A | grep Termin"
   ```

   ```bash
   watch -n 10 "date; kubectl get pods -o wide -A | grep Pending"
   ```

   ```bash
   watch -n 5 "date; kubectl get pods -o wide -A | grep -v Completed | grep -v Running"
   ```

1. (`ncn-mw#`) Detect the change in state of the various Postgres instances running.

   Run the following in a separate window:

   ```bash
   watch -n 30 "date; kubectl get postgresql -A"
   ```

   If Postgres reports a status that deviates from `Running`, that would require further investigation and possibly remediation via [Troubleshooting the Postgres Database](../kubernetes/Troubleshoot_Postgres_Database.md).

## Launch a non-interactive batch job

The purpose of this procedure is to launch a non-interactive, long-running batch job across computes via a UAI (or the UAN, if present) in order to ensure that even though the UAI pod used to launch the job is running on the
worker NCN being taken down, it will start up on another worker NCN (once Kubernetes begins terminating pods).

Additionally, it is important to verify that the batch job continued to run, uninterrupted through that process. If the target NCN for shutdown is not a worker node (where a UAI would be running), then there is no need to pay
attention to the steps, below, that discuss ensuring the UAI can only be created on the NCN worker node that is targeted for shutdown. If executing a shut down of a master or storage NCN, the procedure can begin at creating a
UAI. It is still good to ensure that non-interactive batch jobs are uninterrupted, even with the UAI they are launched from is not being disrupted.

### Launch on a UAI

1. (`ncn-mw#`) Create a UAI.

   To create a UAI, see the `Validate UAI Creation` section of [Validate CSM Health](../validate_csm_health.md) and/or [Create a UAI](../UAS_user_and_admin_topics/Create_a_UAI.md).

   If the target node for shutdown is a worker NCN, force the UAI to be created on target worker NCN with the following steps:

   1. Create labels to ensure that UAI pods will only be able to start-up on the target worker NCN.

      In this example, `ncn-w002` is the target node for shutdown on a system with only three NCN worker nodes.

      ```bash
      kubectl label node ncn-w001 uas=False --overwrite
      kubectl label node ncn-w003 uas=False --overwrite
      ```

      If successful, output similar to `node/ncn-w00X labeled` will be returned.

   1. Verify the labels were applied successfully.

      ```bash
      kubectl get nodes -l uas=False
      ```

      Example output:

      ```text
      NAME       STATUS   ROLES    AGE     VERSION
      ncn-w001   Ready    <none>   4d19h   v1.18.2
      ncn-w003   Ready    <none>   4d19h   v1.18.2
      ```

   1. Remove the labels set above after the UAI has been created.

      > **IMPORTANT:** After a UAI has been created, labels must be cleared or else when Kubernetes terminates the running UAI on the NCN being shut down, it will not be able to reschedule the UAI on another pod.

      ```bash
      kubectl label node ncn-w001 uas-
      kubectl label node ncn-w003 uas-
      ```

1. Verify that WLM is configured with the appropriate workload manager within the created UAI.

   1. (`ncn-mw#`) Verify the connection string of the created UAI.

      ```bash
      cray uas list --format toml
      ```

      Example output:

      ```toml
      [[results]]
      uai_age = "2m"
      uai_connect_string = "ssh vers@10.103.8.170"
      uai_host = "ncn-w002"
      uai_img = "registry.local/cray/cray-uai-cos-2.1.70:latest"
      uai_ip = "10.103.8.170"
      uai_msg = ""
      uai_name = "uai-vers-f8fa541f"
      uai_status = "Running: Ready"
      username = "vers"
      ```

   1. (`ncn-mw#`) Log in to the created UAI.

      For example:

      ```bash
      ssh vers@10.103.8.170
      ```

   1. (`uai#`) Verify the configuration of Slurm, for example, within the UAI:

      ```bash
      srun -N 4 hostname | sort
      ```

      Example output:

      ```text
      nid000001
      nid000002
      nid000003
      nid000004
      ```

1. Copy an MPI application source and WLM batch job files to the UAI.

1. Compile an MPI application with the UAI. Launch application as batch job (not interactive) on compute node(s) that have not been designated, already, for reboots once an NCN is shut down.

   1. Verify that batch job is running and that application output is streaming to a file. Streaming output will be used to verify that the batch job is still running during resiliency testing. A batch job, when submitted, will
      designate a log file location. This log file can be accessed to be able to verify that the batch job is continuing to run after an NCN is brought down and once it is back online. Additionally, the `squeue` command can be
      used to verify that the job continues to run (for Slurm).

   1. (`ncn-mw#`) Delete the UAI session when all of the testing is complete.

      ```bash
      cray uas delete --uai-list uai-vers-f8fa541f
      ```

### Launch on a UAN

1. (`uan#`) Log in to the UAN and verify that a WLM has been properly configured.

   In this example, Slurm will be used.

   ```bash
   srun -N 4 hostname | sort
   ```

   Example output:

   ```text
   nid000001
   nid000002
   nid000003
   nid000004
   ```

1. Copy an MPI application source and WLM batch job files to UAN.

1. Compile an MPI application within the UAN. Launch the application as interactive on compute node(s)that have not been designated, already, for either reboots (once an NCN is shut down) or that are not already running an MPI
   job via a UAI.

1. Verify that the job launched on the UAN is running and that application output is streaming to a file. Streaming output will be used to verify that the batch job is still running during resiliency testing. A batch job, when
   submitted, will designate a log file location. This log file can be accessed to be able to verify that the batch job is continuing to run after an NCN is brought down and once it is back online. Additionally, the `squeue`
   command can be used to verify that the job continues to run (for Slurm).

## Shut down an NCN

1. Establish a console session to the NCN targeted for shutdown by executing the steps in [Establish a Serial Connection to NCNs](../conman/Establish_a_Serial_Connection_to_NCNs.md).

1. Log onto the target node and execute `/sbin/shutdown -h 0`.

   1. Take note of the timestamp of the power off in the target node's console output.

   1. (`linux#`) Once the target node is reported as being powered off, verify that the node's power status with the `ipmitool` is reported as off.

      ```bash
      ipmitool -I lanplus -U root -P <password> -H <ncn-node-name> chassis power status
      ```

      **`NOTE`** In previous releases, an `ipmitool` command has been used to simply yank the power to an NCN. There have been times where this resulted in a longer recovery procedure under Shasta 1.5 (mostly due to issues with
      getting nodes physically booted up again), so the preference has been to simply use the `shutdown` command.

      If the NCN shutdown is a master or worker node, within 5-6 minutes of the node being shut down, Kubernetes will begin reporting `Terminating` pods on the target node and start rescheduling pods to other NCN nodes. New
      pending pods will be created for pods that can not be relocated off of the NCN shut down. Pods reported as `Terminating` will remain in that state until the NCN has been powered back up.

1. Take note of changes in the data being reported out of the many monitoring windows that were set-up in a previous step.

## Conduct testing

After the target NCN was shut down, assuming the command line windows that were set up for ensuring API responsiveness are not encountering persistent failures, the next step will be to use a BOS template to boot a
pre-designated set of compute nodes. The timing of this test is recommended to be around 10 minutes after the NCN has gone down. That should give ample time for Kubernetes to have terminated pods on the downed node (in the case
of a master or worker NCN) and for them to have been rescheduled and in a healthy state on another NCN. Going too much earlier than 10 minutes runs the risk that there are still some critical pods that are settling out to reach
a healthy state.

1. (`ncn-mw#`) Reboot a pre-designated set of compute nodes and watch the reboot.

   1. Use BOS to reboot the designated compute nodes.

      ```bash
      cray bos v1 session create --template-uuid boot-nids-1-4 --operation reboot
      ```

      Issuing this reboot command will output a Boot Orchestration Agent (BOA) `jobId`, which can be used to find the new BOA pod that has been created for the boot. Then, the logs can be tailed to watch the compute boot proceed.

   1. Find the BOA job name using the returned BOA `jobID`.

      ```bash
      kubectl get pods -o wide -A | grep <boa-job-id>
      ```

   1. Watch the progress of the reboot of the compute nodes.

      ```bash
      kubectl logs -n services <boa-job-pod-name> -c boa -f
      ```

      Failures or a timeout being reached in either the boot or CFS (post-boot configuration) phase will need investigation. For more information around accessing logs for the BOS operations, see
      [Check the Progress of BOS Session Operations](../boot_orchestration/Check_the_Progress_of_BOS_Session_Operations.md).

1. If the target node for shutdown was a worker NCN, verify that the UAI launched on that node still exists. It should be running on another worker NCN.

   * Any prior SSH session established with the UAI while it was running on the downed NCN worker node will be unresponsive. A new SSH session will need to be established once the UAI pods has been successfully relocated to
     another worker NCN.
   * Log back into the UAI and verify that the WLM batch job is still running and streaming output. The log file created with the kick-off of the batch job should still be accessible and the `squeue` command can be used to
     verify that the job continues to run (for Slurm).

1. If the WLM batch job was launched on a UAN, log back into it and verify that the batch job is still running and streaming output via the log file created with the batch job and/or the `squeue` command (if Slurm is used as
   the WLM).

1. Verify that new WLM jobs can be started on a compute node after the NCN is down (either via a UAI or the UAN node).

1. (`ncn-mw#`) Look for any pods that are in a state other than `Running`, `Completed`, `Pending`, or `Terminating`:

   ```bash
   kubectl get pods -o wide -A | grep -Ev "Running|Completed|Pending|Termin"
   ```

   Compare what comes up in this list to the pod list that was collected before. If there are new pods that are in status `ImagePullBackOff` or `CrashLoopBackOff`, a `kubectl describe` as well as `kubectl logs` command should
   be run against them to collect additional data about what happened. Obviously, if there were pods in a bad state before the procedure started, then it should not be expected that bringing one of the NCNs down is going to fix
   that.

   Ignore anything that was already in a bad state before (that was deemed to be okay). It is also worth taking note of any pods in a bad state at this stage as this should be checked again after bringing the NCN back up - to
   see if those pods remain in a bad state or if they are cleared. Noting behaviors, collecting logs, and opening tickets throughout this process is recommended when behavior occurs that is not expected. When we see an issue
   that has not been encountered before, it may not be immediately clear if code changes/regressions are at fault or if it is simply an intermittent/timing kind of issue that has not previously surfaced. The recommendation at
   that point, given time/resources is to repeat the test to gain a sense of the repeatability of the behavior (in the case that the issue is not directly tied to a code change).

   Additionally, it is as important to understand (and document) any work-around procedures needed to fix issues encountered. In addition to filing a bug for a permanent fix, workaround documentation can be very useful when
   written up - for both internal and external customers to access.

## Power on the downed NCN

1. (`linux#`) Use the `ipmitool` command to power up the NCN.

   It will take several minutes for the NCN to reboot. Progress can be monitored over the connected serial console session. Wait to begin execution of the next steps until after it can be determined that the NCN has booted
   up and is back at the login prompt (when viewing the serial console log).

   ```bash
   ipmitool -I lanplus -U root -P <password> -H <hostname> chassis power on   #example hostname is ncn-w003-mgmt
   ```

   Check the following depending on the NCN type powered on:

   * If the NCN being powered on is a master or worker, verify that `Terminating` pods on that NCN clear up. It may take several minutes. Watch the command prompt, previously set-up, that is displaying the `Terminating` pod list.
   * If the NCN being powered on is a storage node, wait for Ceph to recover and again report a `HEALTH_OK` status. It may take several minutes for Ceph to resolve clock skew. This can be noted in the previously set-up window
     to watch Ceph status.

1. Check that pod statuses have returned to the state that they were in at the beginning of this procedure, paying particular attention to any pods that were previously noted to be in a bad state while the NCN was down.
   Additionally, there is no concern if pods that were in a bad state at the beginning of the procedure, are still in a bad state. What is important to note is anything that is different from either the beginning of the test or
   from the time that the NCN was down.

## Execute post-boot health checks

1. Re-run the `Platform Health Checks` section of [Validate CSM Health](../validate_csm_health.md) noting any output that indicates output is not as expected.

1. Ensure that after a downed NCN worker node (can ignore if not a worker node) has been powered up, a new UAI can be created on that NCN. It may be necessary to label the nodes again, to ensure the UAI gets created on the
   worker node that was just powered on. Refer to the section above for `Launch a Non-Interactive Batch Job` for the procedure.

   > **IMPORTANT:** Do not forget to remove the labels after the UAI has been created. Once the UAI has been created, log into it and ensure a new workload manager job can be launched.

1. Ensure tickets have been opened for any unexpected behavior along with associated logs and notes on workarounds, if any were executed.
