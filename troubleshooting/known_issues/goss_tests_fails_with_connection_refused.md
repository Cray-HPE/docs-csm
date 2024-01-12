# Goss Test Fails with Connection Refused

## Table of contents

- [Introduction](#introduction)
- [Example Error](#example-error)
- [Examining the problem](#examining-the-problem)
- [Resolution](#resolution)
- [Other possible causes of this error](#other-possible-causes-of-this-error)

## Introduction

Follow this procedure when a goss-test fails with `Failed to establish a new connection: [Errno 111] Connection refused`.

## Example Error

An example of this error can be seen below.

```bash
ERROR: Error encountered running http://ncn-s003.hmn:8997/ncn-healthcheck-storage tests: Unexpected error attempting GET request to http://ncn-s003.hmn:8997/ncn-healthcheck-storage:
ConnectionError: HTTPConnectionPool(host='ncn-s003.hmn', port=8997): Max retries exceeded with url: /ncn-healthcheck-storage (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7f8890320a58>: Failed to establish a new connection: [Errno 111] Connection refused',))
ERROR: Skipping http://ncn-s003.hmn:8997/ncn-healthcheck-storage due to error
ERROR: Error encountered running http://ncn-s003.hmn:8999/ncn-afterpitreboot-healthcheck-storage tests: Unexpected error attempting GET request to http://ncn-s003.hmn:8999/ncn-afterpitreboot-healthcheck-storage: ConnectionError: HTTPConnectionPool(host='ncn-s003.hmn', port=8999):
Max retries exceeded with url: /ncn-afterpitreboot-healthcheck-storage (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7f88902ecd68>: Failed to establish a new connection: [Errno 111] Connection refused',))
ERROR: Skipping http://ncn-s003.hmn:8999/ncn-afterpitreboot-healthcheck-storage due to error
```

## Examining the problem

This error means that not all goss tests on the NCN are available via the goss servers. This can be seen by comparing the output from
`systemctl status goss-servers` on multiple nodes of the same type (i.e. storage, master, worker). The node with the error will
have less entries under `CGroup`. An example of output from a node with and without this error can be seen below.

If the error is on `ncn-s003`, the following might be seen when running `systemctl status goss-servers` on `ncn-s003`.

```bash
ncn-s003:~ # systemctl status goss-servers
● goss-servers.service - goss-servers
     Loaded: loaded (/etc/systemd/system/goss-servers.service; enabled; vendor preset: disabled)
     Active: active (running) since Sun 2023-12-03 18:14:10 UTC; 1 week 4 days ago
   Main PID: 6590 (bash)
      Tasks: 14
     CGroup: /system.slice/goss-servers.service
             ├─6590 /bin/bash /usr/sbin/start-goss-servers.sh
             ├─6654 /usr/bin/goss -g /opt/cray/tests/install/ncn/suites/ncn-preflight-tests.yaml --vars /tmp/goss-variables-1701627250-GrTf8J-temp.yaml serve --format json --max-concurrent 4 --endpoint /ncn-preflight-tests --listen-addr 10.254.1.22:8994
             ├─6655 /usr/bin/goss -g /opt/cray/tests/install/ncn/suites/ncn-smoke-tests.yaml --vars /tmp/goss-variables-1701627250-GrTf8J-temp.yaml serve --format json --max-concurrent 4 --endpoint /ncn-smoke-tests --listen-addr 10.254.1.22:8995
             └─6660 sleep infinity
```

On another storage node without this error, there would be more entries in `CGroup` when running `systemctl status goss-servers` on that node.

```bash
ncn-s001:~ # systemctl status goss-servers
● goss-servers.service - goss-servers
     Loaded: loaded (/etc/systemd/system/goss-servers.service; enabled; vendor preset: disabled)
     Active: active (running) since Fri 2023-12-01 20:00:46 UTC; 1 week 6 days ago
   Main PID: 169809 (bash)
      Tasks: 92
     CGroup: /system.slice/goss-servers.service
             ├─169809 /bin/bash /usr/sbin/start-goss-servers.sh
             ├─169889 /usr/bin/goss -g /opt/cray/tests/install/ncn/suites/ncn-preflight-tests.yaml --vars /tmp/goss-variables-1701460846-P7yxMI-temp.yaml serve --format json --max-concurrent 4 --endpoint /ncn-preflight-tests --listen-addr 10.254.1.18:8994
             ├─169890 /usr/bin/goss -g /opt/cray/tests/install/ncn/suites/ncn-smoke-tests.yaml --vars /tmp/goss-variables-1701460846-P7yxMI-temp.yaml serve --format json --max-concurrent 4 --endpoint /ncn-smoke-tests --listen-addr 10.254.1.18:8995
             ├─169891 /usr/bin/goss -g /opt/cray/tests/install/ncn/suites/ncn-spire-healthchecks.yaml --vars /tmp/goss-variables-1701460846-P7yxMI-temp.yaml serve --format json --max-concurrent 4 --endpoint /ncn-spire-healthchecks --listen-addr 10.254.1.18:8996
             ├─169892 /usr/bin/goss -g /opt/cray/tests/install/ncn/suites/ncn-healthcheck-storage.yaml --vars /tmp/goss-variables-1701460846-P7yxMI-temp.yaml serve --format json --max-concurrent 4 --endpoint /ncn-healthcheck-storage --listen-addr 10.254.1.18:8997
             ├─169893 /usr/bin/goss -g /opt/cray/tests/install/ncn/suites/ncn-afterpitreboot-healthcheck-storage.yaml --vars /tmp/goss-variables-1701460846-P7yxMI-temp.yaml serve --format json --max-concurrent 4 --endpoint /ncn-afterpitreboot-healthcheck-storage --listen-addr 10.254.1.18:8999
             ├─169894 /usr/bin/goss -g /opt/cray/tests/install/ncn/suites/ncn-storage-tests.yaml --vars /tmp/goss-variables-1701460846-P7yxMI-temp.yaml serve --format json --max-concurrent 4 --endpoint /ncn-storage-tests --listen-addr 10.254.1.18:9004
             └─169919 sleep infinity
```

## Resolution

To resolve this problem, simply restart goss-servers **on the node with the error**.

```bash
systemctl restart goss-servers
```

After restarting goss-servers, rerun `systemctl status goss-servers` to make sure there are the same number entries in `CGroup`
as seen on a node without this problem.

## Other possible causes of this error

If the above resolution did not fix the problem, there are two other possible causes of this issue.

1. There is a `yaml` error in the test that is trying to be run. Evaluate the `yaml` file that is being run for any errors.

1. The goss tests were not able to load which can indicate a downlevel csm-testing RPM. Make sure that the correct versions of `csm-testing` and `goss-servers` rpm are installed on all NCNs. Run the following command on all NCNs.

    ```bash
    rpm -qa goss-servers csm-testing
    ```
