#!/bin/bash

#Store password
echo " Please enter Switch Password"
read -s SW_ADMIN_PASSWORD
export SW_ADMIN_PASSWORD

#Update CANU
wget https://github.com/Cray-HPE/canu/releases/download/1.6.13/canu-1.6.13-1.x86_64.rpm
rpm -Uvh canu-1.6.13-1.x86_64.rpm

#Install sshpass
zypper -n install sshpass

#Download Goss yaml configuration file
wget -O goss.yaml https://raw.githubusercontent.com/Cray-HPE/csm-testing/main/goss-testing/tests/ncn/goss-check-system-management-tools.yaml

#Execute goss checks
goss validate 

