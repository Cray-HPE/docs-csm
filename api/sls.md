<!-- Generator: Widdershins v4.0.1 -->

<h1 id="system-layout-service">System Layout Service v2</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

System Layout Service (SLS) holds information on the complete, designed system.
SLS gets this information from an input file on the system.
Besides information like what hardware should be present in a system, SLS
also stores information about what network connections exist and what power
connections exist. SLS details the physical locations of network hardware,
compute nodes and cabinets. Further, it stores information about the network,
such as which port on which switch should be connected to each compute node.
The API allows updating this information as well.

Note that SLS is not responsible for verifying that the system is set up
correctly. It only lets the Shasta system know what the system should be
configured with. SLS does not store the details of the actual
hardware like hardware identifiers. Instead it stores a generalized abstraction
of the system that other services may use. SLS thus does not need to change as
hardware within the system is replaced. Interaction with SLS is required if
the system setup changes – for example, if system cabling is altered or during 
installation, expansion or reduction. SLS does not interact with the hardware.

Each object in SLS has the following basic properties:
* Parent – Each object in SLS has a parent object except the system root (s0).
* Children – Objects may have children.
* xname – Every object has an xname – a unique identifier for that object.
* Type – a hardware type like "comptype_ncard", "comptype_cabinet".
* Class – kind of hardware like "River" or "Mountain"
* TypeString – a human readable type like "Cabinet"

Some objects may have additional properties depending on their type. For example, additional
properties for cabinets include "Network", "IP6Prefix", "IP4Base", "MACprefix" etc.

## Resources

### /hardware

Create hardware entries in SLS. This resource can be used when you add new
components or expand your system. Interaction with this resource is not required if a
component is removed or replaced.

### /hardware/{xname}

Retrieve, update, or delete information about specific xnames.

### /search/hardware

Uses HTTP query parameters to find hardware entries with matching properties. Returns a
JSON list of xnames. If multiple query parameters are passed, any returned hardware must
match all parameters.

For example, a query string of "?parent=x0" would return a list of all children of cabinet
x0. A query string of "?type=comptype_node" would return a list of all compute
nodes.

Valid query parameters are: xname, parent, class, type, power_connector, node_nics, networks, peers.

### /search/networks

Uses HTTP query parameters to find network entries with matching properties.

### /networks

Create new network objects or retrieve networks available in the system.

### /networks/{network}

Retrieve, update, or delete information about specific networks.

### /dumpstate

Dumps the current database state of the service. This may be useful
when you are backing up the system or planning a reinstall of the system.

### /loadstate

Upload and overwrite the current database with the contents of the posted data. The posted
data should be a state dump from /dumpstate. This may be useful to restore the SLS database
after you have reinstalled the system.

## Workflows

### Backup and Restore the SLS Database for Reinstallation

#### GET /dumpstate

Perform a dump of the current state of the SLS data. This should be done before reinstalling
the system. The database dump is a JSON blob in an SLS-specific format.

#### POST /loadstate

Reimport the dump from /dumpstate and restore the SLS database after reinstall.
    
### Expand System

#### POST /hardware

Add the new hardware objects.

#### GET /hardware/{xname}

Review hardware properties of the xname from the JSON array.

### Remove Hardware

#### DELETE /hardware

Remove hardware from SLS

### Modify Hardware Properties

#### PATCH /hardware

Modify hardware properties in SLS. Only additional properties can be modified. Basic properties
like xname, parent, children, type, class, typestring cannot be modified. 
             

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/sls/v1">https://api-gw-service-nmn.local/apis/sls/v1</a>

* <a href="http://cray-sls">http://cray-sls</a>

 License: Cray Proprietary

<h1 id="system-layout-service-hardware">hardware</h1>

Endpoints which request information about hardware

## get__hardware

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sls/v1/hardware HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/hardware \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/hardware', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/hardware", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /hardware`

*Retrieve a list of hardware in the system.*

Retrieve a JSON list of the networks available in the system.  Return value is an array of hardware objects representing all the hardware in the system.

> Example responses

> 200 Response

```json
[
  {
    "Parent": "x0c0s0",
    "Xname": "x0c0s0b0",
    "Children": [
      "x0c0s0b0n0"
    ],
    "Type": "comptype_ncard",
    "TypeString": "string",
    "Class": "Mountain",
    "LastUpdated": 0,
    "LastUpdatedTime": "string",
    "ExtraProperties": {
      "Object": [
        "x0c0s0b0"
      ]
    }
  }
]
```

<h3 id="get__hardware-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Request successful|Inline|

<h3 id="get__hardware-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[hardware](#schemahardware)]|false|none|none|
|» Parent|string|false|read-only|The xname of the parent of this piece of hardware|
|» Xname|[xname](#schemaxname)|true|none|The xname of this piece of hardware|
|» Children|[string]|false|read-only|none|
|» Type|string|false|read-only|The type of this piece of hardware.  This is an optional hint during upload; it will be ignored if it does not match the xname|
|» TypeString|string|false|read-only|none|
|» Class|[hwclass](#schemahwclass)|true|none|The hardware class.|
|» LastUpdated|[last_updated](#schemalast_updated)|false|read-only|The unix timestamp of the last time this entry was created or updated|
|» LastUpdatedTime|[last_updated_time](#schemalast_updated_time)|false|read-only|The human-readable time this object was last created or updated.|
|» ExtraProperties|any|false|none|none|

*oneOf*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_comptype_hsn_connector](#schemahardware_comptype_hsn_connector)|false|none|none|
|»»» Object|[[xname](#schemaxname)]|true|none|An array of xnames that this connector is connected to.  All xnames should have type==comptype_hsn_connector_port|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_pwr_connector](#schemahardware_pwr_connector)|false|none|none|
|»»» PoweredBy|[xname](#schemaxname)|true|none|The xname of this piece of hardware|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_mgmt_switch_connector](#schemahardware_mgmt_switch_connector)|false|none|none|
|»»» NodeNics|[[xname](#schemaxname)]|true|none|An array of Xnames that the hardware_mgmt_switch_connector is connected to.  Excludes the parent.|
|»»» VendorName|string|false|none|The vendor-assigned name for this port, as it appears in the switch management software.  Typically this is something like "GigabitEthernet 1/31" (berkley-style names), but may be any string.|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_bmc](#schemahardware_bmc)|false|none|none|
|»»» IP6addr|string|true|none|The ipv6 address that should be assigned to this BMC, or "DHCPv6".  If omitted, "DHCPv6" is assumed.|
|»»» IP4addr|string|true|none|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|»»» Username|string|false|none|The username that should be used to access the device (or be assigned to the device)|
|»»» Password|string|false|none|The password that should be used to access the device (or be assigned to the device)|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_nic](#schemahardware_nic)|false|none|none|
|»»» Networks|[[xname](#schemaxname)]|true|none|An array of network names that this nic is connected to|
|»»» Peers|[[xname](#schemaxname)]|true|none|An array of xnames this nic is connected directly to.  These ideally connector xnames, not switches|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_nic](#schemahardware_nic)|false|none|none|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_powered_device](#schemahardware_powered_device)|false|none|none|
|»»» PowerConnector|[[xname](#schemaxname)]|true|none|An array of xnames, where each xname has type==*_pwr_connector.  Empty for Mountain switch cards|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_powered_device](#schemahardware_powered_device)|false|none|none|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_powered_device](#schemahardware_powered_device)|false|none|none|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_comptype_cab_pdu](#schemahardware_comptype_cab_pdu)|false|none|none|
|»»» IP6addr|string|true|none|The ipv6 address that should be assigned to this BMC, or "DHCPv6". If omitted, "DHCPv6" is assumed.|
|»»» IP4addr|string|true|none|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|»»» Username|string|true|none|The username that should be used to access the device (or be assigned to the device)|
|»»» Password|string(password)|true|none|The password that should be used to access the device|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_comptype_node](#schemahardware_comptype_node)|false|none|none|
|»»» NodeType|string|true|none|The role type assigned to this node.|
|»»» nid|integer|false|none|none|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_ip_and_creds_optional](#schemahardware_ip_and_creds_optional)|false|none|none|
|»»» IP6addr|string|false|none|The ipv6 address that should be assigned to this BMC, or "DHCPv6".  If omitted, "DHCPv6" is assumed.|
|»»» IP4addr|string|false|none|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|»»» Username|string|false|none|The username that should be used to access the device (or be assigned to the device)|
|»»» Password|string|false|none|The password that should be used to access the device (or be assigned to the device)|

#### Enumerated Values

|Property|Value|
|---|---|
|Class|River|
|Class|Mountain|
|Class|Hill|
|NodeType|Compute|
|NodeType|System|
|NodeType|Application|
|NodeType|Storage|
|NodeType|Management|

<aside class="success">
This operation does not require authentication
</aside>

## post__hardware

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/sls/v1/hardware HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/sls/v1/hardware \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/sls/v1/hardware', headers = headers)

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/sls/v1/hardware", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /hardware`

*Create a new hardware object*

Create a new hardware object.

> Body parameter

```json
{
  "Xname": "x0c0s0b0",
  "Class": "Mountain",
  "ExtraProperties": {
    "Object": [
      "x0c0s0b0"
    ]
  }
}
```

<h3 id="post__hardware-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[hardware_post](#schemahardware_post)|false|none|

> Example responses

> 201 Response

```json
{
  "Parent": "x0c0s0",
  "Xname": "x0c0s0b0",
  "Children": [
    "x0c0s0b0n0"
  ],
  "Type": "comptype_ncard",
  "TypeString": "string",
  "Class": "Mountain",
  "LastUpdated": 0,
  "LastUpdatedTime": "string",
  "ExtraProperties": {
    "Object": [
      "x0c0s0b0"
    ]
  }
}
```

<h3 id="post__hardware-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Request successful. The item was created|[hardware](#schemahardware)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request. See body for details|None|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. The requested resource already exists|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Unexpected error. See body for details|None|

<aside class="success">
This operation does not require authentication
</aside>

## get__hardware_{xname}

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /hardware/{xname}`

*Retrieve information about the requested xname*

Retrieve information about the requested xname. All properties are returned as a JSON array.

<h3 id="get__hardware_{xname}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|[xname](#schemaxname)|true|The xname to look up or alter.|

> Example responses

> 200 Response

```json
{
  "Parent": "x0c0s0",
  "Xname": "x0c0s0b0",
  "Children": [
    "x0c0s0b0n0"
  ],
  "Type": "comptype_ncard",
  "TypeString": "string",
  "Class": "Mountain",
  "LastUpdated": 0,
  "LastUpdatedTime": "string",
  "ExtraProperties": {
    "Object": [
      "x0c0s0b0"
    ]
  }
}
```

<h3 id="get__hardware_{xname}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Request successful|[hardware](#schemahardware)|

<aside class="success">
This operation does not require authentication
</aside>

## put__hardware_{xname}

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname}', headers = headers)

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
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /hardware/{xname}`

*Update a hardware object*

Update a hardware object.  Parent objects will be created, if possible.

> Body parameter

```json
{
  "Class": "Mountain",
  "ExtraProperties": {
    "Object": [
      "x0c0s0b0"
    ]
  }
}
```

<h3 id="put__hardware_{xname}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|[xname](#schemaxname)|true|The xname to look up or alter.|
|body|body|[hardware_put](#schemahardware_put)|false|none|

> Example responses

> 200 Response

```json
{
  "Parent": "x0c0s0",
  "Xname": "x0c0s0b0",
  "Children": [
    "x0c0s0b0n0"
  ],
  "Type": "comptype_ncard",
  "TypeString": "string",
  "Class": "Mountain",
  "LastUpdated": 0,
  "LastUpdatedTime": "string",
  "ExtraProperties": {
    "Object": [
      "x0c0s0b0"
    ]
  }
}
```

<h3 id="put__hardware_{xname}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Request successful. The item was updated|[hardware](#schemahardware)|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Request successful. The item was created|[hardware](#schemahardware)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request. See body for details|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Unexpected error. See body for details|None|

<aside class="success">
This operation does not require authentication
</aside>

## delete__hardware_{xname}

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname} HTTP/1.1
Host: api-gw-service-nmn.local

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname}

```

```python
import requests

r = requests.delete('https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname}')

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/sls/v1/hardware/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /hardware/{xname}`

*Delete the xname*

Delete the requested xname from SLS. Note that if you delete a parent object, then the children are also deleted from SLS. If the child object happens to be a parent, then the deletion can cascade down levels. If you delete a child object, it does not affect the parent.

<h3 id="delete__hardware_{xname}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|[xname](#schemaxname)|true|The xname to look up or alter.|

<h3 id="delete__hardware_{xname}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK. xname removed|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Xname not found|None|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. The xname probably still had children.|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="system-layout-service-search">search</h1>

Endpoints having to do with searching for hardware

## get__search_hardware

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sls/v1/search/hardware HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/search/hardware \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/search/hardware', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /search/hardware`

*Search for nodes matching a set of criteria*

Search for nodes matching a set of criteria. Any of the properties of any entry in the database may be used as search keys.

<h3 id="get__search_hardware-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|query|[xname](#schemaxname)|false|Matches the specified xname|
|parent|query|[xname](#schemaxname)|false|Matches all objects that are direct children of the given xname|
|class|query|[hwclass](#schemahwclass)|false|Matches all objects of the given class|
|type|query|[hwtype](#schemahwtype)|false|Matches all objects of the given type|
|power_connector|query|[xname](#schemaxname)|false|Matches all objects with the given xname in their power_connector property|
|object|query|[xname](#schemaxname)|false|Matches all objects with the given xname in their object property.|
|node_nics|query|[xname](#schemaxname)|false|Matches all objects with the given xname in thier node_nics property|
|networks|query|string|false|Matches all objects with the given xname in their networks property|
|peers|query|[xname](#schemaxname)|false|Matches all objects with the given xname in their peers property|

#### Enumerated Values

|Parameter|Value|
|---|---|
|class|River|
|class|Mountain|
|class|Hill|

> Example responses

> 200 Response

```json
[
  {
    "Parent": "x0c0s0",
    "Xname": "x0c0s0b0",
    "Children": [
      "x0c0s0b0n0"
    ],
    "Type": "comptype_ncard",
    "TypeString": "string",
    "Class": "Mountain",
    "LastUpdated": 0,
    "LastUpdatedTime": "string",
    "ExtraProperties": {
      "Object": [
        "x0c0s0b0"
      ]
    }
  }
]
```

<h3 id="get__search_hardware-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Search completed successfully.  The return is an array of xnames that match the search criteria.|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request. See body for details.|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Search did not find any matching hardware.|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An unexpected error occurred. See body for details.|None|

<h3 id="get__search_hardware-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[hardware](#schemahardware)]|false|none|none|
|» Parent|string|false|read-only|The xname of the parent of this piece of hardware|
|» Xname|[xname](#schemaxname)|true|none|The xname of this piece of hardware|
|» Children|[string]|false|read-only|none|
|» Type|string|false|read-only|The type of this piece of hardware.  This is an optional hint during upload; it will be ignored if it does not match the xname|
|» TypeString|string|false|read-only|none|
|» Class|[hwclass](#schemahwclass)|true|none|The hardware class.|
|» LastUpdated|[last_updated](#schemalast_updated)|false|read-only|The unix timestamp of the last time this entry was created or updated|
|» LastUpdatedTime|[last_updated_time](#schemalast_updated_time)|false|read-only|The human-readable time this object was last created or updated.|
|» ExtraProperties|any|false|none|none|

*oneOf*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_comptype_hsn_connector](#schemahardware_comptype_hsn_connector)|false|none|none|
|»»» Object|[[xname](#schemaxname)]|true|none|An array of xnames that this connector is connected to.  All xnames should have type==comptype_hsn_connector_port|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_pwr_connector](#schemahardware_pwr_connector)|false|none|none|
|»»» PoweredBy|[xname](#schemaxname)|true|none|The xname of this piece of hardware|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_mgmt_switch_connector](#schemahardware_mgmt_switch_connector)|false|none|none|
|»»» NodeNics|[[xname](#schemaxname)]|true|none|An array of Xnames that the hardware_mgmt_switch_connector is connected to.  Excludes the parent.|
|»»» VendorName|string|false|none|The vendor-assigned name for this port, as it appears in the switch management software.  Typically this is something like "GigabitEthernet 1/31" (berkley-style names), but may be any string.|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_bmc](#schemahardware_bmc)|false|none|none|
|»»» IP6addr|string|true|none|The ipv6 address that should be assigned to this BMC, or "DHCPv6".  If omitted, "DHCPv6" is assumed.|
|»»» IP4addr|string|true|none|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|»»» Username|string|false|none|The username that should be used to access the device (or be assigned to the device)|
|»»» Password|string|false|none|The password that should be used to access the device (or be assigned to the device)|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_nic](#schemahardware_nic)|false|none|none|
|»»» Networks|[[xname](#schemaxname)]|true|none|An array of network names that this nic is connected to|
|»»» Peers|[[xname](#schemaxname)]|true|none|An array of xnames this nic is connected directly to.  These ideally connector xnames, not switches|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_nic](#schemahardware_nic)|false|none|none|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_powered_device](#schemahardware_powered_device)|false|none|none|
|»»» PowerConnector|[[xname](#schemaxname)]|true|none|An array of xnames, where each xname has type==*_pwr_connector.  Empty for Mountain switch cards|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_powered_device](#schemahardware_powered_device)|false|none|none|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_powered_device](#schemahardware_powered_device)|false|none|none|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_comptype_cab_pdu](#schemahardware_comptype_cab_pdu)|false|none|none|
|»»» IP6addr|string|true|none|The ipv6 address that should be assigned to this BMC, or "DHCPv6". If omitted, "DHCPv6" is assumed.|
|»»» IP4addr|string|true|none|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|»»» Username|string|true|none|The username that should be used to access the device (or be assigned to the device)|
|»»» Password|string(password)|true|none|The password that should be used to access the device|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_comptype_node](#schemahardware_comptype_node)|false|none|none|
|»»» NodeType|string|true|none|The role type assigned to this node.|
|»»» nid|integer|false|none|none|

*xor*

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|»» *anonymous*|[hardware_ip_and_creds_optional](#schemahardware_ip_and_creds_optional)|false|none|none|
|»»» IP6addr|string|false|none|The ipv6 address that should be assigned to this BMC, or "DHCPv6".  If omitted, "DHCPv6" is assumed.|
|»»» IP4addr|string|false|none|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|»»» Username|string|false|none|The username that should be used to access the device (or be assigned to the device)|
|»»» Password|string|false|none|The password that should be used to access the device (or be assigned to the device)|

#### Enumerated Values

|Property|Value|
|---|---|
|Class|River|
|Class|Mountain|
|Class|Hill|
|NodeType|Compute|
|NodeType|System|
|NodeType|Application|
|NodeType|Storage|
|NodeType|Management|

<aside class="success">
This operation does not require authentication
</aside>

## get__search_networks

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sls/v1/search/networks HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/search/networks \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/search/networks', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/search/networks", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /search/networks`

*Perform a search for networks matching a set of criteria.*

Perform a search for networks matching a set of criteria.  Any of the properties of any entry in the database may be used as search keys.

<h3 id="get__search_networks-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|name|query|string|false|Matches the specified network name|
|full_name|query|string|false|Matches the specified network full name|
|type|query|[network_type](#schemanetwork_type)|false|Matches the specified network type|
|ip_address|query|[network_ip_range](#schemanetwork_ip_range)|false|Matches all networks that could contain the specified IP address in their IP ranges|

> Example responses

> 200 Response

```json
[
  {
    "Name": "HSN",
    "FullName": "High Speed Network",
    "IPRanges": [
      "string"
    ],
    "Type": "slingshot10",
    "LastUpdated": 0,
    "LastUpdatedTime": "string",
    "ExtraProperties": {
      "CIDR": "10.253.0.0/16",
      "VlanRange": [
        0
      ],
      "MTU": 9000,
      "Subnets": [
        {
          "Name": "cabinet_1008_hsn\"",
          "FullName": "Cabinet 1008 HSN",
          "CIDR": "10.253.0.0/16",
          "VlanID": 60,
          "Gateway": "192.168.0.1",
          "DHCPStart": "192.168.0.1",
          "DHCPEnd": "192.168.0.1",
          "IPReservations": [
            {
              "IPAddress": "192.168.0.1",
              "Name": "S3",
              "Aliases": [
                "rgw-vip.local"
              ],
              "Comment": "string"
            }
          ],
          "Comment": "string"
        }
      ],
      "Comment": "string"
    }
  }
]
```

<h3 id="get__search_networks-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Search completed successfully.  Return is an array of networks matching the search criteria.|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Search did not find any matching networks.|None|

<h3 id="get__search_networks-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[network](#schemanetwork)]|false|none|none|
|» Name|string|true|none|none|
|» FullName|string|false|none|none|
|» IPRanges|[[network_ip_range](#schemanetwork_ip_range)]|true|none|none|
|» Type|[network_type](#schemanetwork_type)|true|none|none|
|» LastUpdated|[last_updated](#schemalast_updated)|false|read-only|The unix timestamp of the last time this entry was created or updated|
|» LastUpdatedTime|[last_updated_time](#schemalast_updated_time)|false|read-only|The human-readable time this object was last created or updated.|
|» ExtraProperties|[network_extra_properties](#schemanetwork_extra_properties)|false|none|none|
|»» CIDR|string|false|none|none|
|»» VlanRange|[integer]|false|none|none|
|»» MTU|integer|false|none|none|
|»» Subnets|[[network_ipv4_subnet](#schemanetwork_ipv4_subnet)]|false|none|none|
|»»» Name|string|true|none|none|
|»»» FullName|string|false|none|none|
|»»» CIDR|string|true|none|none|
|»»» VlanID|integer|true|none|none|
|»»» Gateway|string(ipv4)|false|none|none|
|»»» DHCPStart|string(ipv4)|false|none|none|
|»»» DHCPEnd|string(ipv4)|false|none|none|
|»»» IPReservations|[[network_ip_reservation](#schemanetwork_ip_reservation)]|false|none|none|
|»»»» IPAddress|string(ipv4)|true|none|none|
|»»»» Name|string|true|none|none|
|»»»» Aliases|[string]|false|none|none|
|»»»» Comment|string|false|none|none|
|»»» Comment|string|false|none|none|
|»» Comment|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="system-layout-service-dumpstate">dumpstate</h1>

Endpoints that handle debug or state management

## get__dumpstate

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sls/v1/dumpstate HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/dumpstate \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/dumpstate', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/dumpstate", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /dumpstate`

*Retrieve a dump of current service state*

Get a dump of current service state. The format of this is implementation-specific.

> Example responses

> 200 Response

```json
{
  "Hardware": {
    "property1": {
      "Parent": "x0c0s0",
      "Xname": "x0c0s0b0",
      "Children": [
        "x0c0s0b0n0"
      ],
      "Type": "comptype_ncard",
      "TypeString": "string",
      "Class": "Mountain",
      "LastUpdated": 0,
      "LastUpdatedTime": "string",
      "ExtraProperties": {
        "Object": [
          "x0c0s0b0"
        ]
      }
    },
    "property2": {
      "Parent": "x0c0s0",
      "Xname": "x0c0s0b0",
      "Children": [
        "x0c0s0b0n0"
      ],
      "Type": "comptype_ncard",
      "TypeString": "string",
      "Class": "Mountain",
      "LastUpdated": 0,
      "LastUpdatedTime": "string",
      "ExtraProperties": {
        "Object": [
          "x0c0s0b0"
        ]
      }
    }
  },
  "Networks": {
    "property1": {
      "Name": "HSN",
      "FullName": "High Speed Network",
      "IPRanges": [
        "string"
      ],
      "Type": "slingshot10",
      "LastUpdated": 0,
      "LastUpdatedTime": "string",
      "ExtraProperties": {
        "CIDR": "10.253.0.0/16",
        "VlanRange": [
          0
        ],
        "MTU": 9000,
        "Subnets": [
          {
            "Name": "cabinet_1008_hsn\"",
            "FullName": "Cabinet 1008 HSN",
            "CIDR": "10.253.0.0/16",
            "VlanID": 60,
            "Gateway": "192.168.0.1",
            "DHCPStart": "192.168.0.1",
            "DHCPEnd": "192.168.0.1",
            "IPReservations": [
              {
                "IPAddress": "192.168.0.1",
                "Name": "S3",
                "Aliases": [
                  "rgw-vip.local"
                ],
                "Comment": "string"
              }
            ],
            "Comment": "string"
          }
        ],
        "Comment": "string"
      }
    },
    "property2": {
      "Name": "HSN",
      "FullName": "High Speed Network",
      "IPRanges": [
        "string"
      ],
      "Type": "slingshot10",
      "LastUpdated": 0,
      "LastUpdatedTime": "string",
      "ExtraProperties": {
        "CIDR": "10.253.0.0/16",
        "VlanRange": [
          0
        ],
        "MTU": 9000,
        "Subnets": [
          {
            "Name": "cabinet_1008_hsn\"",
            "FullName": "Cabinet 1008 HSN",
            "CIDR": "10.253.0.0/16",
            "VlanID": 60,
            "Gateway": "192.168.0.1",
            "DHCPStart": "192.168.0.1",
            "DHCPEnd": "192.168.0.1",
            "IPReservations": [
              {
                "IPAddress": "192.168.0.1",
                "Name": "S3",
                "Aliases": [
                  "rgw-vip.local"
                ],
                "Comment": "string"
              }
            ],
            "Comment": "string"
          }
        ],
        "Comment": "string"
      }
    }
  }
}
```

<h3 id="get__dumpstate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|State dumped successfully|[slsState](#schemaslsstate)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An error occurred in state dumping.  See body for details|None|

<aside class="success">
This operation does not require authentication
</aside>

## post__loadstate

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/sls/v1/loadstate HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: multipart/form-data

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/sls/v1/loadstate \
  -H 'Content-Type: multipart/form-data'

```

```python
import requests
headers = {
  'Content-Type': 'multipart/form-data'
}

r = requests.post('https://api-gw-service-nmn.local/apis/sls/v1/loadstate', headers = headers)

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
        "Content-Type": []string{"multipart/form-data"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/sls/v1/loadstate", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /loadstate`

*Load services state and overwrite current service state*

"Load services state and overwrite current service state. The format of the upload is implementation specific."

> Body parameter

```yaml
sls_dump:
  Hardware:
    property1:
      Xname: x0c0s0b0
      Class: Mountain
      ExtraProperties:
        Object:
          - x0c0s0b0
    property2:
      Xname: x0c0s0b0
      Class: Mountain
      ExtraProperties:
        Object:
          - x0c0s0b0
  Networks:
    property1:
      Name: HSN
      FullName: High Speed Network
      IPRanges:
        - string
      Type: slingshot10
      ExtraProperties:
        CIDR: 10.253.0.0/16
        VlanRange:
          - 0
        MTU: 9000
        Subnets:
          - Name: cabinet_1008_hsn"
            FullName: Cabinet 1008 HSN
            CIDR: 10.253.0.0/16
            VlanID: 60
            Gateway: 192.168.0.1
            DHCPStart: 192.168.0.1
            DHCPEnd: 192.168.0.1
            IPReservations:
              - IPAddress: 192.168.0.1
                Name: S3
                Aliases:
                  - rgw-vip.local
                Comment: string
            Comment: string
        Comment: string
    property2:
      Name: HSN
      FullName: High Speed Network
      IPRanges:
        - string
      Type: slingshot10
      ExtraProperties:
        CIDR: 10.253.0.0/16
        VlanRange:
          - 0
        MTU: 9000
        Subnets:
          - Name: cabinet_1008_hsn"
            FullName: Cabinet 1008 HSN
            CIDR: 10.253.0.0/16
            VlanID: 60
            Gateway: 192.168.0.1
            DHCPStart: 192.168.0.1
            DHCPEnd: 192.168.0.1
            IPReservations:
              - IPAddress: 192.168.0.1
                Name: S3
                Aliases:
                  - rgw-vip.local
                Comment: string
            Comment: string
        Comment: string

```

<h3 id="post__loadstate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|object|false|A JSON dictionary, where each item has a key equal to the xname of the object it contains.  Each value is a JSON representation of an object SLS should maintain.|
|» sls_dump|body|[slsState](#schemaslsstate)|false|none|
|»» Hardware|body|object|false|none|
|»»» **additionalProperties**|body|[hardware](#schemahardware)|false|none|
|»»»» Parent|body|string|false|The xname of the parent of this piece of hardware|
|»»»» Xname|body|[xname](#schemaxname)|true|The xname of this piece of hardware|
|»»»» Children|body|[string]|false|none|
|»»»» Type|body|string|false|The type of this piece of hardware.  This is an optional hint during upload; it will be ignored if it does not match the xname|
|»»»» TypeString|body|string|false|none|
|»»»» Class|body|[hwclass](#schemahwclass)|true|The hardware class.|
|»»»» LastUpdated|body|[last_updated](#schemalast_updated)|false|The unix timestamp of the last time this entry was created or updated|
|»»»» LastUpdatedTime|body|[last_updated_time](#schemalast_updated_time)|false|The human-readable time this object was last created or updated.|
|»»»» ExtraProperties|body|any|false|none|
|»»»»» *anonymous*|body|[hardware_comptype_hsn_connector](#schemahardware_comptype_hsn_connector)|false|none|
|»»»»»» Object|body|[[xname](#schemaxname)]|true|An array of xnames that this connector is connected to.  All xnames should have type==comptype_hsn_connector_port|
|»»»»» *anonymous*|body|[hardware_pwr_connector](#schemahardware_pwr_connector)|false|none|
|»»»»»» PoweredBy|body|[xname](#schemaxname)|true|The xname of this piece of hardware|
|»»»»» *anonymous*|body|[hardware_mgmt_switch_connector](#schemahardware_mgmt_switch_connector)|false|none|
|»»»»»» NodeNics|body|[[xname](#schemaxname)]|true|An array of Xnames that the hardware_mgmt_switch_connector is connected to.  Excludes the parent.|
|»»»»»» VendorName|body|string|false|The vendor-assigned name for this port, as it appears in the switch management software.  Typically this is something like "GigabitEthernet 1/31" (berkley-style names), but may be any string.|
|»»»»» *anonymous*|body|[hardware_bmc](#schemahardware_bmc)|false|none|
|»»»»»» IP6addr|body|string|true|The ipv6 address that should be assigned to this BMC, or "DHCPv6".  If omitted, "DHCPv6" is assumed.|
|»»»»»» IP4addr|body|string|true|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|»»»»»» Username|body|string|false|The username that should be used to access the device (or be assigned to the device)|
|»»»»»» Password|body|string|false|The password that should be used to access the device (or be assigned to the device)|
|»»»»» *anonymous*|body|[hardware_nic](#schemahardware_nic)|false|none|
|»»»»»» Networks|body|[[xname](#schemaxname)]|true|An array of network names that this nic is connected to|
|»»»»»» Peers|body|[[xname](#schemaxname)]|true|An array of xnames this nic is connected directly to.  These ideally connector xnames, not switches|
|»»»»» *anonymous*|body|[hardware_nic](#schemahardware_nic)|false|none|
|»»»»» *anonymous*|body|[hardware_powered_device](#schemahardware_powered_device)|false|none|
|»»»»»» PowerConnector|body|[[xname](#schemaxname)]|true|An array of xnames, where each xname has type==*_pwr_connector.  Empty for Mountain switch cards|
|»»»»» *anonymous*|body|[hardware_powered_device](#schemahardware_powered_device)|false|none|
|»»»»» *anonymous*|body|[hardware_powered_device](#schemahardware_powered_device)|false|none|
|»»»»» *anonymous*|body|[hardware_comptype_cab_pdu](#schemahardware_comptype_cab_pdu)|false|none|
|»»»»»» IP6addr|body|string|true|The ipv6 address that should be assigned to this BMC, or "DHCPv6". If omitted, "DHCPv6" is assumed.|
|»»»»»» IP4addr|body|string|true|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|»»»»»» Username|body|string|true|The username that should be used to access the device (or be assigned to the device)|
|»»»»»» Password|body|string(password)|true|The password that should be used to access the device|
|»»»»» *anonymous*|body|[hardware_comptype_node](#schemahardware_comptype_node)|false|none|
|»»»»»» NodeType|body|string|true|The role type assigned to this node.|
|»»»»»» nid|body|integer|false|none|
|»»»»» *anonymous*|body|[hardware_ip_and_creds_optional](#schemahardware_ip_and_creds_optional)|false|none|
|»»»»»» IP6addr|body|string|false|The ipv6 address that should be assigned to this BMC, or "DHCPv6".  If omitted, "DHCPv6" is assumed.|
|»»»»»» IP4addr|body|string|false|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|»»»»»» Username|body|string|false|The username that should be used to access the device (or be assigned to the device)|
|»»»»»» Password|body|string|false|The password that should be used to access the device (or be assigned to the device)|
|»» Networks|body|object|false|none|
|»»» **additionalProperties**|body|[network](#schemanetwork)|false|none|
|»»»» Name|body|string|true|none|
|»»»» FullName|body|string|false|none|
|»»»» IPRanges|body|[[network_ip_range](#schemanetwork_ip_range)]|true|none|
|»»»» Type|body|[network_type](#schemanetwork_type)|true|none|
|»»»» LastUpdated|body|[last_updated](#schemalast_updated)|false|The unix timestamp of the last time this entry was created or updated|
|»»»» LastUpdatedTime|body|[last_updated_time](#schemalast_updated_time)|false|The human-readable time this object was last created or updated.|
|»»»» ExtraProperties|body|[network_extra_properties](#schemanetwork_extra_properties)|false|none|
|»»»»» CIDR|body|string|false|none|
|»»»»» VlanRange|body|[integer]|false|none|
|»»»»» MTU|body|integer|false|none|
|»»»»» Subnets|body|[[network_ipv4_subnet](#schemanetwork_ipv4_subnet)]|false|none|
|»»»»»» Name|body|string|true|none|
|»»»»»» FullName|body|string|false|none|
|»»»»»» CIDR|body|string|true|none|
|»»»»»» VlanID|body|integer|true|none|
|»»»»»» Gateway|body|string(ipv4)|false|none|
|»»»»»» DHCPStart|body|string(ipv4)|false|none|
|»»»»»» DHCPEnd|body|string(ipv4)|false|none|
|»»»»»» IPReservations|body|[[network_ip_reservation](#schemanetwork_ip_reservation)]|false|none|
|»»»»»»» IPAddress|body|string(ipv4)|true|none|
|»»»»»»» Name|body|string|true|none|
|»»»»»»» Aliases|body|[string]|false|none|
|»»»»»»» Comment|body|string|false|none|
|»»»»»» Comment|body|string|false|none|
|»»»»» Comment|body|string|false|none|

#### Enumerated Values

|Parameter|Value|
|---|---|
|»»»» Class|River|
|»»»» Class|Mountain|
|»»»» Class|Hill|
|»»»»»» NodeType|Compute|
|»»»»»» NodeType|System|
|»»»»»» NodeType|Application|
|»»»»»» NodeType|Storage|
|»»»»»» NodeType|Management|

<h3 id="post__loadstate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|State loaded successfully|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Loading state failed.  See body for error|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="system-layout-service-misc">misc</h1>

Other endpoints

## get__health

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sls/v1/health HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/health \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/health', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/health", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /health`

*Query the health of the service*

The `health` resource returns health information about the SLS service and its dependencies.  This actively checks the connection between  SLS and the following:

  * Vault
  * Database

This is primarily intended as a diagnostic tool to investigate the functioning of the SLS service.

> Example responses

> 200 Response

```json
{
  "Vault": "Not checked",
  "DBConnection": "Ready"
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
|» Vault|string|true|none|Status of the Vault.|
|» DBConnection|string|true|none|Status of the connection with the database.|

<aside class="success">
This operation does not require authentication
</aside>

## get__liveness

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sls/v1/liveness HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/liveness \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/liveness', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/liveness", data)
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
GET https://api-gw-service-nmn.local/apis/sls/v1/readiness HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/readiness \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/readiness', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/readiness", data)
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

## get__version

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sls/v1/version HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/version \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/version', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/version", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /version`

*Retrieve versioning information on the information in SLS*

Retrieve the current version of the SLS mapping. Information returned is a JSON array with two keys:
* Counter: A monotonically increasing counter. This counter is incremented every time
  a change is made to the map stored in SLS. This shall be 0 if no data is uploaded to SLS
* LastUpdated: An ISO 8601 datetime representing the time of the last change to SLS. 
  This shall be set to the Unix Epoch if no data has ever been stored in SLS.

> Example responses

> 200 Response

```json
{
  "counter": 0,
  "last_updated": "2019-08-24T14:15:22Z"
}
```

<h3 id="get__version-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Information retrieved successfully|[versionResponse](#schemaversionresponse)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An error occurred, see text of response for more information|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="system-layout-service-network">network</h1>

## get__networks

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sls/v1/networks HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/networks \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/networks', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/networks", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /networks`

*Retrieve a list of networks in the system*

Retrieve a JSON list of the networks available in the system.  Return value
is an array of strings with each string representing the name field of the network object.

> Example responses

> 200 Response

```json
[
  {
    "Name": "HSN",
    "FullName": "High Speed Network",
    "IPRanges": [
      "string"
    ],
    "Type": "slingshot10",
    "LastUpdated": 0,
    "LastUpdatedTime": "string",
    "ExtraProperties": {
      "CIDR": "10.253.0.0/16",
      "VlanRange": [
        0
      ],
      "MTU": 9000,
      "Subnets": [
        {
          "Name": "cabinet_1008_hsn\"",
          "FullName": "Cabinet 1008 HSN",
          "CIDR": "10.253.0.0/16",
          "VlanID": 60,
          "Gateway": "192.168.0.1",
          "DHCPStart": "192.168.0.1",
          "DHCPEnd": "192.168.0.1",
          "IPReservations": [
            {
              "IPAddress": "192.168.0.1",
              "Name": "S3",
              "Aliases": [
                "rgw-vip.local"
              ],
              "Comment": "string"
            }
          ],
          "Comment": "string"
        }
      ],
      "Comment": "string"
    }
  }
]
```

<h3 id="get__networks-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Request successful|Inline|

<h3 id="get__networks-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[network](#schemanetwork)]|false|none|none|
|» Name|string|true|none|none|
|» FullName|string|false|none|none|
|» IPRanges|[[network_ip_range](#schemanetwork_ip_range)]|true|none|none|
|» Type|[network_type](#schemanetwork_type)|true|none|none|
|» LastUpdated|[last_updated](#schemalast_updated)|false|read-only|The unix timestamp of the last time this entry was created or updated|
|» LastUpdatedTime|[last_updated_time](#schemalast_updated_time)|false|read-only|The human-readable time this object was last created or updated.|
|» ExtraProperties|[network_extra_properties](#schemanetwork_extra_properties)|false|none|none|
|»» CIDR|string|false|none|none|
|»» VlanRange|[integer]|false|none|none|
|»» MTU|integer|false|none|none|
|»» Subnets|[[network_ipv4_subnet](#schemanetwork_ipv4_subnet)]|false|none|none|
|»»» Name|string|true|none|none|
|»»» FullName|string|false|none|none|
|»»» CIDR|string|true|none|none|
|»»» VlanID|integer|true|none|none|
|»»» Gateway|string(ipv4)|false|none|none|
|»»» DHCPStart|string(ipv4)|false|none|none|
|»»» DHCPEnd|string(ipv4)|false|none|none|
|»»» IPReservations|[[network_ip_reservation](#schemanetwork_ip_reservation)]|false|none|none|
|»»»» IPAddress|string(ipv4)|true|none|none|
|»»»» Name|string|true|none|none|
|»»»» Aliases|[string]|false|none|none|
|»»»» Comment|string|false|none|none|
|»»» Comment|string|false|none|none|
|»» Comment|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## post__networks

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/sls/v1/networks HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/sls/v1/networks \
  -H 'Content-Type: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/sls/v1/networks', headers = headers)

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
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/sls/v1/networks", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /networks`

*Create a new network*

Create a new network. Must include all fields at the time of upload.

> Body parameter

```json
{
  "Name": "HSN",
  "FullName": "High Speed Network",
  "IPRanges": [
    "string"
  ],
  "Type": "slingshot10",
  "ExtraProperties": {
    "CIDR": "10.253.0.0/16",
    "VlanRange": [
      0
    ],
    "MTU": 9000,
    "Subnets": [
      {
        "Name": "cabinet_1008_hsn\"",
        "FullName": "Cabinet 1008 HSN",
        "CIDR": "10.253.0.0/16",
        "VlanID": 60,
        "Gateway": "192.168.0.1",
        "DHCPStart": "192.168.0.1",
        "DHCPEnd": "192.168.0.1",
        "IPReservations": [
          {
            "IPAddress": "192.168.0.1",
            "Name": "S3",
            "Aliases": [
              "rgw-vip.local"
            ],
            "Comment": "string"
          }
        ],
        "Comment": "string"
      }
    ],
    "Comment": "string"
  }
}
```

<h3 id="post__networks-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[network](#schemanetwork)|false|none|

<h3 id="post__networks-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Network created|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request. See body for details|None|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Network with that name already exists|None|

<aside class="success">
This operation does not require authentication
</aside>

## get__networks_{network}

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sls/v1/networks/{network} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sls/v1/networks/{network} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sls/v1/networks/{network}', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sls/v1/networks/{network}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /networks/{network}`

*Retrieve a network item*

Retrieve the specific network.

<h3 id="get__networks_{network}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|network|path|string|true|The network to look up or alter.|

> Example responses

> 200 Response

```json
{
  "Name": "HSN",
  "FullName": "High Speed Network",
  "IPRanges": [
    "string"
  ],
  "Type": "slingshot10",
  "LastUpdated": 0,
  "LastUpdatedTime": "string",
  "ExtraProperties": {
    "CIDR": "10.253.0.0/16",
    "VlanRange": [
      0
    ],
    "MTU": 9000,
    "Subnets": [
      {
        "Name": "cabinet_1008_hsn\"",
        "FullName": "Cabinet 1008 HSN",
        "CIDR": "10.253.0.0/16",
        "VlanID": 60,
        "Gateway": "192.168.0.1",
        "DHCPStart": "192.168.0.1",
        "DHCPEnd": "192.168.0.1",
        "IPReservations": [
          {
            "IPAddress": "192.168.0.1",
            "Name": "S3",
            "Aliases": [
              "rgw-vip.local"
            ],
            "Comment": "string"
          }
        ],
        "Comment": "string"
      }
    ],
    "Comment": "string"
  }
}
```

<h3 id="get__networks_{network}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Request successful|[network](#schemanetwork)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|No network item found with requested name|None|

<aside class="success">
This operation does not require authentication
</aside>

## put__networks_{network}

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/sls/v1/networks/{network} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/sls/v1/networks/{network} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('https://api-gw-service-nmn.local/apis/sls/v1/networks/{network}', headers = headers)

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
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/sls/v1/networks/{network}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /networks/{network}`

*Update a network object*

Update a network object. Parent objects will be created, if possible.

> Body parameter

```json
{
  "Name": "HSN",
  "FullName": "High Speed Network",
  "IPRanges": [
    "string"
  ],
  "Type": "slingshot10",
  "ExtraProperties": {
    "CIDR": "10.253.0.0/16",
    "VlanRange": [
      0
    ],
    "MTU": 9000,
    "Subnets": [
      {
        "Name": "cabinet_1008_hsn\"",
        "FullName": "Cabinet 1008 HSN",
        "CIDR": "10.253.0.0/16",
        "VlanID": 60,
        "Gateway": "192.168.0.1",
        "DHCPStart": "192.168.0.1",
        "DHCPEnd": "192.168.0.1",
        "IPReservations": [
          {
            "IPAddress": "192.168.0.1",
            "Name": "S3",
            "Aliases": [
              "rgw-vip.local"
            ],
            "Comment": "string"
          }
        ],
        "Comment": "string"
      }
    ],
    "Comment": "string"
  }
}
```

<h3 id="put__networks_{network}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|network|path|string|true|The network to look up or alter.|
|body|body|[network](#schemanetwork)|false|none|

> Example responses

> 200 Response

```json
{
  "Name": "HSN",
  "FullName": "High Speed Network",
  "IPRanges": [
    "string"
  ],
  "Type": "slingshot10",
  "LastUpdated": 0,
  "LastUpdatedTime": "string",
  "ExtraProperties": {
    "CIDR": "10.253.0.0/16",
    "VlanRange": [
      0
    ],
    "MTU": 9000,
    "Subnets": [
      {
        "Name": "cabinet_1008_hsn\"",
        "FullName": "Cabinet 1008 HSN",
        "CIDR": "10.253.0.0/16",
        "VlanID": 60,
        "Gateway": "192.168.0.1",
        "DHCPStart": "192.168.0.1",
        "DHCPEnd": "192.168.0.1",
        "IPReservations": [
          {
            "IPAddress": "192.168.0.1",
            "Name": "S3",
            "Aliases": [
              "rgw-vip.local"
            ],
            "Comment": "string"
          }
        ],
        "Comment": "string"
      }
    ],
    "Comment": "string"
  }
}
```

<h3 id="put__networks_{network}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Request successful|[network](#schemanetwork)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request. See body for details|None|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Conflict. The requested resource already exists|None|

<aside class="success">
This operation does not require authentication
</aside>

## delete__networks_{network}

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/sls/v1/networks/{network} HTTP/1.1
Host: api-gw-service-nmn.local

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/sls/v1/networks/{network}

```

```python
import requests

r = requests.delete('https://api-gw-service-nmn.local/apis/sls/v1/networks/{network}')

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/sls/v1/networks/{network}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /networks/{network}`

*Delete the named network*

Delete the specific network from SLS.

<h3 id="delete__networks_{network}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|network|path|string|true|The network to look up or alter.|

<h3 id="delete__networks_{network}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK. Network removed|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Network not found|None|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_versionResponse">versionResponse</h2>
<!-- backwards compatibility -->
<a id="schemaversionresponse"></a>
<a id="schema_versionResponse"></a>
<a id="tocSversionresponse"></a>
<a id="tocsversionresponse"></a>

```json
{
  "counter": 0,
  "last_updated": "2019-08-24T14:15:22Z"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|counter|integer|false|none|A monotonically increasing counter that increases every time a change is made to SLS|
|last_updated|string(date-time)|false|none|An ISO-8601 datetime representing when a change was last made to SLS|

<h2 id="tocS_network">network</h2>
<!-- backwards compatibility -->
<a id="schemanetwork"></a>
<a id="schema_network"></a>
<a id="tocSnetwork"></a>
<a id="tocsnetwork"></a>

```json
{
  "Name": "HSN",
  "FullName": "High Speed Network",
  "IPRanges": [
    "string"
  ],
  "Type": "slingshot10",
  "LastUpdated": 0,
  "LastUpdatedTime": "string",
  "ExtraProperties": {
    "CIDR": "10.253.0.0/16",
    "VlanRange": [
      0
    ],
    "MTU": 9000,
    "Subnets": [
      {
        "Name": "cabinet_1008_hsn\"",
        "FullName": "Cabinet 1008 HSN",
        "CIDR": "10.253.0.0/16",
        "VlanID": 60,
        "Gateway": "192.168.0.1",
        "DHCPStart": "192.168.0.1",
        "DHCPEnd": "192.168.0.1",
        "IPReservations": [
          {
            "IPAddress": "192.168.0.1",
            "Name": "S3",
            "Aliases": [
              "rgw-vip.local"
            ],
            "Comment": "string"
          }
        ],
        "Comment": "string"
      }
    ],
    "Comment": "string"
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|true|none|none|
|FullName|string|false|none|none|
|IPRanges|[[network_ip_range](#schemanetwork_ip_range)]|true|none|none|
|Type|[network_type](#schemanetwork_type)|true|none|none|
|LastUpdated|[last_updated](#schemalast_updated)|false|none|The unix timestamp of the last time this entry was created or updated|
|LastUpdatedTime|[last_updated_time](#schemalast_updated_time)|false|none|The human-readable time this object was last created or updated.|
|ExtraProperties|[network_extra_properties](#schemanetwork_extra_properties)|false|none|none|

<h2 id="tocS_network_ip_range">network_ip_range</h2>
<!-- backwards compatibility -->
<a id="schemanetwork_ip_range"></a>
<a id="schema_network_ip_range"></a>
<a id="tocSnetwork_ip_range"></a>
<a id="tocsnetwork_ip_range"></a>

```json
"string"

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|none|

<h2 id="tocS_network_type">network_type</h2>
<!-- backwards compatibility -->
<a id="schemanetwork_type"></a>
<a id="schema_network_type"></a>
<a id="tocSnetwork_type"></a>
<a id="tocsnetwork_type"></a>

```json
"slingshot10"

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|none|

<h2 id="tocS_network_extra_properties">network_extra_properties</h2>
<!-- backwards compatibility -->
<a id="schemanetwork_extra_properties"></a>
<a id="schema_network_extra_properties"></a>
<a id="tocSnetwork_extra_properties"></a>
<a id="tocsnetwork_extra_properties"></a>

```json
{
  "CIDR": "10.253.0.0/16",
  "VlanRange": [
    0
  ],
  "MTU": 9000,
  "Subnets": [
    {
      "Name": "cabinet_1008_hsn\"",
      "FullName": "Cabinet 1008 HSN",
      "CIDR": "10.253.0.0/16",
      "VlanID": 60,
      "Gateway": "192.168.0.1",
      "DHCPStart": "192.168.0.1",
      "DHCPEnd": "192.168.0.1",
      "IPReservations": [
        {
          "IPAddress": "192.168.0.1",
          "Name": "S3",
          "Aliases": [
            "rgw-vip.local"
          ],
          "Comment": "string"
        }
      ],
      "Comment": "string"
    }
  ],
  "Comment": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|CIDR|string|false|none|none|
|VlanRange|[integer]|false|none|none|
|MTU|integer|false|none|none|
|Subnets|[[network_ipv4_subnet](#schemanetwork_ipv4_subnet)]|false|none|none|
|Comment|string|false|none|none|

<h2 id="tocS_network_ipv4_subnet">network_ipv4_subnet</h2>
<!-- backwards compatibility -->
<a id="schemanetwork_ipv4_subnet"></a>
<a id="schema_network_ipv4_subnet"></a>
<a id="tocSnetwork_ipv4_subnet"></a>
<a id="tocsnetwork_ipv4_subnet"></a>

```json
{
  "Name": "cabinet_1008_hsn\"",
  "FullName": "Cabinet 1008 HSN",
  "CIDR": "10.253.0.0/16",
  "VlanID": 60,
  "Gateway": "192.168.0.1",
  "DHCPStart": "192.168.0.1",
  "DHCPEnd": "192.168.0.1",
  "IPReservations": [
    {
      "IPAddress": "192.168.0.1",
      "Name": "S3",
      "Aliases": [
        "rgw-vip.local"
      ],
      "Comment": "string"
    }
  ],
  "Comment": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Name|string|true|none|none|
|FullName|string|false|none|none|
|CIDR|string|true|none|none|
|VlanID|integer|true|none|none|
|Gateway|string(ipv4)|false|none|none|
|DHCPStart|string(ipv4)|false|none|none|
|DHCPEnd|string(ipv4)|false|none|none|
|IPReservations|[[network_ip_reservation](#schemanetwork_ip_reservation)]|false|none|none|
|Comment|string|false|none|none|

<h2 id="tocS_network_ip_reservation">network_ip_reservation</h2>
<!-- backwards compatibility -->
<a id="schemanetwork_ip_reservation"></a>
<a id="schema_network_ip_reservation"></a>
<a id="tocSnetwork_ip_reservation"></a>
<a id="tocsnetwork_ip_reservation"></a>

```json
{
  "IPAddress": "192.168.0.1",
  "Name": "S3",
  "Aliases": [
    "rgw-vip.local"
  ],
  "Comment": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|IPAddress|string(ipv4)|true|none|none|
|Name|string|true|none|none|
|Aliases|[string]|false|none|none|
|Comment|string|false|none|none|

<h2 id="tocS_xname">xname</h2>
<!-- backwards compatibility -->
<a id="schemaxname"></a>
<a id="schema_xname"></a>
<a id="tocSxname"></a>
<a id="tocsxname"></a>

```json
"x0c0s0b0"

```

The xname of this piece of hardware

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The xname of this piece of hardware|

<h2 id="tocS_hwtype">hwtype</h2>
<!-- backwards compatibility -->
<a id="schemahwtype"></a>
<a id="schema_hwtype"></a>
<a id="tocShwtype"></a>
<a id="tocshwtype"></a>

```json
"comptype_ncard"

```

The type of this piece of hardware.  This is an optional hint during upload; it will be ignored if it does not match the xname

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The type of this piece of hardware.  This is an optional hint during upload; it will be ignored if it does not match the xname|

<h2 id="tocS_hwclass">hwclass</h2>
<!-- backwards compatibility -->
<a id="schemahwclass"></a>
<a id="schema_hwclass"></a>
<a id="tocShwclass"></a>
<a id="tocshwclass"></a>

```json
"Mountain"

```

The hardware class.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The hardware class.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|River|
|*anonymous*|Mountain|
|*anonymous*|Hill|

<h2 id="tocS_last_updated">last_updated</h2>
<!-- backwards compatibility -->
<a id="schemalast_updated"></a>
<a id="schema_last_updated"></a>
<a id="tocSlast_updated"></a>
<a id="tocslast_updated"></a>

```json
0

```

The unix timestamp of the last time this entry was created or updated

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|integer|false|read-only|The unix timestamp of the last time this entry was created or updated|

<h2 id="tocS_last_updated_time">last_updated_time</h2>
<!-- backwards compatibility -->
<a id="schemalast_updated_time"></a>
<a id="schema_last_updated_time"></a>
<a id="tocSlast_updated_time"></a>
<a id="tocslast_updated_time"></a>

```json
"string"

```

The human-readable time this object was last created or updated.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|read-only|The human-readable time this object was last created or updated.|

<h2 id="tocS_hardware_put">hardware_put</h2>
<!-- backwards compatibility -->
<a id="schemahardware_put"></a>
<a id="schema_hardware_put"></a>
<a id="tocShardware_put"></a>
<a id="tocshardware_put"></a>

```json
{
  "Class": "Mountain",
  "ExtraProperties": {
    "Object": [
      "x0c0s0b0"
    ]
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Class|[hwclass](#schemahwclass)|true|none|The hardware class.|
|ExtraProperties|[hardware_extra_properties](#schemahardware_extra_properties)|false|none|none|

<h2 id="tocS_hardware_post">hardware_post</h2>
<!-- backwards compatibility -->
<a id="schemahardware_post"></a>
<a id="schema_hardware_post"></a>
<a id="tocShardware_post"></a>
<a id="tocshardware_post"></a>

```json
{
  "Xname": "x0c0s0b0",
  "Class": "Mountain",
  "ExtraProperties": {
    "Object": [
      "x0c0s0b0"
    ]
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Xname|[xname](#schemaxname)|true|none|The xname of this piece of hardware|
|Class|[hwclass](#schemahwclass)|true|none|The hardware class.|
|ExtraProperties|[hardware_extra_properties](#schemahardware_extra_properties)|false|none|none|

<h2 id="tocS_hardware">hardware</h2>
<!-- backwards compatibility -->
<a id="schemahardware"></a>
<a id="schema_hardware"></a>
<a id="tocShardware"></a>
<a id="tocshardware"></a>

```json
{
  "Parent": "x0c0s0",
  "Xname": "x0c0s0b0",
  "Children": [
    "x0c0s0b0n0"
  ],
  "Type": "comptype_ncard",
  "TypeString": "string",
  "Class": "Mountain",
  "LastUpdated": 0,
  "LastUpdatedTime": "string",
  "ExtraProperties": {
    "Object": [
      "x0c0s0b0"
    ]
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Parent|string|false|read-only|The xname of the parent of this piece of hardware|
|Xname|[xname](#schemaxname)|true|none|The xname of this piece of hardware|
|Children|[string]|false|read-only|none|
|Type|string|false|read-only|The type of this piece of hardware.  This is an optional hint during upload; it will be ignored if it does not match the xname|
|TypeString|string|false|read-only|none|
|Class|[hwclass](#schemahwclass)|true|none|The hardware class.|
|LastUpdated|[last_updated](#schemalast_updated)|false|none|The unix timestamp of the last time this entry was created or updated|
|LastUpdatedTime|[last_updated_time](#schemalast_updated_time)|false|none|The human-readable time this object was last created or updated.|
|ExtraProperties|[hardware_extra_properties](#schemahardware_extra_properties)|false|none|none|

<h2 id="tocS_hardware_bmc">hardware_bmc</h2>
<!-- backwards compatibility -->
<a id="schemahardware_bmc"></a>
<a id="schema_hardware_bmc"></a>
<a id="tocShardware_bmc"></a>
<a id="tocshardware_bmc"></a>

```json
{
  "IP6addr": "DHCPv6",
  "IP4addr": "10.1.1.1",
  "Username": "user_name",
  "Password": "vault://tok"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|IP6addr|string|true|none|The ipv6 address that should be assigned to this BMC, or "DHCPv6".  If omitted, "DHCPv6" is assumed.|
|IP4addr|string|true|none|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|Username|string|false|none|The username that should be used to access the device (or be assigned to the device)|
|Password|string|false|none|The password that should be used to access the device (or be assigned to the device)|

<h2 id="tocS_hardware_ip_and_creds_optional">hardware_ip_and_creds_optional</h2>
<!-- backwards compatibility -->
<a id="schemahardware_ip_and_creds_optional"></a>
<a id="schema_hardware_ip_and_creds_optional"></a>
<a id="tocShardware_ip_and_creds_optional"></a>
<a id="tocshardware_ip_and_creds_optional"></a>

```json
{
  "IP6addr": "DHCPv6",
  "IP4addr": "10.1.1.1",
  "Username": "user_name",
  "Password": "vault://tok"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|IP6addr|string|false|none|The ipv6 address that should be assigned to this BMC, or "DHCPv6".  If omitted, "DHCPv6" is assumed.|
|IP4addr|string|false|none|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|Username|string|false|none|The username that should be used to access the device (or be assigned to the device)|
|Password|string|false|none|The password that should be used to access the device (or be assigned to the device)|

<h2 id="tocS_hardware_powered_device">hardware_powered_device</h2>
<!-- backwards compatibility -->
<a id="schemahardware_powered_device"></a>
<a id="schema_hardware_powered_device"></a>
<a id="tocShardware_powered_device"></a>
<a id="tocshardware_powered_device"></a>

```json
{
  "PowerConnector": [
    "x0c0s0b0"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|PowerConnector|[[xname](#schemaxname)]|true|none|An array of xnames, where each xname has type==*_pwr_connector.  Empty for Mountain switch cards|

<h2 id="tocS_hardware_comptype_hsn_connector">hardware_comptype_hsn_connector</h2>
<!-- backwards compatibility -->
<a id="schemahardware_comptype_hsn_connector"></a>
<a id="schema_hardware_comptype_hsn_connector"></a>
<a id="tocShardware_comptype_hsn_connector"></a>
<a id="tocshardware_comptype_hsn_connector"></a>

```json
{
  "Object": [
    "x0c0s0b0"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Object|[[xname](#schemaxname)]|true|none|An array of xnames that this connector is connected to.  All xnames should have type==comptype_hsn_connector_port|

<h2 id="tocS_hardware_pwr_connector">hardware_pwr_connector</h2>
<!-- backwards compatibility -->
<a id="schemahardware_pwr_connector"></a>
<a id="schema_hardware_pwr_connector"></a>
<a id="tocShardware_pwr_connector"></a>
<a id="tocshardware_pwr_connector"></a>

```json
{
  "PoweredBy": "x0c0s0b0"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|PoweredBy|[xname](#schemaxname)|true|none|The hardware this cable is connected to.  May be any type of object.  Parent is excluded|

<h2 id="tocS_hardware_mgmt_switch_connector">hardware_mgmt_switch_connector</h2>
<!-- backwards compatibility -->
<a id="schemahardware_mgmt_switch_connector"></a>
<a id="schema_hardware_mgmt_switch_connector"></a>
<a id="tocShardware_mgmt_switch_connector"></a>
<a id="tocshardware_mgmt_switch_connector"></a>

```json
{
  "NodeNics": [
    "x0c0s0b0"
  ],
  "VendorName": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|NodeNics|[[xname](#schemaxname)]|true|none|An array of Xnames that the hardware_mgmt_switch_connector is connected to.  Excludes the parent.|
|VendorName|string|false|none|The vendor-assigned name for this port, as it appears in the switch management software.  Typically this is something like "GigabitEthernet 1/31" (berkley-style names), but may be any string.|

<h2 id="tocS_hardware_comptype_rtr_bmc">hardware_comptype_rtr_bmc</h2>
<!-- backwards compatibility -->
<a id="schemahardware_comptype_rtr_bmc"></a>
<a id="schema_hardware_comptype_rtr_bmc"></a>
<a id="tocShardware_comptype_rtr_bmc"></a>
<a id="tocshardware_comptype_rtr_bmc"></a>

```json
{
  "IP6addr": "DHCPv6",
  "IP4addr": "10.1.1.1",
  "Username": "user_name",
  "Password": "vault://tok"
}

```

### Properties

*None*

<h2 id="tocS_hardware_comptype_bmc_nic">hardware_comptype_bmc_nic</h2>
<!-- backwards compatibility -->
<a id="schemahardware_comptype_bmc_nic"></a>
<a id="schema_hardware_comptype_bmc_nic"></a>
<a id="tocShardware_comptype_bmc_nic"></a>
<a id="tocshardware_comptype_bmc_nic"></a>

```json
{
  "Networks": [
    "x0c0s0b0"
  ],
  "Peers": [
    "x0c0s0b0"
  ]
}

```

### Properties

*None*

<h2 id="tocS_hardware_nic">hardware_nic</h2>
<!-- backwards compatibility -->
<a id="schemahardware_nic"></a>
<a id="schema_hardware_nic"></a>
<a id="tocShardware_nic"></a>
<a id="tocshardware_nic"></a>

```json
{
  "Networks": [
    "x0c0s0b0"
  ],
  "Peers": [
    "x0c0s0b0"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Networks|[[xname](#schemaxname)]|true|none|An array of network names that this nic is connected to|
|Peers|[[xname](#schemaxname)]|true|none|An array of xnames this nic is connected directly to.  These ideally connector xnames, not switches|

<h2 id="tocS_hardware_comptype_rtmod">hardware_comptype_rtmod</h2>
<!-- backwards compatibility -->
<a id="schemahardware_comptype_rtmod"></a>
<a id="schema_hardware_comptype_rtmod"></a>
<a id="tocShardware_comptype_rtmod"></a>
<a id="tocshardware_comptype_rtmod"></a>

```json
{
  "PowerConnector": [
    "x0c0s0b0"
  ]
}

```

### Properties

*None*

<h2 id="tocS_hardware_comptype_mgmt_switch">hardware_comptype_mgmt_switch</h2>
<!-- backwards compatibility -->
<a id="schemahardware_comptype_mgmt_switch"></a>
<a id="schema_hardware_comptype_mgmt_switch"></a>
<a id="tocShardware_comptype_mgmt_switch"></a>
<a id="tocshardware_comptype_mgmt_switch"></a>

```json
{
  "PowerConnector": [
    "x0c0s0b0"
  ]
}

```

### Properties

*None*

<h2 id="tocS_hardware_comptype_compmod">hardware_comptype_compmod</h2>
<!-- backwards compatibility -->
<a id="schemahardware_comptype_compmod"></a>
<a id="schema_hardware_comptype_compmod"></a>
<a id="tocShardware_comptype_compmod"></a>
<a id="tocshardware_comptype_compmod"></a>

```json
{
  "PowerConnector": [
    "x0c0s0b0"
  ]
}

```

### Properties

*None*

<h2 id="tocS_hardware_comptype_cab_pdu">hardware_comptype_cab_pdu</h2>
<!-- backwards compatibility -->
<a id="schemahardware_comptype_cab_pdu"></a>
<a id="schema_hardware_comptype_cab_pdu"></a>
<a id="tocShardware_comptype_cab_pdu"></a>
<a id="tocshardware_comptype_cab_pdu"></a>

```json
{
  "IP6addr": "DHCPv6",
  "IP4addr": "10.1.1.1",
  "Username": "user_name",
  "Password": "vault://tok"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|IP6addr|string|true|none|The ipv6 address that should be assigned to this BMC, or "DHCPv6". If omitted, "DHCPv6" is assumed.|
|IP4addr|string|true|none|The ipv4 address that should be assigned to this BMC, or "DHCPv4".  If omitted, "DHCPv4" is assumed.|
|Username|string|true|none|The username that should be used to access the device (or be assigned to the device)|
|Password|string(password)|true|none|The password that should be used to access the device|

<h2 id="tocS_hardware_comptype_node">hardware_comptype_node</h2>
<!-- backwards compatibility -->
<a id="schemahardware_comptype_node"></a>
<a id="schema_hardware_comptype_node"></a>
<a id="tocShardware_comptype_node"></a>
<a id="tocshardware_comptype_node"></a>

```json
{
  "NodeType": "Compute",
  "nid": "2"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|NodeType|string|true|none|The role type assigned to this node.|
|nid|integer|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|NodeType|Compute|
|NodeType|System|
|NodeType|Application|
|NodeType|Storage|
|NodeType|Management|

<h2 id="tocS_hardware_comptype_nodecard">hardware_comptype_nodecard</h2>
<!-- backwards compatibility -->
<a id="schemahardware_comptype_nodecard"></a>
<a id="schema_hardware_comptype_nodecard"></a>
<a id="tocShardware_comptype_nodecard"></a>
<a id="tocshardware_comptype_nodecard"></a>

```json
{
  "IP6addr": "DHCPv6",
  "IP4addr": "10.1.1.1",
  "Username": "user_name",
  "Password": "vault://tok"
}

```

### Properties

*None*

<h2 id="tocS_hardware_extra_properties">hardware_extra_properties</h2>
<!-- backwards compatibility -->
<a id="schemahardware_extra_properties"></a>
<a id="schema_hardware_extra_properties"></a>
<a id="tocShardware_extra_properties"></a>
<a id="tocshardware_extra_properties"></a>

```json
{
  "Object": [
    "x0c0s0b0"
  ]
}

```

### Properties

oneOf

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_comptype_hsn_connector](#schemahardware_comptype_hsn_connector)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_pwr_connector](#schemahardware_pwr_connector)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_mgmt_switch_connector](#schemahardware_mgmt_switch_connector)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_comptype_rtr_bmc](#schemahardware_comptype_rtr_bmc)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_comptype_bmc_nic](#schemahardware_comptype_bmc_nic)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_nic](#schemahardware_nic)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_comptype_rtmod](#schemahardware_comptype_rtmod)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_comptype_mgmt_switch](#schemahardware_comptype_mgmt_switch)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_comptype_compmod](#schemahardware_comptype_compmod)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_comptype_cab_pdu](#schemahardware_comptype_cab_pdu)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_comptype_node](#schemahardware_comptype_node)|false|none|none|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[hardware_comptype_nodecard](#schemahardware_comptype_nodecard)|false|none|none|

<h2 id="tocS_slsState">slsState</h2>
<!-- backwards compatibility -->
<a id="schemaslsstate"></a>
<a id="schema_slsState"></a>
<a id="tocSslsstate"></a>
<a id="tocsslsstate"></a>

```json
{
  "Hardware": {
    "property1": {
      "Parent": "x0c0s0",
      "Xname": "x0c0s0b0",
      "Children": [
        "x0c0s0b0n0"
      ],
      "Type": "comptype_ncard",
      "TypeString": "string",
      "Class": "Mountain",
      "LastUpdated": 0,
      "LastUpdatedTime": "string",
      "ExtraProperties": {
        "Object": [
          "x0c0s0b0"
        ]
      }
    },
    "property2": {
      "Parent": "x0c0s0",
      "Xname": "x0c0s0b0",
      "Children": [
        "x0c0s0b0n0"
      ],
      "Type": "comptype_ncard",
      "TypeString": "string",
      "Class": "Mountain",
      "LastUpdated": 0,
      "LastUpdatedTime": "string",
      "ExtraProperties": {
        "Object": [
          "x0c0s0b0"
        ]
      }
    }
  },
  "Networks": {
    "property1": {
      "Name": "HSN",
      "FullName": "High Speed Network",
      "IPRanges": [
        "string"
      ],
      "Type": "slingshot10",
      "LastUpdated": 0,
      "LastUpdatedTime": "string",
      "ExtraProperties": {
        "CIDR": "10.253.0.0/16",
        "VlanRange": [
          0
        ],
        "MTU": 9000,
        "Subnets": [
          {
            "Name": "cabinet_1008_hsn\"",
            "FullName": "Cabinet 1008 HSN",
            "CIDR": "10.253.0.0/16",
            "VlanID": 60,
            "Gateway": "192.168.0.1",
            "DHCPStart": "192.168.0.1",
            "DHCPEnd": "192.168.0.1",
            "IPReservations": [
              {
                "IPAddress": "192.168.0.1",
                "Name": "S3",
                "Aliases": [
                  "rgw-vip.local"
                ],
                "Comment": "string"
              }
            ],
            "Comment": "string"
          }
        ],
        "Comment": "string"
      }
    },
    "property2": {
      "Name": "HSN",
      "FullName": "High Speed Network",
      "IPRanges": [
        "string"
      ],
      "Type": "slingshot10",
      "LastUpdated": 0,
      "LastUpdatedTime": "string",
      "ExtraProperties": {
        "CIDR": "10.253.0.0/16",
        "VlanRange": [
          0
        ],
        "MTU": 9000,
        "Subnets": [
          {
            "Name": "cabinet_1008_hsn\"",
            "FullName": "Cabinet 1008 HSN",
            "CIDR": "10.253.0.0/16",
            "VlanID": 60,
            "Gateway": "192.168.0.1",
            "DHCPStart": "192.168.0.1",
            "DHCPEnd": "192.168.0.1",
            "IPReservations": [
              {
                "IPAddress": "192.168.0.1",
                "Name": "S3",
                "Aliases": [
                  "rgw-vip.local"
                ],
                "Comment": "string"
              }
            ],
            "Comment": "string"
          }
        ],
        "Comment": "string"
      }
    }
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Hardware|object|false|none|none|
|» **additionalProperties**|[hardware](#schemahardware)|false|none|none|
|Networks|object|false|none|none|
|» **additionalProperties**|[network](#schemanetwork)|false|none|none|

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

