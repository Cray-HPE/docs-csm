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

echo "Reconfiguring apparmor for haproxy"
sed -i -e '/inet6/a\' -e '  /etc/ceph/rgw.pem r,' /etc/apparmor.d/usr.sbin.haproxy
systemctl enable apparmor.service
systemctl restart apparmor.service

echo "Reconfiguring haproxy"
/srv/cray/scripts/metal/generate_haproxy_cfg.sh > /etc/haproxy/haproxy.cfg
systemctl enable haproxy.service
systemctl restart haproxy.service

echo "Reconfiguring keepalived"
/srv/cray/scripts/metal/generate_keepalived_conf.sh > /etc/keepalived/keepalived.conf
systemctl enable keepalived.service
systemctl restart keepalived.service

if [[ $(hostname) =~ ncn-s00[1-3] ]]; then
  echo "Reconfiguring ceph-csi storage class config map"
  . /srv/cray/scripts/common/csi-configuration.sh
  create_k8s_storage_class
fi

echo "Enabling Ceph services to start on boot and starting if stopped"
#shellcheck disable=SC2046
for service in $(cephadm ls |jq -r .[].systemd_unit|grep $(ceph status -f json-pretty |jq -r .fsid));
do
  systemctl enable $service
  if [[ $(systemctl is-active $service) != "active" ]]
  then
    systemctl restart $service
  fi
done
