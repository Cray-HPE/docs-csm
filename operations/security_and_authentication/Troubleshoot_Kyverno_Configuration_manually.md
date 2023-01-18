# Troubleshoot Kyverno configuration manually

## Check Kyverno pods

(`ncn-mw#`) Run the following script to verify that the expected Kyverno pods are running:

```bash
/opt/cray/tests/install/livecd/scripts/k8s_kyverno_pods_running.sh -p
```

## Check Kyverno policy report

(`ncn-mw#`) Run the following script in order to check the Kyverno policy report for any failures, warnings, errors, and skipped policies:

```bash
/opt/cray/tests/install/livecd/scripts/k8s_kyverno_polr_list.sh -p
```

## More information

See [Kyverno](../kubernetes/Kyverno.md).
