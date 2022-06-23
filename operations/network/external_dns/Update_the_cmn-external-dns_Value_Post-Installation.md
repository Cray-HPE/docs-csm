# Update the `cmn-external-dns` value post-installation

By default, the `services/cray-dns-powerdns-cmn-tcp` and `services/cray-dns-powerdns-cmn-udp` services both share the same Customer Management Network \(CMN\) external IP address.
This is defined by the `cmn-external-dns` value, which is specified during the `csi config init` input.

The IP address must be in the static range reserved in MetalLB's `cmn-static-pool` subnet. Currently, this is the only CMN IP address that must be known external to the system,
in order for external DNS to delegate the `system-name.site-domain` zone to `services/cray-dns-powerdns` deployment.

Changing this value after install is relatively straightforward, and only requires the external IP address for `services/cray-dns-powerdns-cmn-tcp` and `services/cray-dns-powerdns-cmn-udp` services to be changed. This
procedure will update the IP addresses that DNS queries.

## Prerequisites

The system is installed.

## Procedure

### Update the LoadBalancer IP address

1. Find the external IP address for the `services/cray-dns-powerdns-cmn-tcp` and `services/cray-dns-powerdns-cmn-tcp` services.

    ```bash
    ncn-m001# kubectl -n services get svc | grep cray-dns-powerdns-cmn-
    ```

    Example output:

    ```text
    cray-dns-powerdns-cmn-tcp                     LoadBalancer   10.25.211.48    10.102.14.113   53:31111/TCP                 2d2h
    cray-dns-powerdns-cmn-udp                     LoadBalancer   10.25.156.88    10.102.14.113   53:32674/UDP                 2d2h
    ```

1. Edit the services and change `spec.loadBalancerIP` to the desired CMN IP address.

    1. Edit the `cray-dns-powerdns-cmn-tcp` service.

        ```bash
        ncn-m001# kubectl -n services edit svc cray-dns-powerdns-cmn-tcp
        ```

    1. Edit the `cray-dns-powerdns-cmn-udp` service.

        ```bash
        ncn-m001# kubectl -n services edit svc cray-dns-powerdns-cmn-udp
        ```

### Update SLS

The `external-dns` IP address reservation in the SLS CMN `cmn_metallb_static_pool` subnet should be updated to the desired CMN IP address.

1. Retrieve the SLS data for CMN.

   ```bash
   ncn-m001# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials \
                 -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
                 -o jsonpath='{.data.client-secret}' | base64 -d` \
                 https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
               | jq -r '.access_token')

   ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" \
                 https://api-gw-service-nmn.local/apis/sls/v1/networks/CMN|jq > CMN.json

   ncn-m001# cp CMN.json CMN.json.bak
   ```

1. Update the `external-dns` IP address in `CMN.json` to the desired CMN IP address.

   ```json
   {
     "Comment": "site to system lookups",
     "IPAddress": "x.x.x.x",
     "Name": "external-dns"
   }
   ```

1. Upload the updated `CMN.json` file to SLS.

   ```bash
   ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" --header \
                 "Content-Type: application/json" --request PUT --data @CMN.json \
                 https://api-gw-service-nmn.local/apis/sls/v1/networks/CMN
   ```

### Update `customizations.yaml`

**IMPORTANT:** If this step is not performed, then the PowerDNS configuration will be overwritten with the previous value the next time CSM or the `cray-dns-powerdns` Helm chart is upgraded.

1. Extract `customizations.yaml` from the `site-init` secret in the `loftsman` namespace.

   ```bash
   ncn-m001# kubectl -n loftsman get secret site-init -o json | jq -r '.data."customizations.yaml"' | base64 -d > customizations.yaml
   ```

1. Update `system_to_site_lookups` in `customizations.yaml` to the desired CMN IP address.

   ```yaml
   spec:
     network:
       netstaticips:
         site_to_system_lookups: x.x.x.x
   ```

1. Update the `site-init` secret in the `loftsman` namespace.

   ```bash
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```
