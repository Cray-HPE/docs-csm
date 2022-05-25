# Troubleshoot Liveliness or Readiness Probe Failures

Identify and troubleshoot Readiness or Liveliness probes that report services as unhealthy intermittently.

This is a known issue and can be classified into two categories, connection refused and client timeout. Both categories are shown in the procedure below. The commands in this procedure assume the user is logged into either a master or worker non-compute node \(NCN\).

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Troubleshoot a refused connection.

    ```bash
    ncn-w001# kubectl get events -A | grep -i unhealthy | grep "connection refused"
    istio-system      5m24s       Warning   Unhealthy    pod/istio-pilot-68477d98d-5bsmk      Readiness probe failed: Get http://10.45.0.100:8080/ready: dial tcp 10.45.0.100:8080: connect: connection refused
    ```

    This may occur if the health check ran when the pod was being terminated. To confirm this is the case, check that the pod no longer exists. If that is true, disregard this unhealthy event.

    ```bash
    ncn-w001# kubectl get pod/istio-pilot-68477d98d-5bsmk -n istio-system
    Error from server (NotFound): pods "istio-pilot-68477d98d-5bsmk" not found
    ```

2.  Troubleshoot a client timeout.

    ```bash
    ncn-w001# kubectl get events -A | grep -i unhealthy | grep "Client.Timeout|DeadlineExceeded"
    services    40m         Warning   Unhealthy     pod/cray-bos-69f85bcd89-vdq52      Liveness probe failed: Get http://10.45.0.20:15020/app-health/cray-bos/livez: net/http: request canceled (Client.Timeout exceeded while awaiting headers)
    ```

    This may occur if the health check did not respond within the specified timeout. To confirm that the service is healthy, check the health using the curl command.

    ```bash
    ncn-w001# curl -i http://10.45.0.20:15020/app-health/cray-bos/livez
    HTTP/1.1 200 OK
    Date: Tue, 07 Jul 2020 19:37:32 GMT
    Content-Length: 0
    ```

    An HTTP Response of 2\*\* or 3\*\* from the curl test is considered success. For example, a response of 200 OK.


If there is an unhealthy event where the pod still exists and the curl test still fails, please contact support.

