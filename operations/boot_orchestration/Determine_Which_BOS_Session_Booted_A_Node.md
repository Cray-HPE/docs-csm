# Determine Which BOS Session Booted a Node

This guide is split into BOS Version 1 (V1) and BOS Version 2 (V2) sections
because the procedures are different for the two different versions.

## BOS Version 1 (V1)

To determine which BOS Session booted or rebooted a node, query the node's
kernel boot parameters. They contain a string 'bos_session_id' which identifies
which BOS session booted or rebooted the node. Then, use this BOS Session ID
to describe the BOS Session, which identifies the BOS Session template used.

### Query the Node

(`ncn-mw#`) Query the node in question via ssh. The returned value will be the session ID.

```bash
BOS_SESSION_ID=$(ssh <node's xname> "cat /proc/cmdline" | awk -v RS=" " -F "=" '{if ($1 == "bos_session_id") { print $2; }}')

```

### Query BOS
(`ncn-mw#`) Ask BOS to describe this session.

'''bash
cray bos v1 session describe ${BOS_SESSION_ID} --format json
'''

The templateName parameter is the BOS session template used to boot or reboot the node.

### Example

(`ncn-mw#`) From a management node (master or worker), ssh to the node in question.

```bash
BOS_SESSION_ID=$(ssh x3000c0s19b4n0 "cat /proc/cmdline" | awk -v RS=" " -F "=" '{if ($1 == "bos_session_id") { print $2; }}')

echo $BOS_SESSION_ID
4b6744ee-837f-4f60-9051-897aed6c7623
```

```bash
cray bos v1 session describe 4b6744ee-837f-4f60-9051-897aed6c7623 --format json
{
  "complete": false,
  "error_count": 0,
  "in_progress": false,
  "job": "boa-147b09de-59a8-4444-9bcb-9b54ac7d78cc",
  "operation": "reboot",
  "start_time": "2023-06-23T20:57:34.352623Z",
  "status_link": "/v1/session/147b09de-59a8-4444-9bcb-9b54ac7d78cc/status",
  "stop_time": "2023-06-23 21:24:14.647779",
  "templateName": "knn-boot-x3000c0s28b4n0"
}
```
The session template is "knn-boot-x3000c0s28b4n0".

## BOS Version 2 (V2)

Ask BOS V2 to describe the component. The session that last acted upon the
node is listed in this description.

### Instructions
(`ncn-mw#`) cray bos v2 components describe <node's xname> --format json | jq .session

(`ncn-mw#`) cray bos v2 sessions describe <BOS session ID> --format json

### Example
(`ncn-mw#`) cray bos v2 components describe x3000c0s17b0n0 --format json | jq .session
"94e712ab-df76-40ee-8cfb-7ac487fd8a13"

(`ncn-mw#`) cray bos v2 sessions describe 94e712ab-df76-40ee-8cfb-7ac487fd8a13 --format json
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
The session template is "gdr-tmpl".
