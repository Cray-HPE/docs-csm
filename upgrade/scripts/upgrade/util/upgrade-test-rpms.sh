#!/bin/bash
set -euo pipefail
ncns=$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',')

echo "Installing updated versions of csm-testing goss-servers craycli rpms"
pdsh -b -w ${ncns} 'zypper install -y csm-testing goss-servers craycli'

echo "Enabling and starting goss-servers"
pdsh -b -w ${ncns} 'systemctl enable goss-servers && systemctl start goss-servers'
