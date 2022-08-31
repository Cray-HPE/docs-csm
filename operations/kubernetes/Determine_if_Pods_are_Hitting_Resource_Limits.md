# Determine if Pods are Hitting Resource Limits

Determine if a pod is being CPU throttled or hitting its memory limits (`OOMKilled`).
Use the `/opt/cray/platform-utils/detect_cpu_throttling.sh` script to determine if any pods are being CPU throttled, and check the Kubernetes events to see if any pods are hitting a memory limit.

**IMPORTANT:** The presence of CPU throttling does not always indicate a problem, but if a service is being slow or experiencing latency issues,
this procedure can be used to evaluate if it is not performing well as a result of CPU throttling.

Identify pods that are hitting resource limits in order to increase the resource limits for those pods.

## Prerequisites

`kubectl` is installed.

## Procedure

1. Use the `/opt/cray/platform-utils/detect_cpu_throttling.sh` script to determine if any pods are being CPU throttled _(this script is installed on master and worker NCNs)_.  The script can be used in two different ways:

    1. (`ncn-mw#`) Pass in a substring of the desired pod name(s).  In the example below, the `externaldns` pods are being used:

       ```bash
       /opt/cray/platform-utils/detect_cpu_throttling.sh externaldns
       ```

       Example output:

       ```text
       Checking cray-externaldns-coredns-58b5f8494-c45kh

       Checking cray-externaldns-coredns-58b5f8494-pjvz6

       Checking cray-externaldns-etcd-2kn7w6gnsx

       Checking cray-externaldns-etcd-88x4drpv27

       Checking cray-externaldns-etcd-sbnbph52vh

       Checking cray-externaldns-external-dns-5bb8765896-w87wb
       *** CPU throttling: ***
       nr_periods 1127304
       nr_throttled 473554
       throttled_time 71962850825439
       ```

    1. (`ncn-mw#`) Call the script without a parameter to evaluate all pods.  It can take two minutes or more to run when evaluating all pods:

       ```bash
       /opt/cray/platform-utils/detect_cpu_throttling.sh
       ```

       Example output:

       ```text
       Checking benji-k8s-fsfreeze-9zlfk

       Checking benji-k8s-fsfreeze-fgqmd

       Checking benji-k8s-fsfreeze-qgbcp

       Checking benji-k8s-maint-796b444bfc-qcrhx

       Checking benji-k8s-postgresql-0

       Checking benji-k8s-pushgateway-777fd86545-qrmbr

       [...]
       ```

    1. Interpreting script results (see [cgroup documentation](https://kernel.googlesource.com/pub/scm/linux/kernel/git/glommer/memcg/+/cpu_stat/Documentation/cgroups/cpu.txt) for more details):

       * `nr_periods`: How many full periods have been elapsed.
       * `nr_throttled`: The number of times we exausted the full allowed bandwidth.
       * `throttled_time`: The total time the tasks were not run due to being overquota.

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

    1. (`ncn-mw#`) Determine which pod was killed using the output above. Use `grep` on the string returned in the previous step to find the pod name. In this example, prometheus is used:

       ```bash
       kubectl get pod -A | grep prometheus
       ```

Follow the procedure to increase the resource limits for the pods identified in this procedure. See [Increase Pod Resource Limits](Increase_Pod_Resource_Limits.md) for how to increase these limits.
