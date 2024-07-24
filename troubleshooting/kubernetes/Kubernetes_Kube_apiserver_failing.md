# Kubernetes `kube-apiserver` Failing

If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../../operations/kubernetes/encryption/README.md) and the encryption files have not been restored after a master node rebuild or upgrade,
then the `kube-apiserver` on that node will fail.
This document only outlines the fix if the `kube-apiserver` if it is failing due to Kubernetes encryption not being restored.

## Process

1. (`ncn-m001`) Check if Kubernetes encryption is enabled.

    1. Check if all master nodes have the same encryption files. It is possible that a master node that was upgraded or rebuilt does not have the encryption files that exist on the other nodes.

        ```bash
        pdsh -w ncn-m00[1-3] 'ls -lh /etc/cray/kubernetes/encryption'
        ```

        Expected output if encyrption is not enabled. The `current.yaml` file should be symbolically linked to the `default.yaml` file on all master nodes as seen below:

        ```bash
        ncn-m001:~ # pdsh -w ncn-m00[1-3] 'ls -lh /etc/cray/kubernetes/encryption'
        ncn-m002: Warning: Permanently added 'ncn-m002,10.252.1.11' (ECDSA) to the list of known hosts.
        ncn-m003: Warning: Permanently added 'ncn-m003,10.252.1.12' (ECDSA) to the list of known hosts.
        ncn-m001: Warning: Permanently added 'ncn-m001' (ECDSA) to the list of known hosts.
        ncn-m001: total 4.0K
        ncn-m001: lrwxrwxrwx 1 root root  44 Jul  6 21:01 current.yaml -> /etc/cray/kubernetes/encryption/default.yaml
        ncn-m001: -r-------- 1 root root 151 Jul  6 21:01 default.yaml
        ncn-m002: total 4.0K
        ncn-m002: lrwxrwxrwx 1 root root  44 Jul  6 19:33 current.yaml -> /etc/cray/kubernetes/encryption/default.yaml
        ncn-m002: -r-------- 1 root root 151 Jul  6 19:33 default.yaml
        ncn-m003: total 4.0K
        ncn-m003: lrwxrwxrwx 1 root root  44 Jul  6 19:34 current.yaml -> /etc/cray/kubernetes/encryption/default.yaml
        ncn-m003: -r-------- 1 root root 151 Jul  6 19:34 default.yaml
        ```

        Expected output if encryption is enabled but has not been restored on a single master node:

        ```bash
        ncn-m001:~ # pdsh -w ncn-m00[1-3] 'ls -lh /etc/cray/kubernetes/encryption'
        ncn-m001: Warning: Permanently added 'ncn-m001,10.252.1.10' (ECDSA) to the list of known hosts.
        ncn-m002: Warning: Permanently added 'ncn-m002' (ECDSA) to the list of known hosts.
        ncn-m002: total 8.0K
        ncn-m002: lrwxrwxrwx 1 root root  69 Jul 23 22:22 current.yaml -> d857284b70d5157900ee74db5c2ba802f05f7e0d066e91c83c8832d373dd271a.yaml
        ncn-m002: -rw------- 1 root root 334 Jul 23 22:21 d857284b70d5157900ee74db5c2ba802f05f7e0d066e91c83c8832d373dd271a.yaml
        ncn-m002: -r-------- 1 root root 151 Jul  6 19:33 default.yaml
        ncn-m001: total 4.0K
        ncn-m001: lrwxrwxrwx 1 root root  44 Jul  6 21:01 current.yaml -> /etc/cray/kubernetes/encryption/default.yaml
        ncn-m001: -r-------- 1 root root 151 Jul  6 21:01 default.yaml
        ncn-m003: total 8.0K
        ncn-m003: lrwxrwxrwx 1 root root  69 Jul 23 22:20 current.yaml -> d857284b70d5157900ee74db5c2ba802f05f7e0d066e91c83c8832d373dd271a.yaml
        ncn-m003: -rw------- 1 root root 334 Jul 23 22:19 d857284b70d5157900ee74db5c2ba802f05f7e0d066e91c83c8832d373dd271a.yaml
        ncn-m003: -r-------- 1 root root 151 Jul  6 19:34 default.yaml
        ```

    2. Check the status of Kubernetes encryption.

        ```bash
        /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --status
        ```

        Expected output if encyrption is not enabled:

        ```bash
        ncn-m001:~ # /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --status
        k8s encryption status
        changed: 2024-07-06 20:07:35+0000
        ncn-m001: identity
        ncn-m002: identity
        ncn-m003: dentity
        current: identity
        goal: identity
        etcd: identity
        ```

        Expected output if encryption is enabled but has not been restored on a single master node:

        ```bash
        ncn-m001:~ # /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --status
        k8s encryption status
        changed: 2024-07-06 20:07:35+0000
        ncn-m001: identity
        ncn-m002: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        ncn-m003: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        current: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        goal: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        etcd: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        interim state detected, ensure all control plane nodes are in sync
        ```

        Expected output if encryption is enabled on all master nodes:

        ```bash
        ncn-m001:~ # /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --status
        k8s encryption status
        changed: 2024-07-06 20:07:35+0000
        ncn-m001: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        ncn-m002: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        ncn-m003: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        current: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        goal: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        etcd: aescbc-625e61a4ebe4d3ddf8b5eec3b546663945b837d53ca966d72e49b42cdae4e656 identity
        ```

    If Kubernetes encryption is set up on the system and is enabled on all master nodes, then there is nothing more to do. Follow the next step if Kubernetes encryption is not correctly set up on a master node.

1. (`ncn-m001`) Set up Kubernetes encryption on the master node that does not have it enabled.

    1. Copy `/etc/cray/kubernetes/encryption` files to the master node without Kubernetes encryption enabled from another master node. Adjust the node names below based on which master node contains the correct files and which node is the target node.

        ```bash
        scp /etc/cray/kubernetes/encryption/* ncn-m001:/etc/cray/kubernetes/encryption/
        ```

    1. Restart `kube-apiserver` on the node where Kubernetes encryption is being enabled. This should be the same node that the `kube-apiserver` is failing on and why this troubleshooting document is being followed.

        Set the `failing_api_serv_node` to the node where the `kube-apiserver` is failing.

        ```bash
        failing_api_serv_node=ncn-m001
        ```

        Delete the failing `kube-apiserver` pod.

        ```bash
        kubectl delete pod -n kube-system kube-apiserver-${failing_api_serv_node}
        ```

1. (`ncn-m001`) Check that encryption is enabled on all master nodes. This may take 10 minutes to for the output to reflect an encryption change. Please see  the [Kubernetes Encryption Documentation](../../operations/kubernetes/encryption/README.md) for details.

    ```bash
    /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --status
    ```
