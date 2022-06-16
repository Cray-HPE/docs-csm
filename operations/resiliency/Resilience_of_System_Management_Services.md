# Resilience of System Management Services

HPE Cray EX systems are designed so that system management services \(SMS\) are fully resilient and that there is no single point of failure. The design of the system allows for resiliency in the following ways:

* Three non-compute nodes \(NCNs\) are configured as Kubernetes master nodes. When one master goes down, operations \(such as jobs running across compute nodes\) are expected to continue.
* At least three utility storage nodes provide persistent storage for the services running on the Kubernetes management nodes. When one of the utility storage nodes goes down, operations \(such as jobs running across compute nodes\) are expected to continue.
* At least three NCNs are configured as Kubernetes worker nodes.
  If one of only three Kubernetes worker nodes were to go down, it would be much more difficult for the remaining two NCN worker nodes to handle the total balance of pods.
  It is less significant to lose one of the NCN worker nodes if the system has more than three NCN worker nodes because there are more worker nodes able to handle the pod load.
* The state and configuration of the Kubernetes cluster are stored in an etcd cluster distributed across the Kubernetes master nodes. This cluster is also backed up on an interval, and backups are pushed to Ceph Rados Gateway \(S3\).
* A micro-service can run on any node that meets the requirements for that micro-service, such as appropriate hardware attributes, which are indicated by labels and taints.
* All micro-services have shared persistent storage so that they can be restarted on any NCN in the Kubernetes management cluster without losing state.

Kubernetes is designed to ensure that the wanted number of deployments of a micro-service are always running on one or more worker nodes.
In addition, it ensures that if one worker node becomes unresponsive, the micro-services that were running on it are
migrated to another NCN that is up and meets the requirements of those micro-services.

See [Restore System Functionality if a Kubernetes Worker Node is Down](Restore_System_Functionality_if_a_Kubernetes_Worker_Node_is_Down.md) for more information.

## Resiliency Improvements

To increase the overall resiliency of system management services and software within the system, the following improvements were made:

* Capsules services have implemented replicas for added resiliency.
* Added support for new storage class that supports Read-Write-Many and in doing so, eliminated some of the errors
  we encountered on pods which could not seamlessly start up on other worker NCNs upon termination \(because of a PVC unmount error\).
* Modified procedures for reloading DVS on NCNs to reduce DVS service interruptions.
* DVS now retries DNS queries in `dvs_generate_map`, which improves boot resiliency at scale.
* Additional retries implemented in the BOA, IMS, and CFS services for increased protection around outages of dependent services.
* Image-based installs emphasizing "non-special" node types eliminated single points of failure previously encountered with DNS, administrative and installation tooling, and gathering of Cray System Management \(CSM\) logging for Ceph and Kubernetes.

## Expected Resiliency Behavior

In addition, the following general criteria describe the expected behavior of the system if a single Kubernetes node \(master, worker, or storage\) goes down temporarily:

* Once a job has been launched and is executing on the compute plane,
  it is expected that it will continue to run without interruption during planned or unplanned outages characterized by the loss of an NCN master, worker, or storage node.
  Applications launched through PALS may show error messages and lost output if a worker node goes down during application runtime.
* If an NCN worker node goes down, it will take between 4 and 5 minutes before most of the pods which had been running on the downed NCN will begin terminating. This is a predefined Kubernetes behavior, not something inherent to HPE Cray EX.
* Within around 20 minutes or less, it should be possible to launch a job using a UAI or UAN after planned or unplanned outages characterized by the loss of an NCN master, worker, or storage node.
  * In the case of a UAN, the recovery time is expected to be quicker.
    However, launching a UAI after an NCN outage means that some UAI pods may need to relocate to other NCN worker nodes.
    The status of those new UAI pods will remain unready until all necessary content has been loaded on the new NCN that the UAI is starting up on.
    This process can take approximately 10 minutes.
* Within around 20 minutes or less, it should be possible to boot and configure compute nodes
  after planned or unplanned outages characterized by the loss of an NCN master, worker, or storage node.

* At least three utility storage nodes provide persistent storage for the services running on the Kubernetes management nodes.
  When one of the utility storage nodes goes down, critical operations such as job launch, application run, or compute node boot are expected to continue to work.
* Not all pods running on a downed NCN worker node are expected to migrate to a remaining NCN worker node.
  There are some pods which are configured with anti-affinity such that if the pod exists on another NCN worker node, it will not start another of those pods on that same NCN worker node.
  At this time, this mostly only applies to etcd clusters running in the cluster.
  It is optimal to have those pods balanced across the NCN worker nodes \(and not have multiple etcd pods, from the same etcd cluster, running on the same NCN worker node\).
  Thus, when an NCN worker node goes down, the etcd pods running on it will remain in terminated state and will not attempt to relocate to another NCN worker node.
  This should be fine as there should be at least two other etcd pods \(from the cluster of 3\) running on other NCN worker nodes.
  Additionally, any pods that are part of a stateful set will not migrate off a worker node when it goes down.
  Those are expected to stay on the node and also remain in the terminated state until the NCN worker nodes comes back up
  or unless deliberate action is taken to force that pod off the NCN worker node which is down.
  * The `cps-cm-pm` pods are part of a daemonset and they only run on designated nodes. When the node comes back up the containers will be restarted and service restored.
    Refer to "Content Projection Service \(CPS\)" in the Cray Operating System \(COS\) product stream documentation for more information on changing node assignments.
* After an NCN worker, storage, or master node goes down, if there are issues with launching a UAI session or booting compute
  nodes, that does not necessarily mean that the problem is due to a worker node being down.
  If possible, it is advised to also check the relevant
  "Compute Node Boot Troubleshooting Information" and [User Access Service](../UAS_user_and_admin_topics/index.md)(specifically with respect to [Troubleshoot UAS Issues](../UAS_user_and_admin_topics/Troubleshoot_UAS_Issues.md)) procedures.
  Those sections can give guidance around general known issues and how to troubleshoot them.
  For any customer support ticket opened on these issues, however, it would be an important piece of
  data to include in that ticket if the issue was encountered while one or more of the NCNs were down.

## Known Issues and Workarounds

Though an effort was made to increase the number of pod replicas for services that were critical to system operations
such as booting computes, launching jobs, and running applications across the compute plane, there are still some services that remain with single copies of their pods.
In general, this does not result in a critical issue if these singleton pods are on an NCN worker node that goes down.
Most micro-services should \(after being terminated by Kubernetes\), simply be rescheduled onto a remaining NCN worker node.
That assumes that the remaining NCN worker nodes have sufficient resources available and meet the hardware/network requirements of the pods.

However, it is important to note that some pods, when running on a worker NCN that goes down, may require some manual intervention to be rescheduled.
Note the workarounds in this section for such pods. Work is ongoing to correct these issues in a future release.

* **Nexus pod**
  * The `nexus` pod is a single pod deployment and serves as our image repository.
    If it is on an NCN worker node that goes down, it will attempt to start up on another NCN worker node.
    However, it is likely that it can also encounter the `Multi-Attach error for volume` error that can be seen in the `kubectl describe` output for the pod that is trying to come up on the new node.
    1. To determine if this is happening, run the following:

        ```bash
        ncn# kubectl get pods -n nexus | grep nexus
        ```

    2. Describe the pod obtained in the previous step

        ```bash
        ncn# kubectl describe pod -n nexus NEXUS_FULL_POD_NAME
        ```

    3. If the event data at the bottom of the `kubectl describe` command output indicates that a Multi-Attach PVC error has occurred,
       then see the [Troubleshoot Pods Multi-Attach Error](../utility_storage/Troubleshoot_Pods_Multi-Attach_Error.md) procedure to unmount the PVC.
       This will allow the Nexus pod to begin successfully running on the new NCN worker node.

* **High-speed network resiliency after `ncn-w001` goes down**
  * The `slingshot-fabric-manager` pod running on one of NCNs does not rely on `ncn-w001`. If `ncn-w001` goes down, the `slingshot-fabric-manager` pods should not be impacted as the pod is runs on other NCNs, such as `ncn-w002`.
  * The `slingshot-fabric-manager` pod relies on Kubernetes to launch the new pod on another NCN if the `slingshot-fabric-manager` pod is running on `ncn-w001` when it is brought down.

    Use the following command and check the `NODE` column to check which NCN the pod is running on:

    ```bash
    ncn# kubectl get pod -n services -o wide | awk 'NR == 1 || /slingshot-fabric-manager/'
    ```

    * When the `slingshot-fabric-manager` pod goes down, the switches will continue to run.
      Even if the status of the switches changes, those changes will be picked up after the `slingshot-fabric-manager` pod is brought back up and the sweeping process restarts.
    * The `slingshot-fabric-manager` relies on data in persistent storage. The data is persistent across upgrades but when the pods are deleted, the data is also deleted.

## Future Resiliency Improvements

In a future release, strides will be made to further improve the resiliency of the system.
These improvements may include one or more of the following:

* Further emphasis on eliminating singleton system management pods.
* Reduce time delays for individual service responsiveness after its pods are terminated because of it running on a worker node that has gone down.
* Rebalancing of pods/workloads after an NCN worker node comes back up after being down.
* Analysis/improvements with respect to outages of the Node Management Network \(NMN\) and the impact to critical system management services.
* Expanded analysis/improvements of resiliency of noncritical services \(those that are not directly related to job launch, application run, or compute boot\).
