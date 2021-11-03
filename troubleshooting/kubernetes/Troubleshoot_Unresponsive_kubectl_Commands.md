## Troubleshoot Unresponsive kubectl Commands

Use this procedure to check if any kworkers are in an error state because of a high load. Once the error has been identified, workaround the issue by returning the high load to a normal level.

The `kubectl` command can become unresponsive because of a high load. Another symptom is that `ps aux` cannot return or complete because of aspects of the proc file system being locked.

If `kubectl` is non-responsive on `ncn-w001`, the commands can be run from any other master or worker non-compute node \(NCN\).


### Prerequisites

The `kubectl` command is not responsive on a node.


### Identify the kworker Issue

1.  Check to see if `kubectl` is not responding because of a kworker issue.

    1.  List the process identification \(pid\) numbers of the kworkers in the D state.

        Processes in the D state are blocked on I/O and are not an issue unless they remain blocked indefinitely. Use the command below to see which pids remain stuck in this state.

        ```bash
        ncn-w001# ps aux |grep [k]worker|grep -e " D"| awk '{ print $2 }'
        ```

    2.  Show the stack for all kworkers in the D state.

        Note which kworkers clear and which ones remain stuck in this state over a period of time.

        ```bash
        ncn-w001# for i in `ps aux | grep [k]worker | grep -e " D" |\
         awk '{print $2}'` ; do cat /proc/$i/stack; echo; done
        ```

2. Check to see what the load is on the worker node and gather data for any pids consuming a lot of CPU.

    1.  Monitor the processes and system resource usage.

        ```bash
        ncn-w001# top
        top - 10:12:03 up 34 days, 17:31, 10 users,  load average: 7.39, 9.16, 10.99
        Tasks: 2155 total,   4 running, 2141 sleeping,   1 stopped,   9 zombie
        %Cpu(s):  4.3 us,  2.5 sy,  0.0 ni, 93.0 id,  0.0 wa,  0.0 hi,  0.3 si,  0.0 st
        MiB Mem : 257510.5+total, 69119.86+free, 89578.68+used, 98812.04+buff/cache
        MiB Swap:    0.000 total,    0.000 free,    0.000 used. 173468.1+avail Mem

            PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
           6105 root      20   0  193436 182772   2300 S 60.00 0.069  13485:54 lldpad
          49574 root      20   0 14.299g 495212  60896 S 47.54 0.188  31582:58 kubelet
              1 root      20   0  231236  19436   6572 S 38.69 0.007  16904:47 systemd
          43098 root      20   0 16.148g 652640  78748 S 38.69 0.248  18721:18 containerd
          20229 root      20   0   78980  14648   6448 S 35.08 0.006  15421:51 systemd
        1515295 1001      20   0 16.079g 5.439g  96312 S 11.48 2.163  12480:39 java
           4706 message+  20   0   41060   5620   3724 S 8.852 0.002   3352:38 dbus-daemon
        1282935 101       20   0  685476  38556  13748 S 6.557 0.015 262:09.88 patroni
          81539 root      20   0  300276 161372  26036 S 5.902 0.061   4145:40 mixs
          89619 root      20   0 4731796 498600  24144 S 5.902 0.189   2898:54 envoy
          85600 root      20   0 2292564 123596  23248 S 4.590 0.047   2211:58 envoy

        ...
        ```

    2.  Generate a performance counter profile for the pids consuming a lot of CPU.

        Replace the PID value with the actual pid number.

        ```bash
        ncn-w001# perf top -g -p PID
        Samples: 18  of event 'cycles', Event count (approx.): 4065227
          Children      Self  Shared Object     Symbol
        +   29.31%     9.77%  [kernel]          [k] load_balance
        +   19.54%    19.54%  [kernel]          [k] find_busiest_group
        +   11.17%    11.17%  kubelet           [.] 0x0000000000038d3c
        +    9.77%     9.77%  [kernel]          [k] select_task_rq_fair
        +    9.77%     9.77%  [kernel]          [k] cpuacct_charge

        ...
        ```

    3.  Verify that `ps -ef` completes.

        ```bash
        ncn-w001# ps -ef
        ```

3.  Check the /var/log/messages on the worker node to see if there are any errors.

    ```bash
    ncn-w001# grep -i error /var/log/messages
    <nil>"
    2020-07-19T07:19:34.485659+00:00 ncn-w001 containerd[43098]: time="2020-07-19T07:19:34.485540765Z" level=info msg="Exec process \"9946991ef8108d21c163a04c9085fd15a60e3991b8e9d7b2250a071df9b6cbb8\" exits with exit code 0 and error
    <nil>"
    2020-07-19T07:19:38.468970+00:00 ncn-w001 containerd[43098]: time="2020-07-19T07:19:38.468818388Z" level=info msg="Exec process \"e6fe9ccbb1127a77f8c9db84b339dafe068f9e08579962f790ebf882ee35e071\" exits with exit code 0 and error
    <nil>"
    2020-07-19T07:19:44.440413+00:00 ncn-w001 containerd[43098]: time="2020-07-19T07:19:44.440243465Z" level=info msg="Exec process \"7a3cf826f008c37bd0fe89382561af42afe37ac4d52f37ce9312cc950248f4da\" exits with exit code 0 and error
    <nil>"
    2020-07-19T07:20:02.442421+00:00 ncn-w001 containerd[43098]: time="2020-07-19T07:20:02.442266943Z" level=error msg="StopPodSandbox for \"d449618d075b918fd6397572c79bd758087b31788dd8bf40f4dc10bb1a013a68\" failed" error="failed to destroy network for sandbox \"d449618d075b918fd6397572c79bd758087b31788dd8bf40f4dc10bb1a013a68\": Multus: Err in getting k8s network from pod: getPodNetworkAnnotation: failed to query the pod sma-monasca-agent-xkxnj in out of cluster comm: pods \"sma-monasca-agent-xkxnj\" not found"
    2020-07-19T07:20:04.440834+00:00 ncn-w001 containerd[43098]: time="2020-07-19T07:20:04.440742542Z" level=info msg="Exec process \"2a751ca1453d7888be88ab4010becbb0e75b7419d82e45ca63e55e4155110208\" exits with exit code 0 and error
    <nil>"
    2020-07-19T07:20:06.587325+00:00 ncn-w001 containerd[43098]: time="2020-07-19T07:20:06.587133372Z" level=error msg="collecting metrics for bf1d562e060ba56254f5f5ea4634ef4ae189abb462c875e322c3973b83c4c85d" error="ttrpc: closed: unknown"
    2020-07-19T07:20:14.450624+00:00 ncn-w001 containerd[43098]: time="2020-07-19T07:20:14.450547541Z" level=info msg="Exec process \"ceb384f1897d742134e7d2c9da5a62650ed1274f0ee4c5a17fa9cac1a24b6dc4\" exits with exit code 0 and error

    ...
    ```


### Recovery Steps

1.  Restart the kubelet.

    Run the following command on the node where kubectl in non-responsive.

    ```bash
    ncn-w001# systemctl restart kubelet
    ```

    If restarting the kubelet did not resolve the issue, proceed to the next step to restart the container runtime environment.

2.  Restart the container runtime environment on the node with the issue.

    This will likely hang or fail to complete without a timeout.

    ```bash
    ncn-w001# systemctl restart containerd
    ```

3.  Reboot the node.

    The node must be rebooted if the remediation of restarting kubelet and containerd did not resolve the kworker and high load average issue.

    **IMPORTANT:** If the node experiencing issues is `ncn-w001`, the ipmitool command must be run from another node that has access to the management plane. The admin will be cut off if using `ncn-w001` when powering off `ncn-w001-mgmt`.

    Replace NCN\_NAME in the commands below with the node experiencing the issue. In this example, it is `ncn-w999`.

    ```bash
    ncn-w001# export USERNAME=root
    ncn-w001# export IPMI_PASSWORD=changeme
    ncn-w001# export NCN_NAME=ncn-w999
    ncn-w001# ipmitool -U $USERNAME -E -I lanplus -H ${NCN_NAME}-mgmt power off; sleep 5;
    ncn-w001# ipmitool -U $USERNAME -E -I lanplus -H ${NCN_NAME}-mgmt power show; echo
    ncn-w001# ipmitool -U $USERNAME -E -I lanplus -H ${NCN_NAME}-mgmt power on; sleep 5;
    ncn-w001# ipmitool -U $USERNAME -E -I lanplus -H ${NCN_NAME} power show; echo
    ```

4.  Watch the console of the node being rebooted.

    This command will not return anything, but will show the ttyS0 console of the node. Use `~.` to disconnect. The same `~.` keystroke can also break an SSH session. After doing this, the connection to the SSH session may need to be reestablished.

    ```bash
    ncn-w001# ipmitool -U $USERNAME -E -I lanplus -H NCN_NAME-mgmt sol activate
    ```


Try running a `kubectl` command on the node where it was previously unresponsive.


