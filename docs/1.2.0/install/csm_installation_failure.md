# CSM Services Install Fails Because of Missing Secret

When running the install script in the [Install CSM Services](install_csm_services.md) procedure, it may fail due to a
timing-related issue. This page documents how to determine if this problem was the cause of an install script failure,
and the appropriate remediation steps to take if it is encountered.

## How to determine if an install hit this issue

1. Verify that the installation script output contains an error about a missing secret.

    Example snippet from the install script output:

    ```text
      ERROR   Step: Set Management NCNs to use Unbound --- Checking Precondition
    + Getting admin-client-auth secret
    Error from server (NotFound): secrets "admin-client-auth" not found
    + Obtaining access token
    curl: (22) The requested URL returned error: 404
    + Querying SLS
    curl: (22) The requested URL returned error: 503

    Check the doc below for troubleshooting:
          If any management NCNs are missing from the output, take corrective action
          before proceeding.

     INFO  Failed Pipeline/Step id: f0cd9574240989eb04118d308f26b3ea
    exit status 22
    ```

    If the above `secrets "admin-client-auth" not found` error is observed, then proceed to the next step.

1. Verify that `keycloak-setup` has this issue.

    Look for a `keycloak-setup` pod still in the `Running` state:

    ```bash
    pit# kubectl get pods -n services | grep keycloak-setup
    ```

    Example output:

    ```text
    keycloak-setup-1-xj9s5                                            1/2     Running   0          32m
    ```

1. Check the `istio-proxy` container logs for the `keycloak-setup` pod found in the previous step.

    In the following command, substitute the name of the `keycloak-setup` pod found in the previous step.

    ```bash
    pit # kubectl logs --namespace services -n services KEYCLOAK-SETUP-POD-NAME --container istio-proxy | grep '[[:space:]]503[[:space:]]' | grep SDS | tail -n2
    ```

    If the output looks similar to the following, then proceed to the remediation steps.

    ```text
      [2022-05-27T13:21:24.535Z] "POST /keycloak/realms/master/protocol/openid-connect/token HTTP/1.1" 503 UF,URX "TLS error: Secret is not supplied by SDS" 96 159 16 - "-" "python-requests/2.27.1" "19fe9b72-d887-4649-b934-9dc7bc76cc21" "keycloak.services:8080" "10.44.0.31:8080" outbound|8080||keycloak.services.svc.cluster.local - 10.28.81.125:8080 10.32.0.25:60032 - default
      [2022-05-27T13:21:34.573Z] "POST /keycloak/realms/master/protocol/openid-connect/token HTTP/1.1" 503 UF,URX "TLS error: Secret is not supplied by SDS" 96 159 61 - "-" "python-requests/2.27.1" "ef0255b4-260b-47b5-8077-3e17e9371baf" "keycloak.services:8080" "10.44.0.31:8080" outbound|8080||keycloak.services.svc.cluster.local - 10.28.81.125:8080 10.32.0.25:60964 - default
    ```

## Remediate the problem

1. Delete the current `keycloak-setup` pod.

    In the following command, substitute the name of the `keycloak-setup` pod found in the previous section.

    ```bash
    pit # kubectl delete pod --namespace services KEYCLOAK-SETUP-POD-NAME
    ```

1. Find the pod name of the new `keycloak-setup` pod by using the same `kubectl get pods` command from the previous section.

1. Ensure that the new `keycloak-setup` pod completed setup:

    In the following command, substitute the name of the new `keycloak-setup` pod found in the previous step.

    ```bash
    pit # kubectl logs --namespace services -n services NEW-KEYCLOAK-SETUP-POD-NAME --container keycloak-setup | tail -n 3
    ```

    Example output indicating that it has completed setup:

    ```text
    2022-05-27 14:12:25,251 - INFO    - keycloak_setup - Deleting 'keycloak-gatekeeper-client' Secret in namespace 'services'...
    2022-05-27 14:12:25,264 - INFO    - keycloak_setup - The 'keycloak-gatekeeper-client' secret in namespace 'services' already doesn't exit.
    2022-05-27 14:12:25,264 - INFO    - keycloak_setup - Keycloak setup complete
    ```

1. Once all Keycloak pods have successfully completed, then re-run the installation script and proceed with the installation.

    ```bash
    pit # kubectl get pods --namespace services | grep keycloak | grep -Ev '(Completed|Running)'
    ```

    If this command gives no output, then installation may proceed.
