# Troubleshoot Intermittent HTTP 503 Code Failures

There are cases where API calls or `cray` command invocations will fail (sometimes intermittently) with an HTTP 503 error code.
In the event that this occurs, attempt to remediate the issue by taking the following actions, according to specific error codes
found in the pod or Envoy container log.

(`ncn-mw#`) The Envoy container is typically named `istio-proxy`, and it runs as a sidecar for pods that are part of the Istio mesh.
For pods with this sidecar, the logs can be viewed by running a command similar to the following:

```bash
kubectl logs <podname> -n <namespace> -c istio-proxy | grep 503
```

For general Kubernetes troubleshooting information, including more information on viewing pod logs, see
[Kubernetes troubleshooting topics](../../troubleshooting/README.md#kubernetes).

This page is broken into different sections, based on the errors found in the log.

- [`UF,URX` with TLS error](#ufurx-with-tls-error)
  - [Symptom](#symptom-ufurx-with-tls-error)
  - [Description](#description-ufurx-with-a-tls-error)
  - [Remediation](#remediation-ufurx-with-a-tls-error)
- [`UAEX`](#uaex)
  - [Symptom](#symptom-uaex)
  - [Description](#description-uaex)
  - [Remediation](#remediation-uaex)
- [Other error codes](#other-error-codes)

## `UF,URX` with TLS error

### Symptom (`UF,URX` with TLS error)

```text
[2022-05-10T16:27:29.232Z] "POST /apis/hbtd/hmi/v1/heartbeat HTTP/2" 503 UF,URX "-" "TLS error: Secret is not supplied by SDS"
```

### Description (`UF,URX` with a TLS error)

Envoy containers can occasionally get into this state when NCNs are being rebooted or upgraded, as well as when many deployments
are being created.

### Remediation (`UF,URX` with a TLS error)

(`ncn-mw#`) Do a Kubernetes delete or rolling restart:

- If it is a single replica, then delete the pod.
- If it is part of a multiple replica exhibiting the issue, then perform a rolling restart of the deployment or `StatefulSet`.

    Here is an example of how to do that for the `istio-ingressgateway` deployment in the `istio-system` namespace.

    1. Initiate a rolling restart of the deployment.

        ```bash
        kubectl rollout restart -n istio-system deployment istio-ingressgateway
        ```

    1. Wait for the restart to complete.

        ```bash
        kubectl rollout status -n istio-system deployment istio-ingressgateway
        ```

Once the roll out is complete, or the new pod is running, then the HTTP 503 message should clear.

To ensure there are no further pods in this state you may run this script:

```bash
/usr/share/doc/csm/scripts/operations/known-issues.sh
```

If any pods are still affected by this specific issue the script will provide a list of `kubectl` delete commands that will need to be run.

## `UAEX`

### Symptom (`UAEX`)

```text
[2022-06-24T14:16:27.229Z] "POST /apis/hbtd/hmi/v1/heartbeat HTTP/2" 503 UAEX "-" 131 0 30 - "10.34.0.0" "-" "1797b0d3-56f0-4674-8cf2-a8a61f9adaea" "api-gw-service-nmn.local" "-" - - 10.40.0.29:443 10.34.0.0:15995 api-gw-service-nmn.local -
```

### Description (`UAEX`)

This error code typically indicates an issue with the authorization service (for example, Spire or OPA).

### Remediation (`UAEX`)

1. (`ncn-mw#`) Initiate a rolling restart of Istio and Spire.

    ```bash
    kubectl rollout restart -n istio-system deployment istio-ingressgateway
    kubectl rollout restart -n spire statefulset spire-postgres spire-server
    kubectl rollout restart -n spire daemonset spire-agent request-ncn-join-token
    kubectl rollout restart -n spire deployment spire-jwks spire-postgres-pooler
    kubectl rollout restart -n spire statefulset cray-spire-postgres cray-spire-server
    kubectl rollout restart -n spire daemonset cray-spire-agent
    kubectl rollout restart -n spire deployment cray-spire-jwks cray-spire-postgres-pooler
    ```

1. (`ncn-mw#`) Wait for Istio and Spire restarts to complete.

    ```bash
    kubectl rollout status -n istio-system deployment istio-ingressgateway
    kubectl rollout status -n spire statefulset spire-server
    kubectl rollout status -n spire daemonset spire-agent
    kubectl rollout status -n spire daemonset request-ncn-join-token
    kubectl rollout status -n spire deployment spire-jwks
    kubectl rollout status -n spire deployment spire-postgres-pooler
    kubectl rollout status -n spire statefulset cray-spire-server
    kubectl rollout status -n spire daemonset cray-spire-agent
    kubectl rollout status -n spire deployment cray-spire-jwks
    kubectl rollout status -n spire deployment cray-spire-postgres-pooler
    ```

1. (`ncn-mw#`) Initiate a rolling restart of OPA ingressgateway deployment (CSM 1.5.0) or daemonset (CSM 1.5.1 or later).

    1. For CSM 1.5.0:

    ```bash
    kubectl rollout restart -n opa deployment cray-opa-ingressgateway
    kubectl rollout status -n opa deployment cray-opa-ingressgateway
    ```

    1. For CSM 1.5.1 or later:

    ```bash
    kubectl rollout restart -n opa daemonset cray-opa-ingressgateway
    kubectl rollout status -n opa daemonset cray-opa-ingressgateway
    ```

Once the restarts are all complete, the HTTP 503 UAEX message should clear.

## Other error codes

Although the above codes are most common, various other issues such as networking or application errors can cause different errors in
the pod or sidecar logs. Refer to the [Envoy access log documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#)
for a list of possible Envoy response flags. In general, running a rolling restart of the application itself to see if it clears the error is a good practice.
If that does not resolve the problem, then an understanding of what the error message or response flag means is required to further troubleshoot the issue.
