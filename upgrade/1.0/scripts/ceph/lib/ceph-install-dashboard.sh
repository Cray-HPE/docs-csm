#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

function install_dashboard () {
    echo "Enabling the Ceph Dashboard"
    until $(ceph mgr services|jq .dashboard) =~ "ncn-s00"
    ceph mgr module enable dashboard
    done
    echo "Copying or Creating certificates"
    ceph dashboard create-self-signed-cert
    echo "Checking port info"
    if $(ceph config get mgr mgr/dashboard/server_port) != 8443
    then
     ceph config set mgr/dashboard/server_port 8443
    fi
    echo "Creating cray_cephadm dashboard user"
    ceph dashboard ac-user-create cray_cephadm initial0 administrator
    echo "Setting up dashboard access to radosgw"
    radosgw-admin user create --uid=cray_cephadm --display-name=cray_cephadm --system
    access_key=$(radosgw-admin user info --uid cray_cephadm|jq '.keys[0].access_key')
    secret_key=$(radosgw-admin user info --uid cray_cephadm|jq '.keys[0].secret_key')
    ceph dashboard set-rgw-api-access-key -i $access_key
    ceph dashboard set-rgw-api-secret-key -i $secret_key
    # Leaving a place where we can set the rgw-vip address
    # ceph dashboard set-rgw-api-host <host>
    ceph dashboard set-rgw-api-port 8080
    # Putting option incase we need to enable/disable https
    # ceph dashboard set-rgw-api-scheme <scheme>  # http or https
    # Need to investigate the below
    # ceph dashboard set-rgw-api-admin-resource <admin_resource>
    echo "Disable ssl_verify until we are on signed certs"
    ceph dashboard set-rgw-api-ssl-verify False
    # Add checks for verifying the dashboard is up and functional
}
