# Configure the BOS Timeout When Booting Compute Nodes

> **`NOTE`** This section is for Boot Orchestration Service \(BOS\) v1 only. For similar functionality in BOS v2 see the BOS v2 [Options](Options.md).

Manually update the `boa-job-template` ConfigMap to tune the timeout and sleep intervals for the Boot Orchestration Agent \(BOA\).
Correcting the timeout value is a good troubleshooting option for when BOS sessions hang waiting for nodes to be in a `Ready` state.

If the BOS timeout occurs when booting compute nodes, the system will be unable to boot via BOS.

## Prerequisites

A BOS session was run and compute nodes are failing to move to a `Ready` state.

## Procedure

1. (`ncn-mw#`) Edit the `boa-job-template` ConfigMap to add the new timeout values.

    ```bash
    kubectl edit configmap -n services boa-job-template
    ```

    Node boots can be set to time out faster by adding the following environment variables to the `boa-job-template`. These variables do not appear in the ConfigMap by default.

    - `NODE_STATE_CHECK_NUMBER_OF_RETRIES`
      - BOA will check on the expected state of nodes this many times before giving up. This number can be set to a very low number to make BOA time-out quickly.
    - `NODE_STATE_CHECK_SLEEP_INTERVAL`
      - This is how long BOA will sleep between checks, in seconds. This number can be set to a very low number to make BOA time-out quickly.

    The current default behavior in the absence of these parameters is 5 seconds \(sleep interval\) x 120 \(retries\), which has a timeout of 600 seconds or 10 minutes.
    The default values are shown below:

    ```yaml
    - name: "NODE_STATE_CHECK_NUMBER_OF_RETRIES"
      value: "120"
    - name: "NODE_STATE_CHECK_SLEEP_INTERVAL"
      value: "5"
    ```

    The example below increases the number of retries to 360, which results in a timeout of 1800 seconds or 30 minutes if the sleep interval is not changed from the default value of 5 seconds.
    Different values might be needed depending on system size.

    Add the following values to the ConfigMap:

    ```yaml
    - name: "NODE_STATE_CHECK_NUMBER_OF_RETRIES"
      value: "360"
    ```

    The new variables need to be placed under the environment \(`env:`\) section in the ConfigMap. As an example, the `env` section in the ConfigMap looks as below.

    ```yaml
    env:
        - name: OPERATION
         value: "{{ operation }}"
        - name: SESSION_ID
         value:  "{{ session_id }}"
        - name: SESSION_TEMPLATE_ID
         value:  "{{ session_template_id }}"
        - name: SESSION_LIMIT
         value:  "{{ session_limit }}"
        - name: DATABASE_NAME
         value: "{{ DATABASE_NAME }}"
        - name: DATABASE_PORT
         value: "{{ DATABASE_PORT }}"
        - name: LOG_LEVEL
         value: "{{ log_level  }}"
        - name: SINGLE_THREAD_MODE
         value: "{{ single_thread_mode }}"
        - name: S3_ACCESS_KEY
         valueFrom:
           secretKeyRef:
             name: {{ s3_credentials }}
             key: access_key
        - name: S3_SECRET_KEY
         valueFrom:
           secretKeyRef:
             name: {{ s3_credentials }}
             key: secret_key
        - name: GIT_SSL_CAINFO
         value: /etc/cray/ca/certificate_authority.crt
        - name: S3_PROTOCOL
         value: "{{ S3_PROTOCOL }}"
        - name: S3_GATEWAY
         value: "{{ S3_GATEWAY }}"
        **- name: "NODE_STATE_CHECK_NUMBER_OF_RETRIES"
         value: "360"**
    ```

1. (`ncn-mw#`) Restart BOA.

    Restarting BOA will allow the new timeout values to take effect.

    ```bash
    kubectl scale deployment -n services cray-bos --replicas=0 && kubectl scale deployment -n services cray-bos --replicas=1
    ```
