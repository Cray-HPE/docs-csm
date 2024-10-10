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

    GET /v2/sessiontemplates

  b. Create a new Session Template if desired.

    PUT /v2/sessiontemplate/{template_name}

    If no Session Template exists that satisfies requirements,
    then create a new Session Template.
    This Session Template can be used to create a new Session later.

2. Create the Session.

  POST /v2/sessions

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

  GET /v2/sessions/{session_id}

## Interactions with Other APIs

### Configuration Framework Service (CFS)

If *enable_cfs* is true in a Session Template, then BOS will invoke CFS to
configure the target nodes during *boot* or *reboot* operations.

### Hardware State Manager (HSM)

In some situations BOS checks HSM to determine if a node has been disabled.

### Image Management Service (IMS)

BOS works in concert with IMS to access boot images.
All boot images specified via the Session Template must be available via IMS.

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/bos">https://api-gw-service-nmn.local/apis/bos</a>

# Authentication

- HTTP Authentication, scheme: bearer 

<h1 id="boot-orchestration-service-version">version</h1>

## root_get

<a id="opIdroot_get"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/bos/ HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/ \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="root_get-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of Versions|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An Internal Server Error occurred handling the request.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="root_get-responseschema">Response Schema</h3>

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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An Internal Server Error occurred handling the request.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
[
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
]
```

<h3 id="get_v2_sessiontemplates-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template details array|[V2SessionTemplateArray](#schemav2sessiontemplatearray)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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

<h3 id="get_v2_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session Template details|[V2SessionTemplate](#schemav2sessiontemplate)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
  "limit": "",
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

> Example responses

> 201 Response

```json
{
  "name": "session-20190728032600",
  "tenant": "string",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "",
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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
    "limit": "",
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
|session_id|path|[V2SessionName](#schemav2sessionname)|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "name": "session-20190728032600",
  "tenant": "string",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "",
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

*Update status of a single Session*

Update the state for a given Session in the BOS database.
This is intended only for internal use by the BOS service.

> Body parameter

```json
{
  "components": "string",
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
|body|body|[V2SessionUpdate](#schemav2sessionupdate)|true|The state for a single Session|
|session_id|path|[V2SessionName](#schemav2sessionname)|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "name": "session-20190728032600",
  "tenant": "string",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "",
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
|session_id|path|[V2SessionName](#schemav2sessionname)|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
|session_id|path|[V2SessionName](#schemav2sessionname)|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
|session_id|path|[V2SessionName](#schemav2sessionname)|true|Session ID|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

> Example responses

> 200 Response

```json
{
  "name": "session-20190728032600",
  "tenant": "string",
  "operation": "boot",
  "template_name": "cle-1.0.0",
  "limit": "",
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
|session|query|[V2SessionName](#schemav2sessionname)|false|Retrieve the Components with the given Session ID.|
|staged_session|query|[V2SessionName](#schemav2sessionname)|false|Retrieve the Components with the given staged Session ID.|
|enabled|query|boolean|false|Retrieve the Components with the "enabled" state.|
|phase|query|[V2ComponentPhase](#schemav2componentphase)|false|Retrieve the Components in the given phase.|
|status|query|string|false|Retrieve the Components with the given status.|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**ids**: Retrieve the Components with the given ID
(e.g. xname for hardware Components). Can be chained
for selecting groups of Components.

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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
      "power_on_attempts": 1048576,
      "power_off_graceful_attempts": 1048576,
      "power_off_forceful_attempts": 1048576
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
      "power_on_attempts": 1048576,
      "power_off_graceful_attempts": 1048576,
      "power_off_forceful_attempts": 1048576
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
|body|body|[V2ComponentArrayWithIds](#schemav2componentarraywithids)|true|The state for an array of Components|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|

#### Detailed descriptions

**Cray-Tenant-Name**: Tenant name.

Requests with a non-empty tenant name will restict the context of the operation to Session Templates owned by that tenant.

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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
      "power_on_attempts": 1048576,
      "power_off_graceful_attempts": 1048576,
      "power_off_forceful_attempts": 1048576
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
      "power_on_attempts": 1048576,
      "power_off_graceful_attempts": 1048576,
      "power_off_forceful_attempts": 1048576
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
    "session": ""
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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
      "power_on_attempts": 1048576,
      "power_off_graceful_attempts": 1048576,
      "power_off_forceful_attempts": 1048576
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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
    "power_on_attempts": 1048576,
    "power_off_graceful_attempts": 1048576,
    "power_off_forceful_attempts": 1048576
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
    "power_on_attempts": 1048576,
    "power_off_graceful_attempts": 1048576,
    "power_off_forceful_attempts": 1048576
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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
    "power_on_attempts": 1048576,
    "power_off_graceful_attempts": 1048576,
    "power_off_forceful_attempts": 1048576
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
    "power_on_attempts": 1048576,
    "power_off_graceful_attempts": 1048576,
    "power_off_forceful_attempts": 1048576
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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
    "power_on_attempts": 1048576,
    "power_off_graceful_attempts": 1048576,
    "power_off_forceful_attempts": 1048576
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Cray-Tenant-Name: vcluster-my-tenant1' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cray-Tenant-Name': 'vcluster-my-tenant1',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

Requests with an empty tenant name, or that omit this parameter, will have no such context restrictions.

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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
        "Authorization": []string{"Bearer {access-token}"},
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
  "default_retry_policy": 1,
  "disable_components_on_completion": true,
  "discovery_frequency": 33554432,
  "ims_errors_fatal": true,
  "ims_images_must_exist": true,
  "logging_level": "string",
  "max_boot_wait_time": 1048576,
  "max_component_batch_size": 1000,
  "max_power_off_wait_time": 1048576,
  "max_power_on_wait_time": 1048576,
  "polling_frequency": 1048576,
  "reject_nids": true,
  "session_limit_required": true
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
  "default_retry_policy": 1,
  "disable_components_on_completion": true,
  "discovery_frequency": 33554432,
  "ims_errors_fatal": true,
  "ims_images_must_exist": true,
  "logging_level": "string",
  "max_boot_wait_time": 1048576,
  "max_component_batch_size": 1000,
  "max_power_off_wait_time": 1048576,
  "max_power_on_wait_time": 1048576,
  "polling_frequency": 1048576,
  "reject_nids": true,
  "session_limit_required": true
}
```

<h3 id="patch_v2_options-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of service-wide options|[V2Options](#schemav2options)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
  "default_retry_policy": 1,
  "disable_components_on_completion": true,
  "discovery_frequency": 33554432,
  "ims_errors_fatal": true,
  "ims_images_must_exist": true,
  "logging_level": "string",
  "max_boot_wait_time": 1048576,
  "max_component_batch_size": 1000,
  "max_power_off_wait_time": 1048576,
  "max_power_on_wait_time": 1048576,
  "polling_frequency": 1048576,
  "reject_nids": true,
  "session_limit_required": true
}
```

<h3 id="get_v2_options-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of service-wide options|[V2Options](#schemav2options)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
|*anonymous*|string|false|none|Age in minutes (e.g. "3m"), hours (e.g. "5h"), days (e.g. "10d"), or weeks (e.g. "2w").|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|A path to the initrd to use for booting.|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|A path to the kernel to use for booting.|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|A path identifying the metadata describing the components of the boot image.<br>This could be a URI, URL, etc, depending on the type of the Boot Set.|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The kernel parameters to use to boot the nodes.|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is the 'entity tag'. It helps verify the version of metadata describing the components of the boot image we are working with.|

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

* Boot Set names must use only letters, digits, periods (.), dashes (-), and underscores (_).
* Boot Set names must begin and end with a letter or digit.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|write-only|The Boot Set name.<br><br>* Boot Set names must use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Boot Set names must begin and end with a letter or digit.|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The root file system provider.|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The root file system provider passthrough.<br>These are additional kernel parameters that will be appended to<br>the 'rootfs=<protocol>' kernel parameter|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The MIME type of the metadata describing the components of the boot image. This type controls how BOS processes the path attribute.|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The name of configuration to be applied.|

<h2 id="tocS_EmptyString">EmptyString</h2>
<!-- backwards compatibility -->
<a id="schemaemptystring"></a>
<a id="schema_EmptyString"></a>
<a id="tocSemptystring"></a>
<a id="tocsemptystring"></a>

```json
""

```

An empty string value.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|An empty string value.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*||

<h2 id="tocS_EmptyStringNullable">EmptyStringNullable</h2>
<!-- backwards compatibility -->
<a id="schemaemptystringnullable"></a>
<a id="schema_EmptyStringNullable"></a>
<a id="tocSemptystringnullable"></a>
<a id="tocsemptystringnullable"></a>

```json
""

```

An empty string value.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string¦null|false|none|An empty string value.|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*||

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Hardware component name (xname).|

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
Nodes must be specified by component name (xname). NIDs are not supported.
If the reject_nids option is enabled, then Session Template creation or validation will fail if
any of the boot sets contain a NodeList that appears to contain a NID.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[HardwareComponentName](#schemahardwarecomponentname)]|false|none|A node list that is required to have at least one node.<br>Nodes must be specified by component name (xname). NIDs are not supported.<br>If the reject_nids option is enabled, then Session Template creation or validation will fail if<br>any of the boot sets contain a NodeList that appears to contain a NID.|

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
""

```

A comma-separated list of nodes, groups, or roles to which the Session
will be limited. Components are treated as OR operations unless
preceded by "&" for AND or "!" for NOT.

Alternatively, the limit can be set to "*", which means no limit.

An empty string or null value is the same as specifying no limit.

If the reject_nids option is enabled, then Session creation will fail if its
limit appears to contain a NID value.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string¦null|false|none|A comma-separated list of nodes, groups, or roles to which the Session<br>will be limited. Components are treated as OR operations unless<br>preceded by "&" for AND or "!" for NOT.<br><br>Alternatively, the limit can be set to "*", which means no limit.<br><br>An empty string or null value is the same as specifying no limit.<br><br>If the reject_nids option is enabled, then Session creation will fail if its<br>limit appears to contain a NID value.|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|An optional description for the Session Template.|

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

The name must:
* Use only letters, digits, periods (.), dashes (-), and underscores (_).
* Begin and end with a letter or digit.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Name of the Session Template.<br><br>The name must:<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Name of a tenant. Used for multi-tenancy. An empty string means no tenant.|

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
with multi-tenancy enabled. An empty string or null value means the resource
is not owned by a tenant. The absence of this field from a resource indicates
the same.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string¦null|false|read-only|Name of the tenant that owns this resource. Only used in environments<br>with multi-tenancy enabled. An empty string or null value means the resource<br>is not owned by a tenant. The absence of this field from a resource indicates<br>the same.|

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
|configuration|[CfsConfiguration](#schemacfsconfiguration)|false|none|The name of configuration to be applied.|

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
|name|string|false|read-only|Name of the Session Template.<br><br>Names must:<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.|
|tenant|[V2TenantName](#schemav2tenantname)|false|none|Name of the tenant that owns this resource. Only used in environments<br>with multi-tenancy enabled. An empty string or null value means the resource<br>is not owned by a tenant. The absence of this field from a resource indicates<br>the same.|
|description|[SessionTemplateDescription](#schemasessiontemplatedescription)|false|none|An optional description for the Session Template.|
|enable_cfs|[EnableCfs](#schemaenablecfs)|false|none|Whether to enable the Configuration Framework Service (CFS).|
|cfs|[V2CfsParameters](#schemav2cfsparameters)|false|none|This is the collection of parameters that are passed to the Configuration<br>Framework Service when configuration is enabled. Can be set as the global value for<br>a Session Template, or individually within a Boot Set.|
|boot_sets|object|true|none|Mapping from Boot Set names to Boot Sets.<br><br>* Boot Set names must be 1-127 characters in length.<br>* Boot Set names must use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Boot Set names must begin and end with a letter or digit.|
|» **additionalProperties**|[V2BootSet](#schemav2bootset)|false|none|A Boot Set is a collection of nodes defined by an explicit list, their functional<br>role, and their logical groupings. This collection of nodes is associated with one<br>set of boot artifacts and optional additional records for configuration and root<br>filesystem provisioning.<br><br>A boot set requires at least one of the following fields to be specified:<br>node_list, node_roles_groups, node_groups<br><br>If specified, the name field must match the key mapping to this boot set in the<br>boot_sets field of the containing V2SessionTemplate.|
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

The name must:
* Use only letters, digits, periods (.), dashes (-), and underscores (_).
* Begin and end with a letter or digit.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Name of the Session.<br><br>The name must:<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.|

<h2 id="tocS_V2SessionNameOrEmpty">V2SessionNameOrEmpty</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionnameorempty"></a>
<a id="schema_V2SessionNameOrEmpty"></a>
<a id="tocSv2sessionnameorempty"></a>
<a id="tocsv2sessionnameorempty"></a>

```json
"session-20190728032600"

```

### Properties

oneOf

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[V2SessionName](#schemav2sessionname)|false|none|Name of the Session.<br><br>The name must:<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[EmptyString](#schemaemptystring)|false|none|An empty string value.|

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
  "limit": "",
  "stage": false,
  "include_disabled": false
}

```

A Session Creation object. A UUID name is generated if a name is not provided. The limit parameter is
required if the session_limit_required option is true.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[V2SessionName](#schemav2sessionname)|false|none|Name of the Session.<br><br>The name must:<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.|
|operation|[V2SessionOperation](#schemav2sessionoperation)|true|none|A Session represents a desired state that is being applied to a group<br>of Components.  Sessions run until all Components it manages have<br>either been disabled due to completion, or until all Components are<br>managed by other newer Sessions.<br><br>Operation -- An operation to perform on Components in this Session.<br>    Boot                 Applies the Template to the Components and boots/reboots if necessary.<br>    Reboot               Applies the Template to the Components; guarantees a reboot.<br>    Shutdown             Power down Components that are on.|
|template_name|[SessionTemplateName](#schemasessiontemplatename)|true|none|Name of the Session Template.<br><br>The name must:<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.|
|limit|[SessionLimit](#schemasessionlimit)|false|none|A comma-separated list of nodes, groups, or roles to which the Session<br>will be limited. Components are treated as OR operations unless<br>preceded by "&" for AND or "!" for NOT.<br><br>Alternatively, the limit can be set to "*", which means no limit.<br><br>An empty string or null value is the same as specifying no limit.<br><br>If the reject_nids option is enabled, then Session creation will fail if its<br>limit appears to contain a NID value.|
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

A boot set requires at least one of the following fields to be specified:
node_list, node_roles_groups, node_groups

If specified, the name field must match the key mapping to this boot set in the
boot_sets field of the containing V2SessionTemplate.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|[BootSetName](#schemabootsetname)|false|none|The Boot Set name.<br><br>* Boot Set names must use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Boot Set names must begin and end with a letter or digit.|
|path|[BootManifestPath](#schemabootmanifestpath)|true|none|A path identifying the metadata describing the components of the boot image.<br>This could be a URI, URL, etc, depending on the type of the Boot Set.|
|cfs|[V2CfsParameters](#schemav2cfsparameters)|false|none|This is the collection of parameters that are passed to the Configuration<br>Framework Service when configuration is enabled. Can be set as the global value for<br>a Session Template, or individually within a Boot Set.|
|type|[BootSetType](#schemabootsettype)|true|none|The MIME type of the metadata describing the components of the boot image. This type controls how BOS processes the path attribute.|
|etag|[BootSetEtag](#schemabootsetetag)|false|none|This is the 'entity tag'. It helps verify the version of metadata describing the components of the boot image we are working with.|
|kernel_parameters|[BootKernelParameters](#schemabootkernelparameters)|false|none|The kernel parameters to use to boot the nodes.|
|node_list|[NodeList](#schemanodelist)|false|none|A node list that is required to have at least one node.<br>Nodes must be specified by component name (xname). NIDs are not supported.<br>If the reject_nids option is enabled, then Session Template creation or validation will fail if<br>any of the boot sets contain a NodeList that appears to contain a NID.|
|node_roles_groups|[NodeRoleList](#schemanoderolelist)|false|none|Node role list. Allows actions against nodes with associated roles.|
|node_groups|[NodeGroupList](#schemanodegrouplist)|false|none|Node group list. Allows actions against associated nodes by logical groupings.|
|arch|string|false|none|The node architecture to target. Filters nodes that are not part of matching architecture from being targeted by boot actions. This value should correspond to HSM component 'Arch' field exactly. For reasons of backwards compatibility, all HSM nodes that are of type Unknown are treated as being of type X86.|
|rootfs_provider|[BootSetRootfsProvider](#schemabootsetrootfsprovider)|false|none|The root file system provider.|
|rootfs_provider_passthrough|[BootSetRootfsProviderPassthrough](#schemabootsetrootfsproviderpassthrough)|false|none|The root file system provider passthrough.<br>These are additional kernel parameters that will be appended to<br>the 'rootfs=<protocol>' kernel parameter|

#### Enumerated Values

|Property|Value|
|---|---|
|arch|X86|
|arch|ARM|
|arch|Other|
|arch|Unknown|

<h2 id="tocS_V2SessionTemplateArray">V2SessionTemplateArray</h2>
<!-- backwards compatibility -->
<a id="schemav2sessiontemplatearray"></a>
<a id="schema_V2SessionTemplateArray"></a>
<a id="tocSv2sessiontemplatearray"></a>
<a id="tocsv2sessiontemplatearray"></a>

```json
[
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
]

```

An array of Session Templates.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2SessionTemplate](#schemav2sessiontemplate)]|false|none|An array of Session Templates.|

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
  "limit": "",
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
|name|[V2SessionName](#schemav2sessionname)|true|none|Name of the Session.<br><br>The name must:<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.|
|tenant|[V2TenantName](#schemav2tenantname)|false|none|Name of the tenant that owns this resource. Only used in environments<br>with multi-tenancy enabled. An empty string or null value means the resource<br>is not owned by a tenant. The absence of this field from a resource indicates<br>the same.|
|operation|[V2SessionOperation](#schemav2sessionoperation)|true|none|A Session represents a desired state that is being applied to a group<br>of Components.  Sessions run until all Components it manages have<br>either been disabled due to completion, or until all Components are<br>managed by other newer Sessions.<br><br>Operation -- An operation to perform on Components in this Session.<br>    Boot                 Applies the Template to the Components and boots/reboots if necessary.<br>    Reboot               Applies the Template to the Components; guarantees a reboot.<br>    Shutdown             Power down Components that are on.|
|template_name|[SessionTemplateName](#schemasessiontemplatename)|true|none|Name of the Session Template.<br><br>The name must:<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.|
|limit|[SessionLimit](#schemasessionlimit)|false|none|A comma-separated list of nodes, groups, or roles to which the Session<br>will be limited. Components are treated as OR operations unless<br>preceded by "&" for AND or "!" for NOT.<br><br>Alternatively, the limit can be set to "*", which means no limit.<br><br>An empty string or null value is the same as specifying no limit.<br><br>If the reject_nids option is enabled, then Session creation will fail if its<br>limit appears to contain a NID value.|
|stage|boolean|false|none|Set to stage a Session which will not immediately change the state of any Components.<br>The "applystaged" endpoint can be called at a later time to trigger the start of this Session.|
|components|string|false|none|A comma-separated list of nodes, representing the initial list of nodes<br>the Session should operate against.  The list will remain even if<br>other Sessions have taken over management of the nodes.|
|include_disabled|boolean|false|none|Set to include nodes that have been disabled as indicated in the Hardware State Manager (HSM).|
|status|[V2SessionStatus](#schemav2sessionstatus)|false|none|Information on the status of a Session.|

<h2 id="tocS_V2SessionUpdate">V2SessionUpdate</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionupdate"></a>
<a id="schema_V2SessionUpdate"></a>
<a id="tocSv2sessionupdate"></a>
<a id="tocsv2sessionupdate"></a>

```json
{
  "components": "string",
  "status": {
    "start_time": "string",
    "end_time": "string",
    "status": "pending",
    "error": "string"
  }
}

```

A Session update object

## Link Relationships

* self : The Session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|components|string|false|none|A comma-separated list of nodes, representing the initial list of nodes<br>the Session should operate against.  The list will remain even if<br>other Sessions have taken over management of the nodes.|
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
    "limit": "",
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
|kernel|[BootKernelPath](#schemabootkernelpath)|false|none|A path to the kernel to use for booting.|
|kernel_parameters|[BootKernelParameters](#schemabootkernelparameters)|false|none|The kernel parameters to use to boot the nodes.|
|initrd|[BootInitrdPath](#schemabootinitrdpath)|false|none|A path to the initrd to use for booting.|

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

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The Component's ID. (e.g. xname for hardware Components)|

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

The actual boot artifacts and configuration for a Component

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
|configuration|[CfsConfiguration](#schemacfsconfiguration)|false|none|The name of configuration to be applied.|
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

The staged boot artifacts and configuration for a Component. Optionally, a Session
may be set which can be triggered at a later time against this Component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|boot_artifacts|[V2BootArtifacts](#schemav2bootartifacts)|false|none|A collection of boot artifacts.|
|configuration|[CfsConfiguration](#schemacfsconfiguration)|false|none|The name of configuration to be applied.|
|session|[V2SessionNameOrEmpty](#schemav2sessionnameorempty)|false|none|none|
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
  "power_on_attempts": 1048576,
  "power_off_graceful_attempts": 1048576,
  "power_off_forceful_attempts": 1048576
}

```

Information on the most recent attempt to return the node to its desired state.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|power_on_attempts|integer|false|none|How many attempts have been made to power-on since the last time the node was in the desired state.|
|power_off_graceful_attempts|integer|false|none|How many attempts have been made to power-off gracefully since the last time the node was in the desired state.|
|power_off_forceful_attempts|integer|false|none|How many attempts have been made to power-off forcefully since the last time the node was in the desired state.|

<h2 id="tocS_V2ComponentPhase">V2ComponentPhase</h2>
<!-- backwards compatibility -->
<a id="schemav2componentphase"></a>
<a id="schema_V2ComponentPhase"></a>
<a id="tocSv2componentphase"></a>
<a id="tocsv2componentphase"></a>

```json
"string"

```

The current phase of the Component in the boot process.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The current phase of the Component in the boot process.|

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
|phase|[V2ComponentPhase](#schemav2componentphase)|false|none|The current phase of the Component in the boot process.|
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
    "power_on_attempts": 1048576,
    "power_off_graceful_attempts": 1048576,
    "power_off_forceful_attempts": 1048576
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
|id|[V2ComponentId](#schemav2componentid)|false|none|The Component's ID. (e.g. xname for hardware Components)|
|actual_state|[V2ComponentActualState](#schemav2componentactualstate)|false|none|The actual boot artifacts and configuration for a Component|
|desired_state|[V2ComponentDesiredState](#schemav2componentdesiredstate)|false|none|The desired boot artifacts and configuration for a Component|
|staged_state|[V2ComponentStagedState](#schemav2componentstagedstate)|false|none|The staged boot artifacts and configuration for a Component. Optionally, a Session<br>may be set which can be triggered at a later time against this Component.|
|last_action|[V2ComponentLastAction](#schemav2componentlastaction)|false|none|Information on the most recent action taken against the node.|
|event_stats|[V2ComponentEventStats](#schemav2componenteventstats)|false|none|Information on the most recent attempt to return the node to its desired state.|
|status|[V2ComponentStatus](#schemav2componentstatus)|false|none|Status information for the Component|
|enabled|boolean|false|none|A flag indicating if actions should be taken for this Component.|
|error|string|false|none|A description of the most recent error to impact the Component.|
|session|[V2SessionNameOrEmpty](#schemav2sessionnameorempty)|false|none|none|
|retry_policy|integer|false|none|The maximum number attempts per action when actions fail.<br>Defaults to the global default_retry_policy if not set|

<h2 id="tocS_V2ComponentWithId">V2ComponentWithId</h2>
<!-- backwards compatibility -->
<a id="schemav2componentwithid"></a>
<a id="schema_V2ComponentWithId"></a>
<a id="tocSv2componentwithid"></a>
<a id="tocsv2componentwithid"></a>

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
    "power_on_attempts": 1048576,
    "power_off_graceful_attempts": 1048576,
    "power_off_forceful_attempts": 1048576
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
|id|[V2ComponentId](#schemav2componentid)|true|none|The Component's ID. (e.g. xname for hardware Components)|
|actual_state|[V2ComponentActualState](#schemav2componentactualstate)|false|none|The actual boot artifacts and configuration for a Component|
|desired_state|[V2ComponentDesiredState](#schemav2componentdesiredstate)|false|none|The desired boot artifacts and configuration for a Component|
|staged_state|[V2ComponentStagedState](#schemav2componentstagedstate)|false|none|The staged boot artifacts and configuration for a Component. Optionally, a Session<br>may be set which can be triggered at a later time against this Component.|
|last_action|[V2ComponentLastAction](#schemav2componentlastaction)|false|none|Information on the most recent action taken against the node.|
|event_stats|[V2ComponentEventStats](#schemav2componenteventstats)|false|none|Information on the most recent attempt to return the node to its desired state.|
|status|[V2ComponentStatus](#schemav2componentstatus)|false|none|Status information for the Component|
|enabled|boolean|false|none|A flag indicating if actions should be taken for this Component.|
|error|string|false|none|A description of the most recent error to impact the Component.|
|session|[V2SessionNameOrEmpty](#schemav2sessionnameorempty)|false|none|none|
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
      "power_on_attempts": 1048576,
      "power_off_graceful_attempts": 1048576,
      "power_off_forceful_attempts": 1048576
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

<h2 id="tocS_V2ComponentArrayWithIds">V2ComponentArrayWithIds</h2>
<!-- backwards compatibility -->
<a id="schemav2componentarraywithids"></a>
<a id="schema_V2ComponentArrayWithIds"></a>
<a id="tocSv2componentarraywithids"></a>
<a id="tocsv2componentarraywithids"></a>

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
      "power_on_attempts": 1048576,
      "power_off_graceful_attempts": 1048576,
      "power_off_forceful_attempts": 1048576
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

An array of Component states with associated Ids.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2ComponentWithId](#schemav2componentwithid)]|false|none|An array of Component states with associated Ids.|

<h2 id="tocS_V2ComponentsFilterByIds">V2ComponentsFilterByIds</h2>
<!-- backwards compatibility -->
<a id="schemav2componentsfilterbyids"></a>
<a id="schema_V2ComponentsFilterByIds"></a>
<a id="tocSv2componentsfilterbyids"></a>
<a id="tocsv2componentsfilterbyids"></a>

```json
{
  "ids": "string",
  "session": ""
}

```

Information for patching multiple Components by listing their IDs.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ids|string|true|none|A comma-separated list of Component IDs.|
|session|[EmptyStringNullable](#schemaemptystringnullable)|false|none|An empty string value.|

<h2 id="tocS_V2ComponentsFilterBySession">V2ComponentsFilterBySession</h2>
<!-- backwards compatibility -->
<a id="schemav2componentsfilterbysession"></a>
<a id="schema_V2ComponentsFilterBySession"></a>
<a id="tocSv2componentsfilterbysession"></a>
<a id="tocsv2componentsfilterbysession"></a>

```json
{
  "ids": "",
  "session": "session-20190728032600"
}

```

Information for patching multiple Components by Session name.
All Components part of this Session will be patched.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ids|[EmptyStringNullable](#schemaemptystringnullable)|false|none|An empty string value.|
|session|[V2SessionName](#schemav2sessionname)|true|none|Name of the Session.<br><br>The name must:<br>* Use only letters, digits, periods (.), dashes (-), and underscores (_).<br>* Begin and end with a letter or digit.|

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
      "power_on_attempts": 1048576,
      "power_off_graceful_attempts": 1048576,
      "power_off_forceful_attempts": 1048576
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
    "session": ""
  }
}

```

Information for patching multiple Components.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|patch|[V2Component](#schemav2component)|true|none|The current and desired artifacts state for a Component, and<br>the Session responsible for the Component's current state.|
|filters|any|true|none|none|

oneOf

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» *anonymous*|[V2ComponentsFilterByIds](#schemav2componentsfilterbyids)|false|none|Information for patching multiple Components by listing their IDs.|

xor

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» *anonymous*|[V2ComponentsFilterBySession](#schemav2componentsfilterbysession)|false|none|Information for patching multiple Components by Session name.<br>All Components part of this Session will be patched.|

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
  "default_retry_policy": 1,
  "disable_components_on_completion": true,
  "discovery_frequency": 33554432,
  "ims_errors_fatal": true,
  "ims_images_must_exist": true,
  "logging_level": "string",
  "max_boot_wait_time": 1048576,
  "max_component_batch_size": 1000,
  "max_power_off_wait_time": 1048576,
  "max_power_on_wait_time": 1048576,
  "polling_frequency": 1048576,
  "reject_nids": true,
  "session_limit_required": true
}

```

Options for the Boot Orchestration Service.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|cleanup_completed_session_ttl|string|false|none|Delete complete Sessions that are older than cleanup_completed_session_ttl (in minutes, hours, days, or weeks).<br>0 disables cleanup behavior.|
|clear_stage|boolean|false|none|Allows a Component's staged information to be cleared when the requested staging action has been started. Defaults to false.|
|component_actual_state_ttl|string|false|none|The maximum amount of time a Component's actual state is considered valid (in minutes, hours, days, or weeks).<br>0 disables cleanup behavior for newly booted nodes and instructs bos-state-reporter to report once instead of periodically.|
|default_retry_policy|integer|false|none|The default maximum number attempts per node for failed actions.|
|disable_components_on_completion|boolean|false|none|If true, when a Session has brought a Component to its desired state, that Component will be marked as disabled in BOS.<br>If false, BOS will continue to maintain the state of the nodes declaratively, even after a Session finishes.|
|discovery_frequency|integer|false|none|How frequently the BOS discovery agent syncs new Components from HSM (in seconds)|
|ims_errors_fatal|boolean|false|none|This option modifies how BOS behaves when validating the architecture of a boot image in a boot set.<br>Specifically, this option comes into play when BOS needs data from IMS in order to do this validation, but<br>IMS is unreachable.<br>In the above situation, if this option is true, then the validation will fail.<br>Otherwise, if the option is false, then a warning will be logged, but the validation will not<br>be failed because of this.|
|ims_images_must_exist|boolean|false|none|This option modifies how BOS behaves when validating a boot set whose boot image appears to be from IMS.<br>Specifically, this option comes into play when the image does not actually exist in IMS.<br>In the above situation, if this option is true, then the validation will fail.<br>Otherwise, if the option is false, then a warning will be logged, but the validation will not<br>be failed because of this. Note that if ims_images_must_exist is true but ims_errors_fatal is false, then<br>a failure to determine whether or not an image is in IMS will NOT result in a fatal error.|
|logging_level|string|false|none|The logging level for all BOS services|
|max_boot_wait_time|integer|false|none|How long BOS will wait for a node to boot into a usable state before rebooting it again (in seconds)|
|max_component_batch_size|integer|false|none|The maximum number of Components that a BOS operator will process at once. 0 means no limit.|
|max_power_off_wait_time|integer|false|none|How long BOS will wait for a node to power off before forcefully powering off (in seconds)|
|max_power_on_wait_time|integer|false|none|How long BOS will wait for a node to power on before calling power on again (in seconds)|
|polling_frequency|integer|false|none|How frequently the BOS operators check Component state for needed actions (in seconds)|
|reject_nids|boolean|false|none|If true, then BOS will attempt to prevent Sessions and Session Templates that reference NIDs (which BOS does not support).<br>Specifically, if this option is true, then:<br>- When creating a Session, if the Session limit or a Session Template node list appear to contain NID values, then Session creation will fail.<br>- When creating a Session Template, if a node list appears to contain a NID value, then the Session Template creation will fail.<br>- When validating an existing Session Template, if a node list appears to contain a NID value, then the validation will report an error.<br><br>This option does NOT have an effect on Sessions that were created prior to it being enabled (even if they have not yet started).|
|session_limit_required|boolean|false|none|If true, Sessions cannot be created without specifying the limit parameter.|

