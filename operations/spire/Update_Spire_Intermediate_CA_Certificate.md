# Update Spire intermediate CA certificate

Prior to CSM 1.2.5 there is no mechanism to automatically update the spire
intermediate CA certificate before it expires. This certificate expires after
one year. Administrators will want to keep track of when this certificate
expires and manually update the certificate before it expires.

## How to obtain the expiration date for the Spire intermediate CA

To obtain the expiration date of the Spire intermediate CA certificate, run the
following command on a node that has access to kubectl (Such as ncn-m001)

```bash
kubectl get secret -n spire spire.spire.ca-tls -o json | jq -r '.data."tls.crt" | @base64d' | openssl x509 -noout -enddate
```

## How to replace the Spire intermediate CA certificate with a new one

In order to replace the expired or soon to expire Spire intermediate CA
certificate you need to delete the secret that stores the certificate and then
re-run the job that obtains the certificate and creates the secret.

```bash
SPIRE_INTERMEDIATE_JOB=$(kubectl get job -n vault -o name| grep 'spire-intermediate' | tail -n1)
kubectl get secrets -n spire spire.spire.ca-tls -o yaml > spire.spire.ca-tls.yaml.bak
kubectl delete secret -n spire spire.spire.ca-tls
kubectl get -n vault "$SPIRE_INTERMEDIATE_JOB" -o json | jq 'del(.spec.selector,.spec.template.metadata.labels)' | kubectl replace --force -f -
```

After the `spire.spire.ca-tls` secret in the `spire` namespace has been
repopulated you should roll the spire-server to make sure all of them pick up
the new CA.

```bash
kubectl rollout restart -n spire statefulset spire-server
```

Any spire-agents in the CLBO state should come back into a Running state the
next time they're started. If you don't wish to wait for them to be restarted
automatically then you can delete the spire-agent pod, which will cause a new
one to start up in its place.
