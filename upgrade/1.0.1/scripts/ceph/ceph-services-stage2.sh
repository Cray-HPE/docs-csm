#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
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
