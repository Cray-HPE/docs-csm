# Cabinet Routing
NCNs require additional routing to enable access to Mountain, Hill and River Compute cabinets.
The following script should be **applied to all NCN worker and master nodes**.

Requires:
* Platform installation
* Running and configured SLS
* Post m001 reboot

Apply the following script to all workers and masters. This idempotent script will apply live and persisted routes for the cabinets as configured by CSI and stored in SLS:
```
#!/bin/bash


export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
export URL="https://api_gw_service.local/apis/sls/v1/networks"

function on_error() {
   echo "Error: $1.  Exiting" 
   exit 1
}

function set_routes() {
    local network=$1
    local subnets=$2
    local gateway=$3

    for subnet in ${subnets}
    do
        # Live routes
        if [[ -z $(ip route show ${subnet} via ${gateway}) ]]
        then
            echo "Adding missing ${network} route:  ip route add ${subnet} via ${gateway}"
            /sbin/ip route add ${subnet} via ${gateway}
        fi

        # Persisted routes
        route_file="/etc/sysconfig/network/ifroute-bond0"
        [[ -f ${route_file} ]] || touch ${route_file}

        egrep "${subnet}.*${gateway}.*\-.*bond0" ${route_file} 2>&1>>/dev/null
        if [[ $? != 0 ]]
        then
            echo "Adding missing route in ${route_file}"
            echo "${subnet} ${gateway} - bond0" >> ${route_file}
        fi
    done
}


#
# Collect network information from SLS
#
nmn_hmn_networks=$(curl -k -H "Authorization: Bearer ${TOKEN}" ${URL} 2>/dev/null | jq ".[] | {NetworkName: .Name, Subnets: .ExtraProperties.Subnets[]} | { NetworkName: .NetworkName, SubnetName: .Subnets.Name, SubnetCIDR: .Subnets.CIDR, Gateway: .Subnets.Gateway} | select(.SubnetName==\"network_hardware\") ")
[[ ! -z ${nmn_hmn_networks} ]] || on_error "Cannot retrieve HMN and NMN networks from SLS. Check SLS connectivity."
cabinet_networks=$(curl -k -H "Authorization: Bearer ${TOKEN}" ${URL} 2>/dev/null | jq ".[] | {NetworkName: .Name, Subnets: .ExtraProperties.Subnets[]} | { NetworkName: .NetworkName, SubnetName: .Subnets.Name, SubnetCIDR: .Subnets.CIDR} | select(.SubnetName | startswith(\"cabinet_\")) ")
[[ ! -z ${cabinet_networks} ]] || on_error "Cannot retrieve cabinet networks from SLS. Check SLS connectivity."


#
# NMN
#
gateway=$(echo ${nmn_hmn_networks} | jq -r ". | select(.NetworkName==\"NMN\") | .Gateway")
[[ ! -z ${gateway} ]] || on_error "NMN gateway not found"
cabinet_subnets=$(echo ${cabinet_networks} | jq -r ". | select(.NetworkName==\"NMN\" or .NetworkName==\"NMN_RVR\" or .NetworkName==\"NMN_MTN\") | .SubnetCIDR")
[[ ! -z ${cabinet_subnets} ]] || on_error "NMN cabinet subnets not found"
set_routes "NMN" "${cabinet_subnets}" "${gateway}"


#
# HMN
#
gateway=$(echo ${nmn_hmn_networks} | jq -r ". | select(.NetworkName==\"HMN\") | .Gateway")
[[ ! -z ${gateway} ]] || on_error "HMN gateway not found"
cabinet_subnets=$(echo ${cabinet_networks} | jq -r ". | select(.NetworkName==\"HMN\" or .NetworkName==\"HMN_RVR\" or .NetworkName==\"HMN_MTN\") | .SubnetCIDR")
[[ ! -z ${cabinet_subnets} ]] || on_error "HMN cabinet subnets not found"
set_routes "HMN" "${cabinet_subnets}" "${gateway}"
```