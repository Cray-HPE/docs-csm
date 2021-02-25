## CEPH CSI


### Verification Check

Verify that the ceph-csi requirements are in place

1. Verify all post ceph install tasks have run
2. Log into any storage node.
3. Check /etc/cray/ceph for completed task files
    ```bash
    ncn-s001:~ # ls /etc/cray/ceph/
    ceph_k8s_initialized  csi_initialized  installed  kubernetes_nodes.txt  tuned
    ```
4. Check to see if k8s ceph-csi prerequisites have been created
   > You can also run this from any k8s-manager/k8s-worker node
      ```bash
      pit:~ # kubectl get cm
      NAME               DATA   AGE
      ceph-csi-config    1      3h50m
      cephfs-csi-sc      1      3h50m
      kube-csi-sc        1      3h50m
      sma-csi-sc         1      3h50m
      sts-rados-config   1      4h

      pit:~ # kubectl get secrets |grep csi
      csi-cephfs-secret             Opaque                                4      3h51m
      csi-kube-secret               Opaque                                2      3h51m
      csi-sma-secret                Opaque                                2      3h51m
      ```

5. check your results against the above example.
6. if you are missing any components then you will want to re-run the storage node cloud-init script
   * log in to ncn-s001
   * ceph -s
       * if it returns a connection error then assume ceph is not installed and you can re-run the cloud-init script
   * ls /etc/cray/ceph
       * if any files are there they will represent completed stages
       * if you have a running cluster you will want to edit the following file and comment out the section shown
            ```bash
            ncn-s001# vi /srv/cray/scripts/common/storage-ceph-cloudinit.sh
            Comment out
            #if [ -f "$ceph_installed_file" ]; then
            #  echo "This ceph cluster has been initialized"
            #else
            #  echo "Installing ceph"
            #  init
            #  mark_initialized $ceph_installed_file
            #fi
            ```
   * run the storage-ceph-cloudinit.sh script
       ```bash
   ncn-s001:~ # /srv/cray/scripts/common/storage-ceph-cloudinit.sh
   Configuring node auditing software
   Using generic auditing configuration
   This ceph cluster has been initialized
   This ceph cluster has already been tuned
   This ceph radosgw config and initial k8s integration already complete
   ceph-csi configuration has been already been completed
       ```
    * if your output is like above then that means that all the steps ran.
      - You can also locate file in /etc/cray/ceph that are create as each step completes
    * if the script failed out then you will have more output for the tasks that are being run. 
