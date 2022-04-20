# Gateway Testing

With the introduction of BiCAN, service APIs are now available on one or more networks depending on who is allowed access to the services and from where.
The services are accessed via three different ingress gateways using a token that can be retrieved from keycloak.

This page describes how to run a set of tests to determine if the gateways are functioning properly. The gateway test will obtain an API token from Keycloak and then use that token to attempt to access a set of service APIs on one or more networks as defined in the gateway test definition file (`gateway-test-defn.yaml`). The test will check the return code to make sure it gets the expected response.

When the nmnlb network is specified, it will use `api-gw-service-nmn.local` as an override for `nmnlb.<system-domain>` in 1.2. You can set `use-api-gw-override: false` in `gateway-test-defn.yaml` if you would like to disable that override and use `nmnlb.<system-domain>`.

## Running gateway tests on an NCN

The gateway test scripts can be found in `/usr/share/doc/csm/scripts/operations/gateway-test`. To test the gateways from an NCN, use `gateway-test.py`. When `gateway-test.py` is run from an NCN, it has access to the admin client secret using `kubectl`. It will use the admin client secret to get the token for accessing the APIs.

You can run the test by executing the following command. You will need to specify the system domain (for example, `eniac.dev.cray.com`).

```bash
ncn# /usr/share/doc/csm/scripts/operations/gateway-test/gateway-test.py eniac.dev.cray.com
```

The test will cycle through all of the test networks specified in `gateway-test-defn.yaml`.

```yaml
test-networks:
- name: nmnlb
  gateway: services-gateway
- name: cmn
  gateway: services-gateway
- name: can
  gateway: customer-user-gateway
- name: chn
  gateway: customer-user-gateway
```

For each network it will attempt to obtain a token from Keycloak. On an NCN, it should be able to get a token from each of those networks. It will then use that token to attempt to access each of the services defined in `gateway-test-defn.yaml` on each of the `test-networks`. The test will be able to determine whether it should or should not be able to access the service and it will output a PASS or FAIL for each test, depending on the actual results.

## Running gateway tests from UAN, Compute Node, or a device outside of the cluster

You will need to install the `docs-csm` RPM on a device outside the cluster or copy both the `gateway-test.py` and `gateway-test-defn.yaml` files to a system that has `python3` installed. Because we do not have access to `kubectl` outside the cluster, you will need to obtain the admin client secret from the system by running the following command on an NCN.

```bash
ncn# kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d
26947343-d4ab-403b-14e937dbd700
```
You will then need to set the ADMIN_CLIENT_SECRET environment variable to the admin-client-auth secret you obtained.

```bash
linux# export ADMIN_CLIENT_SECRET=26947343-d4ab-403b-14e937dbd700
```

Run the tests by executing the following the command. The system domain (e.g. eniac.dev.cray.com) must be specified.

```bash
linux# /usr/share/doc/csm/scripts/operations/gateway-test/gateway-test.py eniac.dev.cray.com
```

## Running gateway tests on a UAI 

In order to test the gateways from a UAI, you will need to run `uai-gateway-test.sh`.

This script will execute the following steps:

1. Create a UAI with a `cray-uai-gateway-test` image.
1. Pass the system domain, user network, and admin client secret to the test UAI.
1. Execute `gateway-test.py` on the node.
1. Output the results.
1. Delete the test UAI.

Run the test by executing the following command.

```bash
ncn# /usr/share/doc/csm/scripts/operations/gateway-test/uai-gateway-test.sh
```

The test will find the first UAI `cray-uai-gateway-test` image to create the test UAI. A different image may optionally be specified by using the `--imagename` option.

## Example Results 

The results of running the tests will show the following

* Retrieval of a token on the CMN network in order to get SLS data to determine which networks are defined on the system
* For each of the test networks:
    * Retrieval of a token on the network under test.
    * Results from each of the networks defined in `gateway-test-defn.yaml`. It will attempt to access each of the services with the token and check the expected results.
    * It will show PASS or FAIL depending on the expected response for the service and the token being used.
    * It will show SKIP for services that are not expected to be installed on the system.
* The return code of `gateway-test.py` will be non-zero if any of the tests within it fail or we are unable to retrieve a token on any of the networks that are expected to be accessible.

### Running from an NCN that is configured with CHN as the user network

```bash
ncn-m001# ./gateway-test.py eniac.dev.cray.com
auth.cmn.eniac.dev.cray.com is reachable
Token successfully retrieved at https://auth.cmn.eniac.dev.cray.com/keycloak/realms/shasta/protocol/openid-connect/token

Getting token for nmnlb
api-gw-service-nmn.local is reachable
Token successfully retrieved at https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token


------------- api-gw-service-nmn.local -------------------
api-gw-service-nmn.local is reachable
PASS - [cray-bos]: https://api-gw-service-nmn.local/apis/bos/v1/session - 200
PASS - [cray-bss]: https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters - 200
PASS - [cray-capmc]: https://api-gw-service-nmn.local/apis/capmc/capmc/get_node_rules - 200
PASS - [cray-cfs-api]: https://api-gw-service-nmn.local/apis/cfs/v2/sessions - 200
PASS - [cray-console-data]: https://api-gw-service-nmn.local/apis/consoledata/liveness - 204
PASS - [cray-console-node]: https://api-gw-service-nmn.local/apis/console-node/console-node/liveness - 204
PASS - [cray-console-operator]: https://api-gw-service-nmn.local/apis/console-operator/console-operator/liveness - 204
SKIP - [cray-cps]: https://api-gw-service-nmn.local/apis/v2/cps/contents - virtual service not found
PASS - [cray-fas]: https://api-gw-service-nmn.local/apis/fas/v1/snapshots - 200
PASS - [cray-hbtd]: https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/health - 200
PASS - [cray-hmnfd]: https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/health - 200
PASS - [cray-ims]: https://api-gw-service-nmn.local/apis/ims/images - 200
PASS - [cray-powerdns-manager]: https://api-gw-service-nmn.local/apis/powerdns-manager/v1/liveness - 204
PASS - [cray-reds]: https://api-gw-service-nmn.local/apis/reds/v1/liveness - 204
PASS - [cray-scsd]: https://api-gw-service-nmn.local/apis/scsd/v1/health - 200
PASS - [cray-sls]: https://api-gw-service-nmn.local/apis/sls/v1/health - 200
PASS - [cray-smd]: https://api-gw-service-nmn.local/apis/smd/hsm/v1/service/ready - 200
PASS - [cray-sts]: https://api-gw-service-nmn.local/apis/sts/healthz - 200
PASS - [cray-uas-mgr]: https://api-gw-service-nmn.local/apis/uas-mgr/v1/images - 200
SKIP - [nmdv2-service]: https://api-gw-service-nmn.local/apis/v2/nmd/dumps - virtual service not found
SKIP - [slingshot-fabric-manager]: https://api-gw-service-nmn.local/apis/fabric-manager/fabric/port-policies - virtual service not found
SKIP - [sma-telemetry]: https://api-gw-service-nmn.local/apis/sma-telemetry-api/v1/ping - virtual service not found

------------- api.cmn.eniac.dev.cray.com -------------------
api.cmn.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.cmn.eniac.dev.cray.com/apis/bos/v1/session - 200
PASS - [cray-bss]: https://api.cmn.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 200
PASS - [cray-capmc]: https://api.cmn.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 200
PASS - [cray-cfs-api]: https://api.cmn.eniac.dev.cray.com/apis/cfs/v2/sessions - 200
PASS - [cray-console-data]: https://api.cmn.eniac.dev.cray.com/apis/consoledata/liveness - 204
PASS - [cray-console-node]: https://api.cmn.eniac.dev.cray.com/apis/console-node/console-node/liveness - 204
PASS - [cray-console-operator]: https://api.cmn.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 204
SKIP - [cray-cps]: https://api.cmn.eniac.dev.cray.com/apis/v2/cps/contents - virtual service not found
PASS - [cray-fas]: https://api.cmn.eniac.dev.cray.com/apis/fas/v1/snapshots - 200
PASS - [cray-hbtd]: https://api.cmn.eniac.dev.cray.com/apis/hbtd/hmi/v1/health - 200
PASS - [cray-hmnfd]: https://api.cmn.eniac.dev.cray.com/apis/hmnfd/hmi/v2/health - 200
PASS - [cray-ims]: https://api.cmn.eniac.dev.cray.com/apis/ims/images - 200
PASS - [cray-powerdns-manager]: https://api.cmn.eniac.dev.cray.com/apis/powerdns-manager/v1/liveness - 204
PASS - [cray-reds]: https://api.cmn.eniac.dev.cray.com/apis/reds/v1/liveness - 204
PASS - [cray-scsd]: https://api.cmn.eniac.dev.cray.com/apis/scsd/v1/health - 200
PASS - [cray-sls]: https://api.cmn.eniac.dev.cray.com/apis/sls/v1/health - 200
PASS - [cray-smd]: https://api.cmn.eniac.dev.cray.com/apis/smd/hsm/v1/service/ready - 200
PASS - [cray-sts]: https://api.cmn.eniac.dev.cray.com/apis/sts/healthz - 200
PASS - [cray-uas-mgr]: https://api.cmn.eniac.dev.cray.com/apis/uas-mgr/v1/images - 200
SKIP - [nmdv2-service]: https://api.cmn.eniac.dev.cray.com/apis/v2/nmd/dumps - virtual service not found
SKIP - [slingshot-fabric-manager]: https://api.cmn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies - virtual service not found
SKIP - [sma-telemetry]: https://api.cmn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping - virtual service not found

------------- api.can.eniac.dev.cray.com -------------------
ping: api.can.eniac.dev.cray.com: Name or service not known
api.can.eniac.dev.cray.com is NOT reachable
can is not reachable and is not expected to be

------------- api.chn.eniac.dev.cray.com -------------------
api.chn.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.chn.eniac.dev.cray.com/apis/bos/v1/session - 404
PASS - [cray-bss]: https://api.chn.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 404
PASS - [cray-capmc]: https://api.chn.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 404
PASS - [cray-cfs-api]: https://api.chn.eniac.dev.cray.com/apis/cfs/v2/sessions - 404
PASS - [cray-console-data]: https://api.chn.eniac.dev.cray.com/apis/consoledata/liveness - 404
PASS - [cray-console-node]: https://api.chn.eniac.dev.cray.com/apis/console-node/console-node/liveness - 404
PASS - [cray-console-operator]: https://api.chn.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 404
SKIP - [cray-cps]: https://api.chn.eniac.dev.cray.com/apis/v2/cps/contents - virtual service not found
PASS - [cray-fas]: https://api.chn.eniac.dev.cray.com/apis/fas/v1/snapshots - 404
PASS - [cray-hbtd]: https://api.chn.eniac.dev.cray.com/apis/hbtd/hmi/v1/health - 404
PASS - [cray-hmnfd]: https://api.chn.eniac.dev.cray.com/apis/hmnfd/hmi/v2/health - 404
PASS - [cray-ims]: https://api.chn.eniac.dev.cray.com/apis/ims/images - 404
PASS - [cray-powerdns-manager]: https://api.chn.eniac.dev.cray.com/apis/powerdns-manager/v1/liveness - 404
PASS - [cray-reds]: https://api.chn.eniac.dev.cray.com/apis/reds/v1/liveness - 404
PASS - [cray-scsd]: https://api.chn.eniac.dev.cray.com/apis/scsd/v1/health - 404
PASS - [cray-sls]: https://api.chn.eniac.dev.cray.com/apis/sls/v1/health - 404
PASS - [cray-smd]: https://api.chn.eniac.dev.cray.com/apis/smd/hsm/v1/service/ready - 404
PASS - [cray-sts]: https://api.chn.eniac.dev.cray.com/apis/sts/healthz - 404
PASS - [cray-uas-mgr]: https://api.chn.eniac.dev.cray.com/apis/uas-mgr/v1/images - 404
SKIP - [nmdv2-service]: https://api.chn.eniac.dev.cray.com/apis/v2/nmd/dumps - virtual service not found
SKIP - [slingshot-fabric-manager]: https://api.chn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies - virtual service not found
SKIP - [sma-telemetry]: https://api.chn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping - virtual service not found

Getting token for cmn
auth.cmn.eniac.dev.cray.com is reachable
Token successfully retrieved at https://auth.cmn.eniac.dev.cray.com/keycloak/realms/shasta/protocol/openid-connect/token


------------- api-gw-service-nmn.local -------------------
api-gw-service-nmn.local is reachable
PASS - [cray-bos]: https://api-gw-service-nmn.local/apis/bos/v1/session - 200
PASS - [cray-bss]: https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters - 200
PASS - [cray-capmc]: https://api-gw-service-nmn.local/apis/capmc/capmc/get_node_rules - 200
PASS - [cray-cfs-api]: https://api-gw-service-nmn.local/apis/cfs/v2/sessions - 200
PASS - [cray-console-data]: https://api-gw-service-nmn.local/apis/consoledata/liveness - 204
PASS - [cray-console-node]: https://api-gw-service-nmn.local/apis/console-node/console-node/liveness - 204
PASS - [cray-console-operator]: https://api-gw-service-nmn.local/apis/console-operator/console-operator/liveness - 204
SKIP - [cray-cps]: https://api-gw-service-nmn.local/apis/v2/cps/contents - virtual service not found
PASS - [cray-fas]: https://api-gw-service-nmn.local/apis/fas/v1/snapshots - 200
PASS - [cray-hbtd]: https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/health - 200
PASS - [cray-hmnfd]: https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/health - 200
PASS - [cray-ims]: https://api-gw-service-nmn.local/apis/ims/images - 200
PASS - [cray-powerdns-manager]: https://api-gw-service-nmn.local/apis/powerdns-manager/v1/liveness - 204
PASS - [cray-reds]: https://api-gw-service-nmn.local/apis/reds/v1/liveness - 204
PASS - [cray-scsd]: https://api-gw-service-nmn.local/apis/scsd/v1/health - 200
PASS - [cray-sls]: https://api-gw-service-nmn.local/apis/sls/v1/health - 200
PASS - [cray-smd]: https://api-gw-service-nmn.local/apis/smd/hsm/v1/service/ready - 200
PASS - [cray-sts]: https://api-gw-service-nmn.local/apis/sts/healthz - 200
PASS - [cray-uas-mgr]: https://api-gw-service-nmn.local/apis/uas-mgr/v1/images - 200
SKIP - [nmdv2-service]: https://api-gw-service-nmn.local/apis/v2/nmd/dumps - virtual service not found
SKIP - [slingshot-fabric-manager]: https://api-gw-service-nmn.local/apis/fabric-manager/fabric/port-policies - virtual service not found
SKIP - [sma-telemetry]: https://api-gw-service-nmn.local/apis/sma-telemetry-api/v1/ping - virtual service not found

------------- api.cmn.eniac.dev.cray.com -------------------
api.cmn.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.cmn.eniac.dev.cray.com/apis/bos/v1/session - 200
PASS - [cray-bss]: https://api.cmn.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 200
PASS - [cray-capmc]: https://api.cmn.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 200
PASS - [cray-cfs-api]: https://api.cmn.eniac.dev.cray.com/apis/cfs/v2/sessions - 200
PASS - [cray-console-data]: https://api.cmn.eniac.dev.cray.com/apis/consoledata/liveness - 204
PASS - [cray-console-node]: https://api.cmn.eniac.dev.cray.com/apis/console-node/console-node/liveness - 204
PASS - [cray-console-operator]: https://api.cmn.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 204
SKIP - [cray-cps]: https://api.cmn.eniac.dev.cray.com/apis/v2/cps/contents - virtual service not found
PASS - [cray-fas]: https://api.cmn.eniac.dev.cray.com/apis/fas/v1/snapshots - 200
PASS - [cray-hbtd]: https://api.cmn.eniac.dev.cray.com/apis/hbtd/hmi/v1/health - 200
PASS - [cray-hmnfd]: https://api.cmn.eniac.dev.cray.com/apis/hmnfd/hmi/v2/health - 200
PASS - [cray-ims]: https://api.cmn.eniac.dev.cray.com/apis/ims/images - 200
PASS - [cray-powerdns-manager]: https://api.cmn.eniac.dev.cray.com/apis/powerdns-manager/v1/liveness - 204
PASS - [cray-reds]: https://api.cmn.eniac.dev.cray.com/apis/reds/v1/liveness - 204
PASS - [cray-scsd]: https://api.cmn.eniac.dev.cray.com/apis/scsd/v1/health - 200
PASS - [cray-sls]: https://api.cmn.eniac.dev.cray.com/apis/sls/v1/health - 200
PASS - [cray-smd]: https://api.cmn.eniac.dev.cray.com/apis/smd/hsm/v1/service/ready - 200
PASS - [cray-sts]: https://api.cmn.eniac.dev.cray.com/apis/sts/healthz - 200
PASS - [cray-uas-mgr]: https://api.cmn.eniac.dev.cray.com/apis/uas-mgr/v1/images - 200
SKIP - [nmdv2-service]: https://api.cmn.eniac.dev.cray.com/apis/v2/nmd/dumps - virtual service not found
SKIP - [slingshot-fabric-manager]: https://api.cmn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies - virtual service not found
SKIP - [sma-telemetry]: https://api.cmn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping - virtual service not found

------------- api.can.eniac.dev.cray.com -------------------
ping: api.can.eniac.dev.cray.com: Name or service not known
api.can.eniac.dev.cray.com is NOT reachable
can is not reachable and is not expected to be

------------- api.chn.eniac.dev.cray.com -------------------
api.chn.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.chn.eniac.dev.cray.com/apis/bos/v1/session - 404
PASS - [cray-bss]: https://api.chn.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 404
PASS - [cray-capmc]: https://api.chn.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 404
PASS - [cray-cfs-api]: https://api.chn.eniac.dev.cray.com/apis/cfs/v2/sessions - 404
PASS - [cray-console-data]: https://api.chn.eniac.dev.cray.com/apis/consoledata/liveness - 404
PASS - [cray-console-node]: https://api.chn.eniac.dev.cray.com/apis/console-node/console-node/liveness - 404
PASS - [cray-console-operator]: https://api.chn.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 404
SKIP - [cray-cps]: https://api.chn.eniac.dev.cray.com/apis/v2/cps/contents - virtual service not found
PASS - [cray-fas]: https://api.chn.eniac.dev.cray.com/apis/fas/v1/snapshots - 404
PASS - [cray-hbtd]: https://api.chn.eniac.dev.cray.com/apis/hbtd/hmi/v1/health - 404
PASS - [cray-hmnfd]: https://api.chn.eniac.dev.cray.com/apis/hmnfd/hmi/v2/health - 404
PASS - [cray-ims]: https://api.chn.eniac.dev.cray.com/apis/ims/images - 404
PASS - [cray-powerdns-manager]: https://api.chn.eniac.dev.cray.com/apis/powerdns-manager/v1/liveness - 404
PASS - [cray-reds]: https://api.chn.eniac.dev.cray.com/apis/reds/v1/liveness - 404
PASS - [cray-scsd]: https://api.chn.eniac.dev.cray.com/apis/scsd/v1/health - 404
PASS - [cray-sls]: https://api.chn.eniac.dev.cray.com/apis/sls/v1/health - 404
PASS - [cray-smd]: https://api.chn.eniac.dev.cray.com/apis/smd/hsm/v1/service/ready - 404
PASS - [cray-sts]: https://api.chn.eniac.dev.cray.com/apis/sts/healthz - 404
PASS - [cray-uas-mgr]: https://api.chn.eniac.dev.cray.com/apis/uas-mgr/v1/images - 404
SKIP - [nmdv2-service]: https://api.chn.eniac.dev.cray.com/apis/v2/nmd/dumps - virtual service not found
SKIP - [slingshot-fabric-manager]: https://api.chn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies - virtual service not found
SKIP - [sma-telemetry]: https://api.chn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping - virtual service not found

Getting token for can
ping: auth.can.eniac.dev.cray.com: Name or service not known
auth.can.eniac.dev.cray.com is NOT reachable

Getting token for chn
auth.chn.eniac.dev.cray.com is reachable
Token successfully retrieved at https://auth.chn.eniac.dev.cray.com/keycloak/realms/shasta/protocol/openid-connect/token


------------- api-gw-service-nmn.local -------------------
api-gw-service-nmn.local is reachable
PASS - [cray-bos]: https://api-gw-service-nmn.local/apis/bos/v1/session - 403
PASS - [cray-bss]: https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters - 403
PASS - [cray-capmc]: https://api-gw-service-nmn.local/apis/capmc/capmc/get_node_rules - 403
PASS - [cray-cfs-api]: https://api-gw-service-nmn.local/apis/cfs/v2/sessions - 403
PASS - [cray-console-data]: https://api-gw-service-nmn.local/apis/consoledata/liveness - 403
PASS - [cray-console-node]: https://api-gw-service-nmn.local/apis/console-node/console-node/liveness - 403
PASS - [cray-console-operator]: https://api-gw-service-nmn.local/apis/console-operator/console-operator/liveness - 403
SKIP - [cray-cps]: https://api-gw-service-nmn.local/apis/v2/cps/contents - virtual service not found
PASS - [cray-fas]: https://api-gw-service-nmn.local/apis/fas/v1/snapshots - 403
PASS - [cray-hbtd]: https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/health - 403
PASS - [cray-hmnfd]: https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/health - 403
PASS - [cray-ims]: https://api-gw-service-nmn.local/apis/ims/images - 403
PASS - [cray-powerdns-manager]: https://api-gw-service-nmn.local/apis/powerdns-manager/v1/liveness - 403
PASS - [cray-reds]: https://api-gw-service-nmn.local/apis/reds/v1/liveness - 403
PASS - [cray-scsd]: https://api-gw-service-nmn.local/apis/scsd/v1/health - 403
PASS - [cray-sls]: https://api-gw-service-nmn.local/apis/sls/v1/health - 403
PASS - [cray-smd]: https://api-gw-service-nmn.local/apis/smd/hsm/v1/service/ready - 403
PASS - [cray-sts]: https://api-gw-service-nmn.local/apis/sts/healthz - 403
PASS - [cray-uas-mgr]: https://api-gw-service-nmn.local/apis/uas-mgr/v1/images - 403
SKIP - [nmdv2-service]: https://api-gw-service-nmn.local/apis/v2/nmd/dumps - virtual service not found
SKIP - [slingshot-fabric-manager]: https://api-gw-service-nmn.local/apis/fabric-manager/fabric/port-policies - virtual service not found
SKIP - [sma-telemetry]: https://api-gw-service-nmn.local/apis/sma-telemetry-api/v1/ping - virtual service not found

------------- api.cmn.eniac.dev.cray.com -------------------
api.cmn.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.cmn.eniac.dev.cray.com/apis/bos/v1/session - 403
PASS - [cray-bss]: https://api.cmn.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 403
PASS - [cray-capmc]: https://api.cmn.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 403
PASS - [cray-cfs-api]: https://api.cmn.eniac.dev.cray.com/apis/cfs/v2/sessions - 403
PASS - [cray-console-data]: https://api.cmn.eniac.dev.cray.com/apis/consoledata/liveness - 403
PASS - [cray-console-node]: https://api.cmn.eniac.dev.cray.com/apis/console-node/console-node/liveness - 403
PASS - [cray-console-operator]: https://api.cmn.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 403
SKIP - [cray-cps]: https://api.cmn.eniac.dev.cray.com/apis/v2/cps/contents - virtual service not found
PASS - [cray-fas]: https://api.cmn.eniac.dev.cray.com/apis/fas/v1/snapshots - 403
PASS - [cray-hbtd]: https://api.cmn.eniac.dev.cray.com/apis/hbtd/hmi/v1/health - 403
PASS - [cray-hmnfd]: https://api.cmn.eniac.dev.cray.com/apis/hmnfd/hmi/v2/health - 403
PASS - [cray-ims]: https://api.cmn.eniac.dev.cray.com/apis/ims/images - 403
PASS - [cray-powerdns-manager]: https://api.cmn.eniac.dev.cray.com/apis/powerdns-manager/v1/liveness - 403
PASS - [cray-reds]: https://api.cmn.eniac.dev.cray.com/apis/reds/v1/liveness - 403
PASS - [cray-scsd]: https://api.cmn.eniac.dev.cray.com/apis/scsd/v1/health - 403
PASS - [cray-sls]: https://api.cmn.eniac.dev.cray.com/apis/sls/v1/health - 403
PASS - [cray-smd]: https://api.cmn.eniac.dev.cray.com/apis/smd/hsm/v1/service/ready - 403
PASS - [cray-sts]: https://api.cmn.eniac.dev.cray.com/apis/sts/healthz - 403
PASS - [cray-uas-mgr]: https://api.cmn.eniac.dev.cray.com/apis/uas-mgr/v1/images - 403
SKIP - [nmdv2-service]: https://api.cmn.eniac.dev.cray.com/apis/v2/nmd/dumps - virtual service not found
SKIP - [slingshot-fabric-manager]: https://api.cmn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies - virtual service not found
SKIP - [sma-telemetry]: https://api.cmn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping - virtual service not found

------------- api.can.eniac.dev.cray.com -------------------
ping: api.can.eniac.dev.cray.com: Name or service not known
api.can.eniac.dev.cray.com is NOT reachable
can is not reachable and is not expected to be

------------- api.chn.eniac.dev.cray.com -------------------
api.chn.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.chn.eniac.dev.cray.com/apis/bos/v1/session - 404
PASS - [cray-bss]: https://api.chn.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 404
PASS - [cray-capmc]: https://api.chn.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 404
PASS - [cray-cfs-api]: https://api.chn.eniac.dev.cray.com/apis/cfs/v2/sessions - 404
PASS - [cray-console-data]: https://api.chn.eniac.dev.cray.com/apis/consoledata/liveness - 404
PASS - [cray-console-node]: https://api.chn.eniac.dev.cray.com/apis/console-node/console-node/liveness - 404
PASS - [cray-console-operator]: https://api.chn.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 404
SKIP - [cray-cps]: https://api.chn.eniac.dev.cray.com/apis/v2/cps/contents - virtual service not found
PASS - [cray-fas]: https://api.chn.eniac.dev.cray.com/apis/fas/v1/snapshots - 404
PASS - [cray-hbtd]: https://api.chn.eniac.dev.cray.com/apis/hbtd/hmi/v1/health - 404
PASS - [cray-hmnfd]: https://api.chn.eniac.dev.cray.com/apis/hmnfd/hmi/v2/health - 404
PASS - [cray-ims]: https://api.chn.eniac.dev.cray.com/apis/ims/images - 404
PASS - [cray-powerdns-manager]: https://api.chn.eniac.dev.cray.com/apis/powerdns-manager/v1/liveness - 404
PASS - [cray-reds]: https://api.chn.eniac.dev.cray.com/apis/reds/v1/liveness - 404
PASS - [cray-scsd]: https://api.chn.eniac.dev.cray.com/apis/scsd/v1/health - 404
PASS - [cray-sls]: https://api.chn.eniac.dev.cray.com/apis/sls/v1/health - 404
PASS - [cray-smd]: https://api.chn.eniac.dev.cray.com/apis/smd/hsm/v1/service/ready - 404
PASS - [cray-sts]: https://api.chn.eniac.dev.cray.com/apis/sts/healthz - 404
PASS - [cray-uas-mgr]: https://api.chn.eniac.dev.cray.com/apis/uas-mgr/v1/images - 404
SKIP - [nmdv2-service]: https://api.chn.eniac.dev.cray.com/apis/v2/nmd/dumps - virtual service not found
SKIP - [slingshot-fabric-manager]: https://api.chn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies - virtual service not found
SKIP - [sma-telemetry]: https://api.chn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping - virtual service not found

Overall Gateway Test Status:  PASS
```

### Running from a UAI

```bash
ncn-m001# ./uai-gateway-test.sh 
Creating Gateway Test UAI with image artifactory.algol60.net/csm-docker/stable/cray-gateway_test:1.4.0-20220418215843_786bfac
Waiting for uai-vers-733eea45 to be ready
status = Running: Not Ready
status = Running: Ready
System domain is eniac.dev.cray.com
User Network on eniac is chn
Got admin client secret
Running gateway tests on the UAI...(this may take 1-2 minutes)

Getting token for nmnlb
api-gw-service-nmn.local is NOT reachable

Getting token for cmn
auth.cmn.eniac.dev.cray.com is NOT reachable

Getting token for can
auth.can.eniac.dev.cray.com is reachable
Token successfully retrieved at https://auth.can.eniac.dev.cray.com/keycloak/realms/shasta/protocol/openid-connect/token


------------- api-gw-service-nmn.local -------------------
api-gw-service-nmn.local is NOT reachable
nmnlb is not reachable and is not expected to be

------------- api.cmn.eniac.dev.cray.com -------------------
api.cmn.eniac.dev.cray.com is NOT reachable
cmn is not reachable and is not expected to be

------------- api.can.eniac.dev.cray.com -------------------
api.can.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.can.eniac.dev.cray.com/apis/bos/v1/session - 404
PASS - [cray-bss]: https://api.can.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 404
PASS - [cray-capmc]: https://api.can.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 404
PASS - [cray-cfs-api]: https://api.can.eniac.dev.cray.com/apis/cfs/v2/sessions - 404
PASS - [cray-console-data]: https://api.can.eniac.dev.cray.com/apis/consoledata/liveness - 404
PASS - [cray-console-node]: https://api.can.eniac.dev.cray.com/apis/console-node/console-node/liveness - 404
PASS - [cray-console-operator]: https://api.can.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 404
SKIP - [cray-cps]: https://api.can.eniac.dev.cray.com/apis/v2/cps/contents
PASS - [cray-fas]: https://api.can.eniac.dev.cray.com/apis/fas/v1/snapshots - 404
PASS - [cray-hbtd]: https://api.can.eniac.dev.cray.com/apis/hbtd/hmi/v1/health - 404
PASS - [cray-hmnfd]: https://api.can.eniac.dev.cray.com/apis/hmnfd/hmi/v2/health - 404
PASS - [cray-ims]: https://api.can.eniac.dev.cray.com/apis/ims/images - 404
PASS - [cray-powerdns-manager]: https://api.can.eniac.dev.cray.com/apis/powerdns-manager/v1/liveness - 404
PASS - [cray-reds]: https://api.can.eniac.dev.cray.com/apis/reds/v1/liveness - 404
PASS - [cray-scsd]: https://api.can.eniac.dev.cray.com/apis/scsd/v1/health - 404
PASS - [cray-sls]: https://api.can.eniac.dev.cray.com/apis/sls/v1/health - 404
PASS - [cray-smd]: https://api.can.eniac.dev.cray.com/apis/smd/hsm/v1/service/ready - 404
PASS - [cray-sts]: https://api.can.eniac.dev.cray.com/apis/sts/healthz - 404
PASS - [cray-uas-mgr]: https://api.can.eniac.dev.cray.com/apis/uas-mgr/v1/images - 404
SKIP - [nmdv2-service]: https://api.can.eniac.dev.cray.com/apis/v2/nmd/dumps
SKIP - [slingshot-fabric-manager]: https://api.can.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies
SKIP - [sma-telemetry]: https://api.can.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping

------------- api.chn.eniac.dev.cray.com -------------------
api.chn.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.chn.eniac.dev.cray.com/apis/bos/v1/session - 404
PASS - [cray-bss]: https://api.chn.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 404
PASS - [cray-capmc]: https://api.chn.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 404
PASS - [cray-cfs-api]: https://api.chn.eniac.dev.cray.com/apis/cfs/v2/sessions - 404
PASS - [cray-console-data]: https://api.chn.eniac.dev.cray.com/apis/consoledata/liveness - 404
PASS - [cray-console-node]: https://api.chn.eniac.dev.cray.com/apis/console-node/console-node/liveness - 404
PASS - [cray-console-operator]: https://api.chn.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 404
SKIP - [cray-cps]: https://api.chn.eniac.dev.cray.com/apis/v2/cps/contents
PASS - [cray-fas]: https://api.chn.eniac.dev.cray.com/apis/fas/v1/snapshots - 404
PASS - [cray-hbtd]: https://api.chn.eniac.dev.cray.com/apis/hbtd/hmi/v1/health - 404
PASS - [cray-hmnfd]: https://api.chn.eniac.dev.cray.com/apis/hmnfd/hmi/v2/health - 404
PASS - [cray-ims]: https://api.chn.eniac.dev.cray.com/apis/ims/images - 404
PASS - [cray-powerdns-manager]: https://api.chn.eniac.dev.cray.com/apis/powerdns-manager/v1/liveness - 404
PASS - [cray-reds]: https://api.chn.eniac.dev.cray.com/apis/reds/v1/liveness - 404
PASS - [cray-scsd]: https://api.chn.eniac.dev.cray.com/apis/scsd/v1/health - 404
PASS - [cray-sls]: https://api.chn.eniac.dev.cray.com/apis/sls/v1/health - 404
PASS - [cray-smd]: https://api.chn.eniac.dev.cray.com/apis/smd/hsm/v1/service/ready - 404
PASS - [cray-sts]: https://api.chn.eniac.dev.cray.com/apis/sts/healthz - 404
PASS - [cray-uas-mgr]: https://api.chn.eniac.dev.cray.com/apis/uas-mgr/v1/images - 404
SKIP - [nmdv2-service]: https://api.chn.eniac.dev.cray.com/apis/v2/nmd/dumps
SKIP - [slingshot-fabric-manager]: https://api.chn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies
SKIP - [sma-telemetry]: https://api.chn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping

Getting token for chn
auth.chn.eniac.dev.cray.com is reachable
Token successfully retrieved at https://auth.chn.eniac.dev.cray.com/keycloak/realms/shasta/protocol/openid-connect/token


------------- api-gw-service-nmn.local -------------------
api-gw-service-nmn.local is NOT reachable
nmnlb is not reachable and is not expected to be

------------- api.cmn.eniac.dev.cray.com -------------------
api.cmn.eniac.dev.cray.com is NOT reachable
cmn is not reachable and is not expected to be

------------- api.can.eniac.dev.cray.com -------------------
api.can.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.can.eniac.dev.cray.com/apis/bos/v1/session - 404
PASS - [cray-bss]: https://api.can.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 404
PASS - [cray-capmc]: https://api.can.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 404
PASS - [cray-cfs-api]: https://api.can.eniac.dev.cray.com/apis/cfs/v2/sessions - 404
PASS - [cray-console-data]: https://api.can.eniac.dev.cray.com/apis/consoledata/liveness - 404
PASS - [cray-console-node]: https://api.can.eniac.dev.cray.com/apis/console-node/console-node/liveness - 404
PASS - [cray-console-operator]: https://api.can.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 404
SKIP - [cray-cps]: https://api.can.eniac.dev.cray.com/apis/v2/cps/contents
PASS - [cray-fas]: https://api.can.eniac.dev.cray.com/apis/fas/v1/snapshots - 404
PASS - [cray-hbtd]: https://api.can.eniac.dev.cray.com/apis/hbtd/hmi/v1/health - 404
PASS - [cray-hmnfd]: https://api.can.eniac.dev.cray.com/apis/hmnfd/hmi/v2/health - 404
PASS - [cray-ims]: https://api.can.eniac.dev.cray.com/apis/ims/images - 404
PASS - [cray-powerdns-manager]: https://api.can.eniac.dev.cray.com/apis/powerdns-manager/v1/liveness - 404
PASS - [cray-reds]: https://api.can.eniac.dev.cray.com/apis/reds/v1/liveness - 404
PASS - [cray-scsd]: https://api.can.eniac.dev.cray.com/apis/scsd/v1/health - 404
PASS - [cray-sls]: https://api.can.eniac.dev.cray.com/apis/sls/v1/health - 404
PASS - [cray-smd]: https://api.can.eniac.dev.cray.com/apis/smd/hsm/v1/service/ready - 404
PASS - [cray-sts]: https://api.can.eniac.dev.cray.com/apis/sts/healthz - 404
PASS - [cray-uas-mgr]: https://api.can.eniac.dev.cray.com/apis/uas-mgr/v1/images - 404
SKIP - [nmdv2-service]: https://api.can.eniac.dev.cray.com/apis/v2/nmd/dumps
SKIP - [slingshot-fabric-manager]: https://api.can.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies
SKIP - [sma-telemetry]: https://api.can.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping

------------- api.chn.eniac.dev.cray.com -------------------
api.chn.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.chn.eniac.dev.cray.com/apis/bos/v1/session - 404
PASS - [cray-bss]: https://api.chn.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 404
PASS - [cray-capmc]: https://api.chn.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 404
PASS - [cray-cfs-api]: https://api.chn.eniac.dev.cray.com/apis/cfs/v2/sessions - 404
PASS - [cray-console-data]: https://api.chn.eniac.dev.cray.com/apis/consoledata/liveness - 404
PASS - [cray-console-node]: https://api.chn.eniac.dev.cray.com/apis/console-node/console-node/liveness - 404
PASS - [cray-console-operator]: https://api.chn.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 404
SKIP - [cray-cps]: https://api.chn.eniac.dev.cray.com/apis/v2/cps/contents
PASS - [cray-fas]: https://api.chn.eniac.dev.cray.com/apis/fas/v1/snapshots - 404
PASS - [cray-hbtd]: https://api.chn.eniac.dev.cray.com/apis/hbtd/hmi/v1/health - 404
PASS - [cray-hmnfd]: https://api.chn.eniac.dev.cray.com/apis/hmnfd/hmi/v2/health - 404
PASS - [cray-ims]: https://api.chn.eniac.dev.cray.com/apis/ims/images - 404
PASS - [cray-powerdns-manager]: https://api.chn.eniac.dev.cray.com/apis/powerdns-manager/v1/liveness - 404
PASS - [cray-reds]: https://api.chn.eniac.dev.cray.com/apis/reds/v1/liveness - 404
PASS - [cray-scsd]: https://api.chn.eniac.dev.cray.com/apis/scsd/v1/health - 404
PASS - [cray-sls]: https://api.chn.eniac.dev.cray.com/apis/sls/v1/health - 404
PASS - [cray-smd]: https://api.chn.eniac.dev.cray.com/apis/smd/hsm/v1/service/ready - 404
PASS - [cray-sts]: https://api.chn.eniac.dev.cray.com/apis/sts/healthz - 404
PASS - [cray-uas-mgr]: https://api.chn.eniac.dev.cray.com/apis/uas-mgr/v1/images - 404
SKIP - [nmdv2-service]: https://api.chn.eniac.dev.cray.com/apis/v2/nmd/dumps
SKIP - [slingshot-fabric-manager]: https://api.chn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies
SKIP - [sma-telemetry]: https://api.chn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping

Overall Gateway Test Status:  PASS

Deleting UAI uai-vers-733eea45
results = [ "Successfully deleted uai-vers-733eea45",]
```
