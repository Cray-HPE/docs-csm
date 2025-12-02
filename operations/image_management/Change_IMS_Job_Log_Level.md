# Change IMS Job Log Level

The Image Management Service (IMS) allows administrators to adjust the log level for image creation and customization jobs. 
This is useful for troubleshooting and debugging issues during image build or customization processes.

## Table of Contents

- [Overview](#overview)
- [Update Log Level During Image Creation](#update-log-level-during-image-creation)
- [Update Log Level During Image Customization](#update-log-level-during-image-customization)
- [Apply ConfigMap Changes](#apply-configmap-changes)
- [Example Debug Output](#example-debug-output)
- [Best Practices](#best-practices)

## Overview

The log level can be changed by editing the IMS ConfigMaps. Different log levels provide varying amounts of detail:

- **INFO**: Standard informational messages (default)
- **WARNING**: Warning messages and errors only
- **DEBUG**: Detailed debug information including API calls, connection details, and internal operations

## Update Log Level During Image Creation

IMS image creation jobs consist of multiple steps, each running in a separate container. The log level can be adjusted 
for all steps or for specific steps to debug particular issues.

1. Edit the IMS image creation ConfigMap:

   ```bash
   kubectl -n services edit cm cray-configmap-ims-v2-image-create-kiwi-ng
   ```

1. Locate the log level configuration for the step(s) you want to modify.

   There are 4 steps where the log level can be changed:
   
   - **fetch-recipe**: Container that fetches the image recipe
   - **wait-for-repos**: Container that waits for repositories to be ready
   - **build-ca-rpm**: Container that builds the CA RPM
   - **buildenv-sidecar**: Sidecar container for the build environment

1. Update the `LOG_LEVEL` value for the desired step(s):

   ```yaml
   - name: LOG_LEVEL
     value: "INFO"
   ```
   
   Change the value to one of the supported levels: `"INFO"`, `"WARNING"`, or `"DEBUG"`.

1. Save the changes and exit the editor.

1. Continue to [Apply ConfigMap Changes](#apply-configmap-changes).

## Update Log Level During Image Customization

IMS image customization jobs also support log level adjustments for debugging and troubleshooting.

1. Edit the IMS image customization ConfigMap:

   ```bash
   kubectl -n services edit cm cray-configmap-ims-v2-image-customize
   ```

1. Locate the log level configuration for the step(s) you want to modify.

   There are 2 steps where the log level can be changed:
   
   - **prepare**: Container that prepares the image for customization
   - **buildenv-sidecar**: Sidecar container for the build environment

1. Update the `LOG_LEVEL` value for the desired step(s):

   ```yaml
   - name: LOG_LEVEL
     value: "INFO"
   ```
   
   Change the value to one of the supported levels: `"INFO"`, `"WARNING"`, or `"DEBUG"`.

1. Save the changes and exit the editor.

1. Continue to [Apply ConfigMap Changes](#apply-configmap-changes).

## Apply ConfigMap Changes

After modifying either the image creation or customization ConfigMap, follow these steps to apply the changes:

1. Restart the IMS deployment for changes to take effect:

   ```bash
   kubectl rollout restart deploy cray-ims -n services
   ```

1. Verify that the IMS pods are running:

   ```bash
   kubectl get pods -n services | grep ims
   ```
   
   Wait until all IMS pods show a `Running` status.

1. Create an image creation or customization job and observe the log entries in the corresponding containers.

## Example Debug Output

### Image Creation

When `LOG_LEVEL` is set to `"DEBUG"` for image creation, the `fetch-recipe` container will display detailed logs similar to:

```text
DEBUG:urllib3.connectionpool:Starting new HTTPS connection (1): api-gw-service-nmn.local:443
DEBUG:urllib3.connectionpool:https://api-gw-service-nmn.local:443 "PATCH /apis/ims/jobs/94beba5a-d3b2-4c48-b7e4-ec0f40b2c9c4 HTTP/1.1" 200 1012
DEBUG:/scripts/venv/lib/python3.12/site-packages/ims_python_helper/fetch.py:
```

### Image Customization

When `LOG_LEVEL` is set to `"DEBUG"` for image customization, the `prepare` container will display detailed logs similar to:

```text
DEBUG:urllib3.connectionpool:Starting new HTTPS connection (1): api-gw-service-nmn.local:443
DEBUG:urllib3.connectionpool:https://api-gw-service-nmn.local:443 "PATCH /apis/ims/jobs/89de12e7-c762-4a2d-b937-af091719009c HTTP/1.1" 200 1298
DEBUG:/scripts/venv/lib/python3.12/site-packages/ims_python_helper/fetch.py:
```

## Best Practices

- Use `DEBUG` log level sparingly and only when troubleshooting specific issues, as it generates significantly more log data.
- Set the log level back to `INFO` after troubleshooting is complete to reduce log volume.
- If debugging a specific step, consider only changing the log level for that step rather than all steps.
- Remember to restart the IMS deployment after making ConfigMap changes for them to take effect.
