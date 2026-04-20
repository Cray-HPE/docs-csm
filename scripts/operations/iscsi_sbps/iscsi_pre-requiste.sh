#!/bin/bash

#  MIT License
#
#  (C) Copyright 2026 Hewlett Packard Enterprise Development LP
#
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.

# This script need to be run on iSCSI client nodes when the NCN worker node
# (iSCSI target node) is down during rebuild. Attempting to run when the
#  iSCSI target is up and running, this script will fail. 

# Provide worker name as command line argument

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <argument: NCN worker name>"
  exit 1
fi

NCN_WORKER=$1
echo "NCN_WORKER = $1"

CONFIG_FILE="/etc/iscsi/iscsid.conf"
#CONFIG_FILE="/root/Asha/iscsid.conf"

# Backup the original file
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Set iscsid.safe_logout value 'No'
sed -i 's/^\(\s*iscsid\.safe_logout\s*=\s*\)[Yy][Ee][Ss]/\1No/' "$CONFIG_FILE"

echo "Updated iscsid.safe_logout to No"

systemctl restart iscsid.service

PORTAL=$(iscsiadm -m session | grep $NCN_WORKER | awk '{print $3}' | sed 's/3260.*/3260/')
IQN=$(iscsiadm -m session | grep $NCN_WORKER | awk '{print $4}')

# Logout the iSCSI session

iscsiadm -m node -T $IQN -p $PORTAL -u

exit_status=$?

if [ $exit_status -ne 0 ]; then
  echo "Logging out of iSCSI session with $NCN_WORKER failed, so exiting by resetting iscsid.safe_logout to 'Yes' "
  sed -i 's/^\(\s*iscsid\.safe_logout\s*=\s*\)No/\1Yes/' "$CONFIG_FILE"
  exit 1
fi

# Perform iscsiadm discovery

iscsiadm -m discovery -t sendtargets -p $PORTAL

# Login to iSCSI session

iscsiadm -m node -T $IQN -p $PORTAL -l

# Set back iscsid.safe_logout from 'No' to 'Yes'

sed -i 's/^\(\s*iscsid\.safe_logout\s*=\s*\)No/\1Yes/' "$CONFIG_FILE"

echo "Updated iscsid.safe_logout to Yes"

systemctl restart iscsid.service
