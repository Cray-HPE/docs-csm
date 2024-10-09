# Determine Which BOS Session Booted a Node

This guide is split into two sections, BOS Version 1 (V1) and BOS
Version 2 (V2), because the procedures are different for the two different versions.

## BOS Version 1 (V1)

To determine which BOS Session booted or rebooted a node, query the node's
kernel boot parameters. They contain a `bos_session_id` parameter which identifies
which BOS session booted or rebooted the node. Then, use this BOS Session ID
to describe the BOS Session, which identifies the BOS Session template used.

### Query the node

1. (`ncn-mw#`) Set an environment variable to the xname of the node in question.

    For example:

    ```bash
    export NODE_XNAME="x3000c0s19b4n0"
    ```

1. (`ncn-mw#`) Query the node in question via SSH.

    ```bash
    BOS_SESSION_ID=$(ssh $NODE_XNAME "cat /proc/cmdline" | awk -v RS=" " -F "=" '{if ($1 == "bos_session_id") { print $2; }}')
    echo $BOS_SESSION_ID
    ```

    The output will be the BOS session ID. For example:

    ```text
    4b6744ee-837f-4f60-9051-897aed6c7623
    ```

### Query BOS

1. (`ncn-mw#`) Describe this session.

    ```bash
    cray bos v1 session describe ${BOS_SESSION_ID} --format json
    ```

    This will output information about the BOS session. For example:

    ```json
    {
      "complete": false,
      "error_count": 0,
      "in_progress": false,
      "job": "boa-4b6744ee-837f-4f60-9051-897aed6c7623",
      "operation": "reboot",
      "start_time": "2023-06-23T20:57:34.352623Z",
      "status_link": "/v1/session/4b6744ee-837f-4f60-9051-897aed6c7623/status",
      "stop_time": "2023-06-23 21:24:14.647779",
      "templateName": "knn-boot-x3000c0s28b4n0"
    }
    ```

    The `templateName` parameter is the name of the BOS session template used to boot or reboot the node.

## BOS Version 2 (V2)

Ask BOS V2 to describe the component. The session that last acted upon the
node is listed in this description.

## Instructions

1. (`ncn-mw#`) Set an environment variable to the xname of the node in question.

    For example:

    ```bash
    export NODE_XNAME="x3000c0s17b0n0"
    ```

1. (`ncn-mw#`) Query the BOS component for that node.

    ```bash
    BOS_SESSION_ID=$(cray bos v2 components describe $NODE_XNAME --format json | jq -r .session)
    echo $BOS_SESSION_ID
    ```

    The output will be the BOS session ID. For example:

    ```text
    94e712ab-df76-40ee-8cfb-7ac487fd8a13
    ```

1. (`ncn-mw#`) Describe the BOS session.

    ```bash
    cray bos v2 sessions describe $BOS_SESSION_ID --format json
    ```

    This will output information about the BOS session. For example:

    ```json
    {
      "components": "x3000c0s17b0n0",
      "limit": "x3000c0s17b0n0",
      "name": "94e712ab-df76-40ee-8cfb-7ac487fd8a13",
      "operation": "reboot",
      "stage": false,
      "status": {
        "end_time": "2023-06-27T00:55:58",
        "error": null,
        "start_time": "2023-06-27T00:33:17",
        "status": "complete"
      },
      "template_name": "gdr-tmpl"
    }
    ```

    The `template_name` parameter is the name of the BOS session template used to boot or reboot the node.
