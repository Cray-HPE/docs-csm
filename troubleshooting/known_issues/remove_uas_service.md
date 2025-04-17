# Remove User Access Service

## Description

The User Access Service for managing User Access Instances was removed in CSM 1.6.0 however it may still be running on systems upgraded from earlier CSM versions.

## Symptoms

* The `cray-uas-mgr` or `cray-uas-mgr-bitnami-etcd` Pods may be running.

  ```text
  services             cray-uas-mgr-bd5f6d568-7wqc2                                      2/2     Running            0               2d13h
  services             cray-uas-mgr-bd5f6d568-zhx7t                                      2/2     Running            0               2d13h
  services             cray-uas-mgr-bitnami-etcd-0                                       2/2     Running            0               2d13h
  services             cray-uas-mgr-bitnami-etcd-1                                       2/2     Running            0               2d14h
  services             cray-uas-mgr-bitnami-etcd-2                                       2/2     Running            0               2d13h
  services             cray-uas-mgr-bitnami-etcd-snapshotter-29081400-5hl7p              0/2     Completed          0               40m
  ```

## Solution

### Apply workaround

1. Verify the `cray-uas-mgr` and `update-uas` Helm charts are installed.

   ```bash
   helm -n services ls --filter uas
   ```

   Example output:

   ```text
   NAME            NAMESPACE    REVISION    UPDATED                                    STATUS      CHART                  APP VERSION
   cray-uas-mgr    services     7           2024-06-27 14:10:36.806234737 +0000 UTC    deployed    cray-uas-mgr-1.23.2    1.23.2
   update-uas      services     7           2024-06-27 14:14:23.862427488 +0000 UTC    deployed    update-uas-1.8.1       1.8.1
   ```

2. Remove the `cray-uas-mgr` and `update-uas` Helm charts.

   ```bash
   helm -n services uninstall cray-uas-mgr update-uas
   ```

   Example output:

   ```text
   W0417 12:02:51.478703 3190378 warnings.go:70] policy/v1beta1 PodSecurityPolicy is deprecated in v1.21+, unavailable in v1.25+
   release "cray-uas-mgr" uninstalled
   release "update-uas" uninstalled
   ```

   The `cray-uas-mgr` and `cray-uas-mgr-bitnami-etcd` Pods should no longer be running.
