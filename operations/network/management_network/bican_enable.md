# Enabling Customer High Speed Network Routing

- [Enabling Customer High Speed Network Routing](#enabling-customer-high-speed-network-routing)
  - [Configuration Tasks](#configuration-tasks)
    - [Configure SLS](#configure-sls)
    - [Configure UAN](#configure-uan)
    - [Configure UAI](#configure-uai)
    - [Configure Compute Nodes](#configure-compute-nodes)
      - [Retrieve SLS data as JSON](#retrieve-sls-data-as-json)
      - [Add Compute IPs to CHN SLS data](#add-compute-ips-to-chn-sls-data)
      - [Upload migrated SLS file to SLS service](#upload-migrated-sls-file-to-sls-service)
      - [Enable CFS layer](#enable-cfs-layer)
    - [Configure NCNs](#configure-ncns)
    - [Configure the API gateways](#configure-the-api-gateways)
  - [Validation Tasks](#validation-tasks)
    - [Validating SLS](#validating-sls)
    - [Validating UAN](#validating-uan)
    - [Validating UAI](#validating-uai)
    - [Validate Compute Nodes](#validate-compute-nodes)
    - [Validate NCNs](#validate-ncns)
    - [Validate the API gateways](#validate-the-api-gateways)

<a name="configuration-tasks"></a>

## Configuration Tasks

<a name="configure-sls"></a>

### Configure SLS

To enable the Customer High Speed Network (CHN) the `SystemDefaultRoute` attribute in the System Layout Service (SLS) `BICAN` network needs to be set to the desired network.

Run the following command to update SLS with `CHN` as the `SystemDefaultRoute`

```bash
ncn# /usr/share/doc/csm/scripts/operations/bifurcated_can/bican_route.py --route CHN
Setting SystemDefaultRoute to CHN
```

<a name="configure-uan"></a>

### Configure UAN

The CHN will automatically be configure on a UAN if the SLS `BICAN` network `SystemDefaultRoute` attribute is set to `CHN` and the following Ansible variable is set.

`uan_can_setup: yes`

Please refer to the "HPE Cray User Access Node (UAN) Software Administration Guide (`S-8033`)" document on the [HPE Support Center](https://support.hpe.com) website for more information.

<a name="configure-uai"></a>

### Configure UAI

Newly created User Access Instances (UAI) will use the network configured as the `SystemDefaultRoute` in the SLS `BICAN` network.

Existing UAIs will continue to use the network that was set when it was created.

<a name="configure-compute"></a>

### Configure Compute Nodes

Prerequisites for this task:

- Cray Operating System, Slingshot Host Software, and Slingshot have been installed and configured.
- Egress connection from Compute nodes to site resources (e.g. license server) is required, **and**
  - A NAT device is not in place to enable use of HSN IP addresses, **and**
  - The CHN subnet is large enough to contain all Compute nodes.

#### Retrieve SLS data as JSON

1. Obtain a token.

   ```bash
   ncn-m001# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
                                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

1. Create a working directory.

   ```bash
   ncn-m001# mkdir /root/sls_chn_ips && cd /root/sls_chn_ips
   ```

1. Extract SLS data to a file.

   ```bash
   ncn-m001# curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
   ```

#### Add Compute IPs to CHN SLS data

Process the SLS file:

   ```bash
   ncn-m001# export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
   ncn-m001# ${DOCDIR}/add_computes_to_chn.py --sls-input-file sls_input_file.json
   ```

The default output file name will be `chn_with_computes_added_sls_file.json`, but can  be changed by using the flag `--sls-output-file` with the script.

#### Upload migrated SLS file to SLS service

If the following command does not complete successfully, check if the `TOKEN` environment variable is set correctly.

   ```bash
   ncn-m001# curl --fail -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F 'sls_dump=@chn_with_computes_added_sls_file.json'
   ```

#### Enable CFS layer

CHN network configuration of compute nodes is performed by the UAN CFS configuration layer. This procedure describes how to identify the UAN layer and add it to the compute node configuration.

1. Determine the CFS configuration in use on the compute nodes.

   1. Identify the compute nodes.

      ```bash
      ncn# cray hsm state components list --role Compute --format json | jq -r '.Components[] | .ID'
      x1000c5s1b0n1
      x1000c5s1b0n0
      x1000c5s0b0n0
      x1000c5s0b0n1
      ```

   1. Identify CFS configuration in use on the compute nodes.

      ```bash
      ncn# cray cfs components describe x1000c5s1b0n1
      configurationStatus = "configured"
      desiredConfig = "cos-config-full-2.3-integration"
      enabled = true
      errorCount = 0
      id = "x1000c5s1b0n1"
      ```

   1. Extract the CFS configuration.

      ```bash
      ncn# cray cfs configurations describe cos-config-full-2.3-integration --format json | jq 'del(.lastUpdated) | del(.name)' > cos-config-full-2.3-integration.json
      ```

1. Identify the UAN CFS configuration.

   1. Identify the UAN nodes.

      ```bash
      ncn# cray hsm state components list --role Application --subrole UAN --format    json | jq -r '.Components[] | .ID'
      x3000c0s25b0n0
      x3000c0s16b0n0
      x3000c0s15b0n0
      ```

   1. Identify the UAN CFS configuration in use.

      ```bash
      ncn# cray cfs components describe x3000c0s25b0n0
      configurationStatus = "configured"
      desiredConfig = "chn-uan-cn"
      enabled = true
      errorCount = 0
      id = "x3000c0s25b0n0"
      ```

   1. Identify the UAN CFS configuration layer.

      The resulting output should look similar to this. Installed products, versions, and commit hashes will vary.

      ```json
      ncn# cray cfs configurations describe chn-uan-cn --format json
      {
        "lastUpdated": "2022-05-27T20:15:10Z",
        "layers": [
          {
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
            "commit": "359611be2f6893ddd0020841b73a3d4924120bb1",
            "name": "chn-uan-cn",
            "playbook": "site.yml"
          }
        ],
        "name": "chn-uan-cn"
      }
      ```

1. Edit the extracted compute node configuration and add the UAN layer to it.

1. Update the compute node CFS configuration.

   ```bash
   ncn# cray cfs configurations update cos-config-full-2.3-integration --file cos-config-full-2.3-integration.json
   lastUpdated = "2022-05-27T20:47:18Z"
   name = "cos-config-full-2.3-integration"
   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/   slingshot-host-software-config-management.git"
   commit = "dd428854a04a652f825a3abbbf5ae2ff9842dd55"
   name = "shs-integration"
   playbook = "shs_mellanox_install.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
   commit = "92ce2c9988fa092ad05b40057c3ec81af7b0af97"
   name = "csm-1.9.21"
   playbook = "site.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git"
   commit = "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7"
   name = "cos-compute-integration-2.3.75"
   playbook = "cos-compute.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/sma-config-management.git"
   commit = "2219ca094c0a2721f3bf52f5bd542d8c4794bfed"
   name = "sma-base-config"
   playbook = "sma-base-config.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/sma-config-management.git"
   commit = "2219ca094c0a2721f3bf52f5bd542d8c4794bfed"
   name = "sma-ldms-ncn"
   playbook = "sma-ldms-ncn.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/slurm-config-management.git"
   commit = "0982661002a857d743ee5b772520e47c97f63acc"
   name = "slurm master"
   playbook = "site.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/pbs-config-management.git"
   commit = "874050c9820cc0752c6424ef35295289487acccc"
   name = "pbs master"
   playbook = "site.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/analytics-config-management.git"
   commit = "d4b26b74d08e668e61a1e5ee199e1a235e9efa3b"
   name = "analytics integration"
   playbook = "site.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git"
   commit = "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7"
   name = "cos-compute-last-integration-2.3.75"
   playbook = "cos-compute-last.yml"

   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git"
   commit = "359611be2f6893ddd0020841b73a3d4924120bb1"
   name = "chn-uan-cn"
   playbook = "site.yml"
   ```

1. Check that CFS configuration of the compute node completes successfully.

   Updating the CFS configuration will cause CFS to schedule the nodes for configuration. Run the following command to verify this has occurred.

   ```bash
   ncn# cray cfs components describe x1000c5s1b0n1
   configurationStatus = "pending"
   desiredConfig = "cos-config-full-2.3-integration"
   enabled = true
   errorCount = 0
   id = "x1000c5s1b0n1"
   state = []

   [tags]
   ```

   `configurationStatus` should change from `pending` to `configured` once CFS configuration of the node is complete.

For more information on managing node with CFS please refer to the [Configuration Management](../../../operations/index.md#configuration-management) documentation.

<a name="configure-ncn"></a>

### Configure NCNs

Prerequisites for this task:

- CSM NCN personalization has been configured.
- Cray Operating System, Slingshot Host Software, and Slingshot have been installed and configured.

1. Determine the CFS configuration in use on the worker nodes.

   1. Identify the worker nodes.

      ```bash
      ncn# cray hsm state components list --role Management --subrole Worker --format json | jq -r '.Components[] | .ID'
      x3000c0s4b0n0
      x3000c0s6b0n0
      x3000c0s5b0n0
      x3000c0s7b0n0
      ```

   1. Identify CFS configuration in use on the worker nodes.

      ```bash
      ncn# cray cfs components describe x3000c0s4b0n0
      configurationStatus = "configured"
      desiredConfig = "ncn-personalization"
      enabled = true
      errorCount = 0
      id = "x3000c0s4b0n0"
      ```

1. Extract the CFS configuration

   ```bash
   ncn# cray cfs configurations describe ncn-personalization --format json | jq 'del(.lastUpdated) | del(.name)' > ncn-personalization.json
   ```

   The resulting output file should look similar to this. Installed products, versions, and commit hashes will vary.

   ```json
   {
     "layers": [
       {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/slingshot-host-software-config-management.git",
         "commit": "f4e2bb7e912c39fc63e87a9284d026a5bebb6314",
         "name": "shs-1.7.3-45-1.0.26",
         "playbook": "shs_mellanox_install.yml"
       },
       {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
         "commit": "92ce2c9988fa092ad05b40057c3ec81af7b0af97",
         "name": "csm-1.9.21",
         "playbook": "site.yml"
       },
       {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/sat-config-management.git",
         "commit": "4e14a37b32b0a3b779b7e5f2e70998dde47edde1",
         "name": "sat-2.3.4",
         "playbook": "sat-ncn.yml"
       },
       {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
         "commit": "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7",
         "name": "cos-integration-2.3.75",
         "playbook": "ncn.yml"
       },
       {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
         "commit": "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7",
         "name": "cos-integration-2.3.75",
         "playbook": "ncn-final.yml"
       }
     ]
   }
   ```

1. Edit the extracted file and take the existing CSM layer and create an new layer to run the `enable_chn.yml` playbook.

   ```json
   {
     "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
     "commit": "92ce2c9988fa092ad05b40057c3ec81af7b0af97",
     "name": "csm-1.9.21",
     "playbook": "enable_chn.yml"
   }
   ```

   **Important:** This new layer *must* run after the SHS and COS `ncn-final.yml` layers otherwise the HSN interfaces will not be configured correctly and this playbook will fail.

1. Update the NCN personalization configuration.

   ```bash
   ncn# cray cfs configurations update ncn-personalization --file ncn-personalization.json
   lastUpdated = "2022-05-25T09:22:44Z"
   name = "ncn-personalization"
   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/   slingshot-host-software-config-management.git"
   commit = "f4e2bb7e912c39fc63e87a9284d026a5bebb6314"
   name = "shs-1.7.3-45-1.0.26"
   playbook = "shs_mellanox_install.yml"
   
   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
   commit = "92ce2c9988fa092ad05b40057c3ec81af7b0af97"
   name = "csm-1.9.21"
   playbook = "site.yml"
   
   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/sat-config-management.git"
   commit = "4e14a37b32b0a3b779b7e5f2e70998dde47edde1"
   name = "sat-2.3.4"
   playbook = "sat-ncn.yml"
   
   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git"
   commit = "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7"
   name = "cos-integration-2.3.75"
   playbook = "ncn.yml"
   
   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git"
   commit = "dd2bcbb97e3adbfd604f9aa297fb34baa0dd90f7"
   name = "cos-integration-2.3.75"
   playbook = "ncn-final.yml"
   
   [[layers]]
   cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
   commit = "92ce2c9988fa092ad05b40057c3ec81af7b0af97"
   name = "csm-1.9.21"
   playbook = "enable_chn.yml"
   ```

1. Check that NCN personalization runs and completes successfully on the worker nodes

   Updating the CFS configuration will cause CFS to schedule the nodes for configuration. Run the following command to verify this has occurred.

   ```bash
   ncn# cray cfs components describe x3000c0s4b0n0
   configurationStatus = "pending"
   desiredConfig = "ncn-personalization"
   enabled = true
   errorCount = 0
   id = "x3000c0s4b0n0"
   state = []
   
   [tags]
   ```

   `configurationStatus` should change from `pending` to `configured` once NCN personalization completes successfully.

For more information on managing NCN personalization please refer to [Perform NCN Personalization](../../../operations/CSM_product_management/Perform_NCN_Personalization.md)

<a name="configure-api-gw"></a>

### Configure the API gateways

No additional steps are required to configure the API gateways for CHN.

If CHN is selected during CSM installation or upgrade the `customer-high-speed` MetalLB pool is defined and the load balancers configured with IP addresses from this pool.

<a name="validation-tasks"></a>

## Validation Tasks

<a name="validate-sls"></a>

### Validating SLS

To display current setting of the `SystemDefaultRoute` SLS `BICAN` network, run the following command.

```bash
ncn-m001# /usr/share/doc/csm/scripts/operations/bifurcated_can/bican_route.py --check
Configured SystemDefaultRoute: CHN
```

<a name="validate-uan"></a>

### Validating UAN

1. Retrieve the `CHN` network information from SLS.

   ```bash
   ncn-m001:~ # cray sls search networks list --name CHN --format json  | jq '.[].   ExtraProperties.Subnets[] | select(.Name=="bootstrap_dhcp") | del(.IPReservations)'
   {
     "CIDR": "10.103.9.0/25",
     "DHCPEnd": "10.103.9.62",
     "DHCPStart": "10.103.9.16",
     "FullName": "CHN Bootstrap DHCP Subnet",
     "Gateway": "10.103.9.1",
     "Name": "bootstrap_dhcp",
     "VlanID": 5
   }
   ```

1. Verify the default route is set correctly on the UAN.

   ```bash
   uan02:~ # ip r
   default via 10.103.9.1 dev hsn0
   10.92.100.0/24 via 10.252.0.1 dev nmn0
   10.100.0.0/17 via 10.252.0.1 dev nmn0
   10.103.9.0/25 dev hsn0 proto kernel scope link src 10.103.9.15
   10.252.0.0/17 dev nmn0 proto kernel scope link src 10.252.1.16
   10.253.0.0/16 dev hsn0 proto kernel scope link src 10.253.0.25
   ```

<a name="validate-uai"></a>

### Validating UAI

1. Retrieve the configured CHN subnet from SLS

   ```bash
   ncn-m001# cray sls search networks list --name CHN --format json | jq '.[].   ExtraProperties.Subnets[] | select(.Name=="chn_metallb_address_pool")'
   {
     "CIDR": "10.103.9.64/27",
     "FullName": "CHN Dynamic MetalLB",
     "Gateway": "10.103.9.65",
     "MetalLBPoolName": "customer-high-speed",
     "Name": "chn_metallb_address_pool",
     "VlanID": 5
   }
   ```

1. Verify that UAIs are being created with IP addresses in the correct range.

   ```bash
   ncn-m001# cray uas admin uais list --format json | jq -c '.[] | {uai_name, uai_ip}'
   {"uai_name":"uai-vers-93f0289d","uai_ip":"10.103.9.69"}
   {"uai_name":"uai-vers-9f67ac89","uai_ip":"10.103.9.70"}
   {"uai_name":"uai-vers-b773a5d9","uai_ip":"10.103.9.71"}
   ```

1. Run the UAI gateway tests

   ```bash
   ncn# /usr/share/doc/csm/scripts/operations/gateway-test/uai-gateway-test.sh
   ```

   The test will launch a UAI with the gateway-test image, execute the gateway tests, and then delete the UAI that was launched. The test will complete with an overall test status based on the result of the individual health checks on all of the networks.

   ```bash
   Overall Gateway Test Status:  PASS
   ```

Please refer to the [gateway testing documentation](../gateway_testing.md) for more information.

<a name="validate-compute"></a>

### Validate Compute Nodes

1. Retrieve the `CHN` network information from SLS.

   ```bash
   ncn-m001:~ # cray sls search networks list --name CHN --format json  | jq '.[].   ExtraProperties.Subnets[] | select(.Name=="bootstrap_dhcp") | del(.IPReservations)'
   {
     "CIDR": "10.103.9.0/25",
     "DHCPEnd": "10.103.9.62",
     "DHCPStart": "10.103.9.16",
     "FullName": "CHN Bootstrap DHCP Subnet",
     "Gateway": "10.103.9.1",
     "Name": "bootstrap_dhcp",
     "VlanID": 5
   }
   ```

1. Verify the compute nodes have `CHN` IP addresses set on the `hsn0` interface.

   ```bash
   nid001160:~ # ip ad show hsn0
   3: hsn0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq state UP group default qlen    1000
       link/ether 02:00:00:00:08:73 brd ff:ff:ff:ff:ff:ff
       altname enp194s0np0
       inet 10.253.0.54/16 scope global hsn0
          valid_lft forever preferred_lft forever
       inet 10.103.9.48/25 scope global hsn0
          valid_lft forever preferred_lft forever
       inet6 fe80::ff:fe00:873/64 scope link
          valid_lft forever preferred_lft forever
   ```

1. Verify the default route is set correctly on the compute nodes.

   ```bash
   nid001160:~ # ip route show
   default via 10.103.9.1 dev hsn0
   10.92.100.0/24 via 10.100.0.1 dev nmn0
   10.100.0.0/22 dev nmn0 proto kernel scope link src 10.100.0.13
   10.100.0.0/17 via 10.100.0.1 dev nmn0
   10.103.9.0/25 dev hsn0 proto kernel scope link src 10.103.9.48
   10.252.0.0/17 via 10.100.0.1 dev nmn0
   10.253.0.0/16 dev hsn3 proto kernel scope link src 10.253.0.53
   10.253.0.0/16 dev hsn2 proto kernel scope link src 10.253.0.37
   10.253.0.0/16 dev hsn1 proto kernel scope link src 10.253.0.38
   10.253.0.0/16 dev hsn0 proto kernel scope link src 10.253.0.54
   ```

<a name="validate-ncn"></a>

### Validate NCNs

1. Retrieve the `CHN` network information from SLS.

   ```bash
   ncn-m001:~ # cray sls search networks list --name CHN --format json  | jq '.[].   ExtraProperties.Subnets[] | select(.Name=="bootstrap_dhcp") | del(.IPReservations)'
   {
     "CIDR": "10.103.9.0/25",
     "DHCPEnd": "10.103.9.62",
     "DHCPStart": "10.103.9.16",
     "FullName": "CHN Bootstrap DHCP Subnet",
     "Gateway": "10.103.9.1",
     "Name": "bootstrap_dhcp",
     "VlanID": 5
   }
   ```

1. Verify the worker nodes have `CHN` IP addresses set on the `hsn0` interface.

   ```bash
   ncn-m001:~ # pdsh -w ncn-w00[1-4] 'ip ad show hsn0 | grep inet\ ' | dshbak -c
   ----------------
   ncn-w001
   ----------------
       inet 10.253.0.21/16 brd 10.253.255.255 scope global hsn0
       inet 10.103.9.10/25 scope global hsn0
   ----------------
   ncn-w002
   ----------------
       inet 10.253.0.3/16 brd 10.253.255.255 scope global hsn0
       inet 10.103.9.9/25 scope global hsn0
   ----------------
   ncn-w003
   ----------------
       inet 10.253.0.19/16 brd 10.253.255.255 scope global hsn0
       inet 10.103.9.8/25 scope global hsn0
   ----------------
   ncn-w004
   ----------------
       inet 10.253.0.1/16 brd 10.253.255.255 scope global hsn0
       inet 10.103.9.7/25 scope global hsn0
   ```

<a name="validate-api-gw"></a>

### Validate the API gateways

Check that the `istio-ingressgateway-chn` API gateway has an IP address.

```bash
ncn-m001:~ # kubectl -n istio-system get svc istio-ingressgateway-chn
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
istio-ingressgateway-chn   LoadBalancer   10.23.158.228   10.103.9.65   80:30126/TCP,443:31972/TCP   74d
```

Run the NCN gateway health checks

```bash
ncn-m001:~ # /usr/share/doc/csm/scripts/operations/gateway-test/ncn-gateway-test.sh
```

The test will complete with an overall test status based on the result of the individual health checks on all of the networks.

```bash
Overall Gateway Test Status:  PASS
```

Please refer to the [gateway testing documentation](../gateway_testing.md) for more information.
