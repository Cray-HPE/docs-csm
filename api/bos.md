<!-- Generator: Widdershins v4.0.1 -->

<h1 id="boot-orchestration-service">Boot Orchestration Service v0.0.0-api</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The Boot Orchestration Service (BOS) provides coordinated provisioning actions
over defined hardware sets to enable boot, reboot, shutdown, configuration and
staging for specified hardware subsets. These provisioning actions apply state
through numerous system management APIs at the request of system administrators
for managed product environments.

The default content type for the BOS API is "application/json". Unsuccessful
API calls return a content type of "application/problem+json" as per RFC 7807.

## Resources

### /sessiontemplate

A session template sets the operational context of which nodes to operate on for
any given set of nodes. It is largely comprised of one or more boot
sets and their associated software configuration.

A boot set defines a list of nodes, the image you want to boot/reboot the nodes with,
kernel parameters to use to boot the nodes, and additional configuration management
framework actions to apply during node bring up.

### /session

A BOS session applies a provided action to the nodes defined in a session
template.

## Workflow

### Create a New Session

#### GET /sessiontemplate

List available session templates.
Note the *name* which uniquely identifies each session template.
This value can be used to create a new session later,
if specified in the request body of POST /session.

#### POST /sessiontemplate

If no session template pre-exists that satisfies requirements,
then create a new session template. *name* uniquely identifies the
session template.
This value can be used to create a new session later,
if specified in the request body of POST /session.

#### POST /session

Specify template_name and an
operation to create a new session.
The template_name corresponds to the session template *name*.
A new session is launched as a result of this call.

A limit can also be specified to narrow the scope of the session. The limit
can consist of nodes, groups or roles in a comma-separated list.
Multiple groups are treated as separated by OR, unless "&" is added to
the start of the component, in which case this becomes an AND.  Components
can also be preceded by "!" to exclude them.

Note, the response from a successful session launch contains *links*.
Within *links*, *href* is a string that uniquely identifies the session.
*href* is constructed using the session template name and a generated uuid.
Use the entire *href* string as the path parameter *session_id*
to uniquely identify a session in for the /session/{session_id}
endpoint.

#### GET /session/{session_id}

Get session details by session id.

List all in progress and completed sessions.

## Interactions with Other APIs

BOS works in concert with Image Management Service (IMS) to access boot images,
and if *enable_cfs* is true then
BOS will invoke CFS to configure the compute nodes.

All boot images specified via the session template, must be available via IMS.

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/bos">https://api-gw-service-nmn.local/apis/bos</a>

* <a href="https://cray-bos/">https://cray-bos/</a>

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
{
  "major": 0,
  "minor": 0,
  "patch": 0,
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="get__-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Get version details
The versioning system uses [semver](https://semver.org/).
## Link Relationships
* self : Link to itself
* versions : Link back to the versions resource|[Version](#schemaversion)|

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

> Example responses

> 200 Response

```json
{
  "major": 0,
  "minor": 0,
  "patch": 0,
  "links": [
    {
      "rel": "string",
      "href": "string"
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

> Example responses

> 200 Response

```json
{
  "major": 0,
  "minor": 0,
  "patch": 0,
  "links": [
    {
      "rel": "string",
      "href": "string"
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

Get bos health details.

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

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Create session template*

Create a new session template.

> Body parameter

```json
{
  "templateUrl": "string",
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
    "configuration": "string"
  },
  "partition": "string",
  "boot_sets": {
    "property1": {
      "name": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0,
      "path": "string",
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "network": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0,
      "path": "string",
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "network": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  }
}
```

<h3 id="create_v1_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V1SessionTemplate](#schemav1sessiontemplate)|true|A JSON object for creating a session template|

> Example responses

> 200 Response

```json
{
  "templateUrl": "string",
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
    "configuration": "string"
  },
  "partition": "string",
  "boot_sets": {
    "property1": {
      "name": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0,
      "path": "string",
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "network": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0,
      "path": "string",
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "network": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  },
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="create_v1_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session template details|[V1SessionTemplate](#schemav1sessiontemplate)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*List session templates*

List all session templates. Session templates are
uniquely identified by the name.

> Example responses

> 200 Response

```json
[
  {
    "templateUrl": "string",
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
      "configuration": "string"
    },
    "partition": "string",
    "boot_sets": {
      "property1": {
        "name": "string",
        "boot_ordinal": 0,
        "shutdown_ordinal": 0,
        "path": "string",
        "type": "string",
        "etag": "string",
        "kernel_parameters": "string",
        "network": "string",
        "node_list": [
          "string"
        ],
        "node_roles_groups": [
          "string"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "string",
        "rootfs_provider_passthrough": "string"
      },
      "property2": {
        "name": "string",
        "boot_ordinal": 0,
        "shutdown_ordinal": 0,
        "path": "string",
        "type": "string",
        "etag": "string",
        "kernel_parameters": "string",
        "network": "string",
        "node_list": [
          "string"
        ],
        "node_roles_groups": [
          "string"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "string",
        "rootfs_provider_passthrough": "string"
      }
    },
    "links": [
      {
        "rel": "string",
        "href": "string"
      }
    ]
  }
]
```

<h3 id="get_v1_sessiontemplates-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of SessionTemplates|Inline|

<h3 id="get_v1_sessiontemplates-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V1SessionTemplate](#schemav1sessiontemplate)]|false|none|[A Session Template object represents a collection of resources and metadata.<br>A session template is used to create a Session which when combined with an<br>action (i.e. boot, reconfigure, reboot, shutdown) will create a K8s BOA job<br>to complete the required tasks for the operation.<br><br>A Session Template can be created from a JSON structure.  It will return<br>a SessionTemplate name if successful.<br>This name is required when creating a Session.<br><br>## Link Relationships<br><br>* self : The session object<br>]|
|» templateUrl|string|false|none|The URL to the resource providing the session template data.<br>Specify either a templateURL, or the other session<br>template parameters.|
|» name|string|true|none|Name of the SessionTemplate. The length of the name is restricted to 45 characters.|
|» description|string|false|none|An optional description for the session template.|
|» cfs_url|string|false|none|The url for the repository providing the configuration. DEPRECATED|
|» cfs_branch|string|false|none|The name of the branch containing the configuration that you want to<br>apply to the nodes.  DEPRECATED.|
|» enable_cfs|boolean|false|none|Whether to enable the Configuration Framework Service (CFS).<br>Choices: true/false|
|» cfs|[V1CfsParameters](#schemav1cfsparameters)|false|none|CFS Parameters is the collection of parameters that are passed to the Configuration<br>Framework Service when configuration is enabled.|
|»» clone_url|string|false|none|The clone url for the repository providing the configuration. (DEPRECATED)|
|»» branch|string|false|none|The name of the branch containing the configuration that you want to<br>apply to the nodes. Mutually exclusive with commit. (DEPRECATED)|
|»» commit|string|false|none|The commit id of the configuration that you want to<br>apply to the nodes. Mutually exclusive with branch. (DEPRECATED)|
|»» playbook|string|false|none|The name of the playbook to run for configuration. The file path must be specified<br>relative to the base directory of the config repo. (DEPRECATED)|
|»» configuration|string|false|none|The name of configuration to be applied.|
|» partition|string|false|none|The machine partition to operate on.|
|» boot_sets|object|false|none|none|
|»» **additionalProperties**|[V1BootSet](#schemav1bootset)|false|none|A boot set defines a collection of nodes and the information about the<br>boot artifacts and parameters to be sent to each node over the specified<br>network to enable these nodes to boot. When multiple boot sets are used<br>in a session template, the boot_ordinal and shutdown_ordinal indicate<br>the order in which boot sets need to be acted upon. Boot sets sharing<br>the same ordinal number will be addressed at the same time.|
|»»» name|string|false|none|The Boot Set name.|
|»»» boot_ordinal|integer|false|none|The boot ordinal. This will establish the order for boot set operations.<br>Boot sets boot in order from the lowest to highest boot_ordinal.|
|»»» shutdown_ordinal|integer|false|none|The shutdown ordinal. This will establish the order for boot set<br>shutdown operations. Sets shutdown from low to high shutdown_ordinal.|
|»»» path|string|true|none|A path identifying the metadata describing the components of the boot image. This could be a URI, URL, etc.<br>It will be processed based on the type attribute.|
|»»» type|string|true|none|The mime type of the metadata describing the components of the boot image. This type controls how BOS processes the path attribute.|
|»»» etag|string|false|none|This is the 'entity tag'. It helps verify the version of metadata describing the components of the boot image we are working with.|
|»»» kernel_parameters|string|false|none|The kernel parameters to use to boot the nodes.|
|»»» network|string|false|none|The network over which the node will boot from.<br>Choices:  NMN -- Node Management Network<br>pattern: '^(?i)nmn$'|
|»»» node_list|[string]|false|none|The node list. This is an explicit mapping against hardware xnames.|
|»»» node_roles_groups|[string]|false|none|The node roles list. Allows actions against nodes with associated roles. Roles are defined in SMD.|
|»»» node_groups|[string]|false|none|The node groups list. Allows actions against associated nodes by logical groupings. Logical groups are user defined groups in SMD.|
|»»» rootfs_provider|string|false|none|The root file system provider.|
|»»» rootfs_provider_passthrough|string|false|none|The root file system provider passthrough.<br>These are additional kernel parameters that will be appended to<br>the 'rootfs=<protocol>' kernel parameter|
|» links|[[Link](#schemalink)]|false|read-only|[Link to other resources]|
|»» rel|string|false|none|none|
|»» href|string|false|none|none|

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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate/{session_template_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Get session template by id*

Get session template by session_template_id.
The session_template_id corresponds to the *name*
of the session template.

<h3 id="get_v1_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_template_id|path|string|true|Session Template ID|

> Example responses

> 200 Response

```json
{
  "templateUrl": "string",
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
    "configuration": "string"
  },
  "partition": "string",
  "boot_sets": {
    "property1": {
      "name": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0,
      "path": "string",
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "network": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0,
      "path": "string",
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "network": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  },
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="get_v1_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session template details|[V1SessionTemplate](#schemav1sessiontemplate)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

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

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v1/sessiontemplate/{session_template_id} \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
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

*Delete a session template*

Delete a session template.

<h3 id="delete_v1_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_template_id|path|string|true|Session Template ID|

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

<h3 id="delete_v1_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
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

*Get an example session template.*

Returns a skeleton of a session template, which can be
used as a starting point for users creating their own
session templates.

> Example responses

> 200 Response

```json
{
  "templateUrl": "string",
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
    "configuration": "string"
  },
  "partition": "string",
  "boot_sets": {
    "property1": {
      "name": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0,
      "path": "string",
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "network": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0,
      "path": "string",
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "network": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  },
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="get_v1_sessiontemplatetemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session template details|[V1SessionTemplate](#schemav1sessiontemplate)|

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

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v1/session \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Create a session*

The creation of a session performs the operation
specified in the SessionCreateRequest
on the boot set(s) defined in the session template.

> Body parameter

```json
{
  "operation": "string",
  "templateUuid": "my-session-template",
  "templateName": "my-session-template",
  "limit": "string"
}
```

<h3 id="create_v1_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V1Session](#schemav1session)|true|A JSON object for creating a Session|

> Example responses

> 200 Response

```json
{
  "operation": "string",
  "templateUuid": "my-session-template",
  "templateName": "my-session-template",
  "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "limit": "string",
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="create_v1_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session details|[V1Session](#schemav1session)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*List sessions*

List all sessions, including those in progress and those complete.

> Example responses

> 200 Response

```json
[
  {
    "operation": "string",
    "templateUuid": "my-session-template",
    "templateName": "my-session-template",
    "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
    "limit": "string",
    "links": [
      {
        "rel": "string",
        "href": "string"
      }
    ]
  }
]
```

<h3 id="get_v1_sessions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of Sessions|Inline|

<h3 id="get_v1_sessions-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V1Session](#schemav1session)]|false|none|[A Session object<br><br>## Link Relationships<br><br>* self : The session object<br>]|
|» operation|string|true|none|A Session represents an operation on a SessionTemplate. The creation of a session effectively results in the creation of a K8s Boot Orchestration Agent (BOA) job to perform the duties required to complete the operation.<br>Operation -- An operation to perform on nodes in this session.<br><br>    Boot         Boot nodes that are off.<br><br>    Configure    Reconfigure the nodes using the Configuration Framework<br>                 Service (CFS).<br><br>    Reboot       Gracefully power down nodes that are on and then power<br>                 them back up.<br><br>    Shutdown     Gracefully power down nodes that are on.|
|» templateUuid|string(string)|false|none|DEPRECATED - use templateName|
|» templateName|string(string)|false|none|The name of the Session Template|
|» job|string|false|read-only|The identity of the k8s job that is created to handle the session.|
|» limit|string|false|none|A comma separated of nodes, groups or roles to which the session will be limited. Components are treated as OR operations unless preceded by "&" for AND or "!" for NOT.|
|» links|[[Link](#schemalink)]|false|read-only|[Link to other resources]|
|»» rel|string|false|none|none|
|»» href|string|false|none|none|

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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Get session details by id*

Get session details by session_id.

<h3 id="get_v1_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|

> Example responses

> 200 Response

```json
{
  "operation": "string",
  "templateUuid": "my-session-template",
  "templateName": "my-session-template",
  "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "limit": "string",
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="get_v1_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session details|[V1Session](#schemav1session)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

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

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id} \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
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

*Delete session by id*

Delete session by session_id.

<h3 id="delete_v1_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|

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

<h3 id="delete_v1_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*A list of the statuses for the different boot sets.*

A list of the statuses for the different boot sets.

<h3 id="get_v1_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|

> Example responses

> 200 Response

```json
{
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "boot_sets": [
    "string"
  ],
  "id": "string",
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="get_v1_session_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of Boot Set Statuses and metadata|[V1SessionStatus](#schemav1sessionstatus)|
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

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Create the initial session status*

Creates the initial session status.

> Body parameter

```json
{
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "boot_sets": [
    "string"
  ],
  "id": "string",
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="create_v1_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V1SessionStatus](#schemav1sessionstatus)|true|A JSON object for creating the status for a session|
|session_id|path|string|true|Session ID|

> Example responses

> 204 Response

```json
{
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "boot_sets": [
    "string"
  ],
  "id": "string",
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="create_v1_session_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|A list of Boot Set Statuses and metadata|[V1SessionStatus](#schemav1sessionstatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

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

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Update the session status*

Update the session status. You can update the start or stop times.

> Body parameter

```json
{
  "start_time": "2020-04-24T12:00",
  "stop_time": "2020-04-24T12:00",
  "complete": true,
  "in_progress": false,
  "error_count": 0
}
```

<h3 id="update_v1_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V1GenericMetadata](#schemav1genericmetadata)|true|A JSON object for updating the status for a session|
|session_id|path|string|true|Session ID|

> Example responses

> 200 Response

```json
{
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "boot_sets": [
    "string"
  ],
  "id": "string",
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="update_v1_session_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of Boot Set Statuses and metadata|[V1SessionStatus](#schemav1sessionstatus)|
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

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
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

*Delete the session status*

Deletes an existing Session status

<h3 id="delete_v1_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|

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
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Get the status for a boot set.*

Get the status for a boot set.

<h3 id="get_v1_session_status_by_bootset-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot set name|

> Example responses

> 200 Response

```json
{
  "name": "Boot-Set",
  "session": "Session-ID",
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "phases": [
    {
      "name": "Boot",
      "metadata": {
        "start_time": "2020-04-24T12:00",
        "stop_time": "2020-04-24T12:00",
        "complete": true,
        "in_progress": false,
        "error_count": 0
      },
      "categories": [
        {
          "name": "Succeeded",
          "node_list": [
            [
              "x3000c0s19b1n0",
              "x3000c0s19b2n0"
            ]
          ]
        }
      ],
      "errors": {
        "property1": [
          [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        ],
        "property2": [
          [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        ]
      }
    }
  ],
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="get_v1_session_status_by_bootset-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of the Phase Statuses for the Boot Set and metadata|[V1BootSetStatus](#schemav1bootsetstatus)|
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

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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
  "name": "Boot-Set",
  "session": "Session-ID",
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "phases": [
    {
      "name": "Boot",
      "metadata": {
        "start_time": "2020-04-24T12:00",
        "stop_time": "2020-04-24T12:00",
        "complete": true,
        "in_progress": false,
        "error_count": 0
      },
      "categories": [
        {
          "name": "Succeeded",
          "node_list": [
            [
              "x3000c0s19b1n0",
              "x3000c0s19b2n0"
            ]
          ]
        }
      ],
      "errors": {
        "property1": [
          [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        ],
        "property2": [
          [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        ]
      }
    }
  ],
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="create_v1_boot_set_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V1BootSetStatus](#schemav1bootsetstatus)|true|A JSON object for creating a status for a Boot Set|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot set name|

> Example responses

> 201 Response

```json
{
  "name": "Boot-Set",
  "session": "Session-ID",
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "phases": [
    {
      "name": "Boot",
      "metadata": {
        "start_time": "2020-04-24T12:00",
        "stop_time": "2020-04-24T12:00",
        "complete": true,
        "in_progress": false,
        "error_count": 0
      },
      "categories": [
        {
          "name": "Succeeded",
          "node_list": [
            [
              "x3000c0s19b1n0",
              "x3000c0s19b2n0"
            ]
          ]
        }
      ],
      "errors": {
        "property1": [
          [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        ],
        "property2": [
          [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        ]
      }
    }
  ],
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="create_v1_boot_set_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|The created Boot Set status|[V1BootSetStatus](#schemav1bootsetstatus)|

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

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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
the boot set.

> Body parameter

```json
[
  {
    "update_type": "string",
    "phase": "string",
    "data": {
      "phase": "Boot",
      "source": "in_progress",
      "destination": "Succeeded",
      "node_list": [
        [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      ]
    }
  }
]
```

<h3 id="update_v1_session_status_by_bootset-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|any|true|A JSON object for updating the status for a session|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot set name|

> Example responses

> 200 Response

```json
{
  "name": "Boot-Set",
  "session": "Session-ID",
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "phases": [
    {
      "name": "Boot",
      "metadata": {
        "start_time": "2020-04-24T12:00",
        "stop_time": "2020-04-24T12:00",
        "complete": true,
        "in_progress": false,
        "error_count": 0
      },
      "categories": [
        {
          "name": "Succeeded",
          "node_list": [
            [
              "x3000c0s19b1n0",
              "x3000c0s19b2n0"
            ]
          ]
        }
      ],
      "errors": {
        "property1": [
          [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        ],
        "property2": [
          [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        ]
      }
    }
  ],
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="update_v1_session_status_by_bootset-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of Boot Set Statuses and metadata|[V1BootSetStatus](#schemav1bootsetstatus)|
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

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name} \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
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
|boot_set_name|path|string|true|Boot set name|

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
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}/{phase_name} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Get the status for a specific boot set and phase.*

Get the status for a specific boot set and phase.

<h3 id="get_v1_session_status_by_bootset_and_phase-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot set name|
|phase_name|path|string|true|The phase name|

> Example responses

> 200 Response

```json
{
  "name": "Boot",
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "categories": [
    {
      "name": "Succeeded",
      "node_list": [
        [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      ]
    }
  ],
  "errors": {
    "property1": [
      [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ]
    ],
    "property2": [
      [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ]
    ]
  }
}
```

<h3 id="get_v1_session_status_by_bootset_and_phase-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of the nodes in the Phase and Category|[V1PhaseStatus](#schemav1phasestatus)|
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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/{session_id}/status/{boot_set_name}/{phase_name}/{category_name} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Get the status for a specific boot set, phase, and category.*

Get the status for a specific boot set, phase, and category.

<h3 id="get_v1_session_status_by_bootset_and_phase_and_category-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|
|boot_set_name|path|string|true|Boot set name|
|phase_name|path|string|true|The phase name|
|category_name|path|string|true|The category name|

> Example responses

> 200 Response

```json
{
  "name": "Succeeded",
  "node_list": [
    [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ]
  ]
}
```

<h3 id="get_v1_session_status_by_bootset_and_phase_and_category-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of the nodes in the Phase and Category|[V1PhaseCategoryStatus](#schemav1phasecategorystatus)|
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

> Example responses

> 200 Response

```json
{
  "major": 0,
  "minor": 0,
  "patch": 0,
  "links": [
    {
      "rel": "string",
      "href": "string"
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

Get bos health details.

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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*List session templates*

List all session templates. Session templates are
uniquely identified by the name.

> Example responses

> 200 Response

```json
[
  {
    "name": "cle-1.0.0",
    "description": "string",
    "enable_cfs": true,
    "cfs": {
      "configuration": "string"
    },
    "boot_sets": {
      "property1": {
        "name": "string",
        "path": "string",
        "cfs": {
          "configuration": "string"
        },
        "type": "string",
        "etag": "string",
        "kernel_parameters": "string",
        "node_list": [
          "string"
        ],
        "node_roles_groups": [
          "string"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "string",
        "rootfs_provider_passthrough": "string"
      },
      "property2": {
        "name": "string",
        "path": "string",
        "cfs": {
          "configuration": "string"
        },
        "type": "string",
        "etag": "string",
        "kernel_parameters": "string",
        "node_list": [
          "string"
        ],
        "node_roles_groups": [
          "string"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "string",
        "rootfs_provider_passthrough": "string"
      }
    },
    "links": [
      {
        "rel": "string",
        "href": "string"
      }
    ]
  }
]
```

<h3 id="get_v2_sessiontemplates-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session template details|[V2SessionTemplateArray](#schemav2sessiontemplatearray)|

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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplatesvalid/{session_template_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Validate the session template by id*

Validate session template by session_template_id.
The session_template_id corresponds to the *name*
of the session template.

<h3 id="validate_v2_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_template_id|path|string|true|Session Template ID|

> Example responses

> 200 Response

```json
"string"
```

<h3 id="validate_v2_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session template validity details|[V2SessionTemplateValidation](#schemav2sessiontemplatevalidation)|
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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Get session template by id*

Get session template by session_template_id.
The session_template_id corresponds to the *name*
of the session template.

<h3 id="get_v2_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_template_id|path|string|true|Session Template ID|

> Example responses

> 200 Response

```json
{
  "name": "cle-1.0.0",
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "string"
  },
  "boot_sets": {
    "property1": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  },
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="get_v2_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session template details|[V2SessionTemplate](#schemav2sessiontemplate)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

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

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Create session template*

Create a new session template.

> Body parameter

```json
{
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "string"
  },
  "boot_sets": {
    "property1": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  }
}
```

<h3 id="put_v2_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2SessionTemplate](#schemav2sessiontemplate)|true|A JSON object for creating a session template|
|session_template_id|path|string|true|Session Template ID|

> Example responses

> 200 Response

```json
{
  "name": "cle-1.0.0",
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "string"
  },
  "boot_sets": {
    "property1": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  },
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="put_v2_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session template details|[V2SessionTemplate](#schemav2sessiontemplate)|
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

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Update a session template*

> Body parameter

```json
{
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "string"
  },
  "boot_sets": {
    "property1": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  }
}
```

<h3 id="patch_v2_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2SessionTemplate](#schemav2sessiontemplate)|true|A JSON object for updating a session template|
|session_template_id|path|string|true|Session Template ID|

> Example responses

> 200 Response

```json
{
  "name": "cle-1.0.0",
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "string"
  },
  "boot_sets": {
    "property1": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  },
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="patch_v2_sessiontemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session template details|[V2SessionTemplate](#schemav2sessiontemplate)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

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

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v2/sessiontemplates/{session_template_id} \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
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

*Delete a session template*

Delete a session template.

<h3 id="delete_v2_sessiontemplate-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_template_id|path|string|true|Session Template ID|

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

*Get an example session template.*

Returns a skeleton of a session template, which can be
used as a starting point for users creating their own
session templates.

> Example responses

> 200 Response

```json
{
  "name": "cle-1.0.0",
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "string"
  },
  "boot_sets": {
    "property1": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  },
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}
```

<h3 id="get_v2_sessiontemplatetemplate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session template details|[V2SessionTemplate](#schemav2sessiontemplate)|

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

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v2/sessions \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Create a session*

The creation of a session performs the operation
specified in the SessionCreateRequest
on the boot set(s) defined in the session template.

> Body parameter

```json
{
  "name": "session-20190728032600",
  "operation": "boot",
  "template_name": "my-session-template",
  "limit": "string",
  "stage": false
}
```

<h3 id="post_v2_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2SessionCreate](#schemav2sessioncreate)|true|The information to create a session|

> Example responses

> 201 Response

```json
{
  "name": "string",
  "operation": "boot",
  "template_name": "my-session-template",
  "limit": "string",
  "stage": true,
  "components": "string",
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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessions \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*List sessions*

List all sessions, including those in progress and those complete.

<h3 id="get_v2_sessions-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|min_age|query|string|false|Return only sessions older than the given age.  Age is given in the format "1d" or "6h"|
|max_age|query|string|false|Return only sessions younger than the given age.  Age is given in the format "1d" or "6h"|
|status|query|string|false|Return only sessions with the given status.|

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
    "name": "string",
    "operation": "boot",
    "template_name": "my-session-template",
    "limit": "string",
    "stage": true,
    "components": "string",
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
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Session details|[V2SessionArray](#schemav2sessionarray)|

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

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v2/sessions \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
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

*Delete multiple sessions.*

Delete multiple sessions.  If filters are provided, only sessions matching all filters will be deleted.  By default only completed sessions will be deleted.

<h3 id="delete_v2_sessions-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|min_age|query|string|false|Return only sessions older than the given age.  Age is given in the format "1d" or "6h"|
|max_age|query|string|false|Return only sessions younger than the given age.  Age is given in the format "1d" or "6h"|
|status|query|string|false|Return only sessions with the given status.|

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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Get session details by id*

Get session details by session_id.

<h3 id="get_v2_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|

> Example responses

> 200 Response

```json
{
  "name": "string",
  "operation": "boot",
  "template_name": "my-session-template",
  "limit": "string",
  "stage": true,
  "components": "string",
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

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Update a single session*

Update the state for a given session in the BOS database

> Body parameter

```json
{
  "name": "string",
  "operation": "boot",
  "template_name": "my-session-template",
  "limit": "string",
  "stage": true,
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
|body|body|[V2Session](#schemav2session)|true|The state for a single session|
|session_id|path|string|true|Session ID|

> Example responses

> 200 Response

```json
{
  "name": "string",
  "operation": "boot",
  "template_name": "my-session-template",
  "limit": "string",
  "stage": true,
  "components": "string",
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

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id} \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
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

*Delete session by id*

Delete session by session_id.

<h3 id="delete_v2_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|

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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}/status \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Get session extended status information by id*

Get session extended status information by id

<h3 id="get_v2_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|

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

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v2/sessions/{session_id}/status \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Saves the current session to database*

Saves the current session to database.  For use at session completion.

<h3 id="save_v2_session_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_id|path|string|true|Session ID|

> Example responses

> 200 Response

```json
{
  "name": "string",
  "operation": "boot",
  "template_name": "my-session-template",
  "limit": "string",
  "stage": true,
  "components": "string",
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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/components \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Retrieve the state of a collection of components*

Retrieve the full collection of components in the form of a ComponentArray. Full results can also be filtered by query parameters. Only the first filter parameter of each type is used and the parameters are applied in an AND fashion. If the collection is empty or the filters have no match, an empty array is returned.

<h3 id="get_v2_components-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|ids|query|string|false|Retrieve the components with the given id (e.g. xname for hardware components). Can be chained for selecting groups of components.|
|session|query|string|false|Retrieve the components with the given session id.|
|staged_session|query|string|false|Retrieve the components with the given staged session id.|
|enabled|query|boolean|false|Retrieve the components with the "enabled" state.|
|phase|query|string|false|Retrieve the components in the given phase.|
|status|query|string|false|Retrieve the components with the given status.|

> Example responses

> 200 Response

```json
[
  {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "session": "string",
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
    "session": "string",
    "retry_policy": 1
  }
]
```

<h3 id="get_v2_components-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component states|[V2ComponentArray](#schemav2componentarray)|
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

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/bos/v2/components \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Add or Replace a collection of components*

Update the state for a collection of components in the BOS database

> Body parameter

```json
[
  {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "bss_token": "string"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "bss_token": "string"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "session": "string"
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
    "session": "string",
    "retry_policy": 1
  }
]
```

<h3 id="put_v2_components-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2ComponentArray](#schemav2componentarray)|true|The state for an array of components|

> Example responses

> 200 Response

```json
[
  {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "session": "string",
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
    "session": "string",
    "retry_policy": 1
  }
]
```

<h3 id="put_v2_components-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component states|[V2ComponentArray](#schemav2componentarray)|
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

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v2/components \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Update a collection of components*

Update the state for a collection of components in the BOS database

> Body parameter

```json
{
  "patch": {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "bss_token": "string"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "bss_token": "string"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "session": "string"
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
    "session": "string",
    "retry_policy": 1
  },
  "filters": {
    "ids": "string",
    "session": "string"
  }
}
```

<h3 id="patch_v2_components-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|any|true|The state for an array of components|

> Example responses

> 200 Response

```json
[
  {
    "id": "string",
    "actual_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "session": "string",
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
    "session": "string",
    "retry_policy": 1
  }
]
```

<h3 id="patch_v2_components-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component states|[V2ComponentArray](#schemav2componentarray)|
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

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
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

*Retrieve the state of a single component*

Retrieve the current and desired state of a single component

<h3 id="get_v2_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|component_id|path|string|true|Component id. e.g. xname for hardware components|

> Example responses

> 200 Response

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "session": "string",
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
  "session": "string",
  "retry_policy": 1
}
```

<h3 id="get_v2_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V2Component](#schemav2component)|
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

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Add or Replace a single component*

Update the state for a given component in the BOS database

> Body parameter

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "bss_token": "string"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "bss_token": "string"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "session": "string"
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
  "session": "string",
  "retry_policy": 1
}
```

<h3 id="put_v2_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2Component](#schemav2component)|true|The state for a single component|
|component_id|path|string|true|Component id. e.g. xname for hardware components|

> Example responses

> 200 Response

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "session": "string",
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
  "session": "string",
  "retry_policy": 1
}
```

<h3 id="put_v2_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V2Component](#schemav2component)|
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

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Update a single component*

Update the state for a given component in the BOS database

> Body parameter

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "bss_token": "string"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "bss_token": "string"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "session": "string"
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
  "session": "string",
  "retry_policy": 1
}
```

<h3 id="patch_v2_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2Component](#schemav2component)|true|The state for a single component|
|component_id|path|string|true|Component id. e.g. xname for hardware components|

> Example responses

> 200 Response

```json
{
  "id": "string",
  "actual_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "session": "string",
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
  "session": "string",
  "retry_policy": 1
}
```

<h3 id="patch_v2_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V2Component](#schemav2component)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

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

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/bos/v2/components/{component_id} \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
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

*Delete a single component*

Delete the given component

<h3 id="delete_v2_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|component_id|path|string|true|Component id. e.g. xname for hardware components|

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

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/bos/v2/applystaged \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
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

*Start a staged session for the specified components*

Given a list of xnames, this will trigger the start of any sessions
staged for those components.  Components without a staged session
will be ignored, and a list all components that are acted on will
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
|body|body|[V2ApplyStagedComponents](#schemav2applystagedcomponents)|true|A list of xnames that should have their staged session applied.|

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
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A list of xnames that should have their staged session applied.|[V2ApplyStagedStatus](#schemav2applystagedstatus)|
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
  "cleanup_completed_session_ttl": "string",
  "clear_stage": true,
  "component_actual_state_ttl": "string",
  "disable_components_on_completion": true,
  "discovery_frequency": 0,
  "logging_level": "string",
  "max_boot_wait_time": 0,
  "max_power_on_wait_time": 0,
  "max_power_off_wait_time": 0,
  "polling_frequency": 0,
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
  "cleanup_completed_session_ttl": "string",
  "clear_stage": true,
  "component_actual_state_ttl": "string",
  "disable_components_on_completion": true,
  "discovery_frequency": 0,
  "logging_level": "string",
  "max_boot_wait_time": 0,
  "max_power_on_wait_time": 0,
  "max_power_off_wait_time": 0,
  "polling_frequency": 0,
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

> Example responses

> 200 Response

```json
{
  "major": 0,
  "minor": 0,
  "patch": 0,
  "links": [
    {
      "rel": "string",
      "href": "string"
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
  "cleanup_completed_session_ttl": "string",
  "clear_stage": true,
  "component_actual_state_ttl": "string",
  "disable_components_on_completion": true,
  "discovery_frequency": 0,
  "logging_level": "string",
  "max_boot_wait_time": 0,
  "max_power_on_wait_time": 0,
  "max_power_off_wait_time": 0,
  "polling_frequency": 0,
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

<h2 id="tocS_Version">Version</h2>
<!-- backwards compatibility -->
<a id="schemaversion"></a>
<a id="schema_Version"></a>
<a id="tocSversion"></a>
<a id="tocsversion"></a>

```json
{
  "major": 0,
  "minor": 0,
  "patch": 0,
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}

```

Version data

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|major|integer|false|none|none|
|minor|integer|false|none|none|
|patch|integer|false|none|none|
|links|[[Link](#schemalink)]|false|none|[Link to other resources]|

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
|type|string(uri)|false|none|Relative URI reference to the type of problem which includes human readable documentation.|
|title|string|false|none|Short, human-readable summary of the problem, should not change by occurrence.|
|status|integer|false|none|HTTP status code|
|instance|string(uri)|false|none|A relative URI reference that identifies the specific occurrence of the problem|
|detail|string|false|none|A human-readable explanation specific to this occurrence of the problem. Focus on helping correct the problem, rather than giving debugging information.|

<h2 id="tocS_Link">Link</h2>
<!-- backwards compatibility -->
<a id="schemalink"></a>
<a id="schema_Link"></a>
<a id="tocSlink"></a>
<a id="tocslink"></a>

```json
{
  "rel": "string",
  "href": "string"
}

```

Link to other resources

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|rel|string|false|none|none|
|href|string|false|none|none|

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
  "configuration": "string"
}

```

CFS Parameters is the collection of parameters that are passed to the Configuration
Framework Service when configuration is enabled.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|clone_url|string|false|none|The clone url for the repository providing the configuration. (DEPRECATED)|
|branch|string|false|none|The name of the branch containing the configuration that you want to<br>apply to the nodes. Mutually exclusive with commit. (DEPRECATED)|
|commit|string|false|none|The commit id of the configuration that you want to<br>apply to the nodes. Mutually exclusive with branch. (DEPRECATED)|
|playbook|string|false|none|The name of the playbook to run for configuration. The file path must be specified<br>relative to the base directory of the config repo. (DEPRECATED)|
|configuration|string|false|none|The name of configuration to be applied.|

<h2 id="tocS_V1GenericMetadata">V1GenericMetadata</h2>
<!-- backwards compatibility -->
<a id="schemav1genericmetadata"></a>
<a id="schema_V1GenericMetadata"></a>
<a id="tocSv1genericmetadata"></a>
<a id="tocsv1genericmetadata"></a>

```json
{
  "start_time": "2020-04-24T12:00",
  "stop_time": "2020-04-24T12:00",
  "complete": true,
  "in_progress": false,
  "error_count": 0
}

```

The status metadata

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|start_time|string|false|none|The start time|
|stop_time|string|false|none|The stop time|
|complete|boolean|false|none|Is the object's status complete|
|in_progress|boolean|false|none|Is the object still doing something|
|error_count|integer|false|none|How many errors were encountered|

<h2 id="tocS_V1NodeList">V1NodeList</h2>
<!-- backwards compatibility -->
<a id="schemav1nodelist"></a>
<a id="schema_V1NodeList"></a>
<a id="tocSv1nodelist"></a>
<a id="tocsv1nodelist"></a>

```json
[
  [
    "x3000c0s19b1n0",
    "x3000c0s19b2n0"
  ]
]

```

### Properties

*None*

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
    [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ]
  ]
}

```

A list of the nodes in a given category within a phase.

## Link Relationships

* self : The session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|Name of the Phase Category|
|node_list|[V1NodeList](#schemav1nodelist)|false|none|none|

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
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "categories": [
    {
      "name": "Succeeded",
      "node_list": [
        [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      ]
    }
  ],
  "errors": {
    "property1": [
      [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ]
    ],
    "property2": [
      [
        "x3000c0s19b1n0",
        "x3000c0s19b2n0"
      ]
    ]
  }
}

```

The phase's status. It is a list of all of the nodes in the phase and
what category those nodes fall into within the phase.

## Link Relationships

* self : The session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|Name of the Phase|
|metadata|[V1GenericMetadata](#schemav1genericmetadata)|false|none|The status metadata|
|categories|[[V1PhaseCategoryStatus](#schemav1phasecategorystatus)]|false|none|[A list of the nodes in a given category within a phase.<br><br>## Link Relationships<br><br>* self : The session object<br>]|
|errors|[V1NodeErrorsList](#schemav1nodeerrorslist)|false|none|Categorizing nodes into failures by the type of error they have.<br>This is an additive characterization. Nodes will be added to existing errors.<br>This does not overwrite previously existing errors.|

<h2 id="tocS_V1BootSetStatus">V1BootSetStatus</h2>
<!-- backwards compatibility -->
<a id="schemav1bootsetstatus"></a>
<a id="schema_V1BootSetStatus"></a>
<a id="tocSv1bootsetstatus"></a>
<a id="tocsv1bootsetstatus"></a>

```json
{
  "name": "Boot-Set",
  "session": "Session-ID",
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "phases": [
    {
      "name": "Boot",
      "metadata": {
        "start_time": "2020-04-24T12:00",
        "stop_time": "2020-04-24T12:00",
        "complete": true,
        "in_progress": false,
        "error_count": 0
      },
      "categories": [
        {
          "name": "Succeeded",
          "node_list": [
            [
              "x3000c0s19b1n0",
              "x3000c0s19b2n0"
            ]
          ]
        }
      ],
      "errors": {
        "property1": [
          [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        ],
        "property2": [
          [
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        ]
      }
    }
  ],
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}

```

The status for a Boot Set. It as a list of the phase statuses for the Boot Set.

## Link Relationships

* self : The session object
* phase : A phase of the boot set

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|Name of the Boot Set|
|session|string|false|none|Session ID|
|metadata|[V1GenericMetadata](#schemav1genericmetadata)|false|none|The status metadata|
|phases|[[V1PhaseStatus](#schemav1phasestatus)]|false|none|[The phase's status. It is a list of all of the nodes in the phase and<br>what category those nodes fall into within the phase.<br><br>## Link Relationships<br><br>* self : The session object<br>]|
|links|[[Link](#schemalink)]|false|none|[Link to other resources]|

<h2 id="tocS_V1SessionStatus">V1SessionStatus</h2>
<!-- backwards compatibility -->
<a id="schemav1sessionstatus"></a>
<a id="schema_V1SessionStatus"></a>
<a id="tocSv1sessionstatus"></a>
<a id="tocsv1sessionstatus"></a>

```json
{
  "metadata": {
    "start_time": "2020-04-24T12:00",
    "stop_time": "2020-04-24T12:00",
    "complete": true,
    "in_progress": false,
    "error_count": 0
  },
  "boot_sets": [
    "string"
  ],
  "id": "string",
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}

```

The status for a Boot Session. It is a list of all of the Boot Set Statuses in the session.
## Link Relationships

* self : The session object
* boot sets: URL to access the Boot Set status

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|metadata|[V1GenericMetadata](#schemav1genericmetadata)|false|none|The status metadata|
|boot_sets|[string]|false|none|The boot sets in the Session|
|id|string|false|none|Session ID|
|links|[[Link](#schemalink)]|false|none|[Link to other resources]|

<h2 id="tocS_V1BootSet">V1BootSet</h2>
<!-- backwards compatibility -->
<a id="schemav1bootset"></a>
<a id="schema_V1BootSet"></a>
<a id="tocSv1bootset"></a>
<a id="tocsv1bootset"></a>

```json
{
  "name": "string",
  "boot_ordinal": 0,
  "shutdown_ordinal": 0,
  "path": "string",
  "type": "string",
  "etag": "string",
  "kernel_parameters": "string",
  "network": "string",
  "node_list": [
    "string"
  ],
  "node_roles_groups": [
    "string"
  ],
  "node_groups": [
    "string"
  ],
  "rootfs_provider": "string",
  "rootfs_provider_passthrough": "string"
}

```

A boot set defines a collection of nodes and the information about the
boot artifacts and parameters to be sent to each node over the specified
network to enable these nodes to boot. When multiple boot sets are used
in a session template, the boot_ordinal and shutdown_ordinal indicate
the order in which boot sets need to be acted upon. Boot sets sharing
the same ordinal number will be addressed at the same time.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|The Boot Set name.|
|boot_ordinal|integer|false|none|The boot ordinal. This will establish the order for boot set operations.<br>Boot sets boot in order from the lowest to highest boot_ordinal.|
|shutdown_ordinal|integer|false|none|The shutdown ordinal. This will establish the order for boot set<br>shutdown operations. Sets shutdown from low to high shutdown_ordinal.|
|path|string|true|none|A path identifying the metadata describing the components of the boot image. This could be a URI, URL, etc.<br>It will be processed based on the type attribute.|
|type|string|true|none|The mime type of the metadata describing the components of the boot image. This type controls how BOS processes the path attribute.|
|etag|string|false|none|This is the 'entity tag'. It helps verify the version of metadata describing the components of the boot image we are working with.|
|kernel_parameters|string|false|none|The kernel parameters to use to boot the nodes.|
|network|string|false|none|The network over which the node will boot from.<br>Choices:  NMN -- Node Management Network<br>pattern: '^(?i)nmn$'|
|node_list|[string]|false|none|The node list. This is an explicit mapping against hardware xnames.|
|node_roles_groups|[string]|false|none|The node roles list. Allows actions against nodes with associated roles. Roles are defined in SMD.|
|node_groups|[string]|false|none|The node groups list. Allows actions against associated nodes by logical groupings. Logical groups are user defined groups in SMD.|
|rootfs_provider|string|false|none|The root file system provider.|
|rootfs_provider_passthrough|string|false|none|The root file system provider passthrough.<br>These are additional kernel parameters that will be appended to<br>the 'rootfs=<protocol>' kernel parameter|

<h2 id="tocS_V1SessionTemplate">V1SessionTemplate</h2>
<!-- backwards compatibility -->
<a id="schemav1sessiontemplate"></a>
<a id="schema_V1SessionTemplate"></a>
<a id="tocSv1sessiontemplate"></a>
<a id="tocsv1sessiontemplate"></a>

```json
{
  "templateUrl": "string",
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
    "configuration": "string"
  },
  "partition": "string",
  "boot_sets": {
    "property1": {
      "name": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0,
      "path": "string",
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "network": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "boot_ordinal": 0,
      "shutdown_ordinal": 0,
      "path": "string",
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "network": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  },
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}

```

A Session Template object represents a collection of resources and metadata.
A session template is used to create a Session which when combined with an
action (i.e. boot, reconfigure, reboot, shutdown) will create a K8s BOA job
to complete the required tasks for the operation.

A Session Template can be created from a JSON structure.  It will return
a SessionTemplate name if successful.
This name is required when creating a Session.

## Link Relationships

* self : The session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|templateUrl|string|false|none|The URL to the resource providing the session template data.<br>Specify either a templateURL, or the other session<br>template parameters.|
|name|string|true|none|Name of the SessionTemplate. The length of the name is restricted to 45 characters.|
|description|string|false|none|An optional description for the session template.|
|cfs_url|string|false|none|The url for the repository providing the configuration. DEPRECATED|
|cfs_branch|string|false|none|The name of the branch containing the configuration that you want to<br>apply to the nodes.  DEPRECATED.|
|enable_cfs|boolean|false|none|Whether to enable the Configuration Framework Service (CFS).<br>Choices: true/false|
|cfs|[V1CfsParameters](#schemav1cfsparameters)|false|none|CFS Parameters is the collection of parameters that are passed to the Configuration<br>Framework Service when configuration is enabled.|
|partition|string|false|none|The machine partition to operate on.|
|boot_sets|object|false|none|none|
|» **additionalProperties**|[V1BootSet](#schemav1bootset)|false|none|A boot set defines a collection of nodes and the information about the<br>boot artifacts and parameters to be sent to each node over the specified<br>network to enable these nodes to boot. When multiple boot sets are used<br>in a session template, the boot_ordinal and shutdown_ordinal indicate<br>the order in which boot sets need to be acted upon. Boot sets sharing<br>the same ordinal number will be addressed at the same time.|
|links|[[Link](#schemalink)]|false|read-only|[Link to other resources]|

<h2 id="tocS_V1Session">V1Session</h2>
<!-- backwards compatibility -->
<a id="schemav1session"></a>
<a id="schema_V1Session"></a>
<a id="tocSv1session"></a>
<a id="tocsv1session"></a>

```json
{
  "operation": "string",
  "templateUuid": "my-session-template",
  "templateName": "my-session-template",
  "job": "boa-07877de1-09bb-4ca8-a4e5-943b1262dbf0",
  "limit": "string",
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}

```

A Session object

## Link Relationships

* self : The session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|operation|string|true|none|A Session represents an operation on a SessionTemplate. The creation of a session effectively results in the creation of a K8s Boot Orchestration Agent (BOA) job to perform the duties required to complete the operation.<br>Operation -- An operation to perform on nodes in this session.<br><br>    Boot         Boot nodes that are off.<br><br>    Configure    Reconfigure the nodes using the Configuration Framework<br>                 Service (CFS).<br><br>    Reboot       Gracefully power down nodes that are on and then power<br>                 them back up.<br><br>    Shutdown     Gracefully power down nodes that are on.|
|templateUuid|string(string)|false|none|DEPRECATED - use templateName|
|templateName|string(string)|false|none|The name of the Session Template|
|job|string|false|read-only|The identity of the k8s job that is created to handle the session.|
|limit|string|false|none|A comma separated of nodes, groups or roles to which the session will be limited. Components are treated as OR operations unless preceded by "&" for AND or "!" for NOT.|
|links|[[Link](#schemalink)]|false|read-only|[Link to other resources]|

<h2 id="tocS_V1NodeChangeList">V1NodeChangeList</h2>
<!-- backwards compatibility -->
<a id="schemav1nodechangelist"></a>
<a id="schema_V1NodeChangeList"></a>
<a id="tocSv1nodechangelist"></a>
<a id="tocsv1nodechangelist"></a>

```json
{
  "phase": "Boot",
  "source": "in_progress",
  "destination": "Succeeded",
  "node_list": [
    [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ]
  ]
}

```

The information used to update the status of a node list. It moves nodes from
one category to another within a phase.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|phase|string|true|none|none|
|source|string|true|none|none|
|destination|string|true|none|none|
|node_list|[V1NodeList](#schemav1nodelist)|true|none|none|

<h2 id="tocS_V1NodeErrorsList">V1NodeErrorsList</h2>
<!-- backwards compatibility -->
<a id="schemav1nodeerrorslist"></a>
<a id="schema_V1NodeErrorsList"></a>
<a id="tocSv1nodeerrorslist"></a>
<a id="tocsv1nodeerrorslist"></a>

```json
{
  "property1": [
    [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ]
  ],
  "property2": [
    [
      "x3000c0s19b1n0",
      "x3000c0s19b2n0"
    ]
  ]
}

```

Categorizing nodes into failures by the type of error they have.
This is an additive characterization. Nodes will be added to existing errors.
This does not overwrite previously existing errors.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|**additionalProperties**|[V1NodeList](#schemav1nodelist)|false|none|none|

<h2 id="tocS_V1UpdateRequestNodeChangeList">V1UpdateRequestNodeChangeList</h2>
<!-- backwards compatibility -->
<a id="schemav1updaterequestnodechangelist"></a>
<a id="schema_V1UpdateRequestNodeChangeList"></a>
<a id="tocSv1updaterequestnodechangelist"></a>
<a id="tocsv1updaterequestnodechangelist"></a>

```json
[
  {
    "update_type": "string",
    "phase": "string",
    "data": {
      "phase": "Boot",
      "source": "in_progress",
      "destination": "Succeeded",
      "node_list": [
        [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      ]
    }
  }
]

```

This is the payload sent during an update request. It contains
updates to which categories nodes are in.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|update_type|string|false|none|The type of update data|
|phase|string|false|none|The phase that this data belongs to. If  blank, it belongs to<br>the Boot Set itself, which only applies to the GenericMetadata type.|
|data|[V1NodeChangeList](#schemav1nodechangelist)|false|none|The information used to update the status of a node list. It moves nodes from<br>one category to another within a phase.|

<h2 id="tocS_V1UpdateRequestNodeErrorsList">V1UpdateRequestNodeErrorsList</h2>
<!-- backwards compatibility -->
<a id="schemav1updaterequestnodeerrorslist"></a>
<a id="schema_V1UpdateRequestNodeErrorsList"></a>
<a id="tocSv1updaterequestnodeerrorslist"></a>
<a id="tocsv1updaterequestnodeerrorslist"></a>

```json
[
  {
    "update_type": "string",
    "phase": "string",
    "data": {
      "property1": [
        [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      ],
      "property2": [
        [
          "x3000c0s19b1n0",
          "x3000c0s19b2n0"
        ]
      ]
    }
  }
]

```

This is the payload sent during an update request. It contains
updates to which errors have occurred and which nodes encountered those errors

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|update_type|string|false|none|The type of update data|
|phase|string|false|none|The phase that this data belongs to. If  blank, it belongs to<br>the Boot Set itself, which only applies to the GenericMetadata type.|
|data|[V1NodeErrorsList](#schemav1nodeerrorslist)|false|none|Categorizing nodes into failures by the type of error they have.<br>This is an additive characterization. Nodes will be added to existing errors.<br>This does not overwrite previously existing errors.|

<h2 id="tocS_V1UpdateRequestGenericMetadata">V1UpdateRequestGenericMetadata</h2>
<!-- backwards compatibility -->
<a id="schemav1updaterequestgenericmetadata"></a>
<a id="schema_V1UpdateRequestGenericMetadata"></a>
<a id="tocSv1updaterequestgenericmetadata"></a>
<a id="tocsv1updaterequestgenericmetadata"></a>

```json
[
  {
    "update_type": "string",
    "phase": "string",
    "data": {
      "start_time": "2020-04-24T12:00",
      "stop_time": "2020-04-24T12:00",
      "complete": true,
      "in_progress": false,
      "error_count": 0
    }
  }
]

```

This is the payload sent during an update request. It contains
updates to metadata, specifically start and stop times

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|update_type|string|false|none|The type of update data|
|phase|string|false|none|The phase that this data belongs to. If the phase is boot_set, it belongs to<br>the Boot Set itself, which only applies to the GenericMetadata type.|
|data|[V1GenericMetadata](#schemav1genericmetadata)|false|none|The status metadata|

<h2 id="tocS_V2CfsParameters">V2CfsParameters</h2>
<!-- backwards compatibility -->
<a id="schemav2cfsparameters"></a>
<a id="schema_V2CfsParameters"></a>
<a id="tocSv2cfsparameters"></a>
<a id="tocsv2cfsparameters"></a>

```json
{
  "configuration": "string"
}

```

CFS Parameters is the collection of parameters that are passed to the Configuration
Framework Service when configuration is enabled. Can be set as the global value for
a Session Template, or individually within a boot set.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|configuration|string|false|none|The name of configuration to be applied.|

<h2 id="tocS_V2SessionTemplate">V2SessionTemplate</h2>
<!-- backwards compatibility -->
<a id="schemav2sessiontemplate"></a>
<a id="schema_V2SessionTemplate"></a>
<a id="tocSv2sessiontemplate"></a>
<a id="tocsv2sessiontemplate"></a>

```json
{
  "name": "cle-1.0.0",
  "description": "string",
  "enable_cfs": true,
  "cfs": {
    "configuration": "string"
  },
  "boot_sets": {
    "property1": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    },
    "property2": {
      "name": "string",
      "path": "string",
      "cfs": {
        "configuration": "string"
      },
      "type": "string",
      "etag": "string",
      "kernel_parameters": "string",
      "node_list": [
        "string"
      ],
      "node_roles_groups": [
        "string"
      ],
      "node_groups": [
        "string"
      ],
      "rootfs_provider": "string",
      "rootfs_provider_passthrough": "string"
    }
  },
  "links": [
    {
      "rel": "string",
      "href": "string"
    }
  ]
}

```

A Session Template object represents a collection of resources and metadata.
A session template is used to create a Session which applies the data to
group of components.

A Session Template can be created from a JSON structure.  It will return
a SessionTemplate name if successful.
This name is required when creating a Session.

## Link Relationships

* self : The session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|read-only|Name of the SessionTemplate. The length of the name is restricted to 45 characters.|
|description|string|false|none|An optional description for the session template.|
|enable_cfs|boolean|false|none|Whether to enable the Configuration Framework Service (CFS).<br>Choices: true/false|
|cfs|[V2CfsParameters](#schemav2cfsparameters)|false|none|CFS Parameters is the collection of parameters that are passed to the Configuration<br>Framework Service when configuration is enabled. Can be set as the global value for<br>a Session Template, or individually within a boot set.|
|boot_sets|object|false|none|none|
|» **additionalProperties**|[V2BootSet](#schemav2bootset)|false|none|A boot set is a collection of nodes defined by an explicit list, their functional<br>role, and their logical groupings. This collection of nodes is associated with one<br>set of boot artifacts and optional additional records for configuration and root<br>filesystem provisioning.|
|links|[[Link](#schemalink)]|false|read-only|[Link to other resources]|

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
    "description": "string",
    "enable_cfs": true,
    "cfs": {
      "configuration": "string"
    },
    "boot_sets": {
      "property1": {
        "name": "string",
        "path": "string",
        "cfs": {
          "configuration": "string"
        },
        "type": "string",
        "etag": "string",
        "kernel_parameters": "string",
        "node_list": [
          "string"
        ],
        "node_roles_groups": [
          "string"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "string",
        "rootfs_provider_passthrough": "string"
      },
      "property2": {
        "name": "string",
        "path": "string",
        "cfs": {
          "configuration": "string"
        },
        "type": "string",
        "etag": "string",
        "kernel_parameters": "string",
        "node_list": [
          "string"
        ],
        "node_roles_groups": [
          "string"
        ],
        "node_groups": [
          "string"
        ],
        "rootfs_provider": "string",
        "rootfs_provider_passthrough": "string"
      }
    },
    "links": [
      {
        "rel": "string",
        "href": "string"
      }
    ]
  }
]

```

An array of session templates.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2SessionTemplate](#schemav2sessiontemplate)]|false|none|An array of session templates.|

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
  "template_name": "my-session-template",
  "limit": "string",
  "stage": false
}

```

A Session Creation object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|Name of the session. A uuid name is generated if a name is not provided.|
|operation|string|true|none|A Session represents a desired state that is being applied to a group of components.  Sessions run until all components it manages have either been disabled due to completion, or until all components are managed by other newer sessions.<br>Operation -- An operation to perform on nodes in this session.<br>    Boot                 Applies the template to the components and boots/reboots if necessary.<br>    Reboot               Applies the template to the components guarantees a reboot.<br>    Shutdown             Power down nodes that are on.|
|template_name|string(string)|true|none|The name of the Session Template|
|limit|string|false|none|A comma separated of nodes, groups or roles to which the session will be limited. Components are treated as OR operations unless preceded by "&" for AND or "!" for NOT.|
|stage|boolean|false|none|Set to stage a session which will not immediately change the state of any components. The "applystaged" endpoint can be called at a later time to trigger the start of this session.|

#### Enumerated Values

|Property|Value|
|---|---|
|operation|boot|
|operation|reboot|
|operation|shutdown|

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

Information on the status of a session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|start_time|string|false|none|When the session was created.|
|end_time|string|false|none|When the session completed.|
|status|string|false|none|The status of a session.|
|error|string|false|none|Error which prevented the session from running|

#### Enumerated Values

|Property|Value|
|---|---|
|status|pending|
|status|running|
|status|complete|

<h2 id="tocS_V2BootSet">V2BootSet</h2>
<!-- backwards compatibility -->
<a id="schemav2bootset"></a>
<a id="schema_V2BootSet"></a>
<a id="tocSv2bootset"></a>
<a id="tocsv2bootset"></a>

```json
{
  "name": "string",
  "path": "string",
  "cfs": {
    "configuration": "string"
  },
  "type": "string",
  "etag": "string",
  "kernel_parameters": "string",
  "node_list": [
    "string"
  ],
  "node_roles_groups": [
    "string"
  ],
  "node_groups": [
    "string"
  ],
  "rootfs_provider": "string",
  "rootfs_provider_passthrough": "string"
}

```

A boot set is a collection of nodes defined by an explicit list, their functional
role, and their logical groupings. This collection of nodes is associated with one
set of boot artifacts and optional additional records for configuration and root
filesystem provisioning.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|The Boot Set name.|
|path|string|true|none|A path identifying the metadata describing the components of the boot image. This could be a URI, URL, etc.<br>It will be processed based on the type attribute.|
|cfs|[V2CfsParameters](#schemav2cfsparameters)|false|none|CFS Parameters is the collection of parameters that are passed to the Configuration<br>Framework Service when configuration is enabled. Can be set as the global value for<br>a Session Template, or individually within a boot set.|
|type|string|true|none|The mime type of the metadata describing the components of the boot image. This type controls how BOS processes the path attribute.|
|etag|string|false|none|This is the 'entity tag'. It helps verify the version of metadata describing the components of the boot image we are working with.|
|kernel_parameters|string|false|none|The kernel parameters to use to boot the nodes.|
|node_list|[string]|false|none|The node list. This is an explicit mapping against hardware xnames.|
|node_roles_groups|[string]|false|none|The node roles list. Allows actions against nodes with associated roles. Roles are defined in SMD.|
|node_groups|[string]|false|none|The node groups list. Allows actions against associated nodes by logical groupings. Logical groups are user defined groups in SMD.|
|rootfs_provider|string|false|none|The root file system provider.|
|rootfs_provider_passthrough|string|false|none|The root file system provider passthrough.<br>These are additional kernel parameters that will be appended to<br>the 'rootfs=<protocol>' kernel parameter|

<h2 id="tocS_V2Session">V2Session</h2>
<!-- backwards compatibility -->
<a id="schemav2session"></a>
<a id="schema_V2Session"></a>
<a id="tocSv2session"></a>
<a id="tocsv2session"></a>

```json
{
  "name": "string",
  "operation": "boot",
  "template_name": "my-session-template",
  "limit": "string",
  "stage": true,
  "components": "string",
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

* self : The session object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|Name of the session.|
|operation|string|false|none|A Session represents a desired state that is being applied to a group of components.  Sessions run until all components it manages have either been disabled due to completion, or until all components are managed by other newer sessions.<br>Operation -- An operation to perform on nodes in this session.<br>    Boot                 Applies the template to the components and boots/reboots if necessary.<br>    Reboot               Applies the template to the components guarantees a reboot.<br>    Shutdown             Power down nodes that are on.|
|template_name|string(string)|false|none|The name of the Session Template|
|limit|string|false|none|A comma separated of nodes, groups or roles to which the session will be limited. Components are treated as OR operations unless preceded by "&" for AND or "!" for NOT.|
|stage|boolean|false|none|Set to stage a session which will not immediately change the state of any components. The "applystaged" endpoint can be called at a later time to trigger the start of this session.|
|components|string|false|none|A comma separated list of nodes, representing the initial list of nodes the session should operate against.  The list will remain even if other sessions have taken over management of the nodes.|
|status|[V2SessionStatus](#schemav2sessionstatus)|false|none|Information on the status of a session.|

#### Enumerated Values

|Property|Value|
|---|---|
|operation|boot|
|operation|reboot|
|operation|shutdown|

<h2 id="tocS_V2SessionArray">V2SessionArray</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionarray"></a>
<a id="schema_V2SessionArray"></a>
<a id="tocSv2sessionarray"></a>
<a id="tocsv2sessionarray"></a>

```json
[
  {
    "name": "string",
    "operation": "boot",
    "template_name": "my-session-template",
    "limit": "string",
    "stage": true,
    "components": "string",
    "status": {
      "start_time": "string",
      "end_time": "string",
      "status": "pending",
      "error": "string"
    }
  }
]

```

An array of sessions.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2Session](#schemav2session)]|false|none|An array of sessions.|

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

Detailed information on the phases of a session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|percent_complete|number|false|none|The percent of components currently in a completed/stable state|
|percent_powering_on|number|false|none|The percent of components currently in the powering-on phase|
|percent_powering_off|number|false|none|The percent of components currently in the powering-off phase|
|percent_configuring|number|false|none|The percent of components currently in the configuring phase|

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

Detailed information on the timing of a session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|start_time|string|false|none|When the session was created.|
|end_time|string|false|none|When the session completed.|
|duration|string|false|none|The current duration of the on-going session or final duration of the completed session.|

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

Detailed information on the status of a session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|status|string|false|none|The status of a session.|
|managed_components_count|integer|false|none|The count of components currently managed by this session|
|phases|[V2SessionExtendedStatusPhases](#schemav2sessionextendedstatusphases)|false|none|Detailed information on the phases of a session.|
|percent_successful|number|false|none|The percent of components currently in a successful state|
|percent_failed|number|false|none|The percent of components currently in a failed state|
|percent_staged|number|false|none|The percent of components currently still staged for this session|
|error_summary|object|false|none|A summary of the errors currently listed by all components|
|timing|[V2SessionExtendedStatusTiming](#schemav2sessionextendedstatustiming)|false|none|Detailed information on the timing of a session.|

#### Enumerated Values

|Property|Value|
|---|---|
|status|pending|
|status|running|
|status|complete|

<h2 id="tocS_V2BootArtifacts">V2BootArtifacts</h2>
<!-- backwards compatibility -->
<a id="schemav2bootartifacts"></a>
<a id="schema_V2BootArtifacts"></a>
<a id="tocSv2bootartifacts"></a>
<a id="tocsv2bootartifacts"></a>

```json
{
  "kernel": "string",
  "kernel_parameters": "string",
  "initrd": "string"
}

```

A collection of boot artifacts.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|kernel|string|false|none|An md5sum hash of the kernel ID|
|kernel_parameters|string|false|none|Kernel parameters|
|initrd|string|false|none|Initrd ID|

<h2 id="tocS_V2ComponentActualState">V2ComponentActualState</h2>
<!-- backwards compatibility -->
<a id="schemav2componentactualstate"></a>
<a id="schema_V2ComponentActualState"></a>
<a id="tocSv2componentactualstate"></a>
<a id="tocsv2componentactualstate"></a>

```json
{
  "boot_artifacts": {
    "kernel": "string",
    "kernel_parameters": "string",
    "initrd": "string"
  },
  "bss_token": "string",
  "last_updated": "2019-07-28T03:26:00Z"
}

```

The desired boot artifacts and configuration for a component

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|boot_artifacts|[V2BootArtifacts](#schemav2bootartifacts)|false|none|A collection of boot artifacts.|
|bss_token|string|false|none|A token received from the node identifying the boot artifacts.  For BOS use-only, users should not set this field. It will be overwritten.|
|last_updated|string(date-time)|false|read-only|The date/time when the state was last updated in RFC 3339 format.|

<h2 id="tocS_V2ComponentDesiredState">V2ComponentDesiredState</h2>
<!-- backwards compatibility -->
<a id="schemav2componentdesiredstate"></a>
<a id="schema_V2ComponentDesiredState"></a>
<a id="tocSv2componentdesiredstate"></a>
<a id="tocsv2componentdesiredstate"></a>

```json
{
  "boot_artifacts": {
    "kernel": "string",
    "kernel_parameters": "string",
    "initrd": "string"
  },
  "configuration": "string",
  "bss_token": "string",
  "last_updated": "2019-07-28T03:26:00Z"
}

```

The desired boot artifacts and configuration for a component

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|boot_artifacts|[V2BootArtifacts](#schemav2bootartifacts)|false|none|A collection of boot artifacts.|
|configuration|string|false|none|A CFS configuration ID.|
|bss_token|string|false|none|A token received from BSS identifying the boot artifacts.  For BOS use-only, users should not set this field. It will be overwritten.|
|last_updated|string(date-time)|false|read-only|The date/time when the state was last updated in RFC 3339 format.|

<h2 id="tocS_V2ComponentStagedState">V2ComponentStagedState</h2>
<!-- backwards compatibility -->
<a id="schemav2componentstagedstate"></a>
<a id="schema_V2ComponentStagedState"></a>
<a id="tocSv2componentstagedstate"></a>
<a id="tocsv2componentstagedstate"></a>

```json
{
  "boot_artifacts": {
    "kernel": "string",
    "kernel_parameters": "string",
    "initrd": "string"
  },
  "configuration": "string",
  "session": "string",
  "last_updated": "2019-07-28T03:26:00Z"
}

```

The desired boot artifacts and configuration for a component

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|boot_artifacts|[V2BootArtifacts](#schemav2bootartifacts)|false|none|A collection of boot artifacts.|
|configuration|string|false|none|A CFS configuration ID.|
|session|string|false|none|A session which can be triggered at a later time against this component.|
|last_updated|string(date-time)|false|read-only|The date/time when the state was last updated in RFC 3339 format.|

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
|last_updated|string(date-time)|false|read-only|The date/time when the state was last updated in RFC 3339 format.|
|action|string|false|none|A description of the most recent operator/action to impact the component.|
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

Status information for the component

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|phase|string|false|none|The current phase of the component in the boot process.|
|status|string|false|read-only|The current status of the component.  More detailed than phase.|
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
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "desired_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "bss_token": "string",
    "last_updated": "2019-07-28T03:26:00Z"
  },
  "staged_state": {
    "boot_artifacts": {
      "kernel": "string",
      "kernel_parameters": "string",
      "initrd": "string"
    },
    "configuration": "string",
    "session": "string",
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
  "session": "string",
  "retry_policy": 1
}

```

The current and desired artifacts state for a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string|false|none|The component's id. e.g. xname for hardware components|
|actual_state|[V2ComponentActualState](#schemav2componentactualstate)|false|none|The desired boot artifacts and configuration for a component|
|desired_state|[V2ComponentDesiredState](#schemav2componentdesiredstate)|false|none|The desired boot artifacts and configuration for a component|
|staged_state|[V2ComponentStagedState](#schemav2componentstagedstate)|false|none|The desired boot artifacts and configuration for a component|
|last_action|[V2ComponentLastAction](#schemav2componentlastaction)|false|none|Information on the most recent action taken against the node.|
|event_stats|[V2ComponentEventStats](#schemav2componenteventstats)|false|none|Information on the most recent attempt to return the node to its desired state.|
|status|[V2ComponentStatus](#schemav2componentstatus)|false|none|Status information for the component|
|enabled|boolean|false|none|A flag indicating if actions should be taken for this component.|
|error|string|false|none|A description of the most recent error to impact the component.|
|session|string|false|none|The session responsible for the component's current state|
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
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "session": "string",
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
    "session": "string",
    "retry_policy": 1
  }
]

```

An array of component states.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2Component](#schemav2component)]|false|none|An array of component states.|

<h2 id="tocS_V2ComponentsFilter">V2ComponentsFilter</h2>
<!-- backwards compatibility -->
<a id="schemav2componentsfilter"></a>
<a id="schema_V2ComponentsFilter"></a>
<a id="tocSv2componentsfilter"></a>
<a id="tocsv2componentsfilter"></a>

```json
{
  "ids": "string",
  "session": "string"
}

```

Information for patching multiple components.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ids|string|false|none|A comma separated list of component ids|
|session|string|false|none|A session name.  All components part of this session will be patched.|

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
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "desired_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "bss_token": "string",
      "last_updated": "2019-07-28T03:26:00Z"
    },
    "staged_state": {
      "boot_artifacts": {
        "kernel": "string",
        "kernel_parameters": "string",
        "initrd": "string"
      },
      "configuration": "string",
      "session": "string",
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
    "session": "string",
    "retry_policy": 1
  },
  "filters": {
    "ids": "string",
    "session": "string"
  }
}

```

Information for patching multiple components.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|patch|[V2Component](#schemav2component)|true|none|The current and desired artifacts state for a component.|
|filters|[V2ComponentsFilter](#schemav2componentsfilter)|true|none|Information for patching multiple components.|

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

A list of components that should have their staged session applied.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xnames|[string]|false|none|The list of component xnames|

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

A list of components that should have their staged session applied.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|succeeded|[string]|false|none|The list of component xnames|
|failed|[string]|false|none|The list of component xnames|
|ignored|[string]|false|none|The list of component xnames|

<h2 id="tocS_V2Options">V2Options</h2>
<!-- backwards compatibility -->
<a id="schemav2options"></a>
<a id="schema_V2Options"></a>
<a id="tocSv2options"></a>
<a id="tocsv2options"></a>

```json
{
  "cleanup_completed_session_ttl": "string",
  "clear_stage": true,
  "component_actual_state_ttl": "string",
  "disable_components_on_completion": true,
  "discovery_frequency": 0,
  "logging_level": "string",
  "max_boot_wait_time": 0,
  "max_power_on_wait_time": 0,
  "max_power_off_wait_time": 0,
  "polling_frequency": 0,
  "default_retry_policy": 1
}

```

Options for the boot orchestration service.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|cleanup_completed_session_ttl|string|false|none|Delete complete sessions that are older than cleanup_completed_session_ttl (in hours). 0h disables cleanup behavior.|
|clear_stage|boolean|false|none|Allows components staged information to be cleared when the requested staging action has been started. Defaults to false.|
|component_actual_state_ttl|string|false|none|The maximum amount of time a component's actual state is considered valid (in hours). 0h disables cleanup behavior for newly booted nodes and instructs bos-state-reporter to report once instead of periodically.|
|disable_components_on_completion|boolean|false|none|Allows for BOS components to be marked as disabled after a session has been completed. If false, BOS will continue to maintain the state of the nodes declaratively, even after a session finishes.|
|discovery_frequency|integer|false|none|How frequently the BOS discovery agent syncs new components from HSM. (in seconds)|
|logging_level|string|false|none|The logging level for all BOS services|
|max_boot_wait_time|integer|false|none|How long BOS will wait for a node to boot into a usable state before rebooting it again (in seconds)|
|max_power_on_wait_time|integer|false|none|How long BOS will wait for a node to power on before calling power on again (in seconds)|
|max_power_off_wait_time|integer|false|none|How long BOS will wait for a node to power off before forcefully powering off (in seconds)|
|polling_frequency|integer|false|none|How frequently the BOS operators check component state for needed actions. (in seconds)|
|default_retry_policy|integer|false|none|The default maximum number attempts per node for failed actions.|

