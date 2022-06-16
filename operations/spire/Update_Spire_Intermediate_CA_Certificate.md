# Update Spire Intermediate CA Certificate

Starting with CSM 1.2.5, there is a cronjob in the `vault` namespace named
`spire-intermediate` that runs once a week. If the Spire intermediate CA
certificate is set to expire in less than a month when that job runs, then it
will replace the certificate with a new one. If this process fails you can
take the manual steps listed below in order to update the certificate.

## Obtain the Expiration Date for the Spire Intermediate CA

To obtain the expiration date of the Spire intermediate CA certificate, run the
following command on a node that has access to `kubectl` (such as `ncn-m001`):

```bash
kubectl get secret -n spire spire.spire.ca-tls -o json | jq -r '.data."tls.crt" | @base64d' | openssl x509 -noout -enddate
```

## Replace the Spire Intermediate CA Certificate

1. Delete the secret that stores the certificate.

   ```bash
   SPIRE_INTERMEDIATE_JOB=$(kubectl get job -n vault -o name| grep 'spire-intermediate' | tail -n1)
   kubectl get secrets -n spire spire.spire.ca-tls -o yaml > spire.spire.ca-tls.yaml.bak
   kubectl delete secret -n spire spire.spire.ca-tls
   ```

1. Re-run the job that obtains the secret and creates the certificate.

   ```bash
   kubectl get -n vault "$SPIRE_INTERMEDIATE_JOB" -o json | jq 'del(.spec.selector,.spec.template.metadata.labels)' | kubectl replace --force -f -
   ```

1. After the `spire.spire.ca-tls` secret in the `spire` namespace has been
   repopulated, roll the spire-server to make sure all of them pick up
   the new CA.

   ```bash
   kubectl rollout restart -n spire statefulset spire-server
   ```

   Any `spire-agent` in the `CrashLoopBackOff` state should come back into a `Running` state the
   next time they are started. If you do not wish to wait for them to be restarted
   automatically, then you can delete the `spire-agent` pod, which will cause a new
   one to start up in its place.

1. Enable the NCNs to rejoin Spire.

   ```bash
   kubectl rollout restart -n spire daemonset request-ncn-join-token
   ```

1. Re-run the command to get the certificate's expiration date to verify that
   it has been updated.

   ```bash
   kubectl get secret -n spire spire.spire.ca-tls -o json | jq -r '.data."tls.crt" | @base64d' | openssl x509 -noout -enddate
   ```
