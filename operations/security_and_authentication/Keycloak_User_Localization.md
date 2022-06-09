# Keycloak User Localization

## Verification procedure

Verify that the Keycloak users localize job has completed as expected.

> This section can be skipped if user localization is not required.

After an upgrade, it is possible that all expected Keycloak users were not localized. The procedure below helps determine whether or not this has happened, and
provides remediation steps if they are needed.

1. Check to see if the Keycloak users localize job has completed.

   ```bash
   ncn-m002# kubectl -n services wait --for=condition=complete --timeout=10s job/`kubectl -n services get jobs | grep users-localize | awk '{print $1}'`
   ```

   The job completed if the output contains the string `condition met`.

1. If the job completed, check that the count of localized users matches the expected count from the Keycloak server.

   This can be done by looking at the count of users reported from the command below.

   ```bash
   ncn-m002# cray artifacts get wlm etc/passwd /dev/stdout | wc -l
   ```

   If that count looks correct, then no further action is needed and the remainder of this section should be skipped. Otherwise,
   rerun the localize job by following the remaining steps in the section.

1. Recreate the job.

   ```bash
   ncn-m002# kubectl get job -n services -l app.kubernetes.io/name=cray-keycloak-users-localize -ojson |
                jq '.items[0]' > keycloak-users-localize-job.json
   ncn-m002# kubectl delete job -n services -l app.kubernetes.io/name=cray-keycloak-users-localize
   ncn-m002# cat keycloak-users-localize-job.json | jq 'del(.spec.selector)' |
                jq 'del(.spec.template.metadata.labels)' | kubectl apply -f -
   ```

   Expected output looks similar to:

   ```text
   job.batch "keycloak-users-localize-1" deleted
   job.batch/keycloak-users-localize-1 created
   ```

1. Repeat the first two steps of this procedure to confirm that the job completed and that the Keycloak user count is correct.
