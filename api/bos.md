<!-- Generator: Widdershins v4.0.1 -->

<h1 id="boot-orchestration-service">Boot Orchestration Service v2</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The Boot Orchestration Service (BOS) provides coordinated provisioning actions
over defined hardware sets to enable boot, reboot, shutdown, configuration and
staging for specified hardware subsets. These provisioning actions apply state
through numerous system management APIs at the request of system administrators
for managed product environments.

The default content type for the BOS API is "application/json". Unsuccessful
API calls return a content type of "application/problem+json" as per RFC 7807.

## Resources

### Session Template

A Session Template sets the operational context of which nodes to operate on for
any given set of nodes. It is largely comprised of one or more boot
sets and their associated software configuration.

A Boot Set defines a list of nodes, the image you want to boot/reboot the nodes with,
kernel parameters to use to boot the nodes, and additional configuration management
framework actions to apply during node bring up.

### Session

A BOS Session applies a provided action to the nodes defined in a Session Template.

## Workflow: Create a New Session

1. Choose the Session Template to use.

  Session Templates which do not belong to a tenant are uniquely identified by their
  names. All Session Templates that belong to a given tenant are uniquely identified
  by their names, but may share names with Session Templates that belong to other
  tenants or that do not belong to a tenant.

  a. List available Session Templates.

    GET /v1/sessiontemplate or /v2/sessiontemplates

  b. Create a new Session Template if desired.

    POST /v1/sessiontemplate or PUT /v2/sessiontemplate/{template_name}

    If no Session Template exists that satisfies requirements,
    then create a new Session Template.
    This Session Template can be used to create a new Session later.

2. Create the Session.

  POST /v1/session or /v2/sessions

  Specify template_name and an operation to create a new Session.
  The template_name corresponds to the Session Template *name*.
  A new Session is launched as a result of this call (in the case of
  /v2/sessions, the option to stage but not begin the Session also exists).

  A limit can also be specified to narrow the scope of the Session. The limit
  can consist of nodes, groups, or roles in a comma-separated list.
  Multiple groups are treated as separated by OR, unless "&" is added to
  the start of the component, in which case this becomes an AND.  Components
  can also be preceded by "!" to exclude them.

  Note, the response from a successful Session launch contains *links*.
  Within *links*, *href* is a string that uniquely identifies the Session.
  *href* is constructed using the Session Template name and a generated UUID.
  Use the entire *href* string as the path parameter *session_id*
  to uniquely identify a Session.

3. Get details on the Session.

  GET /v1/session/{session_id} or /v2/sessions/{session_id}

## Interactions with Other APIs

### Configuration Framework Service (CFS)

If *enable_cfs* is true in a Session Template, then BOS will invoke CFS to
configure the target nodes during *boot*, *reboot*, or *configure*
operations. The *configure* operation is only available in BOS v1 Sessions;
if desiring to only perform a CFS configuration on a set of nodes, it is
recommended to use CFS directly.

### Hardware State Manager (HSM)

In some situations BOS checks HSM to determine if a node has been disabled.

### Image Management Service (IMS)

BOS works in concert with IMS to access boot images.
All boot images specified via the Session Template must be available via IMS.

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/bos">https://api-gw-service-nmn.local/apis/bos</a>

* <a href="https://cray-bos">https://cray-bos</a>

<h1 id="boot-orchestration-service-version">version</h1>

## get__

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/ HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/ \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /`

*Get API versions*

Return list of versions currently running.

> Example responses

> 200 Response

```json
[
  {
    "major": "string",
    "minor": "string",
    "patch": "string",
    "links": [
      {
        "href": "string",
        "rel": "string"
      }
    ]
  }
]
```

<h3 id="get__-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of Versions|Inline|

<h3 id="get__-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Version](#schemaversion)]|false|none|[Version data]|
|» major|string|false|none|none|
|» minor|string|false|none|none|
|» patch|string|false|none|none|
|» links|[[Link](#schemalink)]|false|none|List of links to other resources|
|»» href|string|false|none|none|
|»» rel|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## v1_get

<a id="opIdv1_get"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1 HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1 \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1`

*Get API version*

Return the API version

> Example responses

> 200 Response

```json
{
  "major": "string",
  "minor": "string",
  "patch": "string",
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="v1_get-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Get version details
The versioning system uses [semver](https://semver.org/).
## Link Relationships
* self : Link to itself
* versions : Link back to the versions resource|[Version](#schemaversion)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## v1_get_version

<a id="opIdv1_get_version"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/version HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/version \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/version', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/version", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/version`

*Get API version*

Return the API version

> Example responses

> 200 Response

```json
{
  "major": "string",
  "minor": "string",
  "patch": "string",
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="v1_get_version-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Get version details
The versioning system uses [semver](https://semver.org/).
## Link Relationships
* self : Link to itself
* versions : Link back to the versions resource|[Version](#schemaversion)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-orchestration-service-healthz">healthz</h1>

## v1_get_healthz

<a id="opIdv1_get_healthz"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/healthz HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/healthz \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/healthz', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/healthz", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/healthz`

*Get service health details*

Get BOS health details.

> Example responses

> 200 Response

```json
{
  "dbStatus": "string",
  "apiStatus": "string"
}
```

<h3 id="v1_get_healthz-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Service Health information|[Healthz](#schemahealthz)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|Service Unavailable|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-orchestration-service-sessiontemplate">sessiontemplate</h1>

## create_v1_sessiontemplate

<a id="opIdcreate_v1_sessiontemplate"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.post('https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v1/sessiontemplate`

*Create Session Template*

Create a new Session Template.

> Body parameter

```json
{
  "name": "cle-1.0.0",
  "description": "string",
  "cfs_url": "string",
  "cfs_branch": "string",
  "enable_cfs": true,
  "cfs": {
    "clone_url": "string",
    "branch": "string",
    "commit": "string",
    "playbook": "string",
    "configuration": "compute-23.4.0"
  },
  "partition": "string",
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "network": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "network": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0
    }
  }
}
```

<h3 id="create_v1_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V1SessionTemplate](#schemav1sessiontemplate)|true|A JSON object for creating a Session Template|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 201 Response

```json
"cle-1.0.0"
```

<h3 id="create_v1_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Session Template name|[SessionTemplateName](#schemasessiontemplatename)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.
If no tenant was specified, then the request was bad for another reason.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v1_sessiontemplates

<a id="opIdget_v1_sessiontemplates"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/sessiontemplate`

*List Session Templates*

List all Session Templates.

<h3 id="get_v1_sessiontemplates-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
[
  {
    "name": "cle-1.0.0",
    "description": "string",
    "cfs_url": "string",
    "cfs_branch": "string",
    "enable_cfs": true,
    "cfs": {
      "clone_url": "string",
      "branch": "string",
      "commit": "string",
      "playbook": "string",
      "configuration": "compute-23.4.0"
    },
    "partition": "string",
    "boot_sets": {
      "property1": {
        "name": "compute",
        "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
        "type": "s3",
        "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "node_list": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "node_roles_groups": [
          "Compute",
          "Application"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "cpss3",
        "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
        "network": "string",
        "boot_ordinal": 0,
        "shutdown_ordinal": 0
      },
      "property2": {
        "name": "compute",
        "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
        "type": "s3",
        "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "node_list": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "node_roles_groups": [
          "Compute",
          "Application"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "cpss3",
        "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
        "network": "string",
        "boot_ordinal": 0,
        "shutdown_ordinal": 0
      }
    },
    "links": [
      {
        "href": "string",
        "rel": "string"
      }
    ]
  }
]
```

<h3 id="get_v1_sessiontemplates-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template details array|[SessionTemplateArray](#schemasessiontemplatearray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v1_sessiontemplate

<a id="opIdget_v1_sessiontemplate"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate/{session_template_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate/{session_template_id} \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate/{session_template_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate/{session_template_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/sessiontemplate/{session_template_id}`

*Get Session Template by ID*

Get Session Template by Session Template ID.
The Session Template ID corresponds to the *name*
of the Session Template.

<h3 id="get_v1_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_template_id|path|[SessionTemplateName](#schemasessiontemplatename)|true|Session Template name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
{
  "name": "cle-1.0.0",
  "description": "string",
  "cfs_url": "string",
  "cfs_branch": "string",
  "enable_cfs": true,
  "cfs": {
    "clone_url": "string",
    "branch": "string",
    "commit": "string",
    "playbook": "string",
    "configuration": "compute-23.4.0"
  },
  "partition": "string",
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "network": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "network": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0
    }
  },
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="get_v1_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template details|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_v1_sessiontemplate-responseschema">Response Schema</h3>

#### Enumerated Values

|Property|Value|
|---|---|
|arch|X86|
|arch|ARM|
|arch|Other|
|arch|Unknown|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v1_sessiontemplate

<a id="opIddelete_v1_sessiontemplate"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate/{session_template_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate/{session_template_id} \
  -H 'Accept: application/problem+json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate/{session_template_id}', headers = headers)

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
        "Accept": []string{"application/problem+json"},
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate/{session_template_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v1/sessiontemplate/{session_template_id}`

*Delete a Session Template*

Delete a Session Template.

<h3 id="delete_v1_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_template_id|path|[SessionTemplateName](#schemasessiontemplatename)|true|Session Template name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "title": "string",
  "status": 400,
  "instance": "http://example.com",
  "detail": "string"
}
```

<h3 id="delete_v1_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v1_sessiontemplatetemplate

<a id="opIdget_v1_sessiontemplatetemplate"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplatetemplate HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplatetemplate \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplatetemplate', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplatetemplate", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/sessiontemplatetemplate`

*Get an example Session Template.*

Returns a skeleton of a Session Template, which can be
used as a starting point for users creating their own
Session Templates.

> Example responses

> 200 Response

```json
{
  "name": "cle-1.0.0",
  "description": "string",
  "cfs_url": "string",
  "cfs_branch": "string",
  "enable_cfs": true,
  "cfs": {
    "clone_url": "string",
    "branch": "string",
    "commit": "string",
    "playbook": "string",
    "configuration": "compute-23.4.0"
  },
  "partition": "string",
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "network": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "network": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0
    }
  },
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="get_v1_sessiontemplatetemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template details|[V1SessionTemplate](#schemav1sessiontemplate)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-orchestration-service-session">session</h1>

## create_v1_session

<a id="opIdcreate_v1_session"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/bos/v1/session HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v1/session \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.post('https://api-gw-service-nmn.local/apis/bos/v1/session', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/bos/v1/session", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v1/session`

*Create a Session*

The creation of a Session performs the operation
specified in the SessionCreateRequest
on the Boot Sets defined in the Session Template.

> Body parameter

```json
{
  "operation": "boot",
  "templateUuid": "my-session-template",
  "templateName": "cle-1.0.0",
  "limit": "string"
}
```

<h3 id="create_v1_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|any|true|A JSON object for creating a Session|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 201 Response

```json
{
  "operation": "boot",
  "templateName": "cle-1.0.0",
  "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "limit": "string",
  "links": [
    {
      "href": "string",
      "jobId": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
      "rel": "session",
      "type": "GET"
    }
  ]
}
```

<h3 id="create_v1_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Session|[V1Session](#schemav1session)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.
If no tenant was specified, then the request was bad for another reason.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v1_sessions

<a id="opIdget_v1_sessions"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/session HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/session', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/session", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/session`

*List Session IDs*

List IDs of all Sessions, including those in progress and those complete.

<h3 id="get_v1_sessions-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
[
  "8deb0746-b18c-427c-84a8-72ec6a28642c"
]
```

<h3 id="get_v1_sessions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of Session IDs|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_v1_sessions-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V1SessionId](#schemav1sessionid)]|false|none|[Unique BOS v1 Session identifier.]|

<aside class="success">
This operation does not require authentication
</aside>

## get_v1_session

<a id="opIdget_v1_session"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id} \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/session/{session_id}`

*Get Session details by ID*

Get Session details by Session ID.

<h3 id="get_v1_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
{
  "complete": true,
  "error_count": 0,
  "in_progress": false,
  "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "operation": "boot",
  "start_time": "2020-04-24T12:00",
  "status_link": "/v1/session/90730844-094d-45a5-9b90-d661d14d9444/status",
  "stop_time": "2020-04-24T12:00",
  "templateName": "cle-1.0.0"
}
```

<h3 id="get_v1_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session details|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_v1_session-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

## delete_v1_session

<a id="opIddelete_v1_session"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id} \
  -H 'Accept: application/problem+json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}', headers = headers)

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
        "Accept": []string{"application/problem+json"},
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v1/session/{session_id}`

*Delete Session by ID*

Delete Session by Session ID.

<h3 id="delete_v1_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "title": "string",
  "status": 400,
  "instance": "http://example.com",
  "detail": "string"
}
```

<h3 id="delete_v1_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v1_session_status

<a id="opIdget_v1_session_status"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/session/{session_id}/status`

*A list of the statuses for the different Boot Sets.*

A list of the statuses for the different Boot Sets.

<h3 id="get_v1_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
{
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "boot_sets": [
    "compute"
  ],
  "id": "8deb0746-b18c-427c-84a8-72ec6a28642c",
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="get_v1_session_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of Boot Set Statuses and metadata|[V1SessionStatus](#schemav1sessionstatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## create_v1_session_status

<a id="opIdcreate_v1_session_status"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.post('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v1/session/{session_id}/status`

*Create the initial Session status*

Creates the initial Session status.

> Body parameter

```json
{
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "boot_sets": [
    "compute"
  ],
  "id": "8deb0746-b18c-427c-84a8-72ec6a28642c",
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="create_v1_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V1SessionStatus](#schemav1sessionstatus)|true|A JSON object for creating the status for a Session|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
{
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "boot_sets": [
    "compute"
  ],
  "id": "8deb0746-b18c-427c-84a8-72ec6a28642c",
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="create_v1_session_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of Boot Set Statuses and metadata|[V1SessionStatus](#schemav1sessionstatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.
If no tenant was specified, then the request was bad for another reason.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|The resource to be created already exists|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## update_v1_session_status

<a id="opIdupdate_v1_session_status"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v1/session/{session_id}/status`

*Update the Session status*

Update the Session status. You can update the start or stop times.

> Body parameter

```json
{
  "complete": true,
  "error_count": 0,
  "in_progress": false,
  "start_time": "2020-04-24T12:00",
  "stop_time": "2020-04-24T12:00"
}
```

<h3 id="update_v1_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V1GenericMetadata](#schemav1genericmetadata)|true|A JSON object for updating the status for a Session|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
{
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "boot_sets": [
    "compute"
  ],
  "id": "8deb0746-b18c-427c-84a8-72ec6a28642c",
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="update_v1_session_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of Boot Set Statuses and metadata|[V1SessionStatus](#schemav1sessionstatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v1_session_status

<a id="opIddelete_v1_session_status"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status \
  -H 'Accept: application/problem+json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status', headers = headers)

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
        "Accept": []string{"application/problem+json"},
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v1/session/{session_id}/status`

*Delete the Session status*

Deletes an existing Session status

<h3 id="delete_v1_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "title": "string",
  "status": 400,
  "instance": "http://example.com",
  "detail": "string"
}
```

<h3 id="delete_v1_session_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.
If no tenant was specified, then the request was bad for another reason.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v1_session_status_by_bootset

<a id="opIdget_v1_session_status_by_bootset"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/session/{session_id}/status/{boot_set_name}`

*Get the status for a Boot Set.*

Get the status for a Boot Set.

<h3 id="get_v1_session_status_by_bootset-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot Set name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
{
  "name": "compute",
  "session": "8deb0746-b18c-427c-84a8-72ec6a28642c",
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "phases": [
    {
      "name": "Boot",
      "metadata": {
        "complete": true,
        "error_count": 0,
        "in_progress": false,
        "start_time": "2020-04-24T12:00",
        "stop_time": "2020-04-24T12:00"
      },
      "categories": [
        {
          "name": "Succeeded",
          "node_list": [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        }
      ],
      "errors": {
        "property1": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "property2": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      }
    }
  ],
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="get_v1_session_status_by_bootset-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Metadata and a list of the Phase Statuses for the Boot Set|[V1BootSetStatus](#schemav1bootsetstatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## create_v1_boot_set_status

<a id="opIdcreate_v1_boot_set_status"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.post('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v1/session/{session_id}/status/{boot_set_name}`

*Create a Boot Set Status*

Create a status for a Boot Set

> Body parameter

```json
{
  "name": "compute",
  "session": "8deb0746-b18c-427c-84a8-72ec6a28642c",
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "phases": [
    {
      "name": "Boot",
      "metadata": {
        "complete": true,
        "error_count": 0,
        "in_progress": false,
        "start_time": "2020-04-24T12:00",
        "stop_time": "2020-04-24T12:00"
      },
      "categories": [
        {
          "name": "Succeeded",
          "node_list": [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        }
      ],
      "errors": {
        "property1": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "property2": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      }
    }
  ],
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="create_v1_boot_set_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V1BootSetStatus](#schemav1bootsetstatus)|true|A JSON object for creating a status for a Boot Set|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot Set name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 201 Response

```json
{
  "name": "compute",
  "session": "8deb0746-b18c-427c-84a8-72ec6a28642c",
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "phases": [
    {
      "name": "Boot",
      "metadata": {
        "complete": true,
        "error_count": 0,
        "in_progress": false,
        "start_time": "2020-04-24T12:00",
        "stop_time": "2020-04-24T12:00"
      },
      "categories": [
        {
          "name": "Succeeded",
          "node_list": [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        }
      ],
      "errors": {
        "property1": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "property2": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      }
    }
  ],
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="create_v1_boot_set_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|The created Boot Set status|[V1BootSetStatus](#schemav1bootsetstatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|The resource to be created already exists|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## update_v1_session_status_by_bootset

<a id="opIdupdate_v1_session_status_by_bootset"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v1/session/{session_id}/status/{boot_set_name}`

*Update the status.*

This will change the status for one or more nodes within
the Boot Set.

> Body parameter

```json
[
  {
    "update_type": "NodeChangeList",
    "phase": "Boot",
    "data": {
      "phase": "Boot",
      "source": "Succeeded",
      "destination": "Succeeded",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ]
    }
  }
]
```

<h3 id="update_v1_session_status_by_bootset-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V1UpdateRequestList](#schemav1updaterequestlist)|true|A JSON object for updating the status for a Session|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot Set name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
{
  "name": "compute",
  "session": "8deb0746-b18c-427c-84a8-72ec6a28642c",
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "phases": [
    {
      "name": "Boot",
      "metadata": {
        "complete": true,
        "error_count": 0,
        "in_progress": false,
        "start_time": "2020-04-24T12:00",
        "stop_time": "2020-04-24T12:00"
      },
      "categories": [
        {
          "name": "Succeeded",
          "node_list": [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        }
      ],
      "errors": {
        "property1": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "property2": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      }
    }
  ],
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="update_v1_session_status_by_bootset-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of Boot Set Statuses and metadata|[V1BootSetStatus](#schemav1bootsetstatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v1_boot_set_status

<a id="opIddelete_v1_boot_set_status"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} \
  -H 'Accept: application/problem+json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}', headers = headers)

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
        "Accept": []string{"application/problem+json"},
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v1/session/{session_id}/status/{boot_set_name}`

*Delete the Boot Set status*

Deletes an existing Boot Set status

<h3 id="delete_v1_boot_set_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot Set name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "title": "string",
  "status": 400,
  "instance": "http://example.com",
  "detail": "string"
}
```

<h3 id="delete_v1_boot_set_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.
If no tenant was specified, then the request was bad for another reason.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v1_session_status_by_bootset_and_phase

<a id="opIdget_v1_session_status_by_bootset_and_phase"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}/{phase_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}/{phase_name} \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}/{phase_name}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}/{phase_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/session/{session_id}/status/{boot_set_name}/{phase_name}`

*Get the status for a specific Boot Set and phase.*

Get the status for a specific Boot Set and phase.

<h3 id="get_v1_session_status_by_bootset_and_phase-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot Set name|
|phase_name|path|string|true|The phase name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
{
  "name": "Boot",
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "categories": [
    {
      "name": "Succeeded",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ]
    }
  ],
  "errors": {
    "property1": [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ],
    "property2": [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ]
  }
}
```

<h3 id="get_v1_session_status_by_bootset_and_phase-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of the nodes in the Phase and Category|[V1PhaseStatus](#schemav1phasestatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v1_session_status_by_bootset_and_phase_and_category

<a id="opIdget_v1_session_status_by_bootset_and_phase_and_category"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}/{phase_name}/{category_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}/{phase_name}/{category_name} \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}/{phase_name}/{category_name}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}/{phase_name}/{category_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1/session/{session_id}/status/{boot_set_name}/{phase_name}/{category_name}`

*Get the status for a specific Boot Set, phase, and category.*

Get the status for a specific Boot Set, phase, and category.

<h3 id="get_v1_session_status_by_bootset_and_phase_and_category-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot Set name|
|phase_name|path|string|true|The phase name|
|category_name|path|string|true|The category name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name. Multi-tenancy is not supported for most BOS v1 endpoints.
If this parameter is set to a non-empty string, the request will be rejected.

> Example responses

> 200 Response

```json
{
  "name": "Succeeded",
  "node_list": [
    "x3000c0s19b1n0",
    "x3000c0s19b2n0"
  ]
}
```

<h3 id="get_v1_session_status_by_bootset_and_phase_and_category-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of the nodes in the Phase and Category|[V1PhaseCategoryStatus](#schemav1phasecategorystatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Multi-tenancy is not supported for this BOS v1 request.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-orchestration-service-v2">v2</h1>

## get_v2

<a id="opIdget_v2"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2 HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2 \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2`

*Get API version*

Return the API version

> Example responses

> 200 Response

```json
{
  "major": "string",
  "minor": "string",
  "patch": "string",
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="get_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Get version details
The versioning system uses [semver](https://semver.org/).
## Link Relationships
* self : Link to itself
* versions : Link back to the versions resource|[Version](#schemaversion)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_healthz

<a id="opIdget_v2_healthz"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/healthz HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/healthz \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/healthz', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/healthz", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/healthz`

*Get service health details*

Get BOS health details.

> Example responses

> 200 Response

```json
{
  "dbStatus": "string",
  "apiStatus": "string"
}
```

<h3 id="get_v2_healthz-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Service Health information|[Healthz](#schemahealthz)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|Service Unavailable|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_sessiontemplates

<a id="opIdget_v2_sessiontemplates"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/sessiontemplates`

*List Session Templates*

List all Session Templates.

<h3 id="get_v2_sessiontemplates-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
[
  {
    "name": "cle-1.0.0",
    "description": "string",
    "cfs_url": "string",
    "cfs_branch": "string",
    "enable_cfs": true,
    "cfs": {
      "clone_url": "string",
      "branch": "string",
      "commit": "string",
      "playbook": "string",
      "configuration": "compute-23.4.0"
    },
    "partition": "string",
    "boot_sets": {
      "property1": {
        "name": "compute",
        "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
        "type": "s3",
        "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "node_list": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "node_roles_groups": [
          "Compute",
          "Application"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "cpss3",
        "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
        "network": "string",
        "boot_ordinal": 0,
        "shutdown_ordinal": 0
      },
      "property2": {
        "name": "compute",
        "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
        "type": "s3",
        "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "node_list": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "node_roles_groups": [
          "Compute",
          "Application"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "cpss3",
        "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
        "network": "string",
        "boot_ordinal": 0,
        "shutdown_ordinal": 0
      }
    },
    "links": [
      {
        "href": "string",
        "rel": "string"
      }
    ]
  }
]
```

<h3 id="get_v2_sessiontemplates-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template details array|[SessionTemplateArray](#schemasessiontemplatearray)|

<aside class="success">
This operation does not require authentication
</aside>

## validate_v2_sessiontemplate

<a id="opIdvalidate_v2_sessiontemplate"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplatesvalid/{session_template_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplatesvalid/{session_template_id} \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplatesvalid/{session_template_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplatesvalid/{session_template_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/sessiontemplatesvalid/{session_template_id}`

*Validate the Session Template by ID*

Validate Session Template by Session Template ID.
The Session Template ID corresponds to the *name*
of the Session Template.

<h3 id="validate_v2_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_template_id|path|[SessionTemplateName](#schemasessiontemplatename)|true|Session Template name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
"string"
```

<h3 id="validate_v2_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template validity details|[V2SessionTemplateValidation](#schemav2sessiontemplatevalidation)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_sessiontemplate

<a id="opIdget_v2_sessiontemplate"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/sessiontemplates/{session_template_id}`

*Get Session Template by ID*

Get Session Template by Session Template ID.
The Session Template ID corresponds to the *name*
of the Session Template.

<h3 id="get_v2_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_template_id|path|[SessionTemplateName](#schemasessiontemplatename)|true|Session Template name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "name": "cle-1.0.0",
  "description": "string",
  "cfs_url": "string",
  "cfs_branch": "string",
  "enable_cfs": true,
  "cfs": {
    "clone_url": "string",
    "branch": "string",
    "commit": "string",
    "playbook": "string",
    "configuration": "compute-23.4.0"
  },
  "partition": "string",
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "network": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "network": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0
    }
  },
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="get_v2_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template details|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_v2_sessiontemplate-responseschema">Response Schema</h3>

#### Enumerated Values

|Property|Value|
|---|---|
|arch|X86|
|arch|ARM|
|arch|Other|
|arch|Unknown|

<aside class="success">
This operation does not require authentication
</aside>

## put_v2_sessiontemplate

<a id="opIdput_v2_sessiontemplate"></a>

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.put('https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /v2/sessiontemplates/{session_template_id}`

*Create Session Template*

Create a new Session Template.

> Body parameter

```json
{
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "compute-23.4.0"
  },
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    }
  }
}
```

<h3 id="put_v2_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2SessionTemplate](#schemav2sessiontemplate)|true|A JSON object for creating a Session Template|
|session_template_id|path|[SessionTemplateName](#schemasessiontemplatename)|true|Session Template name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "name": "cle-1.0.0",
  "tenant": "string",
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "compute-23.4.0"
  },
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    }
  },
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="put_v2_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template details|[V2SessionTemplate](#schemav2sessiontemplate)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v2_sessiontemplate

<a id="opIdpatch_v2_sessiontemplate"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v2/sessiontemplates/{session_template_id}`

*Update a Session Template*

Update an existing Session Template.

> Body parameter

```json
{
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "compute-23.4.0"
  },
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    }
  }
}
```

<h3 id="patch_v2_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2SessionTemplate](#schemav2sessiontemplate)|true|A JSON object for updating a Session Template|
|session_template_id|path|[SessionTemplateName](#schemasessiontemplatename)|true|Session Template name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "name": "cle-1.0.0",
  "tenant": "string",
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "compute-23.4.0"
  },
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    }
  },
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="patch_v2_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template details|[V2SessionTemplate](#schemav2sessiontemplate)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v2_sessiontemplate

<a id="opIddelete_v2_sessiontemplate"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} \
  -H 'Accept: application/problem+json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id}', headers = headers)

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
        "Accept": []string{"application/problem+json"},
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v2/sessiontemplates/{session_template_id}`

*Delete a Session Template*

Delete a Session Template.

<h3 id="delete_v2_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_template_id|path|[SessionTemplateName](#schemasessiontemplatename)|true|Session Template name|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 404 Response

```json
{
  "type": "about:blank",
  "title": "string",
  "status": 400,
  "instance": "http://example.com",
  "detail": "string"
}
```

<h3 id="delete_v2_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_sessiontemplatetemplate

<a id="opIdget_v2_sessiontemplatetemplate"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplatetemplate HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplatetemplate \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplatetemplate', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplatetemplate", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/sessiontemplatetemplate`

*Get an example Session Template.*

Returns a skeleton of a Session Template, which can be
used as a starting point for users creating their own
Session Templates.

> Example responses

> 200 Response

```json
{
  "name": "cle-1.0.0",
  "tenant": "string",
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "compute-23.4.0"
  },
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    }
  },
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="get_v2_sessiontemplatetemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template details|[V2SessionTemplate](#schemav2sessiontemplate)|

<aside class="success">
This operation does not require authentication
</aside>

## post_v2_session

<a id="opIdpost_v2_session"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/bos/v2/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v2/sessions \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.post('https://api-gw-service-nmn.local/apis/bos/v2/sessions', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/bos/v2/sessions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v2/sessions`

*Create a Session*

The creation of a Session performs the operation
specified in the SessionCreateRequest
on the Boot Sets defined in the Session Template.

> Body parameter

```json
{
  "name": "session-20190728032600",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "string",
  "stage": false,
  "include_disabled": false
}
```

<h3 id="post_v2_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2SessionCreate](#schemav2sessioncreate)|true|The information to create a Session|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 201 Response

```json
{
  "name": "session-20190728032600",
  "tenant": "string",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "string",
  "stage": true,
  "components": "string",
  "include_disabled": true,
  "status": {
    "start_time": "string",
    "end_time": "string",
    "status": "pending",
    "error": "string"
  }
}
```

<h3 id="post_v2_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Session details|[V2Session](#schemav2session)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_sessions

<a id="opIdget_v2_sessions"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessions \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/sessions', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/sessions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/sessions`

*List Sessions*

List all Sessions, including those in progress and those complete.

<h3 id="get_v2_sessions-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|min_age|query|[AgeString](#schemaagestring)|false|Only include Sessions older than the given age.  Age is given in the format "1d" or "6h"|
|max_age|query|[AgeString](#schemaagestring)|false|Only include Sessions younger than the given age.  Age is given in the format "1d" or "6h"|
|status|query|[V2SessionStatusLabel](#schemav2sessionstatuslabel)|false|Only include Sessions with the given status.|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

#### Enumerated Values

|Parameter|Value|
|---|---|
|status|pending|
|status|running|
|status|complete|

> Example responses

> 200 Response

```json
[
  {
    "name": "session-20190728032600",
    "tenant": "string",
    "operation": "boot",
    "template_name": "cle-1.0.0",
    "limit": "string",
    "stage": true,
    "components": "string",
    "include_disabled": true,
    "status": {
      "start_time": "string",
      "end_time": "string",
      "status": "pending",
      "error": "string"
    }
  }
]
```

<h3 id="get_v2_sessions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session details array|[V2SessionArray](#schemav2sessionarray)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v2_sessions

<a id="opIddelete_v2_sessions"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/bos/v2/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v2/sessions \
  -H 'Accept: application/problem+json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/bos/v2/sessions', headers = headers)

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
        "Accept": []string{"application/problem+json"},
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/bos/v2/sessions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v2/sessions`

*Delete multiple Sessions.*

Delete multiple Sessions.  If filters are provided, only Sessions matching
all filters will be deleted.  By default only completed Sessions will be deleted.

<h3 id="delete_v2_sessions-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|min_age|query|[AgeString](#schemaagestring)|false|Only include Sessions older than the given age.  Age is given in the format "1d" or "6h"|
|max_age|query|[AgeString](#schemaagestring)|false|Only include Sessions younger than the given age.  Age is given in the format "1d" or "6h"|
|status|query|[V2SessionStatusLabel](#schemav2sessionstatuslabel)|false|Only include Sessions with the given status.|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

#### Enumerated Values

|Parameter|Value|
|---|---|
|status|pending|
|status|running|
|status|complete|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "title": "string",
  "status": 400,
  "instance": "http://example.com",
  "detail": "string"
}
```

<h3 id="delete_v2_sessions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_session

<a id="opIdget_v2_session"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id} \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/sessions/{session_id}`

*Get Session details by ID*

Get Session details by Session ID.

<h3 id="get_v2_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "name": "session-20190728032600",
  "tenant": "string",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "string",
  "stage": true,
  "components": "string",
  "include_disabled": true,
  "status": {
    "start_time": "string",
    "end_time": "string",
    "status": "pending",
    "error": "string"
  }
}
```

<h3 id="get_v2_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session details|[V2Session](#schemav2session)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v2_session

<a id="opIdpatch_v2_session"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v2/sessions/{session_id}`

*Update a single Session*

Update the state for a given Session in the BOS database

> Body parameter

```json
{
  "name": "session-20190728032600",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "string",
  "stage": true,
  "components": "string",
  "include_disabled": true,
  "status": {
    "start_time": "string",
    "end_time": "string",
    "status": "pending",
    "error": "string"
  }
}
```

<h3 id="patch_v2_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2Session](#schemav2session)|true|The state for a single Session|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "name": "session-20190728032600",
  "tenant": "string",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "string",
  "stage": true,
  "components": "string",
  "include_disabled": true,
  "status": {
    "start_time": "string",
    "end_time": "string",
    "status": "pending",
    "error": "string"
  }
}
```

<h3 id="patch_v2_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session details|[V2Session](#schemav2session)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v2_session

<a id="opIddelete_v2_session"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id} \
  -H 'Accept: application/problem+json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}', headers = headers)

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
        "Accept": []string{"application/problem+json"},
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v2/sessions/{session_id}`

*Delete Session by ID*

Delete Session by Session ID.

<h3 id="delete_v2_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 404 Response

```json
{
  "type": "about:blank",
  "title": "string",
  "status": 400,
  "instance": "http://example.com",
  "detail": "string"
}
```

<h3 id="delete_v2_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_session_status

<a id="opIdget_v2_session_status"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}/status HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}/status \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}/status', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/sessions/{session_id}/status`

*Get Session extended status information by ID*

Get Session extended status information by ID

<h3 id="get_v2_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "status": "pending",
  "managed_components_count": 0,
  "phases": {
    "percent_complete": 0,
    "percent_powering_on": 0,
    "percent_powering_off": 0,
    "percent_configuring": 0
  },
  "percent_successful": 0,
  "percent_failed": 0,
  "percent_staged": 0,
  "error_summary": {},
  "timing": {
    "start_time": "string",
    "end_time": "string",
    "duration": "string"
  }
}
```

<h3 id="get_v2_session_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session status details|[V2SessionExtendedStatus](#schemav2sessionextendedstatus)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## save_v2_session_status

<a id="opIdsave_v2_session_status"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}/status HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}/status \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.post('https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}/status', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v2/sessions/{session_id}/status`

*Saves the current Session to database*

Saves the current Session to database.  For use at Session completion.

<h3 id="save_v2_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "name": "session-20190728032600",
  "tenant": "string",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "string",
  "stage": true,
  "components": "string",
  "include_disabled": true,
  "status": {
    "start_time": "string",
    "end_time": "string",
    "status": "pending",
    "error": "string"
  }
}
```

<h3 id="save_v2_session_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session details|[V2Session](#schemav2session)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_components

<a id="opIdget_v2_components"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/components HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/components \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/components', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/components`

*Retrieve the state of a collection of Components*

Retrieve the full collection of Components in the form of a
ComponentArray. Full results can also be filtered by query
parameters. Only the first filter parameter of each type is
used and the parameters are applied in an AND fashion.
If the collection is empty or the filters have no match, an
empty array is returned.

<h3 id="get_v2_components-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|ids|query|[V2ComponentId](#schemav2componentid)|false|Retrieve the Components with the given ID|
|session|query|string|false|Retrieve the Components with the given Session ID.|
|staged_session|query|string|false|Retrieve the Components with the given staged Session ID.|
|enabled|query|boolean|false|Retrieve the Components with the "enabled" state.|
|phase|query|string|false|Retrieve the Components in the given phase.|
|status|query|string|false|Retrieve the Components with the given status.|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**ids**: Retrieve the Components with the given ID
(e.g. xname for hardware Components). Can be chained
for selecting groups of Components.

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
[
  {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "session": "session-20190728032600",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "last_action": {
      "last_updated": "2019-07-28T03:26:00Z",
      "action": "string",
      "failed": true
    },
    "event_stats": {
      "power_on_attempts": 0,
      "power_off_graceful_attempts": 0,
      "power_off_forceful_attempts": 0
    },
    "status": {
      "phase": "string",
      "status": "string",
      "status_override": "string"
    },
    "enabled": true,
    "error": "string",
    "session": "session-20190728032600",
    "retry_policy": 1
  }
]
```

<h3 id="get_v2_components-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of Component states|[V2ComponentArray](#schemav2componentarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## put_v2_components

<a id="opIdput_v2_components"></a>

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/bos/v2/components HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/bos/v2/components \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.put('https://api-gw-service-nmn.local/apis/bos/v2/components', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/bos/v2/components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /v2/components`

*Add or Replace a collection of Components*

Update the state for a collection of Components in the BOS database

> Body parameter

```json
[
  {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "bss_token": "string"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "bss_token": "string"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "session": "session-20190728032600"
    },
    "last_action": {
      "action": "string",
      "failed": true
    },
    "event_stats": {
      "power_on_attempts": 0,
      "power_off_graceful_attempts": 0,
      "power_off_forceful_attempts": 0
    },
    "status": {
      "phase": "string",
      "status_override": "string"
    },
    "enabled": true,
    "error": "string",
    "session": "session-20190728032600",
    "retry_policy": 1
  }
]
```

<h3 id="put_v2_components-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2ComponentArray](#schemav2componentarray)|true|The state for an array of Components|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
[
  {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "session": "session-20190728032600",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "last_action": {
      "last_updated": "2019-07-28T03:26:00Z",
      "action": "string",
      "failed": true
    },
    "event_stats": {
      "power_on_attempts": 0,
      "power_off_graceful_attempts": 0,
      "power_off_forceful_attempts": 0
    },
    "status": {
      "phase": "string",
      "status": "string",
      "status_override": "string"
    },
    "enabled": true,
    "error": "string",
    "session": "session-20190728032600",
    "retry_policy": 1
  }
]
```

<h3 id="put_v2_components-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of Component states|[V2ComponentArray](#schemav2componentarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v2_components

<a id="opIdpatch_v2_components"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/bos/v2/components HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v2/components \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/bos/v2/components', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/bos/v2/components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v2/components`

*Update a collection of Components*

Update the state for a collection of Components in the BOS database

> Body parameter

```json
{
  "patch": {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "bss_token": "string"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "bss_token": "string"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "session": "session-20190728032600"
    },
    "last_action": {
      "action": "string",
      "failed": true
    },
    "event_stats": {
      "power_on_attempts": 0,
      "power_off_graceful_attempts": 0,
      "power_off_forceful_attempts": 0
    },
    "status": {
      "phase": "string",
      "status_override": "string"
    },
    "enabled": true,
    "error": "string",
    "session": "session-20190728032600",
    "retry_policy": 1
  },
  "filters": {
    "ids": "string",
    "session": "session-20190728032600"
  }
}
```

<h3 id="patch_v2_components-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|any|true|The state for an array of Components|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
[
  {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "session": "session-20190728032600",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "last_action": {
      "last_updated": "2019-07-28T03:26:00Z",
      "action": "string",
      "failed": true
    },
    "event_stats": {
      "power_on_attempts": 0,
      "power_off_graceful_attempts": 0,
      "power_off_forceful_attempts": 0
    },
    "status": {
      "phase": "string",
      "status": "string",
      "status_override": "string"
    },
    "enabled": true,
    "error": "string",
    "session": "session-20190728032600",
    "retry_policy": 1
  }
]
```

<h3 id="patch_v2_components-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of Component states|[V2ComponentArray](#schemav2componentarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_component

<a id="opIdget_v2_component"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/components/{component_id}`

*Retrieve the state of a single Component*

Retrieve the current and desired state of a single Component

<h3 id="get_v2_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|component_id|path|[V2ComponentId](#schemav2componentid)|true|Component ID. e.g. xname for hardware Components|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "session": "session-20190728032600",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "last_action": {
    "last_updated": "2019-07-28T03:26:00Z",
    "action": "string",
    "failed": true
  },
  "event_stats": {
    "power_on_attempts": 0,
    "power_off_graceful_attempts": 0,
    "power_off_forceful_attempts": 0
  },
  "status": {
    "phase": "string",
    "status": "string",
    "status_override": "string"
  },
  "enabled": true,
  "error": "string",
  "session": "session-20190728032600",
  "retry_policy": 1
}
```

<h3 id="get_v2_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single Component state|[V2Component](#schemav2component)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## put_v2_component

<a id="opIdput_v2_component"></a>

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.put('https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /v2/components/{component_id}`

*Add or Replace a single Component*

Update the state for a given Component in the BOS database

> Body parameter

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "bss_token": "string"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "bss_token": "string"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "session": "session-20190728032600"
  },
  "last_action": {
    "action": "string",
    "failed": true
  },
  "event_stats": {
    "power_on_attempts": 0,
    "power_off_graceful_attempts": 0,
    "power_off_forceful_attempts": 0
  },
  "status": {
    "phase": "string",
    "status_override": "string"
  },
  "enabled": true,
  "error": "string",
  "session": "session-20190728032600",
  "retry_policy": 1
}
```

<h3 id="put_v2_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2Component](#schemav2component)|true|The state for a single Component|
|component_id|path|[V2ComponentId](#schemav2componentid)|true|Component ID. e.g. xname for hardware Components|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "session": "session-20190728032600",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "last_action": {
    "last_updated": "2019-07-28T03:26:00Z",
    "action": "string",
    "failed": true
  },
  "event_stats": {
    "power_on_attempts": 0,
    "power_off_graceful_attempts": 0,
    "power_off_forceful_attempts": 0
  },
  "status": {
    "phase": "string",
    "status": "string",
    "status_override": "string"
  },
  "enabled": true,
  "error": "string",
  "session": "session-20190728032600",
  "retry_policy": 1
}
```

<h3 id="put_v2_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single Component state|[V2Component](#schemav2component)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v2_component

<a id="opIdpatch_v2_component"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id}', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v2/components/{component_id}`

*Update a single Component*

Update the state for a given Component in the BOS database

> Body parameter

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "bss_token": "string"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "bss_token": "string"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "session": "session-20190728032600"
  },
  "last_action": {
    "action": "string",
    "failed": true
  },
  "event_stats": {
    "power_on_attempts": 0,
    "power_off_graceful_attempts": 0,
    "power_off_forceful_attempts": 0
  },
  "status": {
    "phase": "string",
    "status_override": "string"
  },
  "enabled": true,
  "error": "string",
  "session": "session-20190728032600",
  "retry_policy": 1
}
```

<h3 id="patch_v2_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2Component](#schemav2component)|true|The state for a single Component|
|component_id|path|[V2ComponentId](#schemav2componentid)|true|Component ID. e.g. xname for hardware Components|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "session": "session-20190728032600",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "last_action": {
    "last_updated": "2019-07-28T03:26:00Z",
    "action": "string",
    "failed": true
  },
  "event_stats": {
    "power_on_attempts": 0,
    "power_off_graceful_attempts": 0,
    "power_off_forceful_attempts": 0
  },
  "status": {
    "phase": "string",
    "status": "string",
    "status_override": "string"
  },
  "enabled": true,
  "error": "string",
  "session": "session-20190728032600",
  "retry_policy": 1
}
```

<h3 id="patch_v2_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single Component state|[V2Component](#schemav2component)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|The update was not allowed due to a conflict.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v2_component

<a id="opIddelete_v2_component"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} \
  -H 'Accept: application/problem+json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id}', headers = headers)

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
        "Accept": []string{"application/problem+json"},
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v2/components/{component_id}`

*Delete a single Component*

Delete the given Component

<h3 id="delete_v2_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|component_id|path|[V2ComponentId](#schemav2componentid)|true|Component ID. e.g. xname for hardware Components|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 404 Response

```json
{
  "type": "about:blank",
  "title": "string",
  "status": 400,
  "instance": "http://example.com",
  "detail": "string"
}
```

<h3 id="delete_v2_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## post_v2_apply_staged

<a id="opIdpost_v2_apply_staged"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/bos/v2/applystaged HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json
Cray-Tenant-Name: vcluster-my-tenant1

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v2/applystaged \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Cray-Tenant-Name: vcluster-my-tenant1'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1'
}

r = requests.post('https://api-gw-service-nmn.local/apis/bos/v2/applystaged', headers = headers)

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
        "Cray-Tenant-Name": []string{"vcluster-my-tenant1"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/bos/v2/applystaged", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v2/applystaged`

*Start a staged Session for the specified Components*

Given a list of xnames, this will trigger the start of any Sessions
staged for those Components.  Components without a staged Session
will be ignored, and a list all Components that are acted on will
be returned in the response.

> Body parameter

```json
{
  "xnames": [
    "string"
  ]
}
```

<h3 id="post_v2_apply_staged-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2ApplyStagedComponents](#schemav2applystagedcomponents)|true|A list of xnames that should have their staged Session applied.|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this paarameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "succeeded": [
    "string"
  ],
  "failed": [
    "string"
  ],
  "ignored": [
    "string"
  ]
}
```

<h3 id="post_v2_apply_staged-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of xnames that should have their staged Session applied.|[V2ApplyStagedStatus](#schemav2applystagedstatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v2_options

<a id="opIdpatch_v2_options"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/bos/v2/options HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v2/options \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/bos/v2/options', headers = headers)

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/bos/v2/options", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v2/options`

*Update BOS service options*

Update one or more of the BOS service options.

> Body parameter

```json
{
  "cleanup_completed_session_ttl": "3d",
  "clear_stage": true,
  "component_actual_state_ttl": "6h",
  "disable_components_on_completion": true,
  "discovery_frequency": 33554432,
  "logging_level": "string",
  "max_boot_wait_time": 1048576,
  "max_power_on_wait_time": 1048576,
  "max_power_off_wait_time": 1048576,
  "polling_frequency": 1048576,
  "default_retry_policy": 1
}
```

<h3 id="patch_v2_options-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2Options](#schemav2options)|true|Service-wide options|

> Example responses

> 200 Response

```json
{
  "cleanup_completed_session_ttl": "3d",
  "clear_stage": true,
  "component_actual_state_ttl": "6h",
  "disable_components_on_completion": true,
  "discovery_frequency": 33554432,
  "logging_level": "string",
  "max_boot_wait_time": 1048576,
  "max_power_on_wait_time": 1048576,
  "max_power_off_wait_time": 1048576,
  "polling_frequency": 1048576,
  "default_retry_policy": 1
}
```

<h3 id="patch_v2_options-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of service-wide options|[V2Options](#schemav2options)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_version_v2

<a id="opIdget_version_v2"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/version HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/version \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/version', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/version", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/version`

*Get API version*

Return the API version

> Example responses

> 200 Response

```json
{
  "major": "string",
  "minor": "string",
  "patch": "string",
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}
```

<h3 id="get_version_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Get version details
The versioning system uses [semver](https://semver.org/).
## Link Relationships
* self : Link to itself
* versions : Link back to the versions resource|[Version](#schemaversion)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-orchestration-service-options">options</h1>

## get_v2_options

<a id="opIdget_v2_options"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/v2/options HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/options \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/bos/v2/options', headers = headers)

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/bos/v2/options", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/options`

*Retrieve the BOS service options*

Retrieve the list of BOS service options.

> Example responses

> 200 Response

```json
{
  "cleanup_completed_session_ttl": "3d",
  "clear_stage": true,
  "component_actual_state_ttl": "6h",
  "disable_components_on_completion": true,
  "discovery_frequency": 33554432,
  "logging_level": "string",
  "max_boot_wait_time": 1048576,
  "max_power_on_wait_time": 1048576,
  "max_power_off_wait_time": 1048576,
  "polling_frequency": 1048576,
  "default_retry_policy": 1
}
```

<h3 id="get_v2_options-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of service-wide options|[V2Options](#schemav2options)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_AgeString">AgeString</h2>
<!-- backwards compatibility -->
<a id="schemaagestring"></a>
<a id="schema_AgeString"></a>
<a id="tocSagestring"></a>
<a id="tocsagestring"></a>

```json
"3d"

```

Age in minutes (e.g. "3m"), hours (e.g. "5h"), days (e.g. "10d"), or weeks (e.g. "2w").

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string(^(0|0[mMhHdDwW]|[1-9][0-9]*[mMhHdDwW])$)|false|none|Age in minutes (e.g. "3m"), hours (e.g. "5h"), days (e.g. "10d"), or weeks (e.g. "2w").|

<h2 id="tocS_BootInitrdPath">BootInitrdPath</h2>
<!-- backwards compatibility -->
<a id="schemabootinitrdpath"></a>
<a id="schema_BootInitrdPath"></a>
<a id="tocSbootinitrdpath"></a>
<a id="tocsbootinitrdpath"></a>

```json
"s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"

```

A path to the initrd to use for booting.

It is recommended that this should be no more than 4095 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|A path to the initrd to use for booting.<br><br>It is recommended that this should be no more than 4095 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_BootKernelPath">BootKernelPath</h2>
<!-- backwards compatibility -->
<a id="schemabootkernelpath"></a>
<a id="schema_BootKernelPath"></a>
<a id="tocSbootkernelpath"></a>
<a id="tocsbootkernelpath"></a>

```json
"s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel"

```

A path to the kernel to use for booting.

It is recommended that this should be no more than 4095 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|A path to the kernel to use for booting.<br><br>It is recommended that this should be no more than 4095 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_BootManifestPath">BootManifestPath</h2>
<!-- backwards compatibility -->
<a id="schemabootmanifestpath"></a>
<a id="schema_BootManifestPath"></a>
<a id="tocSbootmanifestpath"></a>
<a id="tocsbootmanifestpath"></a>

```json
"s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json"

```

A path identifying the metadata describing the components of the boot image.
This could be a URI, URL, etc, depending on the type of the Boot Set.

It is recommended that this should be 1-4095 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|A path identifying the metadata describing the components of the boot image.<br>This could be a URI, URL, etc, depending on the type of the Boot Set.<br><br>It is recommended that this should be 1-4095 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_BootKernelParameters">BootKernelParameters</h2>
<!-- backwards compatibility -->
<a id="schemabootkernelparameters"></a>
<a id="schema_BootKernelParameters"></a>
<a id="tocSbootkernelparameters"></a>
<a id="tocsbootkernelparameters"></a>

```json
"console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}"

```

The kernel parameters to use to boot the nodes.

Linux kernel parameters may never exceed 4096 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The kernel parameters to use to boot the nodes.<br><br>Linux kernel parameters may never exceed 4096 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_BootSetEtag">BootSetEtag</h2>
<!-- backwards compatibility -->
<a id="schemabootsetetag"></a>
<a id="schema_BootSetEtag"></a>
<a id="tocSbootsetetag"></a>
<a id="tocsbootsetetag"></a>

```json
"1cc4eef4f407bd8a62d7d66ee4b9e9c8"

```

This is the 'entity tag'. It helps verify the version of metadata describing the components of the boot image we are working with.

ETags are defined as being 1-65536 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is the 'entity tag'. It helps verify the version of metadata describing the components of the boot image we are working with.<br><br>ETags are defined as being 1-65536 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_BootSetName">BootSetName</h2>
<!-- backwards compatibility -->
<a id="schemabootsetname"></a>
<a id="schema_BootSetName"></a>
<a id="tocSbootsetname"></a>
<a id="tocsbootsetname"></a>

```json
"compute"

```

The Boot Set name.

It is recommended that:
* Boot Set names should be 1-127 characters in length.
* Boot Set names should use only letters, digits, periods (.), dashes (-), and underscores (_).
* Boot Set names should begin and end with a letter or digit.

These restrictions are not enforced in this version of BOS, but they are
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The Boot Set name.<br><br>It is recommended that:<br>* Boot Set names should be 1-127 characters in length.<br>* Boot Set names should use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Boot Set names should begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_BootSetRootfsProvider">BootSetRootfsProvider</h2>
<!-- backwards compatibility -->
<a id="schemabootsetrootfsprovider"></a>
<a id="schema_BootSetRootfsProvider"></a>
<a id="tocSbootsetrootfsprovider"></a>
<a id="tocsbootsetrootfsprovider"></a>

```json
"cpss3"

```

The root file system provider.

It is recommended that this should be 1-511 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The root file system provider.<br><br>It is recommended that this should be 1-511 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_BootSetRootfsProviderPassthrough">BootSetRootfsProviderPassthrough</h2>
<!-- backwards compatibility -->
<a id="schemabootsetrootfsproviderpassthrough"></a>
<a id="schema_BootSetRootfsProviderPassthrough"></a>
<a id="tocSbootsetrootfsproviderpassthrough"></a>
<a id="tocsbootsetrootfsproviderpassthrough"></a>

```json
"dvs:api-gw-service-nmn.local:300:nmn0"

```

The root file system provider passthrough.
These are additional kernel parameters that will be appended to
the 'rootfs=<protocol>' kernel parameter

Linux kernel parameters may never exceed 4096 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The root file system provider passthrough.<br>These are additional kernel parameters that will be appended to<br>the 'rootfs=<protocol>' kernel parameter<br><br>Linux kernel parameters may never exceed 4096 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_BootSetType">BootSetType</h2>
<!-- backwards compatibility -->
<a id="schemabootsettype"></a>
<a id="schema_BootSetType"></a>
<a id="tocSbootsettype"></a>
<a id="tocsbootsettype"></a>

```json
"s3"

```

The MIME type of the metadata describing the components of the boot image. This type controls how BOS processes the path attribute.

It is recommended that this should be 1-127 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The MIME type of the metadata describing the components of the boot image. This type controls how BOS processes the path attribute.<br><br>It is recommended that this should be 1-127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_CfsConfiguration">CfsConfiguration</h2>
<!-- backwards compatibility -->
<a id="schemacfsconfiguration"></a>
<a id="schema_CfsConfiguration"></a>
<a id="tocScfsconfiguration"></a>
<a id="tocscfsconfiguration"></a>

```json
"compute-23.4.0"

```

The name of configuration to be applied.

It is recommended that this should be no more than 127 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The name of configuration to be applied.<br><br>It is recommended that this should be no more than 127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_EnableCfs">EnableCfs</h2>
<!-- backwards compatibility -->
<a id="schemaenablecfs"></a>
<a id="schema_EnableCfs"></a>
<a id="tocSenablecfs"></a>
<a id="tocsenablecfs"></a>

```json
true

```

Whether to enable the Configuration Framework Service (CFS).

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|boolean|false|none|Whether to enable the Configuration Framework Service (CFS).|

<h2 id="tocS_HardwareComponentName">HardwareComponentName</h2>
<!-- backwards compatibility -->
<a id="schemahardwarecomponentname"></a>
<a id="schema_HardwareComponentName"></a>
<a id="tocShardwarecomponentname"></a>
<a id="tocshardwarecomponentname"></a>

```json
"x3001c0s39b0n0"

```

Hardware component name (xname).

It is recommended that this should be 1-127 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Hardware component name (xname).<br><br>It is recommended that this should be 1-127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_Healthz">Healthz</h2>
<!-- backwards compatibility -->
<a id="schemahealthz"></a>
<a id="schema_Healthz"></a>
<a id="tocShealthz"></a>
<a id="tocshealthz"></a>

```json
{
  "dbStatus": "string",
  "apiStatus": "string"
}

```

Service health status

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|dbStatus|string|false|none|none|
|apiStatus|string|false|none|none|

<h2 id="tocS_Link">Link</h2>
<!-- backwards compatibility -->
<a id="schemalink"></a>
<a id="schema_Link"></a>
<a id="tocSlink"></a>
<a id="tocslink"></a>

```json
{
  "href": "string",
  "rel": "string"
}

```

Link to other resources

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|href|string|false|none|none|
|rel|string|false|none|none|

<h2 id="tocS_LinkList">LinkList</h2>
<!-- backwards compatibility -->
<a id="schemalinklist"></a>
<a id="schema_LinkList"></a>
<a id="tocSlinklist"></a>
<a id="tocslinklist"></a>

```json
[
  {
    "href": "string",
    "rel": "string"
  }
]

```

List of links to other resources

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Link](#schemalink)]|false|none|List of links to other resources|

<h2 id="tocS_LinkListReadOnly">LinkListReadOnly</h2>
<!-- backwards compatibility -->
<a id="schemalinklistreadonly"></a>
<a id="schema_LinkListReadOnly"></a>
<a id="tocSlinklistreadonly"></a>
<a id="tocslinklistreadonly"></a>

```json
[
  {
    "href": "string",
    "rel": "string"
  }
]

```

List of links to other resources

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Link](#schemalink)]|false|read-only|List of links to other resources|

<h2 id="tocS_NodeList">NodeList</h2>
<!-- backwards compatibility -->
<a id="schemanodelist"></a>
<a id="schema_NodeList"></a>
<a id="tocSnodelist"></a>
<a id="tocsnodelist"></a>

```json
[
  "x3000c0s19b1n0",
  "x3000c0s19b2n0"
]

```

A node list that is required to have at least one node.

It is recommended that this list should be 1-65535 items in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[HardwareComponentName](#schemahardwarecomponentname)]|false|none|A node list that is required to have at least one node.<br><br>It is recommended that this list should be 1-65535 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_NodeListEmptyOk">NodeListEmptyOk</h2>
<!-- backwards compatibility -->
<a id="schemanodelistemptyok"></a>
<a id="schema_NodeListEmptyOk"></a>
<a id="tocSnodelistemptyok"></a>
<a id="tocsnodelistemptyok"></a>

```json
[
  "x3000c0s19b1n0",
  "x3000c0s19b2n0"
]

```

A node list that is allowed to be empty.

It is recommended that this list should be no more than 65535 items in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[HardwareComponentName](#schemahardwarecomponentname)]|false|none|A node list that is allowed to be empty.<br><br>It is recommended that this list should be no more than 65535 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_NodeGroupList">NodeGroupList</h2>
<!-- backwards compatibility -->
<a id="schemanodegrouplist"></a>
<a id="schema_NodeGroupList"></a>
<a id="tocSnodegrouplist"></a>
<a id="tocsnodegrouplist"></a>

```json
[
  "string"
]

```

Node group list. Allows actions against associated nodes by logical groupings.

It is recommended that this list should be 1-4095 items in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

*None*

<h2 id="tocS_NodeRoleList">NodeRoleList</h2>
<!-- backwards compatibility -->
<a id="schemanoderolelist"></a>
<a id="schema_NodeRoleList"></a>
<a id="tocSnoderolelist"></a>
<a id="tocsnoderolelist"></a>

```json
[
  "Compute",
  "Application"
]

```

Node role list. Allows actions against nodes with associated roles.

It is recommended that this list should be 1-1023 items in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

*None*

<h2 id="tocS_ProblemDetails">ProblemDetails</h2>
<!-- backwards compatibility -->
<a id="schemaproblemdetails"></a>
<a id="schema_ProblemDetails"></a>
<a id="tocSproblemdetails"></a>
<a id="tocsproblemdetails"></a>

```json
{
  "type": "about:blank",
  "title": "string",
  "status": 400,
  "instance": "http://example.com",
  "detail": "string"
}

```

An error response for RFC 7807 problem details.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|type|string(uri)|false|none|Relative URI reference to the type of problem which includes human<br>readable documentation.|
|title|string|false|none|Short, human-readable summary of the problem, should not change by<br>occurrence.|
|status|integer|false|none|HTTP status code|
|instance|string(uri)|false|none|A relative URI reference that identifies the specific occurrence of<br>the problem|
|detail|string|false|none|A human-readable explanation specific to this occurrence of the<br>problem. Focus on helping correct the problem, rather than giving<br>debugging information.|

<h2 id="tocS_SessionLimit">SessionLimit</h2>
<!-- backwards compatibility -->
<a id="schemasessionlimit"></a>
<a id="schema_SessionLimit"></a>
<a id="tocSsessionlimit"></a>
<a id="tocssessionlimit"></a>

```json
"string"

```

A comma-separated list of nodes, groups, or roles to which the Session
will be limited. Components are treated as OR operations unless
preceded by "&" for AND or "!" for NOT.

It is recommended that this should be 1-65535 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|A comma-separated list of nodes, groups, or roles to which the Session<br>will be limited. Components are treated as OR operations unless<br>preceded by "&" for AND or "!" for NOT.<br><br>It is recommended that this should be 1-65535 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_SessionTemplateDescription">SessionTemplateDescription</h2>
<!-- backwards compatibility -->
<a id="schemasessiontemplatedescription"></a>
<a id="schema_SessionTemplateDescription"></a>
<a id="tocSsessiontemplatedescription"></a>
<a id="tocssessiontemplatedescription"></a>

```json
"string"

```

An optional description for the Session Template.

It is recommended that this should be 1-1023 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|An optional description for the Session Template.<br><br>It is recommended that this should be 1-1023 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_SessionTemplateName">SessionTemplateName</h2>
<!-- backwards compatibility -->
<a id="schemasessiontemplatename"></a>
<a id="schema_SessionTemplateName"></a>
<a id="tocSsessiontemplatename"></a>
<a id="tocssessiontemplatename"></a>

```json
"cle-1.0.0"

```

Name of the Session Template.

It is recommended to use names which meet the following restrictions:
* Maximum length of 127 characters.
* Use only letters, digits, periods (.), dashes (-), and underscores (_).
* Begin and end with a letter or digit.

These restrictions are not enforced in this version of BOS, but they are
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* Maximum length of 127 characters.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_TenantName">TenantName</h2>
<!-- backwards compatibility -->
<a id="schematenantname"></a>
<a id="schema_TenantName"></a>
<a id="tocStenantname"></a>
<a id="tocstenantname"></a>

```json
"vcluster-my-tenant1"

```

Name of a tenant. Used for multi-tenancy. An empty string means no tenant.

It is recommended that this should be no more than 127 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Name of a tenant. Used for multi-tenancy. An empty string means no tenant.<br><br>It is recommended that this should be no more than 127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_Version">Version</h2>
<!-- backwards compatibility -->
<a id="schemaversion"></a>
<a id="schema_Version"></a>
<a id="tocSversion"></a>
<a id="tocsversion"></a>

```json
{
  "major": "string",
  "minor": "string",
  "patch": "string",
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}

```

Version data

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|major|string|false|none|none|
|minor|string|false|none|none|
|patch|string|false|none|none|
|links|[LinkList](#schemalinklist)|false|none|List of links to other resources|

<h2 id="tocS_V1CfsBranch">V1CfsBranch</h2>
<!-- backwards compatibility -->
<a id="schemav1cfsbranch"></a>
<a id="schema_V1CfsBranch"></a>
<a id="tocSv1cfsbranch"></a>
<a id="tocsv1cfsbranch"></a>

```json
"string"

```

The name of the branch containing the configuration that you want to
apply to the nodes. Mutually exclusive with commit. (DEPRECATED)

It is recommended that this should be 1-1023 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The name of the branch containing the configuration that you want to<br>apply to the nodes. Mutually exclusive with commit. (DEPRECATED)<br><br>It is recommended that this should be 1-1023 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V1CfsUrl">V1CfsUrl</h2>
<!-- backwards compatibility -->
<a id="schemav1cfsurl"></a>
<a id="schema_V1CfsUrl"></a>
<a id="tocSv1cfsurl"></a>
<a id="tocsv1cfsurl"></a>

```json
"string"

```

The clone URL for the repository providing the configuration. (DEPRECATED)

It is recommended that this should be 1-4096 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The clone URL for the repository providing the configuration. (DEPRECATED)<br><br>It is recommended that this should be 1-4096 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V1CfsParameters">V1CfsParameters</h2>
<!-- backwards compatibility -->
<a id="schemav1cfsparameters"></a>
<a id="schema_V1CfsParameters"></a>
<a id="tocSv1cfsparameters"></a>
<a id="tocsv1cfsparameters"></a>

```json
{
  "clone_url": "string",
  "branch": "string",
  "commit": "string",
  "playbook": "string",
  "configuration": "compute-23.4.0"
}

```

This is the collection of parameters that are passed to the Configuration
Framework Service when configuration is enabled.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|clone_url|[V1CfsUrl](#schemav1cfsurl)|false|none|The clone URL for the repository providing the configuration. (DEPRECATED)<br><br>It is recommended that this should be 1-4096 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|branch|[V1CfsBranch](#schemav1cfsbranch)|false|none|The name of the branch containing the configuration that you want to<br>apply to the nodes. Mutually exclusive with commit. (DEPRECATED)<br><br>It is recommended that this should be 1-1023 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|commit|string|false|none|The commit ID of the configuration that you want to<br>apply to the nodes. Mutually exclusive with branch. (DEPRECATED)<br><br>git commit hashes are hexadecimal strings with a length of 40 characters (although<br>fewer characters may be sufficient to uniquely identify a commit in some cases).<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|playbook|string|false|none|The name of the playbook to run for configuration. The file path must be specified<br>relative to the base directory of the config repository. (DEPRECATED)<br><br>It is recommended that this should be 1-255 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|configuration|[CfsConfiguration](#schemacfsconfiguration)|false|none|The name of configuration to be applied.<br><br>It is recommended that this should be no more than 127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V1CompleteMetadata">V1CompleteMetadata</h2>
<!-- backwards compatibility -->
<a id="schemav1completemetadata"></a>
<a id="schema_V1CompleteMetadata"></a>
<a id="tocSv1completemetadata"></a>
<a id="tocsv1completemetadata"></a>

```json
true

```

Is the object's status complete

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|boolean|false|none|Is the object's status complete|

<h2 id="tocS_V1ErrorCountMetadata">V1ErrorCountMetadata</h2>
<!-- backwards compatibility -->
<a id="schemav1errorcountmetadata"></a>
<a id="schema_V1ErrorCountMetadata"></a>
<a id="tocSv1errorcountmetadata"></a>
<a id="tocsv1errorcountmetadata"></a>

```json
0

```

How many errors were encountered

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|integer|false|none|How many errors were encountered|

<h2 id="tocS_V1InProgressMetadata">V1InProgressMetadata</h2>
<!-- backwards compatibility -->
<a id="schemav1inprogressmetadata"></a>
<a id="schema_V1InProgressMetadata"></a>
<a id="tocSv1inprogressmetadata"></a>
<a id="tocsv1inprogressmetadata"></a>

```json
false

```

Is the object still doing something

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|boolean|false|none|Is the object still doing something|

<h2 id="tocS_V1StartTimeMetadata">V1StartTimeMetadata</h2>
<!-- backwards compatibility -->
<a id="schemav1starttimemetadata"></a>
<a id="schema_V1StartTimeMetadata"></a>
<a id="tocSv1starttimemetadata"></a>
<a id="tocsv1starttimemetadata"></a>

```json
"2020-04-24T12:00"

```

The start time

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The start time|

<h2 id="tocS_V1StopTimeMetadata">V1StopTimeMetadata</h2>
<!-- backwards compatibility -->
<a id="schemav1stoptimemetadata"></a>
<a id="schema_V1StopTimeMetadata"></a>
<a id="tocSv1stoptimemetadata"></a>
<a id="tocsv1stoptimemetadata"></a>

```json
"2020-04-24T12:00"

```

The stop time. In some contexts, the value may be null before the operation finishes.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string¦null|false|none|The stop time. In some contexts, the value may be null before the operation finishes.|

<h2 id="tocS_V1GenericMetadata">V1GenericMetadata</h2>
<!-- backwards compatibility -->
<a id="schemav1genericmetadata"></a>
<a id="schema_V1GenericMetadata"></a>
<a id="tocSv1genericmetadata"></a>
<a id="tocsv1genericmetadata"></a>

```json
{
  "complete": true,
  "error_count": 0,
  "in_progress": false,
  "start_time": "2020-04-24T12:00",
  "stop_time": "2020-04-24T12:00"
}

```

The status metadata

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|complete|[V1CompleteMetadata](#schemav1completemetadata)|false|none|Is the object's status complete|
|error_count|[V1ErrorCountMetadata](#schemav1errorcountmetadata)|false|none|How many errors were encountered|
|in_progress|[V1InProgressMetadata](#schemav1inprogressmetadata)|false|none|Is the object still doing something|
|start_time|[V1StartTimeMetadata](#schemav1starttimemetadata)|false|none|The start time|
|stop_time|[V1StopTimeMetadata](#schemav1stoptimemetadata)|false|none|The stop time. In some contexts, the value may be null before the operation finishes.|

<h2 id="tocS_V1PhaseCategoryName">V1PhaseCategoryName</h2>
<!-- backwards compatibility -->
<a id="schemav1phasecategoryname"></a>
<a id="schema_V1PhaseCategoryName"></a>
<a id="tocSv1phasecategoryname"></a>
<a id="tocsv1phasecategoryname"></a>

```json
"Succeeded"

```

Name of the Phase Category
not_started, in_progress, succeeded, failed, or excluded

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Name of the Phase Category<br>not_started, in_progress, succeeded, failed, or excluded|

<h2 id="tocS_V1PhaseCategoryStatus">V1PhaseCategoryStatus</h2>
<!-- backwards compatibility -->
<a id="schemav1phasecategorystatus"></a>
<a id="schema_V1PhaseCategoryStatus"></a>
<a id="tocSv1phasecategorystatus"></a>
<a id="tocsv1phasecategorystatus"></a>

```json
{
  "name": "Succeeded",
  "node_list": [
    "x3000c0s19b1n0",
    "x3000c0s19b2n0"
  ]
}

```

A list of the nodes in a given category within a Phase.

## Link Relationships

* self : The phase category status object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[V1PhaseCategoryName](#schemav1phasecategoryname)|false|none|Name of the Phase Category<br>not_started, in_progress, succeeded, failed, or excluded|
|node_list|[NodeListEmptyOk](#schemanodelistemptyok)|false|none|A node list that is allowed to be empty.<br><br>It is recommended that this list should be no more than 65535 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V1PhaseStatus">V1PhaseStatus</h2>
<!-- backwards compatibility -->
<a id="schemav1phasestatus"></a>
<a id="schema_V1PhaseStatus"></a>
<a id="tocSv1phasestatus"></a>
<a id="tocsv1phasestatus"></a>

```json
{
  "name": "Boot",
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "categories": [
    {
      "name": "Succeeded",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ]
    }
  ],
  "errors": {
    "property1": [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ],
    "property2": [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ]
  }
}

```

The phase's status. It is a list of all of the nodes in the phase and
what category those nodes fall into within the phase.

## Link Relationships

* self : The phase status object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|Name of the Phase<br>boot, configure, or shutdown|
|metadata|[V1GenericMetadata](#schemav1genericmetadata)|false|none|The status metadata|
|categories|[[V1PhaseCategoryStatus](#schemav1phasecategorystatus)]|false|none|[A list of the nodes in a given category within a Phase.<br><br>## Link Relationships<br><br>* self : The phase category status object<br>]|
|errors|[V1NodeErrorsList](#schemav1nodeerrorslist)|false|none|Categorizing nodes into failures by the type of error they have.<br>This is an additive characterization. Nodes will be added to existing errors.<br>This does not overwrite previously existing errors.|

<h2 id="tocS_V1SessionId">V1SessionId</h2>
<!-- backwards compatibility -->
<a id="schemav1sessionid"></a>
<a id="schema_V1SessionId"></a>
<a id="tocSv1sessionid"></a>
<a id="tocsv1sessionid"></a>

```json
"8deb0746-b18c-427c-84a8-72ec6a28642c"

```

Unique BOS v1 Session identifier.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string(uuid)|false|none|Unique BOS v1 Session identifier.|

<h2 id="tocS_V1BootSetStatus">V1BootSetStatus</h2>
<!-- backwards compatibility -->
<a id="schemav1bootsetstatus"></a>
<a id="schema_V1BootSetStatus"></a>
<a id="tocSv1bootsetstatus"></a>
<a id="tocsv1bootsetstatus"></a>

```json
{
  "name": "compute",
  "session": "8deb0746-b18c-427c-84a8-72ec6a28642c",
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "phases": [
    {
      "name": "Boot",
      "metadata": {
        "complete": true,
        "error_count": 0,
        "in_progress": false,
        "start_time": "2020-04-24T12:00",
        "stop_time": "2020-04-24T12:00"
      },
      "categories": [
        {
          "name": "Succeeded",
          "node_list": [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        }
      ],
      "errors": {
        "property1": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "property2": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      }
    }
  ],
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}

```

The status for a Boot Set. It as a list of the phase statuses for the Boot Set.

## Link Relationships

* self : The Boot Set Status object
* phase : A phase of the Boot Set

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[BootSetName](#schemabootsetname)|false|none|The Boot Set name.<br><br>It is recommended that:<br>* Boot Set names should be 1-127 characters in length.<br>* Boot Set names should use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Boot Set names should begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|session|[V1SessionId](#schemav1sessionid)|false|none|Unique BOS v1 Session identifier.|
|metadata|[V1GenericMetadata](#schemav1genericmetadata)|false|none|The status metadata|
|phases|[[V1PhaseStatus](#schemav1phasestatus)]|false|none|[The phase's status. It is a list of all of the nodes in the phase and<br>what category those nodes fall into within the phase.<br><br>## Link Relationships<br><br>* self : The phase status object<br>]|
|links|[LinkList](#schemalinklist)|false|none|List of links to other resources|

<h2 id="tocS_V1SessionStatus">V1SessionStatus</h2>
<!-- backwards compatibility -->
<a id="schemav1sessionstatus"></a>
<a id="schema_V1SessionStatus"></a>
<a id="tocSv1sessionstatus"></a>
<a id="tocsv1sessionstatus"></a>

```json
{
  "metadata": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  },
  "boot_sets": [
    "compute"
  ],
  "id": "8deb0746-b18c-427c-84a8-72ec6a28642c",
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}

```

The status for a Session. It is a list of all of the Boot Set Statuses in the Session.

## Link Relationships

* self : The Session status object
* boot sets: URL to access the Boot Set status

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|metadata|[V1GenericMetadata](#schemav1genericmetadata)|false|none|The status metadata|
|boot_sets|[[BootSetName](#schemabootsetname)]|false|none|The Boot Sets in the Session|
|id|[V1SessionId](#schemav1sessionid)|false|none|Unique BOS v1 Session identifier.|
|links|[LinkList](#schemalinklist)|false|none|List of links to other resources|

<h2 id="tocS_V1BootSet">V1BootSet</h2>
<!-- backwards compatibility -->
<a id="schemav1bootset"></a>
<a id="schema_V1BootSet"></a>
<a id="tocSv1bootset"></a>
<a id="tocsv1bootset"></a>

```json
{
  "name": "compute",
  "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
  "type": "s3",
  "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
  "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
  "node_list": [
    "x3000c0s19b1n0",
    "x3000c0s19b2n0"
  ],
  "node_roles_groups": [
    "Compute",
    "Application"
  ],
  "node_groups": [
    "string"
  ],
  "rootfs_provider": "cpss3",
  "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
  "network": "string",
  "boot_ordinal": 0,
  "shutdown_ordinal": 0
}

```

A Boot Set defines a collection of nodes and the information about the
boot artifacts and parameters to be sent to each node over the specified
network to enable these nodes to boot. When multiple Boot Sets are used
in a Session Template, the boot_ordinal and shutdown_ordinal indicate
the order in which Boot Sets need to be acted upon. Boot Sets sharing
the same ordinal number will be addressed at the same time.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[BootSetName](#schemabootsetname)|false|none|The Boot Set name.<br><br>It is recommended that:<br>* Boot Set names should be 1-127 characters in length.<br>* Boot Set names should use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Boot Set names should begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|path|[BootManifestPath](#schemabootmanifestpath)|true|none|A path identifying the metadata describing the components of the boot image.<br>This could be a URI, URL, etc, depending on the type of the Boot Set.<br><br>It is recommended that this should be 1-4095 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|type|[BootSetType](#schemabootsettype)|true|none|The MIME type of the metadata describing the components of the boot image. This type controls how BOS processes the path attribute.<br><br>It is recommended that this should be 1-127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|etag|[BootSetEtag](#schemabootsetetag)|false|none|This is the 'entity tag'. It helps verify the version of metadata describing the components of the boot image we are working with.<br><br>ETags are defined as being 1-65536 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|kernel_parameters|[BootKernelParameters](#schemabootkernelparameters)|false|none|The kernel parameters to use to boot the nodes.<br><br>Linux kernel parameters may never exceed 4096 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|node_list|[NodeList](#schemanodelist)|false|none|A node list that is required to have at least one node.<br><br>It is recommended that this list should be 1-65535 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|node_roles_groups|[NodeRoleList](#schemanoderolelist)|false|none|Node role list. Allows actions against nodes with associated roles.<br><br>It is recommended that this list should be 1-1023 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|node_groups|[NodeGroupList](#schemanodegrouplist)|false|none|Node group list. Allows actions against associated nodes by logical groupings.<br><br>It is recommended that this list should be 1-4095 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|rootfs_provider|[BootSetRootfsProvider](#schemabootsetrootfsprovider)|false|none|The root file system provider.<br><br>It is recommended that this should be 1-511 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|rootfs_provider_passthrough|[BootSetRootfsProviderPassthrough](#schemabootsetrootfsproviderpassthrough)|false|none|The root file system provider passthrough.<br>These are additional kernel parameters that will be appended to<br>the 'rootfs=<protocol>' kernel parameter<br><br>Linux kernel parameters may never exceed 4096 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|network|string|false|none|The network over which the node will boot.<br>Choices:  NMN -- Node Management Network|
|boot_ordinal|integer|false|none|The boot ordinal. This will establish the order for Boot Set operations.<br>Boot Sets boot in order from the lowest to highest boot_ordinal.<br><br>It is recommended that this should have a maximum value of 65535.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|shutdown_ordinal|integer|false|none|The shutdown ordinal. This will establish the order for Boot Set<br>shutdown operations. Sets shutdown from low to high shutdown_ordinal.<br><br>It is recommended that this should have a maximum value of 65535.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V1SessionTemplateUuid">V1SessionTemplateUuid</h2>
<!-- backwards compatibility -->
<a id="schemav1sessiontemplateuuid"></a>
<a id="schema_V1SessionTemplateUuid"></a>
<a id="tocSv1sessiontemplateuuid"></a>
<a id="tocsv1sessiontemplateuuid"></a>

```json
"my-session-template"

```

DEPRECATED - use templateName. This field is ignored if templateName is also set.

Name of the Session Template.

It is recommended to use names which meet the following restrictions:
* 1-127 characters in length.
* Use only letters, digits, periods (.), dashes (-), and underscores (_).
* Begin and end with a letter or digit.

These restrictions are not enforced in this version of BOS, but they are
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|DEPRECATED - use templateName. This field is ignored if templateName is also set.<br><br>Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* 1-127 characters in length.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V1SessionTemplate">V1SessionTemplate</h2>
<!-- backwards compatibility -->
<a id="schemav1sessiontemplate"></a>
<a id="schema_V1SessionTemplate"></a>
<a id="tocSv1sessiontemplate"></a>
<a id="tocsv1sessiontemplate"></a>

```json
{
  "name": "cle-1.0.0",
  "description": "string",
  "cfs_url": "string",
  "cfs_branch": "string",
  "enable_cfs": true,
  "cfs": {
    "clone_url": "string",
    "branch": "string",
    "commit": "string",
    "playbook": "string",
    "configuration": "compute-23.4.0"
  },
  "partition": "string",
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "network": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
      "network": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0
    }
  },
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}

```

A Session Template object represents a collection of resources and metadata.
A Session Template is used to create a Session which when combined with an
action (i.e. boot, configure, reboot, shutdown) will create a Kubernetes BOA job
to complete the required tasks for the operation.

## Link Relationships

* self : The Session Template object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[SessionTemplateName](#schemasessiontemplatename)|true|none|Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* Maximum length of 127 characters.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|description|[SessionTemplateDescription](#schemasessiontemplatedescription)|false|none|An optional description for the Session Template.<br><br>It is recommended that this should be 1-1023 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|cfs_url|[V1CfsUrl](#schemav1cfsurl)|false|none|The clone URL for the repository providing the configuration. (DEPRECATED)<br><br>It is recommended that this should be 1-4096 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|cfs_branch|[V1CfsBranch](#schemav1cfsbranch)|false|none|The name of the branch containing the configuration that you want to<br>apply to the nodes. Mutually exclusive with commit. (DEPRECATED)<br><br>It is recommended that this should be 1-1023 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|enable_cfs|[EnableCfs](#schemaenablecfs)|false|none|Whether to enable the Configuration Framework Service (CFS).|
|cfs|[V1CfsParameters](#schemav1cfsparameters)|false|none|This is the collection of parameters that are passed to the Configuration<br>Framework Service when configuration is enabled.|
|partition|string|false|none|The machine partition to operate on.<br><br>It is recommended that this should be 1-255 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|boot_sets|object|false|none|Mapping from Boot Set names to Boot Sets.<br><br>It is recommended that:<br>* At least one Boot Set should be defined, because a Session Template with no<br>  Boot Sets is not functional.<br>* Boot Set names should be 1-127 characters in length.<br>* Boot Set names should use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Boot Set names should begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|» **additionalProperties**|[V1BootSet](#schemav1bootset)|false|none|A Boot Set defines a collection of nodes and the information about the<br>boot artifacts and parameters to be sent to each node over the specified<br>network to enable these nodes to boot. When multiple Boot Sets are used<br>in a Session Template, the boot_ordinal and shutdown_ordinal indicate<br>the order in which Boot Sets need to be acted upon. Boot Sets sharing<br>the same ordinal number will be addressed at the same time.|
|links|[LinkListReadOnly](#schemalinklistreadonly)|false|none|List of links to other resources|

<h2 id="tocS_V1BoaKubernetesJob">V1BoaKubernetesJob</h2>
<!-- backwards compatibility -->
<a id="schemav1boakubernetesjob"></a>
<a id="schema_V1BoaKubernetesJob"></a>
<a id="tocSv1boakubernetesjob"></a>
<a id="tocsv1boakubernetesjob"></a>

```json
"boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0"

```

The identity of the Kubernetes job that is created to handle the Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|read-only|The identity of the Kubernetes job that is created to handle the Session.|

<h2 id="tocS_V1Operation">V1Operation</h2>
<!-- backwards compatibility -->
<a id="schemav1operation"></a>
<a id="schema_V1Operation"></a>
<a id="tocSv1operation"></a>
<a id="tocsv1operation"></a>

```json
"boot"

```

A Session represents an operation on a Session Template.
The creation of a Session effectively results in the creation
of a Kubernetes Boot Orchestration Agent (BOA) job to perform the
duties required to complete the operation.

Operation -- An operation to perform on nodes in this Session.

    Boot         Boot nodes that are off.

    Configure    Reconfigure the nodes using the Configuration Framework
                 Service (CFS).

    Reboot       Gracefully power down nodes that are on and then power
                 them back up.

    Shutdown     Gracefully power down nodes that are on.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|A Session represents an operation on a Session Template.<br>The creation of a Session effectively results in the creation<br>of a Kubernetes Boot Orchestration Agent (BOA) job to perform the<br>duties required to complete the operation.<br><br>Operation -- An operation to perform on nodes in this Session.<br><br>    Boot         Boot nodes that are off.<br><br>    Configure    Reconfigure the nodes using the Configuration Framework<br>                 Service (CFS).<br><br>    Reboot       Gracefully power down nodes that are on and then power<br>                 them back up.<br><br>    Shutdown     Gracefully power down nodes that are on.|

<h2 id="tocS_V1SessionLink">V1SessionLink</h2>
<!-- backwards compatibility -->
<a id="schemav1sessionlink"></a>
<a id="schema_V1SessionLink"></a>
<a id="tocSv1sessionlink"></a>
<a id="tocsv1sessionlink"></a>

```json
{
  "href": "string",
  "jobId": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "rel": "session",
  "type": "GET"
}

```

Link to other resources

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|href|string|false|none|none|
|jobId|[V1BoaKubernetesJob](#schemav1boakubernetesjob)|false|none|The identity of the Kubernetes job that is created to handle the Session.|
|rel|string|false|none|none|
|type|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|rel|session|
|rel|status|
|type|GET|

<h2 id="tocS_V1SessionStatusUri">V1SessionStatusUri</h2>
<!-- backwards compatibility -->
<a id="schemav1sessionstatusuri"></a>
<a id="schema_V1SessionStatusUri"></a>
<a id="tocSv1sessionstatusuri"></a>
<a id="tocsv1sessionstatusuri"></a>

```json
"/v1/session/90730844-094d-45a5-9b90-d661d14d9444/status"

```

URI to the status for this Session

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string(uri)|false|none|URI to the status for this Session|

<h2 id="tocS_V1SessionDetails">V1SessionDetails</h2>
<!-- backwards compatibility -->
<a id="schemav1sessiondetails"></a>
<a id="schema_V1SessionDetails"></a>
<a id="tocSv1sessiondetails"></a>
<a id="tocsv1sessiondetails"></a>

```json
{
  "complete": true,
  "error_count": 0,
  "in_progress": false,
  "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "operation": "boot",
  "start_time": "2020-04-24T12:00",
  "status_link": "/v1/session/90730844-094d-45a5-9b90-d661d14d9444/status",
  "stop_time": "2020-04-24T12:00",
  "templateName": "cle-1.0.0"
}

```

Details about a Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|complete|[V1CompleteMetadata](#schemav1completemetadata)|false|none|Is the object's status complete|
|error_count|[V1ErrorCountMetadata](#schemav1errorcountmetadata)|false|none|How many errors were encountered|
|in_progress|[V1InProgressMetadata](#schemav1inprogressmetadata)|false|none|Is the object still doing something|
|job|[V1BoaKubernetesJob](#schemav1boakubernetesjob)|false|none|The identity of the Kubernetes job that is created to handle the Session.|
|operation|[V1Operation](#schemav1operation)|false|none|A Session represents an operation on a Session Template.<br>The creation of a Session effectively results in the creation<br>of a Kubernetes Boot Orchestration Agent (BOA) job to perform the<br>duties required to complete the operation.<br><br>Operation -- An operation to perform on nodes in this Session.<br><br>    Boot         Boot nodes that are off.<br><br>    Configure    Reconfigure the nodes using the Configuration Framework<br>                 Service (CFS).<br><br>    Reboot       Gracefully power down nodes that are on and then power<br>                 them back up.<br><br>    Shutdown     Gracefully power down nodes that are on.|
|start_time|[V1StartTimeMetadata](#schemav1starttimemetadata)|false|none|The start time|
|status_link|[V1SessionStatusUri](#schemav1sessionstatusuri)|false|none|URI to the status for this Session|
|stop_time|[V1StopTimeMetadata](#schemav1stoptimemetadata)|false|none|The stop time. In some contexts, the value may be null before the operation finishes.|
|templateName|[SessionTemplateName](#schemasessiontemplatename)|false|none|Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* Maximum length of 127 characters.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V1SessionDetailsByTemplateUuid">V1SessionDetailsByTemplateUuid</h2>
<!-- backwards compatibility -->
<a id="schemav1sessiondetailsbytemplateuuid"></a>
<a id="schema_V1SessionDetailsByTemplateUuid"></a>
<a id="tocSv1sessiondetailsbytemplateuuid"></a>
<a id="tocsv1sessiondetailsbytemplateuuid"></a>

```json
{
  "complete": true,
  "error_count": 0,
  "in_progress": false,
  "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "operation": "boot",
  "start_time": "2020-04-24T12:00",
  "status_link": "/v1/session/90730844-094d-45a5-9b90-d661d14d9444/status",
  "stop_time": "2020-04-24T12:00",
  "templateName": "cle-1.0.0"
}

```

Details about a Session using templateUuid instead of templateName.
DEPRECATED -- these will only exist from Sessions created before templateUuid was deprecated.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|complete|[V1CompleteMetadata](#schemav1completemetadata)|false|none|Is the object's status complete|
|error_count|[V1ErrorCountMetadata](#schemav1errorcountmetadata)|false|none|How many errors were encountered|
|in_progress|[V1InProgressMetadata](#schemav1inprogressmetadata)|false|none|Is the object still doing something|
|job|[V1BoaKubernetesJob](#schemav1boakubernetesjob)|false|none|The identity of the Kubernetes job that is created to handle the Session.|
|operation|[V1Operation](#schemav1operation)|false|none|A Session represents an operation on a Session Template.<br>The creation of a Session effectively results in the creation<br>of a Kubernetes Boot Orchestration Agent (BOA) job to perform the<br>duties required to complete the operation.<br><br>Operation -- An operation to perform on nodes in this Session.<br><br>    Boot         Boot nodes that are off.<br><br>    Configure    Reconfigure the nodes using the Configuration Framework<br>                 Service (CFS).<br><br>    Reboot       Gracefully power down nodes that are on and then power<br>                 them back up.<br><br>    Shutdown     Gracefully power down nodes that are on.|
|start_time|[V1StartTimeMetadata](#schemav1starttimemetadata)|false|none|The start time|
|status_link|[V1SessionStatusUri](#schemav1sessionstatusuri)|false|none|URI to the status for this Session|
|stop_time|[V1StopTimeMetadata](#schemav1stoptimemetadata)|false|none|The stop time. In some contexts, the value may be null before the operation finishes.|
|templateName|[SessionTemplateName](#schemasessiontemplatename)|false|none|Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* Maximum length of 127 characters.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V1SessionLinkList">V1SessionLinkList</h2>
<!-- backwards compatibility -->
<a id="schemav1sessionlinklist"></a>
<a id="schema_V1SessionLinkList"></a>
<a id="tocSv1sessionlinklist"></a>
<a id="tocsv1sessionlinklist"></a>

```json
[
  {
    "href": "string",
    "jobId": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
    "rel": "session",
    "type": "GET"
  }
]

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V1SessionLink](#schemav1sessionlink)]|false|read-only|[Link to other resources]|

<h2 id="tocS_V1Session">V1Session</h2>
<!-- backwards compatibility -->
<a id="schemav1session"></a>
<a id="schema_V1Session"></a>
<a id="tocSv1session"></a>
<a id="tocsv1session"></a>

```json
{
  "operation": "boot",
  "templateName": "cle-1.0.0",
  "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "limit": "string",
  "links": [
    {
      "href": "string",
      "jobId": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
      "rel": "session",
      "type": "GET"
    }
  ]
}

```

A Session object

## Link Relationships

* self : The Session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|operation|[V1Operation](#schemav1operation)|true|none|A Session represents an operation on a Session Template.<br>The creation of a Session effectively results in the creation<br>of a Kubernetes Boot Orchestration Agent (BOA) job to perform the<br>duties required to complete the operation.<br><br>Operation -- An operation to perform on nodes in this Session.<br><br>    Boot         Boot nodes that are off.<br><br>    Configure    Reconfigure the nodes using the Configuration Framework<br>                 Service (CFS).<br><br>    Reboot       Gracefully power down nodes that are on and then power<br>                 them back up.<br><br>    Shutdown     Gracefully power down nodes that are on.|
|templateName|[SessionTemplateName](#schemasessiontemplatename)|true|none|Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* Maximum length of 127 characters.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|job|[V1BoaKubernetesJob](#schemav1boakubernetesjob)|false|none|The identity of the Kubernetes job that is created to handle the Session.|
|limit|[SessionLimit](#schemasessionlimit)|false|none|A comma-separated list of nodes, groups, or roles to which the Session<br>will be limited. Components are treated as OR operations unless<br>preceded by "&" for AND or "!" for NOT.<br><br>It is recommended that this should be 1-65535 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|links|[V1SessionLinkList](#schemav1sessionlinklist)|false|none|none|

<h2 id="tocS_V1SessionByTemplateName">V1SessionByTemplateName</h2>
<!-- backwards compatibility -->
<a id="schemav1sessionbytemplatename"></a>
<a id="schema_V1SessionByTemplateName"></a>
<a id="tocSv1sessionbytemplatename"></a>
<a id="tocsv1sessionbytemplatename"></a>

```json
{
  "operation": "boot",
  "templateUuid": "my-session-template",
  "templateName": "cle-1.0.0",
  "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "limit": "string",
  "links": [
    {
      "href": "string",
      "jobId": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
      "rel": "session",
      "type": "GET"
    }
  ]
}

```

A Session object specified by templateName

## Link Relationships

* self : The Session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|operation|[V1Operation](#schemav1operation)|true|none|A Session represents an operation on a Session Template.<br>The creation of a Session effectively results in the creation<br>of a Kubernetes Boot Orchestration Agent (BOA) job to perform the<br>duties required to complete the operation.<br><br>Operation -- An operation to perform on nodes in this Session.<br><br>    Boot         Boot nodes that are off.<br><br>    Configure    Reconfigure the nodes using the Configuration Framework<br>                 Service (CFS).<br><br>    Reboot       Gracefully power down nodes that are on and then power<br>                 them back up.<br><br>    Shutdown     Gracefully power down nodes that are on.|
|templateUuid|[V1SessionTemplateUuid](#schemav1sessiontemplateuuid)|false|none|DEPRECATED - use templateName. This field is ignored if templateName is also set.<br><br>Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* 1-127 characters in length.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|templateName|[SessionTemplateName](#schemasessiontemplatename)|true|none|Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* Maximum length of 127 characters.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|job|[V1BoaKubernetesJob](#schemav1boakubernetesjob)|false|none|The identity of the Kubernetes job that is created to handle the Session.|
|limit|[SessionLimit](#schemasessionlimit)|false|none|A comma-separated list of nodes, groups, or roles to which the Session<br>will be limited. Components are treated as OR operations unless<br>preceded by "&" for AND or "!" for NOT.<br><br>It is recommended that this should be 1-65535 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|links|[V1SessionLinkList](#schemav1sessionlinklist)|false|none|none|

<h2 id="tocS_V1SessionByTemplateUuid">V1SessionByTemplateUuid</h2>
<!-- backwards compatibility -->
<a id="schemav1sessionbytemplateuuid"></a>
<a id="schema_V1SessionByTemplateUuid"></a>
<a id="tocSv1sessionbytemplateuuid"></a>
<a id="tocsv1sessionbytemplateuuid"></a>

```json
{
  "operation": "boot",
  "templateUuid": "my-session-template",
  "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "limit": "string",
  "links": [
    {
      "href": "string",
      "jobId": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
      "rel": "session",
      "type": "GET"
    }
  ]
}

```

A Session object specified by templateUuid (DEPRECATED -- use templateName)

## Link Relationships

* self : The Session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|operation|[V1Operation](#schemav1operation)|true|none|A Session represents an operation on a Session Template.<br>The creation of a Session effectively results in the creation<br>of a Kubernetes Boot Orchestration Agent (BOA) job to perform the<br>duties required to complete the operation.<br><br>Operation -- An operation to perform on nodes in this Session.<br><br>    Boot         Boot nodes that are off.<br><br>    Configure    Reconfigure the nodes using the Configuration Framework<br>                 Service (CFS).<br><br>    Reboot       Gracefully power down nodes that are on and then power<br>                 them back up.<br><br>    Shutdown     Gracefully power down nodes that are on.|
|templateUuid|[V1SessionTemplateUuid](#schemav1sessiontemplateuuid)|true|none|DEPRECATED - use templateName. This field is ignored if templateName is also set.<br><br>Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* 1-127 characters in length.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|job|[V1BoaKubernetesJob](#schemav1boakubernetesjob)|false|none|The identity of the Kubernetes job that is created to handle the Session.|
|limit|[SessionLimit](#schemasessionlimit)|false|none|A comma-separated list of nodes, groups, or roles to which the Session<br>will be limited. Components are treated as OR operations unless<br>preceded by "&" for AND or "!" for NOT.<br><br>It is recommended that this should be 1-65535 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|links|[V1SessionLinkList](#schemav1sessionlinklist)|false|none|none|

<h2 id="tocS_V1PhaseName">V1PhaseName</h2>
<!-- backwards compatibility -->
<a id="schemav1phasename"></a>
<a id="schema_V1PhaseName"></a>
<a id="tocSv1phasename"></a>
<a id="tocsv1phasename"></a>

```json
"Boot"

```

The phase that this data belongs to (boot, shutdown, or configure). If blank,
it belongs to the Boot Set itself, which only applies to the GenericMetadata type.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The phase that this data belongs to (boot, shutdown, or configure). If blank,<br>it belongs to the Boot Set itself, which only applies to the GenericMetadata type.|

<h2 id="tocS_V1NodeChangeList">V1NodeChangeList</h2>
<!-- backwards compatibility -->
<a id="schemav1nodechangelist"></a>
<a id="schema_V1NodeChangeList"></a>
<a id="tocSv1nodechangelist"></a>
<a id="tocsv1nodechangelist"></a>

```json
{
  "phase": "Boot",
  "source": "Succeeded",
  "destination": "Succeeded",
  "node_list": [
    "x3000c0s19b1n0",
    "x3000c0s19b2n0"
  ]
}

```

The information used to update the status of a node list. It moves nodes from
one category to another within a phase.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|phase|[V1PhaseName](#schemav1phasename)|true|none|The phase that this data belongs to (boot, shutdown, or configure). If blank,<br>it belongs to the Boot Set itself, which only applies to the GenericMetadata type.|
|source|[V1PhaseCategoryName](#schemav1phasecategoryname)|true|none|Name of the Phase Category<br>not_started, in_progress, succeeded, failed, or excluded|
|destination|[V1PhaseCategoryName](#schemav1phasecategoryname)|true|none|Name of the Phase Category<br>not_started, in_progress, succeeded, failed, or excluded|
|node_list|[NodeListEmptyOk](#schemanodelistemptyok)|true|none|A node list that is allowed to be empty.<br><br>It is recommended that this list should be no more than 65535 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V1NodeErrorsList">V1NodeErrorsList</h2>
<!-- backwards compatibility -->
<a id="schemav1nodeerrorslist"></a>
<a id="schema_V1NodeErrorsList"></a>
<a id="tocSv1nodeerrorslist"></a>
<a id="tocsv1nodeerrorslist"></a>

```json
{
  "property1": [
    "x3000c0s19b1n0",
    "x3000c0s19b2n0"
  ],
  "property2": [
    "x3000c0s19b1n0",
    "x3000c0s19b2n0"
  ]
}

```

Categorizing nodes into failures by the type of error they have.
This is an additive characterization. Nodes will be added to existing errors.
This does not overwrite previously existing errors.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|**additionalProperties**|[NodeListEmptyOk](#schemanodelistemptyok)|false|none|A node list that is allowed to be empty.<br><br>It is recommended that this list should be no more than 65535 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V1UpdateRequestNodeChange">V1UpdateRequestNodeChange</h2>
<!-- backwards compatibility -->
<a id="schemav1updaterequestnodechange"></a>
<a id="schema_V1UpdateRequestNodeChange"></a>
<a id="tocSv1updaterequestnodechange"></a>
<a id="tocsv1updaterequestnodechange"></a>

```json
{
  "update_type": "NodeChangeList",
  "phase": "Boot",
  "data": {
    "phase": "Boot",
    "source": "Succeeded",
    "destination": "Succeeded",
    "node_list": [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ]
  }
}

```

This is an element of the payload sent during an update request. It contains
updates to which categories nodes are in.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|update_type|string|true|none|The type of update data|
|phase|[V1PhaseName](#schemav1phasename)|true|none|The phase that this data belongs to (boot, shutdown, or configure). If blank,<br>it belongs to the Boot Set itself, which only applies to the GenericMetadata type.|
|data|[V1NodeChangeList](#schemav1nodechangelist)|true|none|The information used to update the status of a node list. It moves nodes from<br>one category to another within a phase.|

#### Enumerated Values

|Property|Value|
|---|---|
|update_type|NodeChangeList|

<h2 id="tocS_V1UpdateRequestNodeErrors">V1UpdateRequestNodeErrors</h2>
<!-- backwards compatibility -->
<a id="schemav1updaterequestnodeerrors"></a>
<a id="schema_V1UpdateRequestNodeErrors"></a>
<a id="tocSv1updaterequestnodeerrors"></a>
<a id="tocsv1updaterequestnodeerrors"></a>

```json
{
  "update_type": "NodeErrorsList",
  "phase": "Boot",
  "data": {
    "property1": [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ],
    "property2": [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ]
  }
}

```

This is an element of the payload sent during an update request. It contains
updates to which errors have occurred and which nodes encountered those errors

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|update_type|string|true|none|The type of update data|
|phase|[V1PhaseName](#schemav1phasename)|true|none|The phase that this data belongs to (boot, shutdown, or configure). If blank,<br>it belongs to the Boot Set itself, which only applies to the GenericMetadata type.|
|data|[V1NodeErrorsList](#schemav1nodeerrorslist)|true|none|Categorizing nodes into failures by the type of error they have.<br>This is an additive characterization. Nodes will be added to existing errors.<br>This does not overwrite previously existing errors.|

#### Enumerated Values

|Property|Value|
|---|---|
|update_type|NodeErrorsList|

<h2 id="tocS_V1UpdateRequestGenericMetadata">V1UpdateRequestGenericMetadata</h2>
<!-- backwards compatibility -->
<a id="schemav1updaterequestgenericmetadata"></a>
<a id="schema_V1UpdateRequestGenericMetadata"></a>
<a id="tocSv1updaterequestgenericmetadata"></a>
<a id="tocsv1updaterequestgenericmetadata"></a>

```json
{
  "update_type": "GenericMetadata",
  "phase": "Boot",
  "data": {
    "complete": true,
    "error_count": 0,
    "in_progress": false,
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00"
  }
}

```

This is an element of the payload sent during an update request. It contains
updates to metadata, specifically start and stop times

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|update_type|string|true|none|The type of update data|
|phase|[V1PhaseName](#schemav1phasename)|true|none|The phase that this data belongs to (boot, shutdown, or configure). If blank,<br>it belongs to the Boot Set itself, which only applies to the GenericMetadata type.|
|data|[V1GenericMetadata](#schemav1genericmetadata)|true|none|The status metadata|

#### Enumerated Values

|Property|Value|
|---|---|
|update_type|GenericMetadata|

<h2 id="tocS_V1UpdateRequestList">V1UpdateRequestList</h2>
<!-- backwards compatibility -->
<a id="schemav1updaterequestlist"></a>
<a id="schema_V1UpdateRequestList"></a>
<a id="tocSv1updaterequestlist"></a>
<a id="tocsv1updaterequestlist"></a>

```json
[
  {
    "update_type": "NodeChangeList",
    "phase": "Boot",
    "data": {
      "phase": "Boot",
      "source": "Succeeded",
      "destination": "Succeeded",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ]
    }
  }
]

```

This is the payload sent during an update request. It contains a list of updates.

### Properties

oneOf

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[V1UpdateRequestNodeChange](#schemav1updaterequestnodechange)|false|none|This is an element of the payload sent during an update request. It contains<br>updates to which categories nodes are in.|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[V1UpdateRequestNodeErrors](#schemav1updaterequestnodeerrors)|false|none|This is an element of the payload sent during an update request. It contains<br>updates to which errors have occurred and which nodes encountered those errors|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[V1UpdateRequestGenericMetadata](#schemav1updaterequestgenericmetadata)|false|none|This is an element of the payload sent during an update request. It contains<br>updates to metadata, specifically start and stop times|

<h2 id="tocS_V2TenantName">V2TenantName</h2>
<!-- backwards compatibility -->
<a id="schemav2tenantname"></a>
<a id="schema_V2TenantName"></a>
<a id="tocSv2tenantname"></a>
<a id="tocsv2tenantname"></a>

```json
"string"

```

Name of the tenant that owns this resource. Only used in environments
with multi-tenancy enabled.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|read-only|Name of the tenant that owns this resource. Only used in environments<br>with multi-tenancy enabled.|

<h2 id="tocS_V2CfsParameters">V2CfsParameters</h2>
<!-- backwards compatibility -->
<a id="schemav2cfsparameters"></a>
<a id="schema_V2CfsParameters"></a>
<a id="tocSv2cfsparameters"></a>
<a id="tocsv2cfsparameters"></a>

```json
{
  "configuration": "compute-23.4.0"
}

```

This is the collection of parameters that are passed to the Configuration
Framework Service when configuration is enabled. Can be set as the global value for
a Session Template, or individually within a Boot Set.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|configuration|[CfsConfiguration](#schemacfsconfiguration)|false|none|The name of configuration to be applied.<br><br>It is recommended that this should be no more than 127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V2SessionTemplate">V2SessionTemplate</h2>
<!-- backwards compatibility -->
<a id="schemav2sessiontemplate"></a>
<a id="schema_V2SessionTemplate"></a>
<a id="tocSv2sessiontemplate"></a>
<a id="tocsv2sessiontemplate"></a>

```json
{
  "name": "cle-1.0.0",
  "tenant": "string",
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "compute-23.4.0"
  },
  "boot_sets": {
    "property1": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    },
    "property2": {
      "name": "compute",
      "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
      "cfs": {
        "configuration": "compute-23.4.0"
      },
      "type": "s3",
      "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_list": [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ],
      "node_roles_groups": [
        "Compute",
        "Application"
      ],
      "node_groups": [
        "string"
      ],
      "arch": "X86",
      "rootfs_provider": "cpss3",
      "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
    }
  },
  "links": [
    {
      "href": "string",
      "rel": "string"
    }
  ]
}

```

A Session Template object represents a collection of resources and metadata.
A Session Template is used to create a Session which applies the data to
group of Components.

## Link Relationships

* self : The Session Template object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|read-only|Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* Maximum length of 127 characters.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|tenant|[V2TenantName](#schemav2tenantname)|false|none|Name of the tenant that owns this resource. Only used in environments<br>with multi-tenancy enabled.|
|description|[SessionTemplateDescription](#schemasessiontemplatedescription)|false|none|An optional description for the Session Template.<br><br>It is recommended that this should be 1-1023 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|enable_cfs|[EnableCfs](#schemaenablecfs)|false|none|Whether to enable the Configuration Framework Service (CFS).|
|cfs|[V2CfsParameters](#schemav2cfsparameters)|false|none|This is the collection of parameters that are passed to the Configuration<br>Framework Service when configuration is enabled. Can be set as the global value for<br>a Session Template, or individually within a Boot Set.|
|boot_sets|object|false|none|Mapping from Boot Set names to Boot Sets.<br><br>It is recommended that:<br>* At least one Boot Set should be defined, because a Session Template with no<br>  Boot Sets is not functional.<br>* Boot Set names should be 1-127 characters in length.<br>* Boot Set names should use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Boot Set names should begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|» **additionalProperties**|[V2BootSet](#schemav2bootset)|false|none|A Boot Set is a collection of nodes defined by an explicit list, their functional<br>role, and their logical groupings. This collection of nodes is associated with one<br>set of boot artifacts and optional additional records for configuration and root<br>filesystem provisioning.|
|links|[LinkListReadOnly](#schemalinklistreadonly)|false|none|List of links to other resources|

<h2 id="tocS_V2SessionTemplateValidation">V2SessionTemplateValidation</h2>
<!-- backwards compatibility -->
<a id="schemav2sessiontemplatevalidation"></a>
<a id="schema_V2SessionTemplateValidation"></a>
<a id="tocSv2sessiontemplatevalidation"></a>
<a id="tocsv2sessiontemplatevalidation"></a>

```json
"string"

```

Message describing errors or incompleteness in a Session Template.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Message describing errors or incompleteness in a Session Template.|

<h2 id="tocS_V2SessionName">V2SessionName</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionname"></a>
<a id="schema_V2SessionName"></a>
<a id="tocSv2sessionname"></a>
<a id="tocsv2sessionname"></a>

```json
"session-20190728032600"

```

Name of the Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Name of the Session.|

<h2 id="tocS_V2SessionOperation">V2SessionOperation</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionoperation"></a>
<a id="schema_V2SessionOperation"></a>
<a id="tocSv2sessionoperation"></a>
<a id="tocsv2sessionoperation"></a>

```json
"boot"

```

A Session represents a desired state that is being applied to a group
of Components.  Sessions run until all Components it manages have
either been disabled due to completion, or until all Components are
managed by other newer Sessions.

Operation -- An operation to perform on Components in this Session.
    Boot                 Applies the Template to the Components and boots/reboots if necessary.
    Reboot               Applies the Template to the Components; guarantees a reboot.
    Shutdown             Power down Components that are on.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|A Session represents a desired state that is being applied to a group<br>of Components.  Sessions run until all Components it manages have<br>either been disabled due to completion, or until all Components are<br>managed by other newer Sessions.<br><br>Operation -- An operation to perform on Components in this Session.<br>    Boot                 Applies the Template to the Components and boots/reboots if necessary.<br>    Reboot               Applies the Template to the Components; guarantees a reboot.<br>    Shutdown             Power down Components that are on.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|boot|
|*anonymous*|reboot|
|*anonymous*|shutdown|

<h2 id="tocS_V2SessionCreate">V2SessionCreate</h2>
<!-- backwards compatibility -->
<a id="schemav2sessioncreate"></a>
<a id="schema_V2SessionCreate"></a>
<a id="tocSv2sessioncreate"></a>
<a id="tocsv2sessioncreate"></a>

```json
{
  "name": "session-20190728032600",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "string",
  "stage": false,
  "include_disabled": false
}

```

A Session Creation object. A UUID name is generated if a name is not provided.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[V2SessionName](#schemav2sessionname)|false|none|Name of the Session.|
|operation|[V2SessionOperation](#schemav2sessionoperation)|true|none|A Session represents a desired state that is being applied to a group<br>of Components.  Sessions run until all Components it manages have<br>either been disabled due to completion, or until all Components are<br>managed by other newer Sessions.<br><br>Operation -- An operation to perform on Components in this Session.<br>    Boot                 Applies the Template to the Components and boots/reboots if necessary.<br>    Reboot               Applies the Template to the Components; guarantees a reboot.<br>    Shutdown             Power down Components that are on.|
|template_name|[SessionTemplateName](#schemasessiontemplatename)|true|none|Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* Maximum length of 127 characters.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|limit|[SessionLimit](#schemasessionlimit)|false|none|A comma-separated list of nodes, groups, or roles to which the Session<br>will be limited. Components are treated as OR operations unless<br>preceded by "&" for AND or "!" for NOT.<br><br>It is recommended that this should be 1-65535 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|stage|boolean|false|none|Set to stage a Session which will not immediately change the state of any Components.<br>The "applystaged" endpoint can be called at a later time to trigger the start of this Session.|
|include_disabled|boolean|false|none|Set to include nodes that have been disabled as indicated in the Hardware State Manager (HSM).|

<h2 id="tocS_V2SessionStatusLabel">V2SessionStatusLabel</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionstatuslabel"></a>
<a id="schema_V2SessionStatusLabel"></a>
<a id="tocSv2sessionstatuslabel"></a>
<a id="tocsv2sessionstatuslabel"></a>

```json
"pending"

```

The status of a Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The status of a Session.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|pending|
|*anonymous*|running|
|*anonymous*|complete|

<h2 id="tocS_V2SessionStartTime">V2SessionStartTime</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionstarttime"></a>
<a id="schema_V2SessionStartTime"></a>
<a id="tocSv2sessionstarttime"></a>
<a id="tocsv2sessionstarttime"></a>

```json
"string"

```

When the Session was created.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|When the Session was created.|

<h2 id="tocS_V2SessionEndTime">V2SessionEndTime</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionendtime"></a>
<a id="schema_V2SessionEndTime"></a>
<a id="tocSv2sessionendtime"></a>
<a id="tocsv2sessionendtime"></a>

```json
"string"

```

When the Session was completed. A null value means the Session has not ended.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string¦null|false|none|When the Session was completed. A null value means the Session has not ended.|

<h2 id="tocS_V2SessionStatus">V2SessionStatus</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionstatus"></a>
<a id="schema_V2SessionStatus"></a>
<a id="tocSv2sessionstatus"></a>
<a id="tocsv2sessionstatus"></a>

```json
{
  "start_time": "string",
  "end_time": "string",
  "status": "pending",
  "error": "string"
}

```

Information on the status of a Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|start_time|[V2SessionStartTime](#schemav2sessionstarttime)|false|none|When the Session was created.|
|end_time|[V2SessionEndTime](#schemav2sessionendtime)|false|none|When the Session was completed. A null value means the Session has not ended.|
|status|[V2SessionStatusLabel](#schemav2sessionstatuslabel)|false|none|The status of a Session.|
|error|string¦null|false|none|Error which prevented the Session from running.<br>A null value means the Session has not encountered an error.|

<h2 id="tocS_V2BootSet">V2BootSet</h2>
<!-- backwards compatibility -->
<a id="schemav2bootset"></a>
<a id="schema_V2BootSet"></a>
<a id="tocSv2bootset"></a>
<a id="tocsv2bootset"></a>

```json
{
  "name": "compute",
  "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
  "cfs": {
    "configuration": "compute-23.4.0"
  },
  "type": "s3",
  "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
  "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
  "node_list": [
    "x3000c0s19b1n0",
    "x3000c0s19b2n0"
  ],
  "node_roles_groups": [
    "Compute",
    "Application"
  ],
  "node_groups": [
    "string"
  ],
  "arch": "X86",
  "rootfs_provider": "cpss3",
  "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0"
}

```

A Boot Set is a collection of nodes defined by an explicit list, their functional
role, and their logical groupings. This collection of nodes is associated with one
set of boot artifacts and optional additional records for configuration and root
filesystem provisioning.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[BootSetName](#schemabootsetname)|false|none|The Boot Set name.<br><br>It is recommended that:<br>* Boot Set names should be 1-127 characters in length.<br>* Boot Set names should use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Boot Set names should begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|path|[BootManifestPath](#schemabootmanifestpath)|true|none|A path identifying the metadata describing the components of the boot image.<br>This could be a URI, URL, etc, depending on the type of the Boot Set.<br><br>It is recommended that this should be 1-4095 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|cfs|[V2CfsParameters](#schemav2cfsparameters)|false|none|This is the collection of parameters that are passed to the Configuration<br>Framework Service when configuration is enabled. Can be set as the global value for<br>a Session Template, or individually within a Boot Set.|
|type|[BootSetType](#schemabootsettype)|true|none|The MIME type of the metadata describing the components of the boot image. This type controls how BOS processes the path attribute.<br><br>It is recommended that this should be 1-127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|etag|[BootSetEtag](#schemabootsetetag)|false|none|This is the 'entity tag'. It helps verify the version of metadata describing the components of the boot image we are working with.<br><br>ETags are defined as being 1-65536 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|kernel_parameters|[BootKernelParameters](#schemabootkernelparameters)|false|none|The kernel parameters to use to boot the nodes.<br><br>Linux kernel parameters may never exceed 4096 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|node_list|[NodeList](#schemanodelist)|false|none|A node list that is required to have at least one node.<br><br>It is recommended that this list should be 1-65535 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|node_roles_groups|[NodeRoleList](#schemanoderolelist)|false|none|Node role list. Allows actions against nodes with associated roles.<br><br>It is recommended that this list should be 1-1023 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|node_groups|[NodeGroupList](#schemanodegrouplist)|false|none|Node group list. Allows actions against associated nodes by logical groupings.<br><br>It is recommended that this list should be 1-4095 items in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|arch|string|false|none|The node architecture to target. Filters nodes that are not part of matching architecture from being targeted by boot actions. This value should correspond to HSM component 'Arch' field exactly. For reasons of backwards compatibility, all HSM nodes that are of type Unknown are treated as being of type X86.|
|rootfs_provider|[BootSetRootfsProvider](#schemabootsetrootfsprovider)|false|none|The root file system provider.<br><br>It is recommended that this should be 1-511 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|rootfs_provider_passthrough|[BootSetRootfsProviderPassthrough](#schemabootsetrootfsproviderpassthrough)|false|none|The root file system provider passthrough.<br>These are additional kernel parameters that will be appended to<br>the 'rootfs=<protocol>' kernel parameter<br><br>Linux kernel parameters may never exceed 4096 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

#### Enumerated Values

|Property|Value|
|---|---|
|arch|X86|
|arch|ARM|
|arch|Other|
|arch|Unknown|

<h2 id="tocS_V2Session">V2Session</h2>
<!-- backwards compatibility -->
<a id="schemav2session"></a>
<a id="schema_V2Session"></a>
<a id="tocSv2session"></a>
<a id="tocsv2session"></a>

```json
{
  "name": "session-20190728032600",
  "tenant": "string",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "string",
  "stage": true,
  "components": "string",
  "include_disabled": true,
  "status": {
    "start_time": "string",
    "end_time": "string",
    "status": "pending",
    "error": "string"
  }
}

```

A Session object

## Link Relationships

* self : The Session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[V2SessionName](#schemav2sessionname)|false|none|Name of the Session.|
|tenant|[V2TenantName](#schemav2tenantname)|false|none|Name of the tenant that owns this resource. Only used in environments<br>with multi-tenancy enabled.|
|operation|[V2SessionOperation](#schemav2sessionoperation)|false|none|A Session represents a desired state that is being applied to a group<br>of Components.  Sessions run until all Components it manages have<br>either been disabled due to completion, or until all Components are<br>managed by other newer Sessions.<br><br>Operation -- An operation to perform on Components in this Session.<br>    Boot                 Applies the Template to the Components and boots/reboots if necessary.<br>    Reboot               Applies the Template to the Components; guarantees a reboot.<br>    Shutdown             Power down Components that are on.|
|template_name|[SessionTemplateName](#schemasessiontemplatename)|false|none|Name of the Session Template.<br><br>It is recommended to use names which meet the following restrictions:<br>* Maximum length of 127 characters.<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.<br><br>These restrictions are not enforced in this version of BOS, but they are<br>targeted to start being enforced in an upcoming BOS version.|
|limit|[SessionLimit](#schemasessionlimit)|false|none|A comma-separated list of nodes, groups, or roles to which the Session<br>will be limited. Components are treated as OR operations unless<br>preceded by "&" for AND or "!" for NOT.<br><br>It is recommended that this should be 1-65535 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|stage|boolean|false|none|Set to stage a Session which will not immediately change the state of any Components.<br>The "applystaged" endpoint can be called at a later time to trigger the start of this Session.|
|components|string|false|none|A comma-separated list of nodes, representing the initial list of nodes<br>the Session should operate against.  The list will remain even if<br>other Sessions have taken over management of the nodes.|
|include_disabled|boolean|false|none|Set to include nodes that have been disabled as indicated in the Hardware State Manager (HSM).|
|status|[V2SessionStatus](#schemav2sessionstatus)|false|none|Information on the status of a Session.|

<h2 id="tocS_V2SessionArray">V2SessionArray</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionarray"></a>
<a id="schema_V2SessionArray"></a>
<a id="tocSv2sessionarray"></a>
<a id="tocsv2sessionarray"></a>

```json
[
  {
    "name": "session-20190728032600",
    "tenant": "string",
    "operation": "boot",
    "template_name": "cle-1.0.0",
    "limit": "string",
    "stage": true,
    "components": "string",
    "include_disabled": true,
    "status": {
      "start_time": "string",
      "end_time": "string",
      "status": "pending",
      "error": "string"
    }
  }
]

```

An array of Sessions.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2Session](#schemav2session)]|false|none|An array of Sessions.|

<h2 id="tocS_V2SessionExtendedStatusPhases">V2SessionExtendedStatusPhases</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionextendedstatusphases"></a>
<a id="schema_V2SessionExtendedStatusPhases"></a>
<a id="tocSv2sessionextendedstatusphases"></a>
<a id="tocsv2sessionextendedstatusphases"></a>

```json
{
  "percent_complete": 0,
  "percent_powering_on": 0,
  "percent_powering_off": 0,
  "percent_configuring": 0
}

```

Detailed information on the phases of a Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|percent_complete|number|false|none|The percent of Components currently in a completed/stable state|
|percent_powering_on|number|false|none|The percent of Components currently in the powering-on phase|
|percent_powering_off|number|false|none|The percent of Components currently in the powering-off phase|
|percent_configuring|number|false|none|The percent of Components currently in the configuring phase|

<h2 id="tocS_V2SessionExtendedStatusTiming">V2SessionExtendedStatusTiming</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionextendedstatustiming"></a>
<a id="schema_V2SessionExtendedStatusTiming"></a>
<a id="tocSv2sessionextendedstatustiming"></a>
<a id="tocsv2sessionextendedstatustiming"></a>

```json
{
  "start_time": "string",
  "end_time": "string",
  "duration": "string"
}

```

Detailed information on the timing of a Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|start_time|[V2SessionStartTime](#schemav2sessionstarttime)|false|none|When the Session was created.|
|end_time|[V2SessionEndTime](#schemav2sessionendtime)|false|none|When the Session was completed. A null value means the Session has not ended.|
|duration|string|false|none|The current duration of the ongoing Session or final duration of the completed Session.|

<h2 id="tocS_V2SessionExtendedStatus">V2SessionExtendedStatus</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionextendedstatus"></a>
<a id="schema_V2SessionExtendedStatus"></a>
<a id="tocSv2sessionextendedstatus"></a>
<a id="tocsv2sessionextendedstatus"></a>

```json
{
  "status": "pending",
  "managed_components_count": 0,
  "phases": {
    "percent_complete": 0,
    "percent_powering_on": 0,
    "percent_powering_off": 0,
    "percent_configuring": 0
  },
  "percent_successful": 0,
  "percent_failed": 0,
  "percent_staged": 0,
  "error_summary": {},
  "timing": {
    "start_time": "string",
    "end_time": "string",
    "duration": "string"
  }
}

```

Detailed information on the status of a Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|status|[V2SessionStatusLabel](#schemav2sessionstatuslabel)|false|none|The status of a Session.|
|managed_components_count|integer|false|none|The count of Components currently managed by this Session|
|phases|[V2SessionExtendedStatusPhases](#schemav2sessionextendedstatusphases)|false|none|Detailed information on the phases of a Session.|
|percent_successful|number|false|none|The percent of Components currently in a successful state|
|percent_failed|number|false|none|The percent of Components currently in a failed state|
|percent_staged|number|false|none|The percent of Components currently still staged for this Session|
|error_summary|object|false|none|A summary of the errors currently listed by all Components|
|timing|[V2SessionExtendedStatusTiming](#schemav2sessionextendedstatustiming)|false|none|Detailed information on the timing of a Session.|

<h2 id="tocS_V2BootArtifacts">V2BootArtifacts</h2>
<!-- backwards compatibility -->
<a id="schemav2bootartifacts"></a>
<a id="schema_V2BootArtifacts"></a>
<a id="tocSv2bootartifacts"></a>
<a id="tocsv2bootartifacts"></a>

```json
{
  "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
  "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
  "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
}

```

A collection of boot artifacts.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|kernel|[BootKernelPath](#schemabootkernelpath)|false|none|A path to the kernel to use for booting.<br><br>It is recommended that this should be no more than 4095 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|kernel_parameters|[BootKernelParameters](#schemabootkernelparameters)|false|none|The kernel parameters to use to boot the nodes.<br><br>Linux kernel parameters may never exceed 4096 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|initrd|[BootInitrdPath](#schemabootinitrdpath)|false|none|A path to the initrd to use for booting.<br><br>It is recommended that this should be no more than 4095 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V2ComponentBssToken">V2ComponentBssToken</h2>
<!-- backwards compatibility -->
<a id="schemav2componentbsstoken"></a>
<a id="schema_V2ComponentBssToken"></a>
<a id="tocSv2componentbsstoken"></a>
<a id="tocsv2componentbsstoken"></a>

```json
"string"

```

A token received from the node identifying the boot artifacts.
For BOS use-only, users should not set this field. It will be overwritten.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|A token received from the node identifying the boot artifacts.<br>For BOS use-only, users should not set this field. It will be overwritten.|

<h2 id="tocS_V2ComponentId">V2ComponentId</h2>
<!-- backwards compatibility -->
<a id="schemav2componentid"></a>
<a id="schema_V2ComponentId"></a>
<a id="tocSv2componentid"></a>
<a id="tocsv2componentid"></a>

```json
"string"

```

The Component's ID. (e.g. xname for hardware Components)

It is recommended that this should be 1-127 characters in length.

This restriction is not enforced in this version of BOS, but it is
targeted to start being enforced in an upcoming BOS version.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The Component's ID. (e.g. xname for hardware Components)<br><br>It is recommended that this should be 1-127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|

<h2 id="tocS_V2ComponentIdList">V2ComponentIdList</h2>
<!-- backwards compatibility -->
<a id="schemav2componentidlist"></a>
<a id="schema_V2ComponentIdList"></a>
<a id="tocSv2componentidlist"></a>
<a id="tocsv2componentidlist"></a>

```json
[
  "string"
]

```

A list of Component IDs (xnames)

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2ComponentId](#schemav2componentid)]|false|none|A list of Component IDs (xnames)|

<h2 id="tocS_V2ComponentLastUpdated">V2ComponentLastUpdated</h2>
<!-- backwards compatibility -->
<a id="schemav2componentlastupdated"></a>
<a id="schema_V2ComponentLastUpdated"></a>
<a id="tocSv2componentlastupdated"></a>
<a id="tocsv2componentlastupdated"></a>

```json
"2019-07-28T03:26:00Z"

```

The date/time when the state was last updated in RFC 3339 format.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string(date-time)|false|read-only|The date/time when the state was last updated in RFC 3339 format.|

<h2 id="tocS_V2ComponentActualState">V2ComponentActualState</h2>
<!-- backwards compatibility -->
<a id="schemav2componentactualstate"></a>
<a id="schema_V2ComponentActualState"></a>
<a id="tocSv2componentactualstate"></a>
<a id="tocsv2componentactualstate"></a>

```json
{
  "boot_artifacts": {
    "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
    "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
    "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
  },
  "bss_token": "string",
  "last_updated": "2019-07-28T03:26:00Z"
}

```

The desired boot artifacts and configuration for a Component

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|boot_artifacts|[V2BootArtifacts](#schemav2bootartifacts)|false|none|A collection of boot artifacts.|
|bss_token|[V2ComponentBssToken](#schemav2componentbsstoken)|false|none|A token received from the node identifying the boot artifacts.<br>For BOS use-only, users should not set this field. It will be overwritten.|
|last_updated|[V2ComponentLastUpdated](#schemav2componentlastupdated)|false|none|The date/time when the state was last updated in RFC 3339 format.|

<h2 id="tocS_V2ComponentDesiredState">V2ComponentDesiredState</h2>
<!-- backwards compatibility -->
<a id="schemav2componentdesiredstate"></a>
<a id="schema_V2ComponentDesiredState"></a>
<a id="tocSv2componentdesiredstate"></a>
<a id="tocsv2componentdesiredstate"></a>

```json
{
  "boot_artifacts": {
    "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
    "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
    "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
  },
  "configuration": "compute-23.4.0",
  "bss_token": "string",
  "last_updated": "2019-07-28T03:26:00Z"
}

```

The desired boot artifacts and configuration for a Component

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|boot_artifacts|[V2BootArtifacts](#schemav2bootartifacts)|false|none|A collection of boot artifacts.|
|configuration|[CfsConfiguration](#schemacfsconfiguration)|false|none|The name of configuration to be applied.<br><br>It is recommended that this should be no more than 127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|bss_token|[V2ComponentBssToken](#schemav2componentbsstoken)|false|none|A token received from the node identifying the boot artifacts.<br>For BOS use-only, users should not set this field. It will be overwritten.|
|last_updated|[V2ComponentLastUpdated](#schemav2componentlastupdated)|false|none|The date/time when the state was last updated in RFC 3339 format.|

<h2 id="tocS_V2ComponentStagedState">V2ComponentStagedState</h2>
<!-- backwards compatibility -->
<a id="schemav2componentstagedstate"></a>
<a id="schema_V2ComponentStagedState"></a>
<a id="tocSv2componentstagedstate"></a>
<a id="tocsv2componentstagedstate"></a>

```json
{
  "boot_artifacts": {
    "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
    "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
    "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
  },
  "configuration": "compute-23.4.0",
  "session": "session-20190728032600",
  "last_updated": "2019-07-28T03:26:00Z"
}

```

The desired boot artifacts and configuration for a Component. Optionally, a Session
may be set which can be triggered at a later time against this Component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|boot_artifacts|[V2BootArtifacts](#schemav2bootartifacts)|false|none|A collection of boot artifacts.|
|configuration|[CfsConfiguration](#schemacfsconfiguration)|false|none|The name of configuration to be applied.<br><br>It is recommended that this should be no more than 127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|session|[V2SessionName](#schemav2sessionname)|false|none|Name of the Session.|
|last_updated|[V2ComponentLastUpdated](#schemav2componentlastupdated)|false|none|The date/time when the state was last updated in RFC 3339 format.|

<h2 id="tocS_V2ComponentLastAction">V2ComponentLastAction</h2>
<!-- backwards compatibility -->
<a id="schemav2componentlastaction"></a>
<a id="schema_V2ComponentLastAction"></a>
<a id="tocSv2componentlastaction"></a>
<a id="tocsv2componentlastaction"></a>

```json
{
  "last_updated": "2019-07-28T03:26:00Z",
  "action": "string",
  "failed": true
}

```

Information on the most recent action taken against the node.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|last_updated|[V2ComponentLastUpdated](#schemav2componentlastupdated)|false|none|The date/time when the state was last updated in RFC 3339 format.|
|action|string|false|none|A description of the most recent operator/action to impact the Component.|
|failed|boolean|false|none|Denotes if the last action failed to accomplish its task|

<h2 id="tocS_V2ComponentEventStats">V2ComponentEventStats</h2>
<!-- backwards compatibility -->
<a id="schemav2componenteventstats"></a>
<a id="schema_V2ComponentEventStats"></a>
<a id="tocSv2componenteventstats"></a>
<a id="tocsv2componenteventstats"></a>

```json
{
  "power_on_attempts": 0,
  "power_off_graceful_attempts": 0,
  "power_off_forceful_attempts": 0
}

```

Information on the most recent attempt to return the node to its desired state.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|power_on_attempts|integer|false|none|How many attempts have been made to power-on since the last time the node was in the desired state.|
|power_off_graceful_attempts|integer|false|none|How many attempts have been made to power-off gracefully since the last time the node was in the desired state.|
|power_off_forceful_attempts|integer|false|none|How many attempts have been made to power-off forcefully since the last time the node was in the desired state.|

<h2 id="tocS_V2ComponentStatus">V2ComponentStatus</h2>
<!-- backwards compatibility -->
<a id="schemav2componentstatus"></a>
<a id="schema_V2ComponentStatus"></a>
<a id="tocSv2componentstatus"></a>
<a id="tocsv2componentstatus"></a>

```json
{
  "phase": "string",
  "status": "string",
  "status_override": "string"
}

```

Status information for the Component

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|phase|string|false|none|The current phase of the Component in the boot process.|
|status|string|false|read-only|The current status of the Component.  More detailed than phase.|
|status_override|string|false|none|If set, this will override the status value.|

<h2 id="tocS_V2Component">V2Component</h2>
<!-- backwards compatibility -->
<a id="schemav2component"></a>
<a id="schema_V2Component"></a>
<a id="tocSv2component"></a>
<a id="tocsv2component"></a>

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
      "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
    },
    "configuration": "compute-23.4.0",
    "session": "session-20190728032600",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "last_action": {
    "last_updated": "2019-07-28T03:26:00Z",
    "action": "string",
    "failed": true
  },
  "event_stats": {
    "power_on_attempts": 0,
    "power_off_graceful_attempts": 0,
    "power_off_forceful_attempts": 0
  },
  "status": {
    "phase": "string",
    "status": "string",
    "status_override": "string"
  },
  "enabled": true,
  "error": "string",
  "session": "session-20190728032600",
  "retry_policy": 1
}

```

The current and desired artifacts state for a Component, and
the Session responsible for the Component's current state.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|[V2ComponentId](#schemav2componentid)|false|none|The Component's ID. (e.g. xname for hardware Components)<br><br>It is recommended that this should be 1-127 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|actual_state|[V2ComponentActualState](#schemav2componentactualstate)|false|none|The desired boot artifacts and configuration for a Component|
|desired_state|[V2ComponentDesiredState](#schemav2componentdesiredstate)|false|none|The desired boot artifacts and configuration for a Component|
|staged_state|[V2ComponentStagedState](#schemav2componentstagedstate)|false|none|The desired boot artifacts and configuration for a Component. Optionally, a Session<br>may be set which can be triggered at a later time against this Component.|
|last_action|[V2ComponentLastAction](#schemav2componentlastaction)|false|none|Information on the most recent action taken against the node.|
|event_stats|[V2ComponentEventStats](#schemav2componenteventstats)|false|none|Information on the most recent attempt to return the node to its desired state.|
|status|[V2ComponentStatus](#schemav2componentstatus)|false|none|Status information for the Component|
|enabled|boolean|false|none|A flag indicating if actions should be taken for this Component.|
|error|string|false|none|A description of the most recent error to impact the Component.|
|session|[V2SessionName](#schemav2sessionname)|false|none|Name of the Session.|
|retry_policy|integer|false|none|The maximum number attempts per action when actions fail.<br>Defaults to the global default_retry_policy if not set|

<h2 id="tocS_V2ComponentArray">V2ComponentArray</h2>
<!-- backwards compatibility -->
<a id="schemav2componentarray"></a>
<a id="schema_V2ComponentArray"></a>
<a id="tocSv2componentarray"></a>
<a id="tocsv2componentarray"></a>

```json
[
  {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "session": "session-20190728032600",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "last_action": {
      "last_updated": "2019-07-28T03:26:00Z",
      "action": "string",
      "failed": true
    },
    "event_stats": {
      "power_on_attempts": 0,
      "power_off_graceful_attempts": 0,
      "power_off_forceful_attempts": 0
    },
    "status": {
      "phase": "string",
      "status": "string",
      "status_override": "string"
    },
    "enabled": true,
    "error": "string",
    "session": "session-20190728032600",
    "retry_policy": 1
  }
]

```

An array of Component states.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2Component](#schemav2component)]|false|none|An array of Component states.|

<h2 id="tocS_V2ComponentsFilter">V2ComponentsFilter</h2>
<!-- backwards compatibility -->
<a id="schemav2componentsfilter"></a>
<a id="schema_V2ComponentsFilter"></a>
<a id="tocSv2componentsfilter"></a>
<a id="tocsv2componentsfilter"></a>

```json
{
  "ids": "string",
  "session": "session-20190728032600"
}

```

Information for patching multiple Components.
If a Session name is specified, then all Components part of this Session will be patched.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ids|string|false|none|A comma-separated list of Component IDs.<br><br>It is recommended that this should be 1-65535 characters in length.<br><br>This restriction is not enforced in this version of BOS, but it is<br>targeted to start being enforced in an upcoming BOS version.|
|session|[V2SessionName](#schemav2sessionname)|false|none|Name of the Session.|

<h2 id="tocS_V2ComponentsUpdate">V2ComponentsUpdate</h2>
<!-- backwards compatibility -->
<a id="schemav2componentsupdate"></a>
<a id="schema_V2ComponentsUpdate"></a>
<a id="tocSv2componentsupdate"></a>
<a id="tocsv2componentsupdate"></a>

```json
{
  "patch": {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/kernel",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "initrd": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/initrd"
      },
      "configuration": "compute-23.4.0",
      "session": "session-20190728032600",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "last_action": {
      "last_updated": "2019-07-28T03:26:00Z",
      "action": "string",
      "failed": true
    },
    "event_stats": {
      "power_on_attempts": 0,
      "power_off_graceful_attempts": 0,
      "power_off_forceful_attempts": 0
    },
    "status": {
      "phase": "string",
      "status": "string",
      "status_override": "string"
    },
    "enabled": true,
    "error": "string",
    "session": "session-20190728032600",
    "retry_policy": 1
  },
  "filters": {
    "ids": "string",
    "session": "session-20190728032600"
  }
}

```

Information for patching multiple Components.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|patch|[V2Component](#schemav2component)|true|none|The current and desired artifacts state for a Component, and<br>the Session responsible for the Component's current state.|
|filters|[V2ComponentsFilter](#schemav2componentsfilter)|true|none|Information for patching multiple Components.<br>If a Session name is specified, then all Components part of this Session will be patched.|

<h2 id="tocS_V2ApplyStagedComponents">V2ApplyStagedComponents</h2>
<!-- backwards compatibility -->
<a id="schemav2applystagedcomponents"></a>
<a id="schema_V2ApplyStagedComponents"></a>
<a id="tocSv2applystagedcomponents"></a>
<a id="tocsv2applystagedcomponents"></a>

```json
{
  "xnames": [
    "string"
  ]
}

```

A list of Components that should have their staged Session applied.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xnames|[V2ComponentIdList](#schemav2componentidlist)|false|none|A list of Component IDs (xnames)|

<h2 id="tocS_V2ApplyStagedStatus">V2ApplyStagedStatus</h2>
<!-- backwards compatibility -->
<a id="schemav2applystagedstatus"></a>
<a id="schema_V2ApplyStagedStatus"></a>
<a id="tocSv2applystagedstatus"></a>
<a id="tocsv2applystagedstatus"></a>

```json
{
  "succeeded": [
    "string"
  ],
  "failed": [
    "string"
  ],
  "ignored": [
    "string"
  ]
}

```

Mapping from Component staged Session statuses to Components with that status.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|succeeded|[V2ComponentIdList](#schemav2componentidlist)|false|none|A list of Component IDs (xnames)|
|failed|[V2ComponentIdList](#schemav2componentidlist)|false|none|A list of Component IDs (xnames)|
|ignored|[V2ComponentIdList](#schemav2componentidlist)|false|none|A list of Component IDs (xnames)|

<h2 id="tocS_V2Options">V2Options</h2>
<!-- backwards compatibility -->
<a id="schemav2options"></a>
<a id="schema_V2Options"></a>
<a id="tocSv2options"></a>
<a id="tocsv2options"></a>

```json
{
  "cleanup_completed_session_ttl": "3d",
  "clear_stage": true,
  "component_actual_state_ttl": "6h",
  "disable_components_on_completion": true,
  "discovery_frequency": 33554432,
  "logging_level": "string",
  "max_boot_wait_time": 1048576,
  "max_power_on_wait_time": 1048576,
  "max_power_off_wait_time": 1048576,
  "polling_frequency": 1048576,
  "default_retry_policy": 1
}

```

Options for the Boot Orchestration Service.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|cleanup_completed_session_ttl|string(^(0|0[mMhHdDwW]|[1-9][0-9]*[mMhHdDwW])$)|false|none|Delete complete Sessions that are older than cleanup_completed_session_ttl (in minutes, hours, days, or weeks).<br>0 disables cleanup behavior.|
|clear_stage|boolean|false|none|Allows a Component's staged information to be cleared when the requested staging action has been started. Defaults to false.|
|component_actual_state_ttl|string(^(0|0[mMhHdDwW]|[1-9][0-9]*[mMhHdDwW])$)|false|none|The maximum amount of time a Component's actual state is considered valid (in minutes, hours, days, or weeks).<br>0 disables cleanup behavior for newly booted nodes and instructs bos-state-reporter to report once instead of periodically.|
|disable_components_on_completion|boolean|false|none|Allows for BOS Components to be marked as disabled after a Session has been completed. If false, BOS will continue to maintain the state<br>of the nodes declaratively, even after a Session finishes.|
|discovery_frequency|integer|false|none|How frequently the BOS discovery agent syncs new Components from HSM. (in seconds)|
|logging_level|string|false|none|The logging level for all BOS services|
|max_boot_wait_time|integer|false|none|How long BOS will wait for a node to boot into a usable state before rebooting it again (in seconds)|
|max_power_on_wait_time|integer|false|none|How long BOS will wait for a node to power on before calling power on again (in seconds)|
|max_power_off_wait_time|integer|false|none|How long BOS will wait for a node to power off before forcefully powering off (in seconds)|
|polling_frequency|integer|false|none|How frequently the BOS operators check Component state for needed actions. (in seconds)|
|default_retry_policy|integer|false|none|The default maximum number attempts per node for failed actions.|

<h2 id="tocS_SessionTemplateArray">SessionTemplateArray</h2>
<!-- backwards compatibility -->
<a id="schemasessiontemplatearray"></a>
<a id="schema_SessionTemplateArray"></a>
<a id="tocSsessiontemplatearray"></a>
<a id="tocssessiontemplatearray"></a>

```json
[
  {
    "name": "cle-1.0.0",
    "description": "string",
    "cfs_url": "string",
    "cfs_branch": "string",
    "enable_cfs": true,
    "cfs": {
      "clone_url": "string",
      "branch": "string",
      "commit": "string",
      "playbook": "string",
      "configuration": "compute-23.4.0"
    },
    "partition": "string",
    "boot_sets": {
      "property1": {
        "name": "compute",
        "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
        "type": "s3",
        "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "node_list": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "node_roles_groups": [
          "Compute",
          "Application"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "cpss3",
        "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
        "network": "string",
        "boot_ordinal": 0,
        "shutdown_ordinal": 0
      },
      "property2": {
        "name": "compute",
        "path": "s3://boot-images/9e3c75e1-ac42-42c7-873c-e758048897d6/manifest.json",
        "type": "s3",
        "etag": "1cc4eef4f407bd8a62d7d66ee4b9e9c8",
        "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}",
        "node_list": [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ],
        "node_roles_groups": [
          "Compute",
          "Application"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "cpss3",
        "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
        "network": "string",
        "boot_ordinal": 0,
        "shutdown_ordinal": 0
      }
    },
    "links": [
      {
        "href": "string",
        "rel": "string"
      }
    ]
  }
]

```

An array of Session Templates.

### Properties

anyOf

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[V1SessionTemplate](#schemav1sessiontemplate)|false|none|A Session Template object represents a collection of resources and metadata.<br>A Session Template is used to create a Session which when combined with an<br>action (i.e. boot, configure, reboot, shutdown) will create a Kubernetes BOA job<br>to complete the required tasks for the operation.<br><br>## Link Relationships<br><br>* self : The Session Template object|

or

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[V2SessionTemplate](#schemav2sessiontemplate)|false|none|A Session Template object represents a collection of resources and metadata.<br>A Session Template is used to create a Session which applies the data to<br>group of Components.<br><br>## Link Relationships<br><br>* self : The Session Template object|

