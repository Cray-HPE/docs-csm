<!-- Generator: Widdershins v4.0.1 -->

<h1 id="configuration-framework-service">Configuration Framework Service v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The Configuration Framework Service (CFS) manages the launch of Ansible Execution Environments for image customization, node personalization, and node reconfiguration. CFS manages the Ansible staging container that pulls Ansible play/role content and inventory (optional) from the git server and launches the Ansible Execution Environment.

CFS includes the following components:

  * CFS REST API
  * A Kubernetes operator running on the management services infrastructure to handle
  the lifecycle and reporting of configuration sessions.
  * Pre-packaged Ansible Execution Environment(s) (AEE) with values tuned for performant
  configuration for executing Ansible playbooks against Cray compute and user access nodes.

CFS uses a Git version control server running in the management services infrastructure for management of the configuration manifest lifecycle.

  The CFS API allows an administrator to customize the compute and user access nodes
  in the following ways:
* Customize the bootable images prior to their use on the system. This process is called

  image customization. CFS uses IMS to stage images in an ssh container and then modifies
  one or more images using Ansible.

* Customize live nodes during boot or post-boot. This process is called node personalization.

  Node personalization involves applying software and/or configuration that differentiates
  a node or a group of nodes from all other groups of nodes.
  This should be used in scenarios where configuration cannot be applied prior to booting
  a node. It is typically best to make changes pre-boot via image customization. This ensures
  Ansible only has to run once against an image, rather than against every individual booted node.
  The BOS and IMS APIs support CFS to customize live nodes during boot time.

## Resources
/healthz - Check service health

/options - Updates service options.

/sessions - Create, retrieve, or delete configuration sessions.

/components - Add, update, retrieve, or delete component information.

/configurations - Add, update, retrieve or delete desired configuration states. (v2 api only)
## Workflows
### Image Customization

 #### GET /images

 Identify the IMS image that you want to customize. Note the id of the image that you want to customize.

 #### POST /sessions

 Create a configuration session and push the configuration to the specific image in IMS.
 You must specify the target definition as image and provide id of the image that you want to customize.
 This step customizes the image as per Ansible playbook and saves the image in the IMS.

### Node Personalization

 #### POST /sessions
 Create a configuration framework session to push configuration to nodes that have already
 been booted, specifying the target (optional), the git repository location, inventory (optional),
 and gives the session a unique name.

 #### GET /sessions/{session_name}
 View details and status for the specific session_name.

 #### DELETE /sessions/{session_name}
 Delete all session history for session_name (as needed).

The default content type for the CFS API is `application/json`. Unsuccessful API calls return a content type of `application/problem+json` as per RFC 7807.

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/cfs">https://api-gw-service-nmn.local/apis/cfs</a>

<h1 id="configuration-framework-service-version">version</h1>

## get_version

<a id="opIdget_version"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/ HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/ \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/", data)
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
  "patch": 0
}
```

<h3 id="get_version-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Version information for the service|[Version](#schemaversion)|

<aside class="success">
This operation does not require authentication
</aside>

## get_versions

<a id="opIdget_versions"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/versions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/versions \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/versions', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/versions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /versions`

*Get API versions*

Return list of versions currently running.

> Example responses

> 200 Response

```json
{
  "major": 0,
  "minor": 0,
  "patch": 0
}
```

<h3 id="get_versions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Version information for the service|[Version](#schemaversion)|

<aside class="success">
This operation does not require authentication
</aside>

## get_versions_v2

<a id="opIdget_versions_v2"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2 HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2 \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v2', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v2", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2`

*Get API versions*

Return list of versions currently running.

> Example responses

> 200 Response

```json
{
  "major": 0,
  "minor": 0,
  "patch": 0
}
```

<h3 id="get_versions_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Version information for the service|[Version](#schemaversion)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="configuration-framework-service-healthz">healthz</h1>

## get_healthz

<a id="opIdget_healthz"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/healthz HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/healthz \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/healthz', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/healthz", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /healthz`

*Get service health details*

Get cfs-api health details.

> Example responses

> 200 Response

```json
{
  "dbStatus": "string",
  "kafkaStatus": "string"
}
```

<h3 id="get_healthz-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Status information for the service|[Healthz](#schemahealthz)|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|Status information for the service|[Healthz](#schemahealthz)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="configuration-framework-service-options">options</h1>

## get_options

<a id="opIdget_options"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/options HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/options \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v2/options', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v2/options", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/options`

*Retrieve the configuration service options*

Retrieve the list of configuration service options.

> Example responses

> 200 Response

```json
{
  "hardwareSyncInterval": 5,
  "batcherCheckInterval": 5,
  "batchSize": 120,
  "batchWindow": 120,
  "defaultBatcherRetryPolicy": 1,
  "defaultPlaybook": "site.yml",
  "defaultAnsibleConfig": "cfs-default-ansible-cfg",
  "sessionTTL": "24h",
  "additionalInventoryUrl": "https://api-gw-service-nmn.local/vcs/cray/inventory.git",
  "batcherMaxBackoff": 3600,
  "batcherDisable": true,
  "batcherPendingTimeout": 0,
  "loggingLevel": "string"
}
```

<h3 id="get_options-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of service-wide configuration options|[V2Options](#schemav2options)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_options

<a id="opIdpatch_options"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v2/options HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v2/options \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v2/options', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v2/options", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v2/options`

*Update configuration service options*

Update one or more of the configuration service options.

> Body parameter

```json
{
  "hardwareSyncInterval": 5,
  "batcherCheckInterval": 5,
  "batchSize": 120,
  "batchWindow": 120,
  "defaultBatcherRetryPolicy": 1,
  "defaultPlaybook": "site.yml",
  "defaultAnsibleConfig": "cfs-default-ansible-cfg",
  "sessionTTL": "24h",
  "additionalInventoryUrl": "https://api-gw-service-nmn.local/vcs/cray/inventory.git",
  "batcherMaxBackoff": 3600,
  "batcherDisable": true,
  "batcherPendingTimeout": 0,
  "loggingLevel": "string"
}
```

<h3 id="patch_options-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2Options](#schemav2options)|true|Service-wide configuration options|

> Example responses

> 200 Response

```json
{
  "hardwareSyncInterval": 5,
  "batcherCheckInterval": 5,
  "batchSize": 120,
  "batchWindow": 120,
  "defaultBatcherRetryPolicy": 1,
  "defaultPlaybook": "site.yml",
  "defaultAnsibleConfig": "cfs-default-ansible-cfg",
  "sessionTTL": "24h",
  "additionalInventoryUrl": "https://api-gw-service-nmn.local/vcs/cray/inventory.git",
  "batcherMaxBackoff": 3600,
  "batcherDisable": true,
  "batcherPendingTimeout": 0,
  "loggingLevel": "string"
}
```

<h3 id="patch_options-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of service-wide configuration options|[V2Options](#schemav2options)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="configuration-framework-service-sessions">sessions</h1>

## get_sessions

<a id="opIdget_sessions"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/sessions \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v2/sessions', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v2/sessions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/sessions`

*Retrieve configuration framework sessions*

Retrieve all the configuration framework sessions on the system.

<h3 id="get_sessions-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|age|query|string|false|Return only sessions older than the given age.  Age is given in the format "1d" or "6h" DEPRECATED: This field has been replaced by min_age and max_age|
|min_age|query|string|false|Return only sessions older than the given age.  Age is given in the format "1d" or "6h"|
|max_age|query|string|false|Return only sessions younger than the given age.  Age is given in the format "1d" or "6h"|
|status|query|string|false|Return only sessions with the given status.|
|name_contains|query|string|false|Return only sessions whose session name contains the given string.|
|succeeded|query|string|false|Return only sessions that have succeeded/failed.|
|tags|query|string|false|Return only sessions whose have the matching tags.  Key-value pairs should be separated using =, and tags can be a comma-separated list. Only sessions that match all tags will be returned.|

#### Enumerated Values

|Parameter|Value|
|---|---|
|status|pending|
|status|running|
|status|complete|
|succeeded|none|
|succeeded|true|
|succeeded|false|
|succeeded|unknown|

> Example responses

> 200 Response

```json
[
  {
    "name": "session-20190728032600",
    "configuration": {
      "name": "example-config",
      "limit": "layer1,layer3"
    },
    "ansible": {
      "config": "cfs-default-ansible-cfg",
      "limit": "host1",
      "verbosity": 0,
      "passthrough": "string"
    },
    "target": {
      "definition": "spec",
      "groups": [
        {
          "name": "test-computes",
          "members": [
            "nid000001",
            "nid000002",
            "nid000003"
          ]
        }
      ],
      "image_map": [
        {
          "source_id": "ff287206-6ff7-4659-92ad-6e732821c6b4",
          "result_name": "new-test-image"
        }
      ]
    },
    "status": {
      "artifacts": [
        {
          "image_id": "f34ff35e-d782-4a65-a1b8-243a3cd740af",
          "result_id": "8b782ccd-8706-4145-a6a1-724e29ed5522",
          "type": "ims_customized_image"
        }
      ],
      "session": {
        "job": "cray-cfs-job-session-20190728032600",
        "completionTime": "2019-07-28T03:26:00Z",
        "startTime": "2019-07-28T03:26:00Z",
        "status": "pending",
        "succeeded": "none"
      }
    },
    "tags": {
      "property1": "string",
      "property2": "string"
    }
  }
]
```

<h3 id="get_sessions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of configuration sessions|Inline|

<h3 id="get_sessions-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2Session](#schemav2session)]|false|none|[An execution session for the Configuration Framework.<br>]|
|» name|string|false|none|Name of the session. The length of the name is restricted to 45 characters.|
|» configuration|object|false|none|The configuration information which the session will apply|
|»» name|string|false|none|The name of the CFS configuration to be applied|
|»» limit|string|false|none|A comma seperated list of layers in the configuration to limit the session to. This can be either a list of named layers, or a list of indices.|
|» ansible|object|false|none|Additional options that will be used when invoking Ansible.|
|»» config|string|false|none|The Kubernetes ConfigMap which holds the ansible.cfg for a given CFS session. This ConfigMap must be present in the same Kubernetes namespace as the CFS service. If no value is given, the value of the defaultAnsibleConfig field in the /options endpoint will be used.|
|»» limit|string|false|none|Additional filtering of hosts or groups from the inventory to run against. This is especially useful when running with dynamic inventory and when you want to run on a subset of nodes or groups. This option corresponds to ansible-playbook's --limit and can be used to specify nodes or groups.|
|»» verbosity|integer|false|none|The verbose mode to use in the call to the ansible-playbook command. 1 = -v, 2 = -vv, etc. Valid values range from 0 to 4. See the ansible-playbook help for more information.|
|»» passthrough|string|false|none|Additional parameters that are added to all Ansible calls for the session. This field is currently limited to the following Ansible parameters: "--extra-vars", "--forks", "--skip-tags", "--start-at-task", and "--tags". WARNING: Parameters passed to Ansible in this way should be used with caution.  State will not be recorded for components when using these flags to avoid incorrect reporting of partial playbook runs.|
|» target|[TargetSpecSection](#schematargetspecsection)|false|none|A target lets you define the nodes or images that you want to customize and consists of two sub-parameters - Definition and groups. By default, Configuration Framework Sessions use dynamic inventory definition to target hosts. When using a session to customize an image, or if a static inventory is required, use this optional section to specify entities (whether images or nodes) for the session to target.|
|»» definition|string|false|none|Source of inventory definition to be used in the configuration session.<br><br>'image' denotes that the session will target an image root through the Image<br>Management Service (IMS). Group members should be a single image identifier known by IMS.<br><br>'spec' denotes inventory that is specified directly via CFS in the target<br>groups/members of this object. You can include a node name (a DNS resolvable name),<br>or a group name and a list of nodes. The command line inventory can be a quick<br>and simple way to run Ansible against a small subset of nodes. However, if more<br>customization of the inventory is needed, specifically customization of host and<br>groups variables, the repo target definition should be used.<br><br>'repo' denotes the inventory will be used from the git repository<br>specified for this session (via `cloneUrl`, and `branch` or `commit`). The inventory<br>must be located in the "hosts" file at the root of the repository.<br><br>'dynamic' (default) will use the CFS-provided dynamic inventory plugin to define<br>the inventory. The hosts file is automatically generated by CFS with data from<br>the Hardware State Manager (HSM), which includes groups and hardware roles.|
|»» groups|[object]|false|none|Specification of the groups and group members per the inventory definition. This list is not valid for the 'repo' and 'dynamic' inventory definition types. Multiple groups can be specified for 'image' and 'spec' inventory definition types.|
|»»» name|string|true|none|Group name|
|»»» members|[string]|true|none|Group members for the inventory.|
|»» image_map|[object]|false|none|Mapping of image IDs to resultant image names.  This is only valid for 'image' inventory definition types.<br>Only images that are defined in 'groups' will result in a new image.<br>If images in 'groups' are not specified here, CFS will generate a name for the resultant image.|
|»»» source_id|string|true|none|Source image id.  This is the image id that is used in 'groups'.|
|»»» result_name|string|true|none|Resultant image name.|
|» status|object|false|none|Status of artifacts, session, and targets. Lists details like session status, session start and completion time, number of successful, failed, or running targets. If the target definition is an image, it also lists the image_id, result_id, and type of image under Artifacts.|
|»» artifacts|[object]|false|none|none|
|»»» image_id|string(uuid)|false|none|The IMS id of the original image to be customized via a configuration session.|
|»»» result_id|string(uuid)|false|none|The IMS id of the image that was customized via a configuration session. This is the resultant image of the customization.|
|»»» type|string|false|none|none|
|»» session|object|false|none|none|
|»»» job|string|false|read-only|The name of the configuration execution environment associated with this session.|
|»»» completionTime|string(date-time)|false|read-only|The date/time when the session completed execution in RFC 3339 format.|
|»»» startTime|string(date-time)|false|read-only|The date/time when the session started execution in RFC 3339 format.|
|»»» status|string|false|read-only|The execution status of the session.|
|»»» succeeded|string|false|read-only|Whether the session executed successfully or not. A 'none'<br>value denotes that the execution has not completed. This<br>field has context when the `status` field is 'complete'.<br>A session may successfully execute even if the underlying<br>tasks do not.|
|» tags|object|false|none|A collection of key-value pairs containing descriptive information for the session, such as information about the session creator.|
|»» **additionalProperties**|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|definition|image|
|definition|spec|
|definition|repo|
|definition|dynamic|
|type|ims_customized_image|
|status|pending|
|status|running|
|status|complete|
|succeeded|none|
|succeeded|true|
|succeeded|false|
|succeeded|unknown|

<aside class="success">
This operation does not require authentication
</aside>

## create_session

<a id="opIdcreate_session"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/cfs/v2/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/cfs/v2/sessions \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/cfs/v2/sessions', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/cfs/v2/sessions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v2/sessions`

*Create a configuration framework session*

Create a new configuration session. A configuration session stages Ansible inventory, launches one or more Ansible Execution Environments (AEE) as containers in the management services infrastructure, and tears down the environments as required. When a session is targeted for image customization, the inventory staging involves using IMS to expose the requested image roots, tearing down the image roots, and generating new boot artifacts afterwards. The session will checkout the prescribed branch or commit of the configuration repository and populate the configuration manifest to the AEE. The Ansible execution begins with an inventory prescribed by the user through CFS. A configuration session also tracks the status of the different stages of the operation and reports information on the success of its execution.

> Body parameter

```json
{
  "name": "session-20190728032600",
  "configurationName": "example-config",
  "configurationLimit": "layer1,layer3",
  "ansibleLimit": "host1",
  "ansibleConfig": "cfs-default-ansible-cfg",
  "ansibleVerbosity": 0,
  "ansiblePassthrough": "string",
  "target": {
    "definition": "spec",
    "groups": [
      {
        "name": "test-computes",
        "members": [
          "nid000001",
          "nid000002",
          "nid000003"
        ]
      }
    ],
    "image_map": [
      {
        "source_id": "ff287206-6ff7-4659-92ad-6e732821c6b4",
        "result_name": "new-test-image"
      }
    ]
  },
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="create_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2SessionCreate](#schemav2sessioncreate)|true|A JSON object for creating Config Framework Sessions|

> Example responses

> 201 Response

```json
{
  "name": "session-20190728032600",
  "configuration": {
    "name": "example-config",
    "limit": "layer1,layer3"
  },
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": "host1",
    "verbosity": 0,
    "passthrough": "string"
  },
  "target": {
    "definition": "spec",
    "groups": [
      {
        "name": "test-computes",
        "members": [
          "nid000001",
          "nid000002",
          "nid000003"
        ]
      }
    ],
    "image_map": [
      {
        "source_id": "ff287206-6ff7-4659-92ad-6e732821c6b4",
        "result_name": "new-test-image"
      }
    ]
  },
  "status": {
    "artifacts": [
      {
        "image_id": "f34ff35e-d782-4a65-a1b8-243a3cd740af",
        "result_id": "8b782ccd-8706-4145-a6a1-724e29ed5522",
        "type": "ims_customized_image"
      }
    ],
    "session": {
      "job": "cray-cfs-job-session-20190728032600",
      "completionTime": "2019-07-28T03:26:00Z",
      "startTime": "2019-07-28T03:26:00Z",
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="create_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|A single configuration session|[V2Session](#schemav2session)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|A session with the same name already exists.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_sessions

<a id="opIddelete_sessions"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v2/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v2/sessions \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/cfs/v2/sessions', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/cfs/v2/sessions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v2/sessions`

*Delete multiple configuration framework sessions*

Delete multiple configuration sessions.  If filters are provided, only sessions matching all filters will be deleted.  By default only completed sessions will be deleted.

<h3 id="delete_sessions-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|age|query|string|false|Deletes only sessions older than the given age.  Age is given in the format "1d" or "6h" DEPRECATED: This field has been replaced by min_age and max_age|
|min_age|query|string|false|Return only sessions older than the given age.  Age is given in the format "1d" or "6h"|
|max_age|query|string|false|Return only sessions younger than the given age.  Age is given in the format "1d" or "6h"|
|status|query|string|false|Deletes only sessions with the given status.|
|name_contains|query|string|false|Delete only sessions whose session name contains the given string.|
|succeeded|query|string|false|Delete only sessions that have succeeded/failed.|
|tags|query|string|false|Return only sessions whose have the matching tags.  Key-value pairs should be separated using =, and tags can be a comma-separated list. Only sessions that match all tags will be deleted.|

#### Enumerated Values

|Parameter|Value|
|---|---|
|status|pending|
|status|running|
|status|complete|
|succeeded|none|
|succeeded|true|
|succeeded|false|
|succeeded|unknown|

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

<h3 id="delete_sessions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_session

<a id="opIdget_session"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/sessions/{session_name}`

*Retrieve a configuration framework session by session_name*

View details about a specific configuration session. This allows you to track the status of the session and the Ansible execution through the session.

<h3 id="get_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_name|path|string|true|Config Framework Session name|

> Example responses

> 200 Response

```json
{
  "name": "session-20190728032600",
  "configuration": {
    "name": "example-config",
    "limit": "layer1,layer3"
  },
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": "host1",
    "verbosity": 0,
    "passthrough": "string"
  },
  "target": {
    "definition": "spec",
    "groups": [
      {
        "name": "test-computes",
        "members": [
          "nid000001",
          "nid000002",
          "nid000003"
        ]
      }
    ],
    "image_map": [
      {
        "source_id": "ff287206-6ff7-4659-92ad-6e732821c6b4",
        "result_name": "new-test-image"
      }
    ]
  },
  "status": {
    "artifacts": [
      {
        "image_id": "f34ff35e-d782-4a65-a1b8-243a3cd740af",
        "result_id": "8b782ccd-8706-4145-a6a1-724e29ed5522",
        "type": "ims_customized_image"
      }
    ],
    "session": {
      "job": "cray-cfs-job-session-20190728032600",
      "completionTime": "2019-07-28T03:26:00Z",
      "startTime": "2019-07-28T03:26:00Z",
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="get_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration session|[V2Session](#schemav2session)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_session

<a id="opIdpatch_session"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v2/sessions/{session_name}`

*Update a configuration framework session*

Update the status of an existing configuration framework session

<h3 id="patch_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_name|path|string|true|Config Framework Session name|

> Example responses

> 200 Response

```json
{
  "name": "session-20190728032600",
  "configuration": {
    "name": "example-config",
    "limit": "layer1,layer3"
  },
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": "host1",
    "verbosity": 0,
    "passthrough": "string"
  },
  "target": {
    "definition": "spec",
    "groups": [
      {
        "name": "test-computes",
        "members": [
          "nid000001",
          "nid000002",
          "nid000003"
        ]
      }
    ],
    "image_map": [
      {
        "source_id": "ff287206-6ff7-4659-92ad-6e732821c6b4",
        "result_name": "new-test-image"
      }
    ]
  },
  "status": {
    "artifacts": [
      {
        "image_id": "f34ff35e-d782-4a65-a1b8-243a3cd740af",
        "result_id": "8b782ccd-8706-4145-a6a1-724e29ed5522",
        "type": "ims_customized_image"
      }
    ],
    "session": {
      "job": "cray-cfs-job-session-20190728032600",
      "completionTime": "2019-07-28T03:26:00Z",
      "startTime": "2019-07-28T03:26:00Z",
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="patch_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration session|[V2Session](#schemav2session)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_session

<a id="opIddelete_session"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v2/sessions/{session_name}`

*Delete a configuration framework session*

Deleting a configuration session deletes the Kubernetes objects associated with the session and also deletes the session history. The operation cannot be undone.

<h3 id="delete_session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|session_name|path|string|true|Config Framework Session name|

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

<h3 id="delete_session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="configuration-framework-service-components">components</h1>

## get_components

<a id="opIdget_components"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/components HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/components \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v2/components', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v2/components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/components`

*Retrieve the state of a collection of components*

Retrieve the full collection of components in the form of a ComponentArray. Full results can also be filtered by query parameters. Only the first filter parameter of each type is used and the parameters are applied in an AND fashion. If the collection is empty or the filters have no match, an empty array is returned.

<h3 id="get_components-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|ids|query|string|false|Retrieve the components with the given id (e.g. xname for hardware components). Can be chained for selecting groups of components.|
|status|query|string|false|Retrieve the components with the status. Multiple statuses can be specified in a comma-separated list.|
|enabled|query|boolean|false|Retrieve the components with the "enabled" state.|
|configName|query|string|false|Retrieve the components with the given configuration set as the desired state.|
|configDetails|query|boolean|false|Include the configuration and config status in the response|
|tags|query|string|false|Return only components whose have the matching tags.  Key-value pairs should be separated using =, and tags can be a comma-separated list.  Only components that match all tags will be returned.|

#### Enumerated Values

|Parameter|Value|
|---|---|
|status|unconfigured|
|status|failed|
|status|pending|
|status|configured|

> Example responses

> 200 Response

```json
[
  {
    "id": "string",
    "state": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "lastUpdated": "2019-07-28T03:26:00Z",
        "sessionName": "string"
      }
    ],
    "stateAppend": {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    },
    "desiredConfig": "string",
    "desiredState": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "lastUpdated": "2019-07-28T03:26:00Z",
        "sessionName": "string"
      }
    ],
    "errorCount": 0,
    "retryPolicy": 0,
    "enabled": true,
    "configurationStatus": "unconfigured",
    "tags": {
      "property1": "string",
      "property2": "string"
    }
  }
]
```

<h3 id="get_components-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component states|[V2ComponentStateArray](#schemav2componentstatearray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## put_components

<a id="opIdput_components"></a>

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/cfs/v2/components HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/cfs/v2/components \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('https://api-gw-service-nmn.local/apis/cfs/v2/components', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/cfs/v2/components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /v2/components`

*Add or Replace a collection of components*

Update the state for a collection of components in the cfs database

> Body parameter

```json
{
  "patch": {
    "id": "string",
    "state": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "sessionName": "string"
      }
    ],
    "stateAppend": {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "sessionName": "string"
    },
    "desiredConfig": "string",
    "errorCount": 0,
    "retryPolicy": 0,
    "enabled": true,
    "tags": {
      "property1": "string",
      "property2": "string"
    }
  },
  "filters": {
    "ids": "string",
    "status": "unconfigured",
    "enabled": true,
    "configName": "string",
    "tags": "string"
  }
}
```

<h3 id="put_components-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|any|true|The configuration/state for an array of components|

> Example responses

> 200 Response

```json
[
  {
    "id": "string",
    "state": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "lastUpdated": "2019-07-28T03:26:00Z",
        "sessionName": "string"
      }
    ],
    "stateAppend": {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    },
    "desiredConfig": "string",
    "desiredState": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "lastUpdated": "2019-07-28T03:26:00Z",
        "sessionName": "string"
      }
    ],
    "errorCount": 0,
    "retryPolicy": 0,
    "enabled": true,
    "configurationStatus": "unconfigured",
    "tags": {
      "property1": "string",
      "property2": "string"
    }
  }
]
```

<h3 id="put_components-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component states|[V2ComponentStateArray](#schemav2componentstatearray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_components

<a id="opIdpatch_components"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v2/components HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v2/components \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v2/components', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v2/components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v2/components`

*Update a collection of components*

Update the state for a collection of components in the cfs database

> Body parameter

```json
{
  "patch": {
    "id": "string",
    "state": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "sessionName": "string"
      }
    ],
    "stateAppend": {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "sessionName": "string"
    },
    "desiredConfig": "string",
    "errorCount": 0,
    "retryPolicy": 0,
    "enabled": true,
    "tags": {
      "property1": "string",
      "property2": "string"
    }
  },
  "filters": {
    "ids": "string",
    "status": "unconfigured",
    "enabled": true,
    "configName": "string",
    "tags": "string"
  }
}
```

<h3 id="patch_components-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|any|true|The configuration/state for an array of components|

> Example responses

> 200 Response

```json
[
  {
    "id": "string",
    "state": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "lastUpdated": "2019-07-28T03:26:00Z",
        "sessionName": "string"
      }
    ],
    "stateAppend": {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    },
    "desiredConfig": "string",
    "desiredState": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "lastUpdated": "2019-07-28T03:26:00Z",
        "sessionName": "string"
      }
    ],
    "errorCount": 0,
    "retryPolicy": 0,
    "enabled": true,
    "configurationStatus": "unconfigured",
    "tags": {
      "property1": "string",
      "property2": "string"
    }
  }
]
```

<h3 id="patch_components-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component states|[V2ComponentStateArray](#schemav2componentstatearray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_component

<a id="opIdget_component"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/components/{component_id}`

*Retrieve the state of a single component*

Retrieve the configuration and current state of a single component

<h3 id="get_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|configDetails|query|boolean|false|Include the configuration and config status in the response|
|component_id|path|string|true|Component id. e.g. xname for hardware components|

> Example responses

> 200 Response

```json
{
  "id": "string",
  "state": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    }
  ],
  "stateAppend": {
    "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
    "playbook": "site.yml",
    "commit": "string",
    "lastUpdated": "2019-07-28T03:26:00Z",
    "sessionName": "string"
  },
  "desiredConfig": "string",
  "desiredState": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    }
  ],
  "errorCount": 0,
  "retryPolicy": 0,
  "enabled": true,
  "configurationStatus": "unconfigured",
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="get_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V2ComponentState](#schemav2componentstate)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## put_component

<a id="opIdput_component"></a>

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /v2/components/{component_id}`

*Add or Replace a single component*

Update the state for a given component in the cfs database

> Body parameter

```json
{
  "id": "string",
  "state": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "sessionName": "string"
    }
  ],
  "stateAppend": {
    "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
    "playbook": "site.yml",
    "commit": "string",
    "sessionName": "string"
  },
  "desiredConfig": "string",
  "errorCount": 0,
  "retryPolicy": 0,
  "enabled": true,
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="put_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2ComponentState](#schemav2componentstate)|true|The configuration/state for a single component|
|component_id|path|string|true|Component id. e.g. xname for hardware components|

> Example responses

> 200 Response

```json
{
  "id": "string",
  "state": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    }
  ],
  "stateAppend": {
    "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
    "playbook": "site.yml",
    "commit": "string",
    "lastUpdated": "2019-07-28T03:26:00Z",
    "sessionName": "string"
  },
  "desiredConfig": "string",
  "desiredState": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    }
  ],
  "errorCount": 0,
  "retryPolicy": 0,
  "enabled": true,
  "configurationStatus": "unconfigured",
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="put_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V2ComponentState](#schemav2componentstate)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_component

<a id="opIdpatch_component"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v2/components/{component_id}`

*Update a single component*

Update the state for a given component in the cfs database

> Body parameter

```json
{
  "id": "string",
  "state": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "sessionName": "string"
    }
  ],
  "stateAppend": {
    "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
    "playbook": "site.yml",
    "commit": "string",
    "sessionName": "string"
  },
  "desiredConfig": "string",
  "errorCount": 0,
  "retryPolicy": 0,
  "enabled": true,
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="patch_component-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2ComponentState](#schemav2componentstate)|true|The configuration/state for a single component|
|component_id|path|string|true|Component id. e.g. xname for hardware components|

> Example responses

> 200 Response

```json
{
  "id": "string",
  "state": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    }
  ],
  "stateAppend": {
    "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
    "playbook": "site.yml",
    "commit": "string",
    "lastUpdated": "2019-07-28T03:26:00Z",
    "sessionName": "string"
  },
  "desiredConfig": "string",
  "desiredState": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    }
  ],
  "errorCount": 0,
  "retryPolicy": 0,
  "enabled": true,
  "configurationStatus": "unconfigured",
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="patch_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V2ComponentState](#schemav2componentstate)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_component

<a id="opIddelete_component"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v2/components/{component_id}`

*Delete a single component*

Delete the given component

<h3 id="delete_component-parameters">Parameters</h3>

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

<h3 id="delete_component-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="configuration-framework-service-configurations">configurations</h1>

## get_configurations

<a id="opIdget_configurations"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/configurations HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/configurations \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v2/configurations', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v2/configurations", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/configurations`

*Retrieve a collection of configurations*

Retrieve the full collection of configurations in the form of a ConfigurationArray.

<h3 id="get_configurations-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|in_use|query|boolean|false|Query for only configurations that are currently referenced by components.|

> Example responses

> 200 Response

```json
[
  {
    "name": "sample-config",
    "description": "string",
    "lastUpdated": "2019-07-28T03:26:00Z",
    "layers": [
      {
        "name": "sample-config",
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "branch": "string"
      }
    ],
    "additional_inventory": {
      "name": "sample-inventory",
      "cloneUrl": "https://vcs.domain/vcs/org/inventory.git",
      "commit": "string",
      "branch": "string"
    }
  }
]
```

<h3 id="get_configurations-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of configurations|[ConfigurationArray](#schemaconfigurationarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_configuration

<a id="opIdget_configuration"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v2/configurations/{configuration_id}`

*Retrieve a single configuration*

Retrieve the given configuration

<h3 id="get_configuration-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|configuration_id|path|string|true|Name of the target configuration|

> Example responses

> 200 Response

```json
{
  "name": "sample-config",
  "description": "string",
  "lastUpdated": "2019-07-28T03:26:00Z",
  "layers": [
    {
      "name": "sample-config",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "branch": "string"
    }
  ],
  "additional_inventory": {
    "name": "sample-inventory",
    "cloneUrl": "https://vcs.domain/vcs/org/inventory.git",
    "commit": "string",
    "branch": "string"
  }
}
```

<h3 id="get_configuration-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration|[Configuration](#schemaconfiguration)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## put_configuration

<a id="opIdput_configuration"></a>

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /v2/configurations/{configuration_id}`

*Add or Replace a single configuration*

Add a configuration to CFS or replace an existing configuration.

> Body parameter

```json
{
  "description": "string",
  "layers": [
    {
      "name": "sample-config",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "branch": "string"
    }
  ],
  "additional_inventory": {
    "name": "sample-inventory",
    "cloneUrl": "https://vcs.domain/vcs/org/inventory.git",
    "commit": "string",
    "branch": "string"
  }
}
```

<h3 id="put_configuration-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[Configuration](#schemaconfiguration)|true|A desired configuration state|
|configuration_id|path|string|true|Name of the target configuration|

> Example responses

> 200 Response

```json
{
  "name": "sample-config",
  "description": "string",
  "lastUpdated": "2019-07-28T03:26:00Z",
  "layers": [
    {
      "name": "sample-config",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "branch": "string"
    }
  ],
  "additional_inventory": {
    "name": "sample-inventory",
    "cloneUrl": "https://vcs.domain/vcs/org/inventory.git",
    "commit": "string",
    "branch": "string"
  }
}
```

<h3 id="put_configuration-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration|[Configuration](#schemaconfiguration)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_configuration

<a id="opIdpatch_configuration"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v2/configurations/{configuration_id}`

*Update the commits for a configuration*

Updates the commits for all layers that specify a branch

<h3 id="patch_configuration-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|configuration_id|path|string|true|Name of the target configuration|

> Example responses

> 200 Response

```json
{
  "name": "sample-config",
  "description": "string",
  "lastUpdated": "2019-07-28T03:26:00Z",
  "layers": [
    {
      "name": "sample-config",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "branch": "string"
    }
  ],
  "additional_inventory": {
    "name": "sample-inventory",
    "cloneUrl": "https://vcs.domain/vcs/org/inventory.git",
    "commit": "string",
    "branch": "string"
  }
}
```

<h3 id="patch_configuration-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration|[Configuration](#schemaconfiguration)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_configuration

<a id="opIddelete_configuration"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} \
  -H 'Accept: application/problem+json'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v2/configurations/{configuration_id}`

*Delete a single configuration*

Delete the given configuration. This will fail in any components are using the specified configuration.

<h3 id="delete_configuration-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|configuration_id|path|string|true|Name of the target configuration|

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

<h3 id="delete_configuration-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_Link">Link</h2>
<!-- backwards compatibility -->
<a id="schemalink"></a>
<a id="schema_Link"></a>
<a id="tocSlink"></a>
<a id="tocslink"></a>

```json
{
  "rel": "/sessions/session-20190728032600",
  "href": "string"
}

```

Link to other resources

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|rel|string|false|none|none|
|href|string|false|none|none|

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
  "patch": 0
}

```

Version data

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|major|integer|false|none|none|
|minor|integer|false|none|none|
|patch|integer|false|none|none|

<h2 id="tocS_Healthz">Healthz</h2>
<!-- backwards compatibility -->
<a id="schemahealthz"></a>
<a id="schema_Healthz"></a>
<a id="tocShealthz"></a>
<a id="tocshealthz"></a>

```json
{
  "dbStatus": "string",
  "kafkaStatus": "string"
}

```

Service health status

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|dbStatus|string|false|none|none|
|kafkaStatus|string|false|none|none|

<h2 id="tocS_V2Options">V2Options</h2>
<!-- backwards compatibility -->
<a id="schemav2options"></a>
<a id="schema_V2Options"></a>
<a id="tocSv2options"></a>
<a id="tocsv2options"></a>

```json
{
  "hardwareSyncInterval": 5,
  "batcherCheckInterval": 5,
  "batchSize": 120,
  "batchWindow": 120,
  "defaultBatcherRetryPolicy": 1,
  "defaultPlaybook": "site.yml",
  "defaultAnsibleConfig": "cfs-default-ansible-cfg",
  "sessionTTL": "24h",
  "additionalInventoryUrl": "https://api-gw-service-nmn.local/vcs/cray/inventory.git",
  "batcherMaxBackoff": 3600,
  "batcherDisable": true,
  "batcherPendingTimeout": 0,
  "loggingLevel": "string"
}

```

Configuration options for the configuration service.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|hardwareSyncInterval|integer|false|none|How frequently the CFS hardware-sync-agent checks with the Hardware State Manager to update its known hardware (in seconds)|
|batcherCheckInterval|integer|false|none|How frequently the batcher checks the configuration states to see if work needs to be done (in seconds)|
|batchSize|integer|false|none|The maximum number of nodes the batcher will run a single CFS session against.|
|batchWindow|integer|false|none|The maximum number of seconds the batcher will wait to run a CFS session once a node has been detected that needs configuration.|
|defaultBatcherRetryPolicy|integer|false|none|The default maximum number retries per node when configuration fails.|
|defaultPlaybook|string|false|none|The default playbook to be used if not specified in a node's desired state.|
|defaultAnsibleConfig|string|false|none|The Kubernetes ConfigMap which holds the default ansible.cfg for a given CFS session. This ConfigMap must be present in the same Kubernetes namespace as the CFS service.|
|sessionTTL|string|false|none|A time-to-live applied to all completed CFS sessions.  Specified in hours or days. e.g. 3d or 24h.  Set to an empty string to disable.|
|additionalInventoryUrl|string|false|none|The git clone URL of a repo with additional inventory files.  All files in the repo will be copied into the hosts directory of CFS.|
|batcherMaxBackoff|integer|false|none|The maximum number of seconds that batcher will backoff from session creation if problems are detected.|
|batcherDisable|boolean|false|none|Disables cfs-batcher's automatic session creation if set to True.|
|batcherPendingTimeout|integer|false|none|How long cfs-batcher will wait on a pending session before deleting and recreating it (in seconds).|
|loggingLevel|string|false|none|The logging level for core CFS services.  This does not affect the Ansible logging level.|

<h2 id="tocS_TargetSpecSection">TargetSpecSection</h2>
<!-- backwards compatibility -->
<a id="schematargetspecsection"></a>
<a id="schema_TargetSpecSection"></a>
<a id="tocStargetspecsection"></a>
<a id="tocstargetspecsection"></a>

```json
{
  "definition": "spec",
  "groups": [
    {
      "name": "test-computes",
      "members": [
        "nid000001",
        "nid000002",
        "nid000003"
      ]
    }
  ],
  "image_map": [
    {
      "source_id": "ff287206-6ff7-4659-92ad-6e732821c6b4",
      "result_name": "new-test-image"
    }
  ]
}

```

A target lets you define the nodes or images that you want to customize and consists of two sub-parameters - Definition and groups. By default, Configuration Framework Sessions use dynamic inventory definition to target hosts. When using a session to customize an image, or if a static inventory is required, use this optional section to specify entities (whether images or nodes) for the session to target.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|definition|string|false|none|Source of inventory definition to be used in the configuration session.<br><br>'image' denotes that the session will target an image root through the Image<br>Management Service (IMS). Group members should be a single image identifier known by IMS.<br><br>'spec' denotes inventory that is specified directly via CFS in the target<br>groups/members of this object. You can include a node name (a DNS resolvable name),<br>or a group name and a list of nodes. The command line inventory can be a quick<br>and simple way to run Ansible against a small subset of nodes. However, if more<br>customization of the inventory is needed, specifically customization of host and<br>groups variables, the repo target definition should be used.<br><br>'repo' denotes the inventory will be used from the git repository<br>specified for this session (via `cloneUrl`, and `branch` or `commit`). The inventory<br>must be located in the "hosts" file at the root of the repository.<br><br>'dynamic' (default) will use the CFS-provided dynamic inventory plugin to define<br>the inventory. The hosts file is automatically generated by CFS with data from<br>the Hardware State Manager (HSM), which includes groups and hardware roles.|
|groups|[object]|false|none|Specification of the groups and group members per the inventory definition. This list is not valid for the 'repo' and 'dynamic' inventory definition types. Multiple groups can be specified for 'image' and 'spec' inventory definition types.|
|» name|string|true|none|Group name|
|» members|[string]|true|none|Group members for the inventory.|
|image_map|[object]|false|none|Mapping of image IDs to resultant image names.  This is only valid for 'image' inventory definition types.<br>Only images that are defined in 'groups' will result in a new image.<br>If images in 'groups' are not specified here, CFS will generate a name for the resultant image.|
|» source_id|string|true|none|Source image id.  This is the image id that is used in 'groups'.|
|» result_name|string|true|none|Resultant image name.|

#### Enumerated Values

|Property|Value|
|---|---|
|definition|image|
|definition|spec|
|definition|repo|
|definition|dynamic|

<h2 id="tocS_V2Session">V2Session</h2>
<!-- backwards compatibility -->
<a id="schemav2session"></a>
<a id="schema_V2Session"></a>
<a id="tocSv2session"></a>
<a id="tocsv2session"></a>

```json
{
  "name": "session-20190728032600",
  "configuration": {
    "name": "example-config",
    "limit": "layer1,layer3"
  },
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": "host1",
    "verbosity": 0,
    "passthrough": "string"
  },
  "target": {
    "definition": "spec",
    "groups": [
      {
        "name": "test-computes",
        "members": [
          "nid000001",
          "nid000002",
          "nid000003"
        ]
      }
    ],
    "image_map": [
      {
        "source_id": "ff287206-6ff7-4659-92ad-6e732821c6b4",
        "result_name": "new-test-image"
      }
    ]
  },
  "status": {
    "artifacts": [
      {
        "image_id": "f34ff35e-d782-4a65-a1b8-243a3cd740af",
        "result_id": "8b782ccd-8706-4145-a6a1-724e29ed5522",
        "type": "ims_customized_image"
      }
    ],
    "session": {
      "job": "cray-cfs-job-session-20190728032600",
      "completionTime": "2019-07-28T03:26:00Z",
      "startTime": "2019-07-28T03:26:00Z",
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}

```

An execution session for the Configuration Framework.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|Name of the session. The length of the name is restricted to 45 characters.|
|configuration|object|false|none|The configuration information which the session will apply|
|» name|string|false|none|The name of the CFS configuration to be applied|
|» limit|string|false|none|A comma seperated list of layers in the configuration to limit the session to. This can be either a list of named layers, or a list of indices.|
|ansible|object|false|none|Additional options that will be used when invoking Ansible.|
|» config|string|false|none|The Kubernetes ConfigMap which holds the ansible.cfg for a given CFS session. This ConfigMap must be present in the same Kubernetes namespace as the CFS service. If no value is given, the value of the defaultAnsibleConfig field in the /options endpoint will be used.|
|» limit|string|false|none|Additional filtering of hosts or groups from the inventory to run against. This is especially useful when running with dynamic inventory and when you want to run on a subset of nodes or groups. This option corresponds to ansible-playbook's --limit and can be used to specify nodes or groups.|
|» verbosity|integer|false|none|The verbose mode to use in the call to the ansible-playbook command. 1 = -v, 2 = -vv, etc. Valid values range from 0 to 4. See the ansible-playbook help for more information.|
|» passthrough|string|false|none|Additional parameters that are added to all Ansible calls for the session. This field is currently limited to the following Ansible parameters: "--extra-vars", "--forks", "--skip-tags", "--start-at-task", and "--tags". WARNING: Parameters passed to Ansible in this way should be used with caution.  State will not be recorded for components when using these flags to avoid incorrect reporting of partial playbook runs.|
|target|[TargetSpecSection](#schematargetspecsection)|false|none|A target lets you define the nodes or images that you want to customize and consists of two sub-parameters - Definition and groups. By default, Configuration Framework Sessions use dynamic inventory definition to target hosts. When using a session to customize an image, or if a static inventory is required, use this optional section to specify entities (whether images or nodes) for the session to target.|
|status|object|false|none|Status of artifacts, session, and targets. Lists details like session status, session start and completion time, number of successful, failed, or running targets. If the target definition is an image, it also lists the image_id, result_id, and type of image under Artifacts.|
|» artifacts|[object]|false|none|none|
|»» image_id|string(uuid)|false|none|The IMS id of the original image to be customized via a configuration session.|
|»» result_id|string(uuid)|false|none|The IMS id of the image that was customized via a configuration session. This is the resultant image of the customization.|
|»» type|string|false|none|none|
|» session|object|false|none|none|
|»» job|string|false|read-only|The name of the configuration execution environment associated with this session.|
|»» completionTime|string(date-time)|false|read-only|The date/time when the session completed execution in RFC 3339 format.|
|»» startTime|string(date-time)|false|read-only|The date/time when the session started execution in RFC 3339 format.|
|»» status|string|false|read-only|The execution status of the session.|
|»» succeeded|string|false|read-only|Whether the session executed successfully or not. A 'none'<br>value denotes that the execution has not completed. This<br>field has context when the `status` field is 'complete'.<br>A session may successfully execute even if the underlying<br>tasks do not.|
|tags|object|false|none|A collection of key-value pairs containing descriptive information for the session, such as information about the session creator.|
|» **additionalProperties**|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|type|ims_customized_image|
|status|pending|
|status|running|
|status|complete|
|succeeded|none|
|succeeded|true|
|succeeded|false|
|succeeded|unknown|

<h2 id="tocS_V2SessionCreate">V2SessionCreate</h2>
<!-- backwards compatibility -->
<a id="schemav2sessioncreate"></a>
<a id="schema_V2SessionCreate"></a>
<a id="tocSv2sessioncreate"></a>
<a id="tocsv2sessioncreate"></a>

```json
{
  "name": "session-20190728032600",
  "configurationName": "example-config",
  "configurationLimit": "layer1,layer3",
  "ansibleLimit": "host1",
  "ansibleConfig": "cfs-default-ansible-cfg",
  "ansibleVerbosity": 0,
  "ansiblePassthrough": "string",
  "target": {
    "definition": "spec",
    "groups": [
      {
        "name": "test-computes",
        "members": [
          "nid000001",
          "nid000002",
          "nid000003"
        ]
      }
    ],
    "image_map": [
      {
        "source_id": "ff287206-6ff7-4659-92ad-6e732821c6b4",
        "result_name": "new-test-image"
      }
    ]
  },
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}

```

The information required to create a Config Framework Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|true|none|Name of the session. The length of the name is restricted to 45 characters.|
|configurationName|string|true|none|The name of a CFS configuration to apply|
|configurationLimit|string|false|none|A comma seperated list of layers in the configuration to limit the session to. This can be either a list of named layers, or a list of indices.|
|ansibleLimit|string|false|none|Additional filtering of hosts or groups from the inventory to run against. This is especially useful when running with dynamic inventory and when you want to run on a subset of nodes or groups. This option corresponds to ansible-playbook's --limit and can be used to specify nodes or groups.|
|ansibleConfig|string|false|none|The Kubernetes ConfigMap which holds the ansible.cfg for a given CFS session. This ConfigMap must be present in the same Kubernetes namespace as the CFS service. If no value is given, the value of the defaultAnsibleConfig field in the /options endpoint will be used.|
|ansibleVerbosity|integer|false|none|The verbose mode to use in the call to the ansible-playbook command. 1 = -v, 2 = -vv, etc. Valid values range from 0 to 4. See the ansible-playbook help for more information.|
|ansiblePassthrough|string|false|none|Additional parameters that are added to all Ansible calls for the session. This field is currently limited to the following Ansible parameters: "--extra-vars", "--forks", "--skip-tags", "--start-at-task", and "--tags". WARNING: Parameters passed to Ansible in this way should be used with caution.  State will not be recorded for components when using these flags to avoid incorrect reporting of partial playbook runs.|
|target|[TargetSpecSection](#schematargetspecsection)|false|none|A target lets you define the nodes or images that you want to customize and consists of two sub-parameters - Definition and groups. By default, Configuration Framework Sessions use dynamic inventory definition to target hosts. When using a session to customize an image, or if a static inventory is required, use this optional section to specify entities (whether images or nodes) for the session to target.|
|tags|object|false|none|A collection of key-value pairs containing descriptive information for the session, such as information about the session creator.|
|» **additionalProperties**|string|false|none|none|

<h2 id="tocS_AdditionalInventoryLayer">AdditionalInventoryLayer</h2>
<!-- backwards compatibility -->
<a id="schemaadditionalinventorylayer"></a>
<a id="schema_AdditionalInventoryLayer"></a>
<a id="tocSadditionalinventorylayer"></a>
<a id="tocsadditionalinventorylayer"></a>

```json
{
  "name": "sample-inventory",
  "cloneUrl": "https://vcs.domain/vcs/org/inventory.git",
  "commit": "string",
  "branch": "string"
}

```

An inventory reference to include in a set of configurations.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|The name of the inventory layer.|
|cloneUrl|string|true|none|The clone URL of the configuration content repository.|
|commit|string|false|none|The commit hash of the configuration repository when the state is set.|
|branch|string|false|none|The repository branch to use. This will automatically set `commit` to master on the branch<br>when the configuration is added.|

<h2 id="tocS_ConfigurationLayer">ConfigurationLayer</h2>
<!-- backwards compatibility -->
<a id="schemaconfigurationlayer"></a>
<a id="schema_ConfigurationLayer"></a>
<a id="tocSconfigurationlayer"></a>
<a id="tocsconfigurationlayer"></a>

```json
{
  "name": "sample-config",
  "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
  "playbook": "site.yml",
  "commit": "string",
  "branch": "string"
}

```

A single desired configuration state for a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|The name of the configuration layer.|
|cloneUrl|string|true|none|The clone URL of the configuration content repository.|
|playbook|string|false|none|The Ansible playbook to run.|
|commit|string|false|none|The commit hash of the configuration repository when the state is set.|
|branch|string|false|none|The configuration branch to use.  This will automatically set commit to master on the branch<br>when the configuration is added.|

<h2 id="tocS_Configuration">Configuration</h2>
<!-- backwards compatibility -->
<a id="schemaconfiguration"></a>
<a id="schema_Configuration"></a>
<a id="tocSconfiguration"></a>
<a id="tocsconfiguration"></a>

```json
{
  "name": "sample-config",
  "description": "string",
  "lastUpdated": "2019-07-28T03:26:00Z",
  "layers": [
    {
      "name": "sample-config",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "branch": "string"
    }
  ],
  "additional_inventory": {
    "name": "sample-inventory",
    "cloneUrl": "https://vcs.domain/vcs/org/inventory.git",
    "commit": "string",
    "branch": "string"
  }
}

```

A collection of ConfigurationLayers.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|read-only|The name of the configuration.|
|description|string|false|none|A user-defined description. This field is not used by CFS.|
|lastUpdated|string(date-time)|false|read-only|The date/time when the state was last updated in RFC 3339 format.|
|layers|[[ConfigurationLayer](#schemaconfigurationlayer)]|false|none|A list of ConfigurationLayer(s).|
|additional_inventory|[AdditionalInventoryLayer](#schemaadditionalinventorylayer)|false|none|An inventory reference to include in a set of configurations.|

<h2 id="tocS_ConfigurationArray">ConfigurationArray</h2>
<!-- backwards compatibility -->
<a id="schemaconfigurationarray"></a>
<a id="schema_ConfigurationArray"></a>
<a id="tocSconfigurationarray"></a>
<a id="tocsconfigurationarray"></a>

```json
[
  {
    "name": "sample-config",
    "description": "string",
    "lastUpdated": "2019-07-28T03:26:00Z",
    "layers": [
      {
        "name": "sample-config",
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "branch": "string"
      }
    ],
    "additional_inventory": {
      "name": "sample-inventory",
      "cloneUrl": "https://vcs.domain/vcs/org/inventory.git",
      "commit": "string",
      "branch": "string"
    }
  }
]

```

An array of configurations.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Configuration](#schemaconfiguration)]|false|none|An array of configurations.|

<h2 id="tocS_ConfigurationStateLayer">ConfigurationStateLayer</h2>
<!-- backwards compatibility -->
<a id="schemaconfigurationstatelayer"></a>
<a id="schema_ConfigurationStateLayer"></a>
<a id="tocSconfigurationstatelayer"></a>
<a id="tocsconfigurationstatelayer"></a>

```json
{
  "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
  "playbook": "site.yml",
  "commit": "string",
  "lastUpdated": "2019-07-28T03:26:00Z",
  "sessionName": "string"
}

```

The current configuration state for a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|cloneUrl|string|false|none|The clone URL of the configuration content repository.|
|playbook|string|false|none|The Ansible playbook to run.|
|commit|string|false|none|The commit hash of the configuration repository when the state is set.|
|lastUpdated|string(date-time)|false|read-only|The date/time when the state was last updated in RFC 3339 format.|
|sessionName|string|false|none|The name of the CFS session that last configured the component.|

<h2 id="tocS_V2ComponentState">V2ComponentState</h2>
<!-- backwards compatibility -->
<a id="schemav2componentstate"></a>
<a id="schema_V2ComponentState"></a>
<a id="tocSv2componentstate"></a>
<a id="tocsv2componentstate"></a>

```json
{
  "id": "string",
  "state": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    }
  ],
  "stateAppend": {
    "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
    "playbook": "site.yml",
    "commit": "string",
    "lastUpdated": "2019-07-28T03:26:00Z",
    "sessionName": "string"
  },
  "desiredConfig": "string",
  "desiredState": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    }
  ],
  "errorCount": 0,
  "retryPolicy": 0,
  "enabled": true,
  "configurationStatus": "unconfigured",
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}

```

The configuration state and desired state for a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string|false|none|The component's id. e.g. xname for hardware components|
|state|[[ConfigurationStateLayer](#schemaconfigurationstatelayer)]|false|none|Information about the desired config and status of the layers|
|stateAppend|[ConfigurationStateLayer](#schemaconfigurationstatelayer)|false|none|A single state that will be appended to the list of current states.|
|desiredConfig|string|false|none|A reference to a configuration|
|desiredState|[[ConfigurationStateLayer](#schemaconfigurationstatelayer)]|false|read-only|Information about the desired config and status of the layers|
|errorCount|integer|false|none|The count of failed configuration attempts.|
|retryPolicy|integer|false|none|The maximum number retries per component when configuration fails.|
|enabled|boolean|false|none|A flag indicating if the component should be scheduled for configuration.|
|configurationStatus|string|false|read-only|A summary of the component's configuration state.|
|tags|object|false|none|A collection of key-value pairs containing descriptive information for the component, such as information about the component owner.|
|» **additionalProperties**|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|configurationStatus|unconfigured|
|configurationStatus|pending|
|configurationStatus|failed|
|configurationStatus|configured|

<h2 id="tocS_V2ComponentStateArray">V2ComponentStateArray</h2>
<!-- backwards compatibility -->
<a id="schemav2componentstatearray"></a>
<a id="schema_V2ComponentStateArray"></a>
<a id="tocSv2componentstatearray"></a>
<a id="tocsv2componentstatearray"></a>

```json
[
  {
    "id": "string",
    "state": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "lastUpdated": "2019-07-28T03:26:00Z",
        "sessionName": "string"
      }
    ],
    "stateAppend": {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    },
    "desiredConfig": "string",
    "desiredState": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "lastUpdated": "2019-07-28T03:26:00Z",
        "sessionName": "string"
      }
    ],
    "errorCount": 0,
    "retryPolicy": 0,
    "enabled": true,
    "configurationStatus": "unconfigured",
    "tags": {
      "property1": "string",
      "property2": "string"
    }
  }
]

```

An array of component configurations.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2ComponentState](#schemav2componentstate)]|false|none|An array of component configurations.|

<h2 id="tocS_V2ComponentsFilter">V2ComponentsFilter</h2>
<!-- backwards compatibility -->
<a id="schemav2componentsfilter"></a>
<a id="schema_V2ComponentsFilter"></a>
<a id="tocSv2componentsfilter"></a>
<a id="tocsv2componentsfilter"></a>

```json
{
  "ids": "string",
  "status": "unconfigured",
  "enabled": true,
  "configName": "string",
  "tags": "string"
}

```

Information for patching multiple components.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ids|string|false|none|A comma-separated list of component IDs|
|status|string|false|none|All components with this status will be patched.|
|enabled|boolean|false|none|Patches all components with the given "enabled" state.|
|configName|string|false|none|A configuration name.  All components with this configuration set will be patched.|
|tags|string|false|none|Patches all components with the given tags.  Key-value pairs should be separated using =, and tags can be a comma-separated list.  Only components that match all tags will be patched.|

#### Enumerated Values

|Property|Value|
|---|---|
|status|unconfigured|
|status|pending|
|status|failed|
|status|configured|

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
    "state": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "lastUpdated": "2019-07-28T03:26:00Z",
        "sessionName": "string"
      }
    ],
    "stateAppend": {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "lastUpdated": "2019-07-28T03:26:00Z",
      "sessionName": "string"
    },
    "desiredConfig": "string",
    "desiredState": [
      {
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "lastUpdated": "2019-07-28T03:26:00Z",
        "sessionName": "string"
      }
    ],
    "errorCount": 0,
    "retryPolicy": 0,
    "enabled": true,
    "configurationStatus": "unconfigured",
    "tags": {
      "property1": "string",
      "property2": "string"
    }
  },
  "filters": {
    "ids": "string",
    "status": "unconfigured",
    "enabled": true,
    "configName": "string",
    "tags": "string"
  }
}

```

Information for patching multiple components.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|patch|[V2ComponentState](#schemav2componentstate)|true|none|The configuration state and desired state for a component.|
|filters|[V2ComponentsFilter](#schemav2componentsfilter)|true|none|Information for patching multiple components.|

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

