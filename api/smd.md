<!-- Generator: Widdershins v4.0.1 -->

<h1 id="hardware-state-manager-api">Hardware State Manager API v2</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The Hardware State Manager (HSM) inventories, monitors, and manages hardware, and tracks the logical and dynamic component states, such as roles, NIDs, and other basic metadata needed to provide most common administrative and operational functions. HSM is the single source of truth for the state of the system. It contains the component state and information on Redfish endpoints for communicating with components via Redfish. It also allows administrators to create partitions and groups for other uses.
## Resources
### /State/Components
HMS components are created during inventory discovery and provide a higher-level representation of the component, including state, NID, role (i.e. compute/service), subtype, and so on. Unlike ComponentEndpoints, however, they are not strictly linked to the parent RedfishEndpoint, and are not automatically deleted when the RedfishEndpoints are (though they can be deleted via a separate call). This is because these components can also represent abstract components, such as removed components (e.g. which would remain, but have their states changed to "Empty" upon removal).
### /Defaults/NodeMaps

This resource allows a mapping file (NodeMaps) to be uploaded that maps node xnames to Node IDs, and optionally, to roles and subroles. These mappings are used when discovering nodes for the first time. These mappings should be uploaded prior to discovery and should contain mappings for each valid node xname in the system, whether populated or not. Nodemap is a JSON file that contains the xname of the node, node ID, and optionally role and subrole. Role can be Compute, Application, Storage, Management etc. The NodeMaps collection can be uploaded to HSM automatically at install time by specifying it as a JSON file. As a result, the endpoints are then automatically discovered by REDS, and inventory discovery is performed by HSM. The desired NID numbers will be set as soon as the nodes are created using the NodeMaps collection.

It is recommended that Nodemaps are uploaded at install time before discovery happens. If they are uploaded after discovery, then the node xnames need to be manually updated with the correct NIDs. You can update NIDs for individual components by using PATCH /State/Components/{xname}/NID.

### /Inventory/Hardware

This resource shows the hardware inventory of the entire system and contains FRU information in location. All entries are displayed as a flat array.
### /Inventory/HardwareByFRU

Every component has FRU information. This resource shows the hardware inventory for all FRUs or for a specific FRU irrespective of the location. This information is constant regardless of where the hardware item is currently in the system. If a HWInventoryByLocation entry is currently populated with a piece of hardware, it will have the corresponding HWInventoryByFRU object embedded. This FRU info can also be looked up by FRU ID regardless of the current location.
### /Inventory/Hardware/Query/{xname}

This resource gets you information about a specific component and it's sub-components. The xname can be a component, partition, ALL, or s0. Both ALL and s0 represent the entire system.
### /Inventory/RedfishEndpoints

This is a BMC or other Redfish controller that has a Redfish entry point and Redfish service root. It is used to discover the components managed by this endpoint during discovery and handles all Redfish interactions by these subcomponents.  If the endpoint has been discovered, this entry will include the ComponentEndpoint entries for these managed subcomponents. You can also create a Redfish Endpoint or update the definition for a Redfish Endpoint. The xname identifies the location of all components in the system, including chassis, controllers, nodes, and so on. Redfish endpoints are given to State Manager.
### /Inventory/ComponentEndpoints

Component Endpoints are the specific URLs for each individual component that are under the Redfish endpoint. Component endpoints are discovered during inventory discovery. They are the management-plane representation of system components and are linked to the parent Redfish Endpoint. They provide a glue layer to bridge the higher-level representation of a component with how it is represented locally by Redfish.

The collection of ComponentEndpoints can be obtained in full, optionally filtered on certain criteria (e.g. obtain just Node components), or accessed by their xname IDs individually.
### /Inventory/ServiceEndpoints

ServiceEndpoints help you do things on Redfish like updating the firmware. They are discovered during inventory discovery.
### /groups

Groups are named sets of system components, most commonly nodes. A group groups components under an administratively chosen label (group name). Each component may belong to any number of groups. If a group has exclusiveGroup=<excl-label> set, then a node may only be a member of one group that matches that exclusive label. For example, if the exclusive group label 'colors' is associated with groups 'blue', 'red', and 'green', then a component that is part of 'green' could not also be placed in 'red'.
You can create, modify, or delete a group and its members. You can also use group names as filters for API calls.
### /partitions

A partition is a formal, non-overlapping division of the system that forms an administratively distinct sub-system. Each component may belong to at most one partition. Partitions are used as an access control mechanism or for implementing multi-tenancy. You can create, modify, or delete a partition and its members. You can also use partitions as filters for other API calls.
### /memberships

A membership shows the association of a component xname to its set of group labels and partition names. There can be many group labels and up to one partition per component. Memberships are not modified directly, as the underlying group or partition is modified instead. A component can be removed from one of the listed groups or partitions or added via POST as well as being present in the initial set of members when a partition or group is created. You can retrieve the memberships for components or memberships for a specific xname.
### /Inventory/DiscoveryStatus

Check discovery status for all components or you can track the status for a specific job ID. You can also check per-endpoint discover status for each RedfishEndpoint. Contains status information about the discovery operation for clients to query. The discover operation returns a link or links to status objects so that a client can determine when the discovery operation is complete.
### /Inventory/Discover

Discover subcomponents by querying all RedfishEndpoints. Once the RedfishEndpoint objects are created, inventory discovery will query these controllers and create or update management plane and managed plane objects representing the components (e.g. nodes, node enclosures, node cards for Mountain chassis CMM endpoints).
### /Subscriptions/SCN

Manage subscriptions to state change notifications (SCNs) from HSM. You can also subscribe to state change notifications by using the HMS Notification Fanout Daemon API.
## Workflows

### Add and Delete a Redfish Endpoint
#### POST /Inventory/RedfishEndpoints
When you manually create Redfish endpoints, the discovery is automatically initiated. You would create Redfish endpoints for components that are not automatically discovered by REDS or MEDS.
#### GET /Inventory/RedfishEndpoints
Check the Redfish endpoints that have been added and check the status of discovery.
#### DELETE /Inventory/RedfishEndpoints/{xname}
Delete a specific Redfish endpoint.
### Perform Inventory Discovery
#### POST /Inventory/Discover
Start inventory discovery of a system's subcomponents by querying all Redfish endpoints. If needed, specify an ID or hostname (xname) in the payload.
#### GET /Inventory/DiscoveryStatus
Check the discovery status of all Redfish endpoints. You can also check the discovery status for each individual component by providing ID.
### Query and Update HMS Components (State/NID)
#### GET /State/Components
Retrieve all HMS Components found by inventory discovery as a named ("Components") array.

#### PATCH /State/Components/{xname}/Enabled
Modify the component's Enabled field.

#### DELETE /State/Components/{xname}
Delete a specific HMS component by providing its xname. As noted, components are not automatically deleted when RedfishEndpoints or ComponentEndpoints are deleted.
### Create and Delete a New Group
#### GET /hsm/v2/State/Components
Retrieve a list of desired components and their state. Select the nodes that you want to group.

#### POST /groups
Create the new group with desired members. Provide a group label (required), description, name, members etc. in the JSON payload.
#### GET /groups/{group_label}
Retrieve the group that was create with the label.
#### GET /State/Components/{group_label}
Retrieve the current state for all the components in the group.
#### DELETE /groups/{group_label}
Delete the group specified by {group_label}.
## Valid State Transitions
```
Prior State -> New State     - Reason
Ready       -> Standby       - HBTD if node has many missed heartbeats
Ready       -> Ready/Warning - HBTD if node has a few missed heartbeats
Standby     -> Ready         - HBTD Node re-starts heartbeating
On          -> Ready         - HBTD Node started heartbeating
Off         -> Ready         - HBTD sees heartbeats before Redfish Event (On)
Standby     -> On            - Redfish Event (On) or if re-discovered while in the standby state
Off         -> On            - Redfish Event (On)
Standby     -> Off           - Redfish Event (Off)
Ready       -> Off           - Redfish Event (Off)
On          -> Off           - Redfish Event (Off)
Any State   -> Empty         - Redfish Endpoint is disabled meaning component removal
```
Generally, nodes transition 'Off' -> 'On' -> 'Ready' when going from 'Off' to booted, and 'Ready' -> 'Ready/Warning' -> 'Standby' -> 'Off' when shutdown.

Base URLs:

* <a href="https://sms/apis/smd/hsm/v2">https://sms/apis/smd/hsm/v2</a>

<h1 id="hardware-state-manager-api-service-info">Service Info</h1>

Service information APIs for getting information on the HSM service such as readiness, etc.

## doReadyGet

<a id="opIddoReadyGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/ready HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/ready \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/ready', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/ready", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/ready`

*Kubernetes readiness endpoint to monitor service health*

The `readiness` resource works in conjunction with the Kubernetes readiness probe to determine when the service is no longer healthy and able to respond correctly to requests.  Too many failures of the readiness probe will result in the traffic being routed away from this service and eventually the service will be shut down and restarted if in an unready state for too long.

This is primarily an endpoint for the automated Kubernetes system.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="doreadyget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|[Response_1.0.0](#schemaresponse_1.0.0)|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|The service is unhealthy and not ready|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doLivenessGet

<a id="opIddoLivenessGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/liveness HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/liveness \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/liveness', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/liveness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/liveness`

*Kubernetes liveness endpoint to monitor service health*

The `liveness` resource works in conjunction with the Kubernetes liveness probe to determine when the service is no longer responding to requests.  Too many failures of the liveness probe will result in the service being shut down and restarted.

This is primarily an endpoint for the automated Kubernetes system.

> Example responses

> 503 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="dolivenessget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|The service is not taking HTTP requests|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doValuesGet

<a id="opIddoValuesGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/values HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/values \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/values', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/values", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/values`

*Retrieve all valid values for use as parameters*

Retrieve all valid values for use as parameters.

> Example responses

> 200 Response

```json
null
```

<h3 id="dovaluesget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of parameters and their valid values.|[Values.1.0.0_Values](#schemavalues.1.0.0_values)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doArchValuesGet

<a id="opIddoArchValuesGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/values/arch HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/values/arch \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/values/arch', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/values/arch", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/values/arch`

*Retrieve all valid values for use with the 'arch' parameter*

Retrieve all valid values for use with the 'arch' (component architecture) parameter.

> Example responses

> 200 Response

```json
{
  "Arch": [
    "X86"
  ]
}
```

<h3 id="doarchvaluesget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of valid values for the 'arch' parameter.|[Values.1.0.0_ArchArray](#schemavalues.1.0.0_archarray)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doClassValuesGet

<a id="opIddoClassValuesGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/values/class HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/values/class \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/values/class', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/values/class", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/values/class`

*Retrieve all valid values for use with the 'class' parameter*

Retrieve all valid values for use with the 'class' (hardware class) parameter.

> Example responses

> 200 Response

```json
{
  "Class": [
    "River"
  ]
}
```

<h3 id="doclassvaluesget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of valid values for the 'class' parameter.|[Values.1.0.0_ClassArray](#schemavalues.1.0.0_classarray)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doFlagValuesGet

<a id="opIddoFlagValuesGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/values/flag HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/values/flag \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/values/flag', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/values/flag", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/values/flag`

*Retrieve all valid values for use with the 'flag' parameter*

Retrieve all valid values for use with the 'flag' (component flag) parameter.

> Example responses

> 200 Response

```json
{
  "Flag": [
    "OK"
  ]
}
```

<h3 id="doflagvaluesget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of valid values for the 'flag' parameter.|[Values.1.0.0_FlagArray](#schemavalues.1.0.0_flagarray)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doNetTypeValuesGet

<a id="opIddoNetTypeValuesGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/values/nettype HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/values/nettype \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/values/nettype', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/values/nettype", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/values/nettype`

*Retrieve all valid values for use with the 'nettype' parameter*

Retrieve all valid values for use with the 'nettype' (component network type) parameter.

> Example responses

> 200 Response

```json
{
  "NetType": [
    "Sling"
  ]
}
```

<h3 id="donettypevaluesget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of valid values for the 'nettype' parameter.|[Values.1.0.0_NetTypeArray](#schemavalues.1.0.0_nettypearray)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doRoleValuesGet

<a id="opIddoRoleValuesGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/values/role HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/values/role \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/values/role', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/values/role", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/values/role`

*Retrieve all valid values for use with the 'role' parameter*

Retrieve all valid values for use with the 'role' (component role) parameter.

> Example responses

> 200 Response

```json
{
  "Role": [
    "Compute"
  ]
}
```

<h3 id="dorolevaluesget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of valid values for the 'role' parameter.|[Values.1.0.0_RoleArray](#schemavalues.1.0.0_rolearray)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doSubRoleValuesGet

<a id="opIddoSubRoleValuesGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/values/subrole HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/values/subrole \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/values/subrole', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/values/subrole", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/values/subrole`

*Retrieve all valid values for use with the 'subrole' parameter*

Retrieve all valid values for use with the 'subrole' (component subrole) parameter.

> Example responses

> 200 Response

```json
{
  "SubRole": [
    "Worker"
  ]
}
```

<h3 id="dosubrolevaluesget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of valid values for the 'subrole' parameter.|[Values.1.0.0_SubRoleArray](#schemavalues.1.0.0_subrolearray)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doStateValuesGet

<a id="opIddoStateValuesGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/values/state HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/values/state \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/values/state', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/values/state", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/values/state`

*Retrieve all valid values for use with the 'state' parameter*

Retrieve all valid values for use with the 'state' (component state) parameter.

> Example responses

> 200 Response

```json
{
  "State": [
    "Ready"
  ]
}
```

<h3 id="dostatevaluesget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of valid values for the 'state' parameter.|[Values.1.0.0_StateArray](#schemavalues.1.0.0_statearray)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doTypeValuesGet

<a id="opIddoTypeValuesGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/service/values/type HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/service/values/type \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/service/values/type', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/service/values/type", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /service/values/type`

*Retrieve all valid values for use with the 'type' parameter*

Retrieve all valid values for use with the 'type' (component HMSType) parameter.

> Example responses

> 200 Response

```json
{
  "Type": [
    "Node"
  ]
}
```

<h3 id="dotypevaluesget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of valid values for the 'type' parameter.|[Values.1.0.0_TypeArray](#schemavalues.1.0.0_typearray)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-component">Component</h1>

High-level component information by xname: state, flag, NID, role, etc.

## doComponentsGet

<a id="opIddoComponentsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/State/Components HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/State/Components \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/State/Components', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/State/Components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /State/Components`

*Retrieve collection of HMS Components*

Retrieve the full collection of state/components in the form of a ComponentArray. Full results can also be filtered by query parameters. When multiple parameters are specified, they are applied in an AND fashion (e.g. type AND state). When a parameter is specified multiple times, they are applied in an OR fashion (e.g. type AND state1 OR state2). If the collection is empty or the filters have no match, an empty array is returned.

<h3 id="docomponentsget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|query|string|false|Filter the results based on xname ID(s). Can be specified multiple times for selecting entries with multiple specific xnames.|
|type|query|string|false|Filter the results based on HMS type like Node, NodeEnclosure, NodeBMC etc. Can be specified multiple times for selecting entries of multiple types.|
|state|query|string|false|Filter the results based on HMS state like Ready, On etc. Can be specified multiple times for selecting entries in different states.|
|flag|query|string|false|Filter the results based on HMS flag value like OK, Alert etc. Can be specified multiple times for selecting entries with different flags.|
|role|query|string|false|Filter the results based on HMS role. Can be specified multiple times for selecting entries with different roles. Valid values are:|
|subrole|query|string|false|Filter the results based on HMS subrole. Can be specified multiple times for selecting entries with different subroles. Valid values are:|
|enabled|query|string|false|Filter the results based on enabled status (true or false).|
|softwarestatus|query|string|false|Filter the results based on software status. Software status is a free form string. Matching is case-insensitive. Can be specified multiple times for selecting entries with different software statuses.|
|subtype|query|string|false|Filter the results based on HMS subtype. Can be specified multiple times for selecting entries with different subtypes.|
|arch|query|string|false|Filter the results based on architecture. Can be specified multiple times for selecting components with different architectures.|
|class|query|string|false|Filter the results based on HMS hardware class. Can be specified multiple times for selecting entries with different classes.|
|nid|query|string|false|Filter the results based on NID. Can be specified multiple times for selecting entries with multiple specific NIDs.|
|nid_start|query|string|false|Filter the results based on NIDs equal to or greater than the provided integer.|
|nid_end|query|string|false|Filter the results based on NIDs less than or equal to the provided integer.|
|partition|query|string|false|Restrict search to the given partition (p#.#). One partition can be combined with at most one group argument which will be treated as a logical AND. NULL will return components in NO partition.|
|group|query|string|false|Restrict search to the given group label. One group can be combined with at most one partition argument which will be treated as a logical AND. NULL will return components in NO groups.|
|stateonly|query|boolean|false|Return only component state and flag fields (plus xname/ID and type). Results can be modified and used for bulk state/flag- only patch operations.|
|flagonly|query|boolean|false|Return only component flag field (plus xname/ID and type). Results can be modified and used for bulk flag-only patch operations.|
|roleonly|query|boolean|false|Return only component role and subrole fields (plus xname/ID and type). Results can be modified and used for bulk role-only patches.|
|nidonly|query|boolean|false|Return only component NID field (plus xname/ID and type). Results can be modified and used for bulk NID-only patches.|

#### Detailed descriptions

**role**: Filter the results based on HMS role. Can be specified multiple times for selecting entries with different roles. Valid values are:
- Compute
- Service
- System
- Application
- Storage
- Management
Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.

**subrole**: Filter the results based on HMS subrole. Can be specified multiple times for selecting entries with different subroles. Valid values are:
- Master
- Worker
- Storage
Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.

#### Enumerated Values

|Parameter|Value|
|---|---|
|type|CDU|
|type|CabinetCDU|
|type|CabinetPDU|
|type|CabinetPDUOutlet|
|type|CabinetPDUPowerConnector|
|type|CabinetPDUController|
|type|Cabinet|
|type|Chassis|
|type|ChassisBMC|
|type|CMMRectifier|
|type|CMMFpga|
|type|CEC|
|type|ComputeModule|
|type|RouterModule|
|type|NodeBMC|
|type|NodeEnclosure|
|type|NodeEnclosurePowerSupply|
|type|HSNBoard|
|type|MgmtSwitch|
|type|MgmtHLSwitch|
|type|CDUMgmtSwitch|
|type|Node|
|type|Processor|
|type|Drive|
|type|StorageGroup|
|type|NodeNIC|
|type|Memory|
|type|NodeAccel|
|type|NodeAccelRiser|
|type|NodeFpga|
|type|HSNAsic|
|type|RouterFpga|
|type|RouterBMC|
|type|HSNLink|
|type|HSNConnector|
|type|INVALID|
|state|Unknown|
|state|Empty|
|state|Populated|
|state|Off|
|state|On|
|state|Standby|
|state|Halt|
|state|Ready|
|flag|OK|
|flag|Warning|
|flag|Alert|
|flag|Locked|
|flag|Unknown|
|arch|X86|
|arch|ARM|
|arch|Other|
|arch|Unknown|
|class|River|
|class|Mountain|
|class|Hill|

> Example responses

> 200 Response

```json
{
  "Components": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "State": "Ready",
      "Flag": "OK",
      "Enabled": true,
      "SoftwareStatus": "string",
      "Role": "Compute",
      "SubRole": "Worker",
      "NID": 1,
      "Subtype": "string",
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River",
      "ReservationDisabled": false,
      "Locked": false
    }
  ]
}
```

<h3 id="docomponentsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ComponentArray representing results of query.|[ComponentArray_ComponentArray](#schemacomponentarray_componentarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request such as invalid argument for filter|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentsPost

<a id="opIddoComponentsPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/State/Components HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/State/Components \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/State/Components', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/State/Components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /State/Components`

*Create/Update a collection of HMS Components*

Create/Update a collection of state/components. If the component already exists it will not be overwritten unless force=true in which case State, Flag, Subtype, NetType, Arch, and Class will get overwritten.

> Body parameter

```json
{
  "Components": [
    {
      "ID": "x0c0s1b0n0",
      "State": "Ready",
      "Flag": "OK",
      "Enabled": true,
      "SoftwareStatus": "string",
      "Role": "Compute",
      "SubRole": "Worker",
      "NID": 1,
      "Subtype": "string",
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River"
    }
  ],
  "Force": true
}
```

<h3 id="docomponentspost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ComponentArray_PostArray](#schemacomponentarray_postarray)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docomponentspost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) One or more Component entries were successfully created/updated.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request such as invalid argument for a component field|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentsDeleteAll

<a id="opIddoComponentsDeleteAll"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/State/Components HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/State/Components \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/State/Components', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/State/Components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /State/Components`

*Delete all components*

Delete all entries in the components collection.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="docomponentsdeleteall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries deleted. Message contains count of deleted items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Collection is empty|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentGet

<a id="opIddoComponentGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/State/Components/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/State/Components/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/State/Components/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/State/Components/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /State/Components/{xname}`

*Retrieve component at {xname}*

Retrieve state or components by xname.

<h3 id="docomponentget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of component to return.|

> Example responses

> 200 Response

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "State": "Ready",
  "Flag": "OK",
  "Enabled": true,
  "SoftwareStatus": "string",
  "Role": "Compute",
  "SubRole": "Worker",
  "NID": 1,
  "Subtype": "string",
  "NetType": "Sling",
  "Arch": "X86",
  "Class": "River",
  "ReservationDisabled": false,
  "Locked": false
}
```

<h3 id="docomponentget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Component entry matching xname/ID|[Component.1.0.0_Component](#schemacomponent.1.0.0_component)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request or invalid xname|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentPut

<a id="opIddoComponentPut"></a>

> Code samples

```http
PUT https://sms/apis/smd/hsm/v2/State/Components/{xname} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://sms/apis/smd/hsm/v2/State/Components/{xname} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('https://sms/apis/smd/hsm/v2/State/Components/{xname}', headers = headers)

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
    req, err := http.NewRequest("PUT", "https://sms/apis/smd/hsm/v2/State/Components/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /State/Components/{xname}`

*Create/Update an HMS Component*

Create/Update a state/component. If the component already exists it will not be overwritten unless force=true in which case State, Flag, Subtype, NetType, Arch, and Class will get overwritten.

> Body parameter

```json
{
  "Component": {
    "ID": "x0c0s1b0n0",
    "State": "Ready",
    "Flag": "OK",
    "Enabled": true,
    "SoftwareStatus": "string",
    "Role": "Compute",
    "SubRole": "Worker",
    "NID": 1,
    "Subtype": "string",
    "NetType": "Sling",
    "Arch": "X86",
    "Class": "River"
  },
  "Force": true
}
```

<h3 id="docomponentput-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of the component to create or update.|
|body|body|[Component.1.0.0_Put](#schemacomponent.1.0.0_put)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docomponentput-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Component entry was successfully created/updated.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request such as invalid argument for a component field|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentDelete

<a id="opIddoComponentDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/State/Components/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/State/Components/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/State/Components/{xname}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/State/Components/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /State/Components/{xname}`

*Delete component with ID {xname}*

Delete a component by xname.

<h3 id="docomponentdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of component record to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="docomponentdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Component is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|XName does Not Exist - no matching ID to delete|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentByNIDGet

<a id="opIddoComponentByNIDGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/State/Components/ByNID/{nid} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/State/Components/ByNID/{nid} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/State/Components/ByNID/{nid}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/State/Components/ByNID/{nid}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /State/Components/ByNID/{nid}`

*Retrieve component with NID={nid}*

Retrieve a component by NID.

<h3 id="docomponentbynidget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|nid|path|string|true|NID of component to return.|

> Example responses

> 200 Response

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "State": "Ready",
  "Flag": "OK",
  "Enabled": true,
  "SoftwareStatus": "string",
  "Role": "Compute",
  "SubRole": "Worker",
  "NID": 1,
  "Subtype": "string",
  "NetType": "Sling",
  "Arch": "X86",
  "Class": "River",
  "ReservationDisabled": false,
  "Locked": false
}
```

<h3 id="docomponentbynidget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Component entry matching xname/ID|[Component.1.0.0_Component](#schemacomponent.1.0.0_component)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompBulkStateDataPatch

<a id="opIddoCompBulkStateDataPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkStateData HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkStateData \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/BulkStateData', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/BulkStateData", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/BulkStateData`

*Update multiple components' state data via a list of xnames*

Specify a list of xnames to update the State and Flag fields. If the Flag field is omitted, Flag is reverted to 'OK'. Other fields are ignored. The list of IDs and the new State are required.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "State": "Ready",
  "Flag": "OK",
  "Force": false,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docompbulkstatedatapatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ComponentArray_PatchArray.StateData](#schemacomponentarray_patcharray.statedata)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompbulkstatedatapatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompStatePatch

<a id="opIddoCompStatePatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/StateData HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/StateData \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/{xname}/StateData', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/{xname}/StateData", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/{xname}/StateData`

*Update component state data at {xname}*

Update the component's state and flag fields only. If Flag field is omitted, the Flag value is reverted to 'OK'.

> Body parameter

```json
{
  "State": "Ready",
  "Flag": "OK",
  "Force": false,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docompstatepatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of component to set state/flag on.|
|body|body|[Component.1.0.0_Patch.StateData](#schemacomponent.1.0.0_patch.statedata)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompstatepatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompBulkFlagOnlyPatch

<a id="opIddoCompBulkFlagOnlyPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkFlagOnly HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkFlagOnly \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/BulkFlagOnly', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/BulkFlagOnly", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/BulkFlagOnly`

*Update multiple components' Flag values via a list of xnames*

Specify a list of xnames to update the Flag field and specify the value. The list of IDs and the new Flag are required.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Flag": "OK",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docompbulkflagonlypatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ComponentArray_PatchArray.FlagOnly](#schemacomponentarray_patcharray.flagonly)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompbulkflagonlypatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompFlagOnlyPatch

<a id="opIddoCompFlagOnlyPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/FlagOnly HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/FlagOnly \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/{xname}/FlagOnly', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/{xname}/FlagOnly", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/{xname}/FlagOnly`

*Update component Flag value at {xname}*

The State is not modified. Only the Flag is updated.

> Body parameter

```json
{
  "Flag": "OK",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docompflagonlypatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of component to modify flag on.|
|body|body|[Component.1.0.0_Patch.FlagOnly](#schemacomponent.1.0.0_patch.flagonly)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompflagonlypatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompBulkEnabledPatch

<a id="opIddoCompBulkEnabledPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkEnabled HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkEnabled \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/BulkEnabled', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/BulkEnabled", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/BulkEnabled`

*Update multiple components' Enabled values via a list of xnames*

Update the Enabled field for a list of xnames. Specify a single value for Enabled and also the list of xnames. Note that Enabled is a boolean field and a value of false sets the component(s) to disabled.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Enabled": true,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docompbulkenabledpatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ComponentArray_PatchArray.Enabled](#schemacomponentarray_patcharray.enabled)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompbulkenabledpatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompEnabledPatch

<a id="opIddoCompEnabledPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/Enabled HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/Enabled \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/{xname}/Enabled', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/{xname}/Enabled", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/{xname}/Enabled`

*Update component Enabled value at {xname}*

Update the component's Enabled field only. The State and other fields are not modified. Note that this is a boolean field, a value of false sets the component to disabled.

> Body parameter

```json
{
  "Enabled": true,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docompenabledpatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of component to set Enabled to true or false.|
|body|body|[Component.1.0.0_Patch.Enabled](#schemacomponent.1.0.0_patch.enabled)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompenabledpatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompBulkSwStatusPatch

<a id="opIddoCompBulkSwStatusPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkSoftwareStatus HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkSoftwareStatus \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/BulkSoftwareStatus', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/BulkSoftwareStatus", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/BulkSoftwareStatus`

*Update multiple components' SoftwareStatus values via a list of xnames*

Update the SoftwareStatus field for a list of xnames. Specify a single new value of SoftwareStatus like admindown and the list of xnames.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "SoftwareStatus": "string",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docompbulkswstatuspatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ComponentArray_PatchArray.SoftwareStatus](#schemacomponentarray_patcharray.softwarestatus)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompbulkswstatuspatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompSwStatusPatch

<a id="opIddoCompSwStatusPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/SoftwareStatus HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/SoftwareStatus \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/{xname}/SoftwareStatus', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/{xname}/SoftwareStatus", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/{xname}/SoftwareStatus`

*Update component SoftwareStatus value at {xname}*

Update the component's SoftwareStatus field only. The State and other fields are not modified.

> Body parameter

```json
{
  "SoftwareStatus": "string",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docompswstatuspatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of component to set new SoftwareStatus value.|
|body|body|[Component.1.0.0_Patch.SoftwareStatus](#schemacomponent.1.0.0_patch.softwarestatus)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompswstatuspatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompBulkRolePatch

<a id="opIddoCompBulkRolePatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkRole HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkRole \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/BulkRole', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/BulkRole", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/BulkRole`

*Update multiple components' Role values via a list of xnames*

Update the Role and SubRole field for a list of xnames. Specify the Role and Subrole values and the list of xnames. The list of IDs and the new Role are required.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Role": "Compute",
  "SubRole": "Worker",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docompbulkrolepatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ComponentArray_PatchArray.Role](#schemacomponentarray_patcharray.role)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompbulkrolepatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompRolePatch

<a id="opIddoCompRolePatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/Role HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/Role \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/{xname}/Role', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/{xname}/Role", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/{xname}/Role`

*Update component Role and SubRole values at {xname}*

Update the component's Role and SubRole fields only. Valid only for nodes. The State and other fields are not modified.

> Body parameter

```json
{
  "Role": "Compute",
  "SubRole": "Worker",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docomprolepatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of component to modify Role on.|
|body|body|[Component.1.0.0_Patch.Role](#schemacomponent.1.0.0_patch.role)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docomprolepatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompArrayNIDPatch

<a id="opIddoCompArrayNIDPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkNID HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/BulkNID \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/BulkNID', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/BulkNID", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/BulkNID`

*Update multiple components' NIDs via ComponentArray*

Modify the submitted ComponentArray and update the corresponding NID value for each entry. Other fields are ignored and not changed. ID field is required for all entries.

> Body parameter

```json
{
  "Components": [
    {
      "ID": "x0c0s0b0n0",
      "NID": 0,
      "ExtendedInfo": {
        "ID": "string",
        "Message": "string",
        "Flag": "OK"
      }
    }
  ]
}
```

<h3 id="docomparraynidpatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ComponentArray_PatchArray.NID](#schemacomponentarray_patcharray.nid)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docomparraynidpatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompNIDPatch

<a id="opIddoCompNIDPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/NID HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/State/Components/{xname}/NID \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/State/Components/{xname}/NID', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/State/Components/{xname}/NID", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /State/Components/{xname}/NID`

*Update component NID value at {xname}*

Update the component's NID field only. Valid only for nodes. State and other fields are not modified.

> Body parameter

```json
{
  "NID": 0,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}
```

<h3 id="docompnidpatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of component to modify NID on.|
|body|body|[Component.1.0.0_Patch.NID](#schemacomponent.1.0.0_patch.nid)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompnidpatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentsQueryPost

<a id="opIddoComponentsQueryPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/State/Components/Query HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/State/Components/Query \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/State/Components/Query', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/State/Components/Query", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /State/Components/Query`

*Create component query (by xname list), returning ComponentArray*

Retrieve the targeted entries in the form of a ComponentArray by providing a payload of component IDs.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "partition": "p1",
  "group": "group_label",
  "stateonly": true,
  "flagonly": true,
  "roleonly": true,
  "nidonly": true,
  "type": [
    "string"
  ],
  "state": [
    "string"
  ],
  "flag": [
    "string"
  ],
  "enabled": [
    "string"
  ],
  "softwarestatus": [
    "string"
  ],
  "role": [
    "string"
  ],
  "subrole": [
    "string"
  ],
  "subtype": [
    "string"
  ],
  "arch": [
    "string"
  ],
  "class": [
    "string"
  ],
  "nid": [
    "string"
  ],
  "nid_start": [
    "string"
  ],
  "nid_end": [
    "string"
  ]
}
```

<h3 id="docomponentsquerypost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ComponentArray_PostQuery](#schemacomponentarray_postquery)|true|none|

> Example responses

> 200 Response

```json
{
  "Components": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "State": "Ready",
      "Flag": "OK",
      "Enabled": true,
      "SoftwareStatus": "string",
      "Role": "Compute",
      "SubRole": "Worker",
      "NID": 1,
      "Subtype": "string",
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River",
      "ReservationDisabled": false,
      "Locked": false
    }
  ]
}
```

<h3 id="docomponentsquerypost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ComponentArray representing results of query.|[ComponentArray_ComponentArray](#schemacomponentarray_componentarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentByNIDQueryPost

<a id="opIddoComponentByNIDQueryPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/State/Components/ByNID/Query HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/State/Components/ByNID/Query \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/State/Components/ByNID/Query', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/State/Components/ByNID/Query", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /State/Components/ByNID/Query`

*Create component query (by NID ranges), returning ComponentArray*

Retrieve the targeted entries in the form of a ComponentArray by providing a payload of NID ranges.

> Body parameter

```json
{
  "NIDRanges": [
    "0-24"
  ],
  "partition": "p1.2",
  "stateonly": true,
  "flagonly": true,
  "roleonly": true,
  "nidonly": true
}
```

<h3 id="docomponentbynidquerypost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ComponentArray_PostByNIDQuery](#schemacomponentarray_postbynidquery)|true|none|

> Example responses

> 200 Response

```json
{
  "Components": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "State": "Ready",
      "Flag": "OK",
      "Enabled": true,
      "SoftwareStatus": "string",
      "Role": "Compute",
      "SubRole": "Worker",
      "NID": 1,
      "Subtype": "string",
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River",
      "ReservationDisabled": false,
      "Locked": false
    }
  ]
}
```

<h3 id="docomponentbynidquerypost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ComponentArray representing results of query.|[ComponentArray_ComponentArray](#schemacomponentarray_componentarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentQueryGet

<a id="opIddoComponentQueryGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/State/Components/Query/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/State/Components/Query/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/State/Components/Query/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/State/Components/Query/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /State/Components/Query/{xname}`

*Retrieve component query for {xname}, returning ComponentArray*

Retrieve component entries in the form of a ComponentArray by providing xname and modifiers in the query string.

<h3 id="docomponentqueryget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of component to query.|
|type|query|string|false|Retrieve xname's children of type={type} instead of {xname} for example NodeBMC, NodeEnclosure etc.|
|state|query|string|false|Filter the results based on HMS state like Ready, On etc. Can be specified multiple times for selecting entries in different states.|
|flag|query|string|false|Filter the results based on HMS flag value like OK, Alert etc. Can be specified multiple times for selecting entries with different flags.|
|role|query|string|false|Filter the results based on HMS role. Can be specified multiple times for selecting entries with different roles. Valid values are:|
|subrole|query|string|false|Filter the results based on HMS subrole. Can be specified multiple times for selecting entries with different subroles. Valid values are:|
|enabled|query|string|false|Filter the results based on enabled status (true or false).|
|softwarestatus|query|string|false|Filter the results based on software status. Software status is a free form string. Matching is case-insensitive. Can be specified multiple times for selecting entries with different software statuses.|
|subtype|query|string|false|Filter the results based on HMS subtype. Can be specified multiple times for selecting entries with different subtypes.|
|arch|query|string|false|Filter the results based on architecture. Can be specified multiple times for selecting components with different architectures.|
|class|query|string|false|Filter the results based on HMS hardware class. Can be specified multiple times for selecting entries with different classes.|
|nid|query|string|false|Filter the results based on NID. Can be specified multiple times for selecting entries with multiple specific NIDs.|
|nid_start|query|string|false|Filter the results based on NIDs equal to or greater than the provided integer.|
|nid_end|query|string|false|Filter the results based on NIDs less than or equal to the provided integer.|
|partition|query|string|false|Restrict search to the given partition (p#.#). One partition can be combined with at most one group argument which will be treated as a logical AND. NULL will return components in NO partition.|
|group|query|string|false|Restrict search to the given group label. One group can be combined with at most one partition argument which will be treated as a logical AND. NULL will return components in NO groups.|
|stateonly|query|boolean|false|Return only component state and flag fields (plus xname/ID and type). Results can be modified and used for bulk state/flag- only patch operations.|
|flagonly|query|boolean|false|Return only component flag field (plus xname/ID and type). Results can be modified and used for bulk flag-only patch operations.|
|roleonly|query|boolean|false|Return only component role and subrole fields (plus xname/ID and type). Results can be modified and used for bulk role-only patches.|
|nidonly|query|boolean|false|Return only component NID field (plus xname/ID and type). Results can be modified and used for bulk NID-only patches.|

#### Detailed descriptions

**role**: Filter the results based on HMS role. Can be specified multiple times for selecting entries with different roles. Valid values are:
- Compute
- Service
- System
- Application
- Storage
- Management
Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.

**subrole**: Filter the results based on HMS subrole. Can be specified multiple times for selecting entries with different subroles. Valid values are:
- Master
- Worker
- Storage
Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.

#### Enumerated Values

|Parameter|Value|
|---|---|
|type|CDU|
|type|CabinetCDU|
|type|CabinetPDU|
|type|CabinetPDUOutlet|
|type|CabinetPDUPowerConnector|
|type|CabinetPDUController|
|type|Cabinet|
|type|Chassis|
|type|ChassisBMC|
|type|CMMRectifier|
|type|CMMFpga|
|type|CEC|
|type|ComputeModule|
|type|RouterModule|
|type|NodeBMC|
|type|NodeEnclosure|
|type|NodeEnclosurePowerSupply|
|type|HSNBoard|
|type|MgmtSwitch|
|type|MgmtHLSwitch|
|type|CDUMgmtSwitch|
|type|Node|
|type|Processor|
|type|Drive|
|type|StorageGroup|
|type|NodeNIC|
|type|Memory|
|type|NodeAccel|
|type|NodeAccelRiser|
|type|NodeFpga|
|type|HSNAsic|
|type|RouterFpga|
|type|RouterBMC|
|type|HSNLink|
|type|HSNConnector|
|type|INVALID|
|state|Unknown|
|state|Empty|
|state|Populated|
|state|Off|
|state|On|
|state|Standby|
|state|Halt|
|state|Ready|
|flag|OK|
|flag|Warning|
|flag|Alert|
|flag|Locked|
|flag|Unknown|
|arch|X86|
|arch|ARM|
|arch|Other|
|arch|Unknown|
|class|River|
|class|Mountain|
|class|Hill|

> Example responses

> 200 Response

```json
{
  "Components": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "State": "Ready",
      "Flag": "OK",
      "Enabled": true,
      "SoftwareStatus": "string",
      "Role": "Compute",
      "SubRole": "Worker",
      "NID": 1,
      "Subtype": "string",
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River",
      "ReservationDisabled": false,
      "Locked": false
    }
  ]
}
```

<h3 id="docomponentqueryget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ComponentArray representing results of query.|[ComponentArray_ComponentArray](#schemacomponentarray_componentarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-nodemap">NodeMap</h1>

Given a node xname ID, provide defaults for NID, Role, etc. to be used when the node is first discovered. These are uploaded prior to discovery and should contain mappings for each valid node xname in the system, whether populated or not.

## doNodeMapsGet

<a id="opIddoNodeMapsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Defaults/NodeMaps HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Defaults/NodeMaps \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Defaults/NodeMaps', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Defaults/NodeMaps", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Defaults/NodeMaps`

*Retrieve all NodeMaps, returning NodeMapArray*

Retrieve all Node map entries as a named array, or an empty array if the collection is empty.

> Example responses

> 200 Response

```json
{
  "NodeMaps": [
    {
      "ID": "x0c0s0b0n0",
      "NID": 1,
      "Role": "Compute",
      "SubRole": "Worker"
    }
  ]
}
```

<h3 id="donodemapsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Named NodeMaps array representing all xname locations that have defaults registered.|[NodeMapArray_NodeMapArray](#schemanodemaparray_nodemaparray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doNodeMapPost

<a id="opIddoNodeMapPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/Defaults/NodeMaps HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/Defaults/NodeMaps \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/Defaults/NodeMaps', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/Defaults/NodeMaps", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /Defaults/NodeMaps`

*Create or Modify NodeMaps*

Create or update the given set of NodeMaps whose ID fields are each a valid xname. The NID field is required and serves as the NID that will be used when a component with the same xname ID is created for the first time by discovery.
Role is an optional field. A node is assigned the default (e.g. Compute) role when it is first created during discovery. The NID must be unique across all entries.
SubRole is an optional field. A node is assigned no subrole by default when it is first created during discovery.

The NodeMaps collection should be uploaded at install time by specifying it as a JSON file. As a result, when the endpoints are automatically discovered by REDS, and inventory discovery is performed by HSM, the desired NID numbers will be set as soon as the nodes are created using the NodeMaps collection. All node xnames that are expected to be used in the system should be included in the mapping, even if not currently populated.

It is recommended that NodeMaps are uploaded at install time before discovery happens. If they are uploaded after discovery, then the node xnames need to be manually updated with the correct NIDs. You can update NIDs for individual components by using PATCH /State/Components/{xname}/NID.

Note the following points:
* If the POST operation contains an xname that already exists, the entry will be overwritten with the new entry (i.e. new NID, Role (if given), etc.).
* The same NID cannot be used for more than one xname. If such a duplicate would be created, the operation will fail.
* If the node has already been discovered for the first time (that is, it exists in /hsm/v2/State/Components and already has a previous/default NID), modifying the NodeMap entry will not automatically reassign the current NID.
* If you wish to use POST to completely replace the current NodeMaps collection (rather than modifying it), first delete it using the DELETE method on the collection. Otherwise the current entries and the new ones will be merged if they are disjoint sets of nodes.

> Body parameter

```json
{
  "NodeMaps": [
    {
      "ID": "x0c0s0b0n0",
      "NID": 1,
      "Role": "Compute",
      "SubRole": "Worker"
    }
  ]
}
```

<h3 id="donodemappost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[NodeMapArray_NodeMapArray](#schemanodemaparray_nodemaparray)|true|none|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="donodemappost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries created or updated.  Message contains count of new/modified items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. Duplicate resource (NID) would be created.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doNodeMapsDeleteAll

<a id="opIddoNodeMapsDeleteAll"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Defaults/NodeMaps HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Defaults/NodeMaps \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Defaults/NodeMaps', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Defaults/NodeMaps", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Defaults/NodeMaps`

*Delete all NodeMap entities*

Delete all entries in the NodeMaps collection.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="donodemapsdeleteall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries deleted. Message contains count of deleted items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Collection is empty|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doNodeMapGet

<a id="opIddoNodeMapGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Defaults/NodeMaps/{xname}`

*Retrieve NodeMap at {xname}*

Retrieve NodeMap, i.e. defaults NID/Role/etc. for node located at physical location {xname}.

<h3 id="donodemapget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of NodeMap record to return.|

> Example responses

> 200 Response

```json
{
  "ID": "x0c0s0b0n0",
  "NID": 1,
  "Role": "Compute",
  "SubRole": "Worker"
}
```

<h3 id="donodemapget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|NodeMap entry matching xname/ID|[NodeMap.1.0.0_NodeMap](#schemanodemap.1.0.0_nodemap)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doNodeMapDelete

<a id="opIddoNodeMapDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Defaults/NodeMaps/{xname}`

*Delete NodeMap with ID {xname}*

Delete NodeMap entry for a specific node {xname}.

<h3 id="donodemapdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of NodeMap record to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="donodemapdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - NodeMap is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|XName does Not Exist - no matching ID to delete|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doNodeMapPut

<a id="opIddoNodeMapPut"></a>

> Code samples

```http
PUT https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname}', headers = headers)

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
    req, err := http.NewRequest("PUT", "https://sms/apis/smd/hsm/v2/Defaults/NodeMaps/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /Defaults/NodeMaps/{xname}`

*Update definition for NodeMap ID {xname}*

Update or create an entry for an individual node xname using PUT. Note the following points:
* If the PUT operation contains an xname that already exists, the entry will be overwritten with the new entry (i.e. new NID, Role (if given), etc.).
* The same NID cannot be used for more than one xname. If such a duplicate would be created, the operation will fail.
* If the node has already been discovered for the first time (that is, it exists in /hsm/v2/State/Components and already has a previous/default NID), modifying the NodeMap entry will not automatically reassign the current NID.

> Body parameter

```json
{
  "NID": 1,
  "Role": "Compute",
  "SubRole": "Worker"
}
```

<h3 id="donodemapput-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of NodeMap record to create or update.|
|body|body|[NodeMap.1.0.0_NodeMap](#schemanodemap.1.0.0_nodemap)|true|none|

> Example responses

> 200 Response

```json
{
  "ID": "x0c0s0b0n0",
  "NID": 1,
  "Role": "Compute",
  "SubRole": "Worker"
}
```

<h3 id="donodemapput-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|NodeMap entry was successfully created/updated.|[NodeMap.1.0.0_PostNodeMap](#schemanodemap.1.0.0_postnodemap)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. Duplicate resource (NID) would be created.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-hwinventory">HWInventory</h1>

HWInventoryByLocation collection containing all components matching the query that was submitted.

## doHWInvByLocationQueryGet

<a id="opIddoHWInvByLocationQueryGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/Hardware/Query/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/Hardware/Query/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/Hardware/Query/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/Hardware/Query/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/Hardware/Query/{xname}`

*Retrieve results of HWInventory query starting at {xname}*

Retrieve zero or more HWInventoryByLocation entries in the form of a HWInventory by providing xname and modifiers in query string. The FRU (field-replaceable unit) data will be included in each HWInventoryByLocation entry if the location is populated.

<h3 id="dohwinvbylocationqueryget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of parent component, system (e.g. s0, all) or partition (p#.#) to target for hardware inventory|
|type|query|string|false|Filter the results based on HMS type like Node, NodeEnclosure, NodeBMC etc. Can be specified multiple times for selecting entries of multiple types.|
|children|query|boolean|false|Also return children of the selected components. Default is true.|
|parents|query|boolean|false|Also return parents of the selected components.|
|partition|query|string|false|Restrict search to the given partition (p#.#). Child components are assumed to be in the same partition as the parent component when performing this kind of query.|
|format|query|string|false|How to display results|

#### Detailed descriptions

**format**: How to display results

  FullyFlat      All component types listed in their own
                 arrays only.  No nesting of any children.
  NestNodesOnly  Flat except that node subcomponents are nested
                 hierarchically.
Default is NestNodesOnly.

#### Enumerated Values

|Parameter|Value|
|---|---|
|type|CDU|
|type|CabinetCDU|
|type|CabinetPDU|
|type|CabinetPDUOutlet|
|type|CabinetPDUPowerConnector|
|type|CabinetPDUController|
|type|Cabinet|
|type|Chassis|
|type|ChassisBMC|
|type|CMMRectifier|
|type|CMMFpga|
|type|CEC|
|type|ComputeModule|
|type|RouterModule|
|type|NodeBMC|
|type|NodeEnclosure|
|type|NodeEnclosurePowerSupply|
|type|HSNBoard|
|type|MgmtSwitch|
|type|MgmtHLSwitch|
|type|CDUMgmtSwitch|
|type|Node|
|type|Processor|
|type|Drive|
|type|StorageGroup|
|type|NodeNIC|
|type|Memory|
|type|NodeAccel|
|type|NodeAccelRiser|
|type|NodeFpga|
|type|HSNAsic|
|type|RouterFpga|
|type|RouterBMC|
|type|HSNLink|
|type|HSNConnector|
|type|INVALID|

> Example responses

> 200 Response

```json
{
  "XName": "x0c0s0b0n0",
  "Format": "NestNodesOnly",
  "Cabinets": [
    {
      "ID": "x0",
      "Type": "Cabinet",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocCabinet",
      "CabinetLocationInfo": {
        "Id": "Cabinet",
        "Name": "Name describing cabinet or where it is located, per manufacturing",
        "Description": "Description of cabinet, per manufacturing",
        "Hostname": "if_defined_in_Redfish"
      },
      "PopulatedFRU": {
        "FRUID": "Cray-2345-1234556789",
        "Type": "Cabinet",
        "Subtype": "MountainCabinet (example)",
        "HWInventoryByFRUType": "HWInvByFRUCabinet",
        "CabinetFRUInfo": {
          "AssetTag": "AdminAssignedAssetTag",
          "Model": 123,
          "Manufacturer": "Cray",
          "PartNumber": "p2345",
          "SerialNumber": "sn1234556789",
          "SKU": "as213234",
          "ChassisType": "Rack"
        }
      }
    }
  ],
  "Chassis": [
    {
      "ID": "x0c0",
      "Type": "Chassis",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocChassis",
      "ChassisLocationInfo": {
        "Id": "Chassis.1",
        "Name": "Name describing component or its location, per manufacturing",
        "Description": "Description, per manufacturing",
        "Hostname": "if_defined_in_Redfish"
      },
      "PopulatedFRU": {
        "FRUID": "Cray-ch01-23452345",
        "Type": "Chassis",
        "Subtype": "MountainChassis (example)",
        "HWInventoryByFRUType": "HWInvByFRUChassis",
        "ChassisFRUInfo": {
          "AssetTag": "AdminAssignedAssetTag",
          "Model": 3245,
          "Manufacturer": "Cray",
          "PartNumber": "ch01",
          "SerialNumber": "sn23452345",
          "SKU": "as213234",
          "ChassisType": "Enclosure"
        }
      }
    }
  ],
  "ComputeModules": [
    {
      "ComputeModuleLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      },
      "NodeEnclosures": [
        {
          "NodeEnclosureLocationInfo": {
            "Id": "string",
            "Name": "string",
            "Description": "string",
            "Hostname": "string"
          }
        }
      ]
    }
  ],
  "RouterModules": [
    {
      "RouterModuleLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      },
      "HSNBoards": [
        {
          "HSNBoardLocationInfo": {
            "Id": "string",
            "Name": "string",
            "Description": "string",
            "Hostname": "string"
          }
        }
      ]
    }
  ],
  "NodeEnclosures": [
    {
      "NodeEnclosureLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ],
  "HSNBoards": [
    {
      "HSNBoardLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ],
  "MgmtSwitches": [
    {
      "MgmtSwitchLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ],
  "MgmtHLSwitches": [
    {
      "MgmtHLSwitchLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ],
  "CDUMgmtSwitches": [
    {
      "CDUMgmtSwitchLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ],
  "Nodes": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocNode",
      "NodeLocationInfo": {
        "Id": "System.Embedded.1",
        "Name": "Name describing system or where it is located, per manufacturing",
        "Description": "Description of system/node type, per manufacturing",
        "Hostname": "if_defined_in_Redfish",
        "ProcessorSummary": {
          "Count": 2,
          "Model": "Multi-Core Intel(R) Xeon(R) processor E5-16xx Series"
        },
        "MemorySummary": {
          "TotalSystemMemoryGiB": 64
        }
      },
      "PopulatedFRU": {
        "FRUID": "Dell-99999-1234.1234.2345",
        "Type": "Node",
        "Subtype": "River",
        "HWInventoryByFRUType": "HWInvByFRUNode",
        "NodeFRUInfo": {
          "AssetTag": "AdminAssignedAssetTag",
          "BiosVersion": "v1.0.2.9999",
          "Model": "OKS0P2354",
          "Manufacturer": "Dell",
          "PartNumber": "p99999",
          "SerialNumber": "1234.1234.2345",
          "SKU": "as213234",
          "SystemType": "Physical",
          "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
        }
      },
      "Processors": [
        {
          "ID": "x0c0s0b0n0p0",
          "Type": "Processor",
          "Ordinal": 0,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocProcessor",
          "ProcessorLocationInfo": {
            "Id": "CPU1",
            "Name": "Processor",
            "Description": "Socket 1 Processor",
            "Socket": "CPU 1"
          },
          "PopulatedFRU": {
            "FRUID": "HOW-TO-ID-CPUS-FROM-REDFISH-IF-AT-ALL",
            "Type": "Processor",
            "Subtype": "SKL24",
            "HWInventoryByFRUType": "HWInvByFRUProcessor",
            "ProcessorFRUInfo": {
              "InstructionSet": "x86-64",
              "Manufacturer": "Intel",
              "MaxSpeedMHz": 2600,
              "Model": "Intel(R) Xeon(R) CPU E5-2623 v4 @ 2.60GHz",
              "ProcessorArchitecture": "x86",
              "ProcessorId": {
                "EffectiveFamily": 6,
                "EffectiveModel": 79,
                "IdentificationRegisters": 263921,
                "MicrocodeInfo": 184549399,
                "Step": 1,
                "VendorID": "GenuineIntel"
              },
              "ProcessorType": "CPU",
              "TotalCores": 24,
              "TotalThreads": 48
            }
          }
        },
        {
          "ID": "x0c0s0b0n0p1",
          "Type": "Processor",
          "Ordinal": 1,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocProcessor",
          "ProcessorLocationInfo": {
            "Id": "CPU2",
            "Name": "Processor",
            "Description": "Socket 2 Processor",
            "Socket": "CPU 2"
          },
          "PopulatedFRU": {
            "FRUID": "HOW-TO-ID-CPUS-FROM-REDFISH-IF-AT-ALL",
            "Type": "Processor",
            "Subtype": "SKL24",
            "HWInventoryByFRUType": "HWInvByFRUProcessor",
            "ProcessorFRUInfo": {
              "InstructionSet": "x86-64",
              "Manufacturer": "Intel",
              "MaxSpeedMHz": 2600,
              "Model": "Intel(R) Xeon(R) CPU E5-2623 v4 @ 2.60GHz",
              "ProcessorArchitecture": "x86",
              "ProcessorId": {
                "EffectiveFamily": 6,
                "EffectiveModel": 79,
                "IdentificationRegisters": 263921,
                "MicrocodeInfo": 184549399,
                "Step": 1,
                "VendorID": "GenuineIntel"
              },
              "ProcessorType": "CPU",
              "TotalCores": 24,
              "TotalThreads": 48
            }
          }
        }
      ],
      "Memory": [
        {
          "ID": "x0c0s0b0n0d0",
          "Type": "Memory",
          "Ordinal": 0,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocMemory",
          "MemoryLocationInfo": {
            "Id": "DIMM1",
            "Name": "DIMM Slot 1",
            "MemoryLocation": {
              "Socket": 1,
              "MemoryController": 1,
              "Channel": 1,
              "Slot": 1
            }
          },
          "PopulatedFRU": {
            "FRUID": "MFR-PARTNUMBER-SERIALNUMBER",
            "Type": "Memory",
            "Subtype": "DIMM2400G32",
            "HWInventoryByFRUType": "HWInvByFRUMemory",
            "MemoryFRUInfo": {
              "BaseModuleType": "RDIMM",
              "BusWidthBits": 72,
              "CapacityMiB": 32768,
              "DataWidthBits": 64,
              "ErrorCorrection": "MultiBitECC",
              "Manufacturer": "Micron",
              "MemoryType": "DRAM",
              "MemoryDeviceType": "DDR4",
              "OperatingSpeedMhz": 2400,
              "PartNumber": "XYZ-123-1232",
              "RankCount": 2,
              "SerialNumber": "sn12344567689"
            }
          }
        },
        {
          "ID": "x0c0s0b0n0d1",
          "Type": "Memory",
          "Ordinal": 1,
          "Status": "Empty",
          "HWInventoryByLocationType": "HWInvByLocMemory",
          "MemoryLocationInfo": {
            "Id": "DIMM2",
            "Name": "Socket 1 DIMM Slot 2",
            "MemoryLocation": {
              "Socket": 1,
              "MemoryController": 1,
              "Channel": 1,
              "Slot": 2
            }
          },
          "PopulatedFRU": null
        },
        {
          "ID": "x0c0s0b0n0d2",
          "Type": "Memory",
          "Ordinal": 2,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocMemory",
          "MemoryLocationInfo": {
            "Id": "DIMM3",
            "Name": "Socket 2 DIMM Slot 1",
            "MemoryLocation": {
              "Socket": 2,
              "MemoryController": 2,
              "Channel": 1,
              "Slot": 1
            }
          },
          "PopulatedFRU": {
            "FRUID": "MFR-PARTNUMBER-SERIALNUMBER_2",
            "Type": "Memory",
            "Subtype": "DIMM2400G32",
            "HWInventoryByFRUType": "HWInvByFRUMemory",
            "MemoryFRUInfo": {
              "BaseModuleType": "RDIMM",
              "BusWidthBits": 72,
              "CapacityMiB": 32768,
              "DataWidthBits": 64,
              "ErrorCorrection": "MultiBitECC",
              "Manufacturer": "Micron",
              "MemoryType": "DRAM",
              "MemoryDeviceType": "DDR4",
              "OperatingSpeedMhz": 2400,
              "PartNumber": "XYZ-123-1232",
              "RankCount": 2,
              "SerialNumber": "k346456346346"
            }
          }
        },
        {
          "ID": "x0c0s0b0n0d3",
          "Type": "Memory",
          "Ordinal": 3,
          "Status": "Empty",
          "HWInventoryByLocationType": "HWInvByLocMemory",
          "MemoryLocationInfo": {
            "Id": "DIMM3",
            "Name": "Socket 2 DIMM Slot 2",
            "MemoryLocation": {
              "Socket": 2,
              "MemoryController": 2,
              "Channel": 1,
              "Slot": 2
            }
          },
          "PopulatedFRU": null
        }
      ]
    }
  ],
  "Processors": [
    {
      "description": "By default, listed as subcomponent of Node, see example there."
    }
  ],
  "NodeAccels": [
    {
      "description": "By default, listed as subcomponent of Node."
    }
  ],
  "Drives": [
    {
      "description": "By default, listed as subcomponent of Node, see example there."
    }
  ],
  "Memory": [
    {
      "description": "By default, listed as subcomponent of Node, see example there."
    }
  ],
  "CabinetPDUs": [
    {
      "ID": "x0m0p0",
      "Type": "CabinetPDU",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocPDU",
      "PDULocationInfo": {
        "Id": "1",
        "Name": "RackPDU1",
        "Description": "Description of PDU, per manufacturing",
        "UUID": "32354641-4135-4332-4a35-313735303734"
      },
      "PopulatedFRU": {
        "FRUID": "CabinetPDU.29347ZT536",
        "Type": "CabinetPDU",
        "HWInventoryByFRUType": "HWInvByFRUPDU",
        "PDUFRUInfo": {
          "FirmwareVersion": "4.3.0",
          "EquipmentType": "RackPDU",
          "Manufacturer": "Contoso",
          "CircuitSummary": {
            "TotalPhases": 3,
            "TotalBranches": 4,
            "TotalOutlets": 16,
            "MonitoredPhases": 3,
            "ControlledOutlets": 8,
            "MonitoredBranches": 4,
            "MonitoredOutlets": 12
          },
          "AssetTag": "PDX-92381",
          "DateOfManufacture": "2017-01-11T08:00:00Z",
          "HardwareRevision": "1.03b",
          "Model": "ZAP4000",
          "SerialNumber": "29347ZT536",
          "PartNumber": "AA-23"
        }
      },
      "CabinetPDUPowerConnectors": [
        {
          "ID": "x0m0p0v1",
          "Type": "CabinetPDUPowerConnector",
          "Ordinal": 0,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocOutlet",
          "OutletLocationInfo": {
            "Id": "A1",
            "Name": "Outlet A1, Branch Circuit A",
            "Description": "Outlet description"
          },
          "PopulatedFRU": {
            "FRUID": "CabinetPDUPowerConnector.0.CabinetPDU.29347ZT536",
            "Type": "CabinetPDUPowerConnector",
            "HWInventoryByFRUType": "HWInvByFRUOutlet",
            "OutletFRUInfo": {
              "PowerEnabled": true,
              "NominalVoltage": "AC120V",
              "RatedCurrentAmps": 20,
              "VoltageType": "AC",
              "OutletType": "NEMA_5_20R",
              "PhaseWiringType": "OnePhase3Wire"
            }
          }
        },
        {
          "ID": "x0m0p0v2",
          "Type": "CabinetPDUPowerConnector",
          "Ordinal": 2,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocOutlet",
          "OutletLocationInfo": {
            "Id": "A2",
            "Name": "Outlet A2, Branch Circuit A",
            "Description": "Outlet description"
          },
          "PopulatedFRU": {
            "FRUID": "CabinetPDUPowerConnector.1.CabinetPDU.29347ZT536",
            "Type": "CabinetPDUPowerConnector",
            "HWInventoryByFRUType": "HWInvByFRUOutlet",
            "OutletFRUInfo": {
              "PowerEnabled": true,
              "NominalVoltage": "AC120V",
              "RatedCurrentAmps": 20,
              "VoltageType": "AC",
              "OutletType": "NEMA_5_20R",
              "PhaseWiringType": "OnePhase3Wire"
            }
          }
        }
      ]
    }
  ],
  "CabinetPDUPowerConnectors": [
    {
      "description": "By default, listed as subcomponent of PDU, see example there."
    }
  ],
  "CMMRectifiers": [
    {
      "CMMRectifierLocationInfo": {
        "Name": "string",
        "FirmwareVersion": "string"
      }
    }
  ],
  "NodeAccelRisers": [
    {
      "NodeAccelRiserLocationInfo": {
        "Name": "string",
        "Description": "string"
      }
    }
  ],
  "NodeHsnNICs": [
    {
      "HSNNICLocationInfo": {
        "Description": "string",
        "Id": "string",
        "Name": "string"
      }
    }
  ],
  "NodeEnclosurePowerSupplies": [
    {
      "NodeEnclosurePowerSupplyLocationInfo": {
        "Name": "string",
        "FirmwareVersion": "string"
      }
    }
  ],
  "NodeBMC": [
    {
      "NodeBMCLocationInfo": {
        "DateTime": "string",
        "DateTimeLocalOffset": "string",
        "Description": "string",
        "FirmwareVersion": "string",
        "Id": "string",
        "Name": "string"
      }
    }
  ],
  "RouterBMC": [
    {
      "RouterBMCLocationInfo": {
        "DateTime": "string",
        "DateTimeLocalOffset": "string",
        "Description": "string",
        "FirmwareVersion": "string",
        "Id": "string",
        "Name": "string"
      }
    }
  ]
}
```

<h3 id="dohwinvbylocationqueryget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ComponentArray representing results of query.|[HWInventory.1.0.0_HWInventory](#schemahwinventory.1.0.0_hwinventory)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-hwinventorybylocation">HWInventoryByLocation</h1>

Hardware inventory information for the given system location/xname

## doHWInvByLocationGetAll

<a id="opIddoHWInvByLocationGetAll"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/Hardware HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/Hardware \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/Hardware', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/Hardware", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/Hardware`

*Retrieve all HWInventoryByLocation entries in array*

Retrieve all HWInventoryByLocation entries. Note that all entries are displayed as a flat array. For most purposes, you will want to use /Inventory/Hardware/Query.

<h3 id="dohwinvbylocationgetall-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|query|string|false|Filter the results based on xname ID(s). Can be specified multiple times for selecting entries with multiple specific xnames.|
|type|query|string|false|Filter the results based on HMS type like Node, NodeEnclosure, NodeBMC etc. Can be specified multiple times for selecting entries of multiple types.|
|manufacturer|query|string|false|Retrieve HWInventoryByLocation entries with the given Manufacturer.|
|partnumber|query|string|false|Retrieve HWInventoryByLocation entries with the given part number.|
|serialnumber|query|string|false|Retrieve HWInventoryByLocation entries with the given serial number.|
|fruid|query|string|false|Retrieve HWInventoryByLocation entries with the given FRU ID.|

#### Enumerated Values

|Parameter|Value|
|---|---|
|type|CDU|
|type|CabinetCDU|
|type|CabinetPDU|
|type|CabinetPDUOutlet|
|type|CabinetPDUPowerConnector|
|type|CabinetPDUController|
|type|Cabinet|
|type|Chassis|
|type|ChassisBMC|
|type|CMMRectifier|
|type|CMMFpga|
|type|CEC|
|type|ComputeModule|
|type|RouterModule|
|type|NodeBMC|
|type|NodeEnclosure|
|type|NodeEnclosurePowerSupply|
|type|HSNBoard|
|type|MgmtSwitch|
|type|MgmtHLSwitch|
|type|CDUMgmtSwitch|
|type|Node|
|type|Processor|
|type|Drive|
|type|StorageGroup|
|type|NodeNIC|
|type|Memory|
|type|NodeAccel|
|type|NodeAccelRiser|
|type|NodeFpga|
|type|HSNAsic|
|type|RouterFpga|
|type|RouterBMC|
|type|HSNLink|
|type|HSNConnector|
|type|INVALID|

> Example responses

> 200 Response

```json
[
  null
]
```

<h3 id="dohwinvbylocationgetall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Flat, unsorted HWInventoryByLocation array.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dohwinvbylocationgetall-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)]|false|none|[This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.]|
|» ID|[XNameCompOrPartition.1.0.0](#schemaxnamecomporpartition.1.0.0)|true|none|This is an ordinary xname, but one where only a partition (hard:soft) or the system alias (s0) will be expected as valid input, or else a parent component.|
|» Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|read-only|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|» Ordinal|integer(int32)|false|read-only|This is the normalized (from zero) index of the component location (e.g. slot number) when there are more than one.  This should match the last number in the xname in most cases (e.g. Ordinal 0 for node x0c0s0b0n0).  Note that Redfish may use a different value or naming scheme, but this is passed through via the *LocationInfo for the type of component.|
|» Status|string|false|read-only|Populated or Empty - whether location is populated.|
|» HWInventoryByLocationType|string|true|none|This is used as a discriminator to determine the additional HMS-type specific subtype that is returned.|
|» PopulatedFRU|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|
|»» FRUID|[FRUId.1.0.0](#schemafruid.1.0.0)|false|read-only|Uniquely identifies a piece of hardware by a serial-number like identifier that is globally unique within the hardware inventory,|
|»» Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|read-only|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|»» FRUSubtype|string|false|none|TBD.|
|»» HWInventoryByFRUType|string|true|none|This is used as a discriminator to determine the additional HMS-type specific subtype that is returned.|

#### Enumerated Values

|Property|Value|
|---|---|
|Type|CDU|
|Type|CabinetCDU|
|Type|CabinetPDU|
|Type|CabinetPDUOutlet|
|Type|CabinetPDUPowerConnector|
|Type|CabinetPDUController|
|Type|Cabinet|
|Type|Chassis|
|Type|ChassisBMC|
|Type|CMMRectifier|
|Type|CMMFpga|
|Type|CEC|
|Type|ComputeModule|
|Type|RouterModule|
|Type|NodeBMC|
|Type|NodeEnclosure|
|Type|NodeEnclosurePowerSupply|
|Type|HSNBoard|
|Type|MgmtSwitch|
|Type|MgmtHLSwitch|
|Type|CDUMgmtSwitch|
|Type|Node|
|Type|Processor|
|Type|Drive|
|Type|StorageGroup|
|Type|NodeNIC|
|Type|Memory|
|Type|NodeAccel|
|Type|NodeAccelRiser|
|Type|NodeFpga|
|Type|HSNAsic|
|Type|RouterFpga|
|Type|RouterBMC|
|Type|HSNLink|
|Type|HSNConnector|
|Type|INVALID|
|Status|Populated|
|Status|Empty|
|HWInventoryByLocationType|HWInvByLocCabinet|
|HWInventoryByLocationType|HWInvByLocChassis|
|HWInventoryByLocationType|HWInvByLocComputeModule|
|HWInventoryByLocationType|HWInvByLocRouterModule|
|HWInventoryByLocationType|HWInvByLocNodeEnclosure|
|HWInventoryByLocationType|HWInvByLocHSNBoard|
|HWInventoryByLocationType|HWInvByLocMgmtSwitch|
|HWInventoryByLocationType|HWInvByLocMgmtHLSwitch|
|HWInventoryByLocationType|HWInvByLocCDUMgmtSwitch|
|HWInventoryByLocationType|HWInvByLocNode|
|HWInventoryByLocationType|HWInvByLocProcessor|
|HWInventoryByLocationType|HWInvByLocNodeAccel|
|HWInventoryByLocationType|HWInvByLocNodeAccelRiser|
|HWInventoryByLocationType|HWInvByLocDrive|
|HWInventoryByLocationType|HWInvByLocMemory|
|HWInventoryByLocationType|HWInvByLocPDU|
|HWInventoryByLocationType|HWInvByLocOutlet|
|HWInventoryByLocationType|HWInvByLocCMMRectifier|
|HWInventoryByLocationType|HWInvByLocNodeEnclosurePowerSupply|
|HWInventoryByLocationType|HWInvByLocNodeBMC|
|HWInventoryByLocationType|HWInvByLocRouterBMC|
|HWInventoryByLocationType|HWInvByLocHSNNIC|
|Type|CDU|
|Type|CabinetCDU|
|Type|CabinetPDU|
|Type|CabinetPDUOutlet|
|Type|CabinetPDUPowerConnector|
|Type|CabinetPDUController|
|Type|Cabinet|
|Type|Chassis|
|Type|ChassisBMC|
|Type|CMMRectifier|
|Type|CMMFpga|
|Type|CEC|
|Type|ComputeModule|
|Type|RouterModule|
|Type|NodeBMC|
|Type|NodeEnclosure|
|Type|NodeEnclosurePowerSupply|
|Type|HSNBoard|
|Type|MgmtSwitch|
|Type|MgmtHLSwitch|
|Type|CDUMgmtSwitch|
|Type|Node|
|Type|Processor|
|Type|Drive|
|Type|StorageGroup|
|Type|NodeNIC|
|Type|Memory|
|Type|NodeAccel|
|Type|NodeAccelRiser|
|Type|NodeFpga|
|Type|HSNAsic|
|Type|RouterFpga|
|Type|RouterBMC|
|Type|HSNLink|
|Type|HSNConnector|
|Type|INVALID|
|HWInventoryByFRUType|HWInvByFRUCabinet|
|HWInventoryByFRUType|HWInvByFRUChassis|
|HWInventoryByFRUType|HWInvByFRUComputeModule|
|HWInventoryByFRUType|HWInvByFRURouterModule|
|HWInventoryByFRUType|HWInvByFRUNodeEnclosure|
|HWInventoryByFRUType|HWInvByFRUHSNBoard|
|HWInventoryByFRUType|HWInvByFRUMgmtSwitch|
|HWInventoryByFRUType|HWInvByFRUMgmtHLSwitch|
|HWInventoryByFRUType|HWInvByFRUCDUMgmtSwitch|
|HWInventoryByFRUType|HWInvByFRUNode|
|HWInventoryByFRUType|HWInvByFRUProcessor|
|HWInventoryByFRUType|HWInvByFRUNodeAccel|
|HWInventoryByFRUType|HWInvByFRUNodeAccelRiser|
|HWInventoryByFRUType|HWInvByFRUDrive|
|HWInventoryByFRUType|HWInvByFRUMemory|
|HWInventoryByFRUType|HWInvByFRUPDU|
|HWInventoryByFRUType|HWInvByFRUOutlet|
|HWInventoryByFRUType|HWInvByFRUCMMRectifier|
|HWInventoryByFRUType|HWInvByFRUNodeEnclosurePowerSupply|
|HWInventoryByFRUType|HWInvByFRUNodeBMC|
|HWInventoryByFRUType|HWInvByFRURouterBMC|
|HWInventoryByFRUType|HWIncByFRUHSNNIC|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvByLocationPost

<a id="opIddoHWInvByLocationPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/Inventory/Hardware HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/Inventory/Hardware \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/Inventory/Hardware', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/Inventory/Hardware", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /Inventory/Hardware`

*Create/Update hardware inventory entries*

Create/Update hardware inventory entries

> Body parameter

```json
{
  "Hardware": [
    {
      "ID": "x3000c0s23b4n4h0",
      "HWInventoryByLocationType": "HWInvByLocHSNNIC",
      "HSNNICLocationInfo": {
        "Id": "HPCNet3",
        "Description": "Shasta Timms NMC REV04 (HSN)"
      },
      "PopulatedFRU": {
        "HWInventoryByFRUType": "HWInvByFRUHSNNIC",
        "HSNNICFRUInfo": {
          "Model": "ConnectX-5 100Gb/s",
          "SerialNumber": "HG20190738",
          "PartNumber": "102005303",
          "Manufacturer": "Mellanox Technologies, Ltd."
        }
      }
    }
  ]
}
```

<h3 id="dohwinvbylocationpost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|object|true|none|
|» Hardware|body|[[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)]|false|[This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.]|
|»» ID|body|[XNameCompOrPartition.1.0.0](#schemaxnamecomporpartition.1.0.0)|true|This is an ordinary xname, but one where only a partition (hard:soft) or the system alias (s0) will be expected as valid input, or else a parent component.|
|»» Type|body|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|»» Ordinal|body|integer(int32)|false|This is the normalized (from zero) index of the component location (e.g. slot number) when there are more than one.  This should match the last number in the xname in most cases (e.g. Ordinal 0 for node x0c0s0b0n0).  Note that Redfish may use a different value or naming scheme, but this is passed through via the *LocationInfo for the type of component.|
|»» Status|body|string|false|Populated or Empty - whether location is populated.|
|»» HWInventoryByLocationType|body|string|true|This is used as a discriminator to determine the additional HMS-type specific subtype that is returned.|
|»» PopulatedFRU|body|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|
|»»» FRUID|body|[FRUId.1.0.0](#schemafruid.1.0.0)|false|Uniquely identifies a piece of hardware by a serial-number like identifier that is globally unique within the hardware inventory,|
|»»» Type|body|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|»»» FRUSubtype|body|string|false|TBD.|
|»»» HWInventoryByFRUType|body|string|true|This is used as a discriminator to determine the additional HMS-type specific subtype that is returned.|

#### Enumerated Values

|Parameter|Value|
|---|---|
|»» Type|CDU|
|»» Type|CabinetCDU|
|»» Type|CabinetPDU|
|»» Type|CabinetPDUOutlet|
|»» Type|CabinetPDUPowerConnector|
|»» Type|CabinetPDUController|
|»» Type|Cabinet|
|»» Type|Chassis|
|»» Type|ChassisBMC|
|»» Type|CMMRectifier|
|»» Type|CMMFpga|
|»» Type|CEC|
|»» Type|ComputeModule|
|»» Type|RouterModule|
|»» Type|NodeBMC|
|»» Type|NodeEnclosure|
|»» Type|NodeEnclosurePowerSupply|
|»» Type|HSNBoard|
|»» Type|MgmtSwitch|
|»» Type|MgmtHLSwitch|
|»» Type|CDUMgmtSwitch|
|»» Type|Node|
|»» Type|Processor|
|»» Type|Drive|
|»» Type|StorageGroup|
|»» Type|NodeNIC|
|»» Type|Memory|
|»» Type|NodeAccel|
|»» Type|NodeAccelRiser|
|»» Type|NodeFpga|
|»» Type|HSNAsic|
|»» Type|RouterFpga|
|»» Type|RouterBMC|
|»» Type|HSNLink|
|»» Type|HSNConnector|
|»» Type|INVALID|
|»» Status|Populated|
|»» Status|Empty|
|»» HWInventoryByLocationType|HWInvByLocCabinet|
|»» HWInventoryByLocationType|HWInvByLocChassis|
|»» HWInventoryByLocationType|HWInvByLocComputeModule|
|»» HWInventoryByLocationType|HWInvByLocRouterModule|
|»» HWInventoryByLocationType|HWInvByLocNodeEnclosure|
|»» HWInventoryByLocationType|HWInvByLocHSNBoard|
|»» HWInventoryByLocationType|HWInvByLocMgmtSwitch|
|»» HWInventoryByLocationType|HWInvByLocMgmtHLSwitch|
|»» HWInventoryByLocationType|HWInvByLocCDUMgmtSwitch|
|»» HWInventoryByLocationType|HWInvByLocNode|
|»» HWInventoryByLocationType|HWInvByLocProcessor|
|»» HWInventoryByLocationType|HWInvByLocNodeAccel|
|»» HWInventoryByLocationType|HWInvByLocNodeAccelRiser|
|»» HWInventoryByLocationType|HWInvByLocDrive|
|»» HWInventoryByLocationType|HWInvByLocMemory|
|»» HWInventoryByLocationType|HWInvByLocPDU|
|»» HWInventoryByLocationType|HWInvByLocOutlet|
|»» HWInventoryByLocationType|HWInvByLocCMMRectifier|
|»» HWInventoryByLocationType|HWInvByLocNodeEnclosurePowerSupply|
|»» HWInventoryByLocationType|HWInvByLocNodeBMC|
|»» HWInventoryByLocationType|HWInvByLocRouterBMC|
|»» HWInventoryByLocationType|HWInvByLocHSNNIC|
|»»» Type|CDU|
|»»» Type|CabinetCDU|
|»»» Type|CabinetPDU|
|»»» Type|CabinetPDUOutlet|
|»»» Type|CabinetPDUPowerConnector|
|»»» Type|CabinetPDUController|
|»»» Type|Cabinet|
|»»» Type|Chassis|
|»»» Type|ChassisBMC|
|»»» Type|CMMRectifier|
|»»» Type|CMMFpga|
|»»» Type|CEC|
|»»» Type|ComputeModule|
|»»» Type|RouterModule|
|»»» Type|NodeBMC|
|»»» Type|NodeEnclosure|
|»»» Type|NodeEnclosurePowerSupply|
|»»» Type|HSNBoard|
|»»» Type|MgmtSwitch|
|»»» Type|MgmtHLSwitch|
|»»» Type|CDUMgmtSwitch|
|»»» Type|Node|
|»»» Type|Processor|
|»»» Type|Drive|
|»»» Type|StorageGroup|
|»»» Type|NodeNIC|
|»»» Type|Memory|
|»»» Type|NodeAccel|
|»»» Type|NodeAccelRiser|
|»»» Type|NodeFpga|
|»»» Type|HSNAsic|
|»»» Type|RouterFpga|
|»»» Type|RouterBMC|
|»»» Type|HSNLink|
|»»» Type|HSNConnector|
|»»» Type|INVALID|
|»»» HWInventoryByFRUType|HWInvByFRUCabinet|
|»»» HWInventoryByFRUType|HWInvByFRUChassis|
|»»» HWInventoryByFRUType|HWInvByFRUComputeModule|
|»»» HWInventoryByFRUType|HWInvByFRURouterModule|
|»»» HWInventoryByFRUType|HWInvByFRUNodeEnclosure|
|»»» HWInventoryByFRUType|HWInvByFRUHSNBoard|
|»»» HWInventoryByFRUType|HWInvByFRUMgmtSwitch|
|»»» HWInventoryByFRUType|HWInvByFRUMgmtHLSwitch|
|»»» HWInventoryByFRUType|HWInvByFRUCDUMgmtSwitch|
|»»» HWInventoryByFRUType|HWInvByFRUNode|
|»»» HWInventoryByFRUType|HWInvByFRUProcessor|
|»»» HWInventoryByFRUType|HWInvByFRUNodeAccel|
|»»» HWInventoryByFRUType|HWInvByFRUNodeAccelRiser|
|»»» HWInventoryByFRUType|HWInvByFRUDrive|
|»»» HWInventoryByFRUType|HWInvByFRUMemory|
|»»» HWInventoryByFRUType|HWInvByFRUPDU|
|»»» HWInventoryByFRUType|HWInvByFRUOutlet|
|»»» HWInventoryByFRUType|HWInvByFRUCMMRectifier|
|»»» HWInventoryByFRUType|HWInvByFRUNodeEnclosurePowerSupply|
|»»» HWInventoryByFRUType|HWInvByFRUNodeBMC|
|»»» HWInventoryByFRUType|HWInvByFRURouterBMC|
|»»» HWInventoryByFRUType|HWIncByFRUHSNNIC|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dohwinvbylocationpost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries created or updated.  Message contains count of new/modified items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvByLocationDeleteAll

<a id="opIddoHWInvByLocationDeleteAll"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/Hardware HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/Hardware \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/Hardware', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/Hardware", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/Hardware`

*Delete all HWInventoryByLocation entries*

Delete all entries in the HWInventoryByLocation collection. Note that this does not delete any associated HWInventoryByFRU entries.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dohwinvbylocationdeleteall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) response code - one or more entries deleted. Message contains count of deleted items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Collection is empty|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvByLocationGet

<a id="opIddoHWInvByLocationGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/Hardware/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/Hardware/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/Hardware/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/Hardware/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/Hardware/{xname}`

*Retrieve HWInventoryByLocation entry at {xname}*

Retrieve HWInventoryByLocation entries for a specific xname.

<h3 id="dohwinvbylocationget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of hardware inventory record to return.|

> Example responses

> HWInventoryByLocation entry matching xname/ID

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "Ordinal": 0,
  "Status": "Populated",
  "HWInventoryByLocationType": "HWInvByLocNode",
  "NodeLocationInfo": {
    "Id": "System.Embedded.1",
    "Name": "Name describing system or where it is located, per manufacturing",
    "Description": "Description of system/node type, per manufacturing",
    "Hostname": "if_defined_in_Redfish",
    "ProcessorSummary": {
      "Count": 2,
      "Model": "Multi-Core Intel(R) Xeon(R) processor E5-16xx Series"
    },
    "MemorySummary": {
      "TotalSystemMemoryGiB": 64
    }
  },
  "PopulatedFRU": {
    "FRUID": "Dell-99999-1234.1234.2345",
    "Type": "Node",
    "Subtype": "River",
    "HWInventoryByFRUType": "HWInvByFRUNode",
    "NodeFRUInfo": {
      "AssetTag": "AdminAssignedAssetTag",
      "BiosVersion": "v1.0.2.9999",
      "Model": "OKS0P2354",
      "Manufacturer": "Dell",
      "PartNumber": "p99999",
      "SerialNumber": "1234.1234.2345",
      "SKU": "as213234",
      "SystemType": "Physical",
      "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
    }
  },
  "Processors": [
    {
      "ID": "x0c0s0b0n0p0",
      "Type": "Processor",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocProcessor",
      "ProcessorLocationInfo": {
        "Id": "CPU1",
        "Name": "Processor",
        "Description": "Socket 1 Processor",
        "Socket": "CPU 1"
      },
      "PopulatedFRU": {
        "FRUID": "HOW-TO-ID-CPUS-FROM-REDFISH-IF-AT-ALL",
        "Type": "Processor",
        "Subtype": "SKL24",
        "HWInventoryByFRUType": "HWInvByFRUProcessor",
        "ProcessorFRUInfo": {
          "InstructionSet": "x86-64",
          "Manufacturer": "Intel",
          "MaxSpeedMHz": 2600,
          "Model": "Intel(R) Xeon(R) CPU E5-2623 v4 @ 2.60GHz",
          "ProcessorArchitecture": "x86",
          "ProcessorId": {
            "EffectiveFamily": 6,
            "EffectiveModel": 79,
            "IdentificationRegisters": 263921,
            "MicrocodeInfo": 184549399,
            "Step": 1,
            "VendorID": "GenuineIntel"
          },
          "ProcessorType": "CPU",
          "TotalCores": 24,
          "TotalThreads": 48
        }
      }
    },
    {
      "ID": "x0c0s0b0n0p1",
      "Type": "Processor",
      "Ordinal": 1,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocProcessor",
      "ProcessorLocationInfo": {
        "Id": "CPU2",
        "Name": "Processor",
        "Description": "Socket 2 Processor",
        "Socket": "CPU 2"
      },
      "PopulatedFRU": {
        "FRUID": "HOW-TO-ID-CPUS-FROM-REDFISH-IF-AT-ALL",
        "Type": "Processor",
        "Subtype": "SKL24",
        "HWInventoryByFRUType": "HWInvByFRUProcessor",
        "ProcessorFRUInfo": {
          "InstructionSet": "x86-64",
          "Manufacturer": "Intel",
          "MaxSpeedMHz": 2600,
          "Model": "Intel(R) Xeon(R) CPU E5-2623 v4 @ 2.60GHz",
          "ProcessorArchitecture": "x86",
          "ProcessorId": {
            "EffectiveFamily": 6,
            "EffectiveModel": 79,
            "IdentificationRegisters": 263921,
            "MicrocodeInfo": 184549399,
            "Step": 1,
            "VendorID": "GenuineIntel"
          },
          "ProcessorType": "CPU",
          "TotalCores": 24,
          "TotalThreads": 48
        }
      }
    }
  ],
  "Memory": [
    {
      "ID": "x0c0s0b0n0d0",
      "Type": "Memory",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocMemory",
      "MemoryLocationInfo": {
        "Id": "DIMM1",
        "Name": "DIMM Slot 1",
        "MemoryLocation": {
          "Socket": 1,
          "MemoryController": 1,
          "Channel": 1,
          "Slot": 1
        }
      },
      "PopulatedFRU": {
        "FRUID": "MFR-PARTNUMBER-SERIALNUMBER",
        "Type": "Memory",
        "Subtype": "DIMM2400G32",
        "HWInventoryByFRUType": "HWInvByFRUMemory",
        "MemoryFRUInfo": {
          "BaseModuleType": "RDIMM",
          "BusWidthBits": 72,
          "CapacityMiB": 32768,
          "DataWidthBits": 64,
          "ErrorCorrection": "MultiBitECC",
          "Manufacturer": "Micron",
          "MemoryType": "DRAM",
          "MemoryDeviceType": "DDR4",
          "OperatingSpeedMhz": 2400,
          "PartNumber": "XYZ-123-1232",
          "RankCount": 2,
          "SerialNumber": "12344567689j"
        }
      }
    },
    {
      "ID": "x0c0s0b0n0d1",
      "Type": "Memory",
      "Ordinal": 1,
      "Status": "Empty",
      "HWInventoryByLocationType": "HWInvByLocMemory",
      "MemoryLocationInfo": {
        "Id": "DIMM2",
        "Name": "Socket 1 DIMM Slot 2",
        "MemoryLocation": {
          "Socket": 1,
          "MemoryController": 1,
          "Channel": 1,
          "Slot": 2
        }
      },
      "PopulatedFRU": null
    },
    {
      "ID": "x0c0s0b0n0d2",
      "Type": "Memory",
      "Ordinal": 2,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocMemory",
      "MemoryLocationInfo": {
        "Id": "DIMM3",
        "Name": "Socket 2 DIMM Slot 1",
        "MemoryLocation": {
          "Socket": 2,
          "MemoryController": 2,
          "Channel": 1,
          "Slot": 1
        }
      },
      "PopulatedFRU": {
        "FRUID": "MFR-PARTNUMBER-SERIALNUMBER_2",
        "Type": "Memory",
        "Subtype": "DIMM2400G32",
        "HWInventoryByFRUType": "HWInvByFRUMemory",
        "MemoryFRUInfo": {
          "BaseModuleType": "RDIMM",
          "BusWidthBits": 72,
          "CapacityMiB": 32768,
          "DataWidthBits": 64,
          "ErrorCorrection": "MultiBitECC",
          "Manufacturer": "Micron",
          "MemoryType": "DRAM",
          "MemoryDeviceType": "DDR4",
          "OperatingSpeedMhz": 2400,
          "PartNumber": "XYZ-123-1232",
          "RankCount": 2,
          "SerialNumber": "346456346346j"
        }
      }
    },
    {
      "ID": "x0c0s0b0n0d3",
      "Type": "Memory",
      "Ordinal": 3,
      "Status": "Empty",
      "HWInventoryByLocationType": "HWInvByLocMemory",
      "MemoryLocationInfo": {
        "Id": "DIMM3",
        "Name": "Socket 2 DIMM Slot 2",
        "MemoryLocation": {
          "Socket": 2,
          "MemoryController": 2,
          "Channel": 1,
          "Slot": 2
        }
      },
      "PopulatedFRU": null
    }
  ]
}
```

> 200 Response

```json
null
```

<h3 id="dohwinvbylocationget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|HWInventoryByLocation entry matching xname/ID|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvByLocationDelete

<a id="opIddoHWInvByLocationDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/Hardware/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/Hardware/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/Hardware/{xname}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/Hardware/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/Hardware/{xname}`

*DELETE HWInventoryByLocation entry with ID (location) {xname}*

Delete HWInventoryByLocation entry for a specific xname.

<h3 id="dohwinvbylocationdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of HWInventoryByLocation record to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dohwinvbylocationdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) code - entry is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|XName does Not Exist - no matching ID to delete|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-hwinventorybyfru">HWInventoryByFRU</h1>

This represents a physical piece of hardware with properties specific to a unique component in the system.  This information is constant regardless of where the hardware item is currently in the system (if it is in the system). If a HWInventoryByLocation entry is currently populated with a piece of hardware, it will have the corresponding HWInventoryByFRU object embedded. This FRU info can also be looked up by FRU ID regardless of the current location.

## doHWInvByFRUGetAll

<a id="opIddoHWInvByFRUGetAll"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/HardwareByFRU`

*Retrieve all HWInventoryByFRU entries in a flat array*

Retrieve all HWInventoryByFRU entries. Note that there is no organization of the data, the entries are presented as a flat array. For most purposes, you will want to use /Inventory/Hardware/Query unless you are interested in components that are not currently installed anywhere.

<h3 id="dohwinvbyfrugetall-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|fruid|query|string|false|Retrieve HWInventoryByFRU entries with the given FRU ID.|
|type|query|string|false|Filter the results based on HMS type like Node, NodeEnclosure, NodeBMC etc. Can be specified multiple times for selecting entries of multiple types.|
|manufacturer|query|string|false|Retrieve HWInventoryByFRU entries with the given Manufacturer.|
|partnumber|query|string|false|Retrieve HWInventoryByFRU entries with the given part number.|
|serialnumber|query|string|false|Retrieve HWInventoryByFRU entries with the given serial number.|

#### Enumerated Values

|Parameter|Value|
|---|---|
|type|CDU|
|type|CabinetCDU|
|type|CabinetPDU|
|type|CabinetPDUOutlet|
|type|CabinetPDUPowerConnector|
|type|CabinetPDUController|
|type|Cabinet|
|type|Chassis|
|type|ChassisBMC|
|type|CMMRectifier|
|type|CMMFpga|
|type|CEC|
|type|ComputeModule|
|type|RouterModule|
|type|NodeBMC|
|type|NodeEnclosure|
|type|NodeEnclosurePowerSupply|
|type|HSNBoard|
|type|MgmtSwitch|
|type|MgmtHLSwitch|
|type|CDUMgmtSwitch|
|type|Node|
|type|Processor|
|type|Drive|
|type|StorageGroup|
|type|NodeNIC|
|type|Memory|
|type|NodeAccel|
|type|NodeAccelRiser|
|type|NodeFpga|
|type|HSNAsic|
|type|RouterFpga|
|type|RouterBMC|
|type|HSNLink|
|type|HSNConnector|
|type|INVALID|

> Example responses

> 200 Response

```json
[
  {
    "FRUID": "Dell-99999-1234-1234-2345",
    "Type": "Node",
    "Subtype": "River",
    "HWInventoryByFRUType": "HWInvByFRUNode",
    "NodeFRUInfo": {
      "AssetTag": "AdminAssignedAssetTag",
      "BiosVersion": "v1.0.2.9999",
      "Model": "OKS0P2354",
      "Manufacturer": "Dell",
      "PartNumber": "y99999",
      "SerialNumber": "1234-1234-2345",
      "SKU": "as213234",
      "SystemType": "Physical",
      "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
    }
  }
]
```

<h3 id="dohwinvbyfrugetall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Flat, unsorted HWInventoryByFRU array.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dohwinvbyfrugetall-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)]|false|none|[This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).]|
|» FRUID|[FRUId.1.0.0](#schemafruid.1.0.0)|false|read-only|Uniquely identifies a piece of hardware by a serial-number like identifier that is globally unique within the hardware inventory,|
|» Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|read-only|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|» FRUSubtype|string|false|none|TBD.|
|» HWInventoryByFRUType|string|true|none|This is used as a discriminator to determine the additional HMS-type specific subtype that is returned.|

#### Enumerated Values

|Property|Value|
|---|---|
|Type|CDU|
|Type|CabinetCDU|
|Type|CabinetPDU|
|Type|CabinetPDUOutlet|
|Type|CabinetPDUPowerConnector|
|Type|CabinetPDUController|
|Type|Cabinet|
|Type|Chassis|
|Type|ChassisBMC|
|Type|CMMRectifier|
|Type|CMMFpga|
|Type|CEC|
|Type|ComputeModule|
|Type|RouterModule|
|Type|NodeBMC|
|Type|NodeEnclosure|
|Type|NodeEnclosurePowerSupply|
|Type|HSNBoard|
|Type|MgmtSwitch|
|Type|MgmtHLSwitch|
|Type|CDUMgmtSwitch|
|Type|Node|
|Type|Processor|
|Type|Drive|
|Type|StorageGroup|
|Type|NodeNIC|
|Type|Memory|
|Type|NodeAccel|
|Type|NodeAccelRiser|
|Type|NodeFpga|
|Type|HSNAsic|
|Type|RouterFpga|
|Type|RouterBMC|
|Type|HSNLink|
|Type|HSNConnector|
|Type|INVALID|
|HWInventoryByFRUType|HWInvByFRUCabinet|
|HWInventoryByFRUType|HWInvByFRUChassis|
|HWInventoryByFRUType|HWInvByFRUComputeModule|
|HWInventoryByFRUType|HWInvByFRURouterModule|
|HWInventoryByFRUType|HWInvByFRUNodeEnclosure|
|HWInventoryByFRUType|HWInvByFRUHSNBoard|
|HWInventoryByFRUType|HWInvByFRUMgmtSwitch|
|HWInventoryByFRUType|HWInvByFRUMgmtHLSwitch|
|HWInventoryByFRUType|HWInvByFRUCDUMgmtSwitch|
|HWInventoryByFRUType|HWInvByFRUNode|
|HWInventoryByFRUType|HWInvByFRUProcessor|
|HWInventoryByFRUType|HWInvByFRUNodeAccel|
|HWInventoryByFRUType|HWInvByFRUNodeAccelRiser|
|HWInventoryByFRUType|HWInvByFRUDrive|
|HWInventoryByFRUType|HWInvByFRUMemory|
|HWInventoryByFRUType|HWInvByFRUPDU|
|HWInventoryByFRUType|HWInvByFRUOutlet|
|HWInventoryByFRUType|HWInvByFRUCMMRectifier|
|HWInventoryByFRUType|HWInvByFRUNodeEnclosurePowerSupply|
|HWInventoryByFRUType|HWInvByFRUNodeBMC|
|HWInventoryByFRUType|HWInvByFRURouterBMC|
|HWInventoryByFRUType|HWIncByFRUHSNNIC|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvByFRUDeleteAll

<a id="opIddoHWInvByFRUDeleteAll"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/HardwareByFRU`

*Delete all HWInventoryByFRU entries*

Delete all entries in the HWInventoryByFRU collection. Note that this does not delete any associated HWInventoryByLocation entries. Also, if any items are associated with a HWInventoryByLocation, the deletion will fail.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dohwinvbyfrudeleteall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) response code - one or more entries deleted. Message contains count of deleted items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Collection is empty|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvByFRUGet

<a id="opIddoHWInvByFRUGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/{fruid} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/{fruid} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/{fruid}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/{fruid}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/HardwareByFRU/{fruid}`

*Retrieve HWInventoryByFRU for {fruid}*

Retrieve HWInventoryByFRU for a specific fruID.

<h3 id="dohwinvbyfruget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|fruid|path|string|true|Global HMS field-replaceable (FRU) identifier (serial number, etc.) of the hardware component to select.|

> Example responses

> 200 Response

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  }
}
```

<h3 id="dohwinvbyfruget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|HWInventoryByFRU entry matching fruid|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvByFRUDelete

<a id="opIddoHWInvByFRUDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/{fruid} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/{fruid} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/{fruid}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/{fruid}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/HardwareByFRU/{fruid}`

*Delete HWInventoryByFRU entry with FRU identifier {fruid}*

Delete an entry in the HWInventoryByFRU collection. Note that this does not delete the associated HWInventoryByLocation entry if the FRU is currently residing in the system. In fact, if the FRU ID is associated with a HWInventoryByLocation currently, the deletion will fail.

<h3 id="dohwinvbyfrudelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|fruid|path|string|true|Locational xname of HWInventoryByFRU record to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dohwinvbyfrudelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) code - entry is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|FRU ID does Not Exist - no matching entry to delete|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-hwinventoryhistory">HWInventoryHistory</h1>

Hardware inventory historical information for the given system location/xname/FRU

## doHWInvHistByLocationsGet

<a id="opIddoHWInvHistByLocationsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/Hardware/History HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/Hardware/History \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/Hardware/History', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/Hardware/History", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/Hardware/History`

*Retrieve the history entries for all HWInventoryByLocation entries*

Retrieve the history entries for all HWInventoryByLocation entries.

<h3 id="dohwinvhistbylocationsget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|query|string|false|Filter the results based on xname ID(s). Can be specified multiple times for selecting entries with multiple specific xnames.|
|eventtype|query|string|false|Retrieve the history entries of a specific type (Added, Removed, etc) for HWInventoryByLocation entries.|
|starttime|query|string|false|Retrieve the history entries from after the requested history window start time for HWInventoryByLocation entries. This takes an RFC3339 formatted string (2006-01-02T15:04:05Z07:00).|
|endtime|query|string|false|Retrieve the history entries from before the requested history window end time for HWInventoryByLocation entries. This takes an RFC3339 formatted string (2006-01-02T15:04:05Z07:00).|

> Example responses

> 200 Response

```json
{
  "Components": [
    {
      "ID": "string",
      "History": [
        {
          "ID": "x0c0s0b0n0",
          "FRUID": "string",
          "Timestamp": "2018-08-09 03:55:57.000000",
          "EventType": "Added"
        }
      ]
    }
  ]
}
```

<h3 id="dohwinvhistbylocationsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of history entries sorted by xname.|[HWInventory.1.0.0_HWInventoryHistoryCollection](#schemahwinventory.1.0.0_hwinventoryhistorycollection)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvHistByLocationDeleteAll

<a id="opIddoHWInvHistByLocationDeleteAll"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/Hardware/History HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/Hardware/History \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/Hardware/History', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/Hardware/History", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/Hardware/History`

*Clear the HWInventory history.*

Delete all HWInventory history entries. Note that this also deletes history for any associated HWInventoryByFRU entries.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dohwinvhistbylocationdeleteall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) response code - one or more entries deleted. Message contains count of deleted items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Collection is empty|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvHistByLocationGet

<a id="opIddoHWInvHistByLocationGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/Hardware/History/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/Hardware/History/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/Hardware/History/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/Hardware/History/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/Hardware/History/{xname}`

*Retrieve the history entries for the HWInventoryByLocation entry at {xname}*

Retrieve the history entries for a HWInventoryByLocation entry with a specific xname.

<h3 id="dohwinvhistbylocationget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of hardware inventory record to return history for.|
|eventtype|query|string|false|Retrieve the history entries of a specific type (Added, Removed, etc) for a HWInventoryByLocation entry.|
|starttime|query|string|false|Retrieve the history entries from after the requested history window start time for a HWInventoryByLocation entry. This takes an RFC3339 formatted string (2006-01-02T15:04:05Z07:00).|
|endtime|query|string|false|Retrieve the history entries from before the requested history window end time for a HWInventoryByLocation entry. This takes an RFC3339 formatted string (2006-01-02T15:04:05Z07:00).|

> Example responses

> 200 Response

```json
{
  "ID": "string",
  "History": [
    {
      "ID": "x0c0s0b0n0",
      "FRUID": "string",
      "Timestamp": "2018-08-09 03:55:57.000000",
      "EventType": "Added"
    }
  ]
}
```

<h3 id="dohwinvhistbylocationget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|History entries for the HWInventoryByLocation entry matching xname/ID|[HWInventory.1.0.0_HWInventoryHistoryArray](#schemahwinventory.1.0.0_hwinventoryhistoryarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvHistByLocationDelete

<a id="opIddoHWInvHistByLocationDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/Hardware/History/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/Hardware/History/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/Hardware/History/{xname}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/Hardware/History/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/Hardware/History/{xname}`

*DELETE history for the HWInventoryByLocation entry with ID (location) {xname}*

Delete history for the HWInventoryByLocation entry for a specific xname.

<h3 id="dohwinvhistbylocationdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of HWInventoryByLocation record to delete history for.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dohwinvhistbylocationdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) code - entry is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|XName does Not Exist - no matching ID to delete|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvHistByFRUsGet

<a id="opIddoHWInvHistByFRUsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/HardwareByFRU/History`

*Retrieve the history entries for all HWInventoryByFRU entries.*

Retrieve the history entries for all HWInventoryByFRU entries. Sorted by FRU.

<h3 id="dohwinvhistbyfrusget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|fruid|query|string|false|Retrieve the history entries for HWInventoryByFRU entries with the given FRU ID.|
|eventtype|query|string|false|Retrieve the history entries of a specific type (Added, Removed, etc) for HWInventoryByFRU entries.|
|starttime|query|string|false|Retrieve the history entries from after the requested history window start time for HWInventoryByFRU entries. This takes an RFC3339 formatted string (2006-01-02T15:04:05Z07:00).|
|endtime|query|string|false|Retrieve the history entries from before the requested history window end time for HWInventoryByFRU entries. This takes an RFC3339 formatted string (2006-01-02T15:04:05Z07:00).|

> Example responses

> 200 Response

```json
{
  "Components": [
    {
      "ID": "string",
      "History": [
        {
          "ID": "x0c0s0b0n0",
          "FRUID": "string",
          "Timestamp": "2018-08-09 03:55:57.000000",
          "EventType": "Added"
        }
      ]
    }
  ]
}
```

<h3 id="dohwinvhistbyfrusget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array of history entries sorted by FRU.|[HWInventory.1.0.0_HWInventoryHistoryCollection](#schemahwinventory.1.0.0_hwinventoryhistorycollection)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvHistByFRUGet

<a id="opIddoHWInvHistByFRUGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History/{fruid} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History/{fruid} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History/{fruid}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History/{fruid}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/HardwareByFRU/History/{fruid}`

*Retrieve the history entries for the HWInventoryByFRU for {fruid}*

Retrieve the history entries for the HWInventoryByFRU for a specific fruID.

<h3 id="dohwinvhistbyfruget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|fruid|path|string|true|Global HMS field-replaceable (FRU) identifier (serial number, etc.) of the hardware component to select.|
|eventtype|query|string|false|Retrieve the history entries of a specific type (Added, Removed, etc) for a HWInventoryByFRU entry.|
|starttime|query|string|false|Retrieve the history entries from after the requested history window start time for a HWInventoryByFRU entry. This takes an RFC3339 formatted string (2006-01-02T15:04:05Z07:00).|
|endtime|query|string|false|Retrieve the history entries from before the requested history window end time for a HWInventoryByFRU entry. This takes an RFC3339 formatted string (2006-01-02T15:04:05Z07:00).|

> Example responses

> 200 Response

```json
{
  "ID": "string",
  "History": [
    {
      "ID": "x0c0s0b0n0",
      "FRUID": "string",
      "Timestamp": "2018-08-09 03:55:57.000000",
      "EventType": "Added"
    }
  ]
}
```

<h3 id="dohwinvhistbyfruget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|History entries for the HWInventoryByFRU entry matching fruid|[HWInventory.1.0.0_HWInventoryHistoryArray](#schemahwinventory.1.0.0_hwinventoryhistoryarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doHWInvHistByFRUDelete

<a id="opIddoHWInvHistByFRUDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History/{fruid} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History/{fruid} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History/{fruid}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/HardwareByFRU/History/{fruid}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/HardwareByFRU/History/{fruid}`

*Delete history for the HWInventoryByFRU entry with FRU identifier {fruid}*

Delete history for an entry in the HWInventoryByFRU collection.

<h3 id="dohwinvhistbyfrudelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|fruid|path|string|true|Locational xname of HWInventoryByFRU record to delete history for.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dohwinvhistbyfrudelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) code - entry is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|FRU ID does Not Exist - no matching entry to delete|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-redfishendpoint">RedfishEndpoint</h1>

This is a BMC or other Redfish controller that has a Redfish entry point and Redfish service root.  It is used to discover the components managed by this endpoint during discovery and handles all Redfish interactions by these subcomponents.  If the endpoint has been discovered, this entry will include the ComponentEndpoint entries for these managed subcomponents.

## doRedfishEndpointsGet

<a id="opIddoRedfishEndpointsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/RedfishEndpoints`

*Retrieve all RedfishEndpoints, returning RedfishEndpointArray*

Retrieve all Redfish endpoint entries as a named array, optionally filtering it.

<h3 id="doredfishendpointsget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|query|string|false|Filter the results based on xname ID(s). Can be specified multiple times for selecting entries with multiple specific xnames.|
|fqdn|query|string|false|Retrieve RedfishEndpoint with the given FQDN|
|type|query|string|false|Filter the results based on HMS type like Node, NodeEnclosure, NodeBMC etc. Can be specified multiple times for selecting entries of multiple types.|
|uuid|query|string|false|Retrieve the RedfishEndpoint with the given UUID.|
|macaddr|query|string|false|Retrieve the RedfishEndpoint with the given MAC address.|
|ipaddress|query|string|false|Retrieve the RedfishEndpoint with the given IP address. A blank string will get Redfish endpoints without IP addresses.|
|laststatus|query|string|false|Retrieve the RedfishEndpoints with the given discovery status. This can be negated (i.e. !DiscoverOK). Valid values are: EndpointInvalid, EPResponseFailedDecode, HTTPsGetFailed, NotYetQueried, VerificationFailed, ChildVerificationFailed, DiscoverOK|

#### Enumerated Values

|Parameter|Value|
|---|---|
|type|CDU|
|type|CabinetCDU|
|type|CabinetPDU|
|type|CabinetPDUOutlet|
|type|CabinetPDUPowerConnector|
|type|CabinetPDUController|
|type|Cabinet|
|type|Chassis|
|type|ChassisBMC|
|type|CMMRectifier|
|type|CMMFpga|
|type|CEC|
|type|ComputeModule|
|type|RouterModule|
|type|NodeBMC|
|type|NodeEnclosure|
|type|NodeEnclosurePowerSupply|
|type|HSNBoard|
|type|MgmtSwitch|
|type|MgmtHLSwitch|
|type|CDUMgmtSwitch|
|type|Node|
|type|Processor|
|type|Drive|
|type|StorageGroup|
|type|NodeNIC|
|type|Memory|
|type|NodeAccel|
|type|NodeAccelRiser|
|type|NodeFpga|
|type|HSNAsic|
|type|RouterFpga|
|type|RouterBMC|
|type|HSNLink|
|type|HSNConnector|
|type|INVALID|

> Example responses

> 200 Response

```json
{
  "RedfishEndpoints": [
    {
      "ID": "x0c0s0b0",
      "Type": "Node",
      "Name": "string",
      "Hostname": "string",
      "Domain": "string",
      "FQDN": "string",
      "Enabled": true,
      "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
      "User": "string",
      "Password": "string",
      "UseSSDP": true,
      "MacRequired": true,
      "MACAddr": "ae:12:e2:ff:89:9d",
      "IPAddress": "10.254.2.10",
      "RediscoverOnUpdate": true,
      "TemplateID": "string",
      "DiscoveryInfo": {
        "LastAttempt": "2019-08-24T14:15:22Z",
        "LastStatus": "EndpointInvalid",
        "RedfishVersion": "string"
      }
    }
  ]
}
```

<h3 id="doredfishendpointsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Named RedfishEndpoints array representing all current RF endpoints.|[RedfishEndpointArray_RedfishEndpointArray](#schemaredfishendpointarray_redfishendpointarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doRedfishEndpointsPost

<a id="opIddoRedfishEndpointsPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /Inventory/RedfishEndpoints`

*Create RedfishEndpoint(s)*

Create a new RedfishEndpoint whose ID field is a valid xname. ID can be given explicitly, or if the Hostname or hostname portion of the FQDN is given, and is a valid xname, this will be used for the ID instead.  The Hostname/Domain can be given as separate fields and will be used to create a FQDN if one is not given. The reverse is also true.  If FQDN is an IP address it will be treated as a hostname with a blank domain.  The domain field is used currently to assign the domain for discovered nodes automatically.

If ID is given and is a valid XName, the hostname/domain/FQDN does not need to have an XName as the hostname portion. It can be any address.
The ID and FQDN must be unique across all entries.

> Body parameter

```json
{
  "ID": "x0c0s0b0",
  "Name": "string",
  "Hostname": "string",
  "Domain": "string",
  "FQDN": "string",
  "Enabled": true,
  "User": "string",
  "Password": "string",
  "UseSSDP": true,
  "MacRequired": true,
  "MACAddr": "ae:12:e2:ff:89:9d",
  "IPAddress": "10.254.2.10",
  "RediscoverOnUpdate": true,
  "TemplateID": "string"
}
```

<h3 id="doredfishendpointspost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[RedfishEndpoint.1.0.0_RedfishEndpoint](#schemaredfishendpoint.1.0.0_redfishendpoint)|true|none|

> Example responses

> Success, returns array of created resource URIs

```json
[
  {
    "URI": "/hsm/v2/Inventory/RedfishEndpoints/x0c0s0b0"
  }
]
```

> 201 Response

```json
[
  {
    "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
  }
]
```

<h3 id="doredfishendpointspost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Success, returns array of created resource URIs|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. Duplicate resource would be created.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="doredfishendpointspost-responseschema">Response Schema</h3>

Status Code **201**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|none|[A ResourceURI is like an odata.id, it provides a path to a resource from the API root, such that when a GET is performed, the corresponding object is returned.  It does not imply other odata functionality.]|
|» ResourceURI|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## doRedfishEndpointsDeleteAll

<a id="opIddoRedfishEndpointsDeleteAll"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/RedfishEndpoints`

*Delete all RedfishEndpoints*

Delete all entries in the RedfishEndpoint collection.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="doredfishendpointsdeleteall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries deleted. Message contains count of deleted items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Collection is empty|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doRedfishEndpointGet

<a id="opIddoRedfishEndpointGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/RedfishEndpoints/{xname}`

*Retrieve RedfishEndpoint at {xname}*

Retrieve RedfishEndpoint, located at physical location {xname}.

<h3 id="doredfishendpointget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of RedfishEndpoint record to return.|

> Example responses

> 200 Response

```json
{
  "ID": "x0c0s0b0",
  "Type": "Node",
  "Name": "string",
  "Hostname": "string",
  "Domain": "string",
  "FQDN": "string",
  "Enabled": true,
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "User": "string",
  "Password": "string",
  "UseSSDP": true,
  "MacRequired": true,
  "MACAddr": "ae:12:e2:ff:89:9d",
  "IPAddress": "10.254.2.10",
  "RediscoverOnUpdate": true,
  "TemplateID": "string",
  "DiscoveryInfo": {
    "LastAttempt": "2019-08-24T14:15:22Z",
    "LastStatus": "EndpointInvalid",
    "RedfishVersion": "string"
  }
}
```

<h3 id="doredfishendpointget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|RedfishEndpoint entry matching xname/ID|[RedfishEndpoint.1.0.0_RedfishEndpoint](#schemaredfishendpoint.1.0.0_redfishendpoint)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doRedfishEndpointDelete

<a id="opIddoRedfishEndpointDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/RedfishEndpoints/{xname}`

*Delete RedfishEndpoint with ID {xname}*

Delete RedfishEndpoint record for a specific xname.

<h3 id="doredfishendpointdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of RedfishEndpoint record to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="doredfishendpointdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - component is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|XName does Not Exist - no matching ID to delete|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doRedfishEndpointPut

<a id="opIddoRedfishEndpointPut"></a>

> Code samples

```http
PUT https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname}', headers = headers)

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
    req, err := http.NewRequest("PUT", "https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /Inventory/RedfishEndpoints/{xname}`

*Update definition for RedfishEndpoint ID {xname}*

Create or update RedfishEndpoint record for a specific xname.

> Body parameter

```json
{
  "ID": "x0c0s0b0",
  "Name": "string",
  "Hostname": "string",
  "Domain": "string",
  "FQDN": "string",
  "Enabled": true,
  "User": "string",
  "Password": "string",
  "UseSSDP": true,
  "MacRequired": true,
  "MACAddr": "ae:12:e2:ff:89:9d",
  "IPAddress": "10.254.2.10",
  "RediscoverOnUpdate": true,
  "TemplateID": "string"
}
```

<h3 id="doredfishendpointput-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of RedfishEndpoint record to create or update.|
|body|body|[RedfishEndpoint.1.0.0_RedfishEndpoint](#schemaredfishendpoint.1.0.0_redfishendpoint)|true|none|

> Example responses

> 200 Response

```json
{
  "ID": "x0c0s0b0",
  "Type": "Node",
  "Name": "string",
  "Hostname": "string",
  "Domain": "string",
  "FQDN": "string",
  "Enabled": true,
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "User": "string",
  "Password": "string",
  "UseSSDP": true,
  "MacRequired": true,
  "MACAddr": "ae:12:e2:ff:89:9d",
  "IPAddress": "10.254.2.10",
  "RediscoverOnUpdate": true,
  "TemplateID": "string",
  "DiscoveryInfo": {
    "LastAttempt": "2019-08-24T14:15:22Z",
    "LastStatus": "EndpointInvalid",
    "RedfishVersion": "string"
  }
}
```

<h3 id="doredfishendpointput-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success, return updated RedfishEndpoint resource|[RedfishEndpoint.1.0.0_RedfishEndpoint](#schemaredfishendpoint.1.0.0_redfishendpoint)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|XName does Not Exist - no matching ID to update|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doRedfishEndpointPatch

<a id="opIddoRedfishEndpointPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname}', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /Inventory/RedfishEndpoints/{xname}`

*Update (PATCH) definition for RedfishEndpoint ID {xname}*

Update (PATCH) RedfishEndpoint record for a specific xname.

> Body parameter

```json
{
  "ID": "x0c0s0b0",
  "Name": "string",
  "Hostname": "string",
  "Domain": "string",
  "FQDN": "string",
  "Enabled": true,
  "User": "string",
  "Password": "string",
  "UseSSDP": true,
  "MacRequired": true,
  "MACAddr": "ae:12:e2:ff:89:9d",
  "IPAddress": "10.254.2.10",
  "RediscoverOnUpdate": true,
  "TemplateID": "string"
}
```

<h3 id="doredfishendpointpatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of RedfishEndpoint record to create or update.|
|body|body|[RedfishEndpoint.1.0.0_RedfishEndpoint](#schemaredfishendpoint.1.0.0_redfishendpoint)|true|none|

> Example responses

> 200 Response

```json
{
  "ID": "x0c0s0b0",
  "Type": "Node",
  "Name": "string",
  "Hostname": "string",
  "Domain": "string",
  "FQDN": "string",
  "Enabled": true,
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "User": "string",
  "Password": "string",
  "UseSSDP": true,
  "MacRequired": true,
  "MACAddr": "ae:12:e2:ff:89:9d",
  "IPAddress": "10.254.2.10",
  "RediscoverOnUpdate": true,
  "TemplateID": "string",
  "DiscoveryInfo": {
    "LastAttempt": "2019-08-24T14:15:22Z",
    "LastStatus": "EndpointInvalid",
    "RedfishVersion": "string"
  }
}
```

<h3 id="doredfishendpointpatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success, return updated RedfishEndpoint resource|[RedfishEndpoint.1.0.0_RedfishEndpoint](#schemaredfishendpoint.1.0.0_redfishendpoint)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|XName does Not Exist - no matching ID to update|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doRedfishEndpointQueryGet

<a id="opIddoRedfishEndpointQueryGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/Query/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/Query/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/Query/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/RedfishEndpoints/Query/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/RedfishEndpoints/Query/{xname}`

*Retrieve RedfishEndpoint query for {xname}, returning RedfishEndpointArray*

Given xname and modifiers in query string, retrieve zero or more RedfishEndpoint entries in the form of a RedfishEndpointArray.

<h3 id="doredfishendpointqueryget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of RedfishEndpoint to query.|

> Example responses

> 200 Response

```json
{
  "RedfishEndpoints": [
    {
      "ID": "x0c0s0b0",
      "Type": "Node",
      "Name": "string",
      "Hostname": "string",
      "Domain": "string",
      "FQDN": "string",
      "Enabled": true,
      "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
      "User": "string",
      "Password": "string",
      "UseSSDP": true,
      "MacRequired": true,
      "MACAddr": "ae:12:e2:ff:89:9d",
      "IPAddress": "10.254.2.10",
      "RediscoverOnUpdate": true,
      "TemplateID": "string",
      "DiscoveryInfo": {
        "LastAttempt": "2019-08-24T14:15:22Z",
        "LastStatus": "EndpointInvalid",
        "RedfishVersion": "string"
      }
    }
  ]
}
```

<h3 id="doredfishendpointqueryget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|RedfishEndpointArray representing results of query.|[RedfishEndpointArray_RedfishEndpointArray](#schemaredfishendpointarray_redfishendpointarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - no matches|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-componentendpoint">ComponentEndpoint</h1>

The Redfish-discovered properties for a component discovered through, and managed by a RedfishEndpoint, such as a node, blade, and so on. These are obtainable via a discovered RedfishEndpoint or can be looked up by their xnames separately so that just the information for a particular component, e.g. node can be retrieved.  They can also provide a back-reference to the parent endpoint.

## doComponentEndpointsGet

<a id="opIddoComponentEndpointsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/ComponentEndpoints`

*Retrieve ComponentEndpoints Collection*

Retrieve the full collection of ComponentEndpoints in the form of a ComponentEndpointArray. Full results can also be filtered by query parameters. Only the first filter parameter of each type is used and the parameters are applied in an AND fashion. If the collection is empty or the filters have no match, an empty array is returned.

<h3 id="docomponentendpointsget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|query|string|false|Filter the results based on xname ID(s). Can be specified multiple times for selecting entries with multiple specific xnames.|
|redfish_ep|query|string|false|Retrieve all ComponentEndpoints managed by the parent Redfish EP.|
|type|query|string|false|Filter the results based on HMS type like Node, NodeEnclosure, NodeBMC etc. Can be specified multiple times for selecting entries of multiple types.|
|redfish_type|query|string|false|Retrieve all ComponentEndpoints with the given Redfish type.|

#### Enumerated Values

|Parameter|Value|
|---|---|
|type|CDU|
|type|CabinetCDU|
|type|CabinetPDU|
|type|CabinetPDUOutlet|
|type|CabinetPDUPowerConnector|
|type|CabinetPDUController|
|type|Cabinet|
|type|Chassis|
|type|ChassisBMC|
|type|CMMRectifier|
|type|CMMFpga|
|type|CEC|
|type|ComputeModule|
|type|RouterModule|
|type|NodeBMC|
|type|NodeEnclosure|
|type|NodeEnclosurePowerSupply|
|type|HSNBoard|
|type|MgmtSwitch|
|type|MgmtHLSwitch|
|type|CDUMgmtSwitch|
|type|Node|
|type|Processor|
|type|Drive|
|type|StorageGroup|
|type|NodeNIC|
|type|Memory|
|type|NodeAccel|
|type|NodeAccelRiser|
|type|NodeFpga|
|type|HSNAsic|
|type|RouterFpga|
|type|RouterBMC|
|type|HSNLink|
|type|HSNConnector|
|type|INVALID|

> Example responses

> ComponentEndpointArray representing the ComponentEndpoint collection or a filtered subset thereof.

```json
{
  "ComponentEndpoints": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "Domain": "mgmt.example.domain.com",
      "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
      "RedfishType": "ComputerSystem",
      "RedfishSubtype": "Physical",
      "ComponentEndpointType": "ComponentEndpointComputerSystem",
      "MACAddr": "d0:94:66:00:aa:37",
      "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
      "OdataID": "/redfish/v1/Systems/System.Embedded.1",
      "RedfishEndpointID": "x0c0s0b0",
      "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
      "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1",
      "RedfishSystemInfo": {
        "Name": "System Embedded 1",
        "Actions": {
          "#ComputerSystem.Reset": {
            "AllowableValues": [
              "On",
              "ForceOff"
            ],
            "target": "/redfish/v1/Systems/System.Embedded.1/Actions/ComputerSystem.Reset"
          }
        },
        "EthernetNICInfo": [
          {
            "RedfishId": "1",
            "@odata.id": "/redfish/v1/Systems/System.Embedded.1/EthernetInterfaces/1",
            "Description": "Management Network Interface",
            "InterfaceEnabled": true,
            "MACAddress": "d0:94:66:00:aa:37,",
            "PermanentMACAddress": "d0:94:66:00:aa:37"
          },
          {
            "RedfishId": "2",
            "@odata.id": "/redfish/v1/Systems/System.Embedded.1/EthernetInterfaces/2",
            "Description": "Management Network Interface",
            "InterfaceEnabled": true,
            "MACAddress": "d0:94:66:00:aa:38",
            "PermanentMACAddress": "d0:94:66:00:aa:38"
          }
        ]
      }
    }
  ]
}
```

> 200 Response

```json
{
  "ComponentEndpoints": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "Domain": "mgmt.example.domain.com",
      "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
      "RedfishType": "ComputerSystem",
      "RedfishSubtype": "Physical",
      "Enabled": true,
      "ComponentEndpointType": "ComponentEndpointComputerSystem",
      "MACAddr": "ae:12:ce:7a:aa:99",
      "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
      "OdataID": "/redfish/v1/Systems/System.Embedded.1",
      "RedfishEndpointID": "x0c0s0b0",
      "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
      "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1"
    }
  ]
}
```

<h3 id="docomponentendpointsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ComponentEndpointArray representing the ComponentEndpoint collection or a filtered subset thereof.|[ComponentEndpointArray_ComponentEndpointArray](#schemacomponentendpointarray_componentendpointarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentEndpointsDeleteAll

<a id="opIddoComponentEndpointsDeleteAll"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/ComponentEndpoints`

*Delete all ComponentEndpoints*

Delete all entries in the ComponentEndpoint collection.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="docomponentendpointsdeleteall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries deleted. Message contains count of deleted items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Collection is empty|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentEndpointGet

<a id="opIddoComponentEndpointGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/ComponentEndpoints/{xname}`

*Retrieve ComponentEndpoint at {xname}*

Retrieve ComponentEndpoint record for a specific xname.

<h3 id="docomponentendpointget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of ComponentEndpoint record to return.|

> Example responses

> HWInventoryByLocation entry matching xname/ID

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "Domain": "mgmt.example.domain.com",
  "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
  "RedfishType": "ComputerSystem",
  "RedfishSubtype": "Physical",
  "ComponentEndpointType": "ComponentEndpointComputerSystem",
  "MACAddr": "d0:94:66:00:aa:37",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/Systems/System.Embedded.1",
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
  "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1",
  "RedfishSystemInfo": {
    "Name": "System Embedded 1",
    "Actions": {
      "#ComputerSystem.Reset": {
        "AllowableValues": [
          "On",
          "ForceOff"
        ],
        "target": "/redfish/v1/Systems/System.Embedded.1/Actions/ComputerSystem.Reset"
      }
    },
    "EthernetNICInfo": [
      {
        "RedfishId": "1",
        "@odata.id": "/redfish/v1/Systems/System.Embedded.1/EthernetInterfaces/1",
        "Description": "Management Network Interface",
        "InterfaceEnabled": true,
        "MACAddress": "d0:94:66:00:aa:37",
        "PermanentMACAddress": "d0:94:66:00:aa:37"
      },
      {
        "RedfishId": "2",
        "@odata.id": "/redfish/v1/Systems/System.Embedded.1/EthernetInterfaces/2",
        "Description": "Management Network Interface",
        "InterfaceEnabled": true,
        "MACAddress": "ae:12:ce:7a:aa:99",
        "PermanentMACAddress": "ae:12:ce:7a:aa:99"
      }
    ]
  }
}
```

> 200 Response

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "Domain": "mgmt.example.domain.com",
  "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
  "RedfishType": "ComputerSystem",
  "RedfishSubtype": "Physical",
  "Enabled": true,
  "ComponentEndpointType": "ComponentEndpointComputerSystem",
  "MACAddr": "ae:12:ce:7a:aa:99",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/Systems/System.Embedded.1",
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
  "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1"
}
```

<h3 id="docomponentendpointget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|HWInventoryByLocation entry matching xname/ID|[ComponentEndpoint.1.0.0_ComponentEndpoint](#schemacomponentendpoint.1.0.0_componentendpoint)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doComponentEndpointDelete

<a id="opIddoComponentEndpointDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints/{xname}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/ComponentEndpoints/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/ComponentEndpoints/{xname}`

*Delete ComponentEndpoint with ID {xname}*

Delete ComponentEndpoint for a specific xname.

<h3 id="docomponentendpointdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of ComponentEndpoint record to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="docomponentendpointdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - ComponentEndpoint is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|XName does Not Exist - no matching ID to delete|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-serviceendpoint">ServiceEndpoint</h1>

The Redfish-discovered properties for a service discovered through, and managed by a RedfishEndpoint, such as UpdateService, EventService, and so on.  These are obtainable via a discovered RedfishEndpoint or can be looked up by their service type and xnames separately so that just the information for a particular service, e.g. UpdateService can be retrieved. They can also provide a back-reference to the parent endpoint.

## doServiceEndpointsGetAll

<a id="opIddoServiceEndpointsGetAll"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/ServiceEndpoints`

*Retrieve ServiceEndpoints Collection*

Retrieve the full collection of ServiceEndpoints in the form of a ServiceEndpointArray. Full results can also be filtered by query parameters.  Only the first filter parameter of each type is used and the parameters are applied in an AND fashion. If the collection is empty or the filters have no match, an empty array is returned.

<h3 id="doserviceendpointsgetall-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|redfish_ep|query|string|false|Retrieve all ServiceEndpoints managed by the parent Redfish EP. Can be repeated to select groups of endpoints.|
|service|query|string|false|Retrieve all ServiceEndpoints of the given Redfish service.|

> Example responses

> ServiceEndpointArray representing the ServiceEndpoint collection or a filtered subset thereof.

```json
{
  "ServiceEndpoints": {
    "RedfishEndpointID": "x0c0s0b0",
    "RedfishType": "UpdateService",
    "RedfishSubtype": "Other",
    "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
    "OdataID": "/redfish/v1/UpdateService",
    "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
    "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/UpdateService",
    "ServiceInfo": {
      "@odata.context": "/redfish/v1/$metadata#UpdateService.UpdateService",
      "@odata.id": "/redfish/v1/UpdateService",
      "@odata.type": "#UpdateService.v1_1_0.UpdateService",
      "ID": "UpdateService",
      "Name": "Update Service",
      "Actions": {
        "#UpdateService.SimpleUpdate": {
          "target": "/redfish/v1/Systems/System.Embedded.1/Actions/ComputerSystem.Reset",
          "title": ""
        }
      },
      "FirmwareInventory": {
        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory"
      },
      "SoftwareInventory": {
        "@odata.id": "/redfish/v1/UpdateService/SoftwareInventory"
      },
      "ServiceEnabled": "True"
    }
  }
}
```

> 200 Response

```json
{
  "ServiceEndpoints": [
    {
      "RedfishEndpointID": "x0c0s0b0",
      "RedfishType": "ComputerSystem",
      "RedfishSubtype": "Physical",
      "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
      "OdataID": "/redfish/v1/Systems/System.Embedded.1",
      "RedfishEndpointFQDN": "string",
      "RedfishURL": "string",
      "ServiceInfo": {
        "Name": "string"
      }
    }
  ]
}
```

<h3 id="doserviceendpointsgetall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ServiceEndpointArray representing the ServiceEndpoint collection or a filtered subset thereof.|[ServiceEndpointArray_ServiceEndpointArray](#schemaserviceendpointarray_serviceendpointarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doServiceEndpointsDeleteAll

<a id="opIddoServiceEndpointsDeleteAll"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/ServiceEndpoints`

*Delete all ServiceEndpoints*

Delete all entries in the ServiceEndpoint collection.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="doserviceendpointsdeleteall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries deleted. Message contains count of deleted items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Collection is empty|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doServiceEndpointsGet

<a id="opIddoServiceEndpointsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/ServiceEndpoints/{service}`

*Retrieve all ServiceEndpoints of a {service}*

Retrieve all ServiceEndpoint records for the Redfish service.

<h3 id="doserviceendpointsget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|service|path|string|true|The Redfish service type of the ServiceEndpoint records to return.|
|redfish_ep|query|string|false|Retrieve all ServiceEndpoints of type {service} managed by the parent Redfish EP. Can be repeated to select groups of endpoints.|

> Example responses

> ServiceEndpointArray representing the subset of the ServiceEndpoint collection filtered by {service} or additionally filtered thereof.

```json
{
  "ServiceEndpoints": {
    "RedfishEndpointID": "x0c0s0b0",
    "RedfishType": "UpdateService",
    "RedfishSubtype": "Other",
    "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
    "OdataID": "/redfish/v1/UpdateService",
    "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
    "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/UpdateService",
    "ServiceInfo": {
      "@odata.context": "/redfish/v1/$metadata#UpdateService.UpdateService",
      "@odata.id": "/redfish/v1/UpdateService",
      "@odata.type": "#UpdateService.v1_1_0.UpdateService",
      "ID": "UpdateService",
      "Name": "Update Service",
      "Actions": {
        "#UpdateService.SimpleUpdate": {
          "target": "/redfish/v1/Systems/System.Embedded.1/Actions/ComputerSystem.Reset",
          "title": ""
        }
      },
      "FirmwareInventory": {
        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory"
      },
      "SoftwareInventory": {
        "@odata.id": "/redfish/v1/UpdateService/SoftwareInventory"
      },
      "ServiceEnabled": "True"
    }
  }
}
```

> 200 Response

```json
{
  "ServiceEndpoints": [
    {
      "RedfishEndpointID": "x0c0s0b0",
      "RedfishType": "ComputerSystem",
      "RedfishSubtype": "Physical",
      "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
      "OdataID": "/redfish/v1/Systems/System.Embedded.1",
      "RedfishEndpointFQDN": "string",
      "RedfishURL": "string",
      "ServiceInfo": {
        "Name": "string"
      }
    }
  ]
}
```

<h3 id="doserviceendpointsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ServiceEndpointArray representing the subset of the ServiceEndpoint collection filtered by {service} or additionally filtered thereof.|[ServiceEndpointArray_ServiceEndpointArray](#schemaserviceendpointarray_serviceendpointarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Service does not exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doServiceEndpointGet

<a id="opIddoServiceEndpointGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service}/RedfishEndpoints/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service}/RedfishEndpoints/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service}/RedfishEndpoints/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service}/RedfishEndpoints/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/ServiceEndpoints/{service}/RedfishEndpoints/{xname}`

*Retrieve the ServiceEndpoint of a {service} managed by {xname}*

Retrieve the ServiceEndpoint for a Redfish service that is managed by xname.

<h3 id="doserviceendpointget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|service|path|string|true|The Redfish service type of the ServiceEndpoint record to return.|
|xname|path|string|true|The locational xname of the RedfishEndpoint that manages the ServiceEndpoint record to return.|

> Example responses

> ServiceEndpoint entry matching {service}/{xname}

```json
{
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishType": "UpdateService",
  "RedfishSubtype": "Other",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/UpdateService",
  "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
  "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/UpdateService",
  "ServiceInfo": {
    "@odata.context": "/redfish/v1/$metadata#UpdateService.UpdateService",
    "@odata.id": "/redfish/v1/UpdateService",
    "@odata.type": "#UpdateService.v1_1_0.UpdateService",
    "ID": "UpdateService",
    "Name": "Update Service",
    "Actions": {
      "#UpdateService.SimpleUpdate": {
        "target": "/redfish/v1/Systems/System.Embedded.1/Actions/ComputerSystem.Reset",
        "title": ""
      }
    },
    "FirmwareInventory": {
      "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory"
    },
    "SoftwareInventory": {
      "@odata.id": "/redfish/v1/UpdateService/SoftwareInventory"
    },
    "ServiceEnabled": "True"
  }
}
```

> 200 Response

```json
{
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishType": "ComputerSystem",
  "RedfishSubtype": "Physical",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/Systems/System.Embedded.1",
  "RedfishEndpointFQDN": "string",
  "RedfishURL": "string",
  "ServiceInfo": {
    "Name": "string"
  }
}
```

<h3 id="doserviceendpointget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ServiceEndpoint entry matching {service}/{xname}|[ServiceEndpoint.1.0.0_ServiceEndpoint](#schemaserviceendpoint.1.0.0_serviceendpoint)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doServiceEndpointDelete

<a id="opIddoServiceEndpointDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service}/RedfishEndpoints/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service}/RedfishEndpoints/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service}/RedfishEndpoints/{xname}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/ServiceEndpoints/{service}/RedfishEndpoints/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/ServiceEndpoints/{service}/RedfishEndpoints/{xname}`

*Delete the {service} ServiceEndpoint managed by {xname}*

Delete the {service} ServiceEndpoint managed by {xname}

<h3 id="doserviceendpointdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|service|path|string|true|The Redfish service type of the ServiceEndpoint record to delete.|
|xname|path|string|true|The locational xname of the RedfishEndpoint that manages the ServiceEndpoint record to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="doserviceendpointdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - ServiceEndpoint is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - no matching ServiceEndpoint to delete|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-componentethernetinterfaces">ComponentEthernetInterfaces</h1>

The MAC address to IP address relation for components in the system. If the component has been discovered by HSM, the xname of the component that has the Ethernet interface will be associated with it as well.

## doCompEthInterfacesGetV2

<a id="opIddoCompEthInterfacesGetV2"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/EthernetInterfaces`

*GET ALL existing component Ethernet interfaces*

Get all component Ethernet interfaces that currently exist, optionally filtering the set, returning an array of component Ethernet interfaces.

<h3 id="docompethinterfacesgetv2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|MACAddress|query|string|false|Retrieve the component Ethernet interface with the provided MAC address. Can be repeated to select multiple component Ethernet interfaces.|
|IPAddress|query|string|false|Retrieve the component Ethernet interface with the provided IP address. Can be repeated to select multiple component Ethernet interfaces. A blank string will retrieve component Ethernet interfaces that have no IP address.|
|Network|query|string|false|Retrieve the component Ethernet interface with a IP addresses on the provided  network. Can be repeated to select multiple component Ethernet interfaces. A blank string will retrieve component Ethernet interfaces that have an IP address with no  network.|
|ComponentID|query|string|false|Retrieve all component Ethernet interfaces with the provided component ID. Can be repeated to select multiple component Ethernet interfaces.|
|Type|query|string|false|Retrieve all component Ethernet interfaces with the provided parent HMS type. Can be repeated to select multiple component Ethernet interfaces.|
|OlderThan|query|string|false|Retrieve all component Ethernet interfaces that were last updated before the specified time. This takes an RFC3339 formatted string (2006-01-02T15:04:05Z07:00).|
|NewerThan|query|string|false|Retrieve all component Ethernet interfaces that were last updated after the specified time. This takes an RFC3339 formatted string (2006-01-02T15:04:05Z07:00).|

> Example responses

> 200 Response

```json
[
  {
    "ID": "a4bf012b7310",
    "Description": "string",
    "MACAddress": "string",
    "IPAddresses": [
      {
        "IPAddress": "10.252.0.1",
        "Network": "HMN"
      }
    ],
    "LastUpdate": "2020-05-13T19:18:45.524974Z",
    "ComponentID": "x0c0s1b0n0",
    "Type": "Node"
  }
]
```

<h3 id="docompethinterfacesgetv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An array containing all existing component Ethernet interface objects.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="docompethinterfacesgetv2-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[CompEthInterface.1.0.0](#schemacompethinterface.1.0.0)]|false|none|[A component Ethernet interface is an object describing a relation between a MAC address and IP address for components.]|
|» ID|string|false|read-only|The ID of the component Ethernet interface.|
|» Description|string|false|none|An optional description for the component Ethernet interface.|
|» MACAddress|string|true|none|The MAC address of this component Ethernet interface|
|» IPAddresses|[[CompEthInterface.1.0.0_IPAddressMapping](#schemacompethinterface.1.0.0_ipaddressmapping)]|false|none|The IP addresses associated with the MAC address for this component Ethernet interface.|
|»» IPAddress|string|true|none|The IP address associated with the MAC address for this component Ethernet interface on for this particular network.|
|»» Network|string|false|none|The network that this IP addresses is associated with.|
|» LastUpdate|string(date-time)|false|read-only|A timestamp for when the component Ethernet interface last was modified.|
|» ComponentID|[XNameRW.1.0.0](#schemaxnamerw.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is the non-readOnly version for writable component lists.|
|» Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|read-only|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|

#### Enumerated Values

|Property|Value|
|---|---|
|Type|CDU|
|Type|CabinetCDU|
|Type|CabinetPDU|
|Type|CabinetPDUOutlet|
|Type|CabinetPDUPowerConnector|
|Type|CabinetPDUController|
|Type|Cabinet|
|Type|Chassis|
|Type|ChassisBMC|
|Type|CMMRectifier|
|Type|CMMFpga|
|Type|CEC|
|Type|ComputeModule|
|Type|RouterModule|
|Type|NodeBMC|
|Type|NodeEnclosure|
|Type|NodeEnclosurePowerSupply|
|Type|HSNBoard|
|Type|MgmtSwitch|
|Type|MgmtHLSwitch|
|Type|CDUMgmtSwitch|
|Type|Node|
|Type|Processor|
|Type|Drive|
|Type|StorageGroup|
|Type|NodeNIC|
|Type|Memory|
|Type|NodeAccel|
|Type|NodeAccelRiser|
|Type|NodeFpga|
|Type|HSNAsic|
|Type|RouterFpga|
|Type|RouterBMC|
|Type|HSNLink|
|Type|HSNConnector|
|Type|INVALID|

<aside class="success">
This operation does not require authentication
</aside>

## doCompEthInterfacePostV2

<a id="opIddoCompEthInterfacePostV2"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /Inventory/EthernetInterfaces`

*CREATE a new component Ethernet interface (via POST)*

Create a new component Ethernet interface.

> Body parameter

```json
{
  "Description": "string",
  "MACAddress": "string",
  "IPAddresses": [
    {
      "IPAddress": "10.252.0.1",
      "Network": "HMN"
    }
  ],
  "ComponentID": "x0c0s1b0n0"
}
```

<h3 id="docompethinterfacepostv2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[CompEthInterface.1.0.0](#schemacompethinterface.1.0.0)|true|none|

> Example responses

> Success, returns array containing the created resource URI.

```json
{
  "uri": "/hsm/v2/Inventory/a4bf012b7311"
}
```

> 201 Response

```json
{
  "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
}
```

<h3 id="docompethinterfacepostv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Success, returns array containing the created resource URI.|[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. Duplicate component Ethernet interface would be created.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompEthInterfaceDeleteAllV2

<a id="opIddoCompEthInterfaceDeleteAllV2"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/EthernetInterfaces`

*Clear the component Ethernet interface collection.*

Delete all component Ethernet interface entries.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="docompethinterfacedeleteallv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) response code - one or more entries deleted. Message contains count of deleted items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Collection is empty|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompEthInterfaceGetV2

<a id="opIddoCompEthInterfaceGetV2"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/EthernetInterfaces/{ethInterfaceID}`

*GET existing component Ethernet interface {ethInterfaceID}*

Retrieve the component Ethernet interface which was created with the given {ethInterfaceID}.

<h3 id="docompethinterfacegetv2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|ethInterfaceID|path|string|true|The ID of the component Ethernet interface to return.|

> Example responses

> 200 Response

```json
{
  "ID": "a4bf012b7310",
  "Description": "string",
  "MACAddress": "string",
  "IPAddresses": [
    {
      "IPAddress": "10.252.0.1",
      "Network": "HMN"
    }
  ],
  "LastUpdate": "2020-05-13T19:18:45.524974Z",
  "ComponentID": "x0c0s1b0n0",
  "Type": "Node"
}
```

<h3 id="docompethinterfacegetv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Component Ethernet interface entry identified by {ethInterfaceID}, if it exists.|[CompEthInterface.1.0.0](#schemacompethinterface.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompEthInterfaceDeleteV2

<a id="opIddoCompEthInterfaceDeleteV2"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/EthernetInterfaces/{ethInterfaceID}`

*DELETE existing component Ethernet interface with {ethInterfaceID}*

Delete the given component Ethernet interface with {ethInterfaceID}.

<h3 id="docompethinterfacedeletev2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|ethInterfaceID|path|string|true|The ID of the component Ethernet interface to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="docompethinterfacedeletev2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - component Ethernet interface is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - No component Ethernet interface with ethInterfaceID.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompEthInterfacePatchV2

<a id="opIddoCompEthInterfacePatchV2"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /Inventory/EthernetInterfaces/{ethInterfaceID}`

*UPDATE metadata for existing component Ethernet interface {ethInterfaceID}*

To update the IP address, CompID, and/or description of a component Ethernet interface, a PATCH operation can be used. Omitted fields are not updated. The 'LastUpdate' field will be updated if an IP address is provided.

> Body parameter

```json
{
  "Description": "string",
  "IPAddresses": [
    {
      "IPAddress": "10.252.0.1",
      "Network": "HMN"
    }
  ],
  "ComponentID": "x0c0s1b0n0"
}
```

<h3 id="docompethinterfacepatchv2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|ethInterfaceID|path|string|true|The ID of the component Ethernet interface to update.|
|body|body|[CompEthInterface.1.0.0_Patch](#schemacompethinterface.1.0.0_patch)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompethinterfacepatchv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The component Ethernet interface with this ethInterfaceID does not exist.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompEthInterfaceIPAddressesGetV2

<a id="opIddoCompEthInterfaceIPAddressesGetV2"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses`

*Retrieve all IP addresses of a component Ethernet interface {ethInterfaceID}*

Retrieve all IP addresses of a component Ethernet interface {ethInterfaceID}

<h3 id="docompethinterfaceipaddressesgetv2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|ethInterfaceID|path|string|true|The ID of the component Ethernet interface to retrieve the IP addresses of.|

> Example responses

> 200 Response

```json
[
  {
    "IPAddress": "10.252.0.1",
    "Network": "HMN"
  }
]
```

<h3 id="docompethinterfaceipaddressesgetv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|IP addresses of the component Ethernet interface entry identified by {ethInterfaceID}, if it exists.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="docompethinterfaceipaddressesgetv2-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[CompEthInterface.1.0.0_IPAddressMapping](#schemacompethinterface.1.0.0_ipaddressmapping)]|false|none|[A IP address Mapping maps a IP address to a network. In a Component Ethernet Interface it is used to describe what IP addresses and their networks that are associated with it.]|
|» IPAddress|string|true|none|The IP address associated with the MAC address for this component Ethernet interface on for this particular network.|
|» Network|string|false|none|The network that this IP addresses is associated with.|

<aside class="success">
This operation does not require authentication
</aside>

## doCompEthInterfaceIPAddressesPostV2

<a id="opIddoCompEthInterfaceIPAddressesPostV2"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses`

*CREATE a new IP address mapping in a component Ethernet interface (via POST)*

Create a new IP address mapping in a component Ethernet interface {ethInterfaceID}.

> Body parameter

```json
{
  "IPAddress": "10.252.0.1",
  "Network": "HMN"
}
```

<h3 id="docompethinterfaceipaddressespostv2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|ethInterfaceID|path|string|true|The ID of the component Ethernet interface to add the IP address to.|
|body|body|[CompEthInterface.1.0.0_IPAddressMapping](#schemacompethinterface.1.0.0_ipaddressmapping)|true|none|

> Example responses

> 201 Response

```json
{
  "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
}
```

<h3 id="docompethinterfaceipaddressespostv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Success, returns the created resource URI.|[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. Duplicate IP address in component Ethernet interface would be created.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompEthInterfaceIPAddressPatchV2

<a id="opIddoCompEthInterfaceIPAddressPatchV2"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses/{ipAddress} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses/{ipAddress} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses/{ipAddress}', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses/{ipAddress}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses/{ipAddress}`

*UPDATE metadata for existing IP address {ipAddress} in a component Ethernet interface {ethInterfaceID*

"To update the network of an IP address in a component Ethernet interface, a PATCH operation can be used. Omitted fields are not updated. The 'LastUpdate' field of the component Ethernet interface will be updated"

> Body parameter

```json
{
  "Network": "string"
}
```

<h3 id="docompethinterfaceipaddresspatchv2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|ethInterfaceID|path|string|true|The ID of the component Ethernet interface with the IP address to patch.|
|ipAddress|path|string|true|The IP address to patch from the component Ethernet interface.|
|body|body|[CompEthInterface.1.0.0_IPAddressMapping_Patch](#schemacompethinterface.1.0.0_ipaddressmapping_patch)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="docompethinterfaceipaddresspatchv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - No IP address with ipAddress exists on the specified component Ethernet interface.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doCompEthInterfaceIPAddressDeleteV2

<a id="opIddoCompEthInterfaceIPAddressDeleteV2"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses/{ipAddress} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses/{ipAddress} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses/{ipAddress}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses/{ipAddress}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Inventory/EthernetInterfaces/{ethInterfaceID}/IPAddresses/{ipAddress}`

*DELETE existing IP address mapping with {ipAddress} from a component Ethernet interface with {ethInterfaceID}*

Delete the given IP address mapping with {ipAddress} from a component Ethernet interface with {ethInterfaceID}. The 'LastUpdate' field of the component Ethernet interface will be updated"

<h3 id="docompethinterfaceipaddressdeletev2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|ethInterfaceID|path|string|true|The ID of the component Ethernet interface to delete the IP address from|
|ipAddress|path|string|true|The IP address to delete from the component Ethernet interface.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="docompethinterfaceipaddressdeletev2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - IP address mapping is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - No IP address with ipAddress exists on the specified component Ethernet interface|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-group">Group</h1>

A group is an informal, possibly overlapping division of the system that groups Components (most frequently nodes) under an administratively chosen label (i.e. group name).  Unlike partitions, components can be members of any number of groups.

## doGroupsGet

<a id="opIddoGroupsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/groups HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/groups \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/groups', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/groups", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /groups`

*Retrieve all existing groups*

Retrieve all groups that currently exist, optionally filtering the set, returning an array of groups.

<h3 id="dogroupsget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|group|query|string|false|Retrieve the group with the provided group label. Can be repeated to select multiple groups.|
|tag|query|string|false|Retrieve all groups associated with the given free-form tag from the tags field.|

> Example responses

> 200 Response

```json
[
  {
    "label": "blue",
    "description": "This is the blue group",
    "tags": [
      "optional_tag1",
      "optional_tag2"
    ],
    "exclusiveGroup": "optional_excl_group",
    "members": {
      "ids": [
        "x1c0s1b0n0",
        "x1c0s1b0n1",
        "x1c0s2b0n0",
        "x1c0s2b0n1"
      ]
    }
  }
]
```

<h3 id="dogroupsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Groups array containing all existing group objects.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dogroupsget-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Group.1.0.0](#schemagroup.1.0.0)]|false|none|[A group is an informal, possibly overlapping division of the system that groups components under an administratively chosen label (i.e. group name). Unlike partitions, components can be members of any number of groups.]|
|» label|[ResourceName](#schemaresourcename)|true|none|Acceptable format for certain user-requested string identifiers.|
|» description|string|false|none|A one-line, user-provided description of the group.|
|» tags|[[ResourceName](#schemaresourcename)]|false|none|A free-form array of strings to provide extra organization/filtering. Not to be confused with labels/groups.|
|» exclusiveGroup|[ResourceName](#schemaresourcename)|false|none|Acceptable format for certain user-requested string identifiers.|
|» members|[Members.1.0.0](#schemamembers.1.0.0)|false|none|The members are a fully enumerated (i.e. no implied members besides those explicitly provided) representation of the components a partition or group|
|»» ids|[[XNameRW.1.0.0](#schemaxnamerw.1.0.0)]|false|none|Set of Component XName IDs that represent the membership of the group or partition.|

<aside class="success">
This operation does not require authentication
</aside>

## doGroupsPost

<a id="opIddoGroupsPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/groups HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/groups \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/groups', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/groups", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /groups`

*Create a new group*

Create a new group identified by the group_label field. Label should be given explicitly, and should not conflict with any existing group, or an error will occur.

Note that if the exclusiveGroup field is present, the group is not allowed to add a member that exists under a different group/label where the exclusiveGroup field is the same. This can be used to create groups of groups where a component may only be present in one of the set.

> Body parameter

```json
{
  "label": "blue",
  "description": "This is the blue group",
  "tags": [
    "optional_tag1",
    "optional_tag2"
  ],
  "exclusiveGroup": "optional_excl_group",
  "members": {
    "ids": [
      "x1c0s1b0n0",
      "x1c0s1b0n1",
      "x1c0s2b0n0",
      "x1c0s2b0n1"
    ]
  }
}
```

<h3 id="dogroupspost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[Group.1.0.0](#schemagroup.1.0.0)|true|none|

> Example responses

> Success, returns array containing the created resource URI.

```json
[
  {
    "uri": "/hsm/v2/groups/mygrouplabel"
  }
]
```

> 201 Response

```json
[
  {
    "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
  }
]
```

<h3 id="dogroupspost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Success, returns array containing the created resource URI.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. Duplicate resource would be created.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dogroupspost-responseschema">Response Schema</h3>

Status Code **201**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|none|[A ResourceURI is like an odata.id, it provides a path to a resource from the API root, such that when a GET is performed, the corresponding object is returned.  It does not imply other odata functionality.]|
|» ResourceURI|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## doGroupGet

<a id="opIddoGroupGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/groups/{group_label} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/groups/{group_label} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/groups/{group_label}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/groups/{group_label}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /groups/{group_label}`

*Retrieve existing group {group_label}*

Retrieve the group which was created with the given {group_label}.

<h3 id="dogroupget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|group_label|path|string|true|Label name of the group to return.|
|partition|query|string|false|AND the members set by the given partition name (p#.#).  NULL will return the group members not in ANY partition.|

> Example responses

> 200 Response

```json
{
  "label": "blue",
  "description": "This is the blue group",
  "tags": [
    "optional_tag1",
    "optional_tag2"
  ],
  "exclusiveGroup": "optional_excl_group",
  "members": {
    "ids": [
      "x1c0s1b0n0",
      "x1c0s1b0n1",
      "x1c0s2b0n0",
      "x1c0s2b0n1"
    ]
  }
}
```

<h3 id="dogroupget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Group entry identified by {group_label}, if it exists.|[Group.1.0.0](#schemagroup.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doGroupDelete

<a id="opIddoGroupDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/groups/{group_label} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/groups/{group_label} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/groups/{group_label}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/groups/{group_label}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /groups/{group_label}`

*Delete existing group with {group_label}*

Delete the given group with {group_label}. Any members previously in the group will no longer have the deleted group label associated with them.

<h3 id="dogroupdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|group_label|path|string|true|Label (i.e. name) of the group to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dogroupdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - component is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - No group matches label.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doGroupPatch

<a id="opIddoGroupPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/groups/{group_label} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/groups/{group_label} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/groups/{group_label}', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/groups/{group_label}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /groups/{group_label}`

*Update metadata for existing group {group_label}*

To update the tags array and/or description, a PATCH operation can be used.  Omitted fields are not updated. This cannot be used to completely replace the members list. Rather, individual members can be removed or added with the POST/DELETE {group_label}/members API below.

> Body parameter

```json
{
  "description": "This is an updated group description",
  "tags": [
    "new_tag",
    "existing_tag"
  ]
}
```

<h3 id="dogrouppatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|group_label|path|string|true|Label (i.e. name) of the group to update.|
|body|body|[Group.1.0.0_Patch](#schemagroup.1.0.0_patch)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="dogrouppatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The group with this label did not exist.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doGroupLabelsGet

<a id="opIddoGroupLabelsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/groups/labels HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/groups/labels \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/groups/labels', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/groups/labels", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /groups/labels`

*Retrieve all existing group labels*

Retrieve a string array of all group labels (i.e. group names) that currently exist in HSM.

> Example responses

> Array of group labels which form the names of all existing groups, or an empty array if none currently exist.

```json
[
  "blue",
  "green",
  "red",
  "compute_a"
]
```

> 200 Response

```json
[
  "string"
]
```

<h3 id="dogrouplabelsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Array of group labels which form the names of all existing groups, or an empty array if none currently exist.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dogrouplabelsget-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

## doGroupMembersGet

<a id="opIddoGroupMembersGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/groups/{group_label}/members HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/groups/{group_label}/members \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/groups/{group_label}/members', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/groups/{group_label}/members", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /groups/{group_label}/members`

*Retrieve all members of existing group*

Retrieve members of an existing group {group_label}, optionally filtering the set, returning a members set containing the component xname IDs.

<h3 id="dogroupmembersget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|group_label|path|string|true|Specifies an existing group {group_label} to query the members of.|
|partition|query|string|false|AND the members set by the given partition name (p#.#).  NULL will return the group members not in ANY partition.|

> Example responses

> 200 Response

```json
{
  "ids": [
    "x1c0s1b0n0",
    "x1c0s1b0n1",
    "x2c0s3b0n0",
    "x2c0s3b0n1"
  ]
}
```

<h3 id="dogroupmembersget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Members set including component xname IDs which are members of group {group_label}.  If none exist, an empty array with be returned.|[Members.1.0.0](#schemamembers.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does not exist - No such group {group_label}|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doGroupMembersPost

<a id="opIddoGroupMembersPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/groups/{group_label}/members HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/groups/{group_label}/members \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/groups/{group_label}/members', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/groups/{group_label}/members", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /groups/{group_label}/members`

*Create new member of existing group (via POST)*

Create a new member of group {group_label} with the component xname ID provided in the payload. New member should not already exist in the given group.

> Body parameter

```json
{
  "id": "x0c0s1b0n0"
}
```

<h3 id="dogroupmemberspost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|group_label|path|string|true|Specifies an existing group {group_label} to add the new member to.|
|body|body|[MemberID](#schemamemberid)|true|none|

> Example responses

> Success, returns array containing the created member URI.

```json
[
  {
    "uri": "/hsm/v2/groups/mygrouplabel/members/x0c0s1b0n0"
  }
]
```

> 201 Response

```json
[
  {
    "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
  }
]
```

<h3 id="dogroupmemberspost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Success, returns array containing the created member URI.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request - e.g. malformed string|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does not exist - No such group {group_label}|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. Duplicate resource would be created.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dogroupmemberspost-responseschema">Response Schema</h3>

Status Code **201**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|none|[A ResourceURI is like an odata.id, it provides a path to a resource from the API root, such that when a GET is performed, the corresponding object is returned.  It does not imply other odata functionality.]|
|» ResourceURI|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## doGroupMemberDelete

<a id="opIddoGroupMemberDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/groups/{group_label}/members/{xname_id} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/groups/{group_label}/members/{xname_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/groups/{group_label}/members/{xname_id}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/groups/{group_label}/members/{xname_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /groups/{group_label}/members/{xname_id}`

*Delete member from existing group*

Delete component {xname_id} from the members of group {group_label}.

<h3 id="dogroupmemberdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|group_label|path|string|true|Specifies an existing group {group_label} to remove the member from.|
|xname_id|path|string|true|Member of {group_label} to remove.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dogroupmemberdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - entry deleted. Message contains count of deleted items (should always be one).|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request, malformed group label or component xname_id|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - no such member or group.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-partition">Partition</h1>

A partition is a formal, non-overlapping division of the system that forms an administratively distinct sub-system e.g. for implementing multi-tenancy.

## doPartitionsGet

<a id="opIddoPartitionsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/partitions HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/partitions \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/partitions', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/partitions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /partitions`

*Retrieve all existing partitions*

Retrieve all partitions that currently exist, optionally filtering the set, returning an array of partition records.

<h3 id="dopartitionsget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|partition|query|string|false|Retrieve the partition with the provided partition name (p#.#). Can be repeated to select multiple partitions.|
|tag|query|string|false|Retrieve all partitions associated with the given free-form tag from the tags field.|

> Example responses

> 200 Response

```json
[
  {
    "name": "p1",
    "description": "This is partition 1",
    "tags": [
      "optional_tag_a",
      "optional_tag1"
    ],
    "members": {
      "ids": [
        "x1c0s1b0n0",
        "x1c0s1b0n1",
        "x2c0s3b0n0",
        "x2c0s3b0n1"
      ]
    }
  }
]
```

<h3 id="dopartitionsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Array containing all existing partition objects.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dopartitionsget-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Partition.1.0.0](#schemapartition.1.0.0)]|false|none|[A partition is a formal, non-overlapping division of the system that forms an administratively distinct sub-system e.g. for implementing multi-tenancy.]|
|» name|[ResourceName](#schemaresourcename)|true|none|Acceptable format for certain user-requested string identifiers.|
|» description|string|false|none|A one-line, user-provided description of the partition.|
|» tags|[[ResourceName](#schemaresourcename)]|false|none|A free-form array of strings to provide extra organization/filtering. Not to be confused with labels/groups.|
|» members|[Members.1.0.0](#schemamembers.1.0.0)|false|none|The members are a fully enumerated (i.e. no implied members besides those explicitly provided) representation of the components a partition or group|
|»» ids|[[XNameRW.1.0.0](#schemaxnamerw.1.0.0)]|false|none|Set of Component XName IDs that represent the membership of the group or partition.|

<aside class="success">
This operation does not require authentication
</aside>

## doPartitionsPost

<a id="opIddoPartitionsPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/partitions HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/partitions \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/partitions', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/partitions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /partitions`

*Create new partition (via POST)*

Create a new partition identified by the partition_name field. Partition names should be of the format p# or p#.# (hard_part.soft_part). Partition name should be given explicitly, and should not conflict with any existing partition, or an error will occur.  In addition, the member list must not overlap with any existing partition.

> Body parameter

```json
{
  "name": "p1",
  "description": "This is partition 1",
  "tags": [
    "optional_tag_a",
    "optional_tag1"
  ],
  "members": {
    "ids": [
      "x1c0s1b0n0",
      "x1c0s1b0n1",
      "x2c0s3b0n0",
      "x2c0s3b0n1"
    ]
  }
}
```

<h3 id="dopartitionspost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[Partition.1.0.0](#schemapartition.1.0.0)|true|none|

> Example responses

> Success, returns array containing the created resource URI.

```json
[
  {
    "uri": "/hsm/v2/partitions/p1"
  }
]
```

> 201 Response

```json
[
  {
    "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
  }
]
```

<h3 id="dopartitionspost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Success, returns array containing the created resource URI.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. Duplicate resource would be created.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dopartitionspost-responseschema">Response Schema</h3>

Status Code **201**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|none|[A ResourceURI is like an odata.id, it provides a path to a resource from the API root, such that when a GET is performed, the corresponding object is returned.  It does not imply other odata functionality.]|
|» ResourceURI|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## doPartitionGet

<a id="opIddoPartitionGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/partitions/{partition_name} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/partitions/{partition_name} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/partitions/{partition_name}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/partitions/{partition_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /partitions/{partition_name}`

*Retrieve existing partition {partition_name}*

Retrieve the partition which was created with the given {partition_name}.

<h3 id="dopartitionget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|partition_name|path|string|true|Partition name to be retrieved|

> Example responses

> 200 Response

```json
{
  "name": "p1",
  "description": "This is partition 1",
  "tags": [
    "optional_tag_a",
    "optional_tag1"
  ],
  "members": {
    "ids": [
      "x1c0s1b0n0",
      "x1c0s1b0n1",
      "x2c0s3b0n0",
      "x2c0s3b0n1"
    ]
  }
}
```

<h3 id="dopartitionget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Partition entry identified by {partition_name}, if it exists.|[Partition.1.0.0](#schemapartition.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPartitionDelete

<a id="opIddoPartitionDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/partitions/{partition_name} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/partitions/{partition_name} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/partitions/{partition_name}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/partitions/{partition_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /partitions/{partition_name}`

*Delete existing partition with {partition_name}*

Delete partition {partition_name}. Any members previously in the partition will no longer have the deleted partition name associated with them.

<h3 id="dopartitiondelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|partition_name|path|string|true|Partition name of the partition to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dopartitiondelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - component is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - No partition matches partition_name.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPartitionPatch

<a id="opIddoPartitionPatch"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/partitions/{partition_name} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/partitions/{partition_name} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/partitions/{partition_name}', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/partitions/{partition_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /partitions/{partition_name}`

*Update metadata for existing partition {partition_name}*

Update the tags array and/or description by using PATCH. Omitted fields are not updated. This cannot be used to completely replace the members list. Rather, individual members can be removed or added with the POST/DELETE {partition_name}/members API.

> Body parameter

```json
{
  "description": "This is an updated partition description",
  "tags": [
    "new_tag",
    "existing_tag"
  ]
}
```

<h3 id="dopartitionpatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|partition_name|path|string|true|Name of the partition to update.|
|body|body|[Partition.1.0.0_Patch](#schemapartition.1.0.0_patch)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="dopartitionpatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The partition with this partition_name did not exist.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPartitionNamesGet

<a id="opIddoPartitionNamesGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/partitions/names HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/partitions/names \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/partitions/names', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/partitions/names", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /partitions/names`

*Retrieve all existing partition names*

Retrieve a string array of all partition names that currently exist in HSM. These are just the names, not the complete partition records.

> Example responses

> Array of partition names comprising all partitions known to HSM at the present time, or an empty array if none currently exist.

```json
[
  "p1",
  "p2"
]
```

> 200 Response

```json
[
  "string"
]
```

<h3 id="dopartitionnamesget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Array of partition names comprising all partitions known to HSM at the present time, or an empty array if none currently exist.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dopartitionnamesget-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

## doPartitionMembersGet

<a id="opIddoPartitionMembersGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /partitions/{partition_name}/members`

*Retrieve all members of existing partition*

Retrieve all members of existing partition {partition_name}, optionally filtering the set, returning a members set that includes the component xname IDs.

<h3 id="dopartitionmembersget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|partition_name|path|string|true|Existing partition {partition_name} to query the members of.|

> Example responses

> 200 Response

```json
{
  "ids": [
    "x1c0s1b0n0",
    "x1c0s1b0n1",
    "x2c0s3b0n0",
    "x2c0s3b0n1"
  ]
}
```

<h3 id="dopartitionmembersget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Members set including component xname IDs which are members of partition {partition_name}.  If none exist, an empty array will be returned.|[Members.1.0.0](#schemamembers.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does not exist - No such partition {partition_name}|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPartitionMembersPost

<a id="opIddoPartitionMembersPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /partitions/{partition_name}/members`

*Create new member of existing partition (via POST)*

Create a new member of partition {partition_name} with the component xname ID provided in the payload. New member should not already exist in the given partition

> Body parameter

```json
{
  "id": "x0c0s1b0n0"
}
```

<h3 id="dopartitionmemberspost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|partition_name|path|string|true|Existing partition {partition_name} to add the new member to.|
|body|body|[MemberID](#schemamemberid)|true|none|

> Example responses

> Success, returns array containing the created member URI.

```json
[
  {
    "uri": "/hsm/v2/partitions/p1/members/x0c0s1b0n0"
  }
]
```

> 201 Response

```json
[
  {
    "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
  }
]
```

<h3 id="dopartitionmemberspost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Success, returns array containing the created member URI.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request - Bad partition_name or malformed string?|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does not exist - No such partition {partition_name}|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. Duplicate resource would be created.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dopartitionmemberspost-responseschema">Response Schema</h3>

Status Code **201**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|none|[A ResourceURI is like an odata.id, it provides a path to a resource from the API root, such that when a GET is performed, the corresponding object is returned.  It does not imply other odata functionality.]|
|» ResourceURI|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## doPartitionMemberDelete

<a id="opIddoPartitionMemberDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members/{xname_id} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members/{xname_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members/{xname_id}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/partitions/{partition_name}/members/{xname_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /partitions/{partition_name}/members/{xname_id}`

*Delete member from existing partition*

Delete component {xname_id} from the members of partition {partition_name}.

<h3 id="dopartitionmemberdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|partition_name|path|string|true|Existing partition {partition_name} to remove the member from.|
|xname_id|path|string|true|Member of {partition_name} to remove.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dopartitionmemberdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - entry deleted. Message contains count of deleted items (should always be one).|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request, malformed partition_name or xname_id|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - no such member or partition.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-membership">Membership</h1>

A membership is a mapping of a component xname to its set of group labels and partition names.

## doMembershipsGet

<a id="opIddoMembershipsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/memberships HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/memberships \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/memberships', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/memberships", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /memberships`

*Retrieve all memberships for components*

Display group labels and partition names for each component xname ID (where applicable).

<h3 id="domembershipsget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|query|string|false|Filter the results based on xname ID(s). Can be specified multiple times for selecting entries with multiple specific xnames.|
|type|query|string|false|Filter the results based on HMS type like Node, NodeEnclosure, NodeBMC etc. Can be specified multiple times for selecting entries of multiple types.|
|state|query|string|false|Filter the results based on HMS state like Ready, On etc. Can be specified multiple times for selecting entries in different states.|
|flag|query|string|false|Filter the results based on HMS flag value like OK, Alert etc. Can be specified multiple times for selecting entries with different flags.|
|role|query|string|false|Filter the results based on HMS role. Can be specified multiple times for selecting entries with different roles. Valid values are:|
|subrole|query|string|false|Filter the results based on HMS subrole. Can be specified multiple times for selecting entries with different subroles. Valid values are:|
|enabled|query|string|false|Filter the results based on enabled status (true or false).|
|softwarestatus|query|string|false|Filter the results based on software status. Software status is a free form string. Matching is case-insensitive. Can be specified multiple times for selecting entries with different software statuses.|
|subtype|query|string|false|Filter the results based on HMS subtype. Can be specified multiple times for selecting entries with different subtypes.|
|arch|query|string|false|Filter the results based on architecture. Can be specified multiple times for selecting components with different architectures.|
|class|query|string|false|Filter the results based on HMS hardware class. Can be specified multiple times for selecting entries with different classes.|
|nid|query|string|false|Filter the results based on NID. Can be specified multiple times for selecting entries with multiple specific NIDs.|
|nid_start|query|string|false|Filter the results based on NIDs equal to or greater than the provided integer.|
|nid_end|query|string|false|Filter the results based on NIDs less than or equal to the provided integer.|
|partition|query|string|false|Restrict search to the given partition (p#.#). One partition can be combined with at most one group argument which will be treated as a logical AND. NULL will return components in NO partition.|
|group|query|string|false|Restrict search to the given group label. One group can be combined with at most one partition argument which will be treated as a logical AND. NULL will return components in NO groups.|

#### Detailed descriptions

**role**: Filter the results based on HMS role. Can be specified multiple times for selecting entries with different roles. Valid values are:
- Compute
- Service
- System
- Application
- Storage
- Management
Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.

**subrole**: Filter the results based on HMS subrole. Can be specified multiple times for selecting entries with different subroles. Valid values are:
- Master
- Worker
- Storage
Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.

#### Enumerated Values

|Parameter|Value|
|---|---|
|type|CDU|
|type|CabinetCDU|
|type|CabinetPDU|
|type|CabinetPDUOutlet|
|type|CabinetPDUPowerConnector|
|type|CabinetPDUController|
|type|Cabinet|
|type|Chassis|
|type|ChassisBMC|
|type|CMMRectifier|
|type|CMMFpga|
|type|CEC|
|type|ComputeModule|
|type|RouterModule|
|type|NodeBMC|
|type|NodeEnclosure|
|type|NodeEnclosurePowerSupply|
|type|HSNBoard|
|type|MgmtSwitch|
|type|MgmtHLSwitch|
|type|CDUMgmtSwitch|
|type|Node|
|type|Processor|
|type|Drive|
|type|StorageGroup|
|type|NodeNIC|
|type|Memory|
|type|NodeAccel|
|type|NodeAccelRiser|
|type|NodeFpga|
|type|HSNAsic|
|type|RouterFpga|
|type|RouterBMC|
|type|HSNLink|
|type|HSNConnector|
|type|INVALID|
|state|Unknown|
|state|Empty|
|state|Populated|
|state|Off|
|state|On|
|state|Standby|
|state|Halt|
|state|Ready|
|flag|OK|
|flag|Warning|
|flag|Alert|
|flag|Locked|
|flag|Unknown|
|arch|X86|
|arch|ARM|
|arch|Other|
|arch|Unknown|
|class|River|
|class|Mountain|
|class|Hill|

> Example responses

> 200 Response

```json
[
  {
    "id": "x0c0s22b0n0",
    "nid": 45,
    "partitionName": "p1",
    "groupLabels": [
      "group1",
      "group2"
    ]
  }
]
```

<h3 id="domembershipsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Array containing component xname IDs to their group and partition memberships.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="domembershipsget-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Membership.1.0.0](#schemamembership.1.0.0)]|false|none|[A membership is a mapping of a component xname to its set of group labels and partition names.]|
|» id|[XName.1.0.0](#schemaxname.1.0.0)|false|read-only|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.|
|» partitionName|string|false|none|The name is a human-readable identifier for the partition and uniquely identifies it.|
|» groupLabels|[string]|false|none|An array with all group labels the component is associated with The label is the human-readable identifier for a group and uniquely identifies it.|

<aside class="success">
This operation does not require authentication
</aside>

## doMembershipGet

<a id="opIddoMembershipGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/memberships/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/memberships/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/memberships/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/memberships/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /memberships/{xname}`

*Retrieve membership for component {xname}*

Display group labels and partition names for a given component xname ID.

<h3 id="domembershipget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Component xname ID (i.e. locational identifier)|

> Example responses

> 200 Response

```json
{
  "id": "x0c0s22b0n0",
  "nid": 45,
  "partitionName": "p1",
  "groupLabels": [
    "group1",
    "group2"
  ]
}
```

<h3 id="domembershipget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Membership info for component at {xname}|[Membership.1.0.0](#schemamembership.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found - no such xname.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-discoverystatus">DiscoveryStatus</h1>

Contains status information about the discovery operation for clients to query. The discover operation returns a link or links to status objects so that a client can determine when the discovery operation is complete.

## doDiscoveryStatusGetAll

<a id="opIddoDiscoveryStatusGetAll"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/DiscoveryStatus HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/DiscoveryStatus \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/DiscoveryStatus', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/DiscoveryStatus", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/DiscoveryStatus`

*Retrieve all DiscoveryStatus entries in collection*

Retrieve all DiscoveryStatus entries as an unnamed array.

> Example responses

> 200 Response

```json
[
  {
    "ID": 0,
    "Status": "Complete",
    "LastUpdateTime": "2018-08-09 03:55:57.000000",
    "Details": null
  }
]
```

<h3 id="dodiscoverystatusgetall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Unnamed DiscoveryStatus array representing all entries in collection.|Inline|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="dodiscoverystatusgetall-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[DiscoveryStatus.1.0.0_DiscoveryStatus](#schemadiscoverystatus.1.0.0_discoverystatus)]|false|none|[Returns info on the current status of a discovery operation with the given ID returned when a Discover action is requested.]|
|» ID|number(int32)|false|read-only|The ID number of the discover operation.|
|» Status|string|false|read-only|Describes the status of the given Discover operation.|
|» LastUpdateTime|string(date-time)|false|read-only|The time that the Status field was last updated.|
|» Details|[DiscoveryStatus.1.0.0_Details](#schemadiscoverystatus.1.0.0_details)|false|none|Details accompanying a DiscoveryStatus entry.  Optional. Reserved for future use.|

#### Enumerated Values

|Property|Value|
|---|---|
|Status|NotStarted|
|Status|Pending|
|Status|InProgress|
|Status|Complete|

<aside class="success">
This operation does not require authentication
</aside>

## doDiscoveryStatusGet

<a id="opIddoDiscoveryStatusGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Inventory/DiscoveryStatus/{id} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Inventory/DiscoveryStatus/{id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Inventory/DiscoveryStatus/{id}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Inventory/DiscoveryStatus/{id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Inventory/DiscoveryStatus/{id}`

*Retrieve DiscoveryStatus entry matching {id}*

Retrieve DiscoveryStatus entry with the specific ID.

<h3 id="dodiscoverystatusget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|path|number(int32)|true|Positive integer ID of DiscoveryStatus entry to retrieve|

> Example responses

> 200 Response

```json
{
  "ID": 0,
  "Status": "Complete",
  "LastUpdateTime": "2018-08-09 03:55:57.000000",
  "Details": null
}
```

<h3 id="dodiscoverystatusget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success.  Returns matching DiscoveryStatus entry.|[DiscoveryStatus.1.0.0_DiscoveryStatus](#schemadiscoverystatus.1.0.0_discoverystatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request, e.g. not a positive integer|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found (no such ID)|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-discover">Discover</h1>

Trigger a discovery of system component data by interrogating all, or a subset, of the RedfishEndpoints currently known to the system.

## doInventoryDiscoverPost

<a id="opIddoInventoryDiscoverPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/Inventory/Discover HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/Inventory/Discover \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/Inventory/Discover', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/Inventory/Discover", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /Inventory/Discover`

*Create Discover operation request*

Discover and populate database with component data (ComponentEndpoints, HMS Components, HWInventory) based on interrogating RedfishEndpoint entries.  If not all RedfishEndpoints should be discovered, an array of xnames can be provided in the DiscoverInput payload.

> Body parameter

```json
{
  "xnames": [
    "x0c0s0b0"
  ],
  "force": false
}
```

<h3 id="doinventorydiscoverpost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[Discover.1.0.0_DiscoverInput](#schemadiscover.1.0.0_discoverinput)|false|none|

> Example responses

> Success, discovery started.  DiscoverStatus link(s) to check in returned URI array.

```json
[
  {
    "URI": "/hsm/v2/Inventory/DiscoveryStatus/0"
  }
]
```

> 200 Response

```json
[
  {
    "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
  }
]
```

<h3 id="doinventorydiscoverpost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success, discovery started.  DiscoverStatus link(s) to check in returned URI array.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|One or more requested RedfishEndpoint xname IDs was not found.|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict.  One or more DiscoveryStatus objects is InProgress or Pending and prevents this operation from starting. Try again later or use force option (should never be needed unless some kind of problem has occurred).  Simultaneous discoveries could cause one or both to fail.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<h3 id="doinventorydiscoverpost-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|none|[A ResourceURI is like an odata.id, it provides a path to a resource from the API root, such that when a GET is performed, the corresponding object is returned.  It does not imply other odata functionality.]|
|» ResourceURI|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-scn">SCN</h1>

Manage subscriptions to state change notifications (SCNs) from HSM.

## doPostSCNSubscription

<a id="opIddoPostSCNSubscription"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/Subscriptions/SCN HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/Subscriptions/SCN \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/Subscriptions/SCN', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/Subscriptions/SCN", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /Subscriptions/SCN`

*Create a subscription for state change notifications*

Request a subscription for state change notifications for a set of component states. This will create a new subscription and produce a unique ID for the subscription. This will not affect the existing subscriptions.

> Body parameter

```json
{
  "Subscriber": "scnfd@sms02.cray.com",
  "Enabled": true,
  "Roles": [
    "Compute"
  ],
  "SubRoles": [
    "Worker"
  ],
  "SoftwareStatus": [
    "string"
  ],
  "States": [
    "Ready"
  ],
  "Url": "https://sms02.cray.com:27000/scnfd/v1/scn"
}
```

<h3 id="dopostscnsubscription-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[Subscriptions_SCNPostSubscription](#schemasubscriptions_scnpostsubscription)|true|none|

> Example responses

> 200 Response

```json
{
  "ID": "42",
  "Subscriber": "scnfd@sms02.cray.com",
  "Enabled": true,
  "Roles": [
    "Compute"
  ],
  "SubRoles": [
    "Worker"
  ],
  "SoftwareStatus": [
    "string"
  ],
  "States": [
    "Ready"
  ],
  "Url": "https://sms02.cray.com:27000/scnfd/v1/scn"
}
```

<h3 id="dopostscnsubscription-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A new subscription was created. The subscription ID is included in the response.|[Subscriptions_SCNSubscriptionArrayItem.1.0.0](#schemasubscriptions_scnsubscriptionarrayitem.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request. Malformed JSON. Verify all JSON formatting in payload.|[Problem7807](#schemaproblem7807)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|The subscription already exists for the specified subscriber and URL.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doDeleteSCNSubscriptionsAll

<a id="opIddoDeleteSCNSubscriptionsAll"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Subscriptions/SCN HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Subscriptions/SCN \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Subscriptions/SCN', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Subscriptions/SCN", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Subscriptions/SCN`

*Delete all state change notification subscriptions*

Delete all subscriptions.

> Example responses

> 500 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="dodeletescnsubscriptionsall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success. Subscriptions deleted successfully.|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doGetSCNSubscriptionsAll

<a id="opIddoGetSCNSubscriptionsAll"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Subscriptions/SCN HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Subscriptions/SCN \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Subscriptions/SCN', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Subscriptions/SCN", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Subscriptions/SCN`

*Retrieve currently-held state change notification subscriptions*

Retrieve all information on currently held state change notification subscriptions.

> Example responses

> 200 Response

```json
{
  "SubscriptionList": [
    {
      "ID": "42",
      "Subscriber": "scnfd@sms02.cray.com",
      "Enabled": true,
      "Roles": [
        "Compute"
      ],
      "SubRoles": [
        "Worker"
      ],
      "SoftwareStatus": [
        "string"
      ],
      "States": [
        "Ready"
      ],
      "Url": "https://sms02.cray.com:27000/scnfd/v1/scn"
    }
  ]
}
```

<h3 id="dogetscnsubscriptionsall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success. Currently held subscriptions are returned.|[Subscriptions_SCNSubscriptionArray](#schemasubscriptions_scnsubscriptionarray)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPutSCNSubscription

<a id="opIddoPutSCNSubscription"></a>

> Code samples

```http
PUT https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id}', headers = headers)

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
    req, err := http.NewRequest("PUT", "https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /Subscriptions/SCN/{id}`

*Update a subscription for state change notifications*

Update an existing state change notification subscription in whole. This will overwrite the specified subscription.

> Body parameter

```json
{
  "Subscriber": "scnfd@sms02.cray.com",
  "Enabled": true,
  "Roles": [
    "Compute"
  ],
  "SubRoles": [
    "Worker"
  ],
  "SoftwareStatus": [
    "string"
  ],
  "States": [
    "Ready"
  ],
  "Url": "https://sms02.cray.com:27000/scnfd/v1/scn"
}
```

<h3 id="doputscnsubscription-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|path|string|true|This is the ID associated with the subscription that was generated at its creation.|
|body|body|[Subscriptions_SCNPostSubscription](#schemasubscriptions_scnpostsubscription)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="doputscnsubscription-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success. The subscription has been overwritten.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request. Malformed JSON. Verify all JSON formatting in payload.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The subscription does not exist.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPatchSCNSubscription

<a id="opIddoPatchSCNSubscription"></a>

> Code samples

```http
PATCH https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id}', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /Subscriptions/SCN/{id}`

*Update a subscription for state change notifications*

Update a subscription for state change notifications to add or remove triggers.

> Body parameter

```json
{
  "Op": "add",
  "Enabled": true,
  "Roles": [
    "Compute"
  ],
  "SubRoles": [
    "Worker"
  ],
  "SoftwareStatus": [
    "string"
  ],
  "States": [
    "Ready"
  ]
}
```

<h3 id="dopatchscnsubscription-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|path|string|true|This is the ID associated with the subscription that was generated at its creation.|
|body|body|[Subscriptions_SCNPatchSubscription](#schemasubscriptions_scnpatchsubscription)|true|none|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="dopatchscnsubscription-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request. Malformed JSON. Verify all JSON formatting in payload.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error. Database error.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doDeleteSCNSubscription

<a id="opIddoDeleteSCNSubscription"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /Subscriptions/SCN/{id}`

*Delete a state change notification subscription*

Delete a state change notification subscription.

<h3 id="dodeletescnsubscription-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|path|string|true|This is the ID associated with the subscription that was generated at its creation.|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="dodeletescnsubscription-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success. Subscription deleted successfully.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doGetSCNSubscription

<a id="opIddoGetSCNSubscription"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/Subscriptions/SCN/{id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /Subscriptions/SCN/{id}`

*Retrieve a currently-held state change notification subscription*

Return the information on a currently held state change notification subscription

<h3 id="dogetscnsubscription-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|path|string|true|This is the ID associated with the subscription that was generated at its creation.|

> Example responses

> 200 Response

```json
{
  "Subscriber": "scnfd@sms02.cray.com",
  "Enabled": true,
  "Roles": [
    "Compute"
  ],
  "SubRoles": [
    "Worker"
  ],
  "SoftwareStatus": [
    "string"
  ],
  "States": [
    "Ready"
  ],
  "Url": "https://sms02.cray.com:27000/scnfd/v1/scn"
}
```

<h3 id="dogetscnsubscription-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success. A currently held subscription is returned.|[Subscriptions_SCNPostSubscription](#schemasubscriptions_scnpostsubscription)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-locking">Locking</h1>

Manage locks and reservations on components.

## post__locks_reservations_remove

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/reservations/remove HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/reservations/remove \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/reservations/remove', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/reservations/remove", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/reservations/remove`

*Forcibly deletes existing reservations.*

Given a list of components, forcibly deletes any existing reservation. Does not change lock state; does not disable the reservation ability of the component. An empty set of xnames will delete reservations on all xnames. This functionality should be used sparingly, the normal flow should be to release reservations, versus removing them.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid"
}
```

<h3 id="post__locks_reservations_remove-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminReservationRemove.1.0.0](#schemaadminreservationremove.1.0.0)|true|List of xnames to remove reservations. A `rigid` processing model will result in the entire set of xnames not having their reservation removed if an xname doesn't exist, or isn't reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_reservations_remove-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted. Returns a count + list of xnames that succeeded or failed the operation.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure received. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_reservations_release

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/reservations/release HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/reservations/release \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/reservations/release', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/reservations/release", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/reservations/release`

*Releases existing reservations.*

Given a list of {xname & reservation key}, releases the associated reservations.

> Body parameter

```json
{
  "ReservationKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ],
  "ProcessingModel": "rigid"
}
```

<h3 id="post__locks_reservations_release-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ReservedKeys.1.0.0](#schemareservedkeys.1.0.0)|true|List of {xname and reservation key} to release reservations. A `rigid` processing model will result in the entire set of xnames not having their reservation released if an xname doesn't exist, or isn't reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_reservations_release-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted. Returns a count + list of xnames that succeeded or failed the operation.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure received. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_reservations

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/reservations HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/reservations \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/reservations', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/reservations", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/reservations`

*Create reservations*

Creates reservations on a set of xnames of infinite duration.  Component must be locked to create a reservation.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid"
}
```

<h3 id="post__locks_reservations-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminReservationCreate.1.0.0](#schemaadminreservationcreate.1.0.0)|true|List of components to create reservations. A `rigid` processing model will result in the entire set of xnames not having reservations created if an xname doesn't exist, or isn't locked, or if already reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "string",
      "ReservationKey": "string"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_reservations-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted request.  See response for details.|[AdminReservationCreate_Response.1.0.0](#schemaadminreservationcreate_response.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure received. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not accept reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_service_reservations_release

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/service/reservations/release HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/service/reservations/release \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/service/reservations/release', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/service/reservations/release", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/service/reservations/release`

*Releases existing reservations.*

Given a list of {xname & reservation key}, releases the associated reservations.

> Body parameter

```json
{
  "ReservationKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ],
  "ProcessingModel": "rigid"
}
```

<h3 id="post__locks_service_reservations_release-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ReservedKeys.1.0.0](#schemareservedkeys.1.0.0)|true|List of {xname and reservation key} to release reservations. A `rigid` processing model will result in the entire set of xnames not having their reservation released if an xname doesn't exist, or isn't reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_service_reservations_release-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted. Returns a count + list of xnames that succeeded or failed the operation.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure received. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_service_reservations

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/service/reservations HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/service/reservations \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/service/reservations', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/service/reservations", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/service/reservations`

*Create reservations*

Creates reservations on a set of xnames of finite duration.  Component must be unlocked to create a reservation.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "ReservationDuration": 1
}
```

<h3 id="post__locks_service_reservations-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ServiceReservationCreate.1.0.0](#schemaservicereservationcreate.1.0.0)|true|List of components to create reservations. A `rigid` processing model will result in the entire set of xnames not having reservations created if an xname doesn't exist, or isn't locked, or if already reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "string",
      "ReservationKey": "string",
      "ExpirationTime": "2019-08-24T14:15:22Z"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_service_reservations-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted request.  See response for details.|[ServiceReservationCreate_Response.1.0.0](#schemaservicereservationcreate_response.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure received. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not accept reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_service_reservations_renew

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/service/reservations/renew HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/service/reservations/renew \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/service/reservations/renew', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/service/reservations/renew", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/service/reservations/renew`

*Renew existing reservations.*

Given a list of {xname & reservation key}, renews the associated reservations.

> Body parameter

```json
{
  "ReservationKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ],
  "ProcessingModel": "rigid",
  "ReservationDuration": 1
}
```

<h3 id="post__locks_service_reservations_renew-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ReservedKeysWithRenewal.1.0.0](#schemareservedkeyswithrenewal.1.0.0)|true|List of {xname and reservation key} to renew reservations. A `rigid` processing model will result in the entire set of xnames not having their reservation renewed if an xname doesn't exist, or isn't reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_service_reservations_renew-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted. Returns a count + list of xnames that succeeded or failed the operation.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure received. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_service_reservations_check

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/service/reservations/check HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/service/reservations/check \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/service/reservations/check', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/service/reservations/check", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/service/reservations/check`

*Check the validity of reservations.*

Using xname + reservation key check on the validity of reservations.

> Body parameter

```json
{
  "DeputyKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ]
}
```

<h3 id="post__locks_service_reservations_check-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[DeputyKeys.1.0.0](#schemadeputykeys.1.0.0)|true|List of components & deputy keys to check on validity of reservations.|

> Example responses

> 202 Response

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "string",
      "ExpirationTime": "2019-08-24T14:15:22Z"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_service_reservations_check-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Created reservations.|[ServiceReservationCheck_Response.1.0.0](#schemaservicereservationcheck_response.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not check reservations.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_status

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/status HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/status \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/status', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/status`

*Retrieve lock status for component IDs.*

Using component ID retrieve the status of any lock and/or reservation.

> Body parameter

```json
{
  "ComponentIDs": [
    "string"
  ]
}
```

<h3 id="post__locks_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[Xnames](#schemaxnames)|true|List of components to retrieve status.|

> Example responses

> 200 Response

```json
{
  "Components": [
    {
      "ID": "x1001c0s0b0",
      "Locked": false,
      "Reserved": true,
      "CreatedTime": "2019-08-24T14:15:22Z",
      "ExpirationTime": "2019-08-24T14:15:22Z",
      "ReservationDisabled": false
    }
  ],
  "NotFound": [
    "x1000c0s0b0"
  ]
}
```

<h3 id="post__locks_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Got lock(s) status.|[AdminStatusCheck_Response.1.0.0](#schemaadminstatuscheck_response.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not get lock status.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__locks_status

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/locks/status HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/locks/status \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/locks/status', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/locks/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /locks/status`

*Retrieve lock status for all components or a filtered subset of components.*

Retrieve the status of all component locks and/or reservations. Results can be filtered by query parameters.

<h3 id="get__locks_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|type|query|string|false|Filter the results based on HMS type like Node, NodeEnclosure, NodeBMC etc. Can be specified multiple times for selecting entries of multiple types.|
|state|query|string|false|Filter the results based on HMS state like Ready, On etc. Can be specified multiple times for selecting entries in different states.|
|role|query|string|false|Filter the results based on HMS role. Can be specified multiple times for selecting entries with different roles. Valid values are:|
|subrole|query|string|false|Filter the results based on HMS subrole. Can be specified multiple times for selecting entries with different subroles. Valid values are:|
|locked|query|boolean|false|Return components based on the 'Locked' field of their lock status.|
|reserved|query|boolean|false|Return components based on the 'Reserved' field of their lock status.|
|reservationDisabled|query|boolean|false|Return components based on the 'ReservationDisabled' field of their lock status.|

#### Detailed descriptions

**role**: Filter the results based on HMS role. Can be specified multiple times for selecting entries with different roles. Valid values are:
- Compute
- Service
- System
- Application
- Storage
- Management
Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.

**subrole**: Filter the results based on HMS subrole. Can be specified multiple times for selecting entries with different subroles. Valid values are:
- Master
- Worker
- Storage
Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.

#### Enumerated Values

|Parameter|Value|
|---|---|
|type|CDU|
|type|CabinetCDU|
|type|CabinetPDU|
|type|CabinetPDUOutlet|
|type|CabinetPDUPowerConnector|
|type|CabinetPDUController|
|type|Cabinet|
|type|Chassis|
|type|ChassisBMC|
|type|CMMRectifier|
|type|CMMFpga|
|type|CEC|
|type|ComputeModule|
|type|RouterModule|
|type|NodeBMC|
|type|NodeEnclosure|
|type|NodeEnclosurePowerSupply|
|type|HSNBoard|
|type|MgmtSwitch|
|type|MgmtHLSwitch|
|type|CDUMgmtSwitch|
|type|Node|
|type|Processor|
|type|Drive|
|type|StorageGroup|
|type|NodeNIC|
|type|Memory|
|type|NodeAccel|
|type|NodeAccelRiser|
|type|NodeFpga|
|type|HSNAsic|
|type|RouterFpga|
|type|RouterBMC|
|type|HSNLink|
|type|HSNConnector|
|type|INVALID|
|state|Unknown|
|state|Empty|
|state|Populated|
|state|Off|
|state|On|
|state|Standby|
|state|Halt|
|state|Ready|

> Example responses

> 200 Response

```json
{
  "Components": [
    {
      "ID": "x1001c0s0b0",
      "Locked": false,
      "Reserved": true,
      "CreatedTime": "2019-08-24T14:15:22Z",
      "ExpirationTime": "2019-08-24T14:15:22Z",
      "ReservationDisabled": false
    }
  ],
  "NotFound": [
    "x1000c0s0b0"
  ]
}
```

<h3 id="get__locks_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Got lock(s) status.|[AdminStatusCheck_Response.1.0.0](#schemaadminstatuscheck_response.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not get lock status.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_lock

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/lock HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/lock \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/lock', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/lock", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/lock`

*Locks components.*

Using a component create a lock.  Cannot be locked if already locked, or if there is a current reservation.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid"
}
```

<h3 id="post__locks_lock-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminLock.1.0.0](#schemaadminlock.1.0.0)|true|List of xnames to lock.|

> Example responses

> 200 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_lock-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries locked. Message contains count of locked items.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not lock lock.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_unlock

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/unlock HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/unlock \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/unlock', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/unlock", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/unlock`

*Unlocks components.*

Using a component unlock a lock.  Cannot be unlocked if already unlocked.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid"
}
```

<h3 id="post__locks_unlock-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminLock.1.0.0](#schemaadminlock.1.0.0)|true|List of xnames to unlock.|

> Example responses

> 200 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_unlock-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries unlocked. Message contains count of unlocked locks.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not unlock lock.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_repair

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/repair HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/repair \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/repair', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/repair", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/repair`

*Repair components lock and reservation ability.*

Repairs the disabled status of an xname allowing new reservations to be created.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid"
}
```

<h3 id="post__locks_repair-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminLock.1.0.0](#schemaadminlock.1.0.0)|true|List of xnames to repair.|

> Example responses

> 200 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_repair-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more locks repaired. Message contains count of repaired locks.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not repair lock.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_disable

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/locks/disable HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/locks/disable \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/locks/disable', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/locks/disable", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/disable`

*Disables the ability to create a reservation on components.*

Disables the ability to create a reservation on components, deletes any existing reservations. Does not change lock state. Attempting to disable an already-disabled component will not result in an error.

> Body parameter

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid"
}
```

<h3 id="post__locks_disable-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminLock.1.0.0](#schemaadminlock.1.0.0)|true|List of xnames to disable.|

> Example responses

> 200 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

<h3 id="post__locks_disable-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more locks disabled. Message contains count of disabled locks.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not disable lock.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hardware-state-manager-api-powermap">PowerMap</h1>

Power mapping of components to the components supplying them power. This may contain components in the system whether populated or not.

## doPowerMapsGet

<a id="opIddoPowerMapsGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/sysinfo/powermaps HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/sysinfo/powermaps \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/sysinfo/powermaps', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/sysinfo/powermaps", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /sysinfo/powermaps`

*Retrieve all PowerMaps, returning PowerMapArray*

Retrieve all power map entries as a named array, or an empty array if the collection is empty.

> Example responses

> 200 Response

```json
[
  {
    "id": "x0c0s1b0n0",
    "poweredBy": [
      "x0m0p0j10",
      "x0m0p0j11"
    ]
  }
]
```

<h3 id="dopowermapsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Named PowerMaps array.|[PowerMapArray_PowerMapArray](#schemapowermaparray_powermaparray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPowerMapsPost

<a id="opIddoPowerMapsPost"></a>

> Code samples

```http
POST https://sms/apis/smd/hsm/v2/sysinfo/powermaps HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://sms/apis/smd/hsm/v2/sysinfo/powermaps \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://sms/apis/smd/hsm/v2/sysinfo/powermaps', headers = headers)

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
    req, err := http.NewRequest("POST", "https://sms/apis/smd/hsm/v2/sysinfo/powermaps", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /sysinfo/powermaps`

*Create or Modify PowerMaps*

Create or update the given set of PowerMaps whose ID fields are each a valid xname. The poweredBy field is required.

> Body parameter

```json
[
  {
    "id": "x0c0s1b0n0",
    "poweredBy": [
      "x0m0p0j10",
      "x0m0p0j11"
    ]
  }
]
```

<h3 id="dopowermapspost-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[PowerMapArray_PowerMapArray](#schemapowermaparray_powermaparray)|true|none|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dopowermapspost-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries created or updated.  Message contains count of new/modified items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPowerMapsDeleteAll

<a id="opIddoPowerMapsDeleteAll"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/sysinfo/powermaps HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/sysinfo/powermaps \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/sysinfo/powermaps', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/sysinfo/powermaps", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /sysinfo/powermaps`

*Delete all PowerMap entities*

Delete all entries in the PowerMaps collection.

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dopowermapsdeleteall-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries deleted. Message contains count of deleted items.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Collection is empty|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPowerMapGet

<a id="opIddoPowerMapGet"></a>

> Code samples

```http
GET https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /sysinfo/powermaps/{xname}`

*Retrieve PowerMap at {xname}*

Retrieve PowerMap for a component located at physical location {xname}.

<h3 id="dopowermapget-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of PowerMap record to return.|

> Example responses

> 200 Response

```json
{
  "id": "x0c0s1b0n0",
  "poweredBy": [
    "x0m0p0j10",
    "x0m0p0j11"
  ]
}
```

<h3 id="dopowermapget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|PowerMap entry matching xname/ID|[PowerMap.1.0.0_PowerMap](#schemapowermap.1.0.0_powermap)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPowerMapDelete

<a id="opIddoPowerMapDelete"></a>

> Code samples

```http
DELETE https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname} HTTP/1.1
Host: sms
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /sysinfo/powermaps/{xname}`

*Delete PowerMap with ID {xname}*

Delete PowerMap entry for a specific component {xname}.

<h3 id="dopowermapdelete-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of PowerMap record to delete.|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dopowermapdelete-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - PowerMap is deleted.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|XName does Not Exist - no matching ID to delete|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doPowerMapPut

<a id="opIddoPowerMapPut"></a>

> Code samples

```http
PUT https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname} HTTP/1.1
Host: sms
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname}', headers = headers)

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
    req, err := http.NewRequest("PUT", "https://sms/apis/smd/hsm/v2/sysinfo/powermaps/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /sysinfo/powermaps/{xname}`

*Update definition for PowerMap ID {xname}*

Update or create an entry for an individual component xname using PUT. If the PUT operation contains an xname that already exists, the entry will be overwritten with the new entry.

> Body parameter

```json
{
  "id": "x0c0s1b0n0",
  "poweredBy": [
    "x0m0p0j10",
    "x0m0p0j11"
  ]
}
```

<h3 id="dopowermapput-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|Locational xname of PowerMap record to create or update.|
|body|body|[PowerMap.1.0.0_PowerMap](#schemapowermap.1.0.0_powermap)|true|none|

> Example responses

> 200 Response

```json
{
  "code": "string",
  "message": "string"
}
```

<h3 id="dopowermapput-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - PowerMap was created/updated.|[Response_1.0.0](#schemaresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_Component.1.0.0_Component">Component.1.0.0_Component</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_component"></a>
<a id="schema_Component.1.0.0_Component"></a>
<a id="tocScomponent.1.0.0_component"></a>
<a id="tocscomponent.1.0.0_component"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "State": "Ready",
  "Flag": "OK",
  "Enabled": true,
  "SoftwareStatus": "string",
  "Role": "Compute",
  "SubRole": "Worker",
  "NID": 1,
  "Subtype": "string",
  "NetType": "Sling",
  "Arch": "X86",
  "Class": "River",
  "ReservationDisabled": false,
  "Locked": false
}

```

This is the logical representation of a component for which state is tracked and includes other variables that may be needed by clients. It is keyed by the physical location i.e. xname.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[XName.1.0.0](#schemaxname.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.|
|Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|none|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|State|[HMSState.1.0.0](#schemahmsstate.1.0.0)|false|none|This property indicates the state of the underlying component.|
|Flag|[HMSFlag.1.0.0](#schemahmsflag.1.0.0)|false|none|This property indicates the state flag of the underlying component.|
|Enabled|boolean|false|none|Whether component is enabled. True when enabled, false when disabled.|
|SoftwareStatus|string|false|none|SoftwareStatus of a node, used by the managed plane for running nodes.  Will be missing for other component types or if not set by software.|
|Role|[HMSRole.1.0.0](#schemahmsrole.1.0.0)|false|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|SubRole|[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.|
|NID|integer|false|none|This is the integer Node ID if the component is a node.|
|Subtype|string|false|read-only|Further distinguishes between components of same type.|
|NetType|[NetType.1.0.0](#schemanettype.1.0.0)|false|none|This is the type of high speed network the component is connected to, if it is an applicable component type and the interface is present, or the type of the system HSN.|
|Arch|[HMSArch.1.0.0](#schemahmsarch.1.0.0)|false|none|This is the basic architecture of the component so the proper software can be selected and so on.|
|Class|[HMSClass.1.0.0](#schemahmsclass.1.0.0)|false|none|This is the HSM hardware class of the component.|
|ReservationDisabled|boolean|false|read-only|Whether component can be reserved via the locking API. True when reservations are disabled, thus no new reservations can be created on this component.|
|Locked|boolean|false|read-only|Whether a component is locked via the locking API.|

<h2 id="tocS_Component.1.0.0_ComponentCreate">Component.1.0.0_ComponentCreate</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_componentcreate"></a>
<a id="schema_Component.1.0.0_ComponentCreate"></a>
<a id="tocScomponent.1.0.0_componentcreate"></a>
<a id="tocscomponent.1.0.0_componentcreate"></a>

```json
{
  "ID": "x0c0s1b0n0",
  "State": "Ready",
  "Flag": "OK",
  "Enabled": true,
  "SoftwareStatus": "string",
  "Role": "Compute",
  "SubRole": "Worker",
  "NID": 1,
  "Subtype": "string",
  "NetType": "Sling",
  "Arch": "X86",
  "Class": "River"
}

```

This is the logical representation of a component for which state is tracked and includes other variables that may be needed by clients. It is keyed by the physical location i.e. xname.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[XNameRW.1.0.0](#schemaxnamerw.1.0.0)|true|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is the non-readOnly version for writable component lists.|
|State|[HMSState.1.0.0](#schemahmsstate.1.0.0)|true|none|This property indicates the state of the underlying component.|
|Flag|[HMSFlag.1.0.0](#schemahmsflag.1.0.0)|false|none|This property indicates the state flag of the underlying component.|
|Enabled|boolean|false|none|Whether component is enabled. True when enabled, false when disabled.|
|SoftwareStatus|string|false|none|SoftwareStatus of a node, used by the managed plane for running nodes.  Will be missing for other component types or if not set by software.|
|Role|[HMSRole.1.0.0](#schemahmsrole.1.0.0)|false|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|SubRole|[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.|
|NID|integer|false|none|This is the integer Node ID if the component is a node.|
|Subtype|string|false|none|Further distinguishes between components of same type.|
|NetType|[NetType.1.0.0](#schemanettype.1.0.0)|false|none|This is the type of high speed network the component is connected to, if it is an applicable component type and the interface is present, or the type of the system HSN.|
|Arch|[HMSArch.1.0.0](#schemahmsarch.1.0.0)|false|none|This is the basic architecture of the component so the proper software can be selected and so on.|
|Class|[HMSClass.1.0.0](#schemahmsclass.1.0.0)|false|none|This is the HSM hardware class of the component.|

<h2 id="tocS_Component.1.0.0_Put">Component.1.0.0_Put</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_put"></a>
<a id="schema_Component.1.0.0_Put"></a>
<a id="tocScomponent.1.0.0_put"></a>
<a id="tocscomponent.1.0.0_put"></a>

```json
{
  "Component": {
    "ID": "x0c0s1b0n0",
    "State": "Ready",
    "Flag": "OK",
    "Enabled": true,
    "SoftwareStatus": "string",
    "Role": "Compute",
    "SubRole": "Worker",
    "NID": 1,
    "Subtype": "string",
    "NetType": "Sling",
    "Arch": "X86",
    "Class": "River"
  },
  "Force": true
}

```

This is the payload of a state components URI put operation on a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Component|[Component.1.0.0_ComponentCreate](#schemacomponent.1.0.0_componentcreate)|true|none|This is the logical representation of a component for which state is tracked and includes other variables that may be needed by clients. It is keyed by the physical location i.e. xname.|
|Force|boolean|false|none|If true, 'force' causes this operation to overwrite the 'State', 'Flag', 'Subtype', 'NetType', and 'Arch' fields for the specified component if it already exists. Otherwise, nothing will be overwritten.|

<h2 id="tocS_Component.1.0.0_Patch.StateData">Component.1.0.0_Patch.StateData</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_patch.statedata"></a>
<a id="schema_Component.1.0.0_Patch.StateData"></a>
<a id="tocScomponent.1.0.0_patch.statedata"></a>
<a id="tocscomponent.1.0.0_patch.statedata"></a>

```json
{
  "State": "Ready",
  "Flag": "OK",
  "Force": false,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is the payload of a StateData URI patch operation on a component. Flag ID optional and will be reset to OK if no Flag value is given.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|State|[HMSState.1.0.0](#schemahmsstate.1.0.0)|true|none|This property indicates the state of the underlying component.|
|Flag|[HMSFlag.1.0.0](#schemahmsflag.1.0.0)|false|none|This property indicates the state flag of the underlying component.|
|Force|boolean|false|none|If the state change is normally prohibited, due to the current and new states, force the change anyways.  Default is false.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_Component.1.0.0_Patch.FlagOnly">Component.1.0.0_Patch.FlagOnly</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_patch.flagonly"></a>
<a id="schema_Component.1.0.0_Patch.FlagOnly"></a>
<a id="tocScomponent.1.0.0_patch.flagonly"></a>
<a id="tocscomponent.1.0.0_patch.flagonly"></a>

```json
{
  "Flag": "OK",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is the payload of a FlagOnly patch operation on a component. Flag is required and the State field is unmodified regardless of the value given.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Flag|[HMSFlag.1.0.0](#schemahmsflag.1.0.0)|true|none|This property indicates the state flag of the underlying component.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_Component.1.0.0_Patch.Enabled">Component.1.0.0_Patch.Enabled</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_patch.enabled"></a>
<a id="schema_Component.1.0.0_Patch.Enabled"></a>
<a id="tocScomponent.1.0.0_patch.enabled"></a>
<a id="tocscomponent.1.0.0_patch.enabled"></a>

```json
{
  "Enabled": true,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is the payload of a Enabled patch operation on a Component. Enabled is required, and is a boolean field with true representing enabled and false disabled.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Enabled|boolean|true|none|Component Enabled(true)/Disabled(false) flag|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_Component.1.0.0_Patch.SoftwareStatus">Component.1.0.0_Patch.SoftwareStatus</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_patch.softwarestatus"></a>
<a id="schema_Component.1.0.0_Patch.SoftwareStatus"></a>
<a id="tocScomponent.1.0.0_patch.softwarestatus"></a>
<a id="tocscomponent.1.0.0_patch.softwarestatus"></a>

```json
{
  "SoftwareStatus": "string",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is the payload of a SoftwareStatus patch operation on a Component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|SoftwareStatus|string|false|none|Component/node software status field, reserved for managed plane.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_Component.1.0.0_Patch.Role">Component.1.0.0_Patch.Role</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_patch.role"></a>
<a id="schema_Component.1.0.0_Patch.Role"></a>
<a id="tocScomponent.1.0.0_patch.role"></a>
<a id="tocscomponent.1.0.0_patch.role"></a>

```json
{
  "Role": "Compute",
  "SubRole": "Worker",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is the payload of a Role patch operation on a Component. Role is required, however operation will fail if Role is not a supported property of the corresponding HMS type.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Role|[HMSRole.1.0.0](#schemahmsrole.1.0.0)|true|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|SubRole|[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_Component.1.0.0_Patch.NID">Component.1.0.0_Patch.NID</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_patch.nid"></a>
<a id="schema_Component.1.0.0_Patch.NID"></a>
<a id="tocScomponent.1.0.0_patch.nid"></a>
<a id="tocscomponent.1.0.0_patch.nid"></a>

```json
{
  "NID": 0,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is the payload of a NID patch operation on a Component. NID is required but the operation will fail if NID is not a valid

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|NID|integer|true|none|This is the integer Node ID if the component is a node.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_Component.1.0.0_PatchArrayItem.NID">Component.1.0.0_PatchArrayItem.NID</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_patcharrayitem.nid"></a>
<a id="schema_Component.1.0.0_PatchArrayItem.NID"></a>
<a id="tocScomponent.1.0.0_patcharrayitem.nid"></a>
<a id="tocscomponent.1.0.0_patcharrayitem.nid"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "NID": 0,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is one entry in a NID patch operation on an entire ComponentArray.  ID and NID are required or the operation will fail. Only the NID field is updated, and then only if it is appropriate for the corresponding HMS type of the entry (e.g. node).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)|true|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is identical to XName except that it is not read-only which would prevent it from being a required parameter in query operations in Swagger 2.0.  These operations do not actually write the XName, merely using at a selector to do bulk writes of multiple records, so this is fine.|
|Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|none|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|NID|integer|true|none|This is the integer Node ID if the component is a node.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_Component.1.0.0_ResourceURICollection">Component.1.0.0_ResourceURICollection</h2>
<!-- backwards compatibility -->
<a id="schemacomponent.1.0.0_resourceuricollection"></a>
<a id="schema_Component.1.0.0_ResourceURICollection"></a>
<a id="tocScomponent.1.0.0_resourceuricollection"></a>
<a id="tocscomponent.1.0.0_resourceuricollection"></a>

```json
{
  "Name": "(Type of Object) Collection",
  "Members": [
    {
      "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
    }
  ],
  "MemberCount": 0
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|Should describe the collection, though the type of resources the links correspond to should also be inferred from the context in which the collection was obtained.|
|Members|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|read-only|An array of ResourceIds.|
|MemberCount|number(int32)|false|read-only|Number of ResourceURIs in the collection|

<h2 id="tocS_ComponentByNID.1.0.0_ResourceURICollection">ComponentByNID.1.0.0_ResourceURICollection</h2>
<!-- backwards compatibility -->
<a id="schemacomponentbynid.1.0.0_resourceuricollection"></a>
<a id="schema_ComponentByNID.1.0.0_ResourceURICollection"></a>
<a id="tocScomponentbynid.1.0.0_resourceuricollection"></a>
<a id="tocscomponentbynid.1.0.0_resourceuricollection"></a>

```json
{
  "Name": "(Type of Object) Collection",
  "Members": [
    {
      "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
    }
  ],
  "MemberCount": 0
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|Should describe the collection, though the type of resources the links correspond to should also be inferred from the context in which the collection was obtained.|
|Members|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|read-only|An array of ResourceIds.|
|MemberCount|number(int32)|false|read-only|Number of ResourceURIs in the collection|

<h2 id="tocS_ComponentArray_ComponentArray">ComponentArray_ComponentArray</h2>
<!-- backwards compatibility -->
<a id="schemacomponentarray_componentarray"></a>
<a id="schema_ComponentArray_ComponentArray"></a>
<a id="tocScomponentarray_componentarray"></a>
<a id="tocscomponentarray_componentarray"></a>

```json
{
  "Components": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "State": "Ready",
      "Flag": "OK",
      "Enabled": true,
      "SoftwareStatus": "string",
      "Role": "Compute",
      "SubRole": "Worker",
      "NID": 1,
      "Subtype": "string",
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River",
      "ReservationDisabled": false,
      "Locked": false
    }
  ]
}

```

This is a collection of Component objects returned whenever a query is expected to result in 0 to n matches.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Components|[[Component.1.0.0_Component](#schemacomponent.1.0.0_component)]|false|none|Contains the HMS component objects in the array.|

<h2 id="tocS_ComponentArray_PostArray">ComponentArray_PostArray</h2>
<!-- backwards compatibility -->
<a id="schemacomponentarray_postarray"></a>
<a id="schema_ComponentArray_PostArray"></a>
<a id="tocScomponentarray_postarray"></a>
<a id="tocscomponentarray_postarray"></a>

```json
{
  "Components": [
    {
      "ID": "x0c0s1b0n0",
      "State": "Ready",
      "Flag": "OK",
      "Enabled": true,
      "SoftwareStatus": "string",
      "Role": "Compute",
      "SubRole": "Worker",
      "NID": 1,
      "Subtype": "string",
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River"
    }
  ],
  "Force": true
}

```

This is a component post request. Contains the new component fields to apply.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Components|[[Component.1.0.0_ComponentCreate](#schemacomponent.1.0.0_componentcreate)]|true|none|Contains the HMS component objects in the array.|
|Force|boolean|false|none|If true, 'force' causes this operation to overwrite the 'State', 'Flag', 'Subtype', 'NetType', and 'Arch' fields for the specified component if it already exists. Otherwise, nothing will be overwritten.|

<h2 id="tocS_ComponentArray_PatchArray.StateData">ComponentArray_PatchArray.StateData</h2>
<!-- backwards compatibility -->
<a id="schemacomponentarray_patcharray.statedata"></a>
<a id="schema_ComponentArray_PatchArray.StateData"></a>
<a id="tocScomponentarray_patcharray.statedata"></a>
<a id="tocscomponentarray_patcharray.statedata"></a>

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "State": "Ready",
  "Flag": "OK",
  "Force": false,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is a component state data patch request. Contains the new state to apply, new flag to apply (optional), and a list of component xnames for update. If the component flag is omitted, the flag will be reset to 'ok'.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|true|none|An array of XName/ID values for the components to update.|
|State|[HMSState.1.0.0](#schemahmsstate.1.0.0)|true|none|This property indicates the state of the underlying component.|
|Flag|[HMSFlag.1.0.0](#schemahmsflag.1.0.0)|false|none|This property indicates the state flag of the underlying component.|
|Force|boolean|false|none|If the state change is normally prohibited, due to the current and new states, force the change anyways.  Default is false.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_ComponentArray_PatchArray.FlagOnly">ComponentArray_PatchArray.FlagOnly</h2>
<!-- backwards compatibility -->
<a id="schemacomponentarray_patcharray.flagonly"></a>
<a id="schema_ComponentArray_PatchArray.FlagOnly"></a>
<a id="tocScomponentarray_patcharray.flagonly"></a>
<a id="tocscomponentarray_patcharray.flagonly"></a>

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Flag": "OK",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is a component flag value patch request. Contains the new flag to apply and a list of component xnames for update.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|true|none|An array of XName/ID values for the components to update.|
|Flag|[HMSFlag.1.0.0](#schemahmsflag.1.0.0)|true|none|This property indicates the state flag of the underlying component.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_ComponentArray_PatchArray.Enabled">ComponentArray_PatchArray.Enabled</h2>
<!-- backwards compatibility -->
<a id="schemacomponentarray_patcharray.enabled"></a>
<a id="schema_ComponentArray_PatchArray.Enabled"></a>
<a id="tocScomponentarray_patcharray.enabled"></a>
<a id="tocscomponentarray_patcharray.enabled"></a>

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Enabled": true,
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is a component Enabled field patch request. Contains the new value of enabled to apply and the list of component xnames to update.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|true|none|An array of XName/ID values for the components to update.|
|Enabled|boolean|true|none|Whether component is enabled. True when enabled, false when disabled.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_ComponentArray_PatchArray.SoftwareStatus">ComponentArray_PatchArray.SoftwareStatus</h2>
<!-- backwards compatibility -->
<a id="schemacomponentarray_patcharray.softwarestatus"></a>
<a id="schema_ComponentArray_PatchArray.SoftwareStatus"></a>
<a id="tocScomponentarray_patcharray.softwarestatus"></a>
<a id="tocscomponentarray_patcharray.softwarestatus"></a>

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "SoftwareStatus": "string",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is a component SoftwareStatus field patch request. Contains a new, single value of SoftwareStatus to apply, and the list of component xnames to update.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|true|none|An array of XName/ID values for the components to update.|
|SoftwareStatus|string|true|none|SoftwareStatus of the node, used by the managed plane for running nodes.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_ComponentArray_PatchArray.Role">ComponentArray_PatchArray.Role</h2>
<!-- backwards compatibility -->
<a id="schemacomponentarray_patcharray.role"></a>
<a id="schema_ComponentArray_PatchArray.Role"></a>
<a id="tocScomponentarray_patcharray.role"></a>
<a id="tocscomponentarray_patcharray.role"></a>

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Role": "Compute",
  "SubRole": "Worker",
  "ExtendedInfo": {
    "ID": "string",
    "Message": "string",
    "Flag": "OK"
  }
}

```

This is a component Role value patch request. Contains the new Role to apply and a list of component xnames for update.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|true|none|An array of XName/ID values for the components to update.|
|Role|[HMSRole.1.0.0](#schemahmsrole.1.0.0)|true|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|SubRole|[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.|
|ExtendedInfo|[Message_1.0.0_ExtendedInfo](#schemamessage_1.0.0_extendedinfo)|false|none|TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.|

<h2 id="tocS_ComponentArray_PatchArray.NID">ComponentArray_PatchArray.NID</h2>
<!-- backwards compatibility -->
<a id="schemacomponentarray_patcharray.nid"></a>
<a id="schema_ComponentArray_PatchArray.NID"></a>
<a id="tocScomponentarray_patcharray.nid"></a>
<a id="tocscomponentarray_patcharray.nid"></a>

```json
{
  "Name": "string",
  "Components": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "NID": 0,
      "ExtendedInfo": {
        "ID": "string",
        "Message": "string",
        "Flag": "OK"
      }
    }
  ]
}

```

This is a collection of Component objects with just the ID and NID fields populated.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|Descriptive name e.g. why it was generated.|
|Components|[[Component.1.0.0_PatchArrayItem.NID](#schemacomponent.1.0.0_patcharrayitem.nid)]|false|none|Contains the component objects in the array but with just the Component ID and the patchable fields for a NID patch operation filled in.  Other Component fields are not undated during these operations.|

<h2 id="tocS_ComponentArray_PostQuery">ComponentArray_PostQuery</h2>
<!-- backwards compatibility -->
<a id="schemacomponentarray_postquery"></a>
<a id="schema_ComponentArray_PostQuery"></a>
<a id="tocScomponentarray_postquery"></a>
<a id="tocscomponentarray_postquery"></a>

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "partition": "p1",
  "group": "group_label",
  "stateonly": true,
  "flagonly": true,
  "roleonly": true,
  "nidonly": true,
  "type": [
    "string"
  ],
  "state": [
    "string"
  ],
  "flag": [
    "string"
  ],
  "enabled": [
    "string"
  ],
  "softwarestatus": [
    "string"
  ],
  "role": [
    "string"
  ],
  "subrole": [
    "string"
  ],
  "subtype": [
    "string"
  ],
  "arch": [
    "string"
  ],
  "class": [
    "string"
  ],
  "nid": [
    "string"
  ],
  "nid_start": [
    "string"
  ],
  "nid_end": [
    "string"
  ]
}

```

There are limits to the length of an HTTP URL and query string. Hence, if we wish to query an arbitrary list of XName/IDs, it will need to be in the body of the request.  This object is used for this purpose.  It is similar to the analogous GET operation.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|false|none|An array of XName/ID values for the components to query.|
|partition|string|false|none|Partition name to filter on, as per current /partitions/names|
|group|string|false|none|Group label to filter on, as per current /groups/labels|
|stateonly|boolean|false|none|Return only component state and flag fields (plus xname/ID and type).  Results can be modified and used for bulk state/flag- only patch operations.|
|flagonly|boolean|false|none|Return only component flag field (plus xname/ID and type). Results can be modified and used for bulk flag-only patch operations.|
|roleonly|boolean|false|none|Return only component role and subrole fields (plus xname/ID and type). Results can be modified and used for bulk role-only patches.|
|nidonly|boolean|false|none|Return only component NID field (plus xname/ID and type). Results can be modified and used for bulk NID-only patches.|
|type|[string]|false|none|Retrieve all components with the given HMS type.|
|state|[string]|false|none|Retrieve all components with the given HMS state.|
|flag|[string]|false|none|Retrieve all components with the given HMS flag value.|
|enabled|[string]|false|none|Retrieve all components with the given enabled status (true or false).|
|softwarestatus|[string]|false|none|Retrieve all components with the given software status. Software status is a free form string. Matching is case-insensitive.|
|role|[string]|false|none|Retrieve all components (i.e. nodes) with the given HMS role|
|subrole|[string]|false|none|Retrieve all components (i.e. nodes) with the given HMS subrole|
|subtype|[string]|false|none|Retrieve all components with the given HMS subtype.|
|arch|[string]|false|none|Retrieve all components with the given architecture.|
|class|[string]|false|none|Retrieve all components (i.e. nodes) with the given HMS hardware class. Class can be River, Mountain, etc.|
|nid|[string]|false|none|Retrieve all components (i.e. one node) with the given integer NID|
|nid_start|[string]|false|none|Retrieve all components (i.e. nodes) with NIDs equal to or greater than the provided integer.|
|nid_end|[string]|false|none|Retrieve all components (i.e. nodes) with NIDs less than or equal to the provided integer.|

<h2 id="tocS_ComponentArray_PostByNIDQuery">ComponentArray_PostByNIDQuery</h2>
<!-- backwards compatibility -->
<a id="schemacomponentarray_postbynidquery"></a>
<a id="schema_ComponentArray_PostByNIDQuery"></a>
<a id="tocScomponentarray_postbynidquery"></a>
<a id="tocscomponentarray_postbynidquery"></a>

```json
{
  "NIDRanges": [
    "0-24"
  ],
  "partition": "p1.2",
  "stateonly": true,
  "flagonly": true,
  "roleonly": true,
  "nidonly": true
}

```

There are limits to the length of an HTTP URL and query string. Hence, if we wish to query an arbitrary list of NIDs, it will need to be in the body of the request.  This object is used for this purpose.  Parameters are similar to the analogous GET operation.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|NIDRanges|[[NIDRange.1.0.0](#schemanidrange.1.0.0)]|true|none|NID range values to query, producing a ComponentArray with the matching components, e.g. "0-24" or "2".  Add each multiple ranges as a separate array item.|
|partition|[XNamePartition.1.0.0](#schemaxnamepartition.1.0.0)|false|none|This is an ordinary xname, but one where only a partition (hard:soft) or the system alias (s0) will be expected as valid input.|
|stateonly|boolean|false|none|Return only component state and flag fields (plus xname/ID and type).  Results can be modified and used for bulk state/flag- only patch operations.|
|flagonly|boolean|false|none|Return only component flag field (plus xname/ID and type). Results can be modified and used for bulk flag-only patch operations.|
|roleonly|boolean|false|none|Return only component role and subrole fields (plus xname/ID and type). Results can be modified and used for bulk role-only patches.|
|nidonly|boolean|false|none|Return only component NID field (plus xname/ID and type). Results can be modified and used for bulk NID-only patches.|

<h2 id="tocS_NodeMap.1.0.0_NodeMap">NodeMap.1.0.0_NodeMap</h2>
<!-- backwards compatibility -->
<a id="schemanodemap.1.0.0_nodemap"></a>
<a id="schema_NodeMap.1.0.0_NodeMap"></a>
<a id="tocSnodemap.1.0.0_nodemap"></a>
<a id="tocsnodemap.1.0.0_nodemap"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "NID": 1,
  "Role": "Compute",
  "SubRole": "Worker"
}

```

NodeMaps are a way of pre-populating state manager with a set of valid node xnames (currently populated, or just potentially populated) and assigning each a default NID (and optionally also a Role and SubRole). NID is required and must be unique within the NodeMaps.
When components are first discovered, if a matching NodeMap entry is found, that NID will be used to create the component entry.  This allows NIDs to be defined in advance in an orderly way that allows NID ranges to be consecutive on the set of xnames that is actually used for a particular hardware config.  The default NIDs used if no NodeMap is present are based on enumerating NIDs for ALL POSSIBLE xnames, even though in practice only a small subset will be used for any particular hardware config (resulting in very sparse assignments).  NodeMaps, then, help avoid this.
Updating NodeMaps for already discovered components (unless they are deleted and then rediscovered) will not automatically update the NID field in States/Components.  Likewise using a patch to update NID on a particular entry in States/Components will not automatically define or update a NodeMap entry.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[XName.1.0.0](#schemaxname.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.|
|NID|integer|true|none|Positive default Node ID (NID) for the xname in ID|
|Role|[HMSRole.1.0.0](#schemahmsrole.1.0.0)|false|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|SubRole|[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.|

<h2 id="tocS_NodeMap.1.0.0_PostNodeMap">NodeMap.1.0.0_PostNodeMap</h2>
<!-- backwards compatibility -->
<a id="schemanodemap.1.0.0_postnodemap"></a>
<a id="schema_NodeMap.1.0.0_PostNodeMap"></a>
<a id="tocSnodemap.1.0.0_postnodemap"></a>
<a id="tocsnodemap.1.0.0_postnodemap"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "NID": 1,
  "Role": "Compute",
  "SubRole": "Worker"
}

```

NodeMaps are a way of pre-populating state manager with a set of valid node xnames (currently populated, or just potentially populated) and assigning each a default NID (and optionally also a Role and SubRole). NID is required and must be unique within the NodeMaps.
When components are first discovered, if a matching NodeMap entry is found, that NID will be used to create the component entry.  This allows NIDs to be defined in advance in an orderly way that allows NID ranges to be consecutive on the set of xnames that is actually used for a particular hardware config.  The default NIDs used if no NodeMap is present are based on enumerating NIDs for ALL POSSIBLE xnames, even though in practice only a small subset will be used for any particular hardware config (resulting in very sparse assignments).  NodeMaps, then, help avoid this.
Updating NodeMaps for already discovered components (unless they are deleted and then rediscovered) will not automatically update the NID field in States/Components.  Likewise using a patch to update NID on a particular entry in States/Components will not automatically define or update a NodeMap entry.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)|true|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is identical to XName except that it is not read-only which would prevent it from being a required parameter in query operations in Swagger 2.0.  These operations do not actually write the XName, merely using at a selector to do bulk writes of multiple records, so this is fine.|
|NID|integer|true|none|Positive default Node ID (NID) for the xname in ID|
|Role|[HMSRole.1.0.0](#schemahmsrole.1.0.0)|false|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|SubRole|[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.|

<h2 id="tocS_NodeMapArray_NodeMapArray">NodeMapArray_NodeMapArray</h2>
<!-- backwards compatibility -->
<a id="schemanodemaparray_nodemaparray"></a>
<a id="schema_NodeMapArray_NodeMapArray"></a>
<a id="tocSnodemaparray_nodemaparray"></a>
<a id="tocsnodemaparray_nodemaparray"></a>

```json
{
  "NodeMaps": [
    {
      "ID": "x0c0s0b0n0",
      "NID": 1,
      "Role": "Compute",
      "SubRole": "Worker"
    }
  ]
}

```

This is a named array of NodeMap objects. This is the result of GET-ing the NodeMaps collection, or can be used to populate or update it as input provided via POST.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|NodeMaps|[[NodeMap.1.0.0_PostNodeMap](#schemanodemap.1.0.0_postnodemap)]|false|none|Contains the NodeMap objects in the array.|

<h2 id="tocS_ComponentEndpoint.1.0.0_ComponentEndpoint">ComponentEndpoint.1.0.0_ComponentEndpoint</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpoint.1.0.0_componentendpoint"></a>
<a id="schema_ComponentEndpoint.1.0.0_ComponentEndpoint"></a>
<a id="tocScomponentendpoint.1.0.0_componentendpoint"></a>
<a id="tocscomponentendpoint.1.0.0_componentendpoint"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "Domain": "mgmt.example.domain.com",
  "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
  "RedfishType": "ComputerSystem",
  "RedfishSubtype": "Physical",
  "Enabled": true,
  "ComponentEndpointType": "ComponentEndpointComputerSystem",
  "MACAddr": "ae:12:ce:7a:aa:99",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/Systems/System.Embedded.1",
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
  "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1"
}

```

This describes a child component of a Redfish endpoint and is populated when Redfish endpoint discovery occurs.  It is used by services that need to interact directly with the component via Redfish. It represents a physical component of something and has a corresponding representation as an HMS Component, hence the name. There are also ServiceEndpoints which represent Redfish services that are discovered when the RedfishEndpoint is discovered.
NOTE: These records are discovered, not created, and therefore are not writable (since any changes would be overwritten by a subsequent discovery).
Additional info is appended depending on RedfishType (discriminator)

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[XName.1.0.0](#schemaxname.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.|
|Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|none|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|Domain|string|false|none|Domain of component FQDN.  Hostname is always ID/xname|
|FQDN|string|false|none|Fully-qualified domain name of component on management network if for example the component is a node.|
|RedfishType|[RedfishType.1.0.0](#schemaredfishtype.1.0.0)|false|none|This is the Redfish object type, not to be confused with the HMS component type.|
|RedfishSubtype|[RedfishSubtype.1.0.0](#schemaredfishsubtype.1.0.0)|false|none|This is the type corresponding to the Redfish object type, i.e. the ChassisType field, SystemType, ManagerType fields.  We only use these three types to create ComponentEndpoints for now.|
|Enabled|boolean|false|none|To disable a component without deleting its data from the database, can be set to false|
|ComponentEndpointType|string|true|none|This is used as a discriminator to determine the additional RF-type- specific data that is kept for a ComponentEndpoint.|
|MACAddr|string|false|none|If the component e.g. a ComputerSystem/Node has a MAC on the management network, i.e. corresponding to the FQDN field's Ethernet interface, this field will be present.  Not the HSN MAC.  Represented as the standard colon-separated 6 byte hex string.|
|UUID|[UUID.1.0.0](#schemauuid.1.0.0)|false|none|This is a universally unique identifier i.e. UUID in the canonical format provided by Redfish to identify endpoints and services. If this is the UUID of a RedfishEndpoint, it should be the UUID broadcast by SSDP, if applicable.|
|OdataID|[OdataID.1.0.0](#schemaodataid.1.0.0)|false|none|This is the path (relative to a Redfish endpoint) of a particular Redfish resource, e.g. /Redfish/v1/Systems/System.Embedded.1|
|RedfishEndpointID|[XNameRFEndpoint.1.0.0](#schemaxnamerfendpoint.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). This is identical to a normal XName, but specifies a case where a BMC or other controller type is expected.|
|RedfishEndpointFQDN|string|false|read-only|This is a back-reference to the fully-qualified domain name of the parent Redfish endpoint that was used to discover the component.  It is the RedfishEndpointID field i.e. the hostname/xname plus its current domain.|
|RedfishURL|string|false|read-only|Complete URL to the corresponding Redfish object, combining the RedfishEndpoint's FQDN and the OdataID.|

#### Enumerated Values

|Property|Value|
|---|---|
|ComponentEndpointType|ComponentEndpointChassis|
|ComponentEndpointType|ComponentEndpointComputerSystem|
|ComponentEndpointType|ComponentEndpointManager|
|ComponentEndpointType|ComponentEndpointPowerDistribution|
|ComponentEndpointType|ComponentEndpointOutlet|

<h2 id="tocS_ComponentEndpointChassis">ComponentEndpointChassis</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpointchassis"></a>
<a id="schema_ComponentEndpointChassis"></a>
<a id="tocScomponentendpointchassis"></a>
<a id="tocscomponentendpointchassis"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "Domain": "mgmt.example.domain.com",
  "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
  "RedfishType": "ComputerSystem",
  "RedfishSubtype": "Physical",
  "Enabled": true,
  "ComponentEndpointType": "ComponentEndpointComputerSystem",
  "MACAddr": "ae:12:ce:7a:aa:99",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/Systems/System.Embedded.1",
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
  "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1",
  "RedfishChassisInfo": {
    "Name": "string",
    "Actions": {
      "#Chassis.Reset": {
        "ResetType@Redfish.AllowableValues": [
          "On",
          "ForceOff"
        ],
        "target": "/redfish/v1/Chassis/RackEnclosure/Actions/Chassis.Reset"
      }
    }
  }
}

```

This is a subtype of ComponentEndpoint for Chassis RF components, i.e. of most HMS components other than nodes and BMCs. This subtype is used when the ComponentEndpoint's ComponentEndpointType is 'ComponentEndpointChassis' via the 'discriminator: ComponentEndpointType' property.

### Properties

allOf - discriminator: ComponentEndpoint.1.0.0_ComponentEndpoint.ComponentEndpointType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[ComponentEndpoint.1.0.0_ComponentEndpoint](#schemacomponentendpoint.1.0.0_componentendpoint)|false|none|This describes a child component of a Redfish endpoint and is populated when Redfish endpoint discovery occurs.  It is used by services that need to interact directly with the component via Redfish. It represents a physical component of something and has a corresponding representation as an HMS Component, hence the name. There are also ServiceEndpoints which represent Redfish services that are discovered when the RedfishEndpoint is discovered.<br>NOTE: These records are discovered, not created, and therefore are not writable (since any changes would be overwritten by a subsequent discovery).<br>Additional info is appended depending on RedfishType (discriminator)|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» RedfishChassisInfo|[ComponentEndpoint.1.0.0_RedfishChassisInfo](#schemacomponentendpoint.1.0.0_redfishchassisinfo)|false|none|This is the ChassisInfo field in the RF Chassis subtype of ComponentEndpoint, i.e. when the latter's RedfishType is Chassis. This is where new fields will be added.|

<h2 id="tocS_ComponentEndpointComputerSystem">ComponentEndpointComputerSystem</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpointcomputersystem"></a>
<a id="schema_ComponentEndpointComputerSystem"></a>
<a id="tocScomponentendpointcomputersystem"></a>
<a id="tocscomponentendpointcomputersystem"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "Domain": "mgmt.example.domain.com",
  "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
  "RedfishType": "ComputerSystem",
  "RedfishSubtype": "Physical",
  "Enabled": true,
  "ComponentEndpointType": "ComponentEndpointComputerSystem",
  "MACAddr": "ae:12:ce:7a:aa:99",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/Systems/System.Embedded.1",
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
  "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1",
  "RedfishSystemInfo": {
    "Name": "string",
    "Actions": {
      "#ComputerSystem.Reset": {
        "ResetType@Redfish.AllowableValues": [
          "On",
          "ForceOff",
          "ForceRestart"
        ],
        "target": "/redfish/v1/Systems/System.1/Actions/ComputerSystem.Reset"
      }
    },
    "EthernetNICInfo": [
      {
        "RedfishId": 1,
        "@odata.id": "/redfish/v1/{Chassis/Managers/Systems}/{Id}/EthernetInterfaces/1",
        "Description": "Integrated NIC 1",
        "FQDN": "string",
        "Hostname": "string",
        "InterfaceEnabled": true,
        "MACAddress": "ae:12:ce:7a:aa:99",
        "PermanentMACAddress": "ae:12:ce:7a:aa:99"
      }
    ],
    "PowerURL": "/redfish/v1/Chassis/Node0/Power",
    "PowerControl": [
      {
        "Name": "Node Power Control",
        "PowerCapacityWatts": 900,
        "OEM": {
          "Cray": {
            "PowerIdleWatts": 900,
            "PowerLimit": {
              "Min": 350,
              "Max": 850
            },
            "PowerResetWatts": 250
          }
        },
        "RelatedItem": [
          {
            "@odata.id": "/redfish/v1/Chassis/Node0/Power#/PowerControl/Accelerator0"
          }
        ]
      }
    ]
  }
}

```

This is a subtype of ComponentEndpoint for ComputerSystem RF components, i.e. a node HMS type. This subtype is used when the ComponentEndpoint's ComponentEndpointType is 'ComponentEndpointComputerSystem' via the 'discriminator: ComponentEndpointType' property.

### Properties

allOf - discriminator: ComponentEndpoint.1.0.0_ComponentEndpoint.ComponentEndpointType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[ComponentEndpoint.1.0.0_ComponentEndpoint](#schemacomponentendpoint.1.0.0_componentendpoint)|false|none|This describes a child component of a Redfish endpoint and is populated when Redfish endpoint discovery occurs.  It is used by services that need to interact directly with the component via Redfish. It represents a physical component of something and has a corresponding representation as an HMS Component, hence the name. There are also ServiceEndpoints which represent Redfish services that are discovered when the RedfishEndpoint is discovered.<br>NOTE: These records are discovered, not created, and therefore are not writable (since any changes would be overwritten by a subsequent discovery).<br>Additional info is appended depending on RedfishType (discriminator)|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» RedfishSystemInfo|[ComponentEndpoint.1.0.0_RedfishSystemInfo](#schemacomponentendpoint.1.0.0_redfishsysteminfo)|false|none|This is the SystemInfo object in the RF ComputerSystem subtype of ComponentEndpoint, i.e. when the latter's RedfishType is ComputerSystem. It contains HMS-Node/ComputerSystem-specific Redfish fields that need to be collected during discovery and made available to clients. This is where new fields will be added.  Mostly placeholder now.|

<h2 id="tocS_ComponentEndpointManager">ComponentEndpointManager</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpointmanager"></a>
<a id="schema_ComponentEndpointManager"></a>
<a id="tocScomponentendpointmanager"></a>
<a id="tocscomponentendpointmanager"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "Domain": "mgmt.example.domain.com",
  "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
  "RedfishType": "ComputerSystem",
  "RedfishSubtype": "Physical",
  "Enabled": true,
  "ComponentEndpointType": "ComponentEndpointComputerSystem",
  "MACAddr": "ae:12:ce:7a:aa:99",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/Systems/System.Embedded.1",
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
  "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1",
  "RedfishManagerInfo": {
    "Name": "string",
    "Actions": {
      "#Manager.Reset": {
        "ResetType@Redfish.AllowableValues": [
          "ForceRestart"
        ],
        "target": "/redfish/v1/Managers/BMC/Actions/Manager.Reset"
      }
    },
    "EthernetNICInfo": [
      {
        "RedfishId": 1,
        "@odata.id": "/redfish/v1/{Chassis/Managers/Systems}/{Id}/EthernetInterfaces/1",
        "Description": "Integrated NIC 1",
        "FQDN": "string",
        "Hostname": "string",
        "InterfaceEnabled": true,
        "MACAddress": "ae:12:ce:7a:aa:99",
        "PermanentMACAddress": "ae:12:ce:7a:aa:99"
      }
    ]
  }
}

```

This is a subtype of ComponentEndpoint for Manager RF components, i.e. any BMC type.  For example NodeBMC is a Manager, NodeEnclosure is a Chassis RF type. This subtype is used when the ComponentEndpoint's ComponentEndpointType is 'ComponentEndpointManager' via the 'discriminator: ComponentEndpointType' property.

### Properties

allOf - discriminator: ComponentEndpoint.1.0.0_ComponentEndpoint.ComponentEndpointType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[ComponentEndpoint.1.0.0_ComponentEndpoint](#schemacomponentendpoint.1.0.0_componentendpoint)|false|none|This describes a child component of a Redfish endpoint and is populated when Redfish endpoint discovery occurs.  It is used by services that need to interact directly with the component via Redfish. It represents a physical component of something and has a corresponding representation as an HMS Component, hence the name. There are also ServiceEndpoints which represent Redfish services that are discovered when the RedfishEndpoint is discovered.<br>NOTE: These records are discovered, not created, and therefore are not writable (since any changes would be overwritten by a subsequent discovery).<br>Additional info is appended depending on RedfishType (discriminator)|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» RedfishManagerInfo|[ComponentEndpoint.1.0.0_RedfishManagerInfo](#schemacomponentendpoint.1.0.0_redfishmanagerinfo)|false|none|This is the ManagerInfo object in the RF Manager subtype of ComponentEndpoint, i.e. when the latter's RedfishType is Manager. It contains BMC/Manager-specific Redfish fields that need to be collected during discovery and made available to clients. This is where new fields will be added.  Mostly placeholder now.|

<h2 id="tocS_ComponentEndpointPowerDistribution">ComponentEndpointPowerDistribution</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpointpowerdistribution"></a>
<a id="schema_ComponentEndpointPowerDistribution"></a>
<a id="tocScomponentendpointpowerdistribution"></a>
<a id="tocscomponentendpointpowerdistribution"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "Domain": "mgmt.example.domain.com",
  "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
  "RedfishType": "ComputerSystem",
  "RedfishSubtype": "Physical",
  "Enabled": true,
  "ComponentEndpointType": "ComponentEndpointComputerSystem",
  "MACAddr": "ae:12:ce:7a:aa:99",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/Systems/System.Embedded.1",
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
  "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1",
  "RedfishChassisInfo": {
    "Name": "string"
  }
}

```

This is a subtype of ComponentEndpoint for PowerDistribution RF components. This subtype is used when the ComponentEndpoints ComponentEndpointType is ComponentEndpointPowerDistribution via the discriminator: ComponentEndpointType property.

### Properties

allOf - discriminator: ComponentEndpoint.1.0.0_ComponentEndpoint.ComponentEndpointType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[ComponentEndpoint.1.0.0_ComponentEndpoint](#schemacomponentendpoint.1.0.0_componentendpoint)|false|none|This describes a child component of a Redfish endpoint and is populated when Redfish endpoint discovery occurs.  It is used by services that need to interact directly with the component via Redfish. It represents a physical component of something and has a corresponding representation as an HMS Component, hence the name. There are also ServiceEndpoints which represent Redfish services that are discovered when the RedfishEndpoint is discovered.<br>NOTE: These records are discovered, not created, and therefore are not writable (since any changes would be overwritten by a subsequent discovery).<br>Additional info is appended depending on RedfishType (discriminator)|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» RedfishChassisInfo|[ComponentEndpoint.1.0.0_RedfishPowerDistributionInfo](#schemacomponentendpoint.1.0.0_redfishpowerdistributioninfo)|false|none|This is the RedfishPDUInfo field in the RF Chassis subtype of ComponentEndpoint, i.e. when the latter's RedfishType is PowerDistribution.  This is where new fields will be added.|

<h2 id="tocS_ComponentEndpointOutlet">ComponentEndpointOutlet</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpointoutlet"></a>
<a id="schema_ComponentEndpointOutlet"></a>
<a id="tocScomponentendpointoutlet"></a>
<a id="tocscomponentendpointoutlet"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "Domain": "mgmt.example.domain.com",
  "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
  "RedfishType": "ComputerSystem",
  "RedfishSubtype": "Physical",
  "Enabled": true,
  "ComponentEndpointType": "ComponentEndpointComputerSystem",
  "MACAddr": "ae:12:ce:7a:aa:99",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/Systems/System.Embedded.1",
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
  "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1",
  "RedfishChassisInfo": {
    "Name": "string",
    "Actions": {
      "#Outlet.PowerControl": {
        "PowerControl@Redfish.AllowableValues": [
          "On"
        ],
        "target": "/redfish/v1/PowerEquipment/RackPDUs/1/Outlets/A1/Outlet.PowerControl"
      },
      "#Outlet.ResetBreaker": {
        "ResetBreaker@Redfish.AllowableValues": [
          "Off"
        ],
        "target": "/redfish/v1/PowerEquipment/RackPDUs/1/Outlets/A1/Outlet.ResetBreaker"
      },
      "#Outlet.ResetStatistics": {
        "ResetStatistics@Redfish.AllowableValues": [
          "string"
        ],
        "target": "/redfish/v1/PowerEquipment/RackPDUs/1/Outlets/A1/Outlet.ResetStatistics"
      }
    }
  }
}

```

This is a subtype of ComponentEndpoint for PowerDistribution Outlet RF components. This subtype is used when the ComponentEndpoints ComponentEndpointType is ComponentEndpointOutlet via the discriminator: ComponentEndpointType property.

### Properties

allOf - discriminator: ComponentEndpoint.1.0.0_ComponentEndpoint.ComponentEndpointType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[ComponentEndpoint.1.0.0_ComponentEndpoint](#schemacomponentendpoint.1.0.0_componentendpoint)|false|none|This describes a child component of a Redfish endpoint and is populated when Redfish endpoint discovery occurs.  It is used by services that need to interact directly with the component via Redfish. It represents a physical component of something and has a corresponding representation as an HMS Component, hence the name. There are also ServiceEndpoints which represent Redfish services that are discovered when the RedfishEndpoint is discovered.<br>NOTE: These records are discovered, not created, and therefore are not writable (since any changes would be overwritten by a subsequent discovery).<br>Additional info is appended depending on RedfishType (discriminator)|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» RedfishChassisInfo|[ComponentEndpoint.1.0.0_RedfishOutletInfo](#schemacomponentendpoint.1.0.0_redfishoutletinfo)|false|none|This is the RedfishOutletInfo field in the RF Outlet subtype of ComponentEndpoint, i.e. when the latter's RedfishType is Outlet. This is where new fields will be added.|

<h2 id="tocS_ComponentEndpoint.1.0.0_RedfishChassisInfo">ComponentEndpoint.1.0.0_RedfishChassisInfo</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpoint.1.0.0_redfishchassisinfo"></a>
<a id="schema_ComponentEndpoint.1.0.0_RedfishChassisInfo"></a>
<a id="tocScomponentendpoint.1.0.0_redfishchassisinfo"></a>
<a id="tocscomponentendpoint.1.0.0_redfishchassisinfo"></a>

```json
{
  "Name": "string",
  "Actions": {
    "#Chassis.Reset": {
      "ResetType@Redfish.AllowableValues": [
        "On",
        "ForceOff"
      ],
      "target": "/redfish/v1/Chassis/RackEnclosure/Actions/Chassis.Reset"
    }
  }
}

```

This is the ChassisInfo field in the RF Chassis subtype of ComponentEndpoint, i.e. when the latter's RedfishType is Chassis. This is where new fields will be added.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|The Redfish 'Name' of the Chassis.|
|Actions|[Actions_1.0.0_ChassisActions](#schemaactions_1.0.0_chassisactions)|false|none|This is a pass-through field from Redfish that lists the available actions for a Chassis component (if any were found, else if it be omitted entirely).|

<h2 id="tocS_ComponentEndpoint.1.0.0_RedfishSystemInfo">ComponentEndpoint.1.0.0_RedfishSystemInfo</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpoint.1.0.0_redfishsysteminfo"></a>
<a id="schema_ComponentEndpoint.1.0.0_RedfishSystemInfo"></a>
<a id="tocScomponentendpoint.1.0.0_redfishsysteminfo"></a>
<a id="tocscomponentendpoint.1.0.0_redfishsysteminfo"></a>

```json
{
  "Name": "string",
  "Actions": {
    "#ComputerSystem.Reset": {
      "ResetType@Redfish.AllowableValues": [
        "On",
        "ForceOff",
        "ForceRestart"
      ],
      "target": "/redfish/v1/Systems/System.1/Actions/ComputerSystem.Reset"
    }
  },
  "EthernetNICInfo": [
    {
      "RedfishId": 1,
      "@odata.id": "/redfish/v1/{Chassis/Managers/Systems}/{Id}/EthernetInterfaces/1",
      "Description": "Integrated NIC 1",
      "FQDN": "string",
      "Hostname": "string",
      "InterfaceEnabled": true,
      "MACAddress": "ae:12:ce:7a:aa:99",
      "PermanentMACAddress": "ae:12:ce:7a:aa:99"
    }
  ],
  "PowerURL": "/redfish/v1/Chassis/Node0/Power",
  "PowerControl": [
    {
      "Name": "Node Power Control",
      "PowerCapacityWatts": 900,
      "OEM": {
        "Cray": {
          "PowerIdleWatts": 900,
          "PowerLimit": {
            "Min": 350,
            "Max": 850
          },
          "PowerResetWatts": 250
        }
      },
      "RelatedItem": [
        {
          "@odata.id": "/redfish/v1/Chassis/Node0/Power#/PowerControl/Accelerator0"
        }
      ]
    }
  ]
}

```

This is the SystemInfo object in the RF ComputerSystem subtype of ComponentEndpoint, i.e. when the latter's RedfishType is ComputerSystem. It contains HMS-Node/ComputerSystem-specific Redfish fields that need to be collected during discovery and made available to clients. This is where new fields will be added.  Mostly placeholder now.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|The Redfish 'name' of the ComputerSystem.|
|Actions|[Actions_1.0.0_ComputerSystemActions](#schemaactions_1.0.0_computersystemactions)|false|none|This is a pass-through field from Redfish that lists the available actions for a System component (if any were found, else if it be omitted entirely).|
|EthernetNICInfo|[[EthernetNICInfo_1.0.0](#schemaethernetnicinfo_1.0.0)]|false|none|[This is a summary info for one ordinary Ethernet NIC (i.e. not on HSN). These fields are all passed through from a Redfish EthernetInterface object.]|
|PowerURL|string|false|read-only|The URL for the power info for this node.|
|PowerControl|[[PowerControl_1.0.0](#schemapowercontrol_1.0.0)]|false|none|[This is the power control info for the node. These fields are all passed through from a Redfish PowerControl object.]|

<h2 id="tocS_ComponentEndpoint.1.0.0_RedfishManagerInfo">ComponentEndpoint.1.0.0_RedfishManagerInfo</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpoint.1.0.0_redfishmanagerinfo"></a>
<a id="schema_ComponentEndpoint.1.0.0_RedfishManagerInfo"></a>
<a id="tocScomponentendpoint.1.0.0_redfishmanagerinfo"></a>
<a id="tocscomponentendpoint.1.0.0_redfishmanagerinfo"></a>

```json
{
  "Name": "string",
  "Actions": {
    "#Manager.Reset": {
      "ResetType@Redfish.AllowableValues": [
        "ForceRestart"
      ],
      "target": "/redfish/v1/Managers/BMC/Actions/Manager.Reset"
    }
  },
  "EthernetNICInfo": [
    {
      "RedfishId": 1,
      "@odata.id": "/redfish/v1/{Chassis/Managers/Systems}/{Id}/EthernetInterfaces/1",
      "Description": "Integrated NIC 1",
      "FQDN": "string",
      "Hostname": "string",
      "InterfaceEnabled": true,
      "MACAddress": "ae:12:ce:7a:aa:99",
      "PermanentMACAddress": "ae:12:ce:7a:aa:99"
    }
  ]
}

```

This is the ManagerInfo object in the RF Manager subtype of ComponentEndpoint, i.e. when the latter's RedfishType is Manager. It contains BMC/Manager-specific Redfish fields that need to be collected during discovery and made available to clients. This is where new fields will be added.  Mostly placeholder now.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|The Redfish 'Name' of the Manager.|
|Actions|[Actions_1.0.0_ManagerActions](#schemaactions_1.0.0_manageractions)|false|none|This is a pass-through field from Redfish that lists the available actions for a Manager component (if any were found, else if it be omitted entirely).|
|EthernetNICInfo|[[EthernetNICInfo_1.0.0](#schemaethernetnicinfo_1.0.0)]|false|none|[This is a summary info for one ordinary Ethernet NIC (i.e. not on HSN). These fields are all passed through from a Redfish EthernetInterface object.]|

<h2 id="tocS_ComponentEndpoint.1.0.0_RedfishPowerDistributionInfo">ComponentEndpoint.1.0.0_RedfishPowerDistributionInfo</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpoint.1.0.0_redfishpowerdistributioninfo"></a>
<a id="schema_ComponentEndpoint.1.0.0_RedfishPowerDistributionInfo"></a>
<a id="tocScomponentendpoint.1.0.0_redfishpowerdistributioninfo"></a>
<a id="tocscomponentendpoint.1.0.0_redfishpowerdistributioninfo"></a>

```json
{
  "Name": "string"
}

```

This is the RedfishPDUInfo field in the RF Chassis subtype of ComponentEndpoint, i.e. when the latter's RedfishType is PowerDistribution.  This is where new fields will be added.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|The Redfish Name of the PDU.|

<h2 id="tocS_ComponentEndpoint.1.0.0_RedfishOutletInfo">ComponentEndpoint.1.0.0_RedfishOutletInfo</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpoint.1.0.0_redfishoutletinfo"></a>
<a id="schema_ComponentEndpoint.1.0.0_RedfishOutletInfo"></a>
<a id="tocScomponentendpoint.1.0.0_redfishoutletinfo"></a>
<a id="tocscomponentendpoint.1.0.0_redfishoutletinfo"></a>

```json
{
  "Name": "string",
  "Actions": {
    "#Outlet.PowerControl": {
      "PowerControl@Redfish.AllowableValues": [
        "On"
      ],
      "target": "/redfish/v1/PowerEquipment/RackPDUs/1/Outlets/A1/Outlet.PowerControl"
    },
    "#Outlet.ResetBreaker": {
      "ResetBreaker@Redfish.AllowableValues": [
        "Off"
      ],
      "target": "/redfish/v1/PowerEquipment/RackPDUs/1/Outlets/A1/Outlet.ResetBreaker"
    },
    "#Outlet.ResetStatistics": {
      "ResetStatistics@Redfish.AllowableValues": [
        "string"
      ],
      "target": "/redfish/v1/PowerEquipment/RackPDUs/1/Outlets/A1/Outlet.ResetStatistics"
    }
  }
}

```

This is the RedfishOutletInfo field in the RF Outlet subtype of ComponentEndpoint, i.e. when the latter's RedfishType is Outlet. This is where new fields will be added.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|The Redfish Name of the Outlet.|
|Actions|[Actions_1.0.0_OutletActions](#schemaactions_1.0.0_outletactions)|false|none|This is a pass-through field from Redfish that lists the available actions for a Outlet component (if any were found, else if it be omitted entirely).|

<h2 id="tocS_ComponentEndpoint.1.0.0_ResourceURICollection">ComponentEndpoint.1.0.0_ResourceURICollection</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpoint.1.0.0_resourceuricollection"></a>
<a id="schema_ComponentEndpoint.1.0.0_ResourceURICollection"></a>
<a id="tocScomponentendpoint.1.0.0_resourceuricollection"></a>
<a id="tocscomponentendpoint.1.0.0_resourceuricollection"></a>

```json
{
  "Name": "(Type of Object) Collection",
  "Members": [
    {
      "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
    }
  ],
  "MemberCount": 0
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|Should describe the collection, though the type of resources the links correspond to should also be inferred from the context in which the collection was obtained.|
|Members|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|read-only|An array of ResourceIds.|
|MemberCount|number(int32)|false|read-only|Number of ResourceURIs in the collection|

<h2 id="tocS_ComponentEndpointArray_ComponentEndpointArray">ComponentEndpointArray_ComponentEndpointArray</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpointarray_componentendpointarray"></a>
<a id="schema_ComponentEndpointArray_ComponentEndpointArray"></a>
<a id="tocScomponentendpointarray_componentendpointarray"></a>
<a id="tocscomponentendpointarray_componentendpointarray"></a>

```json
{
  "ComponentEndpoints": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "Domain": "mgmt.example.domain.com",
      "FQDN": "x0c0s0b0n0.mgmt.example.domain.com",
      "RedfishType": "ComputerSystem",
      "RedfishSubtype": "Physical",
      "Enabled": true,
      "ComponentEndpointType": "ComponentEndpointComputerSystem",
      "MACAddr": "ae:12:ce:7a:aa:99",
      "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
      "OdataID": "/redfish/v1/Systems/System.Embedded.1",
      "RedfishEndpointID": "x0c0s0b0",
      "RedfishEndpointFQDN": "x0c0s0b0.mgmt.example.domain.com",
      "RedfishURL": "x0c0s0b0.mgmt.example.domain.com/redfish/v1/Systems/System.Embedded.1"
    }
  ]
}

```

This is a collection of ComponentEndpoint objects returned whenever a query is expected to result in 0 to n matches.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentEndpoints|[[ComponentEndpoint.1.0.0_ComponentEndpoint](#schemacomponentendpoint.1.0.0_componentendpoint)]|false|none|Contains the HMS RedfishEndpoint objects in the array.|

<h2 id="tocS_ComponentEndpointArray_PostQuery">ComponentEndpointArray_PostQuery</h2>
<!-- backwards compatibility -->
<a id="schemacomponentendpointarray_postquery"></a>
<a id="schema_ComponentEndpointArray_PostQuery"></a>
<a id="tocScomponentendpointarray_postquery"></a>
<a id="tocscomponentendpointarray_postquery"></a>

```json
{
  "ComponentEndpointIDs": [
    "x0c0s0b0n0"
  ],
  "partition": "p1.2"
}

```

There are limits to the length of an HTTP URL and query string. Hence, if we wish to query an arbitrary list of XName/IDs, it will need to be in the body of the request.  This object is used for this purpose.  It is similar to the analogous GET operation.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentEndpointIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|true|none|An array of XName/ID values for the ComponentEndpoints to query.|
|partition|[XNamePartition.1.0.0](#schemaxnamepartition.1.0.0)|false|none|This is an ordinary xname, but one where only a partition (hard:soft) or the system alias (s0) will be expected as valid input.|

<h2 id="tocS_HSNInfo.1.0.0">HSNInfo.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahsninfo.1.0.0"></a>
<a id="schema_HSNInfo.1.0.0"></a>
<a id="tocShsninfo.1.0.0"></a>
<a id="tocshsninfo.1.0.0"></a>

```json
{
  "HSNTopology": 0,
  "HSNNetworkType": "Sling",
  "HSNInfoEntries": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "NICAddrs": [
        2313746,
        11484946
      ],
      "HSNCoords": [
        0,
        0,
        0,
        0,
        0
      ]
    }
  ]
}

```

Component to NIC and Network Coordinate Map

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|HSNTopology|[HSNTopology.1.0.0](#schemahsntopology.1.0.0)|false|none|Numerical identifier for HSN topology class|
|HSNNetworkType|[NetType.1.0.0](#schemanettype.1.0.0)|false|none|This is the type of high speed network the component is connected to, if it is an applicable component type and the interface is present, or the type of the system HSN.|
|HSNInfoEntries|[[HSNInfoEntry.1.0.0](#schemahsninfoentry.1.0.0)]|false|none|Contains an HSN info entry for each component.|

<h2 id="tocS_HSNInfoEntry.1.0.0">HSNInfoEntry.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahsninfoentry.1.0.0"></a>
<a id="schema_HSNInfoEntry.1.0.0"></a>
<a id="tocShsninfoentry.1.0.0"></a>
<a id="tocshsninfoentry.1.0.0"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "NICAddrs": [
    2313746,
    11484946
  ],
  "HSNCoords": [
    0,
    0,
    0,
    0,
    0
  ]
}

```

The HSN info for an individual component, e.g. node.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[XName.1.0.0](#schemaxname.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.|
|Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|none|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|NICAddrs|[NICAddrs.1.0.0](#schemanicaddrs.1.0.0)|false|none|A collection of HSN NIC addresses in string form.|
|HSNCoords|[integer]|false|none|HSN Coordinates of the components, an integer tuple of a particular length in array form.|

<h2 id="tocS_HSNTopology.1.0.0">HSNTopology.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahsntopology.1.0.0"></a>
<a id="schema_HSNTopology.1.0.0"></a>
<a id="tocShsntopology.1.0.0"></a>
<a id="tocshsntopology.1.0.0"></a>

```json
0

```

Numerical identifier for HSN topology class

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|integer(int32)|false|none|Numerical identifier for HSN topology class|

<h2 id="tocS_HWInventory.1.0.0_HWInventory">HWInventory.1.0.0_HWInventory</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_hwinventory"></a>
<a id="schema_HWInventory.1.0.0_HWInventory"></a>
<a id="tocShwinventory.1.0.0_hwinventory"></a>
<a id="tocshwinventory.1.0.0_hwinventory"></a>

```json
{
  "XName": "x0c0s0b0n0",
  "Format": "NestNodesOnly",
  "Cabinets": [
    {
      "ID": "x0",
      "Type": "Cabinet",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocCabinet",
      "CabinetLocationInfo": {
        "Id": "Cabinet",
        "Name": "Name describing cabinet or where it is located, per manufacturing",
        "Description": "Description of cabinet, per manufacturing",
        "Hostname": "if_defined_in_Redfish"
      },
      "PopulatedFRU": {
        "FRUID": "Cray-2345-1234556789",
        "Type": "Cabinet",
        "Subtype": "MountainCabinet (example)",
        "HWInventoryByFRUType": "HWInvByFRUCabinet",
        "CabinetFRUInfo": {
          "AssetTag": "AdminAssignedAssetTag",
          "Model": 123,
          "Manufacturer": "Cray",
          "PartNumber": "p2345",
          "SerialNumber": "sn1234556789",
          "SKU": "as213234",
          "ChassisType": "Rack"
        }
      }
    }
  ],
  "Chassis": [
    {
      "ID": "x0c0",
      "Type": "Chassis",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocChassis",
      "ChassisLocationInfo": {
        "Id": "Chassis.1",
        "Name": "Name describing component or its location, per manufacturing",
        "Description": "Description, per manufacturing",
        "Hostname": "if_defined_in_Redfish"
      },
      "PopulatedFRU": {
        "FRUID": "Cray-ch01-23452345",
        "Type": "Chassis",
        "Subtype": "MountainChassis (example)",
        "HWInventoryByFRUType": "HWInvByFRUChassis",
        "ChassisFRUInfo": {
          "AssetTag": "AdminAssignedAssetTag",
          "Model": 3245,
          "Manufacturer": "Cray",
          "PartNumber": "ch01",
          "SerialNumber": "sn23452345",
          "SKU": "as213234",
          "ChassisType": "Enclosure"
        }
      }
    }
  ],
  "ComputeModules": [
    {
      "ComputeModuleLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      },
      "NodeEnclosures": [
        {
          "NodeEnclosureLocationInfo": {
            "Id": "string",
            "Name": "string",
            "Description": "string",
            "Hostname": "string"
          }
        }
      ]
    }
  ],
  "RouterModules": [
    {
      "RouterModuleLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      },
      "HSNBoards": [
        {
          "HSNBoardLocationInfo": {
            "Id": "string",
            "Name": "string",
            "Description": "string",
            "Hostname": "string"
          }
        }
      ]
    }
  ],
  "NodeEnclosures": [
    {
      "NodeEnclosureLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ],
  "HSNBoards": [
    {
      "HSNBoardLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ],
  "MgmtSwitches": [
    {
      "MgmtSwitchLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ],
  "MgmtHLSwitches": [
    {
      "MgmtHLSwitchLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ],
  "CDUMgmtSwitches": [
    {
      "CDUMgmtSwitchLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ],
  "Nodes": [
    {
      "ID": "x0c0s0b0n0",
      "Type": "Node",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocNode",
      "NodeLocationInfo": {
        "Id": "System.Embedded.1",
        "Name": "Name describing system or where it is located, per manufacturing",
        "Description": "Description of system/node type, per manufacturing",
        "Hostname": "if_defined_in_Redfish",
        "ProcessorSummary": {
          "Count": 2,
          "Model": "Multi-Core Intel(R) Xeon(R) processor E5-16xx Series"
        },
        "MemorySummary": {
          "TotalSystemMemoryGiB": 64
        }
      },
      "PopulatedFRU": {
        "FRUID": "Dell-99999-1234.1234.2345",
        "Type": "Node",
        "Subtype": "River",
        "HWInventoryByFRUType": "HWInvByFRUNode",
        "NodeFRUInfo": {
          "AssetTag": "AdminAssignedAssetTag",
          "BiosVersion": "v1.0.2.9999",
          "Model": "OKS0P2354",
          "Manufacturer": "Dell",
          "PartNumber": "p99999",
          "SerialNumber": "1234.1234.2345",
          "SKU": "as213234",
          "SystemType": "Physical",
          "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
        }
      },
      "Processors": [
        {
          "ID": "x0c0s0b0n0p0",
          "Type": "Processor",
          "Ordinal": 0,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocProcessor",
          "ProcessorLocationInfo": {
            "Id": "CPU1",
            "Name": "Processor",
            "Description": "Socket 1 Processor",
            "Socket": "CPU 1"
          },
          "PopulatedFRU": {
            "FRUID": "HOW-TO-ID-CPUS-FROM-REDFISH-IF-AT-ALL",
            "Type": "Processor",
            "Subtype": "SKL24",
            "HWInventoryByFRUType": "HWInvByFRUProcessor",
            "ProcessorFRUInfo": {
              "InstructionSet": "x86-64",
              "Manufacturer": "Intel",
              "MaxSpeedMHz": 2600,
              "Model": "Intel(R) Xeon(R) CPU E5-2623 v4 @ 2.60GHz",
              "ProcessorArchitecture": "x86",
              "ProcessorId": {
                "EffectiveFamily": 6,
                "EffectiveModel": 79,
                "IdentificationRegisters": 263921,
                "MicrocodeInfo": 184549399,
                "Step": 1,
                "VendorID": "GenuineIntel"
              },
              "ProcessorType": "CPU",
              "TotalCores": 24,
              "TotalThreads": 48
            }
          }
        },
        {
          "ID": "x0c0s0b0n0p1",
          "Type": "Processor",
          "Ordinal": 1,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocProcessor",
          "ProcessorLocationInfo": {
            "Id": "CPU2",
            "Name": "Processor",
            "Description": "Socket 2 Processor",
            "Socket": "CPU 2"
          },
          "PopulatedFRU": {
            "FRUID": "HOW-TO-ID-CPUS-FROM-REDFISH-IF-AT-ALL",
            "Type": "Processor",
            "Subtype": "SKL24",
            "HWInventoryByFRUType": "HWInvByFRUProcessor",
            "ProcessorFRUInfo": {
              "InstructionSet": "x86-64",
              "Manufacturer": "Intel",
              "MaxSpeedMHz": 2600,
              "Model": "Intel(R) Xeon(R) CPU E5-2623 v4 @ 2.60GHz",
              "ProcessorArchitecture": "x86",
              "ProcessorId": {
                "EffectiveFamily": 6,
                "EffectiveModel": 79,
                "IdentificationRegisters": 263921,
                "MicrocodeInfo": 184549399,
                "Step": 1,
                "VendorID": "GenuineIntel"
              },
              "ProcessorType": "CPU",
              "TotalCores": 24,
              "TotalThreads": 48
            }
          }
        }
      ],
      "Memory": [
        {
          "ID": "x0c0s0b0n0d0",
          "Type": "Memory",
          "Ordinal": 0,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocMemory",
          "MemoryLocationInfo": {
            "Id": "DIMM1",
            "Name": "DIMM Slot 1",
            "MemoryLocation": {
              "Socket": 1,
              "MemoryController": 1,
              "Channel": 1,
              "Slot": 1
            }
          },
          "PopulatedFRU": {
            "FRUID": "MFR-PARTNUMBER-SERIALNUMBER",
            "Type": "Memory",
            "Subtype": "DIMM2400G32",
            "HWInventoryByFRUType": "HWInvByFRUMemory",
            "MemoryFRUInfo": {
              "BaseModuleType": "RDIMM",
              "BusWidthBits": 72,
              "CapacityMiB": 32768,
              "DataWidthBits": 64,
              "ErrorCorrection": "MultiBitECC",
              "Manufacturer": "Micron",
              "MemoryType": "DRAM",
              "MemoryDeviceType": "DDR4",
              "OperatingSpeedMhz": 2400,
              "PartNumber": "XYZ-123-1232",
              "RankCount": 2,
              "SerialNumber": "sn12344567689"
            }
          }
        },
        {
          "ID": "x0c0s0b0n0d1",
          "Type": "Memory",
          "Ordinal": 1,
          "Status": "Empty",
          "HWInventoryByLocationType": "HWInvByLocMemory",
          "MemoryLocationInfo": {
            "Id": "DIMM2",
            "Name": "Socket 1 DIMM Slot 2",
            "MemoryLocation": {
              "Socket": 1,
              "MemoryController": 1,
              "Channel": 1,
              "Slot": 2
            }
          },
          "PopulatedFRU": null
        },
        {
          "ID": "x0c0s0b0n0d2",
          "Type": "Memory",
          "Ordinal": 2,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocMemory",
          "MemoryLocationInfo": {
            "Id": "DIMM3",
            "Name": "Socket 2 DIMM Slot 1",
            "MemoryLocation": {
              "Socket": 2,
              "MemoryController": 2,
              "Channel": 1,
              "Slot": 1
            }
          },
          "PopulatedFRU": {
            "FRUID": "MFR-PARTNUMBER-SERIALNUMBER_2",
            "Type": "Memory",
            "Subtype": "DIMM2400G32",
            "HWInventoryByFRUType": "HWInvByFRUMemory",
            "MemoryFRUInfo": {
              "BaseModuleType": "RDIMM",
              "BusWidthBits": 72,
              "CapacityMiB": 32768,
              "DataWidthBits": 64,
              "ErrorCorrection": "MultiBitECC",
              "Manufacturer": "Micron",
              "MemoryType": "DRAM",
              "MemoryDeviceType": "DDR4",
              "OperatingSpeedMhz": 2400,
              "PartNumber": "XYZ-123-1232",
              "RankCount": 2,
              "SerialNumber": "k346456346346"
            }
          }
        },
        {
          "ID": "x0c0s0b0n0d3",
          "Type": "Memory",
          "Ordinal": 3,
          "Status": "Empty",
          "HWInventoryByLocationType": "HWInvByLocMemory",
          "MemoryLocationInfo": {
            "Id": "DIMM3",
            "Name": "Socket 2 DIMM Slot 2",
            "MemoryLocation": {
              "Socket": 2,
              "MemoryController": 2,
              "Channel": 1,
              "Slot": 2
            }
          },
          "PopulatedFRU": null
        }
      ]
    }
  ],
  "Processors": [
    {
      "description": "By default, listed as subcomponent of Node, see example there."
    }
  ],
  "NodeAccels": [
    {
      "description": "By default, listed as subcomponent of Node."
    }
  ],
  "Drives": [
    {
      "description": "By default, listed as subcomponent of Node, see example there."
    }
  ],
  "Memory": [
    {
      "description": "By default, listed as subcomponent of Node, see example there."
    }
  ],
  "CabinetPDUs": [
    {
      "ID": "x0m0p0",
      "Type": "CabinetPDU",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocPDU",
      "PDULocationInfo": {
        "Id": "1",
        "Name": "RackPDU1",
        "Description": "Description of PDU, per manufacturing",
        "UUID": "32354641-4135-4332-4a35-313735303734"
      },
      "PopulatedFRU": {
        "FRUID": "CabinetPDU.29347ZT536",
        "Type": "CabinetPDU",
        "HWInventoryByFRUType": "HWInvByFRUPDU",
        "PDUFRUInfo": {
          "FirmwareVersion": "4.3.0",
          "EquipmentType": "RackPDU",
          "Manufacturer": "Contoso",
          "CircuitSummary": {
            "TotalPhases": 3,
            "TotalBranches": 4,
            "TotalOutlets": 16,
            "MonitoredPhases": 3,
            "ControlledOutlets": 8,
            "MonitoredBranches": 4,
            "MonitoredOutlets": 12
          },
          "AssetTag": "PDX-92381",
          "DateOfManufacture": "2017-01-11T08:00:00Z",
          "HardwareRevision": "1.03b",
          "Model": "ZAP4000",
          "SerialNumber": "29347ZT536",
          "PartNumber": "AA-23"
        }
      },
      "CabinetPDUPowerConnectors": [
        {
          "ID": "x0m0p0v1",
          "Type": "CabinetPDUPowerConnector",
          "Ordinal": 0,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocOutlet",
          "OutletLocationInfo": {
            "Id": "A1",
            "Name": "Outlet A1, Branch Circuit A",
            "Description": "Outlet description"
          },
          "PopulatedFRU": {
            "FRUID": "CabinetPDUPowerConnector.0.CabinetPDU.29347ZT536",
            "Type": "CabinetPDUPowerConnector",
            "HWInventoryByFRUType": "HWInvByFRUOutlet",
            "OutletFRUInfo": {
              "PowerEnabled": true,
              "NominalVoltage": "AC120V",
              "RatedCurrentAmps": 20,
              "VoltageType": "AC",
              "OutletType": "NEMA_5_20R",
              "PhaseWiringType": "OnePhase3Wire"
            }
          }
        },
        {
          "ID": "x0m0p0v2",
          "Type": "CabinetPDUPowerConnector",
          "Ordinal": 2,
          "Status": "Populated",
          "HWInventoryByLocationType": "HWInvByLocOutlet",
          "OutletLocationInfo": {
            "Id": "A2",
            "Name": "Outlet A2, Branch Circuit A",
            "Description": "Outlet description"
          },
          "PopulatedFRU": {
            "FRUID": "CabinetPDUPowerConnector.1.CabinetPDU.29347ZT536",
            "Type": "CabinetPDUPowerConnector",
            "HWInventoryByFRUType": "HWInvByFRUOutlet",
            "OutletFRUInfo": {
              "PowerEnabled": true,
              "NominalVoltage": "AC120V",
              "RatedCurrentAmps": 20,
              "VoltageType": "AC",
              "OutletType": "NEMA_5_20R",
              "PhaseWiringType": "OnePhase3Wire"
            }
          }
        }
      ]
    }
  ],
  "CabinetPDUPowerConnectors": [
    {
      "description": "By default, listed as subcomponent of PDU, see example there."
    }
  ],
  "CMMRectifiers": [
    {
      "CMMRectifierLocationInfo": {
        "Name": "string",
        "FirmwareVersion": "string"
      }
    }
  ],
  "NodeAccelRisers": [
    {
      "NodeAccelRiserLocationInfo": {
        "Name": "string",
        "Description": "string"
      }
    }
  ],
  "NodeHsnNICs": [
    {
      "HSNNICLocationInfo": {
        "Description": "string",
        "Id": "string",
        "Name": "string"
      }
    }
  ],
  "NodeEnclosurePowerSupplies": [
    {
      "NodeEnclosurePowerSupplyLocationInfo": {
        "Name": "string",
        "FirmwareVersion": "string"
      }
    }
  ],
  "NodeBMC": [
    {
      "NodeBMCLocationInfo": {
        "DateTime": "string",
        "DateTimeLocalOffset": "string",
        "Description": "string",
        "FirmwareVersion": "string",
        "Id": "string",
        "Name": "string"
      }
    }
  ],
  "RouterBMC": [
    {
      "RouterBMCLocationInfo": {
        "DateTime": "string",
        "DateTimeLocalOffset": "string",
        "Description": "string",
        "FirmwareVersion": "string",
        "Id": "string",
        "Name": "string"
      }
    }
  ]
}

```

This is a collection of hardware inventory data. Depending on the query only some of these arrays will be populated.
Also, depending on the query that produced the inventory, some components may have their subcomponents nested underneath them (hierarchical query), rather than all arranged in their own arrays by their types (flat query).
The default is hierarchical for node subcomponents (Processors, Memory) and flat for everything else, but other query types are possible and can use this same basic structure.
Either way, the 'Target' field is the parent component, partition or system that is used to select the components for the query.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|XName|[XName.1.0.0](#schemaxname.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.|
|Format|string|false|none|How results are displayed<br><br>  FullyFlat      All component types listed in their own<br>                 arrays only.  No nesting of any children<br>  Hierarchical   All subcomponents listed as children up to<br>                 top level component (or set of cabinets)<br>  NestNodesOnly  Flat except that node subcomponents are nested<br>                 hierarchically.<br>Default is NestNodesOnly.|
|Cabinets|[[HWInvByLocCabinet](#schemahwinvbyloccabinet)]|false|read-only|All components with HMS type 'Cabinet' appropriate given Target component/partition and query type.|
|Chassis|[[HWInvByLocChassis](#schemahwinvbylocchassis)]|false|read-only|All appropriate components with HMS type 'Chassis' given Target component/partition and query type.|
|ComputeModules|[[HWInvByLocComputeModule](#schemahwinvbyloccomputemodule)]|false|read-only|All appropriate components with HMS type 'ComputeModule' given Target component/partition and query type.|
|RouterModules|[[HWInvByLocRouterModule](#schemahwinvbylocroutermodule)]|false|read-only|All appropriate components with HMS type 'RouterModule' given Target component/partition and query type.|
|NodeEnclosures|[[HWInvByLocNodeEnclosure](#schemahwinvbylocnodeenclosure)]|false|read-only|All appropriate components with HMS type 'NodeEnclosure' given Target component/partition and query type.|
|HSNBoards|[[HWInvByLocHSNBoard](#schemahwinvbylochsnboard)]|false|read-only|All appropriate components with HMS type 'HSNBoard' given Target component/partition and query type.|
|MgmtSwitches|[[HWInvByLocMgmtSwitch](#schemahwinvbylocmgmtswitch)]|false|read-only|All appropriate components with HMS type 'MgmtSwitch' given Target component/partition and query type.|
|MgmtHLSwitches|[[HWInvByLocMgmtHLSwitch](#schemahwinvbylocmgmthlswitch)]|false|read-only|All appropriate components with HMS type 'MgmtHLSwitch' given Target component/partition and query type.|
|CDUMgmtSwitches|[[HWInvByLocCDUMgmtSwitch](#schemahwinvbyloccdumgmtswitch)]|false|read-only|All appropriate components with HMS type 'CDUMgmtSwitch' given Target component/partition and query type.|
|Nodes|[[HWInvByLocNode](#schemahwinvbylocnode)]|false|read-only|All appropriate components with HMS type 'Node' given Target component/partition and query type.|
|Processors|[[HWInvByLocProcessor](#schemahwinvbylocprocessor)]|false|read-only|All appropriate components with HMS type 'Processor' given Target component/partition and query type.|
|NodeAccels|[[HWInvByLocNodeAccel](#schemahwinvbylocnodeaccel)]|false|read-only|All appropriate components with HMS type 'NodeAccel' given Target component/partition and query type.|
|Drives|[[HWInvByLocDrive](#schemahwinvbylocdrive)]|false|read-only|All appropriate components with HMS type 'Drive' given Target component/partition and query type.|
|Memory|[[HWInvByLocMemory](#schemahwinvbylocmemory)]|false|read-only|All appropriate components with HMS type 'Memory' given Target component/partition and query type.|
|CabinetPDUs|[[HWInvByLocPDU](#schemahwinvbylocpdu)]|false|read-only|All appropriate components with HMS type 'CabinetPDU' given Target component/partition and query type.|
|CabinetPDUPowerConnectors|[[HWInvByLocOutlet](#schemahwinvbylocoutlet)]|false|read-only|All appropriate components with HMS type 'CabinetPDUPowerConnector' given Target component/partition and query type.|
|CMMRectifiers|[[HWInvByLocCMMRectifier](#schemahwinvbyloccmmrectifier)]|false|read-only|All appropriate components with HMS type 'CMMRectifier' given Target component/partition and query type.|
|NodeAccelRisers|[[HWInvByLocNodeAccelRiser](#schemahwinvbylocnodeaccelriser)]|false|read-only|All appropriate components with HMS type 'NodeAccelRiser' given Target component/partition and query type.|
|NodeHsnNICs|[[HWInvByLocHSNNIC](#schemahwinvbylochsnnic)]|false|read-only|All appropriate components with HMS type 'NodeHsnNic' given Target component/partition and query type.|
|NodeEnclosurePowerSupplies|[[HWInvByLocNodeEnclosurePowerSupply](#schemahwinvbylocnodeenclosurepowersupply)]|false|read-only|All appropriate components with HMS type 'NodeEnclosurePowerSupply' given Target component/partition and query type.|
|NodeBMC|[[HWInvByLocNodeBMC](#schemahwinvbylocnodebmc)]|false|read-only|All appropriate components with HMS type 'NodeBMC' given Target component/partition and query type.|
|RouterBMC|[[HWInvByLocRouterBMC](#schemahwinvbylocrouterbmc)]|false|read-only|All appropriate components with HMS type 'RouterBMC' given Target component/partition and query type.|

#### Enumerated Values

|Property|Value|
|---|---|
|Format|FullyFlat|
|Format|Hierarchical|
|Format|NestNodesOnly|

<h2 id="tocS_HWInventory.1.0.0_HWInventoryByLocation">HWInventory.1.0.0_HWInventoryByLocation</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_hwinventorybylocation"></a>
<a id="schema_HWInventory.1.0.0_HWInventoryByLocation"></a>
<a id="tocShwinventory.1.0.0_hwinventorybylocation"></a>
<a id="tocshwinventory.1.0.0_hwinventorybylocation"></a>

```json
null

```

This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[XNameCompOrPartition.1.0.0](#schemaxnamecomporpartition.1.0.0)|true|none|This is an ordinary xname, but one where only a partition (hard:soft) or the system alias (s0) will be expected as valid input, or else a parent component.|
|Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|none|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|Ordinal|integer(int32)|false|read-only|This is the normalized (from zero) index of the component location (e.g. slot number) when there are more than one.  This should match the last number in the xname in most cases (e.g. Ordinal 0 for node x0c0s0b0n0).  Note that Redfish may use a different value or naming scheme, but this is passed through via the *LocationInfo for the type of component.|
|Status|string|false|read-only|Populated or Empty - whether location is populated.|
|HWInventoryByLocationType|string|true|none|This is used as a discriminator to determine the additional HMS-type specific subtype that is returned.|
|PopulatedFRU|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

#### Enumerated Values

|Property|Value|
|---|---|
|Status|Populated|
|Status|Empty|
|HWInventoryByLocationType|HWInvByLocCabinet|
|HWInventoryByLocationType|HWInvByLocChassis|
|HWInventoryByLocationType|HWInvByLocComputeModule|
|HWInventoryByLocationType|HWInvByLocRouterModule|
|HWInventoryByLocationType|HWInvByLocNodeEnclosure|
|HWInventoryByLocationType|HWInvByLocHSNBoard|
|HWInventoryByLocationType|HWInvByLocMgmtSwitch|
|HWInventoryByLocationType|HWInvByLocMgmtHLSwitch|
|HWInventoryByLocationType|HWInvByLocCDUMgmtSwitch|
|HWInventoryByLocationType|HWInvByLocNode|
|HWInventoryByLocationType|HWInvByLocProcessor|
|HWInventoryByLocationType|HWInvByLocNodeAccel|
|HWInventoryByLocationType|HWInvByLocNodeAccelRiser|
|HWInventoryByLocationType|HWInvByLocDrive|
|HWInventoryByLocationType|HWInvByLocMemory|
|HWInventoryByLocationType|HWInvByLocPDU|
|HWInventoryByLocationType|HWInvByLocOutlet|
|HWInventoryByLocationType|HWInvByLocCMMRectifier|
|HWInventoryByLocationType|HWInvByLocNodeEnclosurePowerSupply|
|HWInventoryByLocationType|HWInvByLocNodeBMC|
|HWInventoryByLocationType|HWInvByLocRouterBMC|
|HWInventoryByLocationType|HWInvByLocHSNNIC|

<h2 id="tocS_HWInvByLocCabinet">HWInvByLocCabinet</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyloccabinet"></a>
<a id="schema_HWInvByLocCabinet"></a>
<a id="tocShwinvbyloccabinet"></a>
<a id="tocshwinvbyloccabinet"></a>

```json
{
  "ID": "x0",
  "Type": "Cabinet",
  "Ordinal": 0,
  "Status": "Populated",
  "HWInventoryByLocationType": "HWInvByLocCabinet",
  "CabinetLocationInfo": {
    "Id": "Cabinet",
    "Name": "Name describing cabinet or where it is located, per manufacturing",
    "Description": "Description of cabinet, per manufacturing",
    "Hostname": "if_defined_in_Redfish"
  },
  "PopulatedFRU": {
    "FRUID": "Cray-2345-1234556789",
    "Type": "Cabinet",
    "Subtype": "MountainCabinet (example)",
    "HWInventoryByFRUType": "HWInvByFRUCabinet",
    "CabinetFRUInfo": {
      "AssetTag": "AdminAssignedAssetTag",
      "Model": 123,
      "Manufacturer": "Cray",
      "PartNumber": "p2345",
      "SerialNumber": "sn1234556789",
      "SKU": "as213234",
      "ChassisType": "Rack"
    }
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType Cabinet. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocCabinet'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» CabinetLocationInfo|[HWInventory.1.0.0_RedfishChassisLocationInfo](#schemahwinventory.1.0.0_redfishchassislocationinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|
|» Chassis|[[HWInvByLocChassis](#schemahwinvbylocchassis)]|false|read-only|Embedded chassis HWInv object array representing subcomponents (if query is hierarchical).|

<h2 id="tocS_HWInvByLocChassis">HWInvByLocChassis</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocchassis"></a>
<a id="schema_HWInvByLocChassis"></a>
<a id="tocShwinvbylocchassis"></a>
<a id="tocshwinvbylocchassis"></a>

```json
{
  "ID": "x0c0",
  "Type": "Chassis",
  "Ordinal": 0,
  "Status": "Populated",
  "HWInventoryByLocationType": "HWInvByLocChassis",
  "ChassisLocationInfo": {
    "Id": "Chassis.1",
    "Name": "Name describing component or its location, per manufacturing",
    "Description": "Description, per manufacturing",
    "Hostname": "if_defined_in_Redfish"
  },
  "PopulatedFRU": {
    "FRUID": "Cray-ch01-23452345",
    "Type": "Chassis",
    "Subtype": "MountainChassis (example)",
    "HWInventoryByFRUType": "HWInvByFRUChassis",
    "ChassisFRUInfo": {
      "AssetTag": "AdminAssignedAssetTag",
      "Model": 3245,
      "Manufacturer": "Cray",
      "PartNumber": "ch01",
      "SerialNumber": "sn23452345",
      "SKU": "as213234",
      "ChassisType": "Enclosure"
    }
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType Chassis. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocChassis'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» ChassisLocationInfo|[HWInventory.1.0.0_RedfishChassisLocationInfo](#schemahwinventory.1.0.0_redfishchassislocationinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|
|» ComputeModules|[[HWInvByLocComputeModule](#schemahwinvbyloccomputemodule)]|false|read-only|Embedded ComputeModule HWInv object array representing subcomponents of that type (if query is hierarchical).|
|» RouterModules|[[HWInvByLocRouterModule](#schemahwinvbylocroutermodule)]|false|read-only|Embedded RouterModule HWInv object array representing subcomponents of that type (if query is hierarchical).|

<h2 id="tocS_HWInvByLocComputeModule">HWInvByLocComputeModule</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyloccomputemodule"></a>
<a id="schema_HWInvByLocComputeModule"></a>
<a id="tocShwinvbyloccomputemodule"></a>
<a id="tocshwinvbyloccomputemodule"></a>

```json
{
  "ComputeModuleLocationInfo": {
    "Id": "string",
    "Name": "string",
    "Description": "string",
    "Hostname": "string"
  },
  "NodeEnclosures": [
    {
      "NodeEnclosureLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ]
}

```

This is a subtype of HWInventoryByLocation for HMSType ComputeModule. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocComputeModule'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» ComputeModuleLocationInfo|[HWInventory.1.0.0_RedfishChassisLocationInfo](#schemahwinventory.1.0.0_redfishchassislocationinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|
|» NodeEnclosures|[[HWInvByLocNodeEnclosure](#schemahwinvbylocnodeenclosure)]|false|read-only|Embedded NodeEnclosure HWInv object array representing subcomponents of that type (if query is hierarchical).|

<h2 id="tocS_HWInvByLocRouterModule">HWInvByLocRouterModule</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocroutermodule"></a>
<a id="schema_HWInvByLocRouterModule"></a>
<a id="tocShwinvbylocroutermodule"></a>
<a id="tocshwinvbylocroutermodule"></a>

```json
{
  "RouterModuleLocationInfo": {
    "Id": "string",
    "Name": "string",
    "Description": "string",
    "Hostname": "string"
  },
  "HSNBoards": [
    {
      "HSNBoardLocationInfo": {
        "Id": "string",
        "Name": "string",
        "Description": "string",
        "Hostname": "string"
      }
    }
  ]
}

```

This is a subtype of HWInventoryByLocation for HMSType RouterModule. This is a Mountain switch module. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocRouterModule'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» RouterModuleLocationInfo|[HWInventory.1.0.0_RedfishChassisLocationInfo](#schemahwinventory.1.0.0_redfishchassislocationinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|
|» HSNBoards|[[HWInvByLocHSNBoard](#schemahwinvbylochsnboard)]|false|read-only|Embedded HSNBoard HWInv object array representing subcomponents of that type (if query is hierarchical).|

<h2 id="tocS_HWInvByLocNodeEnclosure">HWInvByLocNodeEnclosure</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocnodeenclosure"></a>
<a id="schema_HWInvByLocNodeEnclosure"></a>
<a id="tocShwinvbylocnodeenclosure"></a>
<a id="tocshwinvbylocnodeenclosure"></a>

```json
{
  "NodeEnclosureLocationInfo": {
    "Id": "string",
    "Name": "string",
    "Description": "string",
    "Hostname": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType NodeEnclosure. It represents a Mountain node card or River rack enclosure.  It is NOT the BMC, which is separate and corresponds to a Redfish Manager. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocNodeEnclosure'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeEnclosureLocationInfo|[HWInventory.1.0.0_RedfishChassisLocationInfo](#schemahwinventory.1.0.0_redfishchassislocationinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocHSNBoard">HWInvByLocHSNBoard</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylochsnboard"></a>
<a id="schema_HWInvByLocHSNBoard"></a>
<a id="tocShwinvbylochsnboard"></a>
<a id="tocshwinvbylochsnboard"></a>

```json
{
  "HSNBoardLocationInfo": {
    "Id": "string",
    "Name": "string",
    "Description": "string",
    "Hostname": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType HSNBoard. It represents a Mountain switch card or River TOR enclosure.  It is NOT the BMC, which is separate and corresponds to a Redfish Manager. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocHSNBoard'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» HSNBoardLocationInfo|[HWInventory.1.0.0_RedfishChassisLocationInfo](#schemahwinventory.1.0.0_redfishchassislocationinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocMgmtSwitch">HWInvByLocMgmtSwitch</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocmgmtswitch"></a>
<a id="schema_HWInvByLocMgmtSwitch"></a>
<a id="tocShwinvbylocmgmtswitch"></a>
<a id="tocshwinvbylocmgmtswitch"></a>

```json
{
  "MgmtSwitchLocationInfo": {
    "Id": "string",
    "Name": "string",
    "Description": "string",
    "Hostname": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType MgmtSwitch. It represents a management switch.  It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocMgmtSwitch'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» MgmtSwitchLocationInfo|[HWInventory.1.0.0_RedfishChassisLocationInfo](#schemahwinventory.1.0.0_redfishchassislocationinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocMgmtHLSwitch">HWInvByLocMgmtHLSwitch</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocmgmthlswitch"></a>
<a id="schema_HWInvByLocMgmtHLSwitch"></a>
<a id="tocShwinvbylocmgmthlswitch"></a>
<a id="tocshwinvbylocmgmthlswitch"></a>

```json
{
  "MgmtHLSwitchLocationInfo": {
    "Id": "string",
    "Name": "string",
    "Description": "string",
    "Hostname": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType MgmtHLSwitch. It represents a high level management switch.  It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocMgmtHLSwitch'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» MgmtHLSwitchLocationInfo|[HWInventory.1.0.0_RedfishChassisLocationInfo](#schemahwinventory.1.0.0_redfishchassislocationinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocCDUMgmtSwitch">HWInvByLocCDUMgmtSwitch</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyloccdumgmtswitch"></a>
<a id="schema_HWInvByLocCDUMgmtSwitch"></a>
<a id="tocShwinvbyloccdumgmtswitch"></a>
<a id="tocshwinvbyloccdumgmtswitch"></a>

```json
{
  "CDUMgmtSwitchLocationInfo": {
    "Id": "string",
    "Name": "string",
    "Description": "string",
    "Hostname": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType CDUMgmtSwitch. It represents a CDU management switch.  It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocCDUMgmtSwitch'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» CDUMgmtSwitchLocationInfo|[HWInventory.1.0.0_RedfishChassisLocationInfo](#schemahwinventory.1.0.0_redfishchassislocationinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocNode">HWInvByLocNode</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocnode"></a>
<a id="schema_HWInvByLocNode"></a>
<a id="tocShwinvbylocnode"></a>
<a id="tocshwinvbylocnode"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "Type": "Node",
  "Ordinal": 0,
  "Status": "Populated",
  "HWInventoryByLocationType": "HWInvByLocNode",
  "NodeLocationInfo": {
    "Id": "System.Embedded.1",
    "Name": "Name describing system or where it is located, per manufacturing",
    "Description": "Description of system/node type, per manufacturing",
    "Hostname": "if_defined_in_Redfish",
    "ProcessorSummary": {
      "Count": 2,
      "Model": "Multi-Core Intel(R) Xeon(R) processor E5-16xx Series"
    },
    "MemorySummary": {
      "TotalSystemMemoryGiB": 64
    }
  },
  "PopulatedFRU": {
    "FRUID": "Dell-99999-1234.1234.2345",
    "Type": "Node",
    "Subtype": "River",
    "HWInventoryByFRUType": "HWInvByFRUNode",
    "NodeFRUInfo": {
      "AssetTag": "AdminAssignedAssetTag",
      "BiosVersion": "v1.0.2.9999",
      "Model": "OKS0P2354",
      "Manufacturer": "Dell",
      "PartNumber": "p99999",
      "SerialNumber": "1234.1234.2345",
      "SKU": "as213234",
      "SystemType": "Physical",
      "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
    }
  },
  "Processors": [
    {
      "ID": "x0c0s0b0n0p0",
      "Type": "Processor",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocProcessor",
      "ProcessorLocationInfo": {
        "Id": "CPU1",
        "Name": "Processor",
        "Description": "Socket 1 Processor",
        "Socket": "CPU 1"
      },
      "PopulatedFRU": {
        "FRUID": "HOW-TO-ID-CPUS-FROM-REDFISH-IF-AT-ALL",
        "Type": "Processor",
        "Subtype": "SKL24",
        "HWInventoryByFRUType": "HWInvByFRUProcessor",
        "ProcessorFRUInfo": {
          "InstructionSet": "x86-64",
          "Manufacturer": "Intel",
          "MaxSpeedMHz": 2600,
          "Model": "Intel(R) Xeon(R) CPU E5-2623 v4 @ 2.60GHz",
          "ProcessorArchitecture": "x86",
          "ProcessorId": {
            "EffectiveFamily": 6,
            "EffectiveModel": 79,
            "IdentificationRegisters": 263921,
            "MicrocodeInfo": 184549399,
            "Step": 1,
            "VendorID": "GenuineIntel"
          },
          "ProcessorType": "CPU",
          "TotalCores": 24,
          "TotalThreads": 48
        }
      }
    },
    {
      "ID": "x0c0s0b0n0p1",
      "Type": "Processor",
      "Ordinal": 1,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocProcessor",
      "ProcessorLocationInfo": {
        "Id": "CPU2",
        "Name": "Processor",
        "Description": "Socket 2 Processor",
        "Socket": "CPU 2"
      },
      "PopulatedFRU": {
        "FRUID": "HOW-TO-ID-CPUS-FROM-REDFISH-IF-AT-ALL",
        "Type": "Processor",
        "Subtype": "SKL24",
        "HWInventoryByFRUType": "HWInvByFRUProcessor",
        "ProcessorFRUInfo": {
          "InstructionSet": "x86-64",
          "Manufacturer": "Intel",
          "MaxSpeedMHz": 2600,
          "Model": "Intel(R) Xeon(R) CPU E5-2623 v4 @ 2.60GHz",
          "ProcessorArchitecture": "x86",
          "ProcessorId": {
            "EffectiveFamily": 6,
            "EffectiveModel": 79,
            "IdentificationRegisters": 263921,
            "MicrocodeInfo": 184549399,
            "Step": 1,
            "VendorID": "GenuineIntel"
          },
          "ProcessorType": "CPU",
          "TotalCores": 24,
          "TotalThreads": 48
        }
      }
    }
  ],
  "Memory": [
    {
      "ID": "x0c0s0b0n0d0",
      "Type": "Memory",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocMemory",
      "MemoryLocationInfo": {
        "Id": "DIMM1",
        "Name": "DIMM Slot 1",
        "MemoryLocation": {
          "Socket": 1,
          "MemoryController": 1,
          "Channel": 1,
          "Slot": 1
        }
      },
      "PopulatedFRU": {
        "FRUID": "MFR-PARTNUMBER-SERIALNUMBER",
        "Type": "Memory",
        "Subtype": "DIMM2400G32",
        "HWInventoryByFRUType": "HWInvByFRUMemory",
        "MemoryFRUInfo": {
          "BaseModuleType": "RDIMM",
          "BusWidthBits": 72,
          "CapacityMiB": 32768,
          "DataWidthBits": 64,
          "ErrorCorrection": "MultiBitECC",
          "Manufacturer": "Micron",
          "MemoryType": "DRAM",
          "MemoryDeviceType": "DDR4",
          "OperatingSpeedMhz": 2400,
          "PartNumber": "XYZ-123-1232",
          "RankCount": 2,
          "SerialNumber": "sn12344567689"
        }
      }
    },
    {
      "ID": "x0c0s0b0n0d1",
      "Type": "Memory",
      "Ordinal": 1,
      "Status": "Empty",
      "HWInventoryByLocationType": "HWInvByLocMemory",
      "MemoryLocationInfo": {
        "Id": "DIMM2",
        "Name": "Socket 1 DIMM Slot 2",
        "MemoryLocation": {
          "Socket": 1,
          "MemoryController": 1,
          "Channel": 1,
          "Slot": 2
        }
      },
      "PopulatedFRU": null
    },
    {
      "ID": "x0c0s0b0n0d2",
      "Type": "Memory",
      "Ordinal": 2,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocMemory",
      "MemoryLocationInfo": {
        "Id": "DIMM3",
        "Name": "Socket 2 DIMM Slot 1",
        "MemoryLocation": {
          "Socket": 2,
          "MemoryController": 2,
          "Channel": 1,
          "Slot": 1
        }
      },
      "PopulatedFRU": {
        "FRUID": "MFR-PARTNUMBER-SERIALNUMBER_2",
        "Type": "Memory",
        "Subtype": "DIMM2400G32",
        "HWInventoryByFRUType": "HWInvByFRUMemory",
        "MemoryFRUInfo": {
          "BaseModuleType": "RDIMM",
          "BusWidthBits": 72,
          "CapacityMiB": 32768,
          "DataWidthBits": 64,
          "ErrorCorrection": "MultiBitECC",
          "Manufacturer": "Micron",
          "MemoryType": "DRAM",
          "MemoryDeviceType": "DDR4",
          "OperatingSpeedMhz": 2400,
          "PartNumber": "XYZ-123-1232",
          "RankCount": 2,
          "SerialNumber": "k346456346346"
        }
      }
    },
    {
      "ID": "x0c0s0b0n0d3",
      "Type": "Memory",
      "Ordinal": 3,
      "Status": "Empty",
      "HWInventoryByLocationType": "HWInvByLocMemory",
      "MemoryLocationInfo": {
        "Id": "DIMM3",
        "Name": "Socket 2 DIMM Slot 2",
        "MemoryLocation": {
          "Socket": 2,
          "MemoryController": 2,
          "Channel": 1,
          "Slot": 2
        }
      },
      "PopulatedFRU": null
    }
  ]
}

```

This is a subtype of HWInventoryByLocation for HMSType Node. It represents a service, compute, or system node. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocNode'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeLocationInfo|[HWInventory.1.0.0_RedfishSystemLocationInfo](#schemahwinventory.1.0.0_redfishsystemlocationinfo)|false|none|These are pass-through properties of the Redfish ComputerSystem object that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|
|» Processors|[[HWInvByLocProcessor](#schemahwinvbylocprocessor)]|false|read-only|Embedded Processor HWInv object array representing subcomponents of that type (this is default for Nodes).|
|» NodeAccels|[[HWInvByLocNodeAccel](#schemahwinvbylocnodeaccel)]|false|read-only|Embedded NodeAccel HWInv object array representing subcomponents of that type (this is default for Nodes).|
|» Drives|[[HWInvByLocDrive](#schemahwinvbylocdrive)]|false|read-only|Embedded Drives HWInv object array representing subcomponents of that type (this is default for Nodes).|
|» Memory|[[HWInvByLocMemory](#schemahwinvbylocmemory)]|false|read-only|Embedded Memory HWInv object array representing subcomponents of that type (this is default for Nodes).|
|» NodeAccelRisers|[[HWInvByLocNodeAccelRiser](#schemahwinvbylocnodeaccelriser)]|false|read-only|Embedded NodeAccelRiser HWInv object array representing subcomponents of that type (this is default for Nodes).|
|» NodeHsnNICs|[[HWInvByLocHSNNIC](#schemahwinvbylochsnnic)]|false|read-only|Embedded NodeHsnNIC HWInv object array representing subcomponents of that type (this is default for Nodes).|

<h2 id="tocS_HWInvByLocProcessor">HWInvByLocProcessor</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocprocessor"></a>
<a id="schema_HWInvByLocProcessor"></a>
<a id="tocShwinvbylocprocessor"></a>
<a id="tocshwinvbylocprocessor"></a>

```json
{
  "description": "By default, listed as subcomponent of Node, see example there."
}

```

This is a subtype of HWInventoryByLocation for HMSType Processor. It represents a primary CPU type (e.g. non-accelerator). It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocProcessor'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» ProcessorLocationInfo|[HWInventory.1.0.0_RedfishProcessorLocationInfo](#schemahwinventory.1.0.0_redfishprocessorlocationinfo)|false|none|These are pass-through properties of the Redfish Processor object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocNodeAccel">HWInvByLocNodeAccel</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocnodeaccel"></a>
<a id="schema_HWInvByLocNodeAccel"></a>
<a id="tocShwinvbylocnodeaccel"></a>
<a id="tocshwinvbylocnodeaccel"></a>

```json
{
  "description": "By default, listed as subcomponent of Node."
}

```

This is a subtype of HWInventoryByLocation for HMSType NodeAccel. It represents a GPU type (e.g. accelerator). It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocNodeAccel'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeAccelLocationInfo|[HWInventory.1.0.0_RedfishProcessorLocationInfo](#schemahwinventory.1.0.0_redfishprocessorlocationinfo)|false|none|These are pass-through properties of the Redfish Processor object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocDrive">HWInvByLocDrive</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocdrive"></a>
<a id="schema_HWInvByLocDrive"></a>
<a id="tocShwinvbylocdrive"></a>
<a id="tocshwinvbylocdrive"></a>

```json
{
  "description": "By default, listed as subcomponent of Node, see example there."
}

```

This is a subtype of HWInventoryByLocation for HMSType Drive. It represents a disk drive. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocDrive'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» DriveLocationInfo|[HWInventory.1.0.0_RedfishDriveLocationInfo](#schemahwinventory.1.0.0_redfishdrivelocationinfo)|false|none|These are pass-through properties of the Redfish Drive object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocMemory">HWInvByLocMemory</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocmemory"></a>
<a id="schema_HWInvByLocMemory"></a>
<a id="tocShwinvbylocmemory"></a>
<a id="tocshwinvbylocmemory"></a>

```json
{
  "description": "By default, listed as subcomponent of Node, see example there."
}

```

This is a subtype of HWInventoryByLocation for HMSType Memory. It represents a DIMM or other memory module type. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocMemory'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» MemoryLocationInfo|[HWInventory.1.0.0_RedfishMemoryLocationInfo](#schemahwinventory.1.0.0_redfishmemorylocationinfo)|false|none|These are pass-through properties of the Redfish Memory object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocPDU">HWInvByLocPDU</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocpdu"></a>
<a id="schema_HWInvByLocPDU"></a>
<a id="tocShwinvbylocpdu"></a>
<a id="tocshwinvbylocpdu"></a>

```json
{
  "ID": "x0m0p0",
  "Type": "CabinetPDU",
  "Ordinal": 0,
  "Status": "Populated",
  "HWInventoryByLocationType": "HWInvByLocPDU",
  "PDULocationInfo": {
    "Id": "1",
    "Name": "RackPDU1",
    "Description": "Description of PDU, per manufacturing",
    "UUID": "32354641-4135-4332-4a35-313735303734"
  },
  "PopulatedFRU": {
    "FRUID": "CabinetPDU.29347ZT536",
    "Type": "CabinetPDU",
    "HWInventoryByFRUType": "HWInvByFRUPDU",
    "PDUFRUInfo": {
      "FirmwareVersion": "4.3.0",
      "EquipmentType": "RackPDU",
      "Manufacturer": "Contoso",
      "CircuitSummary": {
        "TotalPhases": 3,
        "TotalBranches": 4,
        "TotalOutlets": 16,
        "MonitoredPhases": 3,
        "ControlledOutlets": 8,
        "MonitoredBranches": 4,
        "MonitoredOutlets": 12
      },
      "AssetTag": "PDX-92381",
      "DateOfManufacture": "2017-01-11T08:00:00Z",
      "HardwareRevision": "1.03b",
      "Model": "ZAP4000",
      "SerialNumber": "29347ZT536",
      "PartNumber": "AA-23"
    }
  },
  "CabinetPDUPowerConnectors": [
    {
      "ID": "x0m0p0v1",
      "Type": "CabinetPDUPowerConnector",
      "Ordinal": 0,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocOutlet",
      "OutletLocationInfo": {
        "Id": "A1",
        "Name": "Outlet A1, Branch Circuit A",
        "Description": "Outlet description"
      },
      "PopulatedFRU": {
        "FRUID": "CabinetPDUPowerConnector.0.CabinetPDU.29347ZT536",
        "Type": "CabinetPDUPowerConnector",
        "HWInventoryByFRUType": "HWInvByFRUOutlet",
        "OutletFRUInfo": {
          "PowerEnabled": true,
          "NominalVoltage": "AC120V",
          "RatedCurrentAmps": 20,
          "VoltageType": "AC",
          "OutletType": "NEMA_5_20R",
          "PhaseWiringType": "OnePhase3Wire"
        }
      }
    },
    {
      "ID": "x0m0p0v2",
      "Type": "CabinetPDUPowerConnector",
      "Ordinal": 2,
      "Status": "Populated",
      "HWInventoryByLocationType": "HWInvByLocOutlet",
      "OutletLocationInfo": {
        "Id": "A2",
        "Name": "Outlet A2, Branch Circuit A",
        "Description": "Outlet description"
      },
      "PopulatedFRU": {
        "FRUID": "CabinetPDUPowerConnector.1.CabinetPDU.29347ZT536",
        "Type": "CabinetPDUPowerConnector",
        "HWInventoryByFRUType": "HWInvByFRUOutlet",
        "OutletFRUInfo": {
          "PowerEnabled": true,
          "NominalVoltage": "AC120V",
          "RatedCurrentAmps": 20,
          "VoltageType": "AC",
          "OutletType": "NEMA_5_20R",
          "PhaseWiringType": "OnePhase3Wire"
        }
      }
    }
  ]
}

```

This is a subtype of HWInventoryByLocation for HMSType CabinetPDU. It represents a master or slave PowerDistribution aka PDU component. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocPDU'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» PDULocationInfo|[HWInventory.1.0.0_RedfishPDULocationInfo](#schemahwinventory.1.0.0_redfishpdulocationinfo)|false|none|These are pass-through properties of the Redfish PowerDistribution object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|
|» CabinetPDUPowerConnectors|[[HWInvByLocOutlet](#schemahwinvbylocoutlet)]|false|read-only|Embedded Outlets HWInv object array representing outlets of this PDU.|

<h2 id="tocS_HWInvByLocOutlet">HWInvByLocOutlet</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocoutlet"></a>
<a id="schema_HWInvByLocOutlet"></a>
<a id="tocShwinvbylocoutlet"></a>
<a id="tocshwinvbylocoutlet"></a>

```json
{
  "description": "By default, listed as subcomponent of PDU, see example there."
}

```

This is a subtype of HWInventoryByLocation for HMSType CabinetPDUPowerConnector. It an outlet that is a child of of a parent master or slave PDU. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocOutlet'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» OutletLocationInfo|[HWInventory.1.0.0_RedfishOutletLocationInfo](#schemahwinventory.1.0.0_redfishoutletlocationinfo)|false|none|These are pass-through properties of the Redfish PDU Outlet object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocCMMRectifier">HWInvByLocCMMRectifier</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyloccmmrectifier"></a>
<a id="schema_HWInvByLocCMMRectifier"></a>
<a id="tocShwinvbyloccmmrectifier"></a>
<a id="tocshwinvbyloccmmrectifier"></a>

```json
{
  "CMMRectifierLocationInfo": {
    "Name": "string",
    "FirmwareVersion": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType CMMRectifier. It represents a power supply. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocCMMRectifier'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» CMMRectifierLocationInfo|[HWInventory.1.0.0_RedfishCMMRectifierLocationInfo](#schemahwinventory.1.0.0_redfishcmmrectifierlocationinfo)|false|none|These are pass-through properties of the Redfish Power Supply object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocNodeAccelRiser">HWInvByLocNodeAccelRiser</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocnodeaccelriser"></a>
<a id="schema_HWInvByLocNodeAccelRiser"></a>
<a id="tocShwinvbylocnodeaccelriser"></a>
<a id="tocshwinvbylocnodeaccelriser"></a>

```json
{
  "NodeAccelRiserLocationInfo": {
    "Name": "string",
    "Description": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType NodeAccelRiser. It represents a GPUSubsystem baseboard. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocNodeAccelRiser'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeAccelRiserLocationInfo|[HWInventory.1.0.0_RedfishNodeAccelRiserLocationInfo](#schemahwinventory.1.0.0_redfishnodeaccelriserlocationinfo)|false|none|These are the properties of the NodeAccelRiser type that are passed-through to the HMS inventory data when the underlying Redfish object  type is an Assembly with a PhysicalContext of GPUSubsystem.  These are the properties of a specific hardware instance/FRU that may change if the component is relocated within the system.  Child of a Chassis.|

<h2 id="tocS_HWInvByLocNodeEnclosurePowerSupply">HWInvByLocNodeEnclosurePowerSupply</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocnodeenclosurepowersupply"></a>
<a id="schema_HWInvByLocNodeEnclosurePowerSupply"></a>
<a id="tocShwinvbylocnodeenclosurepowersupply"></a>
<a id="tocshwinvbylocnodeenclosurepowersupply"></a>

```json
{
  "NodeEnclosurePowerSupplyLocationInfo": {
    "Name": "string",
    "FirmwareVersion": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType NodeEnclosurePowerSupply. It represents a power supply. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocNodeEnclosurePowerSupply'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeEnclosurePowerSupplyLocationInfo|[HWInventory.1.0.0_RedfishNodeEnclosurePowerSupplyLocationInfo](#schemahwinventory.1.0.0_redfishnodeenclosurepowersupplylocationinfo)|false|none|These are pass-through properties of the Redfish Power Supply object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocNodeBMC">HWInvByLocNodeBMC</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocnodebmc"></a>
<a id="schema_HWInvByLocNodeBMC"></a>
<a id="tocShwinvbylocnodebmc"></a>
<a id="tocshwinvbylocnodebmc"></a>

```json
{
  "NodeBMCLocationInfo": {
    "DateTime": "string",
    "DateTimeLocalOffset": "string",
    "Description": "string",
    "FirmwareVersion": "string",
    "Id": "string",
    "Name": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType NodeBMC. It represents a NodeBMC. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocNodeBMC'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeBMCLocationInfo|[HWInventory.1.0.0_RedfishManagerLocationInfo](#schemahwinventory.1.0.0_redfishmanagerlocationinfo)|false|none|These are pass-through properties of the Redfish Manager object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocRouterBMC">HWInvByLocRouterBMC</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylocrouterbmc"></a>
<a id="schema_HWInvByLocRouterBMC"></a>
<a id="tocShwinvbylocrouterbmc"></a>
<a id="tocshwinvbylocrouterbmc"></a>

```json
{
  "RouterBMCLocationInfo": {
    "DateTime": "string",
    "DateTimeLocalOffset": "string",
    "Description": "string",
    "FirmwareVersion": "string",
    "Id": "string",
    "Name": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType RouterBMC. It represents a RouterBMC. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocRouterBMC'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» RouterBMCLocationInfo|[HWInventory.1.0.0_RedfishManagerLocationInfo](#schemahwinventory.1.0.0_redfishmanagerlocationinfo)|false|none|These are pass-through properties of the Redfish Manager object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInvByLocHSNNIC">HWInvByLocHSNNIC</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbylochsnnic"></a>
<a id="schema_HWInvByLocHSNNIC"></a>
<a id="tocShwinvbylochsnnic"></a>
<a id="tocshwinvbylochsnnic"></a>

```json
{
  "HSNNICLocationInfo": {
    "Description": "string",
    "Id": "string",
    "Name": "string"
  }
}

```

This is a subtype of HWInventoryByLocation for HMSType NodeHSNNIC. It represents a NodeHSNNIC. It is selected via the 'discriminator: HWInventoryByLocationType' of HWInventoryByLocation when HWInventoryByLocationType is 'HWInvByLocHSNNIC'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByLocation.HWInventoryByLocationType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByLocation](#schemahwinventory.1.0.0_hwinventorybylocation)|false|none|This is the basic entry in the hardware inventory for a particular location/xname.  If the location is populated (e.g. if a slot for a blade exists and the blade is present), then there will also be a link to the FRU entry for the physical piece of hardware that occupies it.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» HSNNICLocationInfo|[HWInventory.1.0.0_HSNNICLocationInfo](#schemahwinventory.1.0.0_hsnniclocationinfo)|false|none|These are pass-through properties of the Node HSN NIC object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.|

<h2 id="tocS_HWInventory.1.0.0_RedfishChassisLocationInfo">HWInventory.1.0.0_RedfishChassisLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishchassislocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishChassisLocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishchassislocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishchassislocationinfo"></a>

```json
{
  "Id": "string",
  "Name": "string",
  "Description": "string",
  "Hostname": "string"
}

```

These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Id|string|false|read-only|This is a pass-through of the Redfish value of the same name. The Id is included for informational purposes.  The RedfishEndpoint objects are intended to help locate and interact with HMS components via the Redfish endpoint, so this is mostly needed in case servicing the component requires its ID/name according to a particular COTS manufacturer's naming scheme within, for example, a particular server enclosure.|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|
|Description|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is an informational description set by the BMC implementation.|
|Hostname|string|false|read-only|This is a pass-through of the Redfish value of the same name. Note this is simply what (if anything) Redfish has been told the hostname is.  It isn't necessarily its hostname on any particular network interface (e.g. the HMS management network).|

<h2 id="tocS_HWInventory.1.0.0_RedfishSystemLocationInfo">HWInventory.1.0.0_RedfishSystemLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishsystemlocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishSystemLocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishsystemlocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishsystemlocationinfo"></a>

```json
{
  "Id": "string",
  "Name": "string",
  "Description": "string",
  "Hostname": "string",
  "ProcessorSummary": {
    "Count": 0,
    "Model": "string"
  },
  "MemorySummary": {
    "TotalSystemMemoryGiB": 0
  }
}

```

These are pass-through properties of the Redfish ComputerSystem object that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Id|string|false|read-only|This is a pass-through of the Redfish value of the same name. The Id is included for informational purposes.  The RedfishEndpoint objects are intended to help locate and interact with HMS components via the Redfish endpoint, so this is mostly needed in case servicing the component requires its ID/name according to a particular COTS manufacturer's naming scheme within, for example, a particular server enclosure.|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|
|Description|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is an informational description set by the BMC implementation.|
|Hostname|string|false|read-only|This is a pass-through of the Redfish value of the same name. Note this is simply what (if anything) Redfish has been told the hostname is.  It isn't necessarily its hostname on any particular network interface (e.g. the HMS management network).|
|ProcessorSummary|object|false|read-only|This is a summary of the installed processors, if any. It is taken from ComputerSystem.1.0.0_ProcessorSummary.|
|» Count|number|false|read-only|The number of processors in the system.|
|» Model|string|false|read-only|The processor model for the primary or majority of processors in this system.|
|MemorySummary|object|false|read-only|This object describes the memory of the system in general detail. It is taken from ComputerSystem.1.0.0_MemorySummary.|
|» TotalSystemMemoryGiB|number|false|read-only|The total installed, operating system-accessible memory (RAM), measured in GiB.|

<h2 id="tocS_HWInventory.1.0.0_RedfishProcessorLocationInfo">HWInventory.1.0.0_RedfishProcessorLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishprocessorlocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishProcessorLocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishprocessorlocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishprocessorlocationinfo"></a>

```json
{
  "Id": "string",
  "Name": "string",
  "Description": "string",
  "Socket": "string"
}

```

These are pass-through properties of the Redfish Processor object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Id|string|false|read-only|This is a pass-through of the Redfish value of the same name. The Id is included for informational purposes.  The RedfishEndpoint objects are intended to help locate and interact with HMS components via the Redfish endpoint, so this is mostly needed in case servicing the component requires its ID/name according to a particular COTS manufacturer's naming scheme within, for example, a particular server enclosure.|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|
|Description|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is an informational description set by the BMC implementation.|
|Socket|string|false|read-only|This is a pass-through of the Redfish value of the same name. It represents the socket or location of the processor, and may differ from the normalized HMS Ordinal value (or xname) that is always indexed from 0.  Manufacturers may or may not use zero indexing (or may have some other naming scheme for sockets) and so we retain this information to resolve any ambiguity when servicing the component.|

<h2 id="tocS_HWInventory.1.0.0_RedfishDriveLocationInfo">HWInventory.1.0.0_RedfishDriveLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishdrivelocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishDriveLocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishdrivelocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishdrivelocationinfo"></a>

```json
{
  "Id": "string",
  "Name": "string",
  "Description": "string"
}

```

These are pass-through properties of the Redfish Drive object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Id|string|false|read-only|This is a pass-through of the Redfish value of the same name. The Id is included for informational purposes.  The RedfishEndpoint objects are intended to help locate and interact with HMS components via the Redfish endpoint, so this is mostly needed in case servicing the component requires its ID/name according to a particular COTS manufacturer's naming scheme within, for example, a particular server enclosure.|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|
|Description|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is an informational description set by the BMC implementation.|

<h2 id="tocS_HWInventory.1.0.0_RedfishMemoryLocationInfo">HWInventory.1.0.0_RedfishMemoryLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishmemorylocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishMemoryLocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishmemorylocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishmemorylocationinfo"></a>

```json
{
  "Id": "string",
  "Name": "string",
  "Description": "string",
  "MemoryLocation": {
    "Socket": 0,
    "MemoryController": 0,
    "Channel": 0,
    "Slot": 0
  }
}

```

These are pass-through properties of the Redfish Memory object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Id|string|false|read-only|This is a pass-through of the Redfish value of the same name. The Id is included for informational purposes.  The RedfishEndpoint objects are intended to help locate and interact with HMS components via the Redfish endpoint, so this is mostly needed in case servicing the component requires its ID/name according to a particular COTS manufacturer's naming scheme within, for example, a particular server enclosure.|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|
|Description|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is an informational description set by the BMC implementation.|
|MemoryLocation|object|false|none|Describes the location of the memory module.  Note that the indexing of these fields are set by the manufacturer and may not start at zero (or one for that matter) and therefore are for informational/servicing purposes only. This object and its fields are again a pass-through from Redfish.|
|» Socket|number|false|read-only|Socket number (numbering may vary by manufacturer).|
|» MemoryController|number|false|read-only|Memory controller number (numbering may vary by manufacturer).|
|» Channel|number|false|read-only|Channel number (numbering may vary by manufacturer).|
|» Slot|number|false|read-only|Slot number (numbering may vary by manufacturer).|

<h2 id="tocS_HWInventory.1.0.0_RedfishPDULocationInfo">HWInventory.1.0.0_RedfishPDULocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishpdulocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishPDULocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishpdulocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishpdulocationinfo"></a>

```json
{
  "Id": "string",
  "Name": "string",
  "Description": "string",
  "UUID": "string"
}

```

These are pass-through properties of the Redfish PowerDistribution object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Id|string|false|read-only|This is a pass-through of the Redfish value of the same name. The Id is included for informational purposes.  The RedfishEndpoint objects are intended to help locate and interact with HMS components via the Redfish endpoint, so this is mostly needed in case servicing the component requires its ID/name according to a particular COTS manufacturers naming scheme within, for example, a particular server enclosure.|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|
|Description|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is an informational description set by the implementation.|
|UUID|string|false|read-only|This is a pass-through of the Redfish value of the same name.|

<h2 id="tocS_HWInventory.1.0.0_RedfishOutletLocationInfo">HWInventory.1.0.0_RedfishOutletLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishoutletlocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishOutletLocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishoutletlocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishoutletlocationinfo"></a>

```json
{
  "Id": "string",
  "Name": "string",
  "Description": "string"
}

```

These are pass-through properties of the Redfish PDU Outlet object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Id|string|false|read-only|This is a pass-through of the Redfish value of the same name. The Id is included for informational purposes.  The RedfishEndpoint objects are intended to help locate and interact with HMS components via the Redfish endpoint, so this is mostly needed in case servicing the component requires its ID/name according to a particular COTS manufacturers naming scheme within, for example, a particular server enclosure.|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|
|Description|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is an informational description set by the implementation.|

<h2 id="tocS_HWInventory.1.0.0_RedfishCMMRectifierLocationInfo">HWInventory.1.0.0_RedfishCMMRectifierLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishcmmrectifierlocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishCMMRectifierLocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishcmmrectifierlocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishcmmrectifierlocationinfo"></a>

```json
{
  "Name": "string",
  "FirmwareVersion": "string"
}

```

These are pass-through properties of the Redfish Power Supply object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|
|FirmwareVersion|string|false|read-only|This is a pass-through of the Redfish value of the same name.|

<h2 id="tocS_HWInventory.1.0.0_RedfishNodeAccelRiserLocationInfo">HWInventory.1.0.0_RedfishNodeAccelRiserLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishnodeaccelriserlocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishNodeAccelRiserLocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishnodeaccelriserlocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishnodeaccelriserlocationinfo"></a>

```json
{
  "Name": "string",
  "Description": "string"
}

```

These are the properties of the NodeAccelRiser type that are passed-through to the HMS inventory data when the underlying Redfish object  type is an Assembly with a PhysicalContext of GPUSubsystem.  These are the properties of a specific hardware instance/FRU that may change if the component is relocated within the system.  Child of a Chassis.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|
|Description|string|false|read-only|This is a pass-through of the Redfish value of the same name.|

<h2 id="tocS_HWInventory.1.0.0_RedfishNodeEnclosurePowerSupplyLocationInfo">HWInventory.1.0.0_RedfishNodeEnclosurePowerSupplyLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishnodeenclosurepowersupplylocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishNodeEnclosurePowerSupplyLocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishnodeenclosurepowersupplylocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishnodeenclosurepowersupplylocationinfo"></a>

```json
{
  "Name": "string",
  "FirmwareVersion": "string"
}

```

These are pass-through properties of the Redfish Power Supply object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|
|FirmwareVersion|string|false|read-only|This is a pass-through of the Redfish value of the same name.|

<h2 id="tocS_HWInventory.1.0.0_RedfishManagerLocationInfo">HWInventory.1.0.0_RedfishManagerLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishmanagerlocationinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishManagerLocationInfo"></a>
<a id="tocShwinventory.1.0.0_redfishmanagerlocationinfo"></a>
<a id="tocshwinventory.1.0.0_redfishmanagerlocationinfo"></a>

```json
{
  "DateTime": "string",
  "DateTimeLocalOffset": "string",
  "Description": "string",
  "FirmwareVersion": "string",
  "Id": "string",
  "Name": "string"
}

```

These are pass-through properties of the Redfish Manager object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|DateTime|string|false|read-only|This is a pass-through of the Redfish value of the same name. The current date and time with UTC offset that the manager uses to set or read time.|
|DateTimeLocalOffset|string|false|read-only|This is a pass-through of the Redfish value of the same name. The time offset from UTC that the DateTime property is in +HH:MM format.|
|Description|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is an informational description set by the implementation.|
|FirmwareVersion|string|false|read-only|This is a pass-through of the Redfish value of the same name.|
|Id|string|false|read-only|This is a pass-through of the Redfish value of the same name. The Id is included for informational purposes.  The RedfishEndpoint objects are intended to help locate and interact with HMS components via the Redfish endpoint, so this is mostly needed in case servicing the component requires its ID/name according to a particular COTS manufacturers naming scheme within, for example, a particular server enclosure.|
|Name|string|false|read-only|This is a pass-through of the Redfish value of the same name. This is included for informational purposes as the naming will likely vary from manufacturer-to-manufacturer, but should help match items up to manufacturer's documentation if the normalized HMS naming scheme is too vague for some COTS systems.|

<h2 id="tocS_HWInventory.1.0.0_HSNNICLocationInfo">HWInventory.1.0.0_HSNNICLocationInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_hsnniclocationinfo"></a>
<a id="schema_HWInventory.1.0.0_HSNNICLocationInfo"></a>
<a id="tocShwinventory.1.0.0_hsnniclocationinfo"></a>
<a id="tocshwinventory.1.0.0_hsnniclocationinfo"></a>

```json
{
  "Description": "string",
  "Id": "string",
  "Name": "string"
}

```

These are pass-through properties of the Node HSN NIC object type that are also used in HMS inventory data.  They will be mostly informational as exactly how fields are set depends on how the particular implementation does things, but will be useful for servicing.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Description|string|false|none|This is a pass-through of the Redfish value of the same name.|
|Id|string|false|none|This is a pass-through of the Redfish value of the same name.|
|Name|string|false|none|This is a pass-through of the Redfish value of the same name.|

<h2 id="tocS_HWInventory.1.0.0_HWInventoryByFRU">HWInventory.1.0.0_HWInventoryByFRU</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_hwinventorybyfru"></a>
<a id="schema_HWInventory.1.0.0_HWInventoryByFRU"></a>
<a id="tocShwinventory.1.0.0_hwinventorybyfru"></a>
<a id="tocshwinventory.1.0.0_hwinventorybyfru"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  }
}

```

This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|FRUID|[FRUId.1.0.0](#schemafruid.1.0.0)|false|none|Uniquely identifies a piece of hardware by a serial-number like identifier that is globally unique within the hardware inventory,|
|Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|none|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|FRUSubtype|string|false|none|TBD.|
|HWInventoryByFRUType|string|true|none|This is used as a discriminator to determine the additional HMS-type specific subtype that is returned.|

#### Enumerated Values

|Property|Value|
|---|---|
|HWInventoryByFRUType|HWInvByFRUCabinet|
|HWInventoryByFRUType|HWInvByFRUChassis|
|HWInventoryByFRUType|HWInvByFRUComputeModule|
|HWInventoryByFRUType|HWInvByFRURouterModule|
|HWInventoryByFRUType|HWInvByFRUNodeEnclosure|
|HWInventoryByFRUType|HWInvByFRUHSNBoard|
|HWInventoryByFRUType|HWInvByFRUMgmtSwitch|
|HWInventoryByFRUType|HWInvByFRUMgmtHLSwitch|
|HWInventoryByFRUType|HWInvByFRUCDUMgmtSwitch|
|HWInventoryByFRUType|HWInvByFRUNode|
|HWInventoryByFRUType|HWInvByFRUProcessor|
|HWInventoryByFRUType|HWInvByFRUNodeAccel|
|HWInventoryByFRUType|HWInvByFRUNodeAccelRiser|
|HWInventoryByFRUType|HWInvByFRUDrive|
|HWInventoryByFRUType|HWInvByFRUMemory|
|HWInventoryByFRUType|HWInvByFRUPDU|
|HWInventoryByFRUType|HWInvByFRUOutlet|
|HWInventoryByFRUType|HWInvByFRUCMMRectifier|
|HWInventoryByFRUType|HWInvByFRUNodeEnclosurePowerSupply|
|HWInventoryByFRUType|HWInvByFRUNodeBMC|
|HWInventoryByFRUType|HWInvByFRURouterBMC|
|HWInventoryByFRUType|HWIncByFRUHSNNIC|

<h2 id="tocS_HWInvByFRUCabinet">HWInvByFRUCabinet</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrucabinet"></a>
<a id="schema_HWInvByFRUCabinet"></a>
<a id="tocShwinvbyfrucabinet"></a>
<a id="tocshwinvbyfrucabinet"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "CabinetFRUInfo": {
    "AssetTag": "string",
    "ChassisType": "Rack",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType Cabinet. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUCabinet'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» CabinetFRUInfo|[HWInventory.1.0.0_RedfishChassisFRUInfo](#schemahwinventory.1.0.0_redfishchassisfruinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRUChassis">HWInvByFRUChassis</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfruchassis"></a>
<a id="schema_HWInvByFRUChassis"></a>
<a id="tocShwinvbyfruchassis"></a>
<a id="tocshwinvbyfruchassis"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "ChassisFRUInfo": {
    "AssetTag": "string",
    "ChassisType": "Rack",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType Chassis. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUChassis'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» ChassisFRUInfo|[HWInventory.1.0.0_RedfishChassisFRUInfo](#schemahwinventory.1.0.0_redfishchassisfruinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRUComputeModule">HWInvByFRUComputeModule</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrucomputemodule"></a>
<a id="schema_HWInvByFRUComputeModule"></a>
<a id="tocShwinvbyfrucomputemodule"></a>
<a id="tocshwinvbyfrucomputemodule"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "ComputeModuleFRUInfo": {
    "AssetTag": "string",
    "ChassisType": "Rack",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType ComputeModule. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUComputeModule'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» ComputeModuleFRUInfo|[HWInventory.1.0.0_RedfishChassisFRUInfo](#schemahwinventory.1.0.0_redfishchassisfruinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRURouterModule">HWInvByFRURouterModule</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfruroutermodule"></a>
<a id="schema_HWInvByFRURouterModule"></a>
<a id="tocShwinvbyfruroutermodule"></a>
<a id="tocshwinvbyfruroutermodule"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "RouterModuleFRUInfo": {
    "AssetTag": "string",
    "ChassisType": "Rack",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType RouterModule. This is a Mountain switch module. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRURouterModule'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» RouterModuleFRUInfo|[HWInventory.1.0.0_RedfishChassisFRUInfo](#schemahwinventory.1.0.0_redfishchassisfruinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRUNodeEnclosure">HWInvByFRUNodeEnclosure</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrunodeenclosure"></a>
<a id="schema_HWInvByFRUNodeEnclosure"></a>
<a id="tocShwinvbyfrunodeenclosure"></a>
<a id="tocshwinvbyfrunodeenclosure"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "NodeEnclosureFRUInfo": {
    "AssetTag": "string",
    "ChassisType": "Rack",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType NodeEnclosure. It represents a Mountain node card or River rack enclosure.  It is NOT the BMC, which is separate and corresponds to a Redfish Manager. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUNodeEnclosure'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeEnclosureFRUInfo|[HWInventory.1.0.0_RedfishChassisFRUInfo](#schemahwinventory.1.0.0_redfishchassisfruinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRUHSNBoard">HWInvByFRUHSNBoard</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfruhsnboard"></a>
<a id="schema_HWInvByFRUHSNBoard"></a>
<a id="tocShwinvbyfruhsnboard"></a>
<a id="tocshwinvbyfruhsnboard"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "HSNBoardFRUInfo": {
    "AssetTag": "string",
    "ChassisType": "Rack",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType HSNBoard. It represents a Mountain switch card or River TOR enclosure.  It is NOT the BMC, which is separate and corresponds to a Redfish Manager. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUHSNBoard'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» HSNBoardFRUInfo|[HWInventory.1.0.0_RedfishChassisFRUInfo](#schemahwinventory.1.0.0_redfishchassisfruinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRUMgmtSwitch">HWInvByFRUMgmtSwitch</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrumgmtswitch"></a>
<a id="schema_HWInvByFRUMgmtSwitch"></a>
<a id="tocShwinvbyfrumgmtswitch"></a>
<a id="tocshwinvbyfrumgmtswitch"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "MgmtSwitchFRUInfo": {
    "AssetTag": "string",
    "ChassisType": "Rack",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType MgmtSwitch. It represents a management switch.  It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUMgmtSwitch'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» MgmtSwitchFRUInfo|[HWInventory.1.0.0_RedfishChassisFRUInfo](#schemahwinventory.1.0.0_redfishchassisfruinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRUMgmtHLSwitch">HWInvByFRUMgmtHLSwitch</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrumgmthlswitch"></a>
<a id="schema_HWInvByFRUMgmtHLSwitch"></a>
<a id="tocShwinvbyfrumgmthlswitch"></a>
<a id="tocshwinvbyfrumgmthlswitch"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "MgmtHLSwitchFRUInfo": {
    "AssetTag": "string",
    "ChassisType": "Rack",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType MgmtHLSwitch. It represents a high level management switch.  It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUMgmtHLSwitch'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» MgmtHLSwitchFRUInfo|[HWInventory.1.0.0_RedfishChassisFRUInfo](#schemahwinventory.1.0.0_redfishchassisfruinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRUCDUMgmtSwitch">HWInvByFRUCDUMgmtSwitch</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrucdumgmtswitch"></a>
<a id="schema_HWInvByFRUCDUMgmtSwitch"></a>
<a id="tocShwinvbyfrucdumgmtswitch"></a>
<a id="tocshwinvbyfrucdumgmtswitch"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "CDUMgmtSwitchFRUInfo": {
    "AssetTag": "string",
    "ChassisType": "Rack",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType CDUMgmtSwitch. It represents a CDU management switch.  It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUCDUMgmtSwitch'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» CDUMgmtSwitchFRUInfo|[HWInventory.1.0.0_RedfishChassisFRUInfo](#schemahwinventory.1.0.0_redfishchassisfruinfo)|false|none|These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRUNode">HWInvByFRUNode</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrunode"></a>
<a id="schema_HWInvByFRUNode"></a>
<a id="tocShwinvbyfrunode"></a>
<a id="tocshwinvbyfrunode"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "string",
    "BiosVersion": "string",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string",
    "SystemType": "Physical",
    "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType Node. It represents a service, compute, or system node. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUNode'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeFRUInfo|[HWInventory.1.0.0_RedfishSystemFRUInfo](#schemahwinventory.1.0.0_redfishsystemfruinfo)|false|none|These are pass-through properties of the Redfish ComputerSystem object that are also used in HMS inventory data.  These are properties of a specific hardware instance that remain the same if the component is relocated within the system.<br>Note that Redfish ComputerSystem objects are an abstract type that represents a system, but not necessarily a specific piece of hardware. Chassis objects represent things like the physical enclosure.  The system links to chassis and also to subcomponents that have their own object types like Processors, Memory, and Storage.<br>That said, they are a close fit to how we represent nodes in HMS and so it makes sense to pass through their properties since that is how we will discover this information anyways.|

<h2 id="tocS_HWInvByFRUProcessor">HWInvByFRUProcessor</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfruprocessor"></a>
<a id="schema_HWInvByFRUProcessor"></a>
<a id="tocShwinvbyfruprocessor"></a>
<a id="tocshwinvbyfruprocessor"></a>

```json
{
  "FRUID": "HOW-TO-ID-CPUS-FROM-REDFISH-IF-AT-ALL",
  "Type": "Processor",
  "Subtype": "SKL24",
  "HWInventoryByFRUType": "HWInvByFRUProcessor",
  "ProcessorFRUInfo": {
    "InstructionSet": "x86-64",
    "Manufacturer": "Intel",
    "MaxSpeedMHz": 2600,
    "Model": "Intel(R) Xeon(R) CPU E5-2623 v4 @ 2.60GHz",
    "ProcessorArchitecture": "x86",
    "ProcessorId": {
      "EffectiveFamily": 6,
      "EffectiveModel": 79,
      "IdentificationRegisters": 263921,
      "MicrocodeInfo": 184549399,
      "Step": 1,
      "VendorID": "GenuineIntel"
    },
    "ProcessorType": "CPU",
    "TotalCores": 24,
    "TotalThreads": 48
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType Processor. It represents a primary CPU type (e.g. non-accelerator). It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUProcessor'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» ProcessorFRUInfo|[HWInventory.1.0.0_RedfishProcessorFRUInfo](#schemahwinventory.1.0.0_redfishprocessorfruinfo)|false|none|These are pass-through properties of the Redfish Processor object type that are also used in HMS inventory data. These are properties of a specific processor instance that remain the same if it is relocated within the system.|

<h2 id="tocS_HWInvByFRUNodeAccel">HWInvByFRUNodeAccel</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrunodeaccel"></a>
<a id="schema_HWInvByFRUNodeAccel"></a>
<a id="tocShwinvbyfrunodeaccel"></a>
<a id="tocshwinvbyfrunodeaccel"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "NodeAccelFRUInfo": {
    "InstructionSet": "x86",
    "Manufacturer": "string",
    "MaxSpeedMHz": 0,
    "Model": "string",
    "ProcessorArchitecture": "x86",
    "ProcessorId": {
      "EffectiveFamily": "string",
      "EffectiveModel": "string",
      "IdentificationRegisters": "string",
      "MicrocodeInfo": "string",
      "Step": "string",
      "VendorId": "string"
    },
    "ProcessorType": "CPU",
    "TotalCores": 0,
    "TotalThreads": 0
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType NodeAccel. It represents a GPU type (e.g. accelerator). It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUNodeAccel'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeAccelFRUInfo|[HWInventory.1.0.0_RedfishProcessorFRUInfo](#schemahwinventory.1.0.0_redfishprocessorfruinfo)|false|none|These are pass-through properties of the Redfish Processor object type that are also used in HMS inventory data. These are properties of a specific processor instance that remain the same if it is relocated within the system.|

<h2 id="tocS_HWInvByFRUDrive">HWInvByFRUDrive</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrudrive"></a>
<a id="schema_HWInvByFRUDrive"></a>
<a id="tocShwinvbyfrudrive"></a>
<a id="tocshwinvbyfrudrive"></a>

```json
{
  "HWInventoryByFRUType": "HWInvByFRUDrive",
  "DriveFRUInfo": {
    "SerialNumber": "S45PNA0M540940",
    "Model": "SAMSUNG MZ7LH480HAHQ-00005",
    "CapacityBytes": 503424483328,
    "FailurePredicted": false
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType Drive. It represents a disk drive type. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUDrive'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» DriveFRUInfo|[HWInventory.1.0.0_RedfishDriveFRUInfo](#schemahwinventory.1.0.0_redfishdrivefruinfo)|false|none|These are pass-through properties of the Redfish Drive object type that are also used in HMS inventory data. These are properties of a specific drive instance that remain the same if it is relocated within the system.|

<h2 id="tocS_HWInvByFRUMemory">HWInvByFRUMemory</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrumemory"></a>
<a id="schema_HWInvByFRUMemory"></a>
<a id="tocShwinvbyfrumemory"></a>
<a id="tocshwinvbyfrumemory"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "MemoryFRUInfo": {
    "BaseModuleType": "RDIMM",
    "BusWidthBits": 0,
    "CapacityMiB": 0,
    "DataWidthBits": 0,
    "ErrorCorrection": "NoECC",
    "Manufacturer": "string",
    "MemoryType": "DRAM",
    "MemoryDeviceType": "DDR",
    "OperatingSpeedMhz": 0,
    "PartNumber": "string",
    "RankCount": 0,
    "SerialNumber": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType Memory. It represents a DIMM or other memory module type. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByLocMemory'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» MemoryFRUInfo|[HWInventory.1.0.0_RedfishMemoryFRUInfo](#schemahwinventory.1.0.0_redfishmemoryfruinfo)|false|none|These are pass-through properties of the Redfish Memory object type that are also used in HMS inventory data.  These are properties of a specific memory module that remain the same if it the module is relocated within the system.|

<h2 id="tocS_HWInvByFRUPDU">HWInvByFRUPDU</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrupdu"></a>
<a id="schema_HWInvByFRUPDU"></a>
<a id="tocShwinvbyfrupdu"></a>
<a id="tocshwinvbyfrupdu"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "PDUFRUInfo": {
    "AssetTag": "string",
    "DateOfManufacture": "string",
    "EquipmentType": "RackPDU",
    "FirmwareVersion": "string",
    "HardwareRevision": "string",
    "Model": "string",
    "Manufacturer": "string",
    "PartNumber": "string",
    "SerialNumber": "string",
    "SKU": "string",
    "CircuitSummary": {
      "MonitoredOutlets": 0,
      "TotalPhases": 0,
      "ControlledOutlets": 0,
      "TotalOutlets": 0,
      "MonitoredBranches": 0,
      "MonitoredPhases": 0,
      "TotalBranches": 0
    }
  }
}

```

This is a subtype of HWInventoryByFRU for PDU HMSTypes, e.g. CabinetPDU. It represents a Redfish PowerDistribution master or slave PDU. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUPDU'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» PDUFRUInfo|[HWInventory.1.0.0_RedfishPDUFRUInfo](#schemahwinventory.1.0.0_redfishpdufruinfo)|false|none|These are pass-through properties of the Redfish PowerDistribution type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRUOutlet">HWInvByFRUOutlet</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfruoutlet"></a>
<a id="schema_HWInvByFRUOutlet"></a>
<a id="tocShwinvbyfruoutlet"></a>
<a id="tocshwinvbyfruoutlet"></a>

```json
{
  "ID": "x0m0p0v1",
  "Type": "CabinetPDUPowerConnector",
  "Ordinal": 0,
  "Status": "Populated",
  "HWInventoryByLocationType": "HWInvByLocOutlet",
  "OutletLocationInfo": {
    "Id": "A1",
    "Name": "Outlet A1, Branch Circuit A",
    "Description": "Outlet description",
    "PopulatedFRU": {
      "FRUID": "CabinetPDUPowerConnector.0.CabinetPDU.29347ZT536",
      "Type": "CabinetPDUPowerConnector",
      "HWInventoryByFRUType": "HWInvByFRUOutlet",
      "OutletFRUInfo": {
        "PowerEnabled": true,
        "NominalVoltage": "AC120V",
        "RatedCurrentAmps": 20,
        "VoltageType": "AC",
        "OutletType": "NEMA_5_20R",
        "PhaseWiringType": "OnePhase3Wire"
      }
    }
  }
}

```

This is a subtype of HWInventoryByFRU for Outlet HMSTypes, e.g. CabinetPDUPowerConnector.  It represents an outlet of a PDU. It is selected via the "discriminator:" HWInventoryByFRUType of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUOutlet'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» OutletFRUInfoFRUInfo|[HWInventory.1.0.0_RedfishOutletFRUInfo](#schemahwinventory.1.0.0_redfishoutletfruinfo)|false|none|These are pass-through properties of the Redfish Outlet type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.  Child of a PDU.|

<h2 id="tocS_HWInvByFRUCMMRectifier">HWInvByFRUCMMRectifier</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrucmmrectifier"></a>
<a id="schema_HWInvByFRUCMMRectifier"></a>
<a id="tocShwinvbyfrucmmrectifier"></a>
<a id="tocshwinvbyfrucmmrectifier"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "PowerSupplyFRUInfo": {
    "Manufacturer": "string",
    "SerialNumber": "string",
    "Model": "string",
    "PartNumber": "string",
    "PowerCapacityWatts": 0,
    "PowerInputWatts": 0,
    "PowerOutputWatts": 0,
    "PowerSupplyType": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType CMMRectifier. It represents a power supply type. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUCMMRectifier'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» PowerSupplyFRUInfo|[HWInventory.1.0.0_RedfishCMMRectifierFRUInfo](#schemahwinventory.1.0.0_redfishcmmrectifierfruinfo)|false|none|These are pass-through properties of the Redfish PowerSupply type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.  Child of a Chassis.|

<h2 id="tocS_HWInvByFRUNodeAccelRiser">HWInvByFRUNodeAccelRiser</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrunodeaccelriser"></a>
<a id="schema_HWInvByFRUNodeAccelRiser"></a>
<a id="tocShwinvbyfrunodeaccelriser"></a>
<a id="tocshwinvbyfrunodeaccelriser"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "NodeAccelRiserFRUInfo": {
    "Producer": "string",
    "SerialNumber": "string",
    "Model": "string",
    "PartNumber": "string",
    "ProductionDate": "string",
    "Version": "string",
    "EngineeringChangeLevel": "string",
    "PhysicalContext": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType NodeAccelRiser. It represents a GPUSubsystem baseboard type. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUNodeAccelRiser'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeAccelRiserFRUInfo|[HWInventory.1.0.0_RedfishNodeAccelRiserFRUInfo](#schemahwinventory.1.0.0_redfishnodeaccelriserfruinfo)|false|none|These are the properties of the NodeAccelRiser type that are passed-through to the HMS inventory data when the underlying Redfish object  type is an Assembly with a PhysicalContext of GPUSubsystem.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.  Child of a Chassis.|

<h2 id="tocS_HWInvByFRUNodeEnclosurePowerSupply">HWInvByFRUNodeEnclosurePowerSupply</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrunodeenclosurepowersupply"></a>
<a id="schema_HWInvByFRUNodeEnclosurePowerSupply"></a>
<a id="tocShwinvbyfrunodeenclosurepowersupply"></a>
<a id="tocshwinvbyfrunodeenclosurepowersupply"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "NodeEnclosurePowerSupplyFRUInfo": {
    "Manufacturer": "string",
    "SerialNumber": "string",
    "Model": "string",
    "PartNumber": "string",
    "PowerCapacityWatts": 0,
    "PowerInputWatts": 0,
    "PowerOutputWatts": 0,
    "PowerSupplyType": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType NodeEnclosurePowerSupply. It represents a power supply type. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUNodeEnclosurePowerSupply'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeEnclosurePowerSupplyFRUInfo|[HWInventory.1.0.0_RedfishNodeEnclosurePowerSupplyFRUInfo](#schemahwinventory.1.0.0_redfishnodeenclosurepowersupplyfruinfo)|false|none|These are pass-through properties of the Redfish PowerSupply type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.  Child of a Chassis.|

<h2 id="tocS_HWInvByFRUNodeBMC">HWInvByFRUNodeBMC</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrunodebmc"></a>
<a id="schema_HWInvByFRUNodeBMC"></a>
<a id="tocShwinvbyfrunodebmc"></a>
<a id="tocshwinvbyfrunodebmc"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "NodeBMCFRUInfo": {
    "ManagerType": "string",
    "Manufacturer": "string",
    "SerialNumber": "string",
    "Model": "string",
    "PartNumber": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType NodeBMC. It represents a Node BMC type. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUNodeBMC'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» NodeBMCFRUInfo|[HWInventory.1.0.0_RedfishManagerFRUInfo](#schemahwinventory.1.0.0_redfishmanagerfruinfo)|false|none|These are pass-through properties of the Redfish Manager type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRURouterBMC">HWInvByFRURouterBMC</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfrurouterbmc"></a>
<a id="schema_HWInvByFRURouterBMC"></a>
<a id="tocShwinvbyfrurouterbmc"></a>
<a id="tocshwinvbyfrurouterbmc"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "RouterBMCFRUInfo": {
    "ManagerType": "string",
    "Manufacturer": "string",
    "SerialNumber": "string",
    "Model": "string",
    "PartNumber": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType RouterBMC. It represents a Router BMC type. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRURouterBMC'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» RouterBMCFRUInfo|[HWInventory.1.0.0_RedfishManagerFRUInfo](#schemahwinventory.1.0.0_redfishmanagerfruinfo)|false|none|These are pass-through properties of the Redfish Manager type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInvByFRUHSNNIC">HWInvByFRUHSNNIC</h2>
<!-- backwards compatibility -->
<a id="schemahwinvbyfruhsnnic"></a>
<a id="schema_HWInvByFRUHSNNIC"></a>
<a id="tocShwinvbyfruhsnnic"></a>
<a id="tocshwinvbyfruhsnnic"></a>

```json
{
  "FRUID": "Dell-99999-1234-1234-2345",
  "Type": "Node",
  "Subtype": "River",
  "HWInventoryByFRUType": "HWInvByFRUNode",
  "NodeFRUInfo": {
    "AssetTag": "AdminAssignedAssetTag",
    "BiosVersion": "v1.0.2.9999",
    "Model": "OKS0P2354",
    "Manufacturer": "Dell",
    "PartNumber": "y99999",
    "SerialNumber": "1234-1234-2345",
    "SKU": "as213234",
    "SystemType": "Physical",
    "UUID": "26276e2a-29dd-43eb-8ca6-8186bbc3d971"
  },
  "HSNNICFRUInfo": {
    "Manufacturer": "string",
    "Model": "string",
    "PartNumber": "string",
    "SKU": "string",
    "SerialNumber": "string"
  }
}

```

This is a subtype of HWInventoryByFRU for HMSType NodeHsnNic. It represents a node HSN NIC type. It is selected via the 'discriminator: HWInventoryByFRUType' of HWInventoryByFRU when HWInventoryByFRUType is 'HWInvByFRUHSNNIC'.

### Properties

allOf - discriminator: HWInventory.1.0.0_HWInventoryByFRU.HWInventoryByFRUType

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[HWInventory.1.0.0_HWInventoryByFRU](#schemahwinventory.1.0.0_hwinventorybyfru)|false|none|This represents a physical piece of hardware with properties specific to a unique component in the system.  It is the counterpart to HWInventoryByLocation (which contains ONLY information specific to a particular location in the system that may or may not be populated), in that it contains only info about the component that is durably consistent wherever the component is installed in the system (if it is still installed at all).|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» HSNNICFRUInfo|[HWInventory.1.0.0_HSNNICFRUInfo](#schemahwinventory.1.0.0_hsnnicfruinfo)|false|none|These are pass-through properties of the Node HSN NIC type that are also used in HMS inventory data when this is the underlying network object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.|

<h2 id="tocS_HWInventory.1.0.0_RedfishChassisFRUInfo">HWInventory.1.0.0_RedfishChassisFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishchassisfruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishChassisFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishchassisfruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishchassisfruinfo"></a>

```json
{
  "AssetTag": "string",
  "ChassisType": "Rack",
  "Model": "string",
  "Manufacturer": "string",
  "PartNumber": "string",
  "SerialNumber": "string",
  "SKU": "string"
}

```

These are pass-through properties of the Redfish Chassis object type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|AssetTag|string|false|read-only|The administratively-assigned asset tag for this chassis.|
|ChassisType|string|false|read-only|This property indicates the type of physical form factor of this resource (from Redfish - not all of these will likely appear in practice.  In any case, the HMS type and subtype will identify the hardware type, this is for informational purposes only).|
|Model|string|false|read-only|Manufacturer-provided model number for part.|
|Manufacturer|string|false|read-only|Intended to provide the manufacturer of the part.|
|PartNumber|string|false|read-only|Manufacturer-provided part number for this component.|
|SerialNumber|string|false|read-only|Manufacturer-provided serial number for this component.|
|SKU|string|false|read-only|Manufacturer-provided SKU for this component.|

#### Enumerated Values

|Property|Value|
|---|---|
|ChassisType|Rack|
|ChassisType|Blade|
|ChassisType|Enclosure|
|ChassisType|StandAlone|
|ChassisType|RackMount|
|ChassisType|Card|
|ChassisType|Cartridge|
|ChassisType|Row|
|ChassisType|Pod|
|ChassisType|Expansion|
|ChassisType|Sidecar|
|ChassisType|Zone|
|ChassisType|Sled|
|ChassisType|Shelf|
|ChassisType|Drawer|
|ChassisType|Module|
|ChassisType|Component|
|ChassisType|Other|

<h2 id="tocS_HWInventory.1.0.0_RedfishSystemFRUInfo">HWInventory.1.0.0_RedfishSystemFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishsystemfruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishSystemFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishsystemfruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishsystemfruinfo"></a>

```json
{
  "AssetTag": "string",
  "BiosVersion": "string",
  "Model": "string",
  "Manufacturer": "string",
  "PartNumber": "string",
  "SerialNumber": "string",
  "SKU": "string",
  "SystemType": "Physical",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b"
}

```

These are pass-through properties of the Redfish ComputerSystem object that are also used in HMS inventory data.  These are properties of a specific hardware instance that remain the same if the component is relocated within the system.
Note that Redfish ComputerSystem objects are an abstract type that represents a system, but not necessarily a specific piece of hardware. Chassis objects represent things like the physical enclosure.  The system links to chassis and also to subcomponents that have their own object types like Processors, Memory, and Storage.
That said, they are a close fit to how we represent nodes in HMS and so it makes sense to pass through their properties since that is how we will discover this information anyways.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|AssetTag|string|false|read-only|The administratively-assigned asset tag for this chassis.|
|BiosVersion|string|false|read-only|The version of the system BIOS or primary system firmware.|
|Model|string|false|read-only|Manufacturer-provided model number for part.|
|Manufacturer|string|false|read-only|Intended to provide the manufacturer of the part.|
|PartNumber|string|false|read-only|Manufacturer-provided part number for this component.|
|SerialNumber|string|false|read-only|Manufacturer-provided serial number for this component.|
|SKU|string|false|none|Manufacturer-provided SKU for this component.|
|SystemType|string|false|read-only|Type of system.  Probably always physical for now.|
|UUID|[UUID.1.0.0](#schemauuid.1.0.0)|false|none|This is a universally unique identifier i.e. UUID in the canonical format provided by Redfish to identify endpoints and services. If this is the UUID of a RedfishEndpoint, it should be the UUID broadcast by SSDP, if applicable.|

#### Enumerated Values

|Property|Value|
|---|---|
|SystemType|Physical|
|SystemType|Virtual|
|SystemType|OS|
|SystemType|PhysicallyPartitioned|
|SystemType|VirtuallyPartitioned|

<h2 id="tocS_HWInventory.1.0.0_RedfishProcessorFRUInfo">HWInventory.1.0.0_RedfishProcessorFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishprocessorfruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishProcessorFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishprocessorfruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishprocessorfruinfo"></a>

```json
{
  "InstructionSet": "x86",
  "Manufacturer": "string",
  "MaxSpeedMHz": 0,
  "Model": "string",
  "ProcessorArchitecture": "x86",
  "ProcessorId": {
    "EffectiveFamily": "string",
    "EffectiveModel": "string",
    "IdentificationRegisters": "string",
    "MicrocodeInfo": "string",
    "Step": "string",
    "VendorId": "string"
  },
  "ProcessorType": "CPU",
  "TotalCores": 0,
  "TotalThreads": 0
}

```

These are pass-through properties of the Redfish Processor object type that are also used in HMS inventory data. These are properties of a specific processor instance that remain the same if it is relocated within the system.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|InstructionSet|string|false|read-only|The instruction set of the processor (Redfish pass-through)|
|Manufacturer|string|false|read-only|The processor manufacturer|
|MaxSpeedMHz|number|false|read-only|The maximum clock speed of the processor|
|Model|string|false|read-only|The product model number of this device|
|ProcessorArchitecture|string|false|read-only|The architecture of the processor|
|ProcessorId|object|false|none|Identification information for this processor. Pass-through from Redfish.|
|» EffectiveFamily|string|false|read-only|The effective Family for this processor|
|» EffectiveModel|string|false|read-only|The effective Model for this processor|
|» IdentificationRegisters|string|false|read-only|The contents of the Identification Registers (CPUID) for this processor|
|» MicrocodeInfo|string|false|read-only|The Microcode Information for this processor|
|» Step|string|false|read-only|The Step value for this processor|
|» VendorId|string|false|read-only|The Vendor Identification for this processor|
|ProcessorType|string|false|read-only|The type of processor|
|TotalCores|number|false|read-only|The total number of cores contained in this processor|
|TotalThreads|number|false|read-only|The total number of execution threads supported by this processor|

#### Enumerated Values

|Property|Value|
|---|---|
|InstructionSet|x86|
|InstructionSet|x86-64|
|InstructionSet|IA-64|
|InstructionSet|ARM-A32|
|InstructionSet|ARM-A64|
|InstructionSet|MIPS32|
|InstructionSet|MIPS64|
|InstructionSet|OEM|
|ProcessorArchitecture|x86|
|ProcessorArchitecture|IA-64|
|ProcessorArchitecture|ARM|
|ProcessorArchitecture|MIPS|
|ProcessorArchitecture|OEM|
|ProcessorType|CPU|
|ProcessorType|GPU|
|ProcessorType|FPGA|
|ProcessorType|DSP|
|ProcessorType|Accelerator|
|ProcessorType|OEM|

<h2 id="tocS_HWInventory.1.0.0_RedfishDriveFRUInfo">HWInventory.1.0.0_RedfishDriveFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishdrivefruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishDriveFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishdrivefruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishdrivefruinfo"></a>

```json
{
  "Manufacturer": "string",
  "SerialNumber": "string",
  "PartNumber": "string",
  "Model": "string",
  "SKU": "string",
  "CapacityBytes": 0,
  "Protocol": "AHCI",
  "MediaType": "HDD",
  "RotationSpeedRPM": 0,
  "BlockSizeBytes": 0,
  "CapableSpeedGbs": 0,
  "FailurePredicted": true,
  "EncryptionAbility": "None",
  "EncryptionStatus": "Foreign",
  "NegotiatedSpeedGbs": 0,
  "PredictedMediaLifeLeftPercent": 0
}

```

These are pass-through properties of the Redfish Drive object type that are also used in HMS inventory data. These are properties of a specific drive instance that remain the same if it is relocated within the system.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Manufacturer|string|false|read-only|The drive manufacturer|
|SerialNumber|string|false|read-only|Unique identifier|
|PartNumber|string|false|read-only|Manufacturer part number|
|Model|string|false|read-only|Manufacturer model name|
|SKU|string|false|read-only|Manufacturer Stock Keeping Unit|
|CapacityBytes|number|false|read-only|Manufacturer Stock Keeping Unit|
|Protocol|string|false|read-only|The protocol that this drive currently uses to communicate to the storage controller.|
|MediaType|string|false|read-only|The type of media contained in this drive|
|RotationSpeedRPM|number|false|read-only|The rotation speed of this drive, in revolutions per minute (RPM)|
|BlockSizeBytes|integer|false|read-only|The size, in bytes, of the smallest addressable unit, or block|
|CapableSpeedGbs|number|false|read-only|The speed, in gigabit per second (Gbit/s), at which this drive can communicate to a storage controller in ideal conditions.|
|FailurePredicted|boolean|false|read-only|An indication of whether this drive currently predicts a failure in the near future.|
|EncryptionAbility|string|false|read-only|The encryption ability of this drive.|
|EncryptionStatus|string|false|read-only|The status of the encryption of this drive.|
|NegotiatedSpeedGbs|number|false|read-only|The speed, in gigabit per second (Gbit/s), at which this drive currently communicates to the storage controller.|
|PredictedMediaLifeLeftPercent|number|false|read-only|The percentage of reads and writes that are predicted to still be available for the media.|

#### Enumerated Values

|Property|Value|
|---|---|
|Protocol|AHCI|
|Protocol|FC|
|Protocol|FCP|
|Protocol|FCoE|
|Protocol|FICON|
|Protocol|FTP|
|Protocol|GenZ|
|Protocol|HTTP|
|Protocol|HTTPS|
|Protocol|I2C|
|Protocol|MultiProtocol|
|Protocol|NFSv3|
|Protocol|NFSv4|
|Protocol|NVMe|
|Protocol|NVMeOverFabrics|
|Protocol|OEM|
|Protocol|PCIe|
|Protocol|RoCE|
|Protocol|RoCEv2|
|Protocol|SAS|
|Protocol|SATA|
|Protocol|SFTP|
|Protocol|SMB|
|Protocol|TCP|
|Protocol|TFTP|
|Protocol|UDP|
|Protocol|UHCI|
|Protocol|USB|
|Protocol|iSCSI|
|Protocol|iWARP|
|MediaType|HDD|
|MediaType|SMR|
|MediaType|SSD|
|EncryptionAbility|None|
|EncryptionAbility|Other|
|EncryptionAbility|SelfEncryptingDrive|
|EncryptionStatus|Foreign|
|EncryptionStatus|Locked|
|EncryptionStatus|Encrypted|
|EncryptionStatus|Unencrypted|
|EncryptionStatus|Unlocked|

<h2 id="tocS_HWInventory.1.0.0_RedfishMemoryFRUInfo">HWInventory.1.0.0_RedfishMemoryFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishmemoryfruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishMemoryFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishmemoryfruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishmemoryfruinfo"></a>

```json
{
  "BaseModuleType": "RDIMM",
  "BusWidthBits": 0,
  "CapacityMiB": 0,
  "DataWidthBits": 0,
  "ErrorCorrection": "NoECC",
  "Manufacturer": "string",
  "MemoryType": "DRAM",
  "MemoryDeviceType": "DDR",
  "OperatingSpeedMhz": 0,
  "PartNumber": "string",
  "RankCount": 0,
  "SerialNumber": "string"
}

```

These are pass-through properties of the Redfish Memory object type that are also used in HMS inventory data.  These are properties of a specific memory module that remain the same if it the module is relocated within the system.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|BaseModuleType|string|false|read-only|The base module type of Memory.|
|BusWidthBits|number|false|read-only|Bus width in bits.|
|CapacityMiB|number|false|read-only|Memory Capacity in MiB.|
|DataWidthBits|number|false|read-only|Data width in bits.|
|ErrorCorrection|string|false|read-only|Whether single or multiple errors, or address parity errors can be corrected.|
|Manufacturer|string|false|read-only|The manufacturer of the memory module|
|MemoryType|string|false|read-only|Type of memory module.|
|MemoryDeviceType|string|false|read-only|Type details of the memory.|
|OperatingSpeedMhz|number|false|read-only|Operating speed of Memory in MHz.|
|PartNumber|string|false|read-only|Manufacturer-provided part number for this component.|
|RankCount|number|false|read-only|Number of ranks available in the memory.|
|SerialNumber|string|false|read-only|Manufacturer-provided serial number for this component.|

#### Enumerated Values

|Property|Value|
|---|---|
|BaseModuleType|RDIMM|
|BaseModuleType|UDIMM|
|BaseModuleType|SO_DIMM|
|BaseModuleType|LRDIMM|
|BaseModuleType|Mini_RDIMM|
|BaseModuleType|Mini_UDIMM|
|BaseModuleType|SO_RDIMM_72b|
|BaseModuleType|SO_UDIMM_72b|
|BaseModuleType|SO_DIMM_16b|
|BaseModuleType|SO_DIMM_32b|
|ErrorCorrection|NoECC|
|ErrorCorrection|SingleBitECC|
|ErrorCorrection|MultiBitECC|
|ErrorCorrection|AddressParity|
|MemoryType|DRAM|
|MemoryType|NVDIMM_N|
|MemoryType|NVDIMM_F|
|MemoryType|NVDIMM_P|
|MemoryDeviceType|DDR|
|MemoryDeviceType|DDR2|
|MemoryDeviceType|DDR3|
|MemoryDeviceType|DDR4|
|MemoryDeviceType|DDR4_SDRAM|
|MemoryDeviceType|DDR4E_SDRAM|
|MemoryDeviceType|LPDDR4_SDRAM|
|MemoryDeviceType|DDR3_SDRAM|
|MemoryDeviceType|LPDDR3_SDRAM|
|MemoryDeviceType|DDR2_SDRAM|
|MemoryDeviceType|DDR2_SDRAM_FB_DIMM|
|MemoryDeviceType|DDR2_SDRAM_FB_DIMM_PROBE|
|MemoryDeviceType|DDR_SGRAM|
|MemoryDeviceType|DDR_SDRAM|
|MemoryDeviceType|ROM|
|MemoryDeviceType|SDRAM|
|MemoryDeviceType|EDO|
|MemoryDeviceType|FastPageMode|
|MemoryDeviceType|PipelinedNibble|

<h2 id="tocS_HWInventory.1.0.0_RedfishPDUFRUInfo">HWInventory.1.0.0_RedfishPDUFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishpdufruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishPDUFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishpdufruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishpdufruinfo"></a>

```json
{
  "AssetTag": "string",
  "DateOfManufacture": "string",
  "EquipmentType": "RackPDU",
  "FirmwareVersion": "string",
  "HardwareRevision": "string",
  "Model": "string",
  "Manufacturer": "string",
  "PartNumber": "string",
  "SerialNumber": "string",
  "SKU": "string",
  "CircuitSummary": {
    "MonitoredOutlets": 0,
    "TotalPhases": 0,
    "ControlledOutlets": 0,
    "TotalOutlets": 0,
    "MonitoredBranches": 0,
    "MonitoredPhases": 0,
    "TotalBranches": 0
  }
}

```

These are pass-through properties of the Redfish PowerDistribution type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|AssetTag|string|false|read-only|The administratively-assigned asset tag for this chassis.|
|DateOfManufacture|string|false|read-only|Manufacturer-provided date-of-manufacture for part.|
|EquipmentType|string|false|read-only|This property indicates the type of PowerDistribution in practice.  In any case, the HMS type and subtype will identify the hardware type, this is for informational purposes only).|
|FirmwareVersion|string|false|read-only|Firmware version at time of discovery.|
|HardwareRevision|string|false|read-only|Manufacturer-provided HardwareRevision for part.|
|Model|string|false|read-only|Manufacturer-provided model number for part.|
|Manufacturer|string|false|read-only|Intended to provide the manufacturer of the part.|
|PartNumber|string|false|read-only|Manufacturer-provided part number for this component.|
|SerialNumber|string|false|read-only|Manufacturer-provided serial number for this component.|
|SKU|string|false|read-only|Manufacturer-provided SKU for this component.|
|CircuitSummary|object|false|read-only|Summary of circuits for PDU.|
|» MonitoredOutlets|number|false|read-only|Number of monitored outlets|
|» TotalPhases|number|false|read-only|Number of phases in total|
|» ControlledOutlets|number|false|read-only|Total number of controller outlets|
|» TotalOutlets|number|false|read-only|Total number of outlets|
|» MonitoredBranches|number|false|read-only|Number of monitored branches|
|» MonitoredPhases|number|false|read-only|Number of monitored phases|
|» TotalBranches|number|false|read-only|Number of total branches.|

#### Enumerated Values

|Property|Value|
|---|---|
|EquipmentType|RackPDU|
|EquipmentType|FloorPDU|
|EquipmentType|ManualTransferSwitch|
|EquipmentType|AutomaticTransferSwitch|
|EquipmentType|Other|

<h2 id="tocS_HWInventory.1.0.0_RedfishOutletFRUInfo">HWInventory.1.0.0_RedfishOutletFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishoutletfruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishOutletFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishoutletfruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishoutletfruinfo"></a>

```json
{
  "VoltageType": "AC",
  "NominalVoltage": "string",
  "PowerEnabled": true,
  "RatedCurrentAmps": 0,
  "OutletType": "string",
  "PhaseWiringType": "OnePhase3Wire"
}

```

These are pass-through properties of the Redfish Outlet type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.  Child of a PDU.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|VoltageType|string|false|read-only|type of voltage|
|NominalVoltage|string|false|read-only|Nominal voltage for outlet.|
|PowerEnabled|boolean|false|none|Indicates if the outlet can be powered.|
|RatedCurrentAmps|number|false|read-only|Rated current in amps|
|OutletType|string|false|read-only|Type of outlet.|
|PhaseWiringType|string|false|read-only|Phase wiring type|

#### Enumerated Values

|Property|Value|
|---|---|
|VoltageType|AC|
|VoltageType|DC|
|PhaseWiringType|OnePhase3Wire|
|PhaseWiringType|TwoPhase3Wire|
|PhaseWiringType|TwoPhase4Wire|
|PhaseWiringType|ThreePhase4Wire|
|PhaseWiringType|ThreePhase5Wire|

<h2 id="tocS_HWInventory.1.0.0_RedfishCMMRectifierFRUInfo">HWInventory.1.0.0_RedfishCMMRectifierFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishcmmrectifierfruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishCMMRectifierFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishcmmrectifierfruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishcmmrectifierfruinfo"></a>

```json
{
  "Manufacturer": "string",
  "SerialNumber": "string",
  "Model": "string",
  "PartNumber": "string",
  "PowerCapacityWatts": 0,
  "PowerInputWatts": 0,
  "PowerOutputWatts": 0,
  "PowerSupplyType": "string"
}

```

These are pass-through properties of the Redfish PowerSupply type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.  Child of a Chassis.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Manufacturer|string|false|read-only|The manufacturer of this power supply.|
|SerialNumber|string|false|read-only|The serial number for this power supply.|
|Model|string|false|read-only|The model number for this power supply.|
|PartNumber|string|false|read-only|The part number for this power supply.|
|PowerCapacityWatts|number|false|read-only|The maximum capacity of this power supply.|
|PowerInputWatts|number|false|read-only|The measured input power of this power supply.|
|PowerOutputWatts|number|false|read-only|The measured output power of this power supply.|
|PowerSupplyType|string|false|read-only|The power supply type (AC or DC).|

<h2 id="tocS_HWInventory.1.0.0_RedfishNodeAccelRiserFRUInfo">HWInventory.1.0.0_RedfishNodeAccelRiserFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishnodeaccelriserfruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishNodeAccelRiserFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishnodeaccelriserfruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishnodeaccelriserfruinfo"></a>

```json
{
  "Producer": "string",
  "SerialNumber": "string",
  "Model": "string",
  "PartNumber": "string",
  "ProductionDate": "string",
  "Version": "string",
  "EngineeringChangeLevel": "string",
  "PhysicalContext": "string"
}

```

These are the properties of the NodeAccelRiser type that are passed-through to the HMS inventory data when the underlying Redfish object  type is an Assembly with a PhysicalContext of GPUSubsystem.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.  Child of a Chassis.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Producer|string|false|read-only|The manufacturer of this riser card.|
|SerialNumber|string|false|read-only|The serial number for this riser card.|
|Model|string|false|read-only|The model number for this riser card.|
|PartNumber|string|false|read-only|The part number for this riser card.|
|ProductionDate|string|false|read-only|The date of production of this riser card.|
|Version|string|false|read-only|The version of this riser card.|
|EngineeringChangeLevel|string|false|read-only|The engineering change level of this riser card.|
|PhysicalContext|string|false|read-only|The hardware type of this riser card.|

<h2 id="tocS_HWInventory.1.0.0_RedfishNodeEnclosurePowerSupplyFRUInfo">HWInventory.1.0.0_RedfishNodeEnclosurePowerSupplyFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishnodeenclosurepowersupplyfruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishNodeEnclosurePowerSupplyFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishnodeenclosurepowersupplyfruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishnodeenclosurepowersupplyfruinfo"></a>

```json
{
  "Manufacturer": "string",
  "SerialNumber": "string",
  "Model": "string",
  "PartNumber": "string",
  "PowerCapacityWatts": 0,
  "PowerInputWatts": 0,
  "PowerOutputWatts": 0,
  "PowerSupplyType": "string"
}

```

These are pass-through properties of the Redfish PowerSupply type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.  Child of a Chassis.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Manufacturer|string|false|read-only|The manufacturer of this power supply.|
|SerialNumber|string|false|read-only|The serial number for this power supply.|
|Model|string|false|read-only|The model number for this power supply.|
|PartNumber|string|false|read-only|The part number for this power supply.|
|PowerCapacityWatts|number|false|read-only|The maximum capacity of this power supply.|
|PowerInputWatts|number|false|read-only|The measured input power of this power supply.|
|PowerOutputWatts|number|false|read-only|The measured output power of this power supply.|
|PowerSupplyType|string|false|read-only|The power supply type (AC or DC).|

<h2 id="tocS_HWInventory.1.0.0_RedfishManagerFRUInfo">HWInventory.1.0.0_RedfishManagerFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_redfishmanagerfruinfo"></a>
<a id="schema_HWInventory.1.0.0_RedfishManagerFRUInfo"></a>
<a id="tocShwinventory.1.0.0_redfishmanagerfruinfo"></a>
<a id="tocshwinventory.1.0.0_redfishmanagerfruinfo"></a>

```json
{
  "ManagerType": "string",
  "Manufacturer": "string",
  "SerialNumber": "string",
  "Model": "string",
  "PartNumber": "string"
}

```

These are pass-through properties of the Redfish Manager type that are also used in HMS inventory data when this is the underlying Redfish object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ManagerType|string|false|read-only|The type of manager that this Resource represents, i.e. BMC, EnclosureManager, RackManager, etc.|
|Manufacturer|string|false|read-only|The manufacturer of this manager.|
|SerialNumber|string|false|read-only|The serial number for this manager.|
|Model|string|false|read-only|The model number for this manager.|
|PartNumber|string|false|read-only|The part number for this manager.|

<h2 id="tocS_HWInventory.1.0.0_HSNNICFRUInfo">HWInventory.1.0.0_HSNNICFRUInfo</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_hsnnicfruinfo"></a>
<a id="schema_HWInventory.1.0.0_HSNNICFRUInfo"></a>
<a id="tocShwinventory.1.0.0_hsnnicfruinfo"></a>
<a id="tocshwinventory.1.0.0_hsnnicfruinfo"></a>

```json
{
  "Manufacturer": "string",
  "Model": "string",
  "PartNumber": "string",
  "SKU": "string",
  "SerialNumber": "string"
}

```

These are pass-through properties of the Node HSN NIC type that are also used in HMS inventory data when this is the underlying network object type for a particular HMS component type.  These are the properties of a specific hardware instance/FRU that remain the same if the component is relocated within the system.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Manufacturer|string|false|none|The manufacturer of this HSN NIC.|
|Model|string|false|none|The model of this HSN NIC.|
|PartNumber|string|false|none|The part number for this HSN NIC.|
|SKU|string|false|none|The SKU for this HSN NIC.|
|SerialNumber|string|false|none|The serial number for this HSN NIC.|

<h2 id="tocS_HWInventory.1.0.0_HWInventoryHistoryCollection">HWInventory.1.0.0_HWInventoryHistoryCollection</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_hwinventoryhistorycollection"></a>
<a id="schema_HWInventory.1.0.0_HWInventoryHistoryCollection"></a>
<a id="tocShwinventory.1.0.0_hwinventoryhistorycollection"></a>
<a id="tocshwinventory.1.0.0_hwinventoryhistorycollection"></a>

```json
{
  "Components": [
    {
      "ID": "string",
      "History": [
        {
          "ID": "x0c0s0b0n0",
          "FRUID": "string",
          "Timestamp": "2018-08-09 03:55:57.000000",
          "EventType": "Added"
        }
      ]
    }
  ]
}

```

This is the array of sorted history entries (by FRU or by location).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Components|[[HWInventory.1.0.0_HWInventoryHistoryArray](#schemahwinventory.1.0.0_hwinventoryhistoryarray)]|false|none|[This is the array of history entries for a particular FRU or component location (xname).]|

<h2 id="tocS_HWInventory.1.0.0_HWInventoryHistoryArray">HWInventory.1.0.0_HWInventoryHistoryArray</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_hwinventoryhistoryarray"></a>
<a id="schema_HWInventory.1.0.0_HWInventoryHistoryArray"></a>
<a id="tocShwinventory.1.0.0_hwinventoryhistoryarray"></a>
<a id="tocshwinventory.1.0.0_hwinventoryhistoryarray"></a>

```json
{
  "ID": "string",
  "History": [
    {
      "ID": "x0c0s0b0n0",
      "FRUID": "string",
      "Timestamp": "2018-08-09 03:55:57.000000",
      "EventType": "Added"
    }
  ]
}

```

This is the array of history entries for a particular FRU or component location (xname).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|Locational xname or FRU ID of the component associated with the history entries in the 'History' array.|
|History|[[HWInventory.1.0.0_HWInventoryHistory](#schemahwinventory.1.0.0_hwinventoryhistory)]|false|none|[This is a HWInventory history entry. Each time a HWInventory event happens a history record is created with associated data including locational xname, FRU ID, timestamp, and event type (Added, Removed, Scanned, etc).]|

<h2 id="tocS_HWInventory.1.0.0_HWInventoryHistory">HWInventory.1.0.0_HWInventoryHistory</h2>
<!-- backwards compatibility -->
<a id="schemahwinventory.1.0.0_hwinventoryhistory"></a>
<a id="schema_HWInventory.1.0.0_HWInventoryHistory"></a>
<a id="tocShwinventory.1.0.0_hwinventoryhistory"></a>
<a id="tocshwinventory.1.0.0_hwinventoryhistory"></a>

```json
{
  "ID": "x0c0s0b0n0",
  "FRUID": "string",
  "Timestamp": "2018-08-09 03:55:57.000000",
  "EventType": "Added"
}

```

This is a HWInventory history entry. Each time a HWInventory event happens a history record is created with associated data including locational xname, FRU ID, timestamp, and event type (Added, Removed, Scanned, etc).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[XName.1.0.0](#schemaxname.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.|
|FRUID|[FRUId.1.0.0](#schemafruid.1.0.0)|false|none|Uniquely identifies a piece of hardware by a serial-number like identifier that is globally unique within the hardware inventory,|
|Timestamp|string(date-time)|false|none|The time that the history entry was created.|
|EventType|string|false|none|Describes the type of event the history entry was created for.|

#### Enumerated Values

|Property|Value|
|---|---|
|EventType|Added|
|EventType|Removed|
|EventType|Scanned|

<h2 id="tocS_RedfishEndpoint.1.0.0_RedfishEndpoint">RedfishEndpoint.1.0.0_RedfishEndpoint</h2>
<!-- backwards compatibility -->
<a id="schemaredfishendpoint.1.0.0_redfishendpoint"></a>
<a id="schema_RedfishEndpoint.1.0.0_RedfishEndpoint"></a>
<a id="tocSredfishendpoint.1.0.0_redfishendpoint"></a>
<a id="tocsredfishendpoint.1.0.0_redfishendpoint"></a>

```json
{
  "ID": "x0c0s0b0",
  "Type": "Node",
  "Name": "string",
  "Hostname": "string",
  "Domain": "string",
  "FQDN": "string",
  "Enabled": true,
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "User": "string",
  "Password": "string",
  "UseSSDP": true,
  "MacRequired": true,
  "MACAddr": "ae:12:e2:ff:89:9d",
  "IPAddress": "10.254.2.10",
  "RediscoverOnUpdate": true,
  "TemplateID": "string",
  "DiscoveryInfo": {
    "LastAttempt": "2019-08-24T14:15:22Z",
    "LastStatus": "EndpointInvalid",
    "RedfishVersion": "string"
  }
}

```

This describes a RedfishEndpoint that is interrogated in order to perform discovery of the components below it. It is a BMC or card/blade controller or other device that operates a Redfish entry point through which the components underneath it may be discovered and managed.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[XNameRFEndpoint.1.0.0](#schemaxnamerfendpoint.1.0.0)|true|none|Uniquely identifies the component by its physical location (xname). This is identical to a normal XName, but specifies a case where a BMC or other controller type is expected.|
|Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|none|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|
|Name|string|false|none|This is an arbitrary, user-provided name for the endpoint.  It can describe anything that is not captured by the ID/xname.|
|Hostname|string|false|none|Hostname of the endpoint's FQDN, will always be the host portion of the fully-qualified domain name. Note that the hostname should normally always be the same as the ID field (i.e. xname) of the endpoint.|
|Domain|string|false|none|Domain of the endpoint's FQDN.  Will always match remaining non-hostname portion of fully-qualified domain name (FQDN).|
|FQDN|string|false|none|Fully-qualified domain name of RF endpoint on management network. This is not writable because it is made up of the Hostname and Domain.|
|Enabled|boolean|false|none|To disable a component without deleting its data from the database, can be set to false|
|UUID|[UUID.1.0.0](#schemauuid.1.0.0)|false|none|This is a universally unique identifier i.e. UUID in the canonical format provided by Redfish to identify endpoints and services. If this is the UUID of a RedfishEndpoint, it should be the UUID broadcast by SSDP, if applicable.|
|User|string|false|none|Username to use when interrogating endpoint|
|Password|string|false|none|Password to use when interrogating endpoint, normally suppressed in output.|
|UseSSDP|boolean|false|none|Whether to use SSDP for discovery if the EP supports it.|
|MacRequired|boolean|false|none|Whether the MAC must be used (e.g. in River) in setting up geolocation info so the endpoint's location in the system can be determined.  The MAC does not need to be provided when creating the endpoint if the endpoint type can arrive at a geolocated hostname on its own.|
|MACAddr|string|false|none|This is the MAC on the of the Redfish Endpoint on the management network, i.e. corresponding to the FQDN field's Ethernet interface where the root service is running. Not the HSN MAC. This is a MAC address in the standard colon-separated 12 byte hex format.|
|IPAddress|string|false|none|This is the IP of the Redfish Endpoint on the management network, i.e. corresponding to the FQDN field's Ethernet interface where the root service is running. This may be IPv4 or IPv6|
|RediscoverOnUpdate|boolean|false|none|Trigger a rediscovery when endpoint info is updated.|
|TemplateID|string|false|none|Links to a discovery template defining how the endpoint should be discovered.|
|DiscoveryInfo|object|false|read-only|Contains info about the discovery status of the given endpoint.|
|» LastAttempt|string(date-time)|false|read-only|The time the last discovery attempt took place.|
|» LastStatus|string|false|read-only|Describes the outcome of the last discovery attempt.|
|» RedfishVersion|string|false|read-only|Version of Redfish as reported by the RF service root.|

#### Enumerated Values

|Property|Value|
|---|---|
|LastStatus|EndpointInvalid|
|LastStatus|EPResponseFailedDecode|
|LastStatus|HTTPsGetFailed|
|LastStatus|NotYetQueried|
|LastStatus|VerificationFailed|
|LastStatus|ChildVerificationFailed|
|LastStatus|DiscoverOK|

<h2 id="tocS_RedfishEndpoint.1.0.0_ResourceURICollection">RedfishEndpoint.1.0.0_ResourceURICollection</h2>
<!-- backwards compatibility -->
<a id="schemaredfishendpoint.1.0.0_resourceuricollection"></a>
<a id="schema_RedfishEndpoint.1.0.0_ResourceURICollection"></a>
<a id="tocSredfishendpoint.1.0.0_resourceuricollection"></a>
<a id="tocsredfishendpoint.1.0.0_resourceuricollection"></a>

```json
{
  "Name": "(Type of Object) Collection",
  "Members": [
    {
      "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
    }
  ],
  "MemberCount": 0
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|Should describe the collection, though the type of resources the links correspond to should also be inferred from the context in which the collection was obtained.|
|Members|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|read-only|An array of ResourceIds.|
|MemberCount|number(int32)|false|read-only|Number of ResourceURIs in the collection|

<h2 id="tocS_RedfishEndpointArray_RedfishEndpointArray">RedfishEndpointArray_RedfishEndpointArray</h2>
<!-- backwards compatibility -->
<a id="schemaredfishendpointarray_redfishendpointarray"></a>
<a id="schema_RedfishEndpointArray_RedfishEndpointArray"></a>
<a id="tocSredfishendpointarray_redfishendpointarray"></a>
<a id="tocsredfishendpointarray_redfishendpointarray"></a>

```json
{
  "RedfishEndpoints": [
    {
      "ID": "x0c0s0b0",
      "Type": "Node",
      "Name": "string",
      "Hostname": "string",
      "Domain": "string",
      "FQDN": "string",
      "Enabled": true,
      "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
      "User": "string",
      "Password": "string",
      "UseSSDP": true,
      "MacRequired": true,
      "MACAddr": "ae:12:e2:ff:89:9d",
      "IPAddress": "10.254.2.10",
      "RediscoverOnUpdate": true,
      "TemplateID": "string",
      "DiscoveryInfo": {
        "LastAttempt": "2019-08-24T14:15:22Z",
        "LastStatus": "EndpointInvalid",
        "RedfishVersion": "string"
      }
    }
  ]
}

```

This is a collection of RedfishEndpoint objects returned whenever a query is expected to result in 0 to n matches.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|RedfishEndpoints|[[RedfishEndpoint.1.0.0_RedfishEndpoint](#schemaredfishendpoint.1.0.0_redfishendpoint)]|false|none|Contains the HMS RedfishEndpoint objects in the array.|

<h2 id="tocS_RedfishEndpointArray_PostQuery">RedfishEndpointArray_PostQuery</h2>
<!-- backwards compatibility -->
<a id="schemaredfishendpointarray_postquery"></a>
<a id="schema_RedfishEndpointArray_PostQuery"></a>
<a id="tocSredfishendpointarray_postquery"></a>
<a id="tocsredfishendpointarray_postquery"></a>

```json
{
  "RedfishEndpointIDs": [
    "x0c0s0b0n0"
  ],
  "partition": "p1.2"
}

```

There are limits to the length of an HTTP URL and query string. Hence, if we wish to query an arbitrary list of XName/IDs, it will need to be in the body of the request.  This object is used for this purpose.  It is similar to the analogous GET operation.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|RedfishEndpointIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|true|none|An array of XName/ID values for the RedfishEndpoints to query.|
|partition|[XNamePartition.1.0.0](#schemaxnamepartition.1.0.0)|false|none|This is an ordinary xname, but one where only a partition (hard:soft) or the system alias (s0) will be expected as valid input.|

<h2 id="tocS_ServiceEndpoint.1.0.0_ServiceEndpoint">ServiceEndpoint.1.0.0_ServiceEndpoint</h2>
<!-- backwards compatibility -->
<a id="schemaserviceendpoint.1.0.0_serviceendpoint"></a>
<a id="schema_ServiceEndpoint.1.0.0_ServiceEndpoint"></a>
<a id="tocSserviceendpoint.1.0.0_serviceendpoint"></a>
<a id="tocsserviceendpoint.1.0.0_serviceendpoint"></a>

```json
{
  "RedfishEndpointID": "x0c0s0b0",
  "RedfishType": "ComputerSystem",
  "RedfishSubtype": "Physical",
  "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "OdataID": "/redfish/v1/Systems/System.Embedded.1",
  "RedfishEndpointFQDN": "string",
  "RedfishURL": "string",
  "ServiceInfo": {
    "Name": "string"
  }
}

```

This describes a service running on a Redfish endpoint and is populated when Redfish endpoint discovery occurs.  It is used by clients who need to interact directly with the service via Redfish.
There are also ComponentEndpoints, which represent Redfish components of a physical type (i.e., we track their state as components), which are also discovered when the Redfish Endpoint is discovered.
The RedfishEndpointID is just the ID of the parent Redfish endpoint. As there are many service types per endpoint, the RedfishType must also be included to get a unique entry for a service.  Services do not have their own xnames, and so they are identified by thee combination of the RedfishEndpointID they are running on, plus the RedfishType value (e.g. AccountService, TaskService, etc.).
NOTE: These records are discovered, not created, and therefore are not writable (since any changes would be overwritten by a subsequent discovery).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|RedfishEndpointID|[XNameRFEndpoint.1.0.0](#schemaxnamerfendpoint.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). This is identical to a normal XName, but specifies a case where a BMC or other controller type is expected.|
|RedfishType|[RedfishType.1.0.0](#schemaredfishtype.1.0.0)|false|none|This is the Redfish object type, not to be confused with the HMS component type.|
|RedfishSubtype|[RedfishSubtype.1.0.0](#schemaredfishsubtype.1.0.0)|false|none|This is the type corresponding to the Redfish object type, i.e. the ChassisType field, SystemType, ManagerType fields.  We only use these three types to create ComponentEndpoints for now.|
|UUID|[UUID.1.0.0](#schemauuid.1.0.0)|false|none|This is a universally unique identifier i.e. UUID in the canonical format provided by Redfish to identify endpoints and services. If this is the UUID of a RedfishEndpoint, it should be the UUID broadcast by SSDP, if applicable.|
|OdataID|[OdataID.1.0.0](#schemaodataid.1.0.0)|false|none|This is the path (relative to a Redfish endpoint) of a particular Redfish resource, e.g. /Redfish/v1/Systems/System.Embedded.1|
|RedfishEndpointFQDN|string|false|read-only|This is a back-reference to the fully-qualified domain name of the parent Redfish endpoint that was used to discover the component.  It is the RedfishEndpointID field i.e. the hostname/xname plus its current domain.|
|RedfishURL|string|false|read-only|This is the complete URL to the corresponding Redfish object, combining the RedfishEndpoint's FQDN and the OdataID.|
|ServiceInfo|[ServiceEndpoint.1.0.0_ServiceInfo](#schemaserviceendpoint.1.0.0_serviceinfo)|false|none|This is any additional information for the service.  This is service specific.  Schema for Redfish services can be found at https://redfish.dmtf.org/redfish/schema_index|

<h2 id="tocS_ServiceEndpoint.1.0.0_ServiceInfo">ServiceEndpoint.1.0.0_ServiceInfo</h2>
<!-- backwards compatibility -->
<a id="schemaserviceendpoint.1.0.0_serviceinfo"></a>
<a id="schema_ServiceEndpoint.1.0.0_ServiceInfo"></a>
<a id="tocSserviceendpoint.1.0.0_serviceinfo"></a>
<a id="tocsserviceendpoint.1.0.0_serviceinfo"></a>

```json
{
  "Name": "string"
}

```

This is any additional information for the service.  This is service specific.  Schema for Redfish services can be found at https://redfish.dmtf.org/redfish/schema_index

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|The name of the service.|

<h2 id="tocS_ServiceEndpointArray_ServiceEndpointArray">ServiceEndpointArray_ServiceEndpointArray</h2>
<!-- backwards compatibility -->
<a id="schemaserviceendpointarray_serviceendpointarray"></a>
<a id="schema_ServiceEndpointArray_ServiceEndpointArray"></a>
<a id="tocSserviceendpointarray_serviceendpointarray"></a>
<a id="tocsserviceendpointarray_serviceendpointarray"></a>

```json
{
  "ServiceEndpoints": [
    {
      "RedfishEndpointID": "x0c0s0b0",
      "RedfishType": "ComputerSystem",
      "RedfishSubtype": "Physical",
      "UUID": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
      "OdataID": "/redfish/v1/Systems/System.Embedded.1",
      "RedfishEndpointFQDN": "string",
      "RedfishURL": "string",
      "ServiceInfo": {
        "Name": "string"
      }
    }
  ]
}

```

This is a collection of ServiceEndpoint objects returned whenever a query is expected to result in 0 to n matches.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ServiceEndpoints|[[ServiceEndpoint.1.0.0_ServiceEndpoint](#schemaserviceendpoint.1.0.0_serviceendpoint)]|false|none|Contains the HMS ServiceEndpoint objects in the array.|

<h2 id="tocS_CompEthInterface.1.0.0">CompEthInterface.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemacompethinterface.1.0.0"></a>
<a id="schema_CompEthInterface.1.0.0"></a>
<a id="tocScompethinterface.1.0.0"></a>
<a id="tocscompethinterface.1.0.0"></a>

```json
{
  "ID": "a4bf012b7310",
  "Description": "string",
  "MACAddress": "string",
  "IPAddresses": [
    {
      "IPAddress": "10.252.0.1",
      "Network": "HMN"
    }
  ],
  "LastUpdate": "2020-05-13T19:18:45.524974Z",
  "ComponentID": "x0c0s1b0n0",
  "Type": "Node"
}

```

A component Ethernet interface is an object describing a relation between a MAC address and IP address for components.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|read-only|The ID of the component Ethernet interface.|
|Description|string|false|none|An optional description for the component Ethernet interface.|
|MACAddress|string|true|none|The MAC address of this component Ethernet interface|
|IPAddresses|[[CompEthInterface.1.0.0_IPAddressMapping](#schemacompethinterface.1.0.0_ipaddressmapping)]|false|none|The IP addresses associated with the MAC address for this component Ethernet interface.|
|LastUpdate|string(date-time)|false|read-only|A timestamp for when the component Ethernet interface last was modified.|
|ComponentID|[XNameRW.1.0.0](#schemaxnamerw.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is the non-readOnly version for writable component lists.|
|Type|[HMSType.1.0.0](#schemahmstype.1.0.0)|false|none|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|

<h2 id="tocS_CompEthInterface.1.0.0_Patch">CompEthInterface.1.0.0_Patch</h2>
<!-- backwards compatibility -->
<a id="schemacompethinterface.1.0.0_patch"></a>
<a id="schema_CompEthInterface.1.0.0_Patch"></a>
<a id="tocScompethinterface.1.0.0_patch"></a>
<a id="tocscompethinterface.1.0.0_patch"></a>

```json
{
  "Description": "string",
  "IPAddresses": [
    {
      "IPAddress": "10.252.0.1",
      "Network": "HMN"
    }
  ],
  "ComponentID": "x0c0s1b0n0"
}

```

To update the IP addresses, CompID, and/or description fields of a component Ethernet interface, a PATCH operation can be used. Omitted fields are not updated. NOTE: Updating the IP addresses field updates the LastUpdate field.  

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Description|string|false|none|An optional description for the component Ethernet interface.|
|IPAddresses|[[CompEthInterface.1.0.0_IPAddressMapping](#schemacompethinterface.1.0.0_ipaddressmapping)]|false|none|The IP addresses associated with the MAC address for this component Ethernet interface.|
|ComponentID|[XNameRW.1.0.0](#schemaxnamerw.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is the non-readOnly version for writable component lists.|

<h2 id="tocS_CompEthInterface.1.0.0_IPAddressMapping">CompEthInterface.1.0.0_IPAddressMapping</h2>
<!-- backwards compatibility -->
<a id="schemacompethinterface.1.0.0_ipaddressmapping"></a>
<a id="schema_CompEthInterface.1.0.0_IPAddressMapping"></a>
<a id="tocScompethinterface.1.0.0_ipaddressmapping"></a>
<a id="tocscompethinterface.1.0.0_ipaddressmapping"></a>

```json
{
  "IPAddress": "10.252.0.1",
  "Network": "HMN"
}

```

A IP address Mapping maps a IP address to a network. In a Component Ethernet Interface it is used to describe what IP addresses and their networks that are associated with it.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|IPAddress|string|true|none|The IP address associated with the MAC address for this component Ethernet interface on for this particular network.|
|Network|string|false|none|The network that this IP addresses is associated with.|

<h2 id="tocS_CompEthInterface.1.0.0_IPAddressMapping_Patch">CompEthInterface.1.0.0_IPAddressMapping_Patch</h2>
<!-- backwards compatibility -->
<a id="schemacompethinterface.1.0.0_ipaddressmapping_patch"></a>
<a id="schema_CompEthInterface.1.0.0_IPAddressMapping_Patch"></a>
<a id="tocScompethinterface.1.0.0_ipaddressmapping_patch"></a>
<a id="tocscompethinterface.1.0.0_ipaddressmapping_patch"></a>

```json
{
  "Network": "string"
}

```

To update the network field a IP address mapping in a component  Ethernet interface a PATCH operation can be used. Omitted fields are not updated.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Network|string|false|none|The network that this IP addresses is associated with.|

<h2 id="tocS_DiscoveryStatus.1.0.0_DiscoveryStatus">DiscoveryStatus.1.0.0_DiscoveryStatus</h2>
<!-- backwards compatibility -->
<a id="schemadiscoverystatus.1.0.0_discoverystatus"></a>
<a id="schema_DiscoveryStatus.1.0.0_DiscoveryStatus"></a>
<a id="tocSdiscoverystatus.1.0.0_discoverystatus"></a>
<a id="tocsdiscoverystatus.1.0.0_discoverystatus"></a>

```json
{
  "ID": 0,
  "Status": "Complete",
  "LastUpdateTime": "2018-08-09 03:55:57.000000",
  "Details": null
}

```

Returns info on the current status of a discovery operation with the given ID returned when a Discover action is requested.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|number(int32)|false|read-only|The ID number of the discover operation.|
|Status|string|false|read-only|Describes the status of the given Discover operation.|
|LastUpdateTime|string(date-time)|false|read-only|The time that the Status field was last updated.|
|Details|[DiscoveryStatus.1.0.0_Details](#schemadiscoverystatus.1.0.0_details)|false|none|Details accompanying a DiscoveryStatus entry.  Optional. Reserved for future use.|

#### Enumerated Values

|Property|Value|
|---|---|
|Status|NotStarted|
|Status|Pending|
|Status|InProgress|
|Status|Complete|

<h2 id="tocS_DiscoveryStatus.1.0.0_Details">DiscoveryStatus.1.0.0_Details</h2>
<!-- backwards compatibility -->
<a id="schemadiscoverystatus.1.0.0_details"></a>
<a id="schema_DiscoveryStatus.1.0.0_Details"></a>
<a id="tocSdiscoverystatus.1.0.0_details"></a>
<a id="tocsdiscoverystatus.1.0.0_details"></a>

```json
null

```

Details accompanying a DiscoveryStatus entry.  Optional. Reserved for future use.

### Properties

*None*

<h2 id="tocS_Discover.1.0.0_DiscoverInput">Discover.1.0.0_DiscoverInput</h2>
<!-- backwards compatibility -->
<a id="schemadiscover.1.0.0_discoverinput"></a>
<a id="schema_Discover.1.0.0_DiscoverInput"></a>
<a id="tocSdiscover.1.0.0_discoverinput"></a>
<a id="tocsdiscover.1.0.0_discoverinput"></a>

```json
{
  "xnames": [
    "x0c0s0b0"
  ],
  "force": false
}

```

The POST body for a Discover operation.  Note that these fields are optional.  The default for the xnames field is to select all RedfishEndpoints. The default for force is false.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xnames|[[XNameRFEndpoint.1.0.0](#schemaxnamerfendpoint.1.0.0)]|false|none|An array of XName/ID values for the RedfishEndpoints to discover. If zero-length or omitted, all RedfishEndpoints will be discovered.|
|force|boolean|false|none|Whether to force discovery if there is already a conflicting DiscoveryStatus entry that is either Pending or InProgress. default is false.|

<h2 id="tocS_Subscriptions_SCNPostSubscription">Subscriptions_SCNPostSubscription</h2>
<!-- backwards compatibility -->
<a id="schemasubscriptions_scnpostsubscription"></a>
<a id="schema_Subscriptions_SCNPostSubscription"></a>
<a id="tocSsubscriptions_scnpostsubscription"></a>
<a id="tocssubscriptions_scnpostsubscription"></a>

```json
{
  "Subscriber": "scnfd@sms02.cray.com",
  "Enabled": true,
  "Roles": [
    "Compute"
  ],
  "SubRoles": [
    "Worker"
  ],
  "SoftwareStatus": [
    "string"
  ],
  "States": [
    "Ready"
  ],
  "Url": "https://sms02.cray.com:27000/scnfd/v1/scn"
}

```

This is the JSON payload that contains information to create a new state change notification subscription

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Subscriber|string|false|none|This is the name of the subscriber.|
|Enabled|boolean|false|none|This value toggles subscriptions to state change notifications concerning components being disabled or enabled. 'true' will cause the subscriber to be notified about components being enabled or disabled. 'false' or empty will result in no such notifications.|
|Roles|[[HMSRole.1.0.0](#schemahmsrole.1.0.0)]|false|none|This is an array containing component roles for which to be notified when role changes occur.|
|SubRoles|[[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)]|false|none|This is an array containing component subroles for which to be notified when subrole changes occur.|
|SoftwareStatus|[string]|false|none|This is an array containing component software statuses for which to be notified when software status changes occur.|
|States|[[HMSState.1.0.0](#schemahmsstate.1.0.0)]|false|none|This is an array containing component states for which to be notified when state changes occur.|
|Url|[Subscriptions_Url](#schemasubscriptions_url)|false|none|URL to send notifications to|

<h2 id="tocS_Subscriptions_SCNPatchSubscription">Subscriptions_SCNPatchSubscription</h2>
<!-- backwards compatibility -->
<a id="schemasubscriptions_scnpatchsubscription"></a>
<a id="schema_Subscriptions_SCNPatchSubscription"></a>
<a id="tocSsubscriptions_scnpatchsubscription"></a>
<a id="tocssubscriptions_scnpatchsubscription"></a>

```json
{
  "Op": "add",
  "Enabled": true,
  "Roles": [
    "Compute"
  ],
  "SubRoles": [
    "Worker"
  ],
  "SoftwareStatus": [
    "string"
  ],
  "States": [
    "Ready"
  ]
}

```

This is the JSON payload that contains state change notification subscription information.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Op|string|false|none|The type of operation to be performed on the subscription|
|Enabled|boolean|false|none|This value toggles subscriptions to state change notifications concerning components being disabled or enabled. 'true' will cause the subscriber to be notified about components being enabled or disabled. 'false' or empty will result in no such notifications.|
|Roles|[[HMSRole.1.0.0](#schemahmsrole.1.0.0)]|false|none|This is an array containing component roles for which to be notified when role changes occur.|
|SubRoles|[[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)]|false|none|This is an array containing component subroles for which to be notified when subrole changes occur.|
|SoftwareStatus|[string]|false|none|This is an array containing component software statuses for which to be notified when software status changes occur.|
|States|[[HMSState.1.0.0](#schemahmsstate.1.0.0)]|false|none|This is an array containing component states for which to be notified when state changes occur.|

#### Enumerated Values

|Property|Value|
|---|---|
|Op|add|
|Op|remove|
|Op|replace|

<h2 id="tocS_Subscriptions_SCNSubscriptionArrayItem.1.0.0">Subscriptions_SCNSubscriptionArrayItem.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemasubscriptions_scnsubscriptionarrayitem.1.0.0"></a>
<a id="schema_Subscriptions_SCNSubscriptionArrayItem.1.0.0"></a>
<a id="tocSsubscriptions_scnsubscriptionarrayitem.1.0.0"></a>
<a id="tocssubscriptions_scnsubscriptionarrayitem.1.0.0"></a>

```json
{
  "ID": "42",
  "Subscriber": "scnfd@sms02.cray.com",
  "Enabled": true,
  "Roles": [
    "Compute"
  ],
  "SubRoles": [
    "Worker"
  ],
  "SoftwareStatus": [
    "string"
  ],
  "States": [
    "Ready"
  ],
  "Url": "https://sms02.cray.com:27000/scnfd/v1/scn"
}

```

State change notification subscription JSON payload.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[Subscription_ID](#schemasubscription_id)|false|none|This is the ID associated with the subscription that was generated at its creation.|
|Subscriber|string|false|none|none|
|Enabled|boolean|false|none|This value toggles subscriptions to state change notifications concerning components being disabled or enabled. 'true' will cause the subscriber to be notified about components being enabled or disabled. 'false' or empty will result in no such notifications.|
|Roles|[[HMSRole.1.0.0](#schemahmsrole.1.0.0)]|false|none|This is an array containing component roles for which to be notified when role changes occur.|
|SubRoles|[[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)]|false|none|This is an array containing component subroles for which to be notified when subrole changes occur.|
|SoftwareStatus|[string]|false|none|This is an array containing component software statuses for which to be notified when software status changes occur.|
|States|[[HMSState.1.0.0](#schemahmsstate.1.0.0)]|false|none|This is an array containing component states for which to be notified when state changes occur.|
|Url|[Subscriptions_Url](#schemasubscriptions_url)|false|none|URL to send notifications to|

<h2 id="tocS_Subscriptions_SCNSubscriptionArray">Subscriptions_SCNSubscriptionArray</h2>
<!-- backwards compatibility -->
<a id="schemasubscriptions_scnsubscriptionarray"></a>
<a id="schema_Subscriptions_SCNSubscriptionArray"></a>
<a id="tocSsubscriptions_scnsubscriptionarray"></a>
<a id="tocssubscriptions_scnsubscriptionarray"></a>

```json
{
  "SubscriptionList": [
    {
      "ID": "42",
      "Subscriber": "scnfd@sms02.cray.com",
      "Enabled": true,
      "Roles": [
        "Compute"
      ],
      "SubRoles": [
        "Worker"
      ],
      "SoftwareStatus": [
        "string"
      ],
      "States": [
        "Ready"
      ],
      "Url": "https://sms02.cray.com:27000/scnfd/v1/scn"
    }
  ]
}

```

List of all currently held state change notification subscriptions.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|SubscriptionList|[[Subscriptions_SCNSubscriptionArrayItem.1.0.0](#schemasubscriptions_scnsubscriptionarrayitem.1.0.0)]|false|none|[State change notification subscription JSON payload.]|

<h2 id="tocS_Subscriptions_Url">Subscriptions_Url</h2>
<!-- backwards compatibility -->
<a id="schemasubscriptions_url"></a>
<a id="schema_Subscriptions_Url"></a>
<a id="tocSsubscriptions_url"></a>
<a id="tocssubscriptions_url"></a>

```json
"https://sms02.cray.com:27000/scnfd/v1/scn"

```

URL to send notifications to

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|URL to send notifications to|

<h2 id="tocS_Subscription_ID">Subscription_ID</h2>
<!-- backwards compatibility -->
<a id="schemasubscription_id"></a>
<a id="schema_Subscription_ID"></a>
<a id="tocSsubscription_id"></a>
<a id="tocssubscription_id"></a>

```json
"42"

```

This is the ID associated with the subscription that was generated at its creation.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is the ID associated with the subscription that was generated at its creation.|

<h2 id="tocS_Group.1.0.0">Group.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemagroup.1.0.0"></a>
<a id="schema_Group.1.0.0"></a>
<a id="tocSgroup.1.0.0"></a>
<a id="tocsgroup.1.0.0"></a>

```json
{
  "label": "blue",
  "description": "This is the blue group",
  "tags": [
    "optional_tag1",
    "optional_tag2"
  ],
  "exclusiveGroup": "optional_excl_group",
  "members": {
    "ids": [
      "x1c0s1b0n0",
      "x1c0s1b0n1",
      "x1c0s2b0n0",
      "x1c0s2b0n1"
    ]
  }
}

```

A group is an informal, possibly overlapping division of the system that groups components under an administratively chosen label (i.e. group name). Unlike partitions, components can be members of any number of groups.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|label|[ResourceName](#schemaresourcename)|true|none|Acceptable format for certain user-requested string identifiers.|
|description|string|false|none|A one-line, user-provided description of the group.|
|tags|[[ResourceName](#schemaresourcename)]|false|none|A free-form array of strings to provide extra organization/filtering. Not to be confused with labels/groups.|
|exclusiveGroup|[ResourceName](#schemaresourcename)|false|none|Acceptable format for certain user-requested string identifiers.|
|members|[Members.1.0.0](#schemamembers.1.0.0)|false|none|The members are a fully enumerated (i.e. no implied members besides those explicitly provided) representation of the components a partition or group|

<h2 id="tocS_Group.1.0.0_Patch">Group.1.0.0_Patch</h2>
<!-- backwards compatibility -->
<a id="schemagroup.1.0.0_patch"></a>
<a id="schema_Group.1.0.0_Patch"></a>
<a id="tocSgroup.1.0.0_patch"></a>
<a id="tocsgroup.1.0.0_patch"></a>

```json
{
  "description": "This is an updated group description",
  "tags": [
    "new_tag",
    "existing_tag"
  ]
}

```

To update the tags array and/or description, a PATCH operation can be used.  If either field is omitted, it will not be updated. NOTE: This cannot be used to completely replace the members list Rather, individual members can be removed or added with the POST/DELETE /members API.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|description|string|false|none|A one-line, user-provided description of the group.|
|tags|[[ResourceName](#schemaresourcename)]|false|none|A free-form array of strings to provide extra organization/filtering. Not to be confused with labels/groups.|

<h2 id="tocS_Partition.1.0.0">Partition.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemapartition.1.0.0"></a>
<a id="schema_Partition.1.0.0"></a>
<a id="tocSpartition.1.0.0"></a>
<a id="tocspartition.1.0.0"></a>

```json
{
  "name": "p1",
  "description": "This is partition 1",
  "tags": [
    "optional_tag_a",
    "optional_tag1"
  ],
  "members": {
    "ids": [
      "x1c0s1b0n0",
      "x1c0s1b0n1",
      "x2c0s3b0n0",
      "x2c0s3b0n1"
    ]
  }
}

```

A partition is a formal, non-overlapping division of the system that forms an administratively distinct sub-system e.g. for implementing multi-tenancy.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[ResourceName](#schemaresourcename)|true|none|Acceptable format for certain user-requested string identifiers.|
|description|string|false|none|A one-line, user-provided description of the partition.|
|tags|[[ResourceName](#schemaresourcename)]|false|none|A free-form array of strings to provide extra organization/filtering. Not to be confused with labels/groups.|
|members|[Members.1.0.0](#schemamembers.1.0.0)|false|none|The members are a fully enumerated (i.e. no implied members besides those explicitly provided) representation of the components a partition or group|

<h2 id="tocS_Partition.1.0.0_Patch">Partition.1.0.0_Patch</h2>
<!-- backwards compatibility -->
<a id="schemapartition.1.0.0_patch"></a>
<a id="schema_Partition.1.0.0_Patch"></a>
<a id="tocSpartition.1.0.0_patch"></a>
<a id="tocspartition.1.0.0_patch"></a>

```json
{
  "description": "This is an updated partition description",
  "tags": [
    "new_tag",
    "existing_tag"
  ]
}

```

To update the tags array and/or description, a PATCH operation can be used.  If either field is omitted, it will not be updated. NOTE: This cannot be used to completely replace the members list Rather, individual members can be removed or added with the POST/DELETE /members API.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|description|string|false|none|A one-line, user-provided description of the group.|
|tags|[[ResourceName](#schemaresourcename)]|false|none|A free-form array of strings to provide extra organization/filtering. Not to be confused with labels/groups.|

<h2 id="tocS_Members.1.0.0">Members.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemamembers.1.0.0"></a>
<a id="schema_Members.1.0.0"></a>
<a id="tocSmembers.1.0.0"></a>
<a id="tocsmembers.1.0.0"></a>

```json
{
  "ids": [
    "x1c0s1b0n0",
    "x1c0s1b0n1",
    "x2c0s3b0n0",
    "x2c0s3b0n1"
  ]
}

```

The members are a fully enumerated (i.e. no implied members besides those explicitly provided) representation of the components a partition or group

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ids|[[XNameRW.1.0.0](#schemaxnamerw.1.0.0)]|false|none|Set of Component XName IDs that represent the membership of the group or partition.|

<h2 id="tocS_MemberID">MemberID</h2>
<!-- backwards compatibility -->
<a id="schemamemberid"></a>
<a id="schema_MemberID"></a>
<a id="tocSmemberid"></a>
<a id="tocsmemberid"></a>

```json
{
  "id": "x0c0s1b0n0"
}

```

This is used when creating an new entry in a Group or Partition members array. It is the xname ID of the new member.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|[XNameRW.1.0.0](#schemaxnamerw.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is the non-readOnly version for writable component lists.|

<h2 id="tocS_Membership.1.0.0">Membership.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemamembership.1.0.0"></a>
<a id="schema_Membership.1.0.0"></a>
<a id="tocSmembership.1.0.0"></a>
<a id="tocsmembership.1.0.0"></a>

```json
{
  "id": "x0c0s22b0n0",
  "nid": 45,
  "partitionName": "p1",
  "groupLabels": [
    "group1",
    "group2"
  ]
}

```

A membership is a mapping of a component xname to its set of group labels and partition names.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|[XName.1.0.0](#schemaxname.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.|
|partitionName|string|false|none|The name is a human-readable identifier for the partition and uniquely identifies it.|
|groupLabels|[string]|false|none|An array with all group labels the component is associated with The label is the human-readable identifier for a group and uniquely identifies it.|

<h2 id="tocS_Lock.1.0.0">Lock.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemalock.1.0.0"></a>
<a id="schema_Lock.1.0.0"></a>
<a id="tocSlock.1.0.0"></a>
<a id="tocslock.1.0.0"></a>

```json
{
  "id": "bf9362ad-b29c-40ed-9881-18a5dba3a26b",
  "created": "2019-09-12 03:55:57.000000",
  "reason": "For firmware update",
  "owner": "FUS",
  "lifetime": 90,
  "xnames": [
    "x1c0s1b0n0",
    "x1c0s1b0n1",
    "x1c0s2b0n0",
    "x1c0s2b0n1"
  ]
}

```

A lock is an object describing a temporary reservation of a set of components held by an external service.  If not removed by the external service, HSM will automatically remove the lock after its lifetime has expired.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string|false|read-only|The ID number of the lock.|
|created|string(date-time)|false|read-only|A timestamp for when the lock was created.|
|reason|string|false|none|A one-line, user-provided reason for the lock.|
|owner|string|true|none|A user-provided self identifier for the lock|
|lifetime|integer|true|none|The length of time in seconds the component lock should exist before it is automatically deleted by HSM.|
|xnames|[[XNameRW.1.0.0](#schemaxnamerw.1.0.0)]|true|none|An array of XName/ID values for the components managed by the lock. These components will have their component flag set to "Locked" upon lock creation and set to "OK" upon lock deletion.|

<h2 id="tocS_Lock.1.0.0_Patch">Lock.1.0.0_Patch</h2>
<!-- backwards compatibility -->
<a id="schemalock.1.0.0_patch"></a>
<a id="schema_Lock.1.0.0_Patch"></a>
<a id="tocSlock.1.0.0_patch"></a>
<a id="tocslock.1.0.0_patch"></a>

```json
{
  "reason": "For firmware update",
  "owner": "FUS.25",
  "lifetime": 90
}

```

To update the reason, owner, and/or lifetime fields, a PATCH operation can be used.  Omitted fields are not updated. NOTE: Updating the lifetime field renews the lock. The new expiration time is the lifetime length AFTER the update. The creation timestamp is updated.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|reason|string|false|none|A one-line, user-provided reason for the lock.|
|owner|string|false|none|A user-provided self identifier for the lock (service.JobID)|
|lifetime|integer|false|none|The length of time in seconds the component lock should exist before it is automatically deleted by HSM.|

<h2 id="tocS_AdminLock.1.0.0">AdminLock.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaadminlock.1.0.0"></a>
<a id="schema_AdminLock.1.0.0"></a>
<a id="tocSadminlock.1.0.0"></a>
<a id="tocsadminlock.1.0.0"></a>

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|false|none|An array of XName/ID values for the components to query.|
|Partition|[string]|false|none|Partition name to filter on, as per current /partitions/names|
|Group|[string]|false|none|Group label to filter on, as per current /groups/labels|
|Type|[string]|false|none|Retrieve all components with the given HMS type.|
|State|[[HMSState.1.0.0](#schemahmsstate.1.0.0)]|false|none|Retrieve all components with the given HMS state.|
|Flag|[[HMSFlag.1.0.0](#schemahmsflag.1.0.0)]|false|none|Retrieve all components with the given HMS flag value.|
|Enabled|[string]|false|none|Retrieve all components with the given enabled status (true or false).|
|Softwarestatus|[string]|false|none|Retrieve all components with the given software status. Software status is a free form string. Matching is case-insensitive.|
|Role|[[HMSRole.1.0.0](#schemahmsrole.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS role|
|Subrole|[[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS subrole|
|Subtype|[string]|false|none|Retrieve all components with the given HMS subtype.|
|Arch|[[HMSArch.1.0.0](#schemahmsarch.1.0.0)]|false|none|Retrieve all components with the given architecture.|
|Class|[[HMSClass.1.0.0](#schemahmsclass.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS hardware class. Class can be River, Mountain, etc.|
|NID|[string]|false|none|Retrieve all components (i.e. one node) with the given integer NID|
|ProcessingModel|string|false|none|Rigid is all or nothing, flexible is best attempt.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_AdminReservationRemove.1.0.0">AdminReservationRemove.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaadminreservationremove.1.0.0"></a>
<a id="schema_AdminReservationRemove.1.0.0"></a>
<a id="tocSadminreservationremove.1.0.0"></a>
<a id="tocsadminreservationremove.1.0.0"></a>

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|false|none|An array of XName/ID values for the components to query.|
|Partition|[string]|false|none|Partition name to filter on, as per current /partitions/names|
|Group|[string]|false|none|Group label to filter on, as per current /groups/labels|
|Type|[string]|false|none|Retrieve all components with the given HMS type.|
|State|[[HMSState.1.0.0](#schemahmsstate.1.0.0)]|false|none|Retrieve all components with the given HMS state.|
|Flag|[[HMSFlag.1.0.0](#schemahmsflag.1.0.0)]|false|none|Retrieve all components with the given HMS flag value.|
|Enabled|[string]|false|none|Retrieve all components with the given enabled status (true or false).|
|Softwarestatus|[string]|false|none|Retrieve all components with the given software status. Software status is a free form string. Matching is case-insensitive.|
|Role|[[HMSRole.1.0.0](#schemahmsrole.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS role|
|Subrole|[[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS subrole|
|Subtype|[string]|false|none|Retrieve all components with the given HMS subtype.|
|Arch|[[HMSArch.1.0.0](#schemahmsarch.1.0.0)]|false|none|Retrieve all components with the given architecture.|
|Class|[[HMSClass.1.0.0](#schemahmsclass.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS hardware class. Class can be River, Mountain, etc.|
|NID|[string]|false|none|Retrieve all components (i.e. one node) with the given integer NID|
|ProcessingModel|string|false|none|Rigid is all or nothing, flexible is best attempt.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_AdminStatusCheck_Response.1.0.0">AdminStatusCheck_Response.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaadminstatuscheck_response.1.0.0"></a>
<a id="schema_AdminStatusCheck_Response.1.0.0"></a>
<a id="tocSadminstatuscheck_response.1.0.0"></a>
<a id="tocsadminstatuscheck_response.1.0.0"></a>

```json
{
  "Components": [
    {
      "ID": "x1001c0s0b0",
      "Locked": false,
      "Reserved": true,
      "CreatedTime": "2019-08-24T14:15:22Z",
      "ExpirationTime": "2019-08-24T14:15:22Z",
      "ReservationDisabled": false
    }
  ],
  "NotFound": [
    "x1000c0s0b0"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Components|[[ComponentStatus.1.0.0](#schemacomponentstatus.1.0.0)]|false|none|none|
|NotFound|[string]|false|none|none|

<h2 id="tocS_AdminReservationCreate_Response.1.0.0">AdminReservationCreate_Response.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaadminreservationcreate_response.1.0.0"></a>
<a id="schema_AdminReservationCreate_Response.1.0.0"></a>
<a id="tocSadminreservationcreate_response.1.0.0"></a>
<a id="tocsadminreservationcreate_response.1.0.0"></a>

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "string",
      "ReservationKey": "string"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Success|[[XnameKeysNoExpire.1.0.0](#schemaxnamekeysnoexpire.1.0.0)]|false|none|none|
|Failure|[[FailedXnames.1.0.0](#schemafailedxnames.1.0.0)]|false|none|none|

<h2 id="tocS_AdminReservationCreate.1.0.0">AdminReservationCreate.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaadminreservationcreate.1.0.0"></a>
<a id="schema_AdminReservationCreate.1.0.0"></a>
<a id="tocSadminreservationcreate.1.0.0"></a>
<a id="tocsadminreservationcreate.1.0.0"></a>

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|false|none|An array of XName/ID values for the components to query.|
|Partition|[string]|false|none|Partition name to filter on, as per current /partitions/names|
|Group|[string]|false|none|Group label to filter on, as per current /groups/labels|
|Type|[string]|false|none|Retrieve all components with the given HMS type.|
|State|[[HMSState.1.0.0](#schemahmsstate.1.0.0)]|false|none|Retrieve all components with the given HMS state.|
|Flag|[[HMSFlag.1.0.0](#schemahmsflag.1.0.0)]|false|none|Retrieve all components with the given HMS flag value.|
|Enabled|[string]|false|none|Retrieve all components with the given enabled status (true or false).|
|Softwarestatus|[string]|false|none|Retrieve all components with the given software status. Software status is a free form string. Matching is case-insensitive.|
|Role|[[HMSRole.1.0.0](#schemahmsrole.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS role|
|Subrole|[[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS subrole|
|Subtype|[string]|false|none|Retrieve all components with the given HMS subtype.|
|Arch|[[HMSArch.1.0.0](#schemahmsarch.1.0.0)]|false|none|Retrieve all components with the given architecture.|
|Class|[[HMSClass.1.0.0](#schemahmsclass.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS hardware class. Class can be River, Mountain, etc.|
|NID|[string]|false|none|Retrieve all components (i.e. one node) with the given integer NID|
|ProcessingModel|string|false|none|Rigid is all or nothing, flexible is best attempt.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_ServiceReservationCreate.1.0.0">ServiceReservationCreate.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaservicereservationcreate.1.0.0"></a>
<a id="schema_ServiceReservationCreate.1.0.0"></a>
<a id="tocSservicereservationcreate.1.0.0"></a>
<a id="tocsservicereservationcreate.1.0.0"></a>

```json
{
  "ComponentIDs": [
    "x0c0s0b0n0"
  ],
  "Partition": [
    "p1"
  ],
  "Group": [
    "group_label"
  ],
  "Type": [
    "string"
  ],
  "State": [
    "Ready"
  ],
  "Flag": [
    "OK"
  ],
  "Enabled": [
    "string"
  ],
  "Softwarestatus": [
    "string"
  ],
  "Role": [
    "Compute"
  ],
  "Subrole": [
    "Worker"
  ],
  "Subtype": [
    "string"
  ],
  "Arch": [
    "X86"
  ],
  "Class": [
    "River"
  ],
  "NID": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "ReservationDuration": 1
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[[XNameForQuery.1.0.0](#schemaxnameforquery.1.0.0)]|false|none|An array of XName/ID values for the components to query.|
|Partition|[string]|false|none|Partition name to filter on, as per current /partitions/names|
|Group|[string]|false|none|Group label to filter on, as per current /groups/labels|
|Type|[string]|false|none|Retrieve all components with the given HMS type.|
|State|[[HMSState.1.0.0](#schemahmsstate.1.0.0)]|false|none|Retrieve all components with the given HMS state.|
|Flag|[[HMSFlag.1.0.0](#schemahmsflag.1.0.0)]|false|none|Retrieve all components with the given HMS flag value.|
|Enabled|[string]|false|none|Retrieve all components with the given enabled status (true or false).|
|Softwarestatus|[string]|false|none|Retrieve all components with the given software status. Software status is a free form string. Matching is case-insensitive.|
|Role|[[HMSRole.1.0.0](#schemahmsrole.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS role|
|Subrole|[[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS subrole|
|Subtype|[string]|false|none|Retrieve all components with the given HMS subtype.|
|Arch|[[HMSArch.1.0.0](#schemahmsarch.1.0.0)]|false|none|Retrieve all components with the given architecture.|
|Class|[[HMSClass.1.0.0](#schemahmsclass.1.0.0)]|false|none|Retrieve all components (i.e. nodes) with the given HMS hardware class. Class can be River, Mountain, etc.|
|NID|[string]|false|none|Retrieve all components (i.e. one node) with the given integer NID|
|ProcessingModel|string|false|none|Rigid is all or nothing, flexible is best attempt.|
|ReservationDuration|integer|false|none|Length of time in minutes for the reservation to be valid for.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_ServiceReservationCreate_Response.1.0.0">ServiceReservationCreate_Response.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaservicereservationcreate_response.1.0.0"></a>
<a id="schema_ServiceReservationCreate_Response.1.0.0"></a>
<a id="tocSservicereservationcreate_response.1.0.0"></a>
<a id="tocsservicereservationcreate_response.1.0.0"></a>

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "string",
      "ReservationKey": "string",
      "ExpirationTime": "2019-08-24T14:15:22Z"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Success|[[XnameKeys.1.0.0](#schemaxnamekeys.1.0.0)]|false|none|none|
|Failure|[[FailedXnames.1.0.0](#schemafailedxnames.1.0.0)]|false|none|none|

<h2 id="tocS_ServiceReservationCheck_Response.1.0.0">ServiceReservationCheck_Response.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaservicereservationcheck_response.1.0.0"></a>
<a id="schema_ServiceReservationCheck_Response.1.0.0"></a>
<a id="tocSservicereservationcheck_response.1.0.0"></a>
<a id="tocsservicereservationcheck_response.1.0.0"></a>

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "string",
      "ExpirationTime": "2019-08-24T14:15:22Z"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Success|[[XnameKeysDeputyExpire.1.0.0](#schemaxnamekeysdeputyexpire.1.0.0)]|false|none|none|
|Failure|[[FailedXnames.1.0.0](#schemafailedxnames.1.0.0)]|false|none|none|

<h2 id="tocS_Xnames">Xnames</h2>
<!-- backwards compatibility -->
<a id="schemaxnames"></a>
<a id="schema_Xnames"></a>
<a id="tocSxnames"></a>
<a id="tocsxnames"></a>

```json
{
  "ComponentIDs": [
    "string"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[string]|false|none|none|

<h2 id="tocS_XnameKeysNoExpire.1.0.0">XnameKeysNoExpire.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamekeysnoexpire.1.0.0"></a>
<a id="schema_XnameKeysNoExpire.1.0.0"></a>
<a id="tocSxnamekeysnoexpire.1.0.0"></a>
<a id="tocsxnamekeysnoexpire.1.0.0"></a>

```json
{
  "ID": "string",
  "DeputyKey": "string",
  "ReservationKey": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|DeputyKey|string|false|none|The key that can be passed to a delegate.|
|ReservationKey|string|false|none|The key that can be used to renew/release the reservation. Should not be delegated or shared.|

<h2 id="tocS_XnameKeys.1.0.0">XnameKeys.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamekeys.1.0.0"></a>
<a id="schema_XnameKeys.1.0.0"></a>
<a id="tocSxnamekeys.1.0.0"></a>
<a id="tocsxnamekeys.1.0.0"></a>

```json
{
  "ID": "string",
  "DeputyKey": "string",
  "ReservationKey": "string",
  "ExpirationTime": "2019-08-24T14:15:22Z"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|DeputyKey|string|false|none|The key that can be passed to a delegate.|
|ReservationKey|string|false|none|The key that can be used to renew/release the reservation. Should not be delegated or shared.|
|ExpirationTime|string(date-time)|false|none|none|

<h2 id="tocS_XnameKeysDeputyExpire.1.0.0">XnameKeysDeputyExpire.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamekeysdeputyexpire.1.0.0"></a>
<a id="schema_XnameKeysDeputyExpire.1.0.0"></a>
<a id="tocSxnamekeysdeputyexpire.1.0.0"></a>
<a id="tocsxnamekeysdeputyexpire.1.0.0"></a>

```json
{
  "ID": "string",
  "DeputyKey": "string",
  "ExpirationTime": "2019-08-24T14:15:22Z"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|DeputyKey|string|false|none|The key that can be passed to a delegate.|
|ExpirationTime|string(date-time)|false|none|none|

<h2 id="tocS_XnameWithKey.1.0.0">XnameWithKey.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamewithkey.1.0.0"></a>
<a id="schema_XnameWithKey.1.0.0"></a>
<a id="tocSxnamewithkey.1.0.0"></a>
<a id="tocsxnamewithkey.1.0.0"></a>

```json
{
  "ID": "string",
  "Key": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|Key|string|false|none|none|

<h2 id="tocS_DeputyKeys.1.0.0">DeputyKeys.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemadeputykeys.1.0.0"></a>
<a id="schema_DeputyKeys.1.0.0"></a>
<a id="tocSdeputykeys.1.0.0"></a>
<a id="tocsdeputykeys.1.0.0"></a>

```json
{
  "DeputyKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|DeputyKeys|[[XnameWithKey.1.0.0](#schemaxnamewithkey.1.0.0)]|false|none|none|

<h2 id="tocS_ReservedKeys.1.0.0">ReservedKeys.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemareservedkeys.1.0.0"></a>
<a id="schema_ReservedKeys.1.0.0"></a>
<a id="tocSreservedkeys.1.0.0"></a>
<a id="tocsreservedkeys.1.0.0"></a>

```json
{
  "ReservationKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ],
  "ProcessingModel": "rigid"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ReservationKeys|[[XnameWithKey.1.0.0](#schemaxnamewithkey.1.0.0)]|false|none|none|
|ProcessingModel|string|false|none|Rigid is all or nothing, flexible is best attempt.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_ReservedKeysWithRenewal.1.0.0">ReservedKeysWithRenewal.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemareservedkeyswithrenewal.1.0.0"></a>
<a id="schema_ReservedKeysWithRenewal.1.0.0"></a>
<a id="tocSreservedkeyswithrenewal.1.0.0"></a>
<a id="tocsreservedkeyswithrenewal.1.0.0"></a>

```json
{
  "ReservationKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ],
  "ProcessingModel": "rigid",
  "ReservationDuration": 1
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ReservationKeys|[[XnameWithKey.1.0.0](#schemaxnamewithkey.1.0.0)]|false|none|none|
|ProcessingModel|string|false|none|Rigid is all or nothing, flexible is best attempt.|
|ReservationDuration|integer|false|none|Length of time in minutes for the reservation to be valid for.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_Counts.1.0.0">Counts.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemacounts.1.0.0"></a>
<a id="schema_Counts.1.0.0"></a>
<a id="tocScounts.1.0.0"></a>
<a id="tocscounts.1.0.0"></a>

```json
{
  "Total": 0,
  "Success": 0,
  "Failure": 0
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Total|integer|false|none|none|
|Success|integer|false|none|none|
|Failure|integer|false|none|none|

<h2 id="tocS_FailedXnames.1.0.0">FailedXnames.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemafailedxnames.1.0.0"></a>
<a id="schema_FailedXnames.1.0.0"></a>
<a id="tocSfailedxnames.1.0.0"></a>
<a id="tocsfailedxnames.1.0.0"></a>

```json
{
  "ID": "string",
  "Reason": "NotFound"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|Reason|string|false|none|The key that can be passed to a delegate.|

#### Enumerated Values

|Property|Value|
|---|---|
|Reason|NotFound|
|Reason|Locked|
|Reason|Disabled|
|Reason|Reserved|
|Reason|ServerError|

<h2 id="tocS_ComponentStatus.1.0.0">ComponentStatus.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemacomponentstatus.1.0.0"></a>
<a id="schema_ComponentStatus.1.0.0"></a>
<a id="tocScomponentstatus.1.0.0"></a>
<a id="tocscomponentstatus.1.0.0"></a>

```json
{
  "ID": "x1001c0s0b0",
  "Locked": false,
  "Reserved": true,
  "CreatedTime": "2019-08-24T14:15:22Z",
  "ExpirationTime": "2019-08-24T14:15:22Z",
  "ReservationDisabled": false
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|Locked|boolean|false|none|none|
|Reserved|boolean|false|none|none|
|CreatedTime|string(date-time)|false|none|none|
|ExpirationTime|string(date-time)|false|none|none|
|ReservationDisabled|boolean|false|none|none|

<h2 id="tocS_XnameResponse_1.0.0">XnameResponse_1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnameresponse_1.0.0"></a>
<a id="schema_XnameResponse_1.0.0"></a>
<a id="tocSxnameresponse_1.0.0"></a>
<a id="tocsxnameresponse_1.0.0"></a>

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}

```

This is a simple CAPMC-like response, intended mainly for non-error messages.  For client errors, we now use RFC7807 responses.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Counts|[Counts.1.0.0](#schemacounts.1.0.0)|false|none|none|
|Success|[Xnames](#schemaxnames)|false|none|none|
|Failure|[[FailedXnames.1.0.0](#schemafailedxnames.1.0.0)]|false|none|none|

<h2 id="tocS_PowerMap.1.0.0_PowerMap">PowerMap.1.0.0_PowerMap</h2>
<!-- backwards compatibility -->
<a id="schemapowermap.1.0.0_powermap"></a>
<a id="schema_PowerMap.1.0.0_PowerMap"></a>
<a id="tocSpowermap.1.0.0_powermap"></a>
<a id="tocspowermap.1.0.0_powermap"></a>

```json
{
  "id": "x0c0s1b0n0",
  "poweredBy": [
    "x0m0p0j10",
    "x0m0p0j11"
  ]
}

```

PowerMaps used to show which components are powered by which power supplies.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|[XName.1.0.0](#schemaxname.1.0.0)|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.|
|poweredBy|[[XNameRW.1.0.0](#schemaxnamerw.1.0.0)]|true|none|A list of components that supply this component with power.|

<h2 id="tocS_PowerMap.1.0.0_PostPowerMap">PowerMap.1.0.0_PostPowerMap</h2>
<!-- backwards compatibility -->
<a id="schemapowermap.1.0.0_postpowermap"></a>
<a id="schema_PowerMap.1.0.0_PostPowerMap"></a>
<a id="tocSpowermap.1.0.0_postpowermap"></a>
<a id="tocspowermap.1.0.0_postpowermap"></a>

```json
{
  "id": "x0c0s1b0n0",
  "poweredBy": [
    "x0m0p0j10",
    "x0m0p0j11"
  ]
}

```

PowerMaps used to show which components are powered by which power supplies.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|[XNameRW.1.0.0](#schemaxnamerw.1.0.0)|true|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is the non-readOnly version for writable component lists.|
|poweredBy|[[XNameRW.1.0.0](#schemaxnamerw.1.0.0)]|true|none|A list of components that supply this component with power.|

<h2 id="tocS_PowerMapArray_PowerMapArray">PowerMapArray_PowerMapArray</h2>
<!-- backwards compatibility -->
<a id="schemapowermaparray_powermaparray"></a>
<a id="schema_PowerMapArray_PowerMapArray"></a>
<a id="tocSpowermaparray_powermaparray"></a>
<a id="tocspowermaparray_powermaparray"></a>

```json
[
  {
    "id": "x0c0s1b0n0",
    "poweredBy": [
      "x0m0p0j10",
      "x0m0p0j11"
    ]
  }
]

```

This is an array of PowerMap objects. This is the result of GET-ing the PowerMaps collection, or can be used to populate or update it as input provided via POST.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[PowerMap.1.0.0_PostPowerMap](#schemapowermap.1.0.0_postpowermap)]|false|none|This is an array of PowerMap objects. This is the result of GET-ing the PowerMaps collection, or can be used to populate or update it as input provided via POST.|

<h2 id="tocS_Values.1.0.0_Values">Values.1.0.0_Values</h2>
<!-- backwards compatibility -->
<a id="schemavalues.1.0.0_values"></a>
<a id="schema_Values.1.0.0_Values"></a>
<a id="tocSvalues.1.0.0_values"></a>
<a id="tocsvalues.1.0.0_values"></a>

```json
null

```

This is a list of parameters and their valid values. These values are valid for various parameters in this API.

### Properties

allOf

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[Values.1.0.0_ArchArray](#schemavalues.1.0.0_archarray)|false|none|This is an array of valid HMSArch values. These values are valid for any 'arch' parameter in this API.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[Values.1.0.0_ClassArray](#schemavalues.1.0.0_classarray)|false|none|This is an array of valid HMSClass values. These values are valid for any 'class' parameter in this API.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[Values.1.0.0_FlagArray](#schemavalues.1.0.0_flagarray)|false|none|This is an array of valid HMSFlag values. These values are valid for any 'flag' parameter in this API.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[Values.1.0.0_NetTypeArray](#schemavalues.1.0.0_nettypearray)|false|none|This is an array of valid NetType values. These values are valid for any 'nettype' parameter in this API.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[Values.1.0.0_RoleArray](#schemavalues.1.0.0_rolearray)|false|none|This is an array of valid HMSRole values. These values are valid for any 'role' parameter in this API.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[Values.1.0.0_SubRoleArray](#schemavalues.1.0.0_subrolearray)|false|none|This is an array of valid HMSSubRole values. These values are valid for any 'subrole' parameter in this API.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[Values.1.0.0_StateArray](#schemavalues.1.0.0_statearray)|false|none|This is an array of valid HMSState values. These values are valid for any 'state' parameter in this API.|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[Values.1.0.0_TypeArray](#schemavalues.1.0.0_typearray)|false|none|This is an array of valid HMSType values. These values are valid for any 'type' parameter in this API.|

<h2 id="tocS_Values.1.0.0_ArchArray">Values.1.0.0_ArchArray</h2>
<!-- backwards compatibility -->
<a id="schemavalues.1.0.0_archarray"></a>
<a id="schema_Values.1.0.0_ArchArray"></a>
<a id="tocSvalues.1.0.0_archarray"></a>
<a id="tocsvalues.1.0.0_archarray"></a>

```json
{
  "Arch": [
    "X86"
  ]
}

```

This is an array of valid HMSArch values. These values are valid for any 'arch' parameter in this API.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Arch|[[HMSArch.1.0.0](#schemahmsarch.1.0.0)]|false|none|[This is the basic architecture of the component so the proper software can be selected and so on.]|

<h2 id="tocS_Values.1.0.0_ClassArray">Values.1.0.0_ClassArray</h2>
<!-- backwards compatibility -->
<a id="schemavalues.1.0.0_classarray"></a>
<a id="schema_Values.1.0.0_ClassArray"></a>
<a id="tocSvalues.1.0.0_classarray"></a>
<a id="tocsvalues.1.0.0_classarray"></a>

```json
{
  "Class": [
    "River"
  ]
}

```

This is an array of valid HMSClass values. These values are valid for any 'class' parameter in this API.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Class|[[HMSClass.1.0.0](#schemahmsclass.1.0.0)]|false|none|[This is the HSM hardware class of the component.]|

<h2 id="tocS_Values.1.0.0_FlagArray">Values.1.0.0_FlagArray</h2>
<!-- backwards compatibility -->
<a id="schemavalues.1.0.0_flagarray"></a>
<a id="schema_Values.1.0.0_FlagArray"></a>
<a id="tocSvalues.1.0.0_flagarray"></a>
<a id="tocsvalues.1.0.0_flagarray"></a>

```json
{
  "Flag": [
    "OK"
  ]
}

```

This is an array of valid HMSFlag values. These values are valid for any 'flag' parameter in this API.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Flag|[[HMSFlag.1.0.0](#schemahmsflag.1.0.0)]|false|none|[This property indicates the state flag of the underlying component.]|

<h2 id="tocS_Values.1.0.0_NetTypeArray">Values.1.0.0_NetTypeArray</h2>
<!-- backwards compatibility -->
<a id="schemavalues.1.0.0_nettypearray"></a>
<a id="schema_Values.1.0.0_NetTypeArray"></a>
<a id="tocSvalues.1.0.0_nettypearray"></a>
<a id="tocsvalues.1.0.0_nettypearray"></a>

```json
{
  "NetType": [
    "Sling"
  ]
}

```

This is an array of valid NetType values. These values are valid for any 'nettype' parameter in this API.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|NetType|[[NetType.1.0.0](#schemanettype.1.0.0)]|false|none|[This is the type of high speed network the component is connected to, if it is an applicable component type and the interface is present, or the type of the system HSN.]|

<h2 id="tocS_Values.1.0.0_RoleArray">Values.1.0.0_RoleArray</h2>
<!-- backwards compatibility -->
<a id="schemavalues.1.0.0_rolearray"></a>
<a id="schema_Values.1.0.0_RoleArray"></a>
<a id="tocSvalues.1.0.0_rolearray"></a>
<a id="tocsvalues.1.0.0_rolearray"></a>

```json
{
  "Role": [
    "Compute"
  ]
}

```

This is an array of valid HMSRole values. These values are valid for any 'role' parameter in this API.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Role|[[HMSRole.1.0.0](#schemahmsrole.1.0.0)]|false|none|[This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.]|

<h2 id="tocS_Values.1.0.0_SubRoleArray">Values.1.0.0_SubRoleArray</h2>
<!-- backwards compatibility -->
<a id="schemavalues.1.0.0_subrolearray"></a>
<a id="schema_Values.1.0.0_SubRoleArray"></a>
<a id="tocSvalues.1.0.0_subrolearray"></a>
<a id="tocsvalues.1.0.0_subrolearray"></a>

```json
{
  "SubRole": [
    "Worker"
  ]
}

```

This is an array of valid HMSSubRole values. These values are valid for any 'subrole' parameter in this API.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|SubRole|[[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)]|false|none|[This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.]|

<h2 id="tocS_Values.1.0.0_StateArray">Values.1.0.0_StateArray</h2>
<!-- backwards compatibility -->
<a id="schemavalues.1.0.0_statearray"></a>
<a id="schema_Values.1.0.0_StateArray"></a>
<a id="tocSvalues.1.0.0_statearray"></a>
<a id="tocsvalues.1.0.0_statearray"></a>

```json
{
  "State": [
    "Ready"
  ]
}

```

This is an array of valid HMSState values. These values are valid for any 'state' parameter in this API.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|State|[[HMSState.1.0.0](#schemahmsstate.1.0.0)]|false|none|[This property indicates the state of the underlying component.]|

<h2 id="tocS_Values.1.0.0_TypeArray">Values.1.0.0_TypeArray</h2>
<!-- backwards compatibility -->
<a id="schemavalues.1.0.0_typearray"></a>
<a id="schema_Values.1.0.0_TypeArray"></a>
<a id="tocSvalues.1.0.0_typearray"></a>
<a id="tocsvalues.1.0.0_typearray"></a>

```json
{
  "Type": [
    "Node"
  ]
}

```

This is an array of valid HMSType values. These values are valid for any 'type' parameter in this API.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Type|[[HMSType.1.0.0](#schemahmstype.1.0.0)]|false|none|[This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.]|

<h2 id="tocS_Actions_1.0.0_ChassisActions">Actions_1.0.0_ChassisActions</h2>
<!-- backwards compatibility -->
<a id="schemaactions_1.0.0_chassisactions"></a>
<a id="schema_Actions_1.0.0_ChassisActions"></a>
<a id="tocSactions_1.0.0_chassisactions"></a>
<a id="tocsactions_1.0.0_chassisactions"></a>

```json
{
  "#Chassis.Reset": {
    "ResetType@Redfish.AllowableValues": [
      "On",
      "ForceOff"
    ],
    "target": "/redfish/v1/Chassis/RackEnclosure/Actions/Chassis.Reset"
  }
}

```

This is a pass-through field from Redfish that lists the available actions for a Chassis component (if any were found, else if it be omitted entirely).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|#Chassis.Reset|object|false|none|none|
|» ResetType@Redfish.AllowableValues|[string]|false|none|List of allowable 'reset' Redfish Action types|
|» target|string|false|none|target URI for Redfish Action|

<h2 id="tocS_Actions_1.0.0_ComputerSystemActions">Actions_1.0.0_ComputerSystemActions</h2>
<!-- backwards compatibility -->
<a id="schemaactions_1.0.0_computersystemactions"></a>
<a id="schema_Actions_1.0.0_ComputerSystemActions"></a>
<a id="tocSactions_1.0.0_computersystemactions"></a>
<a id="tocsactions_1.0.0_computersystemactions"></a>

```json
{
  "#ComputerSystem.Reset": {
    "ResetType@Redfish.AllowableValues": [
      "On",
      "ForceOff",
      "ForceRestart"
    ],
    "target": "/redfish/v1/Systems/System.1/Actions/ComputerSystem.Reset"
  }
}

```

This is a pass-through field from Redfish that lists the available actions for a System component (if any were found, else if it be omitted entirely).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|#ComputerSystem.Reset|object|false|none|none|
|» ResetType@Redfish.AllowableValues|[string]|false|none|List of allowable 'reset' Redfish Action types|
|» target|string|false|none|target URI for Redfish Action|

<h2 id="tocS_Actions_1.0.0_ManagerActions">Actions_1.0.0_ManagerActions</h2>
<!-- backwards compatibility -->
<a id="schemaactions_1.0.0_manageractions"></a>
<a id="schema_Actions_1.0.0_ManagerActions"></a>
<a id="tocSactions_1.0.0_manageractions"></a>
<a id="tocsactions_1.0.0_manageractions"></a>

```json
{
  "#Manager.Reset": {
    "ResetType@Redfish.AllowableValues": [
      "ForceRestart"
    ],
    "target": "/redfish/v1/Managers/BMC/Actions/Manager.Reset"
  }
}

```

This is a pass-through field from Redfish that lists the available actions for a Manager component (if any were found, else if it be omitted entirely).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|#Manager.Reset|object|false|none|none|
|» ResetType@Redfish.AllowableValues|[string]|false|none|List of allowable 'reset' Redfish Action types|
|» target|string|false|none|target URI for Redfish Action|

<h2 id="tocS_Actions_1.0.0_OutletActions">Actions_1.0.0_OutletActions</h2>
<!-- backwards compatibility -->
<a id="schemaactions_1.0.0_outletactions"></a>
<a id="schema_Actions_1.0.0_OutletActions"></a>
<a id="tocSactions_1.0.0_outletactions"></a>
<a id="tocsactions_1.0.0_outletactions"></a>

```json
{
  "#Outlet.PowerControl": {
    "PowerControl@Redfish.AllowableValues": [
      "On"
    ],
    "target": "/redfish/v1/PowerEquipment/RackPDUs/1/Outlets/A1/Outlet.PowerControl"
  },
  "#Outlet.ResetBreaker": {
    "ResetBreaker@Redfish.AllowableValues": [
      "Off"
    ],
    "target": "/redfish/v1/PowerEquipment/RackPDUs/1/Outlets/A1/Outlet.ResetBreaker"
  },
  "#Outlet.ResetStatistics": {
    "ResetStatistics@Redfish.AllowableValues": [
      "string"
    ],
    "target": "/redfish/v1/PowerEquipment/RackPDUs/1/Outlets/A1/Outlet.ResetStatistics"
  }
}

```

This is a pass-through field from Redfish that lists the available actions for a Outlet component (if any were found, else if it be omitted entirely).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|#Outlet.PowerControl|object|false|none|none|
|» PowerControl@Redfish.AllowableValues|[string]|false|none|List of allowable PowerControl Redfish Action types|
|» target|string|false|none|target URI for Redfish Action|
|#Outlet.ResetBreaker|object|false|none|none|
|» ResetBreaker@Redfish.AllowableValues|[string]|false|none|List of allowable ResetBreaker Redfish Action types|
|» target|string|false|none|target URI for Redfish Action|
|#Outlet.ResetStatistics|object|false|none|none|
|» ResetStatistics@Redfish.AllowableValues|[string]|false|none|List of allowable ResetStatistics Redfish Action types|
|» target|string|false|none|target URI for Redfish Action|

<h2 id="tocS_Message_1.0.0_ExtendedInfo">Message_1.0.0_ExtendedInfo</h2>
<!-- backwards compatibility -->
<a id="schemamessage_1.0.0_extendedinfo"></a>
<a id="schema_Message_1.0.0_ExtendedInfo"></a>
<a id="tocSmessage_1.0.0_extendedinfo"></a>
<a id="tocsmessage_1.0.0_extendedinfo"></a>

```json
{
  "ID": "string",
  "Message": "string",
  "Flag": "OK"
}

```

TODO This is a general message scheme meant to replace and generalize old HSS error codes.  Largely TBD placeholder.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|Formal, machine readable, name for message.|
|Message|string|false|none|Human readable description of message.|
|Flag|[HMSFlag.1.0.0](#schemahmsflag.1.0.0)|false|none|This property indicates the state flag of the underlying component.|

<h2 id="tocS_EthernetNICInfo_1.0.0">EthernetNICInfo_1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaethernetnicinfo_1.0.0"></a>
<a id="schema_EthernetNICInfo_1.0.0"></a>
<a id="tocSethernetnicinfo_1.0.0"></a>
<a id="tocsethernetnicinfo_1.0.0"></a>

```json
{
  "RedfishId": 1,
  "@odata.id": "/redfish/v1/{Chassis/Managers/Systems}/{Id}/EthernetInterfaces/1",
  "Description": "Integrated NIC 1",
  "FQDN": "string",
  "Hostname": "string",
  "InterfaceEnabled": true,
  "MACAddress": "ae:12:ce:7a:aa:99",
  "PermanentMACAddress": "ae:12:ce:7a:aa:99"
}

```

This is a summary info for one ordinary Ethernet NIC (i.e. not on HSN). These fields are all passed through from a Redfish EthernetInterface object.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|RedfishId|string|false|read-only|The Redfish 'Id' field for the interface.|
|@odata.id|string|false|read-only|This is the relative path to the EthernetInterface via the Redfish entry point. (i.e. the @odata.id field).|
|Description|string|false|read-only|The Redfish 'Description' field for the interface.|
|FQDN|string|false|read-only|The Redfish 'FQDN' of the interface.  This may or may not be set and is not necessarily the same as the FQDN of the ComponentEndpoint.|
|Hostname|string|false|read-only|The Redfish 'Hostname field' for the interface.  This may or may not be set and is not necessarily the same as the Hostname of the ComponentEndpoint.|
|InterfaceEnabled|boolean|false|read-only|The Redfish 'InterfaceEnabled' field if provided by Redfish, else it will be omitted.|
|MACAddress|string|false|none|The Redfish 'MacAddress' field for the interface.  This should normally be set but is not necessarily the same as the MacAddr of the ComponentEndpoint (as there may be multiple interfaces).|
|PermanentMACAddress|string|false|none|The Redfish 'PermanentMacAddress' field for the interface. This may or may not be set and is not necessarily the same as the MacAddr of the ComponentEndpoint (as there may be multiple interfaces).|

<h2 id="tocS_PowerControl_1.0.0">PowerControl_1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemapowercontrol_1.0.0"></a>
<a id="schema_PowerControl_1.0.0"></a>
<a id="tocSpowercontrol_1.0.0"></a>
<a id="tocspowercontrol_1.0.0"></a>

```json
{
  "Name": "Node Power Control",
  "PowerCapacityWatts": 900,
  "OEM": {
    "Cray": {
      "PowerIdleWatts": 900,
      "PowerLimit": {
        "Min": 350,
        "Max": 850
      },
      "PowerResetWatts": 250
    }
  },
  "RelatedItem": [
    {
      "@odata.id": "/redfish/v1/Chassis/Node0/Power#/PowerControl/Accelerator0"
    }
  ]
}

```

This is the power control info for the node. These fields are all passed through from a Redfish PowerControl object.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|Name of the power control interface.|
|PowerCapacityWatts|number|false|read-only|The total amount of power available to the chassis for allocation. This may the power supply capacity, or power budget assigned to the chassis from an up-stream chassis.|
|OEM|object|false|read-only|This is the manufacturer/provider specific extension moniker used to divide the Oem object into sections.|
|» Cray|object|false|read-only|This is the manufacturer/provider specific extension moniker used to divide the Oem object into sections.|
|»» PowerIdleWatts|number|false|read-only|The total amount of power available to the chassis for allocation. This may the power supply capacity, or power budget assigned to the chassis from an up-stream chassis.|
|»» PowerLimit|object|false|read-only|Power limit status and configuration information for this chassis.|
|»»» Min|number|false|read-only|The minimum allowed value for a PowerLimit's LimitInWatts. This is the estimated lowest value (most restrictive) power cap that can be achieved by the associated PowerControl resource.|
|»»» Max|number|false|read-only|The maximum allowed value for a PowerLimit's LimitInWatts. This is the estimated highest value (least restrictive) power cap that can be achieved by the associated PowerControl resource. Note that the actual maximum allowed LimitInWatts is the lesser of PowerLimit.Max or PowerControl.PowerAllocatedWatts.|
|»» PowerResetWatts|number|false|read-only|Typical power consumption during ComputerSystem.ResetAction "On" operation.|
|RelatedItem|[object]|false|read-only|The ID(s) of the resources associated with this Power Limit.|
|» @odata.id|string|false|read-only|An ID of the resource associated with this Power Limit.|

<h2 id="tocS_FRUId.1.0.0">FRUId.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemafruid.1.0.0"></a>
<a id="schema_FRUId.1.0.0"></a>
<a id="tocSfruid.1.0.0"></a>
<a id="tocsfruid.1.0.0"></a>

```json
"string"

```

Uniquely identifies a piece of hardware by a serial-number like identifier that is globally unique within the hardware inventory,

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|read-only|Uniquely identifies a piece of hardware by a serial-number like identifier that is globally unique within the hardware inventory,|

<h2 id="tocS_HMSArch.1.0.0">HMSArch.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahmsarch.1.0.0"></a>
<a id="schema_HMSArch.1.0.0"></a>
<a id="tocShmsarch.1.0.0"></a>
<a id="tocshmsarch.1.0.0"></a>

```json
"X86"

```

This is the basic architecture of the component so the proper software can be selected and so on.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is the basic architecture of the component so the proper software can be selected and so on.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|X86|
|*anonymous*|ARM|
|*anonymous*|Other|

<h2 id="tocS_HMSClass.1.0.0">HMSClass.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahmsclass.1.0.0"></a>
<a id="schema_HMSClass.1.0.0"></a>
<a id="tocShmsclass.1.0.0"></a>
<a id="tocshmsclass.1.0.0"></a>

```json
"River"

```

This is the HSM hardware class of the component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is the HSM hardware class of the component.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|River|
|*anonymous*|Mountain|
|*anonymous*|Hill|

<h2 id="tocS_HMSFlag.1.0.0">HMSFlag.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahmsflag.1.0.0"></a>
<a id="schema_HMSFlag.1.0.0"></a>
<a id="tocShmsflag.1.0.0"></a>
<a id="tocshmsflag.1.0.0"></a>

```json
"OK"

```

This property indicates the state flag of the underlying component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This property indicates the state flag of the underlying component.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|OK|
|*anonymous*|Warning|
|*anonymous*|Alert|
|*anonymous*|Locked|

<h2 id="tocS_HMSRole.1.0.0">HMSRole.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahmsrole.1.0.0"></a>
<a id="schema_HMSRole.1.0.0"></a>
<a id="tocShmsrole.1.0.0"></a>
<a id="tocshmsrole.1.0.0"></a>

```json
"Compute"

```

This is a possibly reconfigurable role for a component, especially a node. Valid values are:
- Compute
- Service
- System
- Application
- Storage
- Management
Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|

<h2 id="tocS_HMSSubRole.1.0.0">HMSSubRole.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahmssubrole.1.0.0"></a>
<a id="schema_HMSSubRole.1.0.0"></a>
<a id="tocShmssubrole.1.0.0"></a>
<a id="tocshmssubrole.1.0.0"></a>

```json
"Worker"

```

This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:
- Master
- Worker
- Storage
Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/subrole' for the complete list.|

<h2 id="tocS_HMSState.1.0.0">HMSState.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahmsstate.1.0.0"></a>
<a id="schema_HMSState.1.0.0"></a>
<a id="tocShmsstate.1.0.0"></a>
<a id="tocshmsstate.1.0.0"></a>

```json
"Ready"

```

This property indicates the state of the underlying component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This property indicates the state of the underlying component.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|Unknown|
|*anonymous*|Empty|
|*anonymous*|Populated|
|*anonymous*|Off|
|*anonymous*|On|
|*anonymous*|Standby|
|*anonymous*|Halt|
|*anonymous*|Ready|

<h2 id="tocS_HMSType.1.0.0">HMSType.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahmstype.1.0.0"></a>
<a id="schema_HMSType.1.0.0"></a>
<a id="tocShmstype.1.0.0"></a>
<a id="tocshmstype.1.0.0"></a>

```json
"Node"

```

This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|read-only|This is the HMS component type category.  It has a particular xname format and represents the kind of component that can occupy that location.  Not to be confused with RedfishType which is Redfish specific and only used when providing Redfish endpoint data from discovery.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|CDU|
|*anonymous*|CabinetCDU|
|*anonymous*|CabinetPDU|
|*anonymous*|CabinetPDUOutlet|
|*anonymous*|CabinetPDUPowerConnector|
|*anonymous*|CabinetPDUController|
|*anonymous*|Cabinet|
|*anonymous*|Chassis|
|*anonymous*|ChassisBMC|
|*anonymous*|CMMRectifier|
|*anonymous*|CMMFpga|
|*anonymous*|CEC|
|*anonymous*|ComputeModule|
|*anonymous*|RouterModule|
|*anonymous*|NodeBMC|
|*anonymous*|NodeEnclosure|
|*anonymous*|NodeEnclosurePowerSupply|
|*anonymous*|HSNBoard|
|*anonymous*|MgmtSwitch|
|*anonymous*|MgmtHLSwitch|
|*anonymous*|CDUMgmtSwitch|
|*anonymous*|Node|
|*anonymous*|Processor|
|*anonymous*|Drive|
|*anonymous*|StorageGroup|
|*anonymous*|NodeNIC|
|*anonymous*|Memory|
|*anonymous*|NodeAccel|
|*anonymous*|NodeAccelRiser|
|*anonymous*|NodeFpga|
|*anonymous*|HSNAsic|
|*anonymous*|RouterFpga|
|*anonymous*|RouterBMC|
|*anonymous*|HSNLink|
|*anonymous*|HSNConnector|
|*anonymous*|INVALID|

<h2 id="tocS_NetType.1.0.0">NetType.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemanettype.1.0.0"></a>
<a id="schema_NetType.1.0.0"></a>
<a id="tocSnettype.1.0.0"></a>
<a id="tocsnettype.1.0.0"></a>

```json
"Sling"

```

This is the type of high speed network the component is connected to, if it is an applicable component type and the interface is present, or the type of the system HSN.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is the type of high speed network the component is connected to, if it is an applicable component type and the interface is present, or the type of the system HSN.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|Sling|
|*anonymous*|Infiniband|
|*anonymous*|Ethernet|
|*anonymous*|OEM|
|*anonymous*|None|

<h2 id="tocS_NIDRange.1.0.0">NIDRange.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemanidrange.1.0.0"></a>
<a id="schema_NIDRange.1.0.0"></a>
<a id="tocSnidrange.1.0.0"></a>
<a id="tocsnidrange.1.0.0"></a>

```json
"0-24"

```

NID range values to query matching components, e.g. "0-24".  Supply only a single range, more can be given in an array of these values.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|NID range values to query matching components, e.g. "0-24".  Supply only a single range, more can be given in an array of these values.|

<h2 id="tocS_NICAddrs.1.0.0">NICAddrs.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemanicaddrs.1.0.0"></a>
<a id="schema_NICAddrs.1.0.0"></a>
<a id="tocSnicaddrs.1.0.0"></a>
<a id="tocsnicaddrs.1.0.0"></a>

```json
[
  2313746,
  11484946
]

```

A collection of HSN NIC addresses in string form.

### Properties

*None*

<h2 id="tocS_OdataID.1.0.0">OdataID.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaodataid.1.0.0"></a>
<a id="schema_OdataID.1.0.0"></a>
<a id="tocSodataid.1.0.0"></a>
<a id="tocsodataid.1.0.0"></a>

```json
"/redfish/v1/Systems/System.Embedded.1"

```

This is the path (relative to a Redfish endpoint) of a particular Redfish resource, e.g. /Redfish/v1/Systems/System.Embedded.1

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|read-only|This is the path (relative to a Redfish endpoint) of a particular Redfish resource, e.g. /Redfish/v1/Systems/System.Embedded.1|

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

<h2 id="tocS_RedfishType.1.0.0">RedfishType.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaredfishtype.1.0.0"></a>
<a id="schema_RedfishType.1.0.0"></a>
<a id="tocSredfishtype.1.0.0"></a>
<a id="tocsredfishtype.1.0.0"></a>

```json
"ComputerSystem"

```

This is the Redfish object type, not to be confused with the HMS component type.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|read-only|This is the Redfish object type, not to be confused with the HMS component type.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|Chassis|
|*anonymous*|ComputerSystem|
|*anonymous*|EthernetInterface|
|*anonymous*|Manager|
|*anonymous*|Memory|
|*anonymous*|Processor|
|*anonymous*|Drive|
|*anonymous*|PowerSupply|
|*anonymous*|AccountService|
|*anonymous*|EventService|
|*anonymous*|LogService|
|*anonymous*|SessionService|
|*anonymous*|TaskService|
|*anonymous*|UpdateService|

<h2 id="tocS_RedfishSubtype.1.0.0">RedfishSubtype.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaredfishsubtype.1.0.0"></a>
<a id="schema_RedfishSubtype.1.0.0"></a>
<a id="tocSredfishsubtype.1.0.0"></a>
<a id="tocsredfishsubtype.1.0.0"></a>

```json
"Physical"

```

This is the type corresponding to the Redfish object type, i.e. the ChassisType field, SystemType, ManagerType fields.  We only use these three types to create ComponentEndpoints for now.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|read-only|This is the type corresponding to the Redfish object type, i.e. the ChassisType field, SystemType, ManagerType fields.  We only use these three types to create ComponentEndpoints for now.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|Rack|
|*anonymous*|Blade|
|*anonymous*|Enclosure|
|*anonymous*|StandAlone|
|*anonymous*|RackMount|
|*anonymous*|Card|
|*anonymous*|Cartridge|
|*anonymous*|Row|
|*anonymous*|Pod|
|*anonymous*|Expansion|
|*anonymous*|Sidecar|
|*anonymous*|Zone|
|*anonymous*|Sled|
|*anonymous*|Shelf|
|*anonymous*|Drawer|
|*anonymous*|Module|
|*anonymous*|Component|
|*anonymous*|Other|
|*anonymous*|Physical|
|*anonymous*|Virtual|
|*anonymous*|OS|
|*anonymous*|PhysicallyPartitioned|
|*anonymous*|VirtuallyPartitioned|
|*anonymous*|ManagementController|
|*anonymous*|EnclosureManager|
|*anonymous*|BMC|
|*anonymous*|RackManager|
|*anonymous*|AuxiliaryController|

<h2 id="tocS_ResourceName">ResourceName</h2>
<!-- backwards compatibility -->
<a id="schemaresourcename"></a>
<a id="schema_ResourceName"></a>
<a id="tocSresourcename"></a>
<a id="tocsresourcename"></a>

```json
"resource_name1"

```

Acceptable format for certain user-requested string identifiers.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Acceptable format for certain user-requested string identifiers.|

<h2 id="tocS_ResourceURI.1.0.0">ResourceURI.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaresourceuri.1.0.0"></a>
<a id="schema_ResourceURI.1.0.0"></a>
<a id="tocSresourceuri.1.0.0"></a>
<a id="tocsresourceuri.1.0.0"></a>

```json
{
  "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
}

```

A ResourceURI is like an odata.id, it provides a path to a resource from the API root, such that when a GET is performed, the corresponding object is returned.  It does not imply other odata functionality.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ResourceURI|string|false|none|none|

<h2 id="tocS_ResourceURICollection_ResourceURICollection">ResourceURICollection_ResourceURICollection</h2>
<!-- backwards compatibility -->
<a id="schemaresourceuricollection_resourceuricollection"></a>
<a id="schema_ResourceURICollection_ResourceURICollection"></a>
<a id="tocSresourceuricollection_resourceuricollection"></a>
<a id="tocsresourceuricollection_resourceuricollection"></a>

```json
{
  "Name": "(Type of Object) Collection",
  "Members": [
    {
      "ResourceURI": "/hsm/v2/API_TYPE/OBJECT_TYPE/OBJECT_ID"
    }
  ],
  "MemberCount": 0
}

```

A ResourceURI is like an odata.id, it provides a path to a resource from the API root, such that when a GET is performed, the corresponding object is returned.  It does not imply other odata functionality.  This is a collection of such IDs, of a single base type, grouped together for some purpose.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|false|read-only|Should describe the collection, though the type of resources the links correspond to should also be inferred from the context in which the collection was obtained.|
|Members|[[ResourceURI.1.0.0](#schemaresourceuri.1.0.0)]|false|read-only|An array of ResourceIds.|
|MemberCount|number(int32)|false|read-only|Number of ResourceURIs in the collection|

<h2 id="tocS_Response_1.0.0">Response_1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaresponse_1.0.0"></a>
<a id="schema_Response_1.0.0"></a>
<a id="tocSresponse_1.0.0"></a>
<a id="tocsresponse_1.0.0"></a>

```json
{
  "code": "string",
  "message": "string"
}

```

This is a simple CAPMC-like response, intended mainly for non-error messages.  For client errors, we now use RFC7807 responses.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|code|string|true|none|none|
|message|string|true|none|none|

<h2 id="tocS_UUID.1.0.0">UUID.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemauuid.1.0.0"></a>
<a id="schema_UUID.1.0.0"></a>
<a id="tocSuuid.1.0.0"></a>
<a id="tocsuuid.1.0.0"></a>

```json
"bf9362ad-b29c-40ed-9881-18a5dba3a26b"

```

This is a universally unique identifier i.e. UUID in the canonical format provided by Redfish to identify endpoints and services. If this is the UUID of a RedfishEndpoint, it should be the UUID broadcast by SSDP, if applicable.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|read-only|This is a universally unique identifier i.e. UUID in the canonical format provided by Redfish to identify endpoints and services. If this is the UUID of a RedfishEndpoint, it should be the UUID broadcast by SSDP, if applicable.|

<h2 id="tocS_XName.1.0.0">XName.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxname.1.0.0"></a>
<a id="schema_XName.1.0.0"></a>
<a id="tocSxname.1.0.0"></a>
<a id="tocsxname.1.0.0"></a>

```json
"x0c0s0b0n0"

```

Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|read-only|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType.|

<h2 id="tocS_XNameRW.1.0.0">XNameRW.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamerw.1.0.0"></a>
<a id="schema_XNameRW.1.0.0"></a>
<a id="tocSxnamerw.1.0.0"></a>
<a id="tocsxnamerw.1.0.0"></a>

```json
"x0c0s1b0n0"

```

Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is the non-readOnly version for writable component lists.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is the non-readOnly version for writable component lists.|

<h2 id="tocS_XNameRFEndpoint.1.0.0">XNameRFEndpoint.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamerfendpoint.1.0.0"></a>
<a id="schema_XNameRFEndpoint.1.0.0"></a>
<a id="tocSxnamerfendpoint.1.0.0"></a>
<a id="tocsxnamerfendpoint.1.0.0"></a>

```json
"x0c0s0b0"

```

Uniquely identifies the component by its physical location (xname). This is identical to a normal XName, but specifies a case where a BMC or other controller type is expected.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Uniquely identifies the component by its physical location (xname). This is identical to a normal XName, but specifies a case where a BMC or other controller type is expected.|

<h2 id="tocS_XNameForQuery.1.0.0">XNameForQuery.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnameforquery.1.0.0"></a>
<a id="schema_XNameForQuery.1.0.0"></a>
<a id="tocSxnameforquery.1.0.0"></a>
<a id="tocsxnameforquery.1.0.0"></a>

```json
"x0c0s0b0n0"

```

Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is identical to XName except that it is not read-only which would prevent it from being a required parameter in query operations in Swagger 2.0.  These operations do not actually write the XName, merely using at a selector to do bulk writes of multiple records, so this is fine.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Uniquely identifies the component by its physical location (xname). There are formatting rules depending on the matching HMSType. This is identical to XName except that it is not read-only which would prevent it from being a required parameter in query operations in Swagger 2.0.  These operations do not actually write the XName, merely using at a selector to do bulk writes of multiple records, so this is fine.|

<h2 id="tocS_XNamePartition.1.0.0">XNamePartition.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamepartition.1.0.0"></a>
<a id="schema_XNamePartition.1.0.0"></a>
<a id="tocSxnamepartition.1.0.0"></a>
<a id="tocsxnamepartition.1.0.0"></a>

```json
"p1.2"

```

This is an ordinary xname, but one where only a partition (hard:soft) or the system alias (s0) will be expected as valid input.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is an ordinary xname, but one where only a partition (hard:soft) or the system alias (s0) will be expected as valid input.|

<h2 id="tocS_XNameCompOrPartition.1.0.0">XNameCompOrPartition.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamecomporpartition.1.0.0"></a>
<a id="schema_XNameCompOrPartition.1.0.0"></a>
<a id="tocSxnamecomporpartition.1.0.0"></a>
<a id="tocsxnamecomporpartition.1.0.0"></a>

```json
"s0"

```

This is an ordinary xname, but one where only a partition (hard:soft) or the system alias (s0) will be expected as valid input, or else a parent component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is an ordinary xname, but one where only a partition (hard:soft) or the system alias (s0) will be expected as valid input, or else a parent component.|

