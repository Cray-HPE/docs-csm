# Kubernetes Encryption

Beginning in CSM 1.3, support is enabled for data encryption in `etcd` for Kubernetes secrets at rest.

This controller is deployed by default in CSM with the `cray-kubernetes-encryption` Helm chart.

By default encryption is not enabled and must be enabled after install.

## Table of contents

* [Implementation Details](#implementation-details)
* [Enabling Encryption](#enabling-encrypion)
* [Disabling Encryption](#disabling-encryption)
* [Encryption Status](#encryption-status)
* [Force Rewrite](#force-rewrite)

## Implementation Details

In order to better understand current limitations to the implementation, it is important to understand how encryption is enabled.

There are two aspects to encryption. The aforementioned `cray-kubernetes-encryption` helm chart, which runs within Kubernetes and determines when existing secret data can be rewritten. The second aspect is control plane configuration of the `kubeapi` process.

For Control Plane nodes encryption configuration is written to `/etc/cray/kubernetes/encryption` and `kubeapi` containers are restarted.

For Kubernetes secret encryption, once all control plane nodes agree on encryption ciphers and their keys, `cray-kubernetes-encryption` will rewrite all secret data.

For further information refer to the [official Kubernetes docs](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/).

## Enabling Encryption

To enable encryption you will need to provide and retain a 16, 24, or 32 byte string. It is important you do not lose this key as once secrets are encrypted in `etcd` Kubernetes needs to be configured with this secret before it can start.

Note that all control plane nodes must be updated. Also note that once a node is updated any new secret data writes performed by `kubeapi` for that node will be encrypted. All control plane nodes should be updated as soon as possible to each other.

There are two allowed encryption methods for encryption that may be chosen, `aescbc` and `aesgcm`.

Both ciphers allow same input string type. Note that while you may specify multiple encryption keys, only the first key will be used for encryption of any newly written Kubernetes secret.

A warning on the `encryption.sh` script. To ensure that you do not leave an entry in `.bash_history`, always run `encryption.sh` with a leading space so `bash` does not record the command in the `.bash_history` file.

* (`ncn-m#`) The following command can be used to enable encryption on all control-plane nodes:

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/encryption.sh --enable --aescbc KEYVALUE
    ```

    Example output:

    ```text
    encryption configuration updated
    ```

## Disabling Encryption

Safely disabling encryption requires two steps to ensure no access to Kubernetes secret data is lost.

The first step is to disable encryption but retain the existing encryption key. This ensures if a node is rebooted, or Kubernetes restarted, that Kubernetes can still read existing encrypted secret data.

* (`ncn-m#`) The following command can be used to disable encryption on all control-plane nodes:

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/encryption.sh --disable --aescbc KEYVALUE
    ```

    Example output:

    ```text
    encryption configuration updated
    ```

Once you see that the `current` encryption is `identity` you may then fully remove all keys from the control plane nodes.

* (`ncn-m#`) The following command can be used to fully disable all encryption:

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/encryption.sh --disable
    ```

    Example output:

    ```text
    encryption configuration updated
    ```

With this final encryption run encryption of etcd secrets will be as default.

## Encryption Status

Encryption status is recorded in a Kubernetes secret `cray-k8s-encryption` via annotations.

* (`ncn-mw#`) The following command can be used to get the status of encryption:

    ```bash
    kubectl get secret cray-k8s-encryption -o json -n kube-system | jq ".metadata.annotations | {changed, current, goal}"
    ```

    Example output:

    ```text
    {
      "changed": "1970-01-01 12:00:00+0000",
      "current": "identity",
      "goal": "identity"
    }
    ```

From this we see the last time any change was performed, the goal encryption name, and the current encryption name.

This example is similar to what you would see on a new or upgraded installation with the default of no encryption. The string `identity` indicates that we are using the identity encryption provider. This provider performs no encryption.

* (`ncn-mw#`) Command output when enabling encryption but secrets are not yet rewritten:

    ```bash
    kubectl get secret cray-k8s-encryption -o json -n kube-system | jq ".metadata.annotations | {changed, current, goal}"
    ```

    Example output:

    ```text
    {
      "changed": "1970-01-01 12:00:00+0000",
      "current": "identity",
      "goal": "aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907"
    }
    ```

From this example we can see that the goal is an `aescbc` cipher.

The `goal` string corresponds to the name in the `/etc/cray/kubernetes/encryption/current.yaml` file on all control plane nodes after the `encryption.sh` script is ran.
We will only see a goal that all control plane nodes agree on.

* (`ncn-mw#`) Command output after secrets are rewritten:

    ```bash
    kubectl get secret cray-k8s-encryption -o json -n kube-system | jq ".metadata.annotations | {changed, current, goal}"
    ```

    Example output:

    ```text
    {
      "changed": "1970-01-01 12:00:00+0000",
      "current": "aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907",
      "goal": "aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907"
    }
    ```

From this example we can see that the `current` key and `goal` keys are in agreement. This indicates all secret data in etcd is now encrypted with this key providers name.

## Forcing Encryption

If for any reason you wish to force a rewrite of secret data, you may do so by overwriting the annotation used by `cray-k8s-encryption`

* (`ncn-mw#`) Force a rewrite of existing data:

    ```bash
    kubectl annotate secret --namespace kube-system cray-k8s-encryption current=rewrite --overwrite
    ```

    This command gives no output on succes.
