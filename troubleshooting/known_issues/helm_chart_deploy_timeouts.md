# Helm Chart Deploy Timeouts

There are times when installing CSM Services (either during fresh install or upgrade) when some helm charts may take longer than five minutes (default) to deploy.
Several charts known to take longer than five minutes have been modified to allow more time, but this page can be used to manually increase this timeout if needed.

## Edit the manifest used by Loftsman

Locate the chart which is taking longer than usual to deploy in the manifest (typically `platform.yaml` or `sysmgmt.yaml` under the media directory for CSM release, e.g., `/etc/cray/upgrade/csm/media/update-products-24.3.0/csm-1.5.0/manifests/sysmgmt.yaml`), and edit (or add) the `timeout` field at the same level as `name` in the manifest:

```text
  - name: cray-uas-mgr
    source: csm-algol60
    version: 1.23.2
    namespace: services
    timeout: 20m0s     <-------------
```

## Continue with the CSM Services install

After having changed this setting in the manifest, re-running the install (or upgrade script) should successfully deploy the chart(s).
