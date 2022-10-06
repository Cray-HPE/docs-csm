# How to troubleshoot Kyverno configuration manually

## Check if Kyverno pods are up and running

Run the script with -p option.

```bash
/opt/cray/tests/install/livecd/scripts/k8s_kyverno_pods_running.sh -p
```

This will list the expected Kyverno pods in running state.

## Check if Kyverno policy report doesn’t have Failures, Warnings, Errors and Skipped policies count

Run the script with -p option.

```bash
/opt/cray/tests/install/livecd/scripts/k8s_kyverno_polr_list.sh -p
```

This is used to check the Kyverno policy report for any Failures, Warnings, Errors and Skipped policies count.

### For more information check

* [Kyverno](../kubernetes/Kyverno.md)
