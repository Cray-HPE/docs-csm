# Determine Which BOS Session Booted a Node

## Overview

Ask BOS to describe the component. The session that last acted upon the
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
