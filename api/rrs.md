<!-- Generator: Widdershins v4.0.1 -->

<h1 id="rack-resiliency-service">Rack Resiliency Service v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The Rack Resiliency Service (RRS) provides a set of APIs to manage Rack Level resiliency. It queries the Kubernetes cluster to provide aggregated zone information and detailed critical service status. It gathers node details across various zones and presents both high-level summaries and in-depth information for zones and critical services.
## Resources

  ### GET /zones
    Retrieve aggregated zone configuration showing Kubernetes_Topology_Zones and CEPH_Zones including:
      - Management_Master_Nodes
      - Management_Worker_Nodes
      - Management_Storage_Nodes

    Alternatively, if zones are not configured, one of the following informational messages is returned:
      - "No K8s Topology/Ceph Zones configured"
      - "No Ceph zones configured"
      - "No K8s topology zones configured"

  ### GET /zones/{zone_name}
    Retrieve detailed information for a specific zone including:
      - Zone_Name
      - Management_Master_Nodes
      - Management_Worker_Nodes
      - Management_Storage_Nodes
      - Node status and OSD information

  ### GET /criticalservices
    Retrieve a list of critical services grouped by namespace

  ### GET /criticalservices/{critical-service-name}
    Retrieve a summarized view of a specific critical service (without pod details). The response includes:
      - configured_instances
      - name
      - namespace
      - type

  ### PATCH /criticalservices
    Update the critical services configuration based on provided input. This endpoint
    modifies which critical services are monitored.

  ### GET /criticalservices/status
    Retrieve the status of all critical services including service status and distribution details.
    Each service object may include:
      - Service Name
      - status
      - balanced: indicates whether the service is properly distributed

  ### GET /criticalservices/status/{critical-service-name}
    Retrieve detailed status for a specific critical service including pod information.
    The response includes:
      - configured_instances
      - currently_running_instances
      - name
      - namespace
      - pods with name, node, status, and zone
      - type
      - status
      - balanced

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/rrs">https://api-gw-service-nmn.local/apis/rrs</a>

License: <a href="http://www.hpe.com/">Hewlett Packard Enterprise Development LP</a>

# Authentication

- HTTP Authentication, scheme: bearer 

<h1 id="rack-resiliency-service-zones">zones</h1>

Retrieve aggregated and detailed information about zones including node types and counts.

## getZones

<a id="opIdgetZones"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/zones HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/rrs/zones \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/zones', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/rrs/zones", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /zones`

*Get Zones Configuration*

Returns an object with a property "Zones" that is an array of zones. Each zone contains:

  - Zone_Name: the name of the zone
  - Kubernetes_Topology_Zone: contains:
      Management_Master_Nodes: list of master node names
      Management_Worker_Nodes: list of worker node names
  - CEPH_Zone: contains:
      Management_Storage_Nodes: list of storage node names

> Example responses

> Zones configuration

```json
{
  "Zones": [
    {
      "Zone_Name": "cscs-rack-x3001",
      "Kubernetes_Topology_Zone": {
        "Management_Master_Nodes": [
          "ncn-m002"
        ],
        "Management_Worker_Nodes": [
          "ncn-w002",
          "ncn-w004"
        ]
      },
      "CEPH_Zone": {
        "Management_Storage_Nodes": [
          "ncn-s004",
          "ncn-s003"
        ]
      }
    },
    {
      "Zone_Name": "cscs-rack-x3002",
      "Kubernetes_Topology_Zone": {
        "Management_Master_Nodes": [
          "ncn-m003"
        ],
        "Management_Worker_Nodes": [
          "ncn-w003"
        ]
      },
      "CEPH_Zone": {
        "Management_Storage_Nodes": [
          "ncn-s005",
          "ncn-s002"
        ]
      }
    },
    {
      "Zone_Name": "cscs-rack-x3000",
      "Kubernetes_Topology_Zone": {
        "Management_Master_Nodes": [
          "ncn-m001"
        ],
        "Management_Worker_Nodes": [
          "ncn-w001",
          "ncn-w005"
        ]
      },
      "CEPH_Zone": {
        "Management_Storage_Nodes": [
          "ncn-s001"
        ]
      }
    }
  ]
}
```

> 404 Response

```json
{
  "detail": "string",
  "errors": {},
  "instance": "http://example.com",
  "status": 400,
  "title": "string",
  "type": "about:blank"
}
```

<h3 id="getzones-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zones configuration|[ZonesResponse](#schemazonesresponse)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## getZoneDetails

<a id="opIdgetZoneDetails"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/zones/{zone_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/rrs/zones/{zone_name} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/zones/{zone_name}', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/rrs/zones/{zone_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /zones/{zone_name}`

*Get Detailed Zone Information*

Returns detailed information for a specific zone. The response includes:

  - Zone_Name: the name of the zone
  - Management_Master: an object with Count, Type, and Nodes (array of node objects with name and status)
  - Management_Worker: an object with Count, Type, and Nodes (array of node objects with name and status)
  - Management_Storage: an object with Count, Type, and Nodes (array of node objects with name, status, and osds)

<h3 id="getzonedetails-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|zone_name|path|[ZoneName](#schemazonename)|true|The name of the zone|

> Example responses

> Detailed zone information

```json
{
  "Zone_Name": "cscs-rack-x3001",
  "Management_Master": {
    "Count": 1,
    "Type": "Kubernetes_Topology_Zone",
    "Nodes": [
      {
        "name": "ncn-m002",
        "status": "Ready"
      }
    ]
  },
  "Management_Worker": {
    "Count": 2,
    "Type": "Kubernetes_Topology_Zone",
    "Nodes": [
      {
        "name": "ncn-w002",
        "status": "Ready"
      },
      {
        "name": "ncn-w004",
        "status": "Ready"
      }
    ]
  },
  "Management_Storage": {
    "Count": 2,
    "Type": "CEPH_Zone",
    "Nodes": [
      {
        "name": "ncn-s004",
        "status": "NotReady",
        "osds": {
          "down": [
            "osd.0",
            "osd.5"
          ]
        }
      },
      {
        "name": "ncn-s003",
        "status": "Ready",
        "osds": {
          "up": [
            "osd.4",
            "osd.9",
            "osd.12",
            "osd.15",
            "osd.18",
            "osd.21",
            "osd.24",
            "osd.27"
          ]
        }
      }
    ]
  }
}
```

> 400 Response

```json
{
  "detail": "string",
  "errors": {},
  "instance": "http://example.com",
  "status": 400,
  "title": "string",
  "type": "about:blank"
}
```

<h3 id="getzonedetails-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Detailed zone information|[ZoneDetailResponse](#schemazonedetailresponse)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

<h1 id="rack-resiliency-service-criticalservices">criticalservices</h1>

Interact with critical service configurations, summaries, and runtime statuses.

## getCriticalServices

<a id="opIdgetCriticalServices"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/criticalservices HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/rrs/criticalservices \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/criticalservices', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/rrs/criticalservices", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /criticalservices`

*Get Critical Services*

Returns a list of critical services grouped by namespace. The response includes a critical_services property containing namespaces with arrays of service objects including:

  - name: the name of the service
  - type: the service type (Deployment, StatefulSet)

> Example responses

> List of critical services grouped by namespace

```json
{
  "critical_services": {
    "namespace": {
      "services": [
        {
          "name": "cray-dns-powerdns",
          "type": "Deployment"
        },
        {
          "name": "cray-hbtd",
          "type": "Deployment"
        },
        {
          "name": "cray-hmnfd",
          "type": "Deployment"
        },
        {
          "name": "cray-keycloak",
          "type": "StatefulSet"
        },
        {
          "name": "cray-sls-postgres",
          "type": "StatefulSet"
        }
      ],
      "spire": [
        {
          "name": "cray-spire-server",
          "type": "StatefulSet"
        }
      ],
      "rack-resiliency": [
        {
          "name": "k8s-zone-api",
          "type": "Deployment"
        }
      ]
    }
  }
}
```

> 404 Response

```json
{
  "detail": "string",
  "errors": {},
  "instance": "http://example.com",
  "status": 400,
  "title": "string",
  "type": "about:blank"
}
```

<h3 id="getcriticalservices-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|List of critical services grouped by namespace|[CriticalServicesListSchema](#schemacriticalserviceslistschema)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patchCriticalServices

<a id="opIdpatchCriticalServices"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/rrs/criticalservices HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/rrs/criticalservices \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/rrs/criticalservices', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/rrs/criticalservices", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /criticalservices`

*Update Critical Services ConfigMap*

Updates the critical services configuration. The request body should contain critical services mapped by service name to their configuration details.

> Body parameter

```json
{
  "critical_services": {
    "property1": {
      "namespace": "rack-resiliency",
      "type": "Deployment"
    },
    "property2": {
      "namespace": "rack-resiliency",
      "type": "Deployment"
    }
  }
}
```

<h3 id="patchcriticalservices-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[CriticalServiceCmStaticType](#schemacriticalservicecmstatictype)|true|Critical services configuration update|

> Example responses

> Critical Services Updated Successfully

```json
{
  "Update": "Successful",
  "Successfully_Added_Services": [
    "k8s-zone-api",
    "kube-multus-ds"
  ],
  "Already_Existing_Services": [
    "coredns",
    "kube-proxy"
  ]
}
```

> 400 Response

```json
{
  "detail": "string",
  "errors": {},
  "instance": "http://example.com",
  "status": 400,
  "title": "string",
  "type": "about:blank"
}
```

<h3 id="patchcriticalservices-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Critical Services Updated Successfully|[CriticalServiceUpdateSchema](#schemacriticalserviceupdateschema)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## getCriticalServiceDetails

<a id="opIdgetCriticalServiceDetails"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/criticalservices/{critical_service_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/rrs/criticalservices/{critical_service_name} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/criticalservices/{critical_service_name}', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/rrs/criticalservices/{critical_service_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /criticalservices/{critical_service_name}`

*Get Critical Service Details (Summarized)*

Returns a summarized view of a specific critical service. The response includes:

  - name: string
  - namespace: string
  - type: string
  - configured_instances: number

<h3 id="getcriticalservicedetails-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|critical_service_name|path|[ServiceName](#schemaservicename)|true|The name of the critical service|

> Example responses

> Summarized critical service information

```json
{
  "critical_service": {
    "name": "cray-hbtd",
    "namespace": "services",
    "type": "Deployment",
    "configured_instances": 3
  }
}
```

> 400 Response

```json
{
  "detail": "string",
  "errors": {},
  "instance": "http://example.com",
  "status": 400,
  "title": "string",
  "type": "about:blank"
}
```

<h3 id="getcriticalservicedetails-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Summarized critical service information|[CriticalServiceDescribeSchema](#schemacriticalservicedescribeschema)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## getAllCriticalServicesStatus

<a id="opIdgetAllCriticalServicesStatus"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/criticalservices/status HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/rrs/criticalservices/status \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/criticalservices/status', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/rrs/criticalservices/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /criticalservices/status`

*Get Critical Services Status*

Returns the status of all critical services with distribution details. Response provides namespaces containing services with their status information including:

  - name: the name of the critical service
  - type: the service type (Deployment, StatefulSet)
  - status: the current status (e.g., Configured, PartiallyConfigured)
  - balanced: indicates whether the service is properly distributed across zones

> Example responses

> Critical services status retrieved successfully

```json
{
  "critical_services": {
    "namespace": {
      "services": [
        {
          "name": "cray-dns-powerdns",
          "type": "Deployment",
          "status": "Configured",
          "balanced": "true"
        },
        {
          "name": "cray-hbtd",
          "type": "Deployment",
          "status": "Configured",
          "balanced": "true"
        },
        {
          "name": "cray-hmnfd",
          "type": "Deployment",
          "status": "Configured",
          "balanced": "true"
        },
        {
          "name": "cray-keycloak",
          "type": "StatefulSet",
          "status": "Configured",
          "balanced": "true"
        },
        {
          "name": "cray-sls-postgres",
          "type": "StatefulSet",
          "status": "PartiallyConfigured",
          "balanced": "true"
        }
      ],
      "spire": [
        {
          "name": "cray-spire-server",
          "type": "StatefulSet",
          "status": "Configured",
          "balanced": "true"
        }
      ],
      "kube-system": [
        {
          "name": "coredns",
          "type": "Deployment",
          "status": "Configured",
          "balanced": "true"
        }
      ],
      "rack-resiliency": [
        {
          "name": "k8s-zone-api",
          "type": "Deployment",
          "status": "Configured",
          "balanced": "true"
        }
      ]
    }
  }
}
```

> 404 Response

```json
{
  "detail": "string",
  "errors": {},
  "instance": "http://example.com",
  "status": 400,
  "title": "string",
  "type": "about:blank"
}
```

<h3 id="getallcriticalservicesstatus-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Critical services status retrieved successfully|[CriticalServicesStatusListSchema](#schemacriticalservicesstatuslistschema)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## getCriticalServiceStatus

<a id="opIdgetCriticalServiceStatus"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/criticalservices/status/{critical_service_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/rrs/criticalservices/status/{critical_service_name} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/criticalservices/status/{critical_service_name}', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/rrs/criticalservices/status/{critical_service_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /criticalservices/status/{critical_service_name}`

*Get Critical Service Status by Name (Detailed)*

Returns detailed status for a specific critical service, including pod information. The response includes:

  - name: string
  - namespace: string
  - type: string
  - status: string
  - balanced: string
  - configured_instances: number
  - currently_running_instances: number
  - pods: array of pod objects with name, node, status, zone

<h3 id="getcriticalservicestatus-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|critical_service_name|path|[ServiceName](#schemaservicename)|true|The name of the critical service|

> Example responses

> Detailed critical service status retrieved successfully

```json
{
  "critical_service": {
    "name": "cray-hbtd",
    "namespace": "services",
    "type": "Deployment",
    "status": "Configured",
    "balanced": "true",
    "configured_instances": 3,
    "currently_running_instances": 3,
    "pods": [
      {
        "name": "cray-hbtd-6cbdbd6955-5xlfg",
        "status": "Running",
        "node": "ncn-w002",
        "zone": "cscs-rack-x3001"
      },
      {
        "name": "cray-hbtd-6cbdbd6955-jwzgq",
        "status": "Running",
        "node": "ncn-w003",
        "zone": "cscs-rack-x3002"
      },
      {
        "name": "cray-hbtd-6cbdbd6955-k6pkt",
        "status": "Running",
        "node": "ncn-w001",
        "zone": "cscs-rack-x3000"
      }
    ]
  }
}
```

> 400 Response

```json
{
  "detail": "string",
  "errors": {},
  "instance": "http://example.com",
  "status": 400,
  "title": "string",
  "type": "about:blank"
}
```

<h3 id="getcriticalservicestatus-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Detailed critical service status retrieved successfully|[CriticalServiceStatusDescribeSchema](#schemacriticalservicestatusdescribeschema)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not found|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

<h1 id="rack-resiliency-service-healthz">healthz</h1>

Kubernetes health check endpoints for service readiness and liveness probes.

## get_healthz_ready

<a id="opIdget_healthz_ready"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/healthz/ready HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/rrs/healthz/ready \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/healthz/ready', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/rrs/healthz/ready", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /healthz/ready`

*Retrieve RRS Readiness Probe*

Readiness probe for RRS. This is used by Kubernetes to determine if RRS is ready to accept requests

> Example responses

> 200 Response

```json
{}
```

<h3 id="get_healthz_ready-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|RRS is ready to accept requests|[EmptyDict](#schemaemptydict)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|RRS is not able to accept requests|[EmptyDict](#schemaemptydict)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_healthz_live

<a id="opIdget_healthz_live"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/healthz/live HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/rrs/healthz/live \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/healthz/live', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/rrs/healthz/live", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /healthz/live`

*Retrieve RRS Liveness Probe*

Liveness probe for RRS. This is used by Kubernetes to determine if RRS is responsive

> Example responses

> 200 Response

```json
{}
```

<h3 id="get_healthz_live-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|RRS is responsive|[EmptyDict](#schemaemptydict)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|RRS is not responsive|[EmptyDict](#schemaemptydict)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

<h1 id="rack-resiliency-service-version">version</h1>

API version information endpoint.

## getVersion

<a id="opIdgetVersion"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/version HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/rrs/version \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/version', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/rrs/version", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /version`

*Get RRS version*

Retrieve the version of the RRS Service

> Example responses

> 200 Response

```json
{
  "version": "1.0.0"
}
```

<h3 id="getversion-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|RRS Version|[VersionSchema](#schemaversionschema)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

# Schemas

<h2 id="tocS_ZoneName">ZoneName</h2>
<!-- backwards compatibility -->
<a id="schemazonename"></a>
<a id="schema_ZoneName"></a>
<a id="tocSzonename"></a>
<a id="tocszonename"></a>

```json
"string"

```

Unique identifier name for the zone

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Unique identifier name for the zone|

<h2 id="tocS_ZonesResponse">ZonesResponse</h2>
<!-- backwards compatibility -->
<a id="schemazonesresponse"></a>
<a id="schema_ZonesResponse"></a>
<a id="tocSzonesresponse"></a>
<a id="tocszonesresponse"></a>

```json
{
  "Zones": [
    {
      "Zone_Name": "string",
      "Kubernetes_Topology_Zone": {
        "Management_Master_Nodes": [
          "string"
        ],
        "Management_Worker_Nodes": [
          "string"
        ]
      },
      "CEPH_Zone": {
        "Management_Storage_Nodes": [
          "string"
        ]
      }
    }
  ]
}

```

Response containing all configured zones in the system with their associated node configurations

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Zones|[[ZoneItemSchema](#schemazoneitemschema)]|true|none|Array of zone configurations showing Kubernetes topology and CEPH zone details|

<h2 id="tocS_ZoneItemSchema">ZoneItemSchema</h2>
<!-- backwards compatibility -->
<a id="schemazoneitemschema"></a>
<a id="schema_ZoneItemSchema"></a>
<a id="tocSzoneitemschema"></a>
<a id="tocszoneitemschema"></a>

```json
{
  "Zone_Name": "string",
  "Kubernetes_Topology_Zone": {
    "Management_Master_Nodes": [
      "string"
    ],
    "Management_Worker_Nodes": [
      "string"
    ]
  },
  "CEPH_Zone": {
    "Management_Storage_Nodes": [
      "string"
    ]
  }
}

```

Configuration details for a single zone including Kubernetes topology and CEPH zone information

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Zone_Name|[ZoneName](#schemazonename)|true|none|Unique identifier name for the zone|
|Kubernetes_Topology_Zone|[KubernetesTopologyZoneSchema](#schemakubernetestopologyzoneschema)|false|none|Kubernetes topology zone configuration containing master and worker node assignments|
|CEPH_Zone|[CephZoneSchema](#schemacephzoneschema)|false|none|CEPH zone configuration containing storage node assignments|

<h2 id="tocS_KubernetesTopologyZoneSchema">KubernetesTopologyZoneSchema</h2>
<!-- backwards compatibility -->
<a id="schemakubernetestopologyzoneschema"></a>
<a id="schema_KubernetesTopologyZoneSchema"></a>
<a id="tocSkubernetestopologyzoneschema"></a>
<a id="tocskubernetestopologyzoneschema"></a>

```json
{
  "Management_Master_Nodes": [
    "string"
  ],
  "Management_Worker_Nodes": [
    "string"
  ]
}

```

Kubernetes topology zone configuration containing master and worker node assignments

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Management_Master_Nodes|[string]|false|none|List of Kubernetes master node names assigned to this zone|
|Management_Worker_Nodes|[string]|false|none|List of Kubernetes worker node names assigned to this zone|

<h2 id="tocS_CephZoneSchema">CephZoneSchema</h2>
<!-- backwards compatibility -->
<a id="schemacephzoneschema"></a>
<a id="schema_CephZoneSchema"></a>
<a id="tocScephzoneschema"></a>
<a id="tocscephzoneschema"></a>

```json
{
  "Management_Storage_Nodes": [
    "string"
  ]
}

```

CEPH zone configuration containing storage node assignments

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Management_Storage_Nodes|[string]|true|none|List of CEPH storage node names assigned to this zone|

<h2 id="tocS_ZoneDetailResponse">ZoneDetailResponse</h2>
<!-- backwards compatibility -->
<a id="schemazonedetailresponse"></a>
<a id="schema_ZoneDetailResponse"></a>
<a id="tocSzonedetailresponse"></a>
<a id="tocszonedetailresponse"></a>

```json
{
  "Zone_Name": "string",
  "Management_Master": {
    "Count": 1,
    "Type": "Kubernetes_Topology_Zone",
    "Nodes": [
      {
        "name": "string",
        "status": "Ready"
      }
    ]
  },
  "Management_Worker": {
    "Count": 1,
    "Type": "Kubernetes_Topology_Zone",
    "Nodes": [
      {
        "name": "string",
        "status": "Ready"
      }
    ]
  },
  "Management_Storage": {
    "Count": 1,
    "Type": "CEPH_Zone",
    "Nodes": [
      {
        "name": "string",
        "status": "Ready",
        "osds": {
          "up": [
            "string"
          ],
          "down": [
            "string"
          ]
        }
      }
    ]
  }
}

```

Detailed information about a specific zone including node counts, types, and individual node status

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Zone_Name|[ZoneName](#schemazonename)|true|none|Unique identifier name for the zone|
|Management_Master|[ManagementKubernetesSchema](#schemamanagementkubernetesschema)|false|none|Management information for Kubernetes nodes (master or worker) including count and individual node details|
|Management_Worker|[ManagementKubernetesSchema](#schemamanagementkubernetesschema)|false|none|Management information for Kubernetes nodes (master or worker) including count and individual node details|
|Management_Storage|[ManagementStorageSchema](#schemamanagementstorageschema)|false|none|Management information for CEPH storage nodes including count and individual node details with OSD information|

<h2 id="tocS_ManagementKubernetesSchema">ManagementKubernetesSchema</h2>
<!-- backwards compatibility -->
<a id="schemamanagementkubernetesschema"></a>
<a id="schema_ManagementKubernetesSchema"></a>
<a id="tocSmanagementkubernetesschema"></a>
<a id="tocsmanagementkubernetesschema"></a>

```json
{
  "Count": 1,
  "Type": "Kubernetes_Topology_Zone",
  "Nodes": [
    {
      "name": "string",
      "status": "Ready"
    }
  ]
}

```

Management information for Kubernetes nodes (master or worker) including count and individual node details

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Count|integer|true|none|Total number of nodes of this type in the zone|
|Type|string|true|none|Type classification indicating this is a Kubernetes topology zone|
|Nodes|[[NodeSchema](#schemanodeschema)]|true|none|Detailed information about each individual node|

#### Enumerated Values

|Property|Value|
|---|---|
|Type|Kubernetes_Topology_Zone|

<h2 id="tocS_ManagementStorageSchema">ManagementStorageSchema</h2>
<!-- backwards compatibility -->
<a id="schemamanagementstorageschema"></a>
<a id="schema_ManagementStorageSchema"></a>
<a id="tocSmanagementstorageschema"></a>
<a id="tocsmanagementstorageschema"></a>

```json
{
  "Count": 1,
  "Type": "CEPH_Zone",
  "Nodes": [
    {
      "name": "string",
      "status": "Ready",
      "osds": {
        "up": [
          "string"
        ],
        "down": [
          "string"
        ]
      }
    }
  ]
}

```

Management information for CEPH storage nodes including count and individual node details with OSD information

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Count|integer|true|none|Total number of storage nodes in the zone|
|Type|string|true|none|Type classification indicating this is a CEPH zone|
|Nodes|[[StorageNodeSchema](#schemastoragenodeschema)]|true|none|Detailed information about each storage node including OSD status|

#### Enumerated Values

|Property|Value|
|---|---|
|Type|CEPH_Zone|

<h2 id="tocS_NodeSchema">NodeSchema</h2>
<!-- backwards compatibility -->
<a id="schemanodeschema"></a>
<a id="schema_NodeSchema"></a>
<a id="tocSnodeschema"></a>
<a id="tocsnodeschema"></a>

```json
{
  "name": "string",
  "status": "Ready"
}

```

Basic node information including name and operational status

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|true|none|Unique name identifier for the node|
|status|string|true|none|Current operational status of the node|

#### Enumerated Values

|Property|Value|
|---|---|
|status|Ready|
|status|NotReady|
|status|Unknown|

<h2 id="tocS_StorageNodeSchema">StorageNodeSchema</h2>
<!-- backwards compatibility -->
<a id="schemastoragenodeschema"></a>
<a id="schema_StorageNodeSchema"></a>
<a id="tocSstoragenodeschema"></a>
<a id="tocsstoragenodeschema"></a>

```json
{
  "name": "string",
  "status": "Ready",
  "osds": {
    "up": [
      "string"
    ],
    "down": [
      "string"
    ]
  }
}

```

Storage node information including CEPH OSD (Object Storage Daemon) status details

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|true|none|Unique name identifier for the storage node|
|status|string|true|none|Current operational status of the storage node|
|osds|[OSDStatesSchema](#schemaosdstatesschema)|true|none|Object Storage Daemon status information showing which OSDs are operational and non-operational|

#### Enumerated Values

|Property|Value|
|---|---|
|status|Ready|
|status|NotReady|

<h2 id="tocS_OSDStatesSchema">OSDStatesSchema</h2>
<!-- backwards compatibility -->
<a id="schemaosdstatesschema"></a>
<a id="schema_OSDStatesSchema"></a>
<a id="tocSosdstatesschema"></a>
<a id="tocsosdstatesschema"></a>

```json
{
  "up": [
    "string"
  ],
  "down": [
    "string"
  ]
}

```

Object Storage Daemon status information showing which OSDs are operational and non-operational

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|up|[string]|false|none|List of OSD identifiers that are currently operational|
|down|[string]|false|none|List of OSD identifiers that are currently non-operational|

<h2 id="tocS_NamespaceName">NamespaceName</h2>
<!-- backwards compatibility -->
<a id="schemanamespacename"></a>
<a id="schema_NamespaceName"></a>
<a id="tocSnamespacename"></a>
<a id="tocsnamespacename"></a>

```json
"rack-resiliency"

```

Kubernetes namespace name where a service is deployed

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Kubernetes namespace name where a service is deployed|

<h2 id="tocS_ServiceName">ServiceName</h2>
<!-- backwards compatibility -->
<a id="schemaservicename"></a>
<a id="schema_ServiceName"></a>
<a id="tocSservicename"></a>
<a id="tocsservicename"></a>

```json
"cray-dns-powerdns"

```

Name of the critical service

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Name of the critical service|

<h2 id="tocS_ServiceBalanced">ServiceBalanced</h2>
<!-- backwards compatibility -->
<a id="schemaservicebalanced"></a>
<a id="schema_ServiceBalanced"></a>
<a id="tocSservicebalanced"></a>
<a id="tocsservicebalanced"></a>

```json
"true"

```

Indicates whether a service is properly distributed across zones for high availability

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Indicates whether a service is properly distributed across zones for high availability|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|true|
|*anonymous*|false|
|*anonymous*|NA|

<h2 id="tocS_ServiceStatus">ServiceStatus</h2>
<!-- backwards compatibility -->
<a id="schemaservicestatus"></a>
<a id="schema_ServiceStatus"></a>
<a id="tocSservicestatus"></a>
<a id="tocsservicestatus"></a>

```json
"error"

```

Current operational status of a critical service indicating its configuration and runtime state

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Current operational status of a critical service indicating its configuration and runtime state|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|error|
|*anonymous*|Configured|
|*anonymous*|PartiallyConfigured|
|*anonymous*|NotConfigured|
|*anonymous*|Running|
|*anonymous*|Unconfigured|

<h2 id="tocS_ServiceType">ServiceType</h2>
<!-- backwards compatibility -->
<a id="schemaservicetype"></a>
<a id="schema_ServiceType"></a>
<a id="tocSservicetype"></a>
<a id="tocsservicetype"></a>

```json
"Deployment"

```

Kubernetes resource type of the service

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Kubernetes resource type of the service|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|Deployment|
|*anonymous*|StatefulSet|

<h2 id="tocS_CriticalServicesListSchema">CriticalServicesListSchema</h2>
<!-- backwards compatibility -->
<a id="schemacriticalserviceslistschema"></a>
<a id="schema_CriticalServicesListSchema"></a>
<a id="tocScriticalserviceslistschema"></a>
<a id="tocscriticalserviceslistschema"></a>

```json
{
  "critical_services": {
    "namespace": {
      "property1": [
        {
          "name": "cray-dns-powerdns",
          "type": "Deployment"
        }
      ],
      "property2": [
        {
          "name": "cray-dns-powerdns",
          "type": "Deployment"
        }
      ]
    }
  }
}

```

Response containing all critical services organized by namespace

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|critical_services|object|true|none|Critical services grouped by their Kubernetes namespaces|
|» namespace|object|true|none|Mapping of namespace names to their contained critical services|
|»» **additionalProperties**|[[CriticalServiceItemSchema](#schemacriticalserviceitemschema)]|false|none|[Basic information about a critical service including its name and Kubernetes resource type]|

<h2 id="tocS_CriticalServiceItemSchema">CriticalServiceItemSchema</h2>
<!-- backwards compatibility -->
<a id="schemacriticalserviceitemschema"></a>
<a id="schema_CriticalServiceItemSchema"></a>
<a id="tocScriticalserviceitemschema"></a>
<a id="tocscriticalserviceitemschema"></a>

```json
{
  "name": "cray-dns-powerdns",
  "type": "Deployment"
}

```

Basic information about a critical service including its name and Kubernetes resource type

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[ServiceName](#schemaservicename)|true|none|Name of the critical service|
|type|[ServiceType](#schemaservicetype)|true|none|Kubernetes resource type of the service|

<h2 id="tocS_CriticalServiceCmStaticType">CriticalServiceCmStaticType</h2>
<!-- backwards compatibility -->
<a id="schemacriticalservicecmstatictype"></a>
<a id="schema_CriticalServiceCmStaticType"></a>
<a id="tocScriticalservicecmstatictype"></a>
<a id="tocscriticalservicecmstatictype"></a>

```json
{
  "critical_services": {
    "property1": {
      "namespace": "rack-resiliency",
      "type": "Deployment"
    },
    "property2": {
      "namespace": "rack-resiliency",
      "type": "Deployment"
    }
  }
}

```

Configuration payload for updating critical services in the system. Contains service definitions that need to be monitored for resiliency

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|critical_services|object|true|none|Mapping from service names to their configuration details for monitoring|
|» **additionalProperties**|[CriticalServiceCmStaticSchema](#schemacriticalservicecmstaticschema)|false|none|Static configuration details for a critical service that needs to be monitored|

<h2 id="tocS_CriticalServiceCmStaticSchema">CriticalServiceCmStaticSchema</h2>
<!-- backwards compatibility -->
<a id="schemacriticalservicecmstaticschema"></a>
<a id="schema_CriticalServiceCmStaticSchema"></a>
<a id="tocScriticalservicecmstaticschema"></a>
<a id="tocscriticalservicecmstaticschema"></a>

```json
{
  "namespace": "rack-resiliency",
  "type": "Deployment"
}

```

Static configuration details for a critical service that needs to be monitored

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|namespace|[NamespaceName](#schemanamespacename)|true|none|Kubernetes namespace name where a service is deployed|
|type|[ServiceType](#schemaservicetype)|true|none|Kubernetes resource type of the service|

<h2 id="tocS_CriticalServiceUpdateSchema">CriticalServiceUpdateSchema</h2>
<!-- backwards compatibility -->
<a id="schemacriticalserviceupdateschema"></a>
<a id="schema_CriticalServiceUpdateSchema"></a>
<a id="tocScriticalserviceupdateschema"></a>
<a id="tocscriticalserviceupdateschema"></a>

```json
{
  "Update": "Successful",
  "Successfully_Added_Services": [
    "cray-dns-powerdns"
  ],
  "Already_Existing_Services": [
    "cray-dns-powerdns"
  ]
}

```

Response indicating the result of updating critical services configuration

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Update|string|true|none|Overall status of the update operation|
|Successfully_Added_Services|[[ServiceName](#schemaservicename)]|true|none|List of service names that were successfully added to the configuration|
|Already_Existing_Services|[[ServiceName](#schemaservicename)]|true|none|List of service names that were already present in the configuration|

#### Enumerated Values

|Property|Value|
|---|---|
|Update|Successful|
|Update|Services Already Exist|

<h2 id="tocS_CriticalServiceDescribeSchema">CriticalServiceDescribeSchema</h2>
<!-- backwards compatibility -->
<a id="schemacriticalservicedescribeschema"></a>
<a id="schema_CriticalServiceDescribeSchema"></a>
<a id="tocScriticalservicedescribeschema"></a>
<a id="tocscriticalservicedescribeschema"></a>

```json
{
  "critical_service": {
    "name": "cray-dns-powerdns",
    "namespace": "rack-resiliency",
    "type": "Deployment",
    "configured_instances": 1
  }
}

```

Summarized view of a critical service without runtime details

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|critical_service|object|true|none|Basic configuration information about the critical service|
|» name|[ServiceName](#schemaservicename)|true|none|Name of the critical service|
|» namespace|[NamespaceName](#schemanamespacename)|true|none|Kubernetes namespace name where a service is deployed|
|» type|[ServiceType](#schemaservicetype)|true|none|Kubernetes resource type of the service|
|» configured_instances|number|true|none|Number of instances configured for this service (replicas for Deployments/StatefulSets)|

<h2 id="tocS_CriticalServiceStatusDescribeSchema">CriticalServiceStatusDescribeSchema</h2>
<!-- backwards compatibility -->
<a id="schemacriticalservicestatusdescribeschema"></a>
<a id="schema_CriticalServiceStatusDescribeSchema"></a>
<a id="tocScriticalservicestatusdescribeschema"></a>
<a id="tocscriticalservicestatusdescribeschema"></a>

```json
{
  "critical_service": {
    "name": "cray-dns-powerdns",
    "namespace": "rack-resiliency",
    "type": "Deployment",
    "status": "error",
    "balanced": "true",
    "configured_instances": 1,
    "currently_running_instances": 0,
    "pods": [
      {
        "name": "string",
        "node": "string",
        "status": "Running",
        "zone": "string"
      }
    ]
  }
}

```

Detailed status information for a critical service including runtime details and pod information

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|critical_service|object|true|none|Complete status information including configuration and runtime details|
|» name|[ServiceName](#schemaservicename)|true|none|Name of the critical service|
|» namespace|[NamespaceName](#schemanamespacename)|true|none|Kubernetes namespace name where a service is deployed|
|» type|[ServiceType](#schemaservicetype)|true|none|Kubernetes resource type of the service|
|» status|[ServiceStatus](#schemaservicestatus)|true|none|Current operational status of a critical service indicating its configuration and runtime state|
|» balanced|[ServiceBalanced](#schemaservicebalanced)|true|none|Indicates whether a service is properly distributed across zones for high availability|
|» configured_instances|number|true|none|Number of instances configured for this service|
|» currently_running_instances|number|true|none|Number of instances currently running and healthy|
|» pods|[[PodSchema](#schemapodschema)]|true|none|Detailed information about each pod instance of this service|

<h2 id="tocS_PodSchema">PodSchema</h2>
<!-- backwards compatibility -->
<a id="schemapodschema"></a>
<a id="schema_PodSchema"></a>
<a id="tocSpodschema"></a>
<a id="tocspodschema"></a>

```json
{
  "name": "string",
  "node": "string",
  "status": "Running",
  "zone": "string"
}

```

Information about an individual pod instance including its location and status

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|true|none|Unique name of the pod instance|
|node|string|true|none|Kubernetes node where the pod is scheduled to run|
|status|string|true|none|Current operational status of the pod|
|zone|string|true|none|Zone where the pod is located based on its assigned node|

#### Enumerated Values

|Property|Value|
|---|---|
|status|Running|
|status|Pending|
|status|Failed|
|status|Terminating|

<h2 id="tocS_CriticalServicesStatusListSchema">CriticalServicesStatusListSchema</h2>
<!-- backwards compatibility -->
<a id="schemacriticalservicesstatuslistschema"></a>
<a id="schema_CriticalServicesStatusListSchema"></a>
<a id="tocScriticalservicesstatuslistschema"></a>
<a id="tocscriticalservicesstatuslistschema"></a>

```json
{
  "critical_services": {
    "namespace": {
      "property1": [
        {
          "name": "cray-dns-powerdns",
          "type": "Deployment",
          "status": "error",
          "balanced": "true"
        }
      ],
      "property2": [
        {
          "name": "cray-dns-powerdns",
          "type": "Deployment",
          "status": "error",
          "balanced": "true"
        }
      ]
    }
  }
}

```

Status overview of all critical services organized by namespace, showing their operational state and distribution

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|critical_services|object|true|none|Critical services grouped by namespace with their status information|
|» namespace|object|true|none|Mapping of namespace names to their contained critical services with status|
|»» **additionalProperties**|[[CriticalServiceStatusItemSchema](#schemacriticalservicestatusitemschema)]|false|none|[Status summary for a critical service showing its operational state and distribution across zones]|

<h2 id="tocS_CriticalServiceStatusItemSchema">CriticalServiceStatusItemSchema</h2>
<!-- backwards compatibility -->
<a id="schemacriticalservicestatusitemschema"></a>
<a id="schema_CriticalServiceStatusItemSchema"></a>
<a id="tocScriticalservicestatusitemschema"></a>
<a id="tocscriticalservicestatusitemschema"></a>

```json
{
  "name": "cray-dns-powerdns",
  "type": "Deployment",
  "status": "error",
  "balanced": "true"
}

```

Status summary for a critical service showing its operational state and distribution across zones

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[ServiceName](#schemaservicename)|true|none|Name of the critical service|
|type|[ServiceType](#schemaservicetype)|true|none|Kubernetes resource type of the service|
|status|[ServiceStatus](#schemaservicestatus)|true|none|Current operational status of a critical service indicating its configuration and runtime state|
|balanced|[ServiceBalanced](#schemaservicebalanced)|true|none|Indicates whether a service is properly distributed across zones for high availability|

<h2 id="tocS_VersionSchema">VersionSchema</h2>
<!-- backwards compatibility -->
<a id="schemaversionschema"></a>
<a id="schema_VersionSchema"></a>
<a id="tocSversionschema"></a>
<a id="tocsversionschema"></a>

```json
{
  "version": "1.0.0"
}

```

Version information for the Rack Resiliency Service

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|version|string|true|none|The current version of the RRS Service|

<h2 id="tocS_ProblemDetails">ProblemDetails</h2>
<!-- backwards compatibility -->
<a id="schemaproblemdetails"></a>
<a id="schema_ProblemDetails"></a>
<a id="tocSproblemdetails"></a>
<a id="tocsproblemdetails"></a>

```json
{
  "detail": "string",
  "errors": {},
  "instance": "http://example.com",
  "status": 400,
  "title": "string",
  "type": "about:blank"
}

```

An error response for RFC 7807 problem details.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|detail|string|false|none|A human-readable explanation specific to this occurrence of the problem. Focus on helping correct the problem, rather than giving debugging information.|
|errors|object|false|none|An object denoting field-specific errors. Only present on error responses when field input is specified for the request.|
|instance|string(uri)|false|none|A relative URI reference that identifies the specific occurrence of the problem|
|status|integer|false|none|HTTP status code|
|title|string|false|none|Short, human-readable summary of the problem, should not change by occurrence.|
|type|string(uri)|false|none|Relative URI reference to the type of problem which includes human-readable documentation.|

<h2 id="tocS_EmptyDict">EmptyDict</h2>
<!-- backwards compatibility -->
<a id="schemaemptydict"></a>
<a id="schema_EmptyDict"></a>
<a id="tocSemptydict"></a>
<a id="tocsemptydict"></a>

```json
{}

```

Empty response object typically returned by health check endpoints to indicate successful operation

### Properties

*None*

