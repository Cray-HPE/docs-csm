# Known Issue: `cray-tftp-upload` errors

* The `cray-tftp-upload` script errors out because of a change to the `ipxe` pods and the TFTP repository.
* This error affects the `cray-upload-recovery-images` script.
* This is expected to be fixed in CSM 1.5.1.

## FIX

If you receive the following type of error, then apply the workaround:


```text
Uploading file: curr.json
error: source and destination are required
Failed to upload curr.json - error code = 0
```

***Workaround:*** Edit the script `/usr/local/bin/cray-tftp-upload`, changing the following line:


```bash
PVC_HOST=`kubectl get pods -n services -l app.kubernetes.io/instance=cms-ipxe -o custom-columns=NS:.metadata.name --no-headers`
```

To:

```bash
PVC_HOST=`kubectl get pods -n services -l app.kubernetes.io/instance=cms-ipxe -o custom-columns=NS:.metadata.name --no-headers | head -1`
```
