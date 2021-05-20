# Initial Ceph Upgrade

These are steps specific to the initial upgrade of ceph from nautilus to octopus.

1. On the stable ncn (master node), start a separate terminal that will watch the status of the ceph cluster.

   ```bash
   ncn-m001# watch ceph -s

   Every 2.0s: ceph -s                                    ncn-m001: Mon Apr 12 21:09:51 2021

     cluster:
       id:     0534e7c4-dea8-49f2-9c56-cc5be5c9b9f7
       health: HEALTH_OK
       .
       .
   ```

2. Download and install the docs-csm-install RPM to each storage node. If this machine does not have direct internet access these RPMs will need to be externally downloaded and then copied to be installed.

   ```bash
   ncn-s001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm
   ```

3. Run the script that creates partitions for `/var/lib/ceph` and `/var/lib/containers` on each storage node (one at a time):

   ```bash
   ncn-s001# /usr/share/doc/csm/upgrade/1.0/scripts/ceph/ceph-partitions-stage1.sh
   ```

4. On `ncn-s001` execute the `ceph-upgrade.sh` script:

   ```bash
   ncn-s001 # cd /usr/share/doc/csm/upgrade/1.0/scripts/ceph
   ncn-s001 # ./ceph-upgrade.sh
   ```

5. Verify the health of the ceph cluster -- ensure it returns to `HEALTH_OK` before proceeding.  This should be evident from the terminal watching the health of the ceph cluster in step 1.

6. [Back to Main Page](../../README.md) to proceed with Stage 2
