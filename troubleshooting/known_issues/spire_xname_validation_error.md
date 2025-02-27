# Enable Spire XName Validation Error

## Description

There is a known issue when the Spire servers are configured to use xname validation in CSM 1.6, where once validation is enabled, the `request-ncn-join` pods enter a crash loop.

There is a misconfiguration of the workloads configuration file that is used when xname validation is turned on. This leads to the Spire registration servers unable to give new
tokens to any workload attempting to join spire.

## Symptoms

* The `request-ncn-join` pods may be in a `Init:CrashLoopBackOff` state.
* Services may fail to acquire tokens from the `spire-server` or `cray-spire-server`.
* The `cray-spire-server` pods contain the following error in the registration server container logs.

  ```text
  2025/02/24 03:19:55 Error: Error Reading Workloads Configuration file, Detail: yaml: line 187: did not find expected '-' indicator
  ```

## Solution

### Apply workaround

1. (`ncn-mw#`) Delete the `cray-spire-workloads` config map.

  Command:

  ```bash
  kubectl delete cm -n spire cray-spire-workloads
  ```

  Output:

  ```bash
  configmap "cray-spire-workloads" deleted
  ```

1. (`ncn-mw#`) Apply a fixed `cray-spire-workloads` config map.

  Command:

  ```bash
  cat <<EOF | kubectl apply --server-side -f -
  apiVersion: v1
  data:
    compute.yaml: |-
      ---
      - spiffeID: spiffe://shasta/compute/XNAME/workload/cpsmount_helper
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cps-utils/bin/cpsmount_helper
      - spiffeID: spiffe://shasta/compute/XNAME/workload/cpsmount
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/cpsmount-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/orca
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/orca-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/ckdump_helper
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/ckdump_helper
      - spiffeID: spiffe://shasta/compute/XNAME/workload/ckdump
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/ckdump-spire-agent
        jwtSVIDTTL: 864000
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/bos-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/bos-reporter-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/cfs-state-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/cfs-state-reporter-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/dvs-map
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/dvs-map-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/dvs-hmi
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/dvs-hmi-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/wlm
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/wlm-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/cpsmount
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/cpsmount-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/cos-config-helper
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/cos-config-helper-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/orca
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/orca-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/ckdump_helper
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/ckdump_helper
      - spiffeID: spiffe://shasta/compute/XNAME/workload/ckdump
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/ckdump-spire-agent
        jwtSVIDTTL: 864000
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/bos-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/bos-reporter-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/cfs-state-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/cfs-state-reporter-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/dvs-map
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/dvs-map-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/dvs-mqtt
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/dvs-mqtt-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/dvs-hmi
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/dvs-hmi-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/wlm
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/wlm-spire-agent
      - spiffeID: spiffe://shasta/compute/XNAME/workload/tpm-provisioner
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/tpm-provisioner
    ncn.yaml: |-
      ---
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/cpsmount_helper
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cps-utils/bin/cpsmount_helper
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/cpsmount
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/cpsmount-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/orca
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/orca-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/ckdump
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/ckdump-spire-agent
        jwtSVIDTTL: 864000
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/bos-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/bos-reporter-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/cfs-state-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/cfs-state-reporter-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/dvs-map
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/dvs-map-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/dvs-hmi
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/dvs-hmi-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/ncn/workload/sbps-marshal
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/sbps-marshal-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/cpsmount
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/cpsmount-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/cos-config-helper
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/cos-config-helper-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/orca
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/orca-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/ckdump
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/ckdump-spire-agent
        jwtSVIDTTL: 864000
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/bos-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/bos-reporter-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/cfs-state-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/cfs-state-reporter-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/dvs-map
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/dvs-map-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/dvs-mqtt
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/dvs-mqtt-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/dvs-hmi
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/dvs-hmi-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/tpm-provisioner
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/tpm-provisioner
      - spiffeID: spiffe://shasta/ncn/workload/sbps-marshal
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/sbps-marshal-spire-agent
    storage.yaml: |-
      ---
      - spiffeID: spiffe://shasta/storage/XNAME/workload/cfs-state-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/cfs-state-reporter-spire-agent
      - spiffeID: spiffe://shasta/storage/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/storage/XNAME/workload/cfs-state-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/cfs-state-reporter-spire-agent
      - spiffeID: spiffe://shasta/storage/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/storage/XNAME/workload/tpm-provisioner
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/tpm-provisioner
    uan.yaml: |-
      ---
      - spiffeID: spiffe://shasta/uan/XNAME/workload/cpsmount_helper
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cps-utils/bin/cpsmount_helper
      - spiffeID: spiffe://shasta/uan/XNAME/workload/cpsmount
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/cpsmount-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/orca
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/orca-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/ckdump_helper
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/ckdump_helper
      - spiffeID: spiffe://shasta/uan/XNAME/workload/ckdump
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/ckdump-spire-agent
        jwtSVIDTTL: 864000
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/bos-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/bos-reporter-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/cfs-state-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/cfs-state-reporter-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/dvs-map
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/dvs-map-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/dvs-hmi
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/dvs-hmi-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/usr/bin/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/cpsmount
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/cpsmount-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/cos-config-helper
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/cos-config-helper-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/orca
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/orca-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/ckdump_helper
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/ckdump_helper
      - spiffeID: spiffe://shasta/uan/XNAME/workload/ckdump
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/ckdump-spire-agent
        jwtSVIDTTL: 864000
      - spiffeID: spiffe://shasta/ncn/XNAME/workload/bos-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/bos-reporter-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/cfs-state-reporter
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/cfs-state-reporter-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/dvs-map
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/dvs-map-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/dvs-mqtt
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/dvs-mqtt-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/dvs-hmi
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/dvs-hmi-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/heartbeat
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/heartbeat-spire-agent
      - spiffeID: spiffe://shasta/uan/XNAME/workload/tpm-provisioner
        selectors:
          - type: unix
            value: uid:0
          - type: unix
            value: gid:0
          - type: unix
            value: path:/opt/cray/cray-spire/tpm-provisioner
  kind: ConfigMap
  metadata:
    annotations:
      meta.helm.sh/release-name: cray-spire
      meta.helm.sh/release-namespace: spire
    labels:
      app.kubernetes.io/instance: cray-spire
      app.kubernetes.io/managed-by: Helm
      app.kubernetes.io/name: cray-spire
    name: cray-spire-workloads
    namespace: spire
  EOF
  ```

  Output:

  ```bash
  configmap/cray-spire-workloads serverside-applied
  ```
