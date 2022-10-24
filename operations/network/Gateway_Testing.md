# Gateway Testing

With the introduction of BiCAN, service APIs are now available on one or more networks depending on who is allowed
access to the services and from where. The services are accessed via three different ingress gateways using a token
that can be retrieved from Keycloak.

This page describes how to run a set of tests that determine if the gateways are functioning properly. The gateway test
will obtain an API token from Keycloak and then use that token to attempt to access a set of service APIs on one or
more networks, as defined in the gateway test definition file (`gateway-test-defn.yaml`). The test will check the
return code to make sure it gets the expected response.

## Topics

- [Running gateway tests on an NCN management node](#running-gateway-tests-on-an-ncn-management-node)
- [Running gateway tests on a UAN or compute node](#running-gateway-tests-on-a-uan-or-compute-node)
- [Running gateway tests on a UAI](#running-gateway-tests-on-a-uai)
- [Running gateway tests on a device outside the system](#running-gateway-tests-on-a-device-outside-the-system)
- [Example results](#example-results)

## Running gateway tests on an NCN management node

The gateway test scripts can be found in `/usr/share/doc/csm/scripts/operations/gateway-test`. When `gateway-test.py` is
run from an NCN, it has access to the admin client secret using `kubectl`. It will use the admin client secret to get
the token for accessing the APIs.

(`ncn#`) Execute the test by running following command.

```bash
/usr/share/doc/csm/scripts/operations/gateway-test/ncn-gateway-test.sh
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

For each network, the test will attempt to obtain a token from Keycloak. On an NCN, it should be able to get a token
from NMNLB, CMN, and either CAN or CHN depending on how the system is configured. It will then use that token to attempt to
access each of the services defined in `gateway-test-defn.yaml`, on each of the `test-networks`. The test will determine whether
it should or should not be able to access the service, and it will output a `PASS` or `FAIL` for each service, as appropriate.
At the end of the tests it will compile and output a final overall PASS/FAIL status.

## Running gateway tests on a UAN or compute node

The same set of tests will be run from a UAN or Compute Node by executing the following command from an NCN that has the `docs-csm` RPM installed. The hostname of the UAN or Compute Node under test must be specified.

Both scripts will fetch the admin client secret, the configured user network, and the site domain from the system.
It will use that information to generate a script that will be transferred to the UAN, executed, and removed.
The networks that should be accessible are different on a UAN versus a Compute node. The script will determine the networks
that should be accessible on the node based on the node type.

The test will determine whether it should or should not be able to access the service, and it will output a `PASS` or `FAIL`
for each service, as appropriate. At the end of the tests it will compile and output a final overall PASS/FAIL status.

### UAN test execution

(`ncn#`)

```bash
/usr/share/doc/csm/scripts/operations/gateway-test/uan-gateway-test.sh <uan-hostname>
```

### Compute node test execution

(`ncn#`)

```bash
/usr/share/doc/csm/scripts/operations/gateway-test/cn-gateway-test.sh <cn-hostname>
```

## Running gateway tests on a UAI

In order to test the gateways from a UAI, the `/usr/share/doc/csm/scripts/operations/gateway-test/uai-gateway-test.sh`
script is used.

This script will execute the following steps:

1. Create a UAI with a `cray-uai-gateway-test` image.
1. Pass the system domain, user network, and admin client secret to the test UAI.
1. Execute `gateway-test.py` on the node.
1. Output the results.
1. Delete the test UAI.

(`ncn#`) Run the test by executing the following command.

```bash
/usr/share/doc/csm/scripts/operations/gateway-test/uai-gateway-test.sh
```

The test will find the first UAI `cray-uai-gateway-test` image to create the test UAI. A different image may optionally
be specified by using the `--imagename` option.

## Running gateway tests on a device outside the system

The following steps must be performed on the system where the test is to be run:

1. `python3` must be installed (if it is not already).

1. Obtain the test code.

   There are two options for doing this:

   - Install the `docs-csm` RPM.

      See [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

   - Copy over the following files from a system where the `docs-csm` RPM is installed:

      - `/usr/share/doc/csm/scripts/operations/gateway-test/gateway-test.py`
      - `/usr/share/doc/csm/scripts/operations/gateway-test/gateway-test-defn.yaml`

1. (`ncn#`) Obtain the admin client secret.

   Because access to `kubectl` is not possible from outside of the cluster, obtain the admin client secret by running the
   following command on an NCN.

   ```bash
   kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d
   ```

   Example output:

   ```text
   26947343-d4ab-403b-14e937dbd700
   ```

1. (`linux#`) Export the admin client secret in an environment variable.

   Back on the system where the tests will be run, set and export the `ADMIN_CLIENT_SECRET` environment variable,
   using the `admin-client-auth` secret obtained in the previous step.

   ```bash
   export ADMIN_CLIENT_SECRET=26947343-d4ab-403b-14e937dbd700
   ```

1. (`linux#`) Execute the test.

   Execute the test by running following command. The system domain (in this example, `eniac.dev.cray.com`) must
   be specified.

   ```bash
   /usr/share/doc/csm/scripts/operations/gateway-test/gateway-test.py eniac.dev.cray.com outside
   ```

## Example results

The results of running the tests will show the following:

- Retrieval of a token on the CMN network; the token is used to get SLS data, which determines which user network is configured
  on the system.
  - If CMN is not accessible, then the test will get the user network from the command line.
- For each of the test networks defined in `gateway-test-defn.yaml`:
  - Retrieval of a token on the network under test.
  - It will attempt to access each of the services with the token and check the expected results.
    - It will show `PASS` or `FAIL` depending on the expected response for the service and the token being used.
    - It will show `SKIP` for services that are not expected to be installed on the system.
- The return code of `gateway-test.py` will be non-zero if any of the tests within it fail.

### Running from an NCN with CHN as the user network

(`ncn#`)

```bash
/usr/share/doc/csm/scripts/operations/gateway-test/gateway-test.py eniac.dev.cray.com
```

```text
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
PASS - [cray-smd]: https://api-gw-service-nmn.local/apis/smd/hsm/v2/service/ready - 200
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
PASS - [cray-smd]: https://api.cmn.eniac.dev.cray.com/apis/smd/hsm/v2/service/ready - 200
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
PASS - [cray-smd]: https://api.chn.eniac.dev.cray.com/apis/smd/hsm/v2/service/ready - 404
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
PASS - [cray-smd]: https://api-gw-service-nmn.local/apis/smd/hsm/v2/service/ready - 200
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
PASS - [cray-smd]: https://api.cmn.eniac.dev.cray.com/apis/smd/hsm/v2/service/ready - 200
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
PASS - [cray-smd]: https://api.chn.eniac.dev.cray.com/apis/smd/hsm/v2/service/ready - 404
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
PASS - [cray-smd]: https://api-gw-service-nmn.local/apis/smd/hsm/v2/service/ready - 403
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
PASS - [cray-smd]: https://api.cmn.eniac.dev.cray.com/apis/smd/hsm/v2/service/ready - 403
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
PASS - [cray-smd]: https://api.chn.eniac.dev.cray.com/apis/smd/hsm/v2/service/ready - 404
PASS - [cray-sts]: https://api.chn.eniac.dev.cray.com/apis/sts/healthz - 404
PASS - [cray-uas-mgr]: https://api.chn.eniac.dev.cray.com/apis/uas-mgr/v1/images - 404
SKIP - [nmdv2-service]: https://api.chn.eniac.dev.cray.com/apis/v2/nmd/dumps - virtual service not found
SKIP - [slingshot-fabric-manager]: https://api.chn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies - virtual service not found
SKIP - [sma-telemetry]: https://api.chn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping - virtual service not found

Overall Gateway Test Status:  PASS
```

### Running from a UAI

(`ncn#`)

```bash
/usr/share/doc/csm/scripts/operations/gateway-test/uai-gateway-test.sh
```

```text
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
PASS - [cray-smd]: https://api.can.eniac.dev.cray.com/apis/smd/hsm/v2/service/ready - 404
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
PASS - [cray-smd]: https://api.chn.eniac.dev.cray.com/apis/smd/hsm/v2/service/ready - 404
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
PASS - [cray-smd]: https://api.can.eniac.dev.cray.com/apis/smd/hsm/v2/service/ready - 404
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
PASS - [cray-smd]: https://api.chn.eniac.dev.cray.com/apis/smd/hsm/v2/service/ready - 404
PASS - [cray-sts]: https://api.chn.eniac.dev.cray.com/apis/sts/healthz - 404
PASS - [cray-uas-mgr]: https://api.chn.eniac.dev.cray.com/apis/uas-mgr/v1/images - 404
SKIP - [nmdv2-service]: https://api.chn.eniac.dev.cray.com/apis/v2/nmd/dumps
SKIP - [slingshot-fabric-manager]: https://api.chn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies
SKIP - [sma-telemetry]: https://api.chn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping

Overall Gateway Test Status:  PASS

Deleting UAI uai-vers-733eea45
results = [ "Successfully deleted uai-vers-733eea45",]
```
