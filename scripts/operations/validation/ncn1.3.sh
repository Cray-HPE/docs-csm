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
mkdir -p /tmp/goss
cd /tmp/goss
wget -q https://raw.githubusercontent.com/Cray-HPE/csm-testing/CASMINST-v1.3/goss-testing/suites/ncn-csm-health-validation.yaml

#Execute goss checks
echo "Automated tests of components..."
goss -g ncn-csm-health-validation.yaml validate 
echo "--------------------------------"
