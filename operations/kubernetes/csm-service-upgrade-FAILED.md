# csm-service-upgrade FAILED
## _timed out waiting for the condition on jobs/cray-dns-unbound-manager_


This document show how to resolve issue when upgrade CSM 1.0.0-rc.2 to 1.0.11, running the csm-service-upgrade.sh script. .

Items below will be part of this document:
- Issue representation
- Solution
- Long Term Solution


## Issue

```sh
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Releasing cray-dns-unbound v0.4.12
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2022-04-18T23:35:28Z INF Found value overrides for chart, applying:
forwardZones:
- forwardIps:
  - 172.30.84.40
  name: .
global:
  appVersion: 0.4.12
 chart=cray-dns-unbound command=ship namespace=services version=0.4.12
2022-04-18T23:35:28Z INF Running helm install/upgrade with arguments: upgrade --install cray-dns-unbound helm/cray-dns-unbound-0.4.12.tgz --namespace services --create-namespace --set global.chart.name=cray-dns-unbound --set global.chart.version=0.4.12 -f /tmp/loftsman-1650324903/cray-dns-unbound-values.yaml chart=cray-dns-unbound command=ship namespace=services version=0.4.12
2022-04-18T23:36:36Z INF Release "cray-dns-unbound" has been upgraded. Happy Helming!
NAME: cray-dns-unbound
LAST DEPLOYED: Mon Apr 18 23:35:28 2022
NAMESPACE: services
STATUS: deployed
REVISION: 23
TEST SUITE: None
 chart=cray-dns-unbound command=ship namespace=services version=0.4.12
2022-04-18T23:36:36Z INF Ship status: success. Recording status, manifest to configmap loftsman-core-services in namespace loftsman command=ship
2022-04-18T23:36:36Z INF Recording log data to configmap loftsman-core-services-ship-log in namespace loftsman command=ship
+ ./lib/wait-for-unbound.sh
+ kubectl wait -n services job cray-sls-init-load --for=condition=complete --timeout=20m
job.batch/cray-sls-init-load condition met
+ kubectl wait -n services deployment cray-dns-unbound --for=condition=available --timeout=20m
deployment.apps/cray-dns-unbound condition met
+ kubectl wait -n services job cray-dns-unbound-coredns --for=condition=complete --timeout=20m
job.batch/cray-dns-unbound-coredns condition met
+ export -f poll-saw-completed-job
+ timeout 20m bash -c 'set -exo pipefail; poll-saw-completed-job'
+ poll-saw-completed-job
++ jq '.items | length'
++ kubectl get event -n services --field-selector involvedObject.kind=CronJob,involvedObject.name=cray-dns-unbound-manager,reason=SawCompletedJob -o json
+ [[ 2 -eq 0 ]]
+ kubectl wait -n services job -l cronjob-name=cray-dns-unbound-manager --for=condition=complete --timeout=5m
job.batch/cray-dns-unbound-manager-1650322800 condition met
job.batch/cray-dns-unbound-manager-1650322980 condition met
job.batch/cray-dns-unbound-manager-1650323160 condition met
timed out waiting for the condition on jobs/cray-dns-unbound-manager-1650323280
timed out waiting for the condition on jobs/cray-dns-unbound-manager-1650324240
[ERROR] - Unexpected errors, check output above
/tmp
CSM Service upgrade failed after 3 retries
```


## Solution

The cause of this failure is the unbound-manager job failing, it can be checking looking to the pods.
Look for the failed unbound pod.

```sh
ncn-m001:~ # kubectl get pod -A | grep unbound
services            cray-dns-unbound-68cb6d759b-2r68h                                 2/2     Running            0          5d22h
services            cray-dns-unbound-68cb6d759b-9vxbk                                 2/2     Running            0          4d15h
services            cray-dns-unbound-68cb6d759b-x7j6d                                 2/2     Running            0          6d17h
services            cray-dns-unbound-7d845ddf8b-4dgcl                                 1/2     Running            0          14h
services            cray-dns-unbound-7d845ddf8b-r6nxt                                 1/2     Running            0          14h
services            cray-dns-unbound-7d845ddf8b-w4hgf                                 1/2     Running            0          14h
services            cray-dns-unbound-coredns-4t45h                                    0/2     Completed          0          13h
services            cray-dns-unbound-manager-1650322800-vn26p                         0/2     Completed          0          14h
services            cray-dns-unbound-manager-1650322980-hhfsr                         0/2     Completed          0          14h
services            cray-dns-unbound-manager-1650323160-lsts5                         0/2     Completed          0          14h
services            cray-dns-unbound-manager-1650373560-47fxg                         0/2     Completed          0          14m
services            cray-dns-unbound-manager-1650373560-4zsv7                         0/2     Completed          0          11m
services            cray-dns-unbound-manager-1650373560-8cpq6                         0/2     Completed          0          19m
services            cray-dns-unbound-manager-1650373560-977xb                         0/2     Completed          0          7m40s
services            cray-dns-unbound-manager-1650373560-wsnl5                         0/2     Completed          0          16m
services            cray-dns-unbound-manager-1650374520-mq4wk                         0/2     Completed          0          4m57s
services            cray-dns-unbound-manager-1650374520-tdhsl                         1/2     Error              0          2m14s
```

Continuing the troubleshootng and looking for most recent log we can understand that it can't talk to Kea.

```sh
ncn-m001:~ # kubectl -n services logs cray-dns-unbound-manager-1650374520-tdhsl -c manager
2022-04-19 13:24:53,530 - __main__ - INFO - Querying Kea in the cluster to find any updated records we need to set
Traceback (most recent call last):
  File "/usr/lib/python3.8/site-packages/requests/adapters.py", line 439, in send
    resp = conn.urlopen(
  File "/usr/lib/python3.8/site-packages/urllib3/connectionpool.py", line 846, in urlopen
    return self.urlopen(
  File "/usr/lib/python3.8/site-packages/urllib3/connectionpool.py", line 846, in urlopen
    return self.urlopen(
  File "/usr/lib/python3.8/site-packages/urllib3/connectionpool.py", line 846, in urlopen
    return self.urlopen(
  [Previous line repeated 7 more times]
  File "/usr/lib/python3.8/site-packages/urllib3/connectionpool.py", line 836, in urlopen
    retries = retries.increment(method, url, response=response, _pool=self)
  File "/usr/lib/python3.8/site-packages/urllib3/util/retry.py", line 573, in increment
    raise MaxRetryError(_pool, url, error or ResponseError(cause))
urllib3.exceptions.MaxRetryError: HTTPConnectionPool(host='cray-dhcp-kea-api', port=8000): Max retries exceeded with url: / (Caused by ResponseError('too many 503 error responses'))

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/srv/unbound/manager.py", line 573, in <module>
    main()
  File "/srv/unbound/manager.py", line 167, in main
    resp = kea_api('POST', '/', headers=kea_headers, json=kea_request)
  File "/srv/unbound/manager.py", line 83, in __call__
    response = http.request(method=method, url=url, headers=headers, **kwargs)
  File "/usr/lib/python3.8/site-packages/requests/sessions.py", line 542, in request
    resp = self.send(prep, **send_kwargs)
  File "/usr/lib/python3.8/site-packages/requests/sessions.py", line 655, in send
    r = adapter.send(request, **kwargs)
  File "/usr/lib/python3.8/site-packages/requests/adapters.py", line 507, in send
    raise RetryError(e, request=request)
requests.exceptions.RetryError: HTTPConnectionPool(host='cray-dhcp-kea-api', port=8000): Max retries exceeded with url: / (Caused by ResponseError('too many 503 error responses'))
```
Looking for the Kea we noticed that is also in bad state, it is reporting "failed to select a subnet...." messages meaning it hasn't loaded the config.

```sh
ncn-m001:~ # kubectl -n services logs cray-dhcp-kea-84b4dd8c5d-ng4mc -c cray-dhcp-kea | head
2022-04-19 13:29:25.948 ERROR [kea-dhcp4.bad-packets/14.139702139406208] DHCP4_PACKET_NAK_0001 [hwtype=1 00:40:a6:83:51:a6], cid=[ff:a6:83:51:a6:00:01:00:01:29:ea:f0:a5:00:40:a6:83:51:a6], tid=0x4cef7c4: failed to select a subnet for incoming packet, src 10.2.0.5, type DHCPDISCOVER
2022-04-19 13:29:25.999 ERROR [kea-dhcp4.bad-packets/14.139702139406208] DHCP4_PACKET_NAK_0001 [hwtype=1 00:40:a6:83:51:48], cid=[ff:a6:83:51:48:00:01:00:01:29:ea:f0:76:00:40:a6:83:51:48], tid=0x4ec73527: failed to select a subnet for incoming packet, src 10.2.0.5, type DHCPDISCOVER
2022-04-19 13:29:26.023 ERROR [kea-dhcp4.bad-packets/14.139702139406208] DHCP4_PACKET_NAK_0001 [hwtype=1 00:40:a6:83:02:8b], cid=[ff:a6:83:02:8b:00:01:00:01:29:ea:f0:65:00:40:a6:83:02:8b], tid=0x18dba25f: failed to select a subnet for incoming packet, src 10.2.0.5, type DHCPDISCOVER
```


Kea is getting a 503 when trying to communicate with SLS so it can't retrieve the list of networks to build the configuration
```sh
/ $ /srv/kea/dhcp-helper.py
ERROR: 503 Server Error: Service Unavailable for url: http://cray-sls/v1/search/hardware?type=comptype_cabinet
```

Checking SLS and its running fine.

```sh
ncn-m001:~ # cray sls dumpstate list --format json | head
{
  "Hardware": {
    "d0w1": {
      "Parent": "d0",
      "Xname": "d0w1",
      "Type": "comptype_cdu_mgmt_switch",
      "Class": "Mountain",
      "TypeString": "CDUMgmtSwitch",
      "LastUpdated": 1618431190,
      "LastUpdatedTime": "2021-04-14 20:13:10.082771 +0000 +0000",
      
```
It can't be queried from the Kea pod

```sh
$ curl http://cray-sls/v1/search/hardware?type=comptype_cabinet
upstream connect error or disconnect/reset before headers. reset reason: connection failure
```

The same query from Unbound works OK

```sh
$ curl http://cray-sls/v1/search/hardware?type=comptype_cabinet
[{"Parent":"s0","Children":["x3000c0r42b0","x3000c0r41b0","x3000c0r39b0","x3000m0","x3000c0r40b0"] 
```

Looks like the istio-proxy container of the cray-dhcp-kea pod isn't behaving correctly
```sh
ncn-m001:~ # kubectl -n services logs cray-dhcp-kea-84b4dd8c5d-ng4mc -c istio-proxy --tail=10
[2022-04-19T13:35:23.864Z] "POST / HTTP/1.1" 503 UF,URX "-" "TLS error: Secret is not supplied by SDS" 52 91 18 - "-" "curl/7.79.1" "622c1d7d-b9bf-4fea-9bc2-28dfe57ae9f0" "cray-dhcp-kea-api:8000" "10.37.0.73:8000" outbound|8000||cray-dhcp-kea-api.services.svc.cluster.local - 10.27.72.242:8000 10.37.0.73:58716 - default
[2022-04-19T13:35:25.005Z] "GET /metrics HTTP/1.1" 503 UF "-" "-" 0 91 0 - "-" "Prometheus/2.18.1" "272cb1cb-483d-4c18-bb25-924a7023ce15" "10.37.0.73:8080" "127.0.0.1:8080" inbound|8080|exporter|cray-sysmgmt-health-dhcp-kea-exporter.services.svc.cluster.local - 10.37.0.73:8080 10.43.0.71:49934 - default
[2022-04-19T13:35:55.308Z] "GET /metrics HTTP/1.1" 503 UF "-" "-" 0 91 0 - "-" "Prometheus/2.18.1" "9a73fa92-2357-4b67-9901-4920ec54c72a" "10.37.0.73:8080" "127.0.0.1:8080" inbound|8080|exporter|cray-sysmgmt-health-dhcp-kea-exporter.services.svc.cluster.local - 10.37.0.73:8080 10.43.0.71:49934 - default
[2022-04-19T13:36:07.206Z] "POST / HTTP/1.1" 503 UF,URX "-" "TLS error: Secret is not supplied by SDS" 52 91 42 - "-" "curl/7.79.1" "711361e4-13a1-4457-b80b-3315ee42d460" "cray-dhcp-kea-api:8000" "10.37.0.73:8000" outbound|8000||cray-dhcp-kea-api.services.svc.cluster.local - 10.27.72.242:8000 10.37.0.73:60928 - default
[2022-04-19T13:36:18.716Z] "POST / HTTP/1.1" 503 UF,URX "-" "TLS error: Secret is not supplied by SDS" 52 91 45 - "-" "curl/7.79.1" "120f0e1a-4aec-4135-b466-cd87b5bf41e6" "cray-dhcp-kea-api:8000" "10.37.0.73:8000" outbound|8000||cray-dhcp-kea-api.services.svc.cluster.local - 10.27.72.242:8000 10.37.0.73:33464 - default
[2022-04-19T13:36:23.852Z] "POST / HTTP/1.1" 503 UF,URX "-" "TLS error: Secret is not supplied by SDS" 52 91 53 - "-" "curl/7.79.1" "e2626e00-6537-4e55-9830-fcaf10805cf1" "cray-dhcp-kea-api:8000" "10.37.0.73:8000" outbound|8000||cray-dhcp-kea-api.services.svc.cluster.local - 10.27.72.242:8000 10.37.0.73:33558 - default
[2022-04-19T13:36:25.005Z] "GET /metrics HTTP/1.1" 503 UF "-" "-" 0 91 0 - "-" "Prometheus/2.18.1" "cd8d304f-714b-4178-b1d1-69720fb7b5c3" "10.37.0.73:8080" "127.0.0.1:8080" inbound|8080|exporter|cray-sysmgmt-health-dhcp-kea-exporter.services.svc.cluster.local - 10.37.0.73:8080 10.43.0.71:49934 - default
[2022-04-19T13:36:55.005Z] "GET /metrics HTTP/1.1" 503 UF "-" "-" 0 91 0 - "-" "Prometheus/2.18.1" "040b2e40-896b-49f9-9b2a-06861c58de8a" "10.37.0.73:8080" "127.0.0.1:8080" inbound|8080|exporter|cray-sysmgmt-health-dhcp-kea-exporter.services.svc.cluster.local - 10.37.0.73:8080 10.43.0.71:49934 - default
[2022-04-19T13:37:07.186Z] "POST / HTTP/1.1" 503 UF,URX "-" "TLS error: Secret is not supplied by SDS" 52 91 26 - "-" "curl/7.79.1" "6407b6fd-3b1b-4d4b-9685-23b42b962a08" "cray-dhcp-kea-api:8000" "10.37.0.73:8000" outbound|8000||cray-dhcp-kea-api.services.svc.cluster.local - 10.27.72.242:8000 10.37.0.73:35484 - default
[2022-04-19T13:37:18.718Z] "POST / HTTP/1.1" 503 UF,URX "-" "TLS error: Secret is not supplied by SDS" 52 91 18 - "-" "curl/7.79.1" "5ee53ea6-a8fc-4cb6-9887-c196626f74d8" "cray-dhcp-kea-api:8000" "10.37.0.73:8000" outbound|8000||cray-dhcp-kea-api.services.svc.cluster.local - 10.27.72.242:8000 10.37.0.73:36314 - default
```
This issue was related to istio/envoy known issue that can be found at https://github.com/istio/istio/issues/26468

**Simply restarting cray-dhcp-kea should resolve this**

## Long Term Solution

Upgrade to CSM 1.2 which has newer Istio version and this bug resolved.