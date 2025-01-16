# Ceph OSD pool fails to create

## Description

Cloud-init on `ncn-s001` can partially fail if not enough OSDs are up when Ceph OSD pools are being created.
This problem has only been observed on CSM 1.6.0 and has been fixed in CSM 1.6.1.
If not enough OSDs are up when Ceph attempts to create pools, the `kube` and/or `smf` pool will not be created.
Additionally, the `csi-kube-secret` and/or the `csi-sma-secret` will not exist in the default namespace.

## Observed Error

(`ncn-s001#`) Look at `cloud-init-output.log` on `ncn-s001` and check if an Ansible task `Create Ceph OSD pool` failed when creating the `kube` and/or `smf` pool..

```bash
cat /var/log/cloud-init-output.log | grep -A 2 'Create Ceph OSD pool'
```

Expected output if the `smf` pool failed to be created:

```text
ncn-s001:~ # cat /var/log/cloud-init-output.log | grep -A 2 'Create Ceph OSD pool'
TASK [ceph-rbd : Create Ceph OSD pool] *****************************************
changed: [ncn-s001.nmn] => (item={'name': 'k8s-block-replicated', 'args': '64 64', 'user': 'k8s-block-replicated', 'secret': 'ceph-rbd-kube', 'storage_class': 'k8s-block-replicated', 'compression_algorithm': 'snappy', 'compression_mode': 'aggressive', 'compression_required_ratio': 0.7, 'namespace': 'k8s-block', 'pool_name': 'kube'})

--
TASK [ceph-rbd : Create Ceph OSD pool] *****************************************
failed: [ncn-s001.nmn] (item={'name': 'sma-block-replicated', 'args': '64 64', 'user': 'sma-block-replicated', 'secret': 'ceph-rbd-sma', 'storage_class': 'sma-block-replicated', 'compression_algorithm': 'snappy', 'compression_mode': 'aggressive', 'compression_required_ratio': 0.7, 'namespace': 'sma-block', 'pool_name': 'smf'}) => {"ansible_loop_var": "item", "changed": false, "cmd": ["ceph", "osd", "pool", "create", "smf", "64", "64"], "delta": "0:00:01.414139", "end": "2025-01-14 03:06:55.659707",
"item": {"args": "64 64", "compression_algorithm": "snappy", "compression_mode": "aggressive", "compression_required_ratio": 0.7, "name": "sma-block-replicated", "namespace": "sma-block", "pool_name": "smf", "secret": "ceph-rbd-sma", "storage_class": "sma-block-replicated", "user": "sma-block-replicated"}, "msg": "non-zero return code", "rc": 34, "start": "2025-01-14 03:06:54.245568",
"stderr": "Error ERANGE:  pg_num 64 size 3 for this pool would result in 288 cumulative PGs per OSD (1155 total PG replicas on 4 'in' root OSDs by crush rule) which exceeds the mon_max_pg_per_osd value of 250", "stderr_lines": ["Error ERANGE:  pg_num 64 size 3 for this pool would result in 288 cumulative PGs per OSD (1155 total PG replicas on 4 'in' root OSDs by crush rule) which exceeds the mon_max_pg_per_osd value of 250"], "stdout": "", "stdout_lines": []}
```

The above error would also cause the`csi-kube-secret` or `csi-sma-secret` secret to be missing from the default namespace and the `kube` and/or `smf` Ceph pools to not be created.

1. (`ncn-m001#`) Check if both `csi-kube-secret` and `csi-sma-secret` secrets exist in the default namespace.

    ```bash
    kubectl get secret -n default | grep 'csi-kube-secret\|csi-sma-secret'
    ```

1. (`ncn-m001#`) Check if the `kube` and/or `smf` pools exist in Ceph. List the Ceph pools in order to see if these pools exist.

    ```bash
    ceph osd pool ls
    ```

## Recovery Procedure

If `cloud-init-output.log` on `ncn-s001` shows that a `Create Ceph OSD pool` task failed, then follow the steps below.
All of the following steps should be run from `ncn-s001`.

1. (`ncn-s001#`) Execute the Ansible playbook to create OSD pools.

    ```bash
    . /etc/ansible/boto3_ansible/bin/activate
    ansible-playbook /etc/ansible/ceph-rgw-users/install.yml --start-at-task="Determine if running on cloud or metal"
    deactivate
    ```

1. (`ncn-s001#`) Execute steps to create necessary secrets and ConfigMaps.

    ```bash
    . /srv/cray/scripts/common/csi-configuration.sh

    echo "creating k8s storage class pre-reqs"
    create_k8s_ceph_secrets
    create_k8s_storage_class

    echo "creating sma storage class pre-reqs"
    create_sma_ceph_secrets
    create_sma_storage_class
    ```

## Verify new pools have been created and secrets exist

1. (`ncn-m001#`) Verify `kube` and `smf` pool exist.

    ```bash
    ceph osd pool ls | grep 'kube\|smf'
    ```

1. (`ncn-m001#`) Verify both `csi-kube-secret` and `csi-sma-secret` secrets exist in the default namespace.

    ```bash
    kubectl get secret -n default | grep 'csi-kube-secret\|csi-sma-secret'
    ```
