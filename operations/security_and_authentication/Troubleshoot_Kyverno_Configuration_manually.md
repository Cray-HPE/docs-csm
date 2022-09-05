# How to troubleshoot Kyverno configuration manually:

## Check if Kyverno pods are up and running.

Test Case: k8s_kyverno_pods_running.sh
To run manually, the test case is executed with -p option.

```bash
./k8s_kyverno_pods_running.sh -p
```

This test case will list the expected Kyverno pods in running state.

## Check if Kyverno policy report doesn’t have Failures, Warnings, Errors and Skipped policies count.

Test Case: k8s_kyverno_polr_list.sh
To run  manually, the test case is executed with -p option.

```bash
./k8s_kyverno_polr_list.sh -p
```

This test case is used to check the Kyverno policy report for any Failures, Warnings, Errors and Skipped policies count.
