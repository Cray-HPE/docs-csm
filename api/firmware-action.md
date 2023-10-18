<!-- Generator: Widdershins v4.0.1 -->

<h1 id="firmware-action-service">Firmware Action Service v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The Firmware Action Service (FAS) provides a common interface for managing the firmware versions of hardware in a system via Redfish. FAS tracks and performs actions like upgrade, downgrade, create, or restore snapshots for system firmware. FAS processes an *image list*, which is a JSON file containing firmware versions for each component on a node.

The firmware RPM's are provided by HPE and installed during installation. The firmware RPM contains the firmware image and the image list. FAS uses the cray-fas-loader (Kubernetes job) to upload firmware images from the RPMs (stored in Nexus) to the artifact repository (S3) and to create the image list in FAS during installation. Note that FAS is a successor to FUS (firmware update service) that was available with earlier versions and offers several enhancements over FUS.

## Resources
### /images
Maintain the image list. Use this resource to update, replace, or return the image list.
### /service/status, /service/version, /service/status/details
Return status and version information for the Firmware Action Service itself.
### /actions
Initiate a firmware action. An action is a collection of operations initiated by user request to update the firmware images on a set of hardware. Example: Update the Gigabyte BMC targets to the latest version.
### /snapshots
Stores current version information for all nodes or restores targets to the stored version level. A snapshot is a point-in-time record of what firmware images were running on the system (a device's targets), constrained by user defined parameters (xname, model/manufacturer, etc). Snapshots can be used to restore the system back to specific firmware versions.
## Parameters

 * *xname* refers to the node.
 * *target* is a component on a node and is case sensitive.
 * *tag* is a label applied to firmware images, it is part of the unique identifier for an image; deviceType, manufacturer, model, target, semanticFirmwareVersion, tag.

## Workflow
### Update firmware for all targets at xname and check status
#### POST /actions
Before updating firmware, administrator must consider firmware dependencies between different components and determine the update sequence. For example, firmware of one component may need to be updated before firmware for another component can be updated.
Upgrade/downgrade/set firmware to an explicit version for all components on the node identified by xname. Upon success, the string response contains an action ID which can be used to query the status of the firmware action.
For example, the response to a successful POST /actions provides actionID:

    {"actionID": "fcac1eec-e93b-4549-90aa-6a59fda0f4c6",
     "overrideDryrun": true,
    }

The actionID is used to submit a request for the status of the action:

    GET .../v1/actions/fcac1eec-e93b-4549-90aa-6a59fda0f4c6

Dry run helps to determine what firmware can be updated for all components on the node identified by xname. You need to enter values like xname, version etc. in a JSON payload. Ensure that the overrideDryrun parameter is set to false (default value) so that the dry run occurs.
#### GET /actions/{actionID}
Retrieve information for a specific action ID.
#### GET /actions/{actionID}/status
Retrieve status for a specific action ID.
#### GET /actions/{actionID}/operations
Retrieve details for a specific action ID.
#### GET /operations/{operationID}
Retrieve detailed information for a specific operationID.
### Create a snapshot to capture the firmware version for selected devices
#### POST /snapshots
You can create a snapshot to record the firmware versions for targets on specific devices. Upon success, the response includes the snapshot name.
#### GET/snapshots/{snapshotName}
Retrieve details of the snapshot that you created. Retrieve details about the specific snapshot by providing the snapshot name. In the response body, look under devices > targets > imageID and check the imageID. Ensure that the imageID is non-zero.
Note that if imageID is a string of zeros like "00000000-0000-0000-0000-000000000000", it implies that there is no image associated with this snapshot. Restoring this snapshot does not lead to any results as there is no image to restore.
### Restore a snapshot
#### POST /snapshots/{snapshotName}/restore
Use this API to restore an existing snapshot by replacing selected components (device + target) with the stored firmware version. Enter the snapshot name as a path parameter.
Upon success, the string response contains an action ID which can be used to query the status of the restore.
#### GET /actions/{actionID}
Using the response from the update, retrieve status of restore for a specific action ID.
## Interactions with other APIs
FAS receives information from the Hardware State Manager (HSM) for each xname.

Base URLs:

* <a href="https://rocket-ncn-w001.us.cray.com/apis/fas/v1">https://rocket-ncn-w001.us.cray.com/apis/fas/v1</a>

* <a href="http://localhost:28800/v1">http://localhost:28800/v1</a>

* <a href="http://localhost:28800">http://localhost:28800</a>

<h1 id="firmware-action-service-actions">actions</h1>

## get__actions

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /actions`

*Retrieve all firmware action sets with summary information*

Retrieve all valid action IDs along with start time and
end time for completed and in-progress actions.

> Example responses

> 200 Response

```json
{
  "actions": [
    {
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "snapshotID": "0a404cc5-4bd4-40f5-b698-aa34ab33b3fb",
      "overrideDryrun": true,
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "running",
      "operationCounts": {
        "total": 100,
        "initial": 0,
        "configured": 0,
        "blocked": 0,
        "needsVerified": 0,
        "verifying": 0,
        "inProgress": 32,
        "failed": 10,
        "success": 58,
        "noSolution": 4,
        "noOperation": 6,
        "aborted": 0,
        "unknown": 0
      },
      "description": "string",
      "blockedBy": [
        "497f6eca-6276-4993-bfeb-53cbbbba6f08"
      ],
      "errors": [
        "string"
      ]
    }
  ]
}
```

<h3 id="get__actions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ActionSummarys](#schemaactionsummarys)|

<aside class="success">
This operation does not require authentication
</aside>

## post__actions

> Code samples

```http
POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Content-Type": []string{"application/json"},
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /actions`

*Update firmware on the system*

Perform a firmware action across the system.
Upon success, the string response contains an action ID which can be used to
query the status of the update.

For example, the response to a successful POST /actions is
the following:
  {"actionID": "fcac1eec-e93b-4549-90aa-6a59fda0f4c6", "overrideDryrun": true}, actionID is the ID to reference the action;
performing a GET .../v1/actions/fcac1eec-e93b-4549-90aa-6a59fda0f4c6  will return status
information on the action and its collection of operations

The parameters are logically AND'd. The parameters are broken into: location, type, level.
The command parameters will FORCE an action or override a dryrun.

stateComponentFilter: -> determines the xnames to run on
  * xnames
  * partitions
  * groups
  * deviceTypes

inventoryHardwareFilter: -> determines the xnames to run on by comparison of the 'type' information
  * manufacturer
  * model

targetFilter:  -> determines the targets to run on
  * targets

imageFilter:   -> can specify a specific image UUID to use.
  * imageID

commands:
  * overrideDryrun ->  option to perform an update. The default value of this parameter is false, which will cause a dryrun to
    be executed. The dry run checks if a newer firmware version exists without actually performing the update operation.
    FAS will only update the system if this parameter is set to true.
    Note that leaving this blank or misspelling true is considered false resulting in a dry run to be performed.
  * restoreNotPossibleOverride -> override to force update for hardware that does not have an identified FROM image and therefore cannot be rolled back to.
    FAS will not perform an update if the currently running firmware is not
    available in the images repository.
  * tag -> the tag associated with the images to update to. `default` is the default tag.
  * timeLimit -> time in seconds to let any operation execute
  * description
  * version - latest, earliest, explicit (used in conjunction with imageFilter)
  * overwriteSameImage -> If the 'fromFirmwareVersion' and 'toFirmwareVersion'
    of an operation are the same, FAS will not update the firmware image on the
    device. Setting this parameter to 'true' causes FAS to send the update command
    to the device. It cannot be verified via FAS if the firmware image was updated.
    Also note that FAS will send the update command to the device, but some devices
    are smart enough to realize the same image and not execute the command.

> Body parameter

```json
{
  "stateComponentFilter": {
    "xnames": [
      "x0c0s0b0",
      "x0c0s2b0"
    ],
    "partitions": [
      "p1"
    ],
    "groups": [
      "red",
      "blue"
    ],
    "deviceTypes": [
      "nodeBMC"
    ]
  },
  "inventoryHardwareFilter": {
    "manufacturer": "cray",
    "model": "c5000"
  },
  "imageFilter": {
    "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
    "overrideImage": true
  },
  "targetFilter": {
    "targets": [
      "BIOS",
      "BMC"
    ]
  },
  "command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": true,
    "restoreNotPossibleOverride": true,
    "overwriteSameImage": true,
    "timeLimit": 10000,
    "description": "update cabinet xxxx"
  }
}
```

<h3 id="post__actions-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ActionParameters](#schemaactionparameters)|true|Optional description in *Markdown*|

> Example responses

> 201 Response

```json
{
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "overrideDryrun": true
}
```

> 404 Response

<h3 id="post__actions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Created|[ActionID](#schemaactionid)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|action set not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__actions_{actionID}

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /actions/{actionID}`

*Retrieve detailed information for a firmware action set*

Retrieve detailed information for a firmware action set specified by actionID.

<h3 id="get__actions_{actionid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|actionID|path|string(uuid)|true|none|

> Example responses

> 200 Response

```json
{
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "snapshotID": "0a404cc5-4bd4-40f5-b698-aa34ab33b3fb",
  "startTime": "2019-08-24T14:15:22Z",
  "endTime": "2019-08-24T14:15:22Z",
  "state": "running",
  "description": "string",
  "operationSummary": {
    "initial": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "configured": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "blocked": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "needsVerified": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "verifying": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "inProgress": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "failed": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "success": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "noSolution": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "noOperation": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "aborted": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "unknown": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ]
  },
  "overrideDryrun": true,
  "parameters": {
    "stateComponentFilter": {
      "xnames": [
        "x0c0s0b0",
        "x0c0s2b0"
      ],
      "partitions": [
        "p1"
      ],
      "groups": [
        "red",
        "blue"
      ],
      "deviceTypes": [
        "nodeBMC"
      ]
    },
    "inventoryHardwareFilter": {
      "manufacturer": "cray",
      "model": "c5000"
    },
    "imageFilter": {
      "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
      "overrideImage": true
    },
    "targetFilter": {
      "targets": [
        "BIOS",
        "BMC"
      ]
    },
    "command": {
      "version": "latest",
      "tag": "default",
      "overrideDryrun": true,
      "restoreNotPossibleOverride": true,
      "overwriteSameImage": true,
      "timeLimit": 10000,
      "description": "update cabinet xxxx"
    }
  },
  "blockedBy": [
    "497f6eca-6276-4993-bfeb-53cbbbba6f08"
  ],
  "errors": [
    "string"
  ]
}
```

> 404 Response

<h3 id="get__actions_{actionid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[Action](#schemaaction)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|action set not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## delete__actions_{actionID}

> Code samples

```http
DELETE https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/error

```

```shell
# You can also use wget
curl -X DELETE https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID} \
  -H 'Accept: application/error'

```

```python
import requests
headers = {
  'Accept': 'application/error'
}

r = requests.delete('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/error"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /actions/{actionID}`

*Delete all information about a completed firmware action set*

Delete all information about a completed firmware action set.

<h3 id="delete__actions_{actionid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|actionID|path|string(uuid)|true|none|

> Example responses

> 400 Response

<h3 id="delete__actions_{actionid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Deleted  - no content|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|cannot delete a running action|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|action set not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## delete__actions_{actionID}_instance

> Code samples

```http
DELETE https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/instance HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/instance \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/instance', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/instance", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /actions/{actionID}/instance`

*Abort a running firmware action set*

Abort a running firmware action set. Stops all actions in progress (will not rollback)

<h3 id="delete__actions_{actionid}_instance-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|actionID|path|string(uuid)|true|none|

> Example responses

> 404 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="delete__actions_{actionid}_instance-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Action already finalized|None|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Aborting action|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|action set not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__actions_{actionID}_status

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/status HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/status \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/status', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /actions/{actionID}/status`

*Retrieve summary information of a firmware action set*

Retrieve summary information of a firmware action set.

<h3 id="get__actions_{actionid}_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|actionID|path|string(uuid)|true|none|

> Example responses

> 200 Response

```json
{
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "snapshotID": "0a404cc5-4bd4-40f5-b698-aa34ab33b3fb",
  "overrideDryrun": true,
  "startTime": "2019-08-24T14:15:22Z",
  "endTime": "2019-08-24T14:15:22Z",
  "state": "running",
  "operationCounts": {
    "total": 100,
    "initial": 0,
    "configured": 0,
    "blocked": 0,
    "needsVerified": 0,
    "verifying": 0,
    "inProgress": 32,
    "failed": 10,
    "success": 58,
    "noSolution": 4,
    "noOperation": 6,
    "aborted": 0,
    "unknown": 0
  },
  "description": "string",
  "blockedBy": [
    "497f6eca-6276-4993-bfeb-53cbbbba6f08"
  ],
  "errors": [
    "string"
  ]
}
```

> 404 Response

<h3 id="get__actions_{actionid}_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ActionSummary](#schemaactionsummary)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|action set not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__actions_{actionID}_operations

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/operations HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/operations \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/operations', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/operations", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /actions/{actionID}/operations`

*Retrieve detailed information of a firmware action set*

Retrieve detailed information of a firmware action set.

<h3 id="get__actions_{actionid}_operations-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|actionID|path|string(uuid)|true|none|

> Example responses

> 200 Response

```json
{
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "snapshotID": "0a404cc5-4bd4-40f5-b698-aa34ab33b3fb",
  "startTime": "2019-08-24T14:15:22Z",
  "endTime": "2019-08-24T14:15:22Z",
  "state": "running",
  "description": "string",
  "operationSummary": {
    "initial": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "configured": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "blocked": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "needsVerified": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "verifying": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "inProgress": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "failed": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "success": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "noSolution": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "noOperation": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "aborted": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "unknown": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ]
  },
  "overrideDryrun": true,
  "parameters": {
    "stateComponentFilter": {
      "xnames": [
        "x0c0s0b0",
        "x0c0s2b0"
      ],
      "partitions": [
        "p1"
      ],
      "groups": [
        "red",
        "blue"
      ],
      "deviceTypes": [
        "nodeBMC"
      ]
    },
    "inventoryHardwareFilter": {
      "manufacturer": "cray",
      "model": "c5000"
    },
    "imageFilter": {
      "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
      "overrideImage": true
    },
    "targetFilter": {
      "targets": [
        "BIOS",
        "BMC"
      ]
    },
    "command": {
      "version": "latest",
      "tag": "default",
      "overrideDryrun": true,
      "restoreNotPossibleOverride": true,
      "overwriteSameImage": true,
      "timeLimit": 10000,
      "description": "update cabinet xxxx"
    }
  },
  "blockedBy": [
    "497f6eca-6276-4993-bfeb-53cbbbba6f08"
  ],
  "errors": [
    "string"
  ]
}
```

> 404 Response

<h3 id="get__actions_{actionid}_operations-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ActionDetail](#schemaactiondetail)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|action set not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__actions_{actionID}_operations_{operationID}

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/operations/{operationID} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/operations/{operationID} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/operations/{operationID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/actions/{actionID}/operations/{operationID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /actions/{actionID}/operations/{operationID}`

*Retrieve detailed information of a firmware operation.*

Retrieve detailed information of a firmware operation.

<h3 id="get__actions_{actionid}_operations_{operationid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|actionID|path|string(uuid)|true|none|
|operationID|path|string(uuid)|true|none|

> Example responses

> 200 Response

```json
{
  "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "startTime": "2019-08-24T14:15:22Z",
  "endTime": "2019-08-24T14:15:22Z",
  "state": "initial",
  "error": "string",
  "xname": "x0c0s2b0",
  "deviceType": "nodeBMC",
  "target": "bmc",
  "targetName": "bmc",
  "manufacturer": "cray",
  "model": "c5000",
  "softwareId": "string",
  "fromFirmwareVersion": "fw123.873US",
  "fromSemanticFirmwareVersion": "1.25.10",
  "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
  "fromTag": "default",
  "toFirmwareVersion": "fw456",
  "toSemanticFirmwareVersion": "1.35.0",
  "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
  "toTag": "recovery"
}
```

> 404 Response

<h3 id="get__actions_{actionid}_operations_{operationid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[Operation](#schemaoperation)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|action set not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__operations_{operationID}

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/operations/{operationID} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/operations/{operationID} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/operations/{operationID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/operations/{operationID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /operations/{operationID}`

*Retrieve detailed information of a firmware operation.*

Retrieve detailed information of a firmware operation.

<h3 id="get__operations_{operationid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|operationID|path|string(uuid)|true|none|

> Example responses

> 200 Response

```json
{
  "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "startTime": "2019-08-24T14:15:22Z",
  "endTime": "2019-08-24T14:15:22Z",
  "state": "initial",
  "error": "string",
  "xname": "x0c0s2b0",
  "deviceType": "nodeBMC",
  "target": "bmc",
  "targetName": "bmc",
  "manufacturer": "cray",
  "model": "c5000",
  "softwareId": "string",
  "fromFirmwareVersion": "fw123.873US",
  "fromSemanticFirmwareVersion": "1.25.10",
  "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
  "fromTag": "default",
  "toFirmwareVersion": "fw456",
  "toSemanticFirmwareVersion": "1.35.0",
  "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
  "toTag": "recovery"
}
```

> 404 Response

<h3 id="get__operations_{operationid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[Operation](#schemaoperation)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|operation not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="firmware-action-service-images">images</h1>

## post__images

> Code samples

```http
POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Content-Type": []string{"application/json"},
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /images`

*Create a new image record*

Create a new image record

> Body parameter

```json
{
  "deviceType": "nodeBMC",
  "manufacturer": "cray",
  "models": [
    [
      "c5000",
      "c5001"
    ]
  ],
  "target": "BIOS",
  "softwareIds": [
    "string"
  ],
  "tags": [
    [
      "recovery",
      "default"
    ]
  ],
  "firmwareVersion": "f1.123.24xz",
  "semanticFirmwareVersion": "1.2.252",
  "updateURI": "string",
  "needManualReboot": true,
  "waitTimeBeforeManualRebootSeconds": 0,
  "waitTimeAfterRebootSeconds": 0,
  "pollingSpeedSeconds": 0,
  "forceResetType": "string",
  "s3URL": "s3://firmware/f1.1123.24.xz.iso",
  "allowableDeviceStates": [
    "ON"
  ]
}
```

<h3 id="post__images-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ImageCreate](#schemaimagecreate)|true|a firmware image record|

> Example responses

> 200 Response

```json
{
  "imageID": "00000000-0000-0000-0000-000000000000"
}
```

> 400 Response

<h3 id="post__images-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ImageID](#schemaimageid)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Image Record Already Exists|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__images

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /images`

*Retrieve a list of images known to the system*

Retrieve a list of images that are known to the system.

> Example responses

> 200 Response

```json
{
  "images": [
    {
      "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
      "createTime": "2019-08-24T14:15:22Z",
      "deviceType": "nodeBMC",
      "manufacturer": "cray",
      "models": [
        "c5000"
      ],
      "target": "BIOS",
      "softwareIds": [
        "string"
      ],
      "tags": [
        [
          "recovery",
          "default"
        ]
      ],
      "firmwareVersion": "f1.123.24xz",
      "semanticFirmwareVersion": "1.2.252",
      "updateURI": "string",
      "needManualReboot": true,
      "waitTimeBeforeManualRebootSeconds": 0,
      "waitTimeAfterRebootSeconds": 0,
      "pollingSpeedSeconds": 0,
      "forceResetType": "string",
      "s3URL": "s3://firmware/f1.1123.24.xz.iso",
      "allowableDeviceStates": [
        "ON"
      ]
    }
  ]
}
```

<h3 id="get__images-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ImageList](#schemaimagelist)|

<aside class="success">
This operation does not require authentication
</aside>

## put__images_{imageID}

> Code samples

```http
PUT https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/error

```

```shell
# You can also use wget
curl -X PUT https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/error'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/error'
}

r = requests.put('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Content-Type": []string{"application/json"},
        "Accept": []string{"application/error"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PUT", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /images/{imageID}`

*Update the image record*

Modify or update an existing image record.

> Body parameter

```json
{
  "deviceType": "nodeBMC",
  "manufacturer": "cray",
  "models": [
    [
      "c5000",
      "c5001"
    ]
  ],
  "target": "BIOS",
  "softwareIds": [
    "string"
  ],
  "tags": [
    [
      "recovery",
      "default"
    ]
  ],
  "firmwareVersion": "f1.123.24xz",
  "semanticFirmwareVersion": "1.2.252",
  "updateURI": "string",
  "needManualReboot": true,
  "waitTimeBeforeManualRebootSeconds": 0,
  "waitTimeAfterRebootSeconds": 0,
  "pollingSpeedSeconds": 0,
  "forceResetType": "string",
  "s3URL": "s3://firmware/f1.1123.24.xz.iso",
  "allowableDeviceStates": [
    "ON"
  ]
}
```

<h3 id="put__images_{imageid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|imageID|path|string(uuid)|true|none|
|body|body|[ImageCreate](#schemaimagecreate)|true|image record|

> Example responses

> 400 Response

<h3 id="put__images_{imageid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Updated|None|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Created|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__images_{imageID}

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /images/{imageID}`

*Retrieve the image record*

Retrieve the image record that is associated with the imageID.

<h3 id="get__images_{imageid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|imageID|path|string(uuid)|true|none|

> Example responses

> 200 Response

```json
{
  "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
  "createTime": "2019-08-24T14:15:22Z",
  "deviceType": "nodeBMC",
  "manufacturer": "cray",
  "models": [
    "c5000"
  ],
  "target": "BIOS",
  "softwareIds": [
    "string"
  ],
  "tags": [
    [
      "recovery",
      "default"
    ]
  ],
  "firmwareVersion": "f1.123.24xz",
  "semanticFirmwareVersion": "1.2.252",
  "updateURI": "string",
  "needManualReboot": true,
  "waitTimeBeforeManualRebootSeconds": 0,
  "waitTimeAfterRebootSeconds": 0,
  "pollingSpeedSeconds": 0,
  "forceResetType": "string",
  "s3URL": "s3://firmware/f1.1123.24.xz.iso",
  "allowableDeviceStates": [
    "ON"
  ]
}
```

> 400 Response

<h3 id="get__images_{imageid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ImageGet](#schemaimageget)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## delete__images_{imageID}

> Code samples

```http
DELETE https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/error

```

```shell
# You can also use wget
curl -X DELETE https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID} \
  -H 'Accept: application/error'

```

```python
import requests
headers = {
  'Accept': 'application/error'
}

r = requests.delete('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/error"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/images/{imageID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /images/{imageID}`

*Delete an image record*

Deletes an image record from the FAS datastore. Does not delete the actual image from S3.

<h3 id="delete__images_{imageid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|imageID|path|string(uuid)|true|none|

> Example responses

> 400 Response

<h3 id="delete__images_{imageid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Successful delete|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="firmware-action-service-service">service</h1>

## get__service_status

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/status HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/status \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/status', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/status`

*Retrieve service status*

Retrieve the status of the Firmware Action Service.

> Example responses

> 200 Response

```json
{
  "serviceStatus": "running"
}
```

> 500 Response

<h3 id="get__service_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ServiceStatus](#schemaservicestatus)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__service_status_details

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/status/details HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/status/details \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/status/details', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/status/details", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/status/details`

*Retrieve service status details*

Retrieve the status of the Firmware Action Service. HSM, ETCD, Service Status and Version are returned.

> Example responses

> 200 Response

```json
{
  "serviceVersion": "1.2.0",
  "serviceStatus": "running",
  "hmsStatus": "connected",
  "storageStatus": "connected"
}
```

> 500 Response

<h3 id="get__service_status_details-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ServiceStatusDetails](#schemaservicestatusdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__service_version

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/version HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/version \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/version', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/service/version", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/version`

*Retrieve the service version*

Retrieve the internal version of FAS.

> Example responses

> 200 Response

```json
{
  "serviceVersion": "1.2.0"
}
```

> 500 Response

<h3 id="get__service_version-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ServiceVersion](#schemaserviceversion)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="firmware-action-service-snapshots">snapshots</h1>

## get__snapshots

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /snapshots`

*Return summary of all stored snapshots*

Return summary of all stored snapshots

> Example responses

> 200 Response

```json
{
  "snapshots": [
    {
      "name": "pre_system_upgrade",
      "captureTime": "2019-08-24T14:15:22Z",
      "expirationTime": "2019-08-24T14:15:22Z",
      "ready": false,
      "relatedActions": [
        {
          "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
          "startTime": "2019-08-24T14:15:22Z",
          "endTime": "2019-08-24T14:15:22Z",
          "state": "completed"
        }
      ],
      "uniqueDeviceCount": 0
    }
  ]
}
```

> 500 Response

<h3 id="get__snapshots-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[SnapshotAll](#schemasnapshotall)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__snapshots

> Code samples

```http
POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Content-Type": []string{"application/json"},
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /snapshots`

*Create a system snapshot*

Records a snapshot of the firmware versions for every target for every device that matches the query parameters.

> Body parameter

```json
{
  "name": "20200402_all_xnames",
  "expirationTime": "2019-08-24T14:15:22Z",
  "stateComponentFilter": {
    "xnames": [
      "x0c0s0b0",
      "x0c0s2b0"
    ],
    "partitions": [
      "p1"
    ],
    "groups": [
      "red",
      "blue"
    ],
    "deviceTypes": [
      "nodeBMC"
    ]
  },
  "inventoryHardwareFilter": {
    "manufacturer": "cray",
    "model": "c5000"
  },
  "targetFilter": {
    "targets": [
      "BIOS",
      "BMC"
    ]
  }
}
```

<h3 id="post__snapshots-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[SnapshotParameters](#schemasnapshotparameters)|true|Optional description in *Markdown*|

> Example responses

> 201 Response

```json
{
  "name": "20200402_all_xnames"
}
```

> 409 Response

<h3 id="post__snapshots-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|OK|[SnapshotID](#schemasnapshotid)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Duplicate, key already exists|[Problem7807](#schemaproblem7807)|

### Response Headers

|Status|Header|Type|Format|Description|
|---|---|---|---|---|
|201|Location|string||location of snapshot|

<aside class="success">
This operation does not require authentication
</aside>

## get__snapshots_{snapshotName}

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /snapshots/{snapshotName}`

*Retrieve a snapshot*

Retrieve a snapshot of the system

<h3 id="get__snapshots_{snapshotname}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|snapshotName|path|string|true|none|

> Example responses

> 200 Response

```json
{
  "name": "string",
  "captureTime": "2019-08-24T14:15:22Z",
  "expirationTime": "2019-08-24T14:15:22Z",
  "ready": false,
  "relatedActions": [
    {
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "completed"
    }
  ],
  "devices": [
    {
      "xname": "x0c0s2b0",
      "targets": [
        {
          "name": "BIOS",
          "firmwareVersion": "fw123.8s",
          "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
          "error": "string"
        }
      ],
      "error": "string"
    }
  ],
  "parameters": {
    "name": "20200402_all_xnames",
    "expirationTime": "2019-08-24T14:15:22Z",
    "stateComponentFilter": {
      "xnames": [
        "x0c0s0b0",
        "x0c0s2b0"
      ],
      "partitions": [
        "p1"
      ],
      "groups": [
        "red",
        "blue"
      ],
      "deviceTypes": [
        "nodeBMC"
      ]
    },
    "inventoryHardwareFilter": {
      "manufacturer": "cray",
      "model": "c5000"
    },
    "targetFilter": {
      "targets": [
        "BIOS",
        "BMC"
      ]
    }
  },
  "errors": [
    "string"
  ]
}
```

> 404 Response

<h3 id="get__snapshots_{snapshotname}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[Snapshot](#schemasnapshot)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## delete__snapshots_{snapshotName}

> Code samples

```http
DELETE https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/error

```

```shell
# You can also use wget
curl -X DELETE https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName} \
  -H 'Accept: application/error'

```

```python
import requests
headers = {
  'Accept': 'application/error'
}

r = requests.delete('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/error"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /snapshots/{snapshotName}`

*Delete a snapshot*

Delete a snapshot of the system. Does not delete any firmware images from S3.

<h3 id="delete__snapshots_{snapshotname}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|snapshotName|path|string|true|none|

> Example responses

> 404 Response

<h3 id="delete__snapshots_{snapshotname}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Successful delete|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__snapshots_{snapshotName}_restore

> Code samples

```http
POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName}/restore?confirm=yes HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName}/restore?confirm=yes \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.post('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName}/restore', params={
  'confirm': 'yes'
}, headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/snapshots/{snapshotName}/restore", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /snapshots/{snapshotName}/restore`

*Restore system snapshot*

Restore a snapshot by replacing each component (device + target) with the stored version. Note that you are prompted for a confirmation.

<h3 id="post__snapshots_{snapshotname}_restore-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|snapshotName|path|string|true|none|
|overrideDryrun|query|boolean|false|Note that leaving this blank or misspelling true is considered false resulting in a dryrun restore action to be performed. You must specify true to force an actual update|
|confirm|query|string|true|none|
|timeLimit|query|integer|false|time limit in seconds that any operation for a firmware action may be allowed to attempt to complete.|

> Example responses

> 202 Response

```json
{
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "overrideDryrun": true
}
```

> 400 Response

<h3 id="post__snapshots_{snapshotname}_restore-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|request to restore accepted. Creating firmware action set|[ActionID](#schemaactionid)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Snapshot name not found|[Problem7807](#schemaproblem7807)|

### Response Headers

|Status|Header|Type|Format|Description|
|---|---|---|---|---|
|202|Location|string|uuid|actionID of the created firmware action set|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="firmware-action-service-loader">loader</h1>

## post__loader

> Code samples

```http
POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/octet-stream
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader \
  -H 'Content-Type: application/octet-stream' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/octet-stream',
  'Accept': 'application/json'
}

r = requests.post('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Content-Type": []string{"application/octet-stream"},
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /loader`

*Upload a file to be processed by the loader*

Upload a file for the loader to add to S3 and create a FAS compatible image record

> Body parameter

```yaml
string

```

<h3 id="post__loader-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|string(binary)|false|none|

> Example responses

> 200 Response

```json
{
  "loaderRunID": "3b7e76fb-4b2e-45d8-9266-664b8966d691"
}
```

> 400 Response

<h3 id="post__loader-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[LoaderRunID](#schemaloaderrunid)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request - No file found|[Problem7807](#schemaproblem7807)|
|415|[Unsupported Media Type](https://tools.ietf.org/html/rfc7231#section-6.5.13)|Unsupported Media Type|[Problem7807](#schemaproblem7807)|
|429|[Too Many Requests](https://tools.ietf.org/html/rfc6585#section-4)|Loader busy, try again later|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__loader

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /loader`

*Return the loader status and list of loader runs*

Return the loader status and list loader runs

> Example responses

> 200 Response

```json
{
  "loaderStatus": "busy",
  "loaderRunList": [
    "497f6eca-6276-4993-bfeb-53cbbbba6f08"
  ]
}
```

<h3 id="get__loader-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[LoaderStatus](#schemaloaderstatus)|

<aside class="success">
This operation does not require authentication
</aside>

## get__loader_{loaderRunID}

> Code samples

```http
GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/{loaderRunID} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/{loaderRunID} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/{loaderRunID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/{loaderRunID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /loader/{loaderRunID}`

*Return the results of a loader run*

Return the results of a loader run

<h3 id="get__loader_{loaderrunid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|loaderRunID|path|string(uuid)|true|none|

> Example responses

> 200 Response

```json
{
  "loaderRunOutput": [
    "string"
  ]
}
```

> 404 Response

<h3 id="get__loader_{loaderrunid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[LoaderRunOutput](#schemaloaderrunoutput)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## delete__loader_{loaderRunID}

> Code samples

```http
DELETE https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/{loaderRunID} HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/error

```

```shell
# You can also use wget
curl -X DELETE https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/{loaderRunID} \
  -H 'Accept: application/error'

```

```python
import requests
headers = {
  'Accept': 'application/error'
}

r = requests.delete('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/{loaderRunID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/error"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/{loaderRunID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /loader/{loaderRunID}`

*Delete a loader run*

Delete a loader run

<h3 id="delete__loader_{loaderrunid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|loaderRunID|path|string(uuid)|true|none|

> Example responses

> 404 Response

<h3 id="delete__loader_{loaderrunid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Successful delete|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__loader_nexus

> Code samples

```http
POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/nexus HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/nexus \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.post('https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/nexus', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://rocket-ncn-w001.us.cray.com/apis/fas/v1/loader/nexus", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /loader/nexus`

*loader firmware images from the Nexus library*

Have the loader read the firmware library from Nexus and add to S3 and create FAS compatible image records

> Example responses

> 200 Response

```json
{
  "loaderRunID": "3b7e76fb-4b2e-45d8-9266-664b8966d691"
}
```

> 429 Response

<h3 id="post__loader_nexus-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[LoaderRunID](#schemaloaderrunid)|
|429|[Too Many Requests](https://tools.ietf.org/html/rfc6585#section-4)|Loader busy, try again later|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_LoaderStatus">LoaderStatus</h2>
<!-- backwards compatibility -->
<a id="schemaloaderstatus"></a>
<a id="schema_LoaderStatus"></a>
<a id="tocSloaderstatus"></a>
<a id="tocsloaderstatus"></a>

```json
{
  "loaderStatus": "busy",
  "loaderRunList": [
    "497f6eca-6276-4993-bfeb-53cbbbba6f08"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|loaderStatus|string|false|none|none|
|loaderRunList|[string]|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|loaderStatus|busy|
|loaderStatus|ready|

<h2 id="tocS_LoaderRunID">LoaderRunID</h2>
<!-- backwards compatibility -->
<a id="schemaloaderrunid"></a>
<a id="schema_LoaderRunID"></a>
<a id="tocSloaderrunid"></a>
<a id="tocsloaderrunid"></a>

```json
{
  "loaderRunID": "3b7e76fb-4b2e-45d8-9266-664b8966d691"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|loaderRunID|string(uuid)|false|none|none|

<h2 id="tocS_LoaderRunOutput">LoaderRunOutput</h2>
<!-- backwards compatibility -->
<a id="schemaloaderrunoutput"></a>
<a id="schema_LoaderRunOutput"></a>
<a id="tocSloaderrunoutput"></a>
<a id="tocsloaderrunoutput"></a>

```json
{
  "loaderRunOutput": [
    "string"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|loaderRunOutput|[string]|false|none|none|

<h2 id="tocS_ActionSummary">ActionSummary</h2>
<!-- backwards compatibility -->
<a id="schemaactionsummary"></a>
<a id="schema_ActionSummary"></a>
<a id="tocSactionsummary"></a>
<a id="tocsactionsummary"></a>

```json
{
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "snapshotID": "0a404cc5-4bd4-40f5-b698-aa34ab33b3fb",
  "overrideDryrun": true,
  "startTime": "2019-08-24T14:15:22Z",
  "endTime": "2019-08-24T14:15:22Z",
  "state": "running",
  "operationCounts": {
    "total": 100,
    "initial": 0,
    "configured": 0,
    "blocked": 0,
    "needsVerified": 0,
    "verifying": 0,
    "inProgress": 32,
    "failed": 10,
    "success": 58,
    "noSolution": 4,
    "noOperation": 6,
    "aborted": 0,
    "unknown": 0
  },
  "description": "string",
  "blockedBy": [
    "497f6eca-6276-4993-bfeb-53cbbbba6f08"
  ],
  "errors": [
    "string"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|actionID|string(uuid)|false|none|none|
|snapshotID|string(uuid)|false|none|none|
|overrideDryrun|boolean|false|none|none|
|startTime|string(date-time)|false|none|none|
|endTime|string(date-time)|false|none|none|
|state|string|false|none|The state of the action -<br><br>  *new* - not yet started<br>  *configured* - configured, but not yet started<br>  *blocked* - configured, but cannot run because another action is executing<br>  *running* - started<br>  *completed* - the action has completed all operations<br>  *abortSignaled* - the action has been instructed to STOP all running operations<br>  *aborted* - the action has stopped all operations|
|operationCounts|[OperationCounts](#schemaoperationcounts)|false|none|none|
|description|string|false|none|none|
|blockedBy|[string]|false|none|none|
|errors|[string]|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|state|new|
|state|configure|
|state|blocked|
|state|running|
|state|completed|
|state|abortSignaled|
|state|aborted|

<h2 id="tocS_ActionSummarys">ActionSummarys</h2>
<!-- backwards compatibility -->
<a id="schemaactionsummarys"></a>
<a id="schema_ActionSummarys"></a>
<a id="tocSactionsummarys"></a>
<a id="tocsactionsummarys"></a>

```json
{
  "actions": [
    {
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "snapshotID": "0a404cc5-4bd4-40f5-b698-aa34ab33b3fb",
      "overrideDryrun": true,
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "running",
      "operationCounts": {
        "total": 100,
        "initial": 0,
        "configured": 0,
        "blocked": 0,
        "needsVerified": 0,
        "verifying": 0,
        "inProgress": 32,
        "failed": 10,
        "success": 58,
        "noSolution": 4,
        "noOperation": 6,
        "aborted": 0,
        "unknown": 0
      },
      "description": "string",
      "blockedBy": [
        "497f6eca-6276-4993-bfeb-53cbbbba6f08"
      ],
      "errors": [
        "string"
      ]
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|actions|[[ActionSummary](#schemaactionsummary)]|false|none|none|

<h2 id="tocS_Action">Action</h2>
<!-- backwards compatibility -->
<a id="schemaaction"></a>
<a id="schema_Action"></a>
<a id="tocSaction"></a>
<a id="tocsaction"></a>

```json
{
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "snapshotID": "0a404cc5-4bd4-40f5-b698-aa34ab33b3fb",
  "startTime": "2019-08-24T14:15:22Z",
  "endTime": "2019-08-24T14:15:22Z",
  "state": "running",
  "description": "string",
  "operationSummary": {
    "initial": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "configured": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "blocked": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "needsVerified": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "verifying": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "inProgress": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "failed": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "success": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "noSolution": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "noOperation": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "aborted": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ],
    "unknown": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "xname": "string",
        "target": "string",
        "targetName": "string",
        "fromFirmwareVersion": "string",
        "stateHelper": "string"
      }
    ]
  },
  "overrideDryrun": true,
  "parameters": {
    "stateComponentFilter": {
      "xnames": [
        "x0c0s0b0",
        "x0c0s2b0"
      ],
      "partitions": [
        "p1"
      ],
      "groups": [
        "red",
        "blue"
      ],
      "deviceTypes": [
        "nodeBMC"
      ]
    },
    "inventoryHardwareFilter": {
      "manufacturer": "cray",
      "model": "c5000"
    },
    "imageFilter": {
      "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
      "overrideImage": true
    },
    "targetFilter": {
      "targets": [
        "BIOS",
        "BMC"
      ]
    },
    "command": {
      "version": "latest",
      "tag": "default",
      "overrideDryrun": true,
      "restoreNotPossibleOverride": true,
      "overwriteSameImage": true,
      "timeLimit": 10000,
      "description": "update cabinet xxxx"
    }
  },
  "blockedBy": [
    "497f6eca-6276-4993-bfeb-53cbbbba6f08"
  ],
  "errors": [
    "string"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|actionID|string(uuid)|false|none|none|
|snapshotID|string(uuid)|false|none|none|
|startTime|string(date-time)|false|none|none|
|endTime|string(date-time)|false|none|none|
|state|string|false|none|The state of the action -<br><br>  *new* - not yet started<br>  *configured* - configured, but not yet started<br>  *blocked* - configured, but cannot run because another action is executing<br>  *running* - started<br>  *completed* - the action has completed all operations<br>  *abortSignaled* - the action has been instructed to STOP all running operations<br>  *aborted* - the action has stopped all operations|
|description|string|false|none|none|
|operationSummary|[OperationSummary](#schemaoperationsummary)|false|none|none|
|overrideDryrun|boolean|false|none|none|
|parameters|[ActionParameters](#schemaactionparameters)|false|none|none|
|blockedBy|[string]|false|none|none|
|errors|[string]|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|state|new|
|state|configure|
|state|blocked|
|state|running|
|state|completed|
|state|abortSignaled|
|state|aborted|

<h2 id="tocS_ActionDetail">ActionDetail</h2>
<!-- backwards compatibility -->
<a id="schemaactiondetail"></a>
<a id="schema_ActionDetail"></a>
<a id="tocSactiondetail"></a>
<a id="tocsactiondetail"></a>

```json
{
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "snapshotID": "0a404cc5-4bd4-40f5-b698-aa34ab33b3fb",
  "startTime": "2019-08-24T14:15:22Z",
  "endTime": "2019-08-24T14:15:22Z",
  "state": "running",
  "description": "string",
  "operationSummary": {
    "initial": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "configured": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "blocked": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "needsVerified": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "verifying": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "inProgress": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "failed": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "success": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "noSolution": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "noOperation": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "aborted": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ],
    "unknown": [
      {
        "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
        "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
        "startTime": "2019-08-24T14:15:22Z",
        "endTime": "2019-08-24T14:15:22Z",
        "state": "initial",
        "error": "string",
        "xname": "x0c0s2b0",
        "deviceType": "nodeBMC",
        "target": "bmc",
        "targetName": "bmc",
        "manufacturer": "cray",
        "model": "c5000",
        "softwareId": "string",
        "fromFirmwareVersion": "fw123.873US",
        "fromSemanticFirmwareVersion": "1.25.10",
        "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
        "fromTag": "default",
        "toFirmwareVersion": "fw456",
        "toSemanticFirmwareVersion": "1.35.0",
        "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
        "toTag": "recovery"
      }
    ]
  },
  "overrideDryrun": true,
  "parameters": {
    "stateComponentFilter": {
      "xnames": [
        "x0c0s0b0",
        "x0c0s2b0"
      ],
      "partitions": [
        "p1"
      ],
      "groups": [
        "red",
        "blue"
      ],
      "deviceTypes": [
        "nodeBMC"
      ]
    },
    "inventoryHardwareFilter": {
      "manufacturer": "cray",
      "model": "c5000"
    },
    "imageFilter": {
      "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
      "overrideImage": true
    },
    "targetFilter": {
      "targets": [
        "BIOS",
        "BMC"
      ]
    },
    "command": {
      "version": "latest",
      "tag": "default",
      "overrideDryrun": true,
      "restoreNotPossibleOverride": true,
      "overwriteSameImage": true,
      "timeLimit": 10000,
      "description": "update cabinet xxxx"
    }
  },
  "blockedBy": [
    "497f6eca-6276-4993-bfeb-53cbbbba6f08"
  ],
  "errors": [
    "string"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|actionID|string(uuid)|false|none|none|
|snapshotID|string(uuid)|false|none|none|
|startTime|string(date-time)|false|none|none|
|endTime|string(date-time)|false|none|none|
|state|string|false|none|The state of the action -<br><br>  *new* - not yet started<br>  *configured* - configured, but not yet started<br>  *blocked* - configured, but cannot run because another action is executing<br>  *running* - started<br>  *completed* - the action has completed all operations<br>  *abortSignaled* - the action has been instructed to STOP all running operations<br>  *aborted* - the action has stopped all operations|
|description|string|false|none|none|
|operationSummary|[OperationDetail](#schemaoperationdetail)|false|none|none|
|overrideDryrun|boolean|false|none|none|
|parameters|[ActionParameters](#schemaactionparameters)|false|none|none|
|blockedBy|[string]|false|none|none|
|errors|[string]|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|state|new|
|state|configure|
|state|blocked|
|state|running|
|state|completed|
|state|abortSignaled|
|state|aborted|

<h2 id="tocS_ActionID">ActionID</h2>
<!-- backwards compatibility -->
<a id="schemaactionid"></a>
<a id="schema_ActionID"></a>
<a id="tocSactionid"></a>
<a id="tocsactionid"></a>

```json
{
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "overrideDryrun": true
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|actionID|string(uuid)|false|none|none|
|overrideDryrun|boolean|false|none|this field represents if the automatic dryrun was overridden by command.|

<h2 id="tocS_ActionParameters">ActionParameters</h2>
<!-- backwards compatibility -->
<a id="schemaactionparameters"></a>
<a id="schema_ActionParameters"></a>
<a id="tocSactionparameters"></a>
<a id="tocsactionparameters"></a>

```json
{
  "stateComponentFilter": {
    "xnames": [
      "x0c0s0b0",
      "x0c0s2b0"
    ],
    "partitions": [
      "p1"
    ],
    "groups": [
      "red",
      "blue"
    ],
    "deviceTypes": [
      "nodeBMC"
    ]
  },
  "inventoryHardwareFilter": {
    "manufacturer": "cray",
    "model": "c5000"
  },
  "imageFilter": {
    "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
    "overrideImage": true
  },
  "targetFilter": {
    "targets": [
      "BIOS",
      "BMC"
    ]
  },
  "command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": true,
    "restoreNotPossibleOverride": true,
    "overwriteSameImage": true,
    "timeLimit": 10000,
    "description": "update cabinet xxxx"
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|stateComponentFilter|[ActionParameters_StateComponentFilter](#schemaactionparameters_statecomponentfilter)|false|none|none|
|inventoryHardwareFilter|[ActionParameters_HardwareFilter](#schemaactionparameters_hardwarefilter)|false|none|none|
|imageFilter|[ActionParameters_ImageFilter](#schemaactionparameters_imagefilter)|false|none|none|
|targetFilter|[ActionParameters_TargetFilter](#schemaactionparameters_targetfilter)|false|none|none|
|command|[ActionParameters_Command](#schemaactionparameters_command)|false|none|none|

<h2 id="tocS_ActionParameters_StateComponentFilter">ActionParameters_StateComponentFilter</h2>
<!-- backwards compatibility -->
<a id="schemaactionparameters_statecomponentfilter"></a>
<a id="schema_ActionParameters_StateComponentFilter"></a>
<a id="tocSactionparameters_statecomponentfilter"></a>
<a id="tocsactionparameters_statecomponentfilter"></a>

```json
{
  "xnames": [
    "x0c0s0b0",
    "x0c0s2b0"
  ],
  "partitions": [
    "p1"
  ],
  "groups": [
    "red",
    "blue"
  ],
  "deviceTypes": [
    "nodeBMC"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xnames|[string]|false|none|none|
|partitions|[string]|false|none|none|
|groups|[string]|false|none|none|
|deviceTypes|[string]|false|none|none|

<h2 id="tocS_ActionParameters_HardwareFilter">ActionParameters_HardwareFilter</h2>
<!-- backwards compatibility -->
<a id="schemaactionparameters_hardwarefilter"></a>
<a id="schema_ActionParameters_HardwareFilter"></a>
<a id="tocSactionparameters_hardwarefilter"></a>
<a id="tocsactionparameters_hardwarefilter"></a>

```json
{
  "manufacturer": "cray",
  "model": "c5000"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|manufacturer|string|false|none|none|
|model|string|false|none|none|

<h2 id="tocS_ActionParameters_TargetFilter">ActionParameters_TargetFilter</h2>
<!-- backwards compatibility -->
<a id="schemaactionparameters_targetfilter"></a>
<a id="schema_ActionParameters_TargetFilter"></a>
<a id="tocSactionparameters_targetfilter"></a>
<a id="tocsactionparameters_targetfilter"></a>

```json
{
  "targets": [
    "BIOS",
    "BMC"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|targets|[string]|false|none|none|

<h2 id="tocS_ActionParameters_ImageFilter">ActionParameters_ImageFilter</h2>
<!-- backwards compatibility -->
<a id="schemaactionparameters_imagefilter"></a>
<a id="schema_ActionParameters_ImageFilter"></a>
<a id="tocSactionparameters_imagefilter"></a>
<a id="tocsactionparameters_imagefilter"></a>

```json
{
  "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
  "overrideImage": true
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|imageID|string(uuid)|false|none|none|
|overrideImage|boolean|false|none|Will not check device properties against image properties to ensure valid image.  Default is false.|

<h2 id="tocS_ActionParameters_Command">ActionParameters_Command</h2>
<!-- backwards compatibility -->
<a id="schemaactionparameters_command"></a>
<a id="schema_ActionParameters_Command"></a>
<a id="tocSactionparameters_command"></a>
<a id="tocsactionparameters_command"></a>

```json
{
  "version": "latest",
  "tag": "default",
  "overrideDryrun": true,
  "restoreNotPossibleOverride": true,
  "overwriteSameImage": true,
  "timeLimit": 10000,
  "description": "update cabinet xxxx"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|version|string|false|none|Go to the latest, earliest semantic version, or explicitly set a specific version as per the imageID.|
|tag|string|false|none|none|
|overrideDryrun|boolean|false|none|causes the action to be executed instead of simulated.  False by default. Checks to see if there are images available to update device firmware as desired.|
|restoreNotPossibleOverride|boolean|false|none|Force the operation, even if the `fromFirmwareVersion` cannot be found. Default to false|
|overwriteSameImage|boolean|false|none|Force the operation, even if the 'fromFirmwareVersion' and the 'toFirmwareVersion' are the same.  Default to false.|
|timeLimit|integer|false|none|time limit for any operation in seconds|
|description|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|version|latest|
|version|earliest|
|version|explicit|

<h2 id="tocS_DeviceFirmware">DeviceFirmware</h2>
<!-- backwards compatibility -->
<a id="schemadevicefirmware"></a>
<a id="schema_DeviceFirmware"></a>
<a id="tocSdevicefirmware"></a>
<a id="tocsdevicefirmware"></a>

```json
{
  "xname": "x0c0s2b0",
  "targets": [
    {
      "name": "BIOS",
      "firmwareVersion": "fw123.8s",
      "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
      "error": "string"
    }
  ],
  "error": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xname|string|false|none|none|
|targets|[[Target](#schematarget)]|false|none|none|
|error|string|false|none|any error that was encountered while populating device information|

<h2 id="tocS_ImageCreate">ImageCreate</h2>
<!-- backwards compatibility -->
<a id="schemaimagecreate"></a>
<a id="schema_ImageCreate"></a>
<a id="tocSimagecreate"></a>
<a id="tocsimagecreate"></a>

```json
{
  "deviceType": "nodeBMC",
  "manufacturer": "cray",
  "models": [
    [
      "c5000",
      "c5001"
    ]
  ],
  "target": "BIOS",
  "softwareIds": [
    "string"
  ],
  "tags": [
    [
      "recovery",
      "default"
    ]
  ],
  "firmwareVersion": "f1.123.24xz",
  "semanticFirmwareVersion": "1.2.252",
  "updateURI": "string",
  "needManualReboot": true,
  "waitTimeBeforeManualRebootSeconds": 0,
  "waitTimeAfterRebootSeconds": 0,
  "pollingSpeedSeconds": 0,
  "forceResetType": "string",
  "s3URL": "s3://firmware/f1.1123.24.xz.iso",
  "allowableDeviceStates": [
    "ON"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|deviceType|string|false|none|node type|
|manufacturer|string|false|none|none|
|models|[string]|false|none|none|
|target|string|false|none|node target|
|softwareIds|[string]|false|none|none|
|tags|[string]|true|none|none|
|firmwareVersion|string|true|none|none|
|semanticFirmwareVersion|string|true|none|none|
|updateURI|string|false|none|where to point the update at|
|needManualReboot|boolean|false|none|whether or not FAS needs to initiate a manual reboot after the update command has been issued|
|waitTimeBeforeManualRebootSeconds|integer|false|none|amount of time to wait after an update to perform a manual reboot|
|waitTimeAfterRebootSeconds|integer|false|none|amount of time to wait after a manual reboot before proceeding to verification step|
|pollingSpeedSeconds|integer|false|none|amount of time to wait between requests to the device to avoid overloading it|
|forceResetType|string|false|none|the command to issue to the Redfish device to force a reboot|
|s3URL|string|true|none|none|
|allowableDeviceStates|[string]|false|none|none|

<h2 id="tocS_ImageGet">ImageGet</h2>
<!-- backwards compatibility -->
<a id="schemaimageget"></a>
<a id="schema_ImageGet"></a>
<a id="tocSimageget"></a>
<a id="tocsimageget"></a>

```json
{
  "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
  "createTime": "2019-08-24T14:15:22Z",
  "deviceType": "nodeBMC",
  "manufacturer": "cray",
  "models": [
    "c5000"
  ],
  "target": "BIOS",
  "softwareIds": [
    "string"
  ],
  "tags": [
    [
      "recovery",
      "default"
    ]
  ],
  "firmwareVersion": "f1.123.24xz",
  "semanticFirmwareVersion": "1.2.252",
  "updateURI": "string",
  "needManualReboot": true,
  "waitTimeBeforeManualRebootSeconds": 0,
  "waitTimeAfterRebootSeconds": 0,
  "pollingSpeedSeconds": 0,
  "forceResetType": "string",
  "s3URL": "s3://firmware/f1.1123.24.xz.iso",
  "allowableDeviceStates": [
    "ON"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|imageID|string(uuid)|false|none|none|
|createTime|string(date-time)|false|none|none|
|deviceType|string|false|none|node type|
|manufacturer|string|false|none|none|
|models|[string]|false|none|none|
|target|string|true|none|node target|
|softwareIds|[string]|false|none|none|
|tags|[string]|false|none|none|
|firmwareVersion|string|false|none|none|
|semanticFirmwareVersion|string|false|none|none|
|updateURI|string|false|none|where to point the update at|
|needManualReboot|boolean|false|none|whether or not FAS needs to initiate a manual reboot after the update command has been issued|
|waitTimeBeforeManualRebootSeconds|integer|false|none|amount of time to wait after an update to perform a manual reboot|
|waitTimeAfterRebootSeconds|integer|false|none|amount of time to wait after a manual reboot before proceeding to verification step|
|pollingSpeedSeconds|integer|false|none|amount of time to wait between requests to the device to avoid overloading it|
|forceResetType|string|false|none|the command to issue to the Redfish device to force a reboot|
|s3URL|string|false|none|none|
|allowableDeviceStates|[string]|false|none|none|

<h2 id="tocS_ImageID">ImageID</h2>
<!-- backwards compatibility -->
<a id="schemaimageid"></a>
<a id="schema_ImageID"></a>
<a id="tocSimageid"></a>
<a id="tocsimageid"></a>

```json
{
  "imageID": "00000000-0000-0000-0000-000000000000"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|imageID|string(uuid)|false|none|none|

<h2 id="tocS_ImageList">ImageList</h2>
<!-- backwards compatibility -->
<a id="schemaimagelist"></a>
<a id="schema_ImageList"></a>
<a id="tocSimagelist"></a>
<a id="tocsimagelist"></a>

```json
{
  "images": [
    {
      "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
      "createTime": "2019-08-24T14:15:22Z",
      "deviceType": "nodeBMC",
      "manufacturer": "cray",
      "models": [
        "c5000"
      ],
      "target": "BIOS",
      "softwareIds": [
        "string"
      ],
      "tags": [
        [
          "recovery",
          "default"
        ]
      ],
      "firmwareVersion": "f1.123.24xz",
      "semanticFirmwareVersion": "1.2.252",
      "updateURI": "string",
      "needManualReboot": true,
      "waitTimeBeforeManualRebootSeconds": 0,
      "waitTimeAfterRebootSeconds": 0,
      "pollingSpeedSeconds": 0,
      "forceResetType": "string",
      "s3URL": "s3://firmware/f1.1123.24.xz.iso",
      "allowableDeviceStates": [
        "ON"
      ]
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|images|array|false|none|none|

<h2 id="tocS_Operation">Operation</h2>
<!-- backwards compatibility -->
<a id="schemaoperation"></a>
<a id="schema_Operation"></a>
<a id="tocSoperation"></a>
<a id="tocsoperation"></a>

```json
{
  "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "startTime": "2019-08-24T14:15:22Z",
  "endTime": "2019-08-24T14:15:22Z",
  "state": "initial",
  "error": "string",
  "xname": "x0c0s2b0",
  "deviceType": "nodeBMC",
  "target": "bmc",
  "targetName": "bmc",
  "manufacturer": "cray",
  "model": "c5000",
  "softwareId": "string",
  "fromFirmwareVersion": "fw123.873US",
  "fromSemanticFirmwareVersion": "1.25.10",
  "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
  "fromTag": "default",
  "toFirmwareVersion": "fw456",
  "toSemanticFirmwareVersion": "1.35.0",
  "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
  "toTag": "recovery"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|operationID|string(uuid)|false|none|none|
|actionID|string(uuid)|false|none|none|
|startTime|string(date-time)|false|none|none|
|endTime|string(date-time)|false|none|none|
|state|string|false|none|The state of the operation -<br><br>  *initial* - not yet started<br>  *configured* - configured, but not yet started<br>  *blocked* - cannot run because another operation is blocking this<br>  *inProgress* - operation started - sent update command<br>  *needsVerified* - operation was sent update command, waiting for finish to verify<br>  *verifying* - operation verifying operation<br>  *aborted* - operation was aborted<br>  *noOperation* - operation has nothing to do - already at firmware level<br>  *noSolution* - operation could not find a firmware to flash<br>  *succeeded* - operation completed successfully<br>  *failed* - operation failed|
|error|string|false|none|none|
|xname|string|false|none|none|
|deviceType|string|false|none|none|
|target|string|false|none|none|
|targetName|string|false|none|none|
|manufacturer|string|false|none|none|
|model|string|false|none|none|
|softwareId|string|false|none|none|
|fromFirmwareVersion|string|false|none|none|
|fromSemanticFirmwareVersion|string|false|none|none|
|fromImageURL|string|false|none|none|
|fromTag|string|false|none|none|
|toFirmwareVersion|string|false|none|none|
|toSemanticFirmwareVersion|string|false|none|none|
|toImageURL|string|false|none|none|
|toTag|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|state|initial|
|state|configured|
|state|blocked|
|state|inProgress|
|state|needsVerified|
|state|verifying|
|state|abort|
|state|noOperation|
|state|noSolution|
|state|succeeded|
|state|failed|

<h2 id="tocS_OperationCounts">OperationCounts</h2>
<!-- backwards compatibility -->
<a id="schemaoperationcounts"></a>
<a id="schema_OperationCounts"></a>
<a id="tocSoperationcounts"></a>
<a id="tocsoperationcounts"></a>

```json
{
  "total": 100,
  "initial": 0,
  "configured": 0,
  "blocked": 0,
  "needsVerified": 0,
  "verifying": 0,
  "inProgress": 32,
  "failed": 10,
  "success": 58,
  "noSolution": 4,
  "noOperation": 6,
  "aborted": 0,
  "unknown": 0
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|total|integer|false|none|total count of all operations|
|initial|integer|false|none|count of operations that have not yet been configured|
|configured|integer|false|none|count of operations that have been configured but not started|
|blocked|integer|false|none|count of operations that have been configured, but cannot yet launch because another operation is pending on the same xname|
|needsVerified|integer|false|none|count of operations that have been started, but need final verification to determine if the operation was successful|
|verifying|integer|false|none|count of operations that have started verification, but are not finished verification.|
|inProgress|integer|false|none|count of operations that have been started, but have not reach the verification stage.|
|failed|integer|false|none|count of operations that have failed to complete firmware task|
|success|integer|false|none|count of operations that have succeeded in completing firmware task|
|noSolution|integer|false|none|count of operations that have no viable solution to satisfy the request.  This is usually because no suitable image exists.|
|noOperation|integer|false|none|count of operations that do not need to be executed, because the desired end state is already achieved.|
|aborted|integer|false|none|count of operations that have been aborted.  It is indeterminate if their firmware task was executed.|
|unknown|integer|false|none|count of unknown states -> should not be present.|

<h2 id="tocS_OperationSummary">OperationSummary</h2>
<!-- backwards compatibility -->
<a id="schemaoperationsummary"></a>
<a id="schema_OperationSummary"></a>
<a id="tocSoperationsummary"></a>
<a id="tocsoperationsummary"></a>

```json
{
  "initial": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "configured": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "blocked": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "needsVerified": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "verifying": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "inProgress": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "failed": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "success": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "noSolution": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "noOperation": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "aborted": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ],
  "unknown": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "xname": "string",
      "target": "string",
      "targetName": "string",
      "fromFirmwareVersion": "string",
      "stateHelper": "string"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|initial|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that have not yet been configured|
|configured|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that have been configured but not started|
|blocked|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that have been configured, but cannot yet launch because another operation is pending on the same xname|
|needsVerified|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that have been started, but need final verification to determine if the operation was successful|
|verifying|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that have started verification, but are not finished verification.|
|inProgress|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that have been started, but have not reach the verification stage.|
|failed|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that have failed to complete firmware task|
|success|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that have succeeded in completing firmware task|
|noSolution|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that have no viable solution to satisfy the request.  This is usually because no suitable image exists.|
|noOperation|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that do not need to be executed, because the desired end state is already achieved.|
|aborted|[[OperationKey](#schemaoperationkey)]|false|none|count of operations that have been aborted.  It is indeterminate if their firmware task was executed.|
|unknown|[[OperationKey](#schemaoperationkey)]|false|none|count of unknown states -> should not be present.|

<h2 id="tocS_OperationDetail">OperationDetail</h2>
<!-- backwards compatibility -->
<a id="schemaoperationdetail"></a>
<a id="schema_OperationDetail"></a>
<a id="tocSoperationdetail"></a>
<a id="tocsoperationdetail"></a>

```json
{
  "initial": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "configured": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "blocked": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "needsVerified": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "verifying": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "inProgress": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "failed": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "success": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "noSolution": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "noOperation": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "aborted": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ],
  "unknown": [
    {
      "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "initial",
      "error": "string",
      "xname": "x0c0s2b0",
      "deviceType": "nodeBMC",
      "target": "bmc",
      "targetName": "bmc",
      "manufacturer": "cray",
      "model": "c5000",
      "softwareId": "string",
      "fromFirmwareVersion": "fw123.873US",
      "fromSemanticFirmwareVersion": "1.25.10",
      "fromImageURL": "s3://fw-update/01ca4727-27d7-43a6-9c5b-f9dfcf805ded/filename.bin",
      "fromTag": "default",
      "toFirmwareVersion": "fw456",
      "toSemanticFirmwareVersion": "1.35.0",
      "toImageURL": "s3://fw-update/3586af8d-0fba-4bfa-8fc5-782764d335e8/filename-1.0.bin",
      "toTag": "recovery"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|initial|[[Operation](#schemaoperation)]|false|none|count of operations that have not yet been configured|
|configured|[[Operation](#schemaoperation)]|false|none|count of operations that have been configured but not started|
|blocked|[[Operation](#schemaoperation)]|false|none|count of operations that have been configured, but cannot yet launch because another operation is pending on the same xname|
|needsVerified|[[Operation](#schemaoperation)]|false|none|count of operations that have been started, but need final verification to determine if the operation was successful|
|verifying|[[Operation](#schemaoperation)]|false|none|count of operations that have started verification, but are not finished verification.|
|inProgress|[[Operation](#schemaoperation)]|false|none|count of operations that have been started, but have not reach the verification stage.|
|failed|[[Operation](#schemaoperation)]|false|none|count of operations that have failed to complete firmware task|
|success|[[Operation](#schemaoperation)]|false|none|count of operations that have succeeded in completing firmware task|
|noSolution|[[Operation](#schemaoperation)]|false|none|count of operations that have no viable solution to satisfy the request.  This is usually because no suitable image exists.|
|noOperation|[[Operation](#schemaoperation)]|false|none|count of operations that do not need to be executed, because the desired end state is already achieved.|
|aborted|[[Operation](#schemaoperation)]|false|none|count of operations that have been aborted.  It is indeterminate if their firmware task was executed.|
|unknown|[[Operation](#schemaoperation)]|false|none|count of unknown states -> should not be present.|

<h2 id="tocS_OperationKey">OperationKey</h2>
<!-- backwards compatibility -->
<a id="schemaoperationkey"></a>
<a id="schema_OperationKey"></a>
<a id="tocSoperationkey"></a>
<a id="tocsoperationkey"></a>

```json
{
  "operationID": "304f12c1-106a-4031-8993-97a9e8ea25f4",
  "xname": "string",
  "target": "string",
  "targetName": "string",
  "fromFirmwareVersion": "string",
  "stateHelper": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|operationID|string(uuid)|false|none|none|
|xname|string|false|none|none|
|target|string|false|none|none|
|targetName|string|false|none|none|
|fromFirmwareVersion|string|false|none|the currently identified firmware version on the xname/target before attempting an update. May be empty.|
|stateHelper|string|false|none|a helper string that might further explain the current state.|

<h2 id="tocS_Problem7807">Problem7807</h2>
<!-- backwards compatibility -->
<a id="schemaproblem7807"></a>
<a id="schema_Problem7807"></a>
<a id="tocSproblem7807"></a>
<a id="tocsproblem7807"></a>

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}

```

RFC 7807 compliant error payload.  All fields are optional except the 'type' field.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|type|string|true|none|none|
|detail|string|false|none|none|
|instance|string|false|none|none|
|status|number(int32)|false|none|none|
|title|string|false|none|none|

<h2 id="tocS_RelatedSnapshotActions">RelatedSnapshotActions</h2>
<!-- backwards compatibility -->
<a id="schemarelatedsnapshotactions"></a>
<a id="schema_RelatedSnapshotActions"></a>
<a id="tocSrelatedsnapshotactions"></a>
<a id="tocsrelatedsnapshotactions"></a>

```json
{
  "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
  "startTime": "2019-08-24T14:15:22Z",
  "endTime": "2019-08-24T14:15:22Z",
  "state": "completed"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|actionID|string(uuid)|false|none|none|
|startTime|string(date-time)|false|none|none|
|endTime|string(date-time)|false|none|none|
|state|string|false|none|The state of the action -<br><br>  *new* - not yet started<br>  *configured* - configured, but not yet started<br>  *blocked* - configured, but cannot run because another action is executing<br>  *running* - started<br>  *completed* - the action has completed all operations<br>  *abortSignaled* - the action has been instructed to STOP all running operations<br>  *aborted* - the action has stopped all operations|

#### Enumerated Values

|Property|Value|
|---|---|
|state|new|
|state|configure|
|state|blocked|
|state|running|
|state|completed|
|state|abortSignaled|
|state|aborted|

<h2 id="tocS_ServiceStatus">ServiceStatus</h2>
<!-- backwards compatibility -->
<a id="schemaservicestatus"></a>
<a id="schema_ServiceStatus"></a>
<a id="tocSservicestatus"></a>
<a id="tocsservicestatus"></a>

```json
{
  "serviceStatus": "running"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|serviceStatus|string|false|none|none|

<h2 id="tocS_ServiceStatusDetails">ServiceStatusDetails</h2>
<!-- backwards compatibility -->
<a id="schemaservicestatusdetails"></a>
<a id="schema_ServiceStatusDetails"></a>
<a id="tocSservicestatusdetails"></a>
<a id="tocsservicestatusdetails"></a>

```json
{
  "serviceVersion": "1.2.0",
  "serviceStatus": "running",
  "hmsStatus": "connected",
  "storageStatus": "connected"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|serviceVersion|string|false|none|none|
|serviceStatus|string|false|none|none|
|hmsStatus|string|false|none|none|
|storageStatus|string|false|none|none|

<h2 id="tocS_ServiceVersion">ServiceVersion</h2>
<!-- backwards compatibility -->
<a id="schemaserviceversion"></a>
<a id="schema_ServiceVersion"></a>
<a id="tocSserviceversion"></a>
<a id="tocsserviceversion"></a>

```json
{
  "serviceVersion": "1.2.0"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|serviceVersion|string|false|none|none|

<h2 id="tocS_Snapshot">Snapshot</h2>
<!-- backwards compatibility -->
<a id="schemasnapshot"></a>
<a id="schema_Snapshot"></a>
<a id="tocSsnapshot"></a>
<a id="tocssnapshot"></a>

```json
{
  "name": "string",
  "captureTime": "2019-08-24T14:15:22Z",
  "expirationTime": "2019-08-24T14:15:22Z",
  "ready": false,
  "relatedActions": [
    {
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "completed"
    }
  ],
  "devices": [
    {
      "xname": "x0c0s2b0",
      "targets": [
        {
          "name": "BIOS",
          "firmwareVersion": "fw123.8s",
          "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
          "error": "string"
        }
      ],
      "error": "string"
    }
  ],
  "parameters": {
    "name": "20200402_all_xnames",
    "expirationTime": "2019-08-24T14:15:22Z",
    "stateComponentFilter": {
      "xnames": [
        "x0c0s0b0",
        "x0c0s2b0"
      ],
      "partitions": [
        "p1"
      ],
      "groups": [
        "red",
        "blue"
      ],
      "deviceTypes": [
        "nodeBMC"
      ]
    },
    "inventoryHardwareFilter": {
      "manufacturer": "cray",
      "model": "c5000"
    },
    "targetFilter": {
      "targets": [
        "BIOS",
        "BMC"
      ]
    }
  },
  "errors": [
    "string"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|none|
|captureTime|string(date-time)|false|none|none|
|expirationTime|string(date-time)|false|none|none|
|ready|boolean|false|none|whether or not the snapshot has completed|
|relatedActions|[[RelatedSnapshotActions](#schemarelatedsnapshotactions)]|false|none|none|
|devices|[[DeviceFirmware](#schemadevicefirmware)]|false|none|none|
|parameters|[SnapshotParameters](#schemasnapshotparameters)|false|none|none|
|errors|[string]|false|none|none|

<h2 id="tocS_SnapshotAll">SnapshotAll</h2>
<!-- backwards compatibility -->
<a id="schemasnapshotall"></a>
<a id="schema_SnapshotAll"></a>
<a id="tocSsnapshotall"></a>
<a id="tocssnapshotall"></a>

```json
{
  "snapshots": [
    {
      "name": "pre_system_upgrade",
      "captureTime": "2019-08-24T14:15:22Z",
      "expirationTime": "2019-08-24T14:15:22Z",
      "ready": false,
      "relatedActions": [
        {
          "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
          "startTime": "2019-08-24T14:15:22Z",
          "endTime": "2019-08-24T14:15:22Z",
          "state": "completed"
        }
      ],
      "uniqueDeviceCount": 0
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|snapshots|[[SnapshotSummary](#schemasnapshotsummary)]|false|none|none|

<h2 id="tocS_SnapshotID">SnapshotID</h2>
<!-- backwards compatibility -->
<a id="schemasnapshotid"></a>
<a id="schema_SnapshotID"></a>
<a id="tocSsnapshotid"></a>
<a id="tocssnapshotid"></a>

```json
{
  "name": "20200402_all_xnames"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|none|

<h2 id="tocS_SnapshotParameters">SnapshotParameters</h2>
<!-- backwards compatibility -->
<a id="schemasnapshotparameters"></a>
<a id="schema_SnapshotParameters"></a>
<a id="tocSsnapshotparameters"></a>
<a id="tocssnapshotparameters"></a>

```json
{
  "name": "20200402_all_xnames",
  "expirationTime": "2019-08-24T14:15:22Z",
  "stateComponentFilter": {
    "xnames": [
      "x0c0s0b0",
      "x0c0s2b0"
    ],
    "partitions": [
      "p1"
    ],
    "groups": [
      "red",
      "blue"
    ],
    "deviceTypes": [
      "nodeBMC"
    ]
  },
  "inventoryHardwareFilter": {
    "manufacturer": "cray",
    "model": "c5000"
  },
  "targetFilter": {
    "targets": [
      "BIOS",
      "BMC"
    ]
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|none|
|expirationTime|string(date-time)|false|none|time at which the snapshot expires and is automatically deleted|
|stateComponentFilter|[ActionParameters_StateComponentFilter](#schemaactionparameters_statecomponentfilter)|false|none|none|
|inventoryHardwareFilter|[ActionParameters_HardwareFilter](#schemaactionparameters_hardwarefilter)|false|none|none|
|targetFilter|[ActionParameters_TargetFilter](#schemaactionparameters_targetfilter)|false|none|none|

<h2 id="tocS_SnapshotSummary">SnapshotSummary</h2>
<!-- backwards compatibility -->
<a id="schemasnapshotsummary"></a>
<a id="schema_SnapshotSummary"></a>
<a id="tocSsnapshotsummary"></a>
<a id="tocssnapshotsummary"></a>

```json
{
  "name": "pre_system_upgrade",
  "captureTime": "2019-08-24T14:15:22Z",
  "expirationTime": "2019-08-24T14:15:22Z",
  "ready": false,
  "relatedActions": [
    {
      "actionID": "4a156b6a-0d73-4d7b-92f3-7bc07d13205f",
      "startTime": "2019-08-24T14:15:22Z",
      "endTime": "2019-08-24T14:15:22Z",
      "state": "completed"
    }
  ],
  "uniqueDeviceCount": 0
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|none|
|captureTime|string(date-time)|false|none|none|
|expirationTime|string(date-time)|false|none|none|
|ready|boolean|false|none|whether or not the snapshot has completed|
|relatedActions|[[RelatedSnapshotActions](#schemarelatedsnapshotactions)]|false|none|none|
|uniqueDeviceCount|integer|false|none|count of unique xnames associated with the snapshot|

<h2 id="tocS_Target">Target</h2>
<!-- backwards compatibility -->
<a id="schematarget"></a>
<a id="schema_Target"></a>
<a id="tocStarget"></a>
<a id="tocstarget"></a>

```json
{
  "name": "BIOS",
  "firmwareVersion": "fw123.8s",
  "imageID": "bbdcb050-2e05-43cb-812a-e1296cd0c01a",
  "error": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|none|
|firmwareVersion|string|false|none|none|
|imageID|string(uuid)|false|none|none|
|error|string|false|none|any error that was encountered while populating target information|

