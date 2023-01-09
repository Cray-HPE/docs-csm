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

function install_dashboard () {
    echo "Enabling the Ceph Dashboard"
    until [[ "$(ceph mgr services|jq .dashboard)" =~ "ncn-s00" ]]
    do
        ceph mgr module enable dashboard
    done
    echo "Copying or Creating certificates"
    ceph dashboard create-self-signed-cert
    echo "Checking port info"
    if $(ceph config get mgr mgr/dashboard/server_port) != 8443
    then
        ceph config set mgr/dashboard/server_port 8443
    fi
    read -s -p "Enter a password for the initial deployment" passwd
    read -s -p "Confirm passwd" passwd2
    #shellcheck disable=SC2053
    #shellcheck disable=SC1010
    if [[ $passwd == $passwd2 ]] then
      echo "Creating cray_cephadm dashboard user"
      ceph dashboard ac-user-create cray_cephadm $passwd administrator
      echo "Setting up dashboard access to radosgw"
      radosgw-admin user create --uid=cray_cephadm --display-name=cray_cephadm --system
      access_key=$(radosgw-admin user info --uid cray_cephadm|jq '.keys[0].access_key')
      secret_key=$(radosgw-admin user info --uid cray_cephadm|jq '.keys[0].secret_key')
      ceph dashboard set-rgw-api-access-key -i "$access_key"
      ceph dashboard set-rgw-api-secret-key -i "$secret_key"
      # Leaving a place where we can set the rgw-vip address
      # ceph dashboard set-rgw-api-host <host>
      ceph dashboard set-rgw-api-port 8080
      # Putting option in case we need to enable/disable https
      # ceph dashboard set-rgw-api-scheme <scheme>  # http or https
      # Need to investigate the below
      # ceph dashboard set-rgw-api-admin-resource <admin_resource>
      echo "Disable ssl_verify until we are on signed certs"
      ceph dashboard set-rgw-api-ssl-verify False
      # Add checks for verifying the dashboard is up and functional
    else
      echo "passwords did not match, please re-run the install"
    fi
}
