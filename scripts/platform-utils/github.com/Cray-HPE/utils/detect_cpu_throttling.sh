#!/bin/sh
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
# Usage: detect_cpu_throttling.sh [pod_name_substr] (default evaluates all pods)
#

str=$1
: ${str:=.}

while read ns pod node; do
  echo ""
  echo "Checking $pod"
  while read -r container; do
    uid=$(echo $container | awk 'BEGIN { FS = "/" } ; {print $NF}')
    ssh -T ${node} <<-EOF
        dir=\$(find /sys/fs/cgroup/cpu,cpuacct/kubepods/burstable -name \*${uid}\* 2>/dev/null)
        [ "\${dir}" = "" ] && { dir=\$(find /sys/fs/cgroup/cpu,cpuacct/system.slice/containerd.service -name \*${uid}\* 2>/dev/null); }
        if [ "\${dir}" != "" ]; then
          num_periods=\$(grep nr_throttled \${dir}/cpu.stat | awk '{print \$NF}')
          if [ \${num_periods} -gt 0 ]; then
            echo "*** CPU throttling for containerid ${uid}: ***"
            cat \${dir}/cpu.stat
            echo ""
          fi
        fi
	EOF
  done <<< "`kubectl -n $ns get pod $pod -o yaml | grep ' - containerID'`"
done <<<"$(kubectl get pods -A -o wide | grep $str | grep Running | awk '{print $1 " " $2 " " $8}')"
