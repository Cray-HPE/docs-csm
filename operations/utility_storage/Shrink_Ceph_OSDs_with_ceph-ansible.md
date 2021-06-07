## Shrink Ceph OSDs with `ceph-ansible`

This procedure describes how to remove an OSD\(s\) from a Ceph cluster with `ceph-ansible`. It is helpful for reducing the size of a cluster or replacing hardware.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Log in as `root` on `ncn-m001`.

2.  Monitor the progress of the OSDs that have been added.

    ```bash
    ncn-m001# ceph -s
    ```

3.  View the status of each OSD and see where they reside.

    ```bash
    ncn-m001# ceph osd tree
    ```

4.  Change to the /opt/cray/ceph-ansible directory.

    ```bash
    ncn-m001# cd /opt/cray/ceph-ansible
    ```

5.  Copy the shrink-osd.yml file.

    ```bash
    ncn-m001# cp infrastructure-playbooks/shrink-osd.yml .
    ```

6.  Remove the desired OSDs.

    The OSD\_NUMBER\_LIST value in the command below should be replaced with a comma separated list of OSD numbers.

    ```bash
    ncn-m001# ansible-playbook shrink-osd.yml \
    -e OSD_NUMBER_LIST -e ireallymeanit=yes
    ```

    Watch that the OSDs disappear from the ceph osd tree. They will also decrease in the ceph -s command output.

7.  Remove references to the OSDs on their respective storage nodes.

    ```bash
    ncn-s001# rm -rf /var/lib/ceph/osd/ceph-OSD.NUM_REMOVED
    ```



