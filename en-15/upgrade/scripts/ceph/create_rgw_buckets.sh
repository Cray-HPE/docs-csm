#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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

function ssh_keygen_keyscan() {
  local target_ncn ncn_ip known_hosts
  known_hosts="/root/.ssh/known_hosts"
  sed -i 's@pdsh.*@@' $known_hosts
  target_ncn="$1"
  ncn_ip=$(host ${target_ncn} | awk '{ print $NF }')
  [ -n "${ncn_ip}" ]
  # Because we may be called without set -e, we should check return codes after running commands
  [ $? -ne 0 ] && return 1
  echo "${target_ncn} IP address is ${ncn_ip}"
  ssh-keygen -R "${target_ncn}" -f "${known_hosts}"
  [ $? -ne 0 ] && return 1
  ssh-keygen -R "${ncn_ip}" -f "${known_hosts}"
  [ $? -ne 0 ] && return 1
  ssh-keyscan -H "${target_ncn},${ncn_ip}" >> "${known_hosts}"
  return $?
}

#shellcheck disable=SC2046
num_storage_nodes=$(printf "%03d" $(craysys metadata get num_storage_nodes))
truncate /root/.ssh/known_hosts --size=0

for node_num in $(seq 1 "$num_storage_nodes"); do
  nodename=$(printf "ncn-s%03d" "$node_num")
  ssh_keygen_keyscan "${nodename}"
  nodename=$(printf "ncn-s%03d.nmn" "$node_num")
  ssh_keygen_keyscan "${nodename}"
done

sed -i "s/LASTNODE/$num_storage_nodes/g" /etc/ansible/hosts
mkdir -p /etc/ansible/ceph-rgw-users/group_vars
cp /tmp/csm-1.5-new-buckets.yml /etc/ansible/ceph-rgw-users/group_vars/all.yml

# Adding conditional wait for k8s credentials.
# Will exit with error if they do not show up within 2 mins.

COUNTER=0
while [[ ! -f /etc/kubernetes/admin.conf ]]; do
  sleep 5
  let COUNTER=COUNTER+1
  if [[ $COUNTER -gt 24 ]]; then
    exit 1
  fi
done

source /etc/ansible/boto3_ansible/bin/activate

playbook=/etc/ansible/ceph-rgw-users/ceph-rgw-users.yaml
cat > $playbook << EOF
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
rm /etc/ansible/ceph-rgw-users/group_vars/all.yml
deactivate
