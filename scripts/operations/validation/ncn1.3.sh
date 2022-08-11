#!/bin/bash

#Store password
echo " Please enter Switch Password"
read -s SW_ADMIN_PASSWORD
export SW_ADMIN_PASSWORD

#Update CANU
echo "Updating CANU for network management"
wget https://github.com/Cray-HPE/canu/releases/download/1.6.13/canu-1.6.13-1.x86_64.rpm
rpm -Uvh canu-1.6.13-1.x86_64.rpm
sleep 2s
echo "--------------------------------"

#Install sshpass
echo "Install required packages"
zypper -n install sshpass
sleep 2s
echo "--------------------------------"

#Download Goss yaml configuration file
wget -O goss.yaml-q https://raw.githubusercontent.com/Cray-HPE/csm-testing/main/goss-testing/tests/ncn/goss-check-system-management-tools.yaml

#Execute goss checks
echo "Autmated tests of components..."
goss validate 
echo "--------------------------------"
sleep 10s

 #Information
 echo "Plerase go to https://github.com/Cray-HPE/docs-csm/blob/CASMINST-5067/troubleshooting/known_issues/check_system_management_monitoring_tools.md for remediation steps on failed items above"