# OAuth2 Proxy TLS Handshake Error

## Description

There is a known issue where the `cray-oauth2-proxies-customer-management-ingress` pod experiences TLS handshake errors that prevent proper SSL/TLS communication.
These errors manifest as "bad record MAC" messages in the pod logs. They can impact authentication and access to services through the customer management ingress.

The issue appears to be related to corrupted TLS state or configuration within the pod, and can be resolved by restarting the affected pod.

## Symptoms

* The `cray-oauth2-proxies-customer-management-ingress` pod shows TLS handshake errors in the logs.
* Users may experience authentication issues or timeouts when accessing services through the customer management ingress.
* The pod logs contain repeated error messages similar to the following:

  ```text
  2025/10/27 15:48:28 http: TLS handshake error from 10.44.0.0:6875: local error: tls: bad record MAC
  2025/10/27 15:48:28 http: TLS handshake error from 10.44.0.0:20520: local error: tls: bad record MAC
  2025/10/27 15:48:28 http: TLS handshake error from 10.44.0.0:27668: local error: tls: bad record MAC
  2025/10/27 15:48:28 http: TLS handshake error from 10.44.0.0:14785: local error: tls: bad record MAC
  2025/10/27 15:48:28 http: TLS handshake error from 10.44.0.0:18512: local error: tls: bad record MAC
  ```

## Solution

1. (`ncn-mw#`) Identify the affected pod name.

   ```bash
   kubectl get pods -n services | grep cray-oauth2-proxies-customer-management-ingress
   ```

   Example output:

   ```text
   cray-oauth2-proxies-customer-management-ingress-5f85bd6d44sqsnj   1/1     Running   0   2d
   ```

1. (`ncn-mw#`) Delete the affected pod to force a restart.

   ```bash
   kubectl delete pod cray-oauth2-proxies-customer-management-ingress-5f85bd6d44sqsnj -n services
   ```

   Example output:

   ```text
   pod "cray-oauth2-proxies-customer-management-ingress-5f85bd6d44sqsnj" deleted
   ```

1. (`ncn-mw#`) Verify that a new pod has been created and is running properly.

   ```bash
   kubectl get pods -n services | grep cray-oauth2-proxies-customer-management-ingress
   ```

   Example output:

   ```text
   cray-oauth2-proxies-customer-management-ingress-5f85bd6d44xyz123   1/1     Running   0   30s
   ```

1. (`ncn-mw#`) Monitor the new pod logs to confirm the TLS handshake errors have been resolved.

   ```bash
   kubectl logs cray-oauth2-proxies-customer-management-ingress-5f85bd6d44xyz123 -n services
   ```

The pod restart will clear any corrupted TLS state and restore normal functionality. The Kubernetes deployment will automatically create a new pod to replace the deleted one.
