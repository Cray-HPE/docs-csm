# Updating Cabinet Routes on Management NCNs

This procedure will use config from System Layout Service (SLS) to set up the proper routing for all air and liquid-cooled cabinets present in the system on each of the Management NCNs.

## Prerequisites
-   Passwordless SSH to all of the management NCNs is configured.
-   Ensure Cray Site Init (CSI) is installed and available on ncn-m001.
    ```bash
    ncn-m001# csi version
    ```

    If the `csi` command is not available, then install it:
    1.  Ensure the `csm-sle-15sp2` RPM repo has been added to ncn-m001.
        ```bash
        ncn-m001# zypper lr csm-sle-15sp2
        ```

        Expected output:
        ```bash
        Alias          : csm-sle-15sp2
        Name           : CSM SLE 15 SP2 Packages (added by Ansible)
        URI            : https://packages.local/repository/csm-sle-15sp2
        Enabled        : Yes
        GPG Check      : ( p) Yes
        Priority       : 99 (default priority)
        Autorefresh    : On
        Keep Packages  : Off
        Type           : rpm-md
        GPG Key URI    :
        Path Prefix    :
        Parent Service :
        Keywords       : ---
        Repo Info Path : /etc/zypp/repos.d/csm-sle-15sp2.repo
        MD Cache Path  : /var/cache/zypp/raw/csm-sle-15sp2
        ```

    2.  If the csm-sle-15sp2` repo is not present, then add it:
        ```bash
        ncn-m001# zypper addrepo -fG https://packages.local/repository/csm-sle-15sp2 csm-sle-15sp2
        ```

    3.  Install Cray Site Init:
        ```bash
        ncn-m001# zypper install cray-site-init
        ```

## Procedure

1.  Get an API Token:
    ```bash
    ncn-m001# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                          -d client_id=admin-client \
                          -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                          https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

2.  Add cabinet routes to each of the management NCNs using data from SLS:
    ```bash
    ncn-m001# /usr/share/doc/csm/scripts/operations/node_management/update-ncn-cabinet-routes.sh
    ```

    If the following message appears, then the route being added is already present on the NCN and can be safely ignored.
    ```
    RTNETLINK answers: File exists
    ```

3.  Create payload to update the `cloud-init` user data for management NCNs in BSS to contain the updated cabinet route information:
    ```bash
    ncn-m001# cat <<EOF >write-files-user-data.json
    {
        "user-data": {
            "write_files": [{
                "content": $(jq -n --rawfile file ifroute-vlan002 '$file'),
                "owner": "root:root",
                "path": "/etc/sysconfig/network/ifroute-vlan002",
                "permissions": "0644"
            },
            {
                "content": $(jq -n --rawfile file ifroute-vlan004 '$file'),
                "owner": "root:root",
                "path": "/etc/sysconfig/network/ifroute-vlan004",
                "permissions": "0644"
            }
            ]
        }
    }
    EOF
    ```

4.  Update BSS `cloud-init` user data for the management NCNs:
    ```bash
    ncn-m001# ncn_xnames=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?type=comptype_node&extra_properties.Role=Management" | jq -r '.[] | .Xname' | sort)
    ncn-m001# for ncn in $ncn_xnames; do
        echo "Updating BSS for $ncn"
        csi handoff bss-update-cloud-init --user-data=write-files-user-data.json --limit=${ncn}
    done
    ```