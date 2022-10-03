# Ceph CSI Troubleshooting

If there has been a failure to initialize all Ceph CSI components on `ncn-s001`, then the storage node
`cloud-init` may need to be rerun.

## Topics

1. [Verify Ceph CSI](#1-verify-ceph-csi)
1. [Rerun storage node `cloud-init`](#2-rerun-storage-node-cloud-init)

## 1. Verify Ceph CSI

Verify that the `ceph-csi` requirements are in place.

   1. (`ncn-s001#`) Log in to `ncn-s001` and run the following command.

      ```bash
      ceph -s
      ```

      If it returns a connection error, then assume Ceph is not installed. See [Rerun storage node `cloud-init`](#2-rerun-storage-node-cloud-init).

   1. (`ncn-s001#`) Verify all post-Ceph-install tasks have run.

      Log in to `ncn-s001` and check `/etc/cray/ceph` for completed task files `ceph_k8s_initialized` and `csi_initialized`.

      ```bash
      ls /etc/cray/ceph/
      ceph_k8s_initialized  csi_initialized  installed  kubernetes_nodes.txt  tuned
      ```

      Check the results against this example.

      If any components are missing, see [Rerun storage node `cloud-init`](#2-rerun-storage-node-cloud-init).

   1. (`ncn#`) Check to see if `ceph-csi` prerequisites have been created in Kubernetes.

      These commands can be run from any master node, any worker node, or `ncn-s001`.

      ```bash
      kubectl get cm
      NAME               DATA   AGE
      ceph-csi-config    1      3h50m
      cephfs-csi-sc      1      3h50m
      kube-csi-sc        1      3h50m
      sma-csi-sc         1      3h50m
      sts-rados-config   1      4h

      kubectl get secrets | grep csi
      csi-cephfs-secret             Opaque                                4      3h51m
      csi-kube-secret               Opaque                                2      3h51m
      csi-sma-secret                Opaque                                2      3h51m
      ```

      Check your results against the above examples.

      If any components are missing, see [Rerun storage node `cloud-init`](#2-rerun-storage-node-cloud-init).

## 2. Rerun storage node `cloud-init`

   This procedure will restart the storage node `cloud-init` process to prepare Ceph for use by the utility storage nodes.

   1. (`ncn-s001#`) Run the following on `ncn-s001`:

       ```bash
       ls /etc/cray/ceph
       ```

       If any files are there, they represent completed stages.

   1. (`ncn-s001#`) If there is a running cluster, then edit `storage-ceph-cloudinit.sh` on `ncn-s001`:

       ```bash
       vi /srv/cray/scripts/common/storage-ceph-cloudinit.sh
       ```

       Comment out this section:

       ```bash
       #if [ -f "$ceph_installed_file" ]; then
       #  echo "This ceph cluster has been initialized"
       #else
       #  echo "Installing ceph"
       #  init
       #  mark_initialized $ceph_installed_file
       #fi
       ```

   1. (`ncn-s001#`) Run the `storage-ceph-cloudinit.sh` script on `ncn-s001`:

       ```bash
       /srv/cray/scripts/common/storage-ceph-cloudinit.sh
       Configuring node auditing software
       Using generic auditing configuration
       This ceph cluster has been initialized
       This ceph cluster has already been tuned
       This ceph radosgw config and initial k8s integration already complete
       ceph-csi configuration has been already been completed
       ```

       - If the output is like above, then that means that all the steps ran.
         - Files in `/etc/cray/ceph` are created as each step completes and can be checked to confirm that the steps were run.
       - If the script failed, then examine the output for indications of what may be causing the problem.
