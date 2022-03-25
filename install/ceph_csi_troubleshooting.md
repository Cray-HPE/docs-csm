# Ceph CSI Troubleshooting

If there has been a failure to initialize all Ceph CSI components on `ncn-s001`, then the storage node
`cloud-init` may need to be rerun.

### Topics:
   1. [Verify Ceph CSI](#verify_ceph_csi)
   1. [Rerun Storage Node cloud-init](#rerun_storage_node_cloud-init)

## Details

<a name="verify_ceph_csi"></a>
### 1. Verify Ceph CSI

Verify that the ceph-csi requirements are in place.

   1. Log in to `ncn-s001` and run the following command.

      ```bash
      ncn-s001# ceph -s
      ```
      If it returns a connection error, then assume Ceph is not installed. See [Rerun Storage Node `cloud-init`](#rerun_storage_node_cloud-init).
   
   1. Verify all post-Ceph-install tasks have run.

      Log in to `ncn-s001` and check `/etc/cray/ceph` for completed task files `ceph_k8s_initialized` and `csi_initialized`.

      ```bash
      ncn-s001# ls /etc/cray/ceph/
      ceph_k8s_initialized  csi_initialized  installed  kubernetes_nodes.txt  tuned
      ```

      Check your results against this example.

      If any components are missing, see [Rerun Storage Node `cloud-init`](#rerun_storage_node_cloud-init).

   1. Check to see if ceph-csi prerequisites have been created in Kubernetes.

      These commands can be run from any master node, any worker node, or `ncn-s001`.

      ```bash
      ncn# kubectl get cm
      NAME               DATA   AGE
      ceph-csi-config    1      3h50m
      cephfs-csi-sc      1      3h50m
      kube-csi-sc        1      3h50m
      sma-csi-sc         1      3h50m
      sts-rados-config   1      4h

      ncn# kubectl get secrets | grep csi
      csi-cephfs-secret             Opaque                                4      3h51m
      csi-kube-secret               Opaque                                2      3h51m
      csi-sma-secret                Opaque                                2      3h51m
      ```

      Check your results against the above examples.

      If any components are missing, see [Rerun Storage Node `cloud-init`](#rerun_storage_node_cloud-init).

<a name="rerun_storage_node_cloud-init"></a>
### 1. Rerun Storage Node `cloud-init`

   This procedure will restart the storage node `cloud-init` process to prepare Ceph for use by the utility storage nodes.

   1. Run the following on `ncn-s001`:

       ```bash
       ncn-s001# ls /etc/cray/ceph
       ```
       If any files are there they will represent completed stages.

   1. If you have a running cluster, edit `storage-ceph-cloudinit.sh` on `ncn-s001`:

       ```bash
       ncn-s001# vi /srv/cray/scripts/common/storage-ceph-cloudinit.sh
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

   1. Run the `storage-ceph-cloudinit.sh` script on `ncn-s001`:

       ```bash
       ncn-s001# /srv/cray/scripts/common/storage-ceph-cloudinit.sh
       Configuring node auditing software
       Using generic auditing configuration
       This ceph cluster has been initialized
       This ceph cluster has already been tuned
       This ceph radosgw config and initial k8s integration already complete
       ceph-csi configuration has been already been completed
       ```

       * If your output is like above, then that means that all the steps ran.
           - You can also locate the files in `/etc/cray/ceph` that are created as each step completes.
       * If the script failed, then examine the output for indications of what may be causing the problem.
