#!/bin/bash

num_storage_nodes=$(printf "%03d" $(craysys metadata get num_storage_nodes))
sed -i "s/LASTNODE/$num_storage_nodes/g" /etc/ansible/hosts

source /etc/ansible/boto3_ansible/bin/activate

playbook=/etc/ansible/ceph-rgw-users/ceph-rgw-users.yaml
cat > $playbook <<EOF
#!/usr/bin/env ansible-playbook
---

- hosts: mons
  any_errors_fatal: false
  remote_user: root
  roles:
    - ceph-rgw-users
EOF

chmod 755 $playbook
/etc/ansible/ceph-rgw-users/ceph-rgw-users.yaml
deactivate
