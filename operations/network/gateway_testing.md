# Gateway Testing

With the introduction of BiCAN, service APIs are now available on one or more networks depending on who is allowed access to the services and from where.
The services are accessed via three different ingress gateways using a token that can be retrieved from keycloak.

This page describes how to run a set of tests to determine if the gateways are functioning properly. The gateway test will obtain an API token from Keycloak and then use that token to attempt to access a set of service APIs on one or more networks as defined in the gateway test definition file (`gateway-test-defn.yaml`). The test will check the return code to make sure it gets the expected response.

When the nmnlb network is specified, it will use `api-gw-service-nmn.local` as an override for `nmnlb.<system-domain>` in 1.2. You can set `use-api-gw-override: false` in gateway-test-defn.yaml if you would like to disable that override and use `nmnlb.<system-domain>`.

## Running gateway tests from an NCN

The gateway test script can be found in `/usr/share/doc/csm/scripts/operations/gateway-test`. When `gateway-test.py` is run from an NCN, it has access to the admin client secret using `kubectl`. It will use the admin client secret to get the token for accessing the APIs.

You can run the test by executing the following command. You will need to specify the system domain (for example, `eniac.dev.cray.com`) and the network you would like to use to obtain the token (for example, `nmnlb`, `can`, `cmn`, or `chn`)

```bash
ncn# /usr/share/doc/csm/scripts/operations/gateway-test/gateway-test.py eniac.dev.cray.com nmnlb
```

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

You can run the tests by executing the following the command. You will need to specify the system domain (e.g. eniac.dev.cray.com) and the network you would like to use to obtain the token (e.g. nmnlb, can.cmn, chn).

```bash
linux# /usr/share/doc/csm/scripts/operations/gateway-test/gateway-test.py eniac.dev.cray.com cmn
```

## Example results

The results of running the tests will show the following

* Retrieval of a token on the CMN network in order to get SLS data to determine which networks are defined on the system
* Retrieval of a token on the network specified on the command line to use for testing the APIs
* Results from each of the networks defined in `gateway-test-defn.yaml`. It will attempt to access each of the services on the network and check the expected results.
  * It will show PASS or FAIL depending on the expected response for the service and the token being used.
  * It will show SKIP for services that are not expected to be installed on the system.
* The return code of the test will be non-zero if any of the tests fail or we are unable to retrieve a token on any of the networks that are expected to be accessible.

NOTE: In this example we are running from a server outside the cluster. It is expected that `api-gw-service-nmn.local` is unreachable from this location.

```bash
# export ADMIN_CLIENT_SECRET=26947343-d4ab-403b-14e937dbd700
# ./gateway-test.py eniac.dev.cray.com cmn
auth.cmn.eniac.dev.cray.com is reachable
Token successfully retrieved at https://auth.cmn.eniac.dev.cray.com/keycloak/realms/shasta/protocol/openid-connect/token

auth.cmn.eniac.dev.cray.com is reachable
Token successfully retrieved at https://auth.cmn.eniac.dev.cray.com/keycloak/realms/shasta/protocol/openid-connect/token


------------- api-gw-service-nmn.local -------------------
ping: api-gw-service-nmn.local: Name or service not known
api-gw-service-nmn.local is NOT reachable

------------- api.cmn.eniac.dev.cray.com -------------------
api.cmn.eniac.dev.cray.com is reachable
PASS - [cray-bos]: https://api.cmn.eniac.dev.cray.com/apis/bos/v1/session - 200
PASS - [cray-bss]: https://api.cmn.eniac.dev.cray.com/apis/bss/boot/v1/bootparameters - 200
FAIL - [cray-capmc]: https://api.cmn.eniac.dev.cray.com/apis/capmc/capmc/get_node_rules - 404
PASS - [cray-cfs-api]: https://api.cmn.eniac.dev.cray.com/apis/cfs/v2/sessions - 200
PASS - [cray-console-data]: https://api.cmn.eniac.dev.cray.com/apis/consoledata/liveness - 204
PASS - [cray-console-node]: https://api.cmn.eniac.dev.cray.com/apis/console-node/console-node/liveness - 204
PASS - [cray-console-operator]: https://api.cmn.eniac.dev.cray.com/apis/console-operator/console-operator/liveness - 204
SKIP - [cray-cps]: https://api.cmn.eniac.dev.cray.com/apis/v2/cps/contents
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
PASS - [gitea-vcs-web]: https://api.cmn.eniac.dev.cray.com/vcs - 200
SKIP - [nmdv2-service]: https://api.cmn.eniac.dev.cray.com/apis/v2/nmd/dumps
SKIP - [slingshot-fabric-manager]: https://api.cmn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies
SKIP - [sma-telemetry]: https://api.cmn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping

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
PASS - [gitea-vcs-web]: https://api.can.eniac.dev.cray.com/vcs - 404
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
PASS - [gitea-vcs-web]: https://api.chn.eniac.dev.cray.com/vcs - 404
SKIP - [nmdv2-service]: https://api.chn.eniac.dev.cray.com/apis/v2/nmd/dumps
SKIP - [slingshot-fabric-manager]: https://api.chn.eniac.dev.cray.com/apis/fabric-manager/fabric/port-policies
SKIP - [sma-telemetry]: https://api.chn.eniac.dev.cray.com/apis/sma-telemetry-api/v1/ping
 # echo $?
1
```
