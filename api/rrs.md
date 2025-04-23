# Rack Resiliency Service (RRS)

## Overview

The Rack Resiliency Service (RRS) provides APIs to access and manage zones data and criticalservices information within Kubernetes and Ceph clusters. It supports zone discovery, status checks, and critical service registration. RRS is used by the `cray rrs` CLI to power high-availability, fault-tolerant operations.

The service exposes a RESTful API and is designed to run inside a Kubernetes cluster with access to the Kubernetes API and Ceph CLI tools.

---
## Resources

  ### /zones

    To view the zones information. It includes both listing and describing zones.

  ### /criticalservices

    To view the criticalservices pertaining to rack resiliency. The resource includes listing the criticalservices, describing them and adding new services to the existing list.

  ### /criticalservices/status

    To view the status of the criticalservices pertaining to rack resiliency. The resource includes listing the status of  criticalservicesand describing the status of particular service.

## Workflows

### Listing Information:
    
#### `GET /zones`

    Obtain a list of all discovered zones across Kubernetes and Ceph.

#### `GET /criticalservices`

    Obtain a list of all the criticalservices pertaining to rack resiliency service.

#### `GET /criticalservices/status`

    Obtain a list of status of all the criticalservices pertaining to rack resiliency service.

---

### Describing resource:

#### `GET /zones/<zone-name>`

    Obtain the detailed information about a specific zone, including nodes, status and OSDs.

#### `GET /criticalservices/<service-name>`

    Obtain the detailed information about a specific criticalservice.


#### `GET /criticalservices/status/<service-name>`

    Obtain the detailed information about the status a specific criticalservice.

---

### Updating information:

#### `PATCH /criticalservices`

    Registers new criticalservice(s) with the system. Requires the service name, namespace and type in a json file in the given format.

**file format:**

```json
{
  "critical-services": {
     "svc-1": {
       "namespace": "ns-1",
       "type": "Deployment"
     },
     "svc-2": {
       "namespace": "ns-2",
       "type": "DaemonSet"
     }
  }
}
```

---

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/rrs">https://api-gw-service-nmn.local/apis/rrs</a>

License: <a href="http://www.hpe.com/">Hewlett Packard Enterprise Development LP</a>

---

# Authentication

- HTTP Authentication, scheme: bearer 

---

<h1 id="rrs-zones">zones</h1>

Interacting with zones

## get_zones

<a id="opIdget_zones"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/zones HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
curl -s -k -H "Authorization: Bearer $TOKEN" \
--header "Content-Type: application/json" https://api-gw-service-nmn.local/apis/rrs/zones

```

```python
import requests
headers = {
  "Authorization": f"Bearer {TOKEN}",
  "Accept": "application/json"
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/zones', headers = headers)

print(r.json())

```

```go
package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    token := os.Getenv("TOKEN")
    url := "https://api-gw-service-nmn.local/apis/rrs/zones"

    req, _ := http.NewRequest("GET", url, nil)
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Accept", "application/json")

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        fmt.Println("Request error:", err)
        return
    }
    defer resp.Body.Close()

    buf := make([]byte, 4096)
    n, _ := resp.Body.Read(buf)
    fmt.Println(string(buf[:n]))
}
```

---

`GET /zones`

*List all Zones*
Retrieve the list of zones present in the system.

> Example responses

> 200 Response

```json
{
  "Zones": [
    {
      "Zone Name": "rack2",
      "Kubernetes Topology Zone": {
        "Management Master Nodes": [
        "master2"
        ],
        "Management Worker Nodes": [
          "worker3"
        ]
      },
      "CEPH Zone": {
        "Management Storage Nodes": [
          "storage5",
          "storage3"
        ]
      }
    }
  ]
}
```

<h3 id="get_zones-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|List of zones|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|
<h3 id="get_zones-responseschema">Response Schema</h3>

Status Code **200**

| Name | Type | Required | Restrictions | Description |
|------|------|----------|--------------|-------------|
| » Zones | array of object | Yes | | List of zone objects |
| »» Zone Name | string | Yes | | Name of the zone |
| »» Kubernetes Topology Zone | object | Yes | | Kubernetes-related nodes grouped by roles |
| »»» Management Master Nodes | array of string | Yes | | List of Kubernetes master nodes in the zone |
| »»» Management Worker Nodes | array of string | Yes | | List of Kubernetes worker nodes in the zone |
| »» CEPH Zone | object | Yes | | Ceph-related storage node details |
| »»» Management Storage Nodes | array of string | Yes | | List of Ceph storage nodes in the zone |

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

---

## describe_zone

<a id="opIddescribe_zones"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/zones/{zone_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
curl -s -k -H "Authorization: Bearer $TOKEN" \
--header "Content-Type: application/json" https://api-gw-service-nmn.local/apis/rrs/zones/{zone_name}

```

```python
import requests
headers = {
  "Authorization": f"Bearer {TOKEN}",
  "Accept": "application/json"
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/zones/{zone_name}', headers = headers)

print(r.json())

```

```go
package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    token := os.Getenv("TOKEN")
    url := "https://api-gw-service-nmn.local/apis/rrs/zones/{zone_name}"

    req, _ := http.NewRequest("GET", url, nil)
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Accept", "application/json")

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        fmt.Println("Request error:", err)
        return
    }
    defer resp.Body.Close()

    buf := make([]byte, 4096)
    n, _ := resp.Body.Read(buf)
    fmt.Println(string(buf[:n]))
}
```

---

`GET /zones/{zone_name}`

*Retrieve zone by zone_name*

Retrieve the zone details by zone_name present in the system.

<h3 id="describe_zones-parameters">Parameters</h3>

|Name|Type|Required|Description|
|---|---|---|---|
|zone_name|string|true|The name of the zone|


> Example responses

> 200 Response

```json
{
  "Zone Name": "rack3",
  "Management Masters": 1,
  "Management Workers": 2,
  "Management Storages": 1,
  "Management Master": {
    "Type": "Kubernetes Topology Zone",
    "Nodes": [
      {
        "Name": "master1",
        "Status": "Ready"
      }
    ]
  },
  "Management Worker": {
    "Type": "Kubernetes Topology Zone",
    "Nodes": [
      {
        "Name": "worker1",
        "Status": "Ready"
      },
      {
        "Name": "worker2",
        "Status": "NotReady"
      }
    ]
  },
  "Management Storage": {
    "Type": "CEPH Zone",
    "Nodes": [
      {
        "Name": "storage1",
        "Status": "Ready",
        "OSDs": {
          "up": [
            "osd.1",
            "osd.2",
          ]
        }
      }
    ]
  }
}
```

<h3 id="describe_zones-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|List of zones|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid Zone name.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="describe_zone-responseschema">Response Schema</h3>

Status Code **200**

| Name | Type | Required | Restrictions | Description |
|------|------|----------|--------------|-------------|
| » Zone Name | string | Yes | | Name of the requested zone |
| » Management Masters | integer | Yes | ≥ 0 | Number of master nodes in the zone |
| » Management Workers | integer | Yes | ≥ 0 | Number of worker nodes in the zone |
| » Management Storages | integer | Yes | ≥ 0 | Number of storage nodes in the zone |
| » Management Master | object | Yes | | Kubernetes master node details |
| »» Type | string | Yes | "Kubernetes Topology Zone" | Type of zone for master nodes |
| »» Nodes | array of object | Yes | | List of master nodes |
| »»» Name | string | Yes | | Name of the master node |
| »»» Status | string | Yes | "Ready", "NotReady" | Status of the master node |
| » Management Worker | object | Yes | | Kubernetes worker node details |
| »» Type | string | Yes | "Kubernetes Topology Zone" | Type of zone for worker nodes |
| »» Nodes | array of object | Yes | | List of worker nodes |
| »»» Name | string | Yes | | Name of the worker node |
| »»» Status | string | Yes | "Ready", "NotReady" | Status of the worker node |
| » Management Storage | object | Yes | | Ceph storage node details |
| »» Type | string | Yes | "CEPH Zone" | Type of zone for storage nodes |
| »» Nodes | array of object | Yes | | List of storage nodes |
| »»» Name | string | Yes | | Name of the storage node |
| »»» Status | string | Yes | "Ready", "NotReady" | Status of the storage node |
| »»» OSDs | object | Yes | | OSD status summary |
| »»»» Stauts | array of string | Yes | up/down | List of OSDs that are up/down |


<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

---
<br>
<h1 id="rrs-criticalservices">criticalservices</h1>

Interacting with criticalservices

## get_criticalservices

<a id="opIdget_criticalservices"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/criticalservices HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
curl -s -k -H "Authorization: Bearer $TOKEN" \
--header "Content-Type: application/json" https://api-gw-service-nmn.local/apis/rrs/criticalservices

```

```python
import requests
headers = {
  "Authorization": f"Bearer {TOKEN}",
  "Accept": "application/json"
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/criticalservices', headers = headers)

print(r.json())

```

```go
package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    token := os.Getenv("TOKEN")
    url := "https://api-gw-service-nmn.local/apis/rrs/criticalservices"

    req, _ := http.NewRequest("GET", url, nil)
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Accept", "application/json")

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        fmt.Println("Request error:", err)
        return
    }
    defer resp.Body.Close()

    buf := make([]byte, 4096)
    n, _ := resp.Body.Read(buf)
    fmt.Println(string(buf[:n]))
}
```

---

`GET /criticalservices`

*List all Criticalservices*
Retrieve the list of criticalservices present pertaining to RRS.

> Example responses

> 200 Response

```json
{
  "critical-services": {
    "namespace": {
      "ns-1": [
        {
          "name": "ns1-svc-1",
          "type": "Deployment"
        },
        {
          "name": "ns1-svc-2",
          "type": "StatefulSet"
        }
      ],
      "ns-2": [
        {
          "name": "ns2-svc-1",   
          "type": "StatefulSet"
        }
      ]
    }
  }
}
```

<h3 id="get_criticalservices-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|List of criticalservices|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_criticalservices-responseschema">Response Schema</h3>

Status Code **200**

| Name | Type | Required | Restrictions | Description |
|------|------|----------|--------------|-------------|
| » critical-services | object | Yes | | Root object containing critical services info |
| »» namespace | object | Yes | | Map of namespaces to their critical services |
| »»» {namespace} | array of object | Yes | | List of critical services in the namespace |
| »»»» name | string | Yes | | Name of the critical service |
| »»»» type | string | Yes | "Deployment", "StatefulSet" | Type of the Kubernetes workload |

> Replace {namespace} dynamically with actual namespace keys like ns-1, ns-2, etc.

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

---

## describe_criticalservices

<a id="opIddescribe_criticalservices"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/criticalservices/{criticalservice_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
curl -s -k -H "Authorization: Bearer $TOKEN" \
--header "Content-Type: application/json" https://api-gw-service-nmn.local/apis/rrs/criticalservices/{criticalservice_name}

```

```python
import requests
headers = {
  "Authorization": f"Bearer {TOKEN}",
  "Accept": "application/json"
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/criticalservices/{criticalservice_name}', headers = headers)

print(r.json())

```

```go
package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    token := os.Getenv("TOKEN")
    url := "https://api-gw-service-nmn.local/apis/rrs/criticalservices/{criticalservice_name}"

    req, _ := http.NewRequest("GET", url, nil)
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Accept", "application/json")

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        fmt.Println("Request error:", err)
        return
    }
    defer resp.Body.Close()

    buf := make([]byte, 4096)
    n, _ := resp.Body.Read(buf)
    fmt.Println(string(buf[:n]))
}
```

---

`GET /criticalservices/{criticalservice_name}`

*Retrieve criticalservice by criticalservice_name*

Retrieve the criticalservice details by criticalservice_name pertaining to RRS.

<h3 id="describe_criticalservices-parameters">Parameters</h3>

|Name|Type|Required|Description|
|---|---|---|---|
|criticalservice_name|string|true|The name of the zone|

> Example responses

> 200 Response

```json
{
  "Critical Service": {
    "Name": "xyz-service",
    "Namespace": "abc-ns",
    "Type": "Deployment/StatefulSet/DaemonSet",
    "Configured Instances": <num>,
    "Currently Running Instances": <num>
  }
}
```

<h3 id="describe_criticalservices-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|List of criticalservices|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid service name.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="describe_criticalservice-responseschema">Response Schema</h3>

Status Code **200**

| Name | Type | Required | Restrictions | Description |
|------|------|----------|--------------|-------------|
| » Critical Service | object | Yes | | Details of the critical service |
| »» Name | string | Yes | | Name of the critical service |
| »» Namespace | string | Yes | | Namespace in which the service is deployed |
| »» Type | string | Yes | Deployment, StatefulSet, DaemonSet | Type of Kubernetes workload |
| »» Configured Instances | integer | Yes | ≥ 0 | Number of instances configured for the service |
| »» Currently Running Instances | integer | Yes | ≥ 0 | Number of instances currently running |

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

---

## update_criticalservices

<a id="opIdupdate_criticalservices"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/irrs/criticalservices HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
curl -s -k -X PATCH \
-H "Authorization: Bearer $TOKEN" \
-H 'Accept: application/json' \
--header "Content-Type: application/json" https://api-gw-service-nmn.local/apis/rrs/criticalservices

```

```python
import requests
headers = {
  "Authorization": f"Bearer {TOKEN}",
  "Accept": "application/json"
  "Content-Type: application/json"
}
with open('payload.json', 'r') as f:
    payload = json.load(f)
r = requests.patch('https://api-gw-service-nmn.local/apis/rrs/criticalservices', headers = headers, json=payload, verify=False)

print(r.json())

```

```go
package main

import (
    "fmt"
    "bytes"
    "net/http"
    "os"
)

func main() {
    token := os.Getenv("TOKEN")
    url := "https://api-gw-service-nmn.local/apis/rrs/criticalservices"
    payloadBytes, err := os.ReadFile("payload.json")

    req, _ := http.NewRequest("PATCH", url, nil)
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Accept", "application/json")
    req.Header.Set("Content-Type", "application/json")

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        fmt.Println("Request error:", err)
        return
    }
    defer resp.Body.Close()

    body, err := io.ReadAll(resp.Body)

    fmt.Println("Status:", resp.Status)
    fmt.Println("Response Body:", string(body))
}
```

---

`PACH /criticalservices`

*Update the list of criticalservices*

Update the criticalservice by adding new ones in the existing configmap.

<h3 id="update_criticalservices-parameters">Parameters</h3>

|Name|Type|Required|Description|
|---|---|---|---|
|body|json|true|File contains the list of criticalservices to be added|

**file format:**

```json
{
  "critical-services": {
     "svc-1": {
       "namespace": "ns-1",
       "type": "Deployment"
     },
     "svc-2": {
       "namespace": "ns-2",
       "type": "DaemonSet"
     }
  }
}
```

> Example responses

> 200 Response

```json
"Update" = "Services Already Exist"
"Successfully Added Services" = ["svc-1",]
"Already Existing Services" = [ "svc-0",]
```

<h3 id="update_criticalservices-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Status of the criticalservice|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="update_criticalservices-responseschema">Response Schema</h3>

Status Code **200**

| Name | Type | Required | Restrictions | Description |
|------|------|----------|--------------|-------------|
| Update | string | Yes | | Summary message indicating the result of the operation |
| Successfully Added Services | array of string | Yes | | List of services that were successfully added |
| Already Existing Services | array of string | Yes | | List of services that were already present |

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

---

<br>
<h1 id="rrs-criticalservices_status">Criticalservices Status</h1>

Interacting with status of criticalservices

## get_criticalservices

<a id="opIdget_criticalservices_status"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/criticalservices/status HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
curl -s -k -H "Authorization: Bearer $TOKEN" \
--header "Content-Type: application/json" https://api-gw-service-nmn.local/apis/rrs/criticalservices/status

```

```python
import requests
headers = {
  "Authorization": f"Bearer {TOKEN}",
  "Accept": "application/json"
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/criticalservices/status', headers = headers)

print(r.json())

```

```go
package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    token := os.Getenv("TOKEN")
    url := "https://api-gw-service-nmn.local/apis/rrs/criticalservices/status"

    req, _ := http.NewRequest("GET", url, nil)
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Accept", "application/json")

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        fmt.Println("Request error:", err)
        return
    }
    defer resp.Body.Close()

    buf := make([]byte, 4096)
    n, _ := resp.Body.Read(buf)
    fmt.Println(string(buf[:n]))
}
```

---

`GET /criticalservices/status`

*List all Criticalservices*
Retrieve the list of status criticalservices present pertaining to RRS.

> Example responses

> 200 Response

```json
{
  "critical-services": {
    "namespace": {
      "ns-1": [
        {
          "name": "ns1-svc-1",
          "type": "Deployment",
          "status": "Configured",
          "balanced": "true"
        },
        {
          "name": "ns1-svc-2",
          "type": "StatefulSet",
          "status": "PartiallyConfigured",
          "balanced": "true"
        }
      ],
      "ns-2": [
        {
          "name": "ns2-svc-1",
          "type": "StatefulSet",
          "status": "NotConfigured",
          "balanced": "true"
        }
      ]
    }
  }
}
```

<h3 id="get_criticalservices_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|List of status of criticalservices|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_criticalservices_status-responseschema">Response Schema</h3>

Status Code **200**

| Name | Type | Required | Restrictions | Description |
|------|------|----------|--------------|-------------|
| » critical-services | object | Yes | | Root object containing critical services information |
| »» namespace | object | Yes | | Map of namespaces to their critical services |
| »»» {namespace} | array of object | Yes | | List of critical services within the given namespace |
| »»»» name | string | Yes | | Name of the critical service |
| »»»» type | string | Yes | Deployment, StatefulSet, DaemonSet | Type of Kubernetes workload |
| »»»» status | string | Yes | Configured, PartiallyConfigured, NotConfigured | Configuration status of the service |
| »»»» balanced | string (boolean) | Yes | "true", "false" | Indicates if service is balanced across zones |

> Replace <namespace> dynamically with actual namespace keys like ns-1, ns-2, etc.

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

---

## describe_criticalservice_status

<a id="opIddescribe_criticalservices_status"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/rrs/criticalservices/status/{criticalservice_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
curl -s -k -H "Authorization: Bearer $TOKEN" \
--header "Content-Type: application/json" https://api-gw-service-nmn.local/apis/rrs/criticalservices/status/{criticalservice_name}

```

```python
import requests
headers = {
  "Authorization": f"Bearer {TOKEN}",
  "Accept": "application/json"
}

r = requests.get('https://api-gw-service-nmn.local/apis/rrs/criticalservices/status/{criticalservice_name}', headers = headers)

print(r.json())

```

```go
package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    token := os.Getenv("TOKEN")
    url := "https://api-gw-service-nmn.local/apis/rrs/criticalservices/status/{criticalservice_name}"

    req, _ := http.NewRequest("GET", url, nil)
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Accept", "application/json")

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        fmt.Println("Request error:", err)
        return
    }
    defer resp.Body.Close()

    buf := make([]byte, 4096)
    n, _ := resp.Body.Read(buf)
    fmt.Println(string(buf[:n]))
}
```

---

`GET /criticalservices/status/{criticalservice_name}`

*Retrieve status of criticalservice by criticalservice_name*

Retrieve the criticalservice status details by criticalservice_name pertaining to RRS.

<h3 id="describe_criticalservices_status-parameters">Parameters</h3>

|Name|Type|Required|Description|
|---|---|---|---|
|criticalservice_name|string|true|The name of the zone|


> Example responses

> 200 Response

```json
{
  "Critical Service": {
    "Name": "xyz-service",
    "Namespace": "abc-ns",
    "Type": "Deployment/StatefulSet/DaemonSet",
    "Configured Instances": <num>,
    "Currently Running Instances": <num>
  }
}
```

<h3 id="describe_criticalservices_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Status of the criticalservice|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid service name.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="describe_criticalservices_status-responseschema">Response Schema</h3>

Status Code **200**

| Name | Type | Required | Restrictions | Description |
|------|------|----------|--------------|-------------|
| » Critical Service | object | Yes | | Contains details about the critical service |
| »» Name | string | Yes | | Name of the critical service |
| »» Namespace | string | Yes | | Namespace in which the service is deployed |
| »» Type | string | Yes | Deployment, StatefulSet, DaemonSet | Type of the Kubernetes workload |
| »» Status | string | Yes | Configured, Partially Configured, Running | Overall configuration or runtime status of the service |
| »» Balanced | string (boolean) | Yes | "true", "false" | Whether the service is balanced across zones |
| »» Configured Instances | integer | Yes | ≥ 0 | Number of instances configured |
| »» Currently Running Instances | integer | Yes | ≥ 0 | Number of instances currently running |
| »» Pods | array of object | Yes | | List of pods under the service |
| »»» Name | string | Yes | | Name of the pod |
| »»» Status | string | Yes | "Running", "Pending", "Failed" | Current status of the pod |
| »»» Node | string | Yes | | Name of the node the pod is running on |
| »»» Zone | string | Yes | | Zone (e.g., rack name) where the pod's node resides |

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

---

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|detail|string|false|none|A human-readable explanation specific to this occurrence of the problem. Focus on helping correct the problem, rather than giving debugging information.|
|errors|object|false|none|An object denoting field-specific errors. Only present on error responses when field input is specified for the request.|
|instance|string(uri)|false|none|A relative URI reference that identifies the specific occurrence of the problem|
|status|integer|false|none|HTTP status code|
|title|string|false|none|Short, human-readable summary of the problem, should not change by occurrence.|
|type|string(uri)|false|none|Relative URI reference to the type of problem which includes human-readable documentation.|

---

## Example CLI Usage (`cray rrs`)

```bash
# List zones
cray rrs zones list

# Describe specific zone
cray rrs zones describe zone-k8s-us-west

# List all critical services
cray rrs criticalservices list

# Get details of a critical service
cray rrs criticalservices describe <service-name>

# Create a new critical service
cray rrs criticalservices --from-file <json-file-path>

# List all critical services status
cray rrs criticalservices status list

# Get details of a critical service status
cray rrs criticalservices status describe <service-name>
```
---
