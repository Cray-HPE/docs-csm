# System Power On Procedures

The procedures in this section detail the high-level tasks required to power on an HPE Cray EX system.

**Important:** If an emergency power off \(EPO\) event occurred, then see [Recover from a Liquid-Cooled Cabinet EPO Event](Recover_from_a_Liquid_Cooled_Cabinet_EPO_Event.md) for recovery procedures.

If user IDs or passwords are needed, then see step 1 of the [Prepare the System for Power Off](Prepare_the_System_for_Power_Off.md#procedure) procedure.

## Note about services used during system power on

- The Power Control Service \(PCS\) service controls power to major components. PCS sequences the power on tasks in the correct order, but  **does not** determine if the required software services are running on the components.
- The Cray Advanced Platform Monitoring and Control \(CAPMC\) service can also control power to major components. CAPMC sequences the power on tasks in the correct order, but **does not** determine if the required software services are running on the components.
- The Boot Orchestration Service \(BOS\) manages and configures power on and boot tasks.
- The System Admin Toolkit \(SAT\) automates boot and shutdown services by stage.

## Known issues during system power on

### `sma-timescaledb-single` in `CrashLoopBackOff` state

Some pods like `sma-timescaledb-single-1` or `sma-timescaledb-single-2` are in `CrashLoopBackOff` status when the system is powered up.
Although `sma-timescaledb-single` pod 0 started, pod 1 and 2 show `CrashLoopBackOff` status.

```text
NAMESPACE     NAME                 READY       STATUS
sma    sma-timescaledb-single-1     0/1     CrashLoopBackOff
sma    sma-timescaledb-single-2     0/1     CrashLoopBackOff
```

Run the following command to resolve this issue:

```bash
kubectl delete pod -n sma sma-timescaledb-single-1
```

This command will fix `sma-timescaledb-single-1` pod and then it fixes pod 2 automatically.

### SMA Alerta and Monasca fail to start

SMA Alerta and Monasca fail to start when the system is powered up.
The job `sma-pgdb-init-job-1` is missing which prevents `sma-alerta-*` from starting. `sma-monasca-*` pod shows `CrashBackLoopOff` status waiting for Alerta to initialize.

(`ncn-m001#`)

```bash
kubectl get pods -A -o wide | grep -Ev " (Completed|Running|(cray-dns-unbound-manager|hms-discovery)-.* (Pending|Init:0/[1-9]|PodInitializing|NotReady|Terminating)) "
```

Example output:

```text
NAMESPACE     NAME                                     READY   STATUS
sma     sma-aiops-enable-disable-models-28891714-v8pcf  0/1 ContainerCreating
sma     sma-alerta-54b657ccb9-ptx4s                     0/1     Init:0/1
sma     sma-monasca-notification-0                      0/1 CrashLoopBackOff    
 --- WARNING --- not all pods are in a 'Running' or 'Completed' state.
```

The `wait-for-sma-pgdb-init-job` container appears to be waiting for this pod which does not exist.

(`ncn-m001#`)

```bash
kubectl logs -n sma sma-alerta-54b657ccb9-ptx4s -c wait-for-sma-pgdb-init-job --timestamps | head -20
```

Example output:

```text
2024-12-05T22:15:34.783970586Z Error from server (NotFound): jobs.batch "sma-pgdb-init-job1" not found
2024-12-05T22:15:34.847387533Z Waiting for sma-pgdb-init job to complete
```

To resolve this issue, use the following workaround:

1. (`ncn#`) Check how many helm versions exist.

   ```bash
   helm history -n sma sma-pgdb-init
   ```

   Example output:

   ```text
   REVISION   UPDATED   STATUS     CHART        APP VERSION  DESCRIPTION     
      1    Sep 23 2024   deployed sma-pgdb-init-1.7.1 1.7.1  Install complete
   ```

2. (`ncn#`) This command works when there is one or more versions that have single digit version numbers.
   It will fail if there is a version 1,10,2,3,4,5,6,7,9 because of the non-numerical sort.
   If there are any two digit versions, then the helm rollback command should be used with a specific older version.

   ```bash
   helm rollback -n sma sma-pgdb-init $(helm history -n sma sma-pgdb-init | awk '{print $1}' |  tail -c 2)
   ```

3. Once the `sma-pgdb-init` job is complete, confirm that the `sma-alerta` and `sma-monasca-notification-0` pods have started normally.

4. (`ncn#`) Confirm how long the `ttlSecondsAfterFinished` value is set in the new job.

   ```bash
   kubectl -n sma get job sma-pgdb-init-job1 -o yaml > sma-pgdb-init-job1.yaml
   grep ttl sma-pgdb-init-job1.yaml
        cluster-job-ttl.cluster-job-ttl.kyverno.io: added /spec/ttlSecondsAfterFinished
    ttlSecondsAfterFinished: 259200
   ```

   This is the number of seconds that a system can be powered off before the job will be deleted. 259200 seconds is only 72 hours so the job will be deleted by Kubernetes after 72 hours.
   If the system is powered off for more than 72 hours, this job will be purged and hence preventing these SMA pods from starting correctly. So increase the value.

5. (`ncn#`) Use the already collected YAML file for `sma-pgdb-init-job1` to delete the current job.

   ```bash
   kubectl -n sma delete -f sma-pgdb-init-job1.yaml
   ```

6. (`ncn#`) Modify the YAML file and make these changes:

   - remove status section
   - remove all UID(s)
   - change `ttlSecondsAfterFinished` value to `maxint`
   - `ttlSecondsAfterFinished: 2147483647`

   ```bash
   vi sma-pgdb-init-job1.yaml
   ```

7. (`ncn#`) Apply new settings.

   ```bash
   kubectl -n sma apply -f sma-pgdb-init-job1.yaml
   ```

## Power on cabinet circuit breakers and PDUs

Always use the cabinet power-on sequence for the site.

The management cabinet is the first part of the system that must be powered on and booted. Management network and Slingshot fabric switches power on and boot when cabinet power is applied. After
cabinets are powered on, wait at least 10 minutes for systems to initialize.

After all the system cabinets are powered on, be sure that all management network and Slingshot network switches are powered on, and that there are no error LEDS or hardware failures.

## Power On the External File Systems

To power on an external Lustre file system (ClusterStor), refer to [Power On the External Lustre File System](Power_On_the_External_Lustre_File_System.md).

To power on the external Spectrum Scale (GPFS) file system, refer to site procedures.

**Note:** If the external file systems are not mounted on worker nodes, then continue to power them in parallel with
the power on and boot of the Kubernetes management cluster and the power on of the compute cabinets. This must be completed
before beginning to power on and boot the compute nodes and User Access Nodes (UANs).

## Power on and boot the Kubernetes management cluster

To power on the management cabinet and bring up the management Kubernetes cluster, refer to [Power On and Start the Management Kubernetes Cluster](Power_On_and_Start_the_Management_Kubernetes_Cluster.md).

## Power on compute cabinets

To power on all liquid-cooled cabinet CDUs and cabinet PDUs, refer to [Power On Compute Cabinets](Power_On_Compute_Cabinets.md).

## Power on and boot compute nodes and User Access Nodes \(UANs\)

**Note:** Ensure that the external Lustre and Spectrum Scale (GPFS) filesystems are available before starting to boot the compute nodes and UANs.

To power on and boot compute nodes and UANs, refer to [Power On and Boot Compute and User Access Nodes](Power_On_and_Boot_Compute_Nodes_and_User_Access_Nodes.md).

## Run system health checks

After power on, refer to [Validate CSM Health](../validate_csm_health.md) to check system health and status.

## Make nodes available to users

Make nodes available to users once system health and any other post-system maintenance checks have completed.
