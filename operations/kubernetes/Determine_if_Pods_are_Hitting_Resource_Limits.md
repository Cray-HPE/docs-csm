# Determine if Pods are Hitting Resource Limits

Determine if a pod is being CPU throttled or hitting its memory limits \(`OOMKilled`\).
Use a script to determine if any pods are being CPU throttled, and check the Kubernetes events to see if any pods are hitting a memory limit.

**IMPORTANT:** The presence of CPU throttling does not always indicate a problem, but if a service is being slow or experiencing
latency issues, this procedure can be used to evaluate if it is not performing well as a result of CPU throttling.

Identify pods that are hitting resource limits in order to increase the resource limits for those pods.

1. Use a script to determine if any pods are being CPU throttled.

    1. Create the script file.

        The script can be used on any master or worker NCN that can SSH to worker nodes.
        Create the `detect_cpu_throttling.sh` script with the following contents:

        ```bash
        #!/bin/sh
        # Usage: detect_cpu_throttling.sh [pod_name_substr] (default evaluates all pods)

        str=$1
        : ${str:=.}

        while read ns pod node; do
          echo ""
          echo "Checking $pod"
          while read -r container; do
            uid=$(echo $container | awk 'BEGIN { FS = "/" } ; {print $NF}')
            ssh -T ${node} <<-EOF
                dir=$(find /sys/fs/cgroup/cpu,cpuacct/kubepods/burstable -name *${uid}* 2>/dev/null)
                [ "${dir}" = "" ] && { dir=$(find /sys/fs/cgroup/cpu,cpuacct/system.slice/containerd.service -name *${uid}* 2>/dev/null); }
                if [ "${dir}" != "" ]; then
                  num_periods=$(grep nr_throttled ${dir}/cpu.stat | awk '{print $NF}')
                  if [ ${num_periods} -gt 0 ]; then
                    echo "*** CPU throttling for containerid ${uid}: ***"
                    cat ${dir}/cpu.stat
                    echo ""
                  fi
                fi
            EOF
          done <<< "`kubectl -n $ns get pod $pod -o yaml | grep ' - containerID'`"
        done <<<"$(kubectl get pods -A -o wide | grep $str | grep Running | awk '{print $1 " " $2 " " $8}')"
        ```

    1. Use the script to determine if any pods are being CPU throttled. The script can be used in two different ways:

        - Pass in a substring of the desired pod names.

            In the example below, the `externaldns` pods are being used.

            ```bash
            ncn-mw# ./detect_cpu_throttling.sh externaldns
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

        - Call the script without a parameter to evaluate all pods.

            It can take two minutes or more to run when evaluating all pods:

            ```bash
            ncn-mw# ./detect_cpu_throttling.sh
            ```

            Example of first several lines of output:

            ```text
            Checking benji-k8s-fsfreeze-9zlfk

            Checking benji-k8s-fsfreeze-fgqmd

            Checking benji-k8s-fsfreeze-qgbcp

            Checking benji-k8s-maint-796b444bfc-qcrhx

            Checking benji-k8s-postgresql-0

            Checking benji-k8s-pushgateway-777fd86545-qrmbr
            ```

1. Check if a pod was killed or restarted because it reached its memory limit.

    1. Look for a Kubernetes event associated with the pod being killed/restarted.

        ```bash
        ncn-mw# kubectl get events -A | grep -C3 OOM
        ```

        Example output:

        ```text
        default   54m    Warning   OOMKilling  node/ncn-w003  Memory cgroup out of memory: Kill process 1223856 (prometheus) score 1966 or sacrifice child
        default   44m    Warning   OOMKilling  node/ncn-w003  Memory cgroup out of memory: Kill process 1372634 (prometheus) score 1966 or sacrifice child
        ```

    1. Determine which pod was killed using the output above.

        Use `grep` on the string returned in the previous step to find the pod name. In this example, `prometheus` is used.

        ```bash
        ncn-mw# kubectl get pod -A | grep prometheus
        ```

Increase the resource limits for the pods identified in this procedure. See [Increase Pod Resource Limits](Increase_Pod_Resource_Limits.md).
