#Unbound in CrashLoopBackOff After Deployment Restart

* There is a known race condition that can cause cray-dns-unbound to go into CLBO after running:
    ```bash
    kubectl rollout restart deployment -n services cray-dns-unbound
     ```
* This can impact csm-1.0.10 or older.
* Run the following command to get cray-dns-unbound out of CLBO
  ```bash
  kubectl patch deployment -n services cray-dns-unbound --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["sh", "-c", "touch /etc/unbound/records.conf;/srv/unbound/entrypoint.sh"]}]'
  ```