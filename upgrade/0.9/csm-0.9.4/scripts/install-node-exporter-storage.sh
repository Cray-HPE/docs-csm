#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -o errexit
set -o pipefail
set -o xtrace

zypper in -y golang-github-prometheus-node_exporter

sed -e "s/10.252.0.7/$(hostname -i)/" >/etc/systemd/system/node_exporter.service <<'EOF'

[Unit]
Description=Node Exporter

[Service]
Type=simple
ExecStart=/usr/bin/node_exporter \
--web.listen-address=10.252.0.7:9100 \
--collector.buddyinfo \
--collector.drbd \
--collector.interrupts \
--collector.ksmd \
--collector.logind \
--collector.meminfo_numa \
--collector.mountstats \
--collector.ntp \
--collector.processes \
--collector.qdisc \
--collector.systemd \
--collector.tcpstat \
--collector.textfile.directory /var/lib/node_exporter/textfile_collector
#--collector.filesystem.ignored-mount-points '^/(dev|proc|sys|var/lib/docker/.+)($|/)' \
#--collector.filesystem.ignored-fs-types '^(autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$' \
SyslogIdentifier=node_exporter
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

chown root:root /etc/systemd/system/node_exporter.service

chmod 644 /etc/systemd/system/node_exporter.service

systemctl start node_exporter

systemctl --no-pager status node_exporter
