# Kubernetes Encryption

Beginning in CSM 1.3, support is enabled for data encryption in `etcd` for Kubernetes secrets at rest.

This controller is deployed by default in CSM with the `cray-kubernetes-encryption` Helm chart.

By default, encryption is not enabled and must be enabled after install.

Note that control plane is used in this document elsewhere master or management nodes may be used. Control plane is used to be consistent with upstream Kubernetes documentation.

## Table of contents

* [Implementation details](#implementation-details)
* [Setup](#setup)
* [Enabling encryption](#enabling-encryption)
* [Disabling encryption](#disabling-encryption)
* [Encryption status](#encryption-status)
* [Force rewrite](#force-rewrite)

## Implementation details

In order to better understand current limitations to the implementation, it is important to understand how encryption is enabled.

There are two aspects to encryption. The first aspect is the aforementioned `cray-kubernetes-encryption` Helm chart, which runs within Kubernetes and determines
when existing secret data can be rewritten. The second aspect is control plane configuration of the `kubeapi` process.

For control plane nodes encryption, configuration is written to `/etc/cray/kubernetes/encryption` and `kubeapi` containers are restarted.

For Kubernetes secret encryption, once all control plane nodes agree on encryption ciphers and their keys, `cray-kubernetes-encryption` will rewrite all secret data.

For further information, refer to the [official Kubernetes documentation](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/).

## Setup

The `encryption.sh` command will need to be made available on all control plane nodes beyond `ncn-m002`.
Shown here for `ncn-m003`.

1. (`ncn-m003#`) Set the `ENCRYPTION_CMD_PATH` variable to `/usr/share/doc/csm/scripts/operations/kubernetes`.

    For example:

    ```bash
    ENCRYPTION_CMD_PATH=/usr/share/doc/csm/scripts/operations/kubernetes
    ```

1. (`ncn-m003#`) Copy the `encryption.sh` command from `ncn-m001`.

    ```bash
    mkdir -pv $ENCRYPTION_CMD_PATH
    scp -p ncn-m001:${ENCRYPTION_CMD_PATH}/encryption.sh $ENCRYPTION_CMD_PATH
    ls -l $ENCRYPTION_CMD_PATH
    ```

    Example output:

    ```text
    ncn-m003:~ # mkdir -pv $ENCRYPTION_CMD_PATH
    mkdir: created directory '/usr/share/doc/csm'
    mkdir: created directory '/usr/share/doc/csm/scripts'
    mkdir: created directory '/usr/share/doc/csm/scripts/operations'
    mkdir: created directory '/usr/share/doc/csm/scripts/operations/kubernetes'
    ncn-m003:~ # scp -p ncn-m001:${ENCRYPTION_CMD_PATH}/encryption.sh $ENCRYPTION_CMD_PATH
    encryption.sh
    ncn-m003:~ # ls -l $ENCRYPTION_CMD_PATH
    total 28
    -rwxr-xr-x 1 root root 27658 Oct 11 20:20 encryption.sh
    ncn-m003:~ #
    ```

## Enabling encryption

Before encryption is enabled, it is recommend that a Bare-Metal etcd backup is taken only if the etcd cluster is healthy.

See [Create a manual Backup of a Healthy Bare-Metal etcd Cluster](../Create_a_Manual_Backup_of_a_Healthy_Bare-Metal_etcd_Cluster.md) for details.

When enabling encryption it is important to ensure all control plane nodes are enabled in short order. However that does not mean all control plane nodes should run the script in parallel.

When encryption is enabled a Bare-Metal etcd cluster can not be restored from a backup taken before encryption is enabled. Such a backup can be used to restore etcd in the event that encryption is later fully disabled.

It is recommended to enable encryption on one node first. If successful may enable encryption in parallel on the remaining nodes.

In order to enable encryption, a 16, 24, or 32 byte string must be provided and retained. It is important not to lose this key, because once secrets
are encrypted in `etcd`, Kubernetes must be configured with this secret before it can start.

Note that all control plane nodes must be updated. Also note that once a node is updated, any new secret data writes performed by `kubeapi` for that node will be encrypted. All control plane nodes should be updated as close to the same time as possible.

There are two allowed encryption methods that may be chosen: `aescbc` and `aesgcm`.

Both ciphers allow the same input string type. Note that while it is possible to specify multiple encryption keys, only the first key will be used for encryption of any newly written Kubernetes secret.

* (`ncn-m#`) The `encryption.sh` script can be used to enable encryption on all control plane nodes.

    As shown in the following command example, always run `encryption.sh` with a leading space on the command line. This will cause Bash to not record the command in the `.bash_history` file.

    ```bash
     /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --enable --aescbc KEYVALUE
    ```

    Example output:

    ```text
    ncn-m001 configuration updated ensure all control plane nodes run this same command
    ```

## Disabling encryption

Safely disabling encryption requires two steps to ensure no access to Kubernetes secret data is lost:

1. (`ncn-m#`) Disable encryption but retain the existing encryption key.

    This ensures that if a node is rebooted, or if Kubernetes is restarted, then Kubernetes can still read
    existing encrypted secret data.

    The following command disables encryption on all control plane nodes.

    ```bash
     /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --disable --aescbc KEYVALUE
    ```

    Example output:

    ```text
    ncn-m001 configuration updated ensure all control plane nodes run this same command
    ```

1. Fully disable all encryption by removing all keys from the control plane nodes.

    1. Verify that the `current` encryption is reported as `identity`.

        See [Encryption status](#encryption-status) for details on how to check this.

    1. (`ncn-m#`) Fully disable all encryption.

        ```bash
         /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --disable
        ```

        Example output:

        ```text
        ncn-m001 configuration updated ensure all control plane nodes run this same command
        ```

        At this point, encryption of `etcd` secrets will be back to default.

## Encryption status

Encryption status is obtained through the `--status` switch of the `encryption.sh` command.

* (`ncn-m#`) The following command reports the encryption status.

    ```bash
    /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --status
    ```

    The return code of this command determines if encryption is applied or not. A non zero status simply indicates that a new cipher is to be applied.

* Example output on a new or upgraded installation with the default of no encryption. Note a return code of 0 indicates encryption is consistent across all nodes.

    ```text
    k8s encryption status
    changed: 1970-01-01 00:00:00+0000
    ncn-m001: identity
    ncn-m002: identity
    ncn-m003: identity
    current: identity
    goal: identity
    etcd: identity
    ```

    The string `identity` indicates that the identity encryption provider is in use. This provider performs no encryption and is the default.

* Example command output when enabling encryption but secrets are not yet rewritten. Note the return code for status is non zero in this case.

    ```text
    k8s encryption status
    changed: 1970-01-01 00:10:00+0000
    ncn-m001: aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 identity
    ncn-m002: aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 identity
    ncn-m003: aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 identity
    current: identity
    goal: aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907
    etcd: identity
    ```

    The goal is an `aescbc` cipher. The `goal` string corresponds to the name in the
    `/etc/cray/kubernetes/encryption/current.yaml` file on all control plane nodes after the `encryption.sh` script has
    been run. Only a goal that all control plane nodes agree on will be reported. The `etcd` string corresponds to the encryption names found in the etcd database itself.

* Example command output after secrets are rewritten. Note a return code of 0 indicates encryption is consistent across all nodes.

    ```text
    k8s encryption status
    changed: 1970-01-01 00:20:00+0000
    ncn-m001: aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 identity
    ncn-m002: aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 identity
    ncn-m003: aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 identity
    current: aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907
    goal: aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907
    etcd: aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907
    ```

    The output shows that the `current` key and `goal` keys are in agreement. This indicates that all secret data in `etcd`
    is now encrypted with this key provider's name. This indicates that all secret data in etcd is now encrypted with this key provider's name.

## Force rewrite

If necessary, a forced rewrite of secret data can be performed. Generally unnecessary but can be used to reduce the time for nodes to synchronize status.

* (`ncn-m#`) Force a rewrite of existing data:

    ```bash
    /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --restart
    ```

* Example output:

    ```text
    secret/cray-k8s-encryption annotated
    daemonset.apps/cray-k8s-encryption restarted
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 0 out of 3 new pods have been updated...
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 0 out of 3 new pods have been updated...
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 0 out of 3 new pods have been updated...
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 1 out of 3 new pods have been updated...
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 1 out of 3 new pods have been updated...
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 1 out of 3 new pods have been updated...
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 2 out of 3 new pods have been updated...
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 2 out of 3 new pods have been updated...
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 2 out of 3 new pods have been updated...
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 2 out of 3 new pods have been updated...
    Waiting for daemon set "cray-k8s-encryption" rollout to finish: 2 of 3 updated pods are available...
    daemon set "cray-k8s-encryption" successfully rolled out
    ```
