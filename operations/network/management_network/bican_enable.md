# Enabling Customer High Speed Network Routing

- [Enabling Customer High Speed Network Routing](#enabling-customer-high-speed-network-routing)
- [Configuration Tasks](#configuration-tasks)
  - [Configure SLS](#configure-sls)
  - [Configure UAN](#configure-uan)
  - [Configure UAI](#configure-uai)
  - [Configure Compute Nodes](#configure-compute-nodes)
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

# Configuration Tasks

<a name="configure-sls"></a>

## Configure SLS

To enable the Customer High Speed Network (CHN) the `SystemDefaultRoute` attribute in the System Layout Service (SLS) `BICAN` network needs to be set to the desired network.

Run the following command to update SLS with `CHN` as the `SystemDefaultRoute`

```bash
ncn# /usr/share/doc/csm/scripts/operations/bifurcated_can/bican_route.py --route CHN
Setting SystemDefaultRoute to CHN
```

<a name="configure-uan"></a>

## Configure UAN

The CHN will automatically be configure on a UAN if the SLS `BICAN` network `SystemDefaultRoute` attribute is set to `CHN` and the following Ansible variable is set.

`uan_can_setup: yes`

Please refer to the "HPE Cray User Access Node (UAN) Software Administration Guide (S-8033)" document on the [HPE Support Center](https://support.hpe.com) website for more information.

<a name="configure-uai"></a>

## Configure UAI

Newly created User Access Instances (UAI) will use the network configured as the `SystemDefaultRoute` in the SLS `BICAN` network.

Existing UAIs will continue to use the network that was set when it was created.

<a name="configure-compute"></a>

## Configure Compute Nodes

TBD

<a name="configure-ncn"></a>

## Configure NCNs

Prerequisites for this task: 
  - CSM NCN personalization has been configured.
  - Cray Operating System, Slingshot Host Software, and Slingshot have been installed and configured.

1. Determine the CFS configuration in use on the worker nodes.

   1. Indentify the worker nodes.
   
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

For more information on managing NCN personalization please refer to operations/CSM_product_management/Perform_NCN_Personalization.md

<a name="configure-api-gw"></a>

## Configure the API gateways

No additional steps are required to configure the API gateways for CHN.

If CHN is selected during CSM installation or upgrade the `customer-high-speed` MetalLB pool is defined and the load balancers configured with IP addresses from this pool.

<a name="validation-tasks"></a>

# Validation Tasks

<a name="validate-sls"></a>

## Validating SLS

To display current setting of the `SystemDefaultRoute` SLS `BICAN` network, run the following command.

```bash
ncn-m001# /usr/share/doc/csm/scripts/operations/bifurcated_can/bican_route.py --check
Configured SystemDefaultRoute: CHN
```

<a name="validate-uan"></a>

## Validating UAN

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

## Validating UAI

1. Retrieve the configured CHN subnet from SLS

   ```
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

   ```
   ncn-m001# cray uas admin uais list --format json | jq -c '.[] | {uai_name, uai_ip}'
   {"uai_name":"uai-vers-93f0289d","uai_ip":"10.103.9.69"}
   {"uai_name":"uai-vers-9f67ac89","uai_ip":"10.103.9.70"}
   {"uai_name":"uai-vers-b773a5d9","uai_ip":"10.103.9.71"}
   ```

1. Run the UAI gateway tests

   ```
   ncn# /usr/share/doc/csm/scripts/operations/gateway-test/uai-gateway-test.sh
   ```

   The test will launch a UAI with the gateway-test image, execute the gateway tests, and then delete the UAI that was launched. The test will complete with an overall test status based on the result of the individual health checks on all of the networks.

   ```
   Overall Gateway Test Status:  PASS
   ```

Please refer to the [gateway testing documentation](../gateway_testing.md) for more information.

<a name="validate-compute"></a>

## Validate Compute Nodes

TBD

<a name="validate-ncn"></a>

## Validate NCNs

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

1. Verify the worker nodes have `CMN` IP addresses set on the hsn0 interface.

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

## Validate the API gateways

Check that the `istio-ingressgateway-cmn` API gateway has an IP address.

```
ncn-m001:~ # kubectl -n istio-system get svc istio-ingressgateway-chn
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
istio-ingressgateway-chn   LoadBalancer   10.23.158.228   10.103.9.65   80:30126/TCP,443:31972/TCP   74d
```

Run the NCN gateway health checks

```
ncn-m001:~ # /usr/share/doc/csm/scripts/operations/gateway-test/ncn-gateway-test.sh
```
The test will complete with an overall test status based on the result of the individual health checks on all of the networks.

```
Overall Gateway Test Status:  PASS
```

Please refer to the [gateway testing documentation](../gateway_testing.md) for more information.
