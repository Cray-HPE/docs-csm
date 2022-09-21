# Kubernetes Encryption

Beginning in CSM 1.3, support is enabled for data encryption in `etcd` for Kubernetes secrets at rest.

This controller is deployed by default in CSM with the `cray-kubernetes-encryption` Helm chart.

By default, encryption is not enabled and must be enabled after install.

## Table of contents

* [Implementation details](#implementation-details)
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

## Enabling encryption

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
    encryption configuration updated
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
    encryption configuration updated
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
        encryption configuration updated
        ```

        At this point, encryption of `etcd` secrets will be back to default.

## Encryption status

Encryption status is recorded in a Kubernetes secret `cray-k8s-encryption` via annotations.

* (`ncn-mw#`) The following command reports the encryption status.

    ```bash
    kubectl get secret cray-k8s-encryption -o json -n kube-system | jq ".metadata.annotations | {changed, current, goal}"
    ```

    The command output will show the last time any change was performed, the goal encryption name, and the current encryption name.

* Example output on a new or upgraded installation with the default of no encryption.

    ```json
    {
      "changed": "1970-01-01 12:00:00+0000",
      "current": "identity",
      "goal": "identity"
    }
    ```

    The string `identity` indicates that the identity encryption provider is in use. This provider performs no encryption.

* Example command output when enabling encryption but secrets are not yet rewritten.

    ```json
    {
      "changed": "1970-01-01 12:00:00+0000",
      "current": "identity",
      "goal": "aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907"
    }
    ```

    The goal is an `aescbc` cipher. The `goal` string corresponds to the name in the
    `/etc/cray/kubernetes/encryption/current.yaml` file on all control plane nodes after the `encryption.sh` script has
    been run. Only a goal that all control plane nodes agree on will be reported.

* Example command output after secrets are rewritten.

    ```json
    {
      "changed": "1970-01-01 12:00:00+0000",
      "current": "aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907",
      "goal": "aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907"
    }
    ```

    The output shows that the `current` key and `goal` keys are in agreement. This indicates that all secret data in `etcd`
    is now encrypted with this key provider's name.

## Forcing encryption

If necessary, a forced rewrite of secret data can be done by overwriting the annotation used by `cray-k8s-encryption`.

* (`ncn-mw#`) Force a rewrite of existing data:

    ```bash
    kubectl annotate secret --namespace kube-system cray-k8s-encryption current=rewrite --overwrite
    ```

    This command gives no output on success.
