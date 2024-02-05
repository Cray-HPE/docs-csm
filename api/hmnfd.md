<!-- Generator: Widdershins v4.0.1 -->

<h1 id="hms-notification-fanout-daemon">HMS Notification Fanout Daemon v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

Nodes like compute nodes or user access nodes may want to be notified when other nodes or components in the system change state. For example, in a booted system, a node may be in tight communication with other nodes in the system and need to be notified when any of those nodes go away.
The HMS Notification Fanout Daemon (HMNFD) provides the Hardware State Manager with the capability of fanning out state change notifications to subscribing compute nodes. HMNFD provides the ability to notify subscribers of component hardware state changes and other changes made to and by the Hardware State Manager.
To receive notifications, a compute node must have an http or https based HMNFD API endpoint service running. This is where the State Change Notifications will be sent when they occur. HMNFD works with the Hardware State Manager and distributes state changes and manages subscriptions.

The REST API provides the following functions:
* Subscription for component state changes:
    * Hardware state (On, Off, Ready, Standby, Halt etc.)
    * Logical state (arbitrary like AdminDown, Other)
    * Role (Compute, Management, Application etc.)
    * Enabled state
    * Flag (OK, Alert, Warning, etc.)

* View current subscriptions
* Delete subscriptions
* Retrieve and modify current service operating parameters
* Create state change notifications for distribution to subscribers
## Deprecation Notice: V1 of the HMS service has been deprecated as of CSM version 1.2.0.  The V1 HMNFD API’s will be removed in the CSM version 1.5 release. All consumers of the V1 HMNFD API interface will need to move to the V2 interface prior to the CSM 1.5 release.
## Resources
### /subscriptions
Manage and view subscriptions to notifications. This resource is generally  used by compute nodes.
### /scn
State change notification messages sent from Hardware State Manager to HMNFD; the same format is used for notifications sent by HMNFD to subscribers. This resource applies only to the HSM.
### /params
Retrieve or update configurable parameters.
### /health
Retrieve health information for the service and its dependencies.
## Workflows
### Manage SCN Subscriptions
#### GET /subscriptions
Retrieve and view current subscriptions.
#### POST /subscriptions/{xname}/agents/{agent}
A node will subscribe to whatever state change notifications (SCNs) it wants to receive. Thus, the node needs to have a service running to which HMNFD can send, via REST, the subscribed-to SCNs. A URL that tells where to send the SCNs is provided as part of the request body schema. Once a subscribed-to SCN occurs, NFD sends it to the node's service via a REST call to the URL supplied during the subscribe operation.  The {xname} and {agent} segments of the URL state which node and which agent on that node are doing the subscribing.  The subscription request info is in the body of the PUT  payload.
#### PATCH /subscriptions/{xname}/agents/{agent}
Modify an existing SCN subscription.  Component list, component states, etc. can be modified with this request, which will remain associated with the component and software agent specified in the URL.
#### DELETE /subscriptions/{xname}/agents
Delete all subscriptions that are not needed on a given node.
#### DELETE /subscriptions/{xname}/agents/{agent}
Delete a specific subscription on a given node.
### Update Service Configurable Parameters
#### GET /params
Fetch a JSON-formatted list of current configurable parameters.
#### PATCH /params
Change the value of one or more configurable parameters.
 

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2">https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2</a>

* <a href="http://cray-hmnfd/hmi/v2">http://cray-hmnfd/hmi/v2</a>

<h1 id="hms-notification-fanout-daemon-subscriptions">subscriptions</h1>

Used for managing State Change Notification subscriptions

## doGetSubscriptionInfo

<a id="opIddoGetSubscriptionInfo"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /subscriptions`

*Retrieve currently-held state change notification subscriptions*

Retrieve all information on currently held State Change Notification subscriptions.

> Example responses

> 200 Response

```json
{
  "SubscriptionList": [
    {
      "Components": [
        "x0c1s2b0n3"
      ],
      "Subscriber": "scnHandler@x1000c1s2b0n3",
      "SubscriberComponent": "x1000c1s2b0n3",
      "SubscriberAgent": "scnHandler",
      "Enabled": "true",
      "Roles": [
        "Compute"
      ],
      "SoftwareStatus": [
        "AdminDown"
      ],
      "States": [
        "Ready"
      ],
      "Url": "https://x0c1s2b0n3.cray.com:8080/scns"
    }
  ]
}
```

<h3 id="dogetsubscriptioninfo-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success.  Currently held subscriptions are returned.|[SubscriptionListArray](#schemasubscriptionlistarray)|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized.  RBAC prevented operation from executing, or authentication token has expired.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist. Endpoint not available.|[Problem7807](#schemaproblem7807)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /subscriptions, only GET operations are allowed.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doGetSubscriptionInfoXName

<a id="opIddoGetSubscriptionInfoXName"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /subscriptions/{xname}`

*Retrieve currently-held state change notification subscriptions for a given component*

Retrieve currently held State Change Notification subscriptions for a component.

<h3 id="dogetsubscriptioninfoxname-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|[XName.1.0.0](#schemaxname.1.0.0)|true|none|

> Example responses

> 200 Response

```json
{
  "SubscriptionList": [
    {
      "Components": [
        "x0c1s2b0n3"
      ],
      "Subscriber": "scnHandler@x1000c1s2b0n3",
      "SubscriberComponent": "x1000c1s2b0n3",
      "SubscriberAgent": "scnHandler",
      "Enabled": "true",
      "Roles": [
        "Compute"
      ],
      "SoftwareStatus": [
        "AdminDown"
      ],
      "States": [
        "Ready"
      ],
      "Url": "https://x0c1s2b0n3.cray.com:8080/scns"
    }
  ]
}
```

<h3 id="dogetsubscriptioninfoxname-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success.  Currently held subscriptions are returned.|[SubscriptionListArray](#schemasubscriptionlistarray)|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized.  RBAC prevented operation from executing, or authentication token has expired.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist. Endpoint not available.|[Problem7807](#schemaproblem7807)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /subscriptions, only GET operations are allowed.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doSubscriptionDeleteXName

<a id="opIddoSubscriptionDeleteXName"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /subscriptions/{xname}/agents`

*Delete all state change notification subscriptions for a component*

Delete all state change notification subscriptions for a component.

<h3 id="dosubscriptiondeletexname-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|[XName.1.0.0](#schemaxname.1.0.0)|true|none|

> Example responses

> 401 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="dosubscriptiondeletexname-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized. RBAC prevented operation from executing, or authentication token has expired.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist.  Endpoint not available.|[Problem7807](#schemaproblem7807)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  Only DELETE operations are allowed.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doSubscriptionPOSTV2

<a id="opIddoSubscriptionPOSTV2"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent}', headers = headers)

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /subscriptions/{xname}/agents/{agent}`

*Subscribe to a state change notification*

Subscribe to state change notifications for a set of components. Once this is done, the subscribing components will receive these notifications as they occur, using the URL specified at subscription time.  The XName of the subscribing component as well as the software agent doing the subscribing are specified in the URL path.

> Body parameter

```json
{
  "Components": [
    "x0c1s2b0n3"
  ],
  "Enabled": "true",
  "Roles": [
    "Compute"
  ],
  "SoftwareStatus": [
    "AdminDown"
  ],
  "States": [
    "Ready"
  ],
  "Url": "https://x0c1s2b0n3.cray.com:8080/scns"
}
```

<h3 id="dosubscriptionpostv2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[SubscribePostV2](#schemasubscribepostv2)|true|none|
|xname|path|string|true|The XName of the subscribing component (typically a node)|
|agent|path|string|true|The software agent running on the subscribing component|

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

<h3 id="dosubscriptionpostv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request.  Malformed JSON.  Verify all JSON formatting in payload, and that all xnames are properly formatted.|[Problem7807](#schemaproblem7807)|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized. RBAC prevented operation from executing, or authentication token has expired.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist.  Endpoint not available.|[Problem7807](#schemaproblem7807)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  Only PATCH and DELETE operations are allowed.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doSubscriptionPATCHV2

<a id="opIddoSubscriptionPATCHV2"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent}', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /subscriptions/{xname}/agents/{agent}`

*Modify a subscription to state change notifications*

Modify an existing subscription to state change notifications for a  component and software agent.  The XName of the subscribing component  as well as the software agent doing the subscribing are specified in  the URL path.

> Body parameter

```json
{
  "Components": [
    "x0c1s2b0n3"
  ],
  "Enabled": "true",
  "Roles": [
    "Compute"
  ],
  "SoftwareStatus": [
    "AdminDown"
  ],
  "States": [
    "Ready"
  ],
  "Url": "https://x0c1s2b0n3.cray.com:8080/scns"
}
```

<h3 id="dosubscriptionpatchv2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[SubscribePostV2](#schemasubscribepostv2)|true|none|
|xname|path|string|true|The XName of the subscribing component (typically a node)|
|agent|path|string|true|The software agent running on the subscribing component|

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

<h3 id="dosubscriptionpatchv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request.  Malformed JSON.  Verify all JSON formatting in payload, and that all xnames are properly formatted.|[Problem7807](#schemaproblem7807)|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized. RBAC prevented operation from executing, or authentication token has expired.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist.  Endpoint not available.|[Problem7807](#schemaproblem7807)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  Only POST, PATCH and DELETE operations are allowed.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doSubscriptionDeleteXNameAgentV2

<a id="opIddoSubscriptionDeleteXNameAgentV2"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions/{xname}/agents/{agent}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /subscriptions/{xname}/agents/{agent}`

*Delete a specific state change notification subscription*

Delete a specific state change notification subscription associated  with a target component and a target software agent.  The XName of the subscribing component as well as the software agent on the subscribing  component are specified in the URL path.

<h3 id="dosubscriptiondeletexnameagentv2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|string|true|The XName of the subscribing component (typically a node)|
|agent|path|string|true|The software agent running on the subscribing component|

> Example responses

> 401 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="dosubscriptiondeletexnameagentv2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Success.|None|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized. RBAC prevented operation from executing, or authentication token has expired.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist.  Endpoint not available.|[Problem7807](#schemaproblem7807)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  Only PUT and DELETE operations are allowed.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hms-notification-fanout-daemon-scn">scn</h1>

State change notification messages sent from Hardware State Manager to HMNFD; the same format is used for notifications sent by HMNFD to subscribers.

## doSCN

<a id="opIddoSCN"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/scn HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/scn \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/scn', headers = headers)

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/scn", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /scn`

*Send a state change notification*

Send a state change notification for fanout to subscribers. This is the API endpoint for Hardware State Manager through which to send state change notifications.

> Body parameter

```json
{
  "Components": [
    "x0c1s2b0n3"
  ],
  "Enabled": "true",
  "Role": "Compute",
  "SoftwareStatus": "AdminDown",
  "State": "Ready"
}
```

<h3 id="doscn-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[StateChanges](#schemastatechanges)|true|none|

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

<h3 id="doscn-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request.  Malformed JSON.  Verify all JSON formatting in payload.|[Problem7807](#schemaproblem7807)|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized.  RBAC prevented operation from executing, or authentication token has expired.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist.  Endpoint not available.|[Problem7807](#schemaproblem7807)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /scn, only POST operations are allowed.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hms-notification-fanout-daemon-params">params</h1>

## doParamsGet

<a id="opIddoParamsGet"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/params HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/params \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/params', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/params", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /params`

*Retrieve service configurable parameters*

Retrieve a JSON-formatted list of current configurable parameters.

> Example responses

> 200 Response

```json
{
  "Debug": 0,
  "KV_url": "http://localhost:2379",
  "Nosm": 1,
  "Port": 27000,
  "Scn_cache_delay": 5,
  "Scn_max_cache": 100,
  "SM_retries": 3,
  "SM_timeout": 5,
  "SM_url": "https://localhost:27999/hsms/v1",
  "Telemetry_host": "kafka.sma.svc.cluster.local:9092:state_change_notifications",
  "Use_telemetry": 1
}
```

<h3 id="doparamsget-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success.  Current configurable parameter values are returned.|[parameters](#schemaparameters)|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized.  RBAC prevented operation from executing, or authentication token has expired.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist.  Endpoint not available.|[Problem7807](#schemaproblem7807)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /params, only GET and PATCH operations are allowed.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## doParamsPatch

<a id="opIddoParamsPatch"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/params HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/params \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/params', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/params", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /params`

*Update service configurable parameters*

Change the value of one or more configurable parameters.

> Body parameter

```json
{
  "Debug": 0,
  "KV_url": "http://localhost:2379",
  "Nosm": 1,
  "Port": 27000,
  "Scn_cache_delay": 5,
  "Scn_max_cache": 100,
  "SM_retries": 3,
  "SM_timeout": 5,
  "SM_url": "https://localhost:27999/hsms/v1",
  "Telemetry_host": "kafka.sma.svc.cluster.local:9092:state_change_notifications",
  "Use_telemetry": 1
}
```

<h3 id="doparamspatch-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[parameters](#schemaparameters)|true|none|

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

<h3 id="doparamspatch-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request.  Malformed JSON.  Verify all JSON formatting in payload.|[Problem7807](#schemaproblem7807)|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized.  RBAC prevented operation from executing, or authentication token has expired.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist.  Endpoint not available.|[Problem7807](#schemaproblem7807)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /params, only GET and PATCH operations are allowed.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|[Problem7807](#schemaproblem7807)|
|default|Default|Unexpected error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="hms-notification-fanout-daemon-health">health</h1>

## get__health

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/health HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/health \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/health', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/health", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /health`

*Query the health of the service*

The `health` resource returns health information about the HMNFD service and its dependencies.  This actively checks the connection between  HMNFD and the following:

  * KV Store
  * Message Bus
  * Worker Pool

This is primarily intended as a diagnostic tool to investigate the functioning of the HMNFD service.

> Example responses

> 200 Response

```json
{
  "KvStore": "KV Store not initialized",
  "MsgBus": "Connected and OPEN",
  "HsmSubscriptions": "HSM Subscription key not present",
  "PruneMap": "Number of items:10",
  "WorkerPool": "Workers:5, Jobs:15"
}
```

<h3 id="get__health-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|Inline|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /health, only GET operations are allowed.|[Problem7807](#schemaproblem7807)|

<h3 id="get__health-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» KvStore|string|true|none|Status of the KV Store.|
|» MsgBus|string|true|none|Status of the connection with the message bus.|
|» HsmSubscriptions|string|true|none|Status of the subscriptions to the Hardware State Manager (HSM).  Any error reported by an attempt to access the HSM subscriptions will be included here.|
|» PruneMap|string|true|none|Status of the list of subscriptions to be pruned.|
|» WorkerPool|string|true|none|Status of the worker pool servicing the notifications.|

<aside class="success">
This operation does not require authentication
</aside>

## get__liveness

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/liveness HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/liveness \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/liveness', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/liveness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /liveness`

*Kubernetes liveness endpoint to monitor service health*

The `liveness` resource works in conjunction with the Kubernetes liveness probe to determine when the service is no longer responding to requests.  Too many failures of the liveness probe will result in the service being shut down and restarted.  

This is primarily an endpoint for the automated Kubernetes system.

> Example responses

> 405 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="get__liveness-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /liveness, only GET operations are allowed.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__readiness

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/readiness HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/readiness \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/readiness', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/readiness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /readiness`

*Kubernetes readiness endpoint to monitor service health*

The `readiness` resource works in conjunction with the Kubernetes readiness probe to determine when the service is no longer healthy and able to respond correctly to requests.  Too many failures of the readiness probe will result in the traffic being routed away from this service and eventually the service will be shut down and restarted if in an unready state for too long.

This is primarily an endpoint for the automated Kubernetes system.

> Example responses

> 405 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="get__readiness-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /readiness, only GET operations are allowed.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_SubscribePost">SubscribePost</h2>
<!-- backwards compatibility -->
<a id="schemasubscribepost"></a>
<a id="schema_SubscribePost"></a>
<a id="tocSsubscribepost"></a>
<a id="tocssubscribepost"></a>

```json
{
  "Components": [
    "x0c1s2b0n3"
  ],
  "Subscriber": "scnHandler@x1000c1s2b0n3",
  "SubscriberComponent": "x1000c1s2b0n3",
  "SubscriberAgent": "scnHandler",
  "Enabled": "true",
  "Roles": [
    "Compute"
  ],
  "SoftwareStatus": [
    "AdminDown"
  ],
  "States": [
    "Ready"
  ],
  "Url": "https://x0c1s2b0n3.cray.com:8080/scns"
}

```

State Change Notification Subscription Message Payload

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Components|[[XName.1.0.0](#schemaxname.1.0.0)]|false|none|This is a list of components to associate with a State Change Notification.|
|Subscriber|string|false|none|This is the xname of the subscriber. It can have an optional service name.  Note that this is only used for backward compatibility with the V1 API, and is not actually used.|
|SubscriberComponent|string|false|none|This is the xname of the subscriber.|
|SubscriberAgent|string|false|none|This is the name of the subscribing software agent.|
|Enabled|boolean|false|none|If true, subscribe to changes to the Enabled status of a component.|
|Roles|[[Roles.1.0.0](#schemaroles.1.0.0)]|false|none|Node role change to subscribe for|
|SoftwareStatus|[[SoftwareStatus.1.0.0](#schemasoftwarestatus.1.0.0)]|false|none|Logical status associated with a component|
|States|[[HMSState.1.0.0](#schemahmsstate.1.0.0)]|false|none|List of states to subscribe for|
|Url|string|false|none|URL to send State Change Notifications to|

<h2 id="tocS_SubscribePostV2">SubscribePostV2</h2>
<!-- backwards compatibility -->
<a id="schemasubscribepostv2"></a>
<a id="schema_SubscribePostV2"></a>
<a id="tocSsubscribepostv2"></a>
<a id="tocssubscribepostv2"></a>

```json
{
  "Components": [
    "x0c1s2b0n3"
  ],
  "Enabled": "true",
  "Roles": [
    "Compute"
  ],
  "SoftwareStatus": [
    "AdminDown"
  ],
  "States": [
    "Ready"
  ],
  "Url": "https://x0c1s2b0n3.cray.com:8080/scns"
}

```

State Change Notification Subscription Message Payload

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Components|[[XName.1.0.0](#schemaxname.1.0.0)]|false|none|This is a list of components to associate with a State Change Notification.|
|Enabled|boolean|false|none|If true, subscribe to changes to the Enabled status of a component.|
|Roles|[[Roles.1.0.0](#schemaroles.1.0.0)]|false|none|Node role change to subscribe for|
|SoftwareStatus|[[SoftwareStatus.1.0.0](#schemasoftwarestatus.1.0.0)]|false|none|Logical status associated with a component|
|States|[[HMSState.1.0.0](#schemahmsstate.1.0.0)]|false|none|List of states to subscribe for|
|Url|string|false|none|URL to send State Change Notifications to|

<h2 id="tocS_parameters">parameters</h2>
<!-- backwards compatibility -->
<a id="schemaparameters"></a>
<a id="schema_parameters"></a>
<a id="tocSparameters"></a>
<a id="tocsparameters"></a>

```json
{
  "Debug": 0,
  "KV_url": "http://localhost:2379",
  "Nosm": 1,
  "Port": 27000,
  "Scn_cache_delay": 5,
  "Scn_max_cache": 100,
  "SM_retries": 3,
  "SM_timeout": 5,
  "SM_url": "https://localhost:27999/hsms/v1",
  "Telemetry_host": "kafka.sma.svc.cluster.local:9092:state_change_notifications",
  "Use_telemetry": 1
}

```

Configurable Parameters Message Payload

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Debug|integer|false|none|This is the debug level of the heartbeat service. It increases the verbosity of the logging.|
|KV_url|string|false|none|ETCD Key-Value store URL|
|Nosm|integer|false|none|Do not contact Hardware State Manager (for testing/debug)|
|Port|integer|false|none|Port number to respond to|
|Scn_cache_delay|integer|false|none|Max number seconds before sending cached and coalesced SCNs to subscribers.|
|Scn_max_cache|integer|false|none|Max number of similar SCNs to cache and coalesce before sending to  subscribers.|
|SM_retries|integer|false|none|Number of times to retry operations with Hardware State Manager on failure|
|SM_timeout|integer|false|none|Number of seconds to wait before giving up when communicating with Hardware State Manager|
|SM_url|string|false|none|URL used when contacting the Hardware State Manager|
|Telemetry_host|string|false|none|URL used when contacting the telemetry bus.  Contains service URL, port, and bus topic.|
|Use_telemetry|integer|false|none|Specifies whether or not to dump State Change Notifications onto the telemetry bus|

<h2 id="tocS_XName.1.0.0">XName.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxname.1.0.0"></a>
<a id="schema_XName.1.0.0"></a>
<a id="tocSxname.1.0.0"></a>
<a id="tocsxname.1.0.0"></a>

```json
"x0c1s2b0n3"

```

Identifies sender by xname. This is the physical, location-based name of a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Identifies sender by xname. This is the physical, location-based name of a component.|

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
|*anonymous*|Active|
|*anonymous*|Standby|
|*anonymous*|Halt|
|*anonymous*|Ready|
|*anonymous*|Paused|

<h2 id="tocS_SoftwareStatus.1.0.0">SoftwareStatus.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemasoftwarestatus.1.0.0"></a>
<a id="schema_SoftwareStatus.1.0.0"></a>
<a id="tocSsoftwarestatus.1.0.0"></a>
<a id="tocssoftwarestatus.1.0.0"></a>

```json
"AdminDown"

```

This property indicates a logical state of the underlying component.

### Properties

*None*

<h2 id="tocS_Roles.1.0.0">Roles.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaroles.1.0.0"></a>
<a id="schema_Roles.1.0.0"></a>
<a id="tocSroles.1.0.0"></a>
<a id="tocsroles.1.0.0"></a>

```json
"Compute"

```

This property indicates a node's role -- compute, service, uan, ssn, and others

### Properties

*None*

<h2 id="tocS_StateChanges">StateChanges</h2>
<!-- backwards compatibility -->
<a id="schemastatechanges"></a>
<a id="schema_StateChanges"></a>
<a id="tocSstatechanges"></a>
<a id="tocsstatechanges"></a>

```json
{
  "Components": [
    "x0c1s2b0n3"
  ],
  "Enabled": "true",
  "Role": "Compute",
  "SoftwareStatus": "AdminDown",
  "State": "Ready"
}

```

This is the JSON payload that contains State Change Notification information, sent by the Hardware State Manager

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Components|[[XName.1.0.0](#schemaxname.1.0.0)]|false|none|This is a list of components to associate with a State Change Notification|
|Enabled|boolean|false|none|If true, component has changed to the Enabled state; if false, it has changed to the Disabled state.|
|Role|[Roles.1.0.0](#schemaroles.1.0.0)|false|none|This property indicates a node's role -- compute, service, uan, ssn, and others|
|SoftwareStatus|[SoftwareStatus.1.0.0](#schemasoftwarestatus.1.0.0)|false|none|This property indicates a logical state of the underlying component.|
|State|[HMSState.1.0.0](#schemahmsstate.1.0.0)|false|none|This property indicates the state of the underlying component.|

<h2 id="tocS_SubscriptionUrl">SubscriptionUrl</h2>
<!-- backwards compatibility -->
<a id="schemasubscriptionurl"></a>
<a id="schema_SubscriptionUrl"></a>
<a id="tocSsubscriptionurl"></a>
<a id="tocssubscriptionurl"></a>

```json
"https://x0c1s2b0n3.cray.com:7999/scn"

```

URL to send State Change Notifications to

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|URL to send State Change Notifications to|

<h2 id="tocS_SubscriptionListArray">SubscriptionListArray</h2>
<!-- backwards compatibility -->
<a id="schemasubscriptionlistarray"></a>
<a id="schema_SubscriptionListArray"></a>
<a id="tocSsubscriptionlistarray"></a>
<a id="tocssubscriptionlistarray"></a>

```json
{
  "SubscriptionList": [
    {
      "Components": [
        "x0c1s2b0n3"
      ],
      "Subscriber": "scnHandler@x1000c1s2b0n3",
      "SubscriberComponent": "x1000c1s2b0n3",
      "SubscriberAgent": "scnHandler",
      "Enabled": "true",
      "Roles": [
        "Compute"
      ],
      "SoftwareStatus": [
        "AdminDown"
      ],
      "States": [
        "Ready"
      ],
      "Url": "https://x0c1s2b0n3.cray.com:8080/scns"
    }
  ]
}

```

List of all currently held State Change Notification subscriptions.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|SubscriptionList|[[SubscribePost](#schemasubscribepost)]|false|none|[This is the JSON payload that contains State Change Notification subscription information.]|

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

