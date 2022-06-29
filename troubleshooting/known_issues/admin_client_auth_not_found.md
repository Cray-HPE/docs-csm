# Known Issue: `admin-client-auth` Not Found

Running the Install CSM Services script, the following error may occur:

```text
ERROR   Step: Set Management NCNs to use Unbound --- Checking Precondition
+ Getting admin-client-auth secret
Error from server (NotFound): secrets "admin-client-auth" not found
+ Obtaining access token
```

## Fix

This can occur if the `keycloak-users-localize` pod has not completed, and that can be caused by an intermittent Istio issue. Remediate the issue with the following procedure:

   1. Follow [Troubleshoot Intermittent HTTP 503 Code Failures](../../operations/kubernetes/Troubleshoot_Intermittent_503s.md) to verify that Istio is healthy.

   1. (`ncn-mw#`) Ensure that the `keycloak-wait-for-postgres-*` pod is in a `Completed` state.

       ```bash
       kubectl get po -n services | grep keycloak-wait-for-postgres
       ```

       Example output:

       ```text
       keycloak-wait-for-postgres-1-pv85m                                0/2     Completed   0          15d
       ```

   1. (`ncn-mw#`) If the `keycloak-wait-for-postgres-*` pod is not in a `Completed` state, then resubmit the job.

       ```bash
       kubectl get job -n services -l app.kubernetes.io/name=keycloak-wait-for-postgres -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels)' | kubectl replace --force -f -
       ```

       Example output:

       ```text
       job.batch "keycloak-wait-for-postgres-1" deleted
       job.batch/keycloak-wait-for-postgres-1 replaced
       ```

Once the `keycloak-wait-for-postgres-*` pod has completed, the `keycloak-users-localize` job should create the `admin-client-auth` secret and complete.
