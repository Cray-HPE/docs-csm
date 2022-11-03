# Troubleshoot Liveliness or Readiness Probe Failures

Identify and troubleshoot Readiness or Liveliness probes that report services as unhealthy intermittently.

This is a known issue and can be classified into two categories, connection refused and client timeout.
The commands in this procedure assume the user is logged into either a master or worker non-compute node \(NCN\).

- [Troubleshoot a refused connection](#troubleshoot-a-refused-connection)
  - [Refused connection - symptom](#refused-connection---symptom)
  - [Refused connection - procedure](#refused-connection---procedure)
- [Troubleshoot a client timeout](#troubleshoot-a-client-timeout)
  - [Client timeout - symptom](#client-timeout---symptom)
  - [Client timeout - procedure](#client-timeout---procedure)
- [Next steps](#next-steps)

## Troubleshoot a refused connection

### Refused connection - symptom

(`ncn-mw#`) The symptom of this problem is a `connection refused` message in the event log.

```bash
kubectl get events -A | grep -i unhealthy | grep "connection refused"
```

Example output:

```text
istio-system      5m24s       Warning   Unhealthy    pod/istio-pilot-68477d98d-5bsmk      Readiness probe failed: Get http://10.45.0.100:8080/ready: dial tcp 10.45.0.100:8080: connect: connection refused
```

### Refused connection - procedure

This may occur if the health check ran when the pod was being terminated.

(`ncn-mw#`) To confirm that this is the case, check that the pod no longer exists. If that is true, then disregard this unhealthy event.

```bash
kubectl get pod/istio-pilot-68477d98d-5bsmk -n istio-system
```

Example output indicating that the pod no longer exists:

```text
Error from server (NotFound): pods "istio-pilot-68477d98d-5bsmk" not found
```

## Troubleshoot a client timeout

### Client timeout - symptom

(`ncn-mw#`) The symptom of this problem is a `Client.Timeout` or `DeadlineExceeded` message in the event log.

```bash
kubectl get events -A | grep -i unhealthy | grep -E "Client[.]Timeout|DeadlineExceeded"
```

Example output indicating this issue:

```text
services    40m         Warning   Unhealthy     pod/cray-bos-69f85bcd89-vdq52      Liveness probe failed: Get http://10.45.0.20:15020/app-health/cray-bos/livez: net/http: request canceled (Client.Timeout exceeded while awaiting headers)
```

### Client timeout - procedure

This may occur if the health check did not respond within the specified timeout.

(`ncn-mw#`) To confirm that the service is healthy, check the health using the `curl` command.

```bash
curl -i http://10.45.0.20:15020/app-health/cray-bos/livez
```

Example output of a healthy service:

```text
HTTP/1.1 200 OK
Date: Tue, 07 Jul 2020 19:37:32 GMT
Content-Length: 0
```

An HTTP response code in the 200's or 300's is considered success. For example, a response of `200 OK`.

## Next steps

If there is an unhealthy event where the above procedures do not clarify the issue, then contact support.
