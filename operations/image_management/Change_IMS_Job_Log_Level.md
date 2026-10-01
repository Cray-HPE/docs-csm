# Change IMS Job Log Level

The Image Management Service (IMS) allows administrators to adjust the log level for image creation and customization jobs.
This is useful for troubleshooting and debugging issues during image build or customization processes.

## Table of contents

- [Overview](#overview)
- [Procedure](#procedure)
    1. [Update log level](#1-update-log-level)
        - [Update log level during image creation](#update-log-level-during-image-creation)
        - [Update log level during image customization](#update-log-level-during-image-customization)
    1. [Apply ConfigMap changes](#2-apply-configmap-changes)
- [Example debug output](#example-debug-output)
    - [Image creation](#image-creation)
    - [Image customization](#image-customization)
- [Best practices](#best-practices)

## Overview

The log level can be changed by editing the IMS ConfigMaps. Different log levels provide varying amounts of detail:

- `INFO`: Standard informational messages (default)
- `WARNING`: Warning messages and errors only
- `DEBUG`: Detailed debug information including API calls, connection details, and internal operations

## Procedure

### 1. Update log level

The log level can be updated for image creation, image customization, or both.

- [Update log level during image creation](#update-log-level-during-image-creation)
- [Update log level during image customization](#update-log-level-during-image-customization)

#### Update log level during image creation

IMS image creation jobs consist of multiple steps, each running in a separate container. The log level can be adjusted
for all steps or for specific steps to debug particular issues.

1. (`ncn-mw#`) Edit the IMS image creation ConfigMap:

   ```bash
   kubectl -n services edit cm cray-configmap-ims-v2-image-create-kiwi-ng
   ```

1. Locate the log level configuration for the steps to be modified.

   There are 4 steps where the log level can be changed:

   - `fetch-recipe`: Container that fetches the image recipe
   - `wait-for-repos`: Container that waits for repositories to be ready
   - `build-ca-rpm`: Container that builds the CA RPM
   - `buildenv-sidecar`: Sidecar container for the build environment

1. Update the `LOG_LEVEL` value for the desired steps:

   ```yaml
   - name: LOG_LEVEL
     value: "INFO"
   ```

   Change the value to one of the supported levels: `INFO`, `WARNING`, or `DEBUG`.

1. Save the changes and exit the editor.

1. Optionally also [Update log level during image customization](#update-log-level-during-image-customization).

1. Continue to [Apply ConfigMap Changes](#2-apply-configmap-changes).

#### Update log level during image customization

IMS image customization jobs also support log level adjustments for debugging and troubleshooting.

1. (`ncn-mw#`) Edit the IMS image customization ConfigMap:

   ```bash
   kubectl -n services edit cm cray-configmap-ims-v2-image-customize
   ```

1. Locate the log level configuration for the steps to be modified.

   There are two steps where the log level can be changed:

   - `prepare`: Container that prepares the image for customization
   - `buildenv-sidecar`: Sidecar container for the build environment

1. Update the `LOG_LEVEL` value for the desired steps:

   ```yaml
   - name: LOG_LEVEL
     value: "INFO"
   ```

   Change the value to one of the supported levels: `INFO`, `WARNING`, or `DEBUG`.

1. Save the changes and exit the editor.

1. Optionally also [Update log level during image creation](#update-log-level-during-image-creation).

1. Continue to [Apply ConfigMap Changes](#2-apply-configmap-changes).

### 2. Apply ConfigMap changes

After modifying either or both ConfigMaps, follow these steps to apply the changes:

1. (`ncn-mw#`) Restart the IMS deployment for changes to take effect:

   ```bash
   kubectl rollout restart deploy cray-ims -n services
   ```

1. (`ncn-mw#`) Verify that the IMS pods are running:

   ```bash
   kubectl get pods -n services | grep ims
   ```

   Wait until all IMS pods show a `Running` status.

1. Create an image creation or customization job and observe the log entries in the corresponding containers.

## Example debug output

### Image creation

When `LOG_LEVEL` is set to `DEBUG` for image creation, the `fetch-recipe` container will display detailed logs similar to:

```text
DEBUG:urllib3.connectionpool:Starting new HTTPS connection (1): api-gw-service-nmn.local:443
DEBUG:urllib3.connectionpool:https://api-gw-service-nmn.local:443 "PATCH /apis/ims/jobs/94beba5a-d3b2-4c48-b7e4-ec0f40b2c9c4 HTTP/1.1" 200 1012
DEBUG:/scripts/venv/lib/python3.12/site-packages/ims_python_helper/fetch.py:
```

### Image customization

When `LOG_LEVEL` is set to `DEBUG` for image customization, the `prepare` container will display detailed logs similar to:

```text
DEBUG:urllib3.connectionpool:Starting new HTTPS connection (1): api-gw-service-nmn.local:443
DEBUG:urllib3.connectionpool:https://api-gw-service-nmn.local:443 "PATCH /apis/ims/jobs/89de12e7-c762-4a2d-b937-af091719009c HTTP/1.1" 200 1298
DEBUG:/scripts/venv/lib/python3.12/site-packages/ims_python_helper/fetch.py:
```

## Best practices

- Use `DEBUG` log level sparingly and only when troubleshooting specific issues, as it generates significantly more log data.
- Set the log level back to `INFO` after troubleshooting is complete to reduce log volume.
- If debugging a specific step, consider only changing the log level for that step rather than all steps.
- Remember to restart the IMS deployment after making ConfigMap changes for them to take effect.
