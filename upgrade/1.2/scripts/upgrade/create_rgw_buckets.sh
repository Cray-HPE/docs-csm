#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

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
