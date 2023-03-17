# Determine if Pods are Hitting Resource Limits

Determine if a pod is being CPU throttled or hitting its memory limits (`OOMKilled`).
Use the `/opt/cray/platform-utils/detect_cpu_throttling.sh` script to determine if any pods are being CPU throttled, and check the Kubernetes events to see if any pods are hitting a memory limit.

**IMPORTANT:** The presence of CPU throttling does not always indicate a problem, but if a service is being slow or experiencing latency issues,
this procedure can be used to evaluate if it is not performing well as a result of CPU throttling.

Identify pods that are hitting resource limits in order to increase the resource limits for those pods.

## Prerequisites

`kubectl` is installed.

## Procedure

1. Use the `/opt/cray/platform-utils/detect_cpu_throttling.sh` script to determine if any pods are being CPU throttled _(this script is installed on master and worker NCNs)_. The script can be used in two different ways:

    1. (`ncn-mw#`) Pass in a substring of the desired pod names.

       In this example, the `externaldns` pods are being used:

       ```bash
       /opt/cray/platform-utils/detect_cpu_throttling.sh externaldns
       ```

       Example output:

       ```text
       Checking cray-externaldns-external-dns-6988c5d5c5-795lb
       *** CPU throttling for containerid 76f45c4c18bf8ee6d4f777a602430e021c2a0d0e024380d22341414ca25ccffd: ***
       nr_periods 6066669
       nr_throttled 23725
       throttled_time 61981768066252
       ```

    1. (`ncn-mw#`) Call the script without a parameter to evaluate all pods.

       This can take two minutes or more to run when evaluating all pods:

       ```bash
       /opt/cray/platform-utils/detect_cpu_throttling.sh
       ```

       Example output:

       ```text
       Checking cray-ceph-csi-cephfs-nodeplugin-zqqvv

       Checking cray-ceph-csi-cephfs-provisioner-6458879894-cbhlx

       Checking cray-ceph-csi-cephfs-provisioner-6458879894-wlg86

       Checking cray-ceph-csi-cephfs-provisioner-6458879894-z85vj

       Checking cray-ceph-csi-rbd-nodeplugin-62478
       *** CPU throttling for containerid 0f52122395dcf209d851eed7a1125b5af8a7a6ea1d8500287cbddc0335e434a0: ***
       nr_periods 14338
       nr_throttled 2
       throttled_time 590491866

       [...]
       ```

    1. Interpret the script results.

       * `nr_periods`: How many full periods have been elapsed.
       * `nr_throttled`: The number of times the full allowed bandwidth was exhausted.
       * `throttled_time`: The total time the tasks were not run because of being over quota.
       * See [cgroup documentation](https://kernel.googlesource.com/pub/scm/linux/kernel/git/glommer/memcg/+/cpu_stat/Documentation/cgroups/cpu.txt) for more details.

1. Check if a pod was killed/restarted because it reached its memory limit.

    1. (`ncn-mw#`) Look for a Kubernetes event associated with the pod being killed/restarted.

       ```bash
       kubectl get events -A | grep -C3 OOM
       ```

       Example output:

       ```text
       default   54m    Warning   OOMKilling  node/ncn-w003  Memory cgroup out of memory: Kill process 1223856 (prometheus) score 1966 or sacrifice child
       default   44m    Warning   OOMKilling  node/ncn-w003  Memory cgroup out of memory: Kill process 1372634 (prometheus) score 1966 or sacrifice child
       ```

    1. (`ncn-mw#`) Determine which pod was killed using the output of the previous command.

       Search the pods in Kubernetes for the string returned in the previous step to find the exact pod name.
       Based on the previous example command output, `prometheus` is used in this example:

       ```bash
       kubectl get pod -A | grep prometheus
       ```

1. Increase the resource limits for the pods identified in this procedure.

    See [Increase Pod Resource Limits](Increase_Pod_Resource_Limits.md) for how to increase these limits.
