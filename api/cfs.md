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

/configurations - Add, update, retrieve or delete desired configuration states.

/sources - Add, update, retrieve, or delete playbook source information. (v3 api only)
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

# Authentication

- HTTP Authentication, scheme: bearer 

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
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

*Get CFS service version*

Return the CFS service version that is currently running.

> Example responses

> 200 Response

```json
{
  "major": "1",
  "minor": "0",
  "patch": "10"
}
```

<h3 id="get_version-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Version information for the service|[Version](#schemaversion)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

*Get CFS service version*

Return the CFS service version that is currently running.

> Example responses

> 200 Response

```json
{
  "major": "1",
  "minor": "0",
  "patch": "10"
}
```

<h3 id="get_versions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Version information for the service|[Version](#schemaversion)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

*Get CFS service version*

Return the CFS service version that is currently running.

> Example responses

> 200 Response

```json
{
  "major": "1",
  "minor": "0",
  "patch": "10"
}
```

<h3 id="get_versions_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Version information for the service|[Version](#schemaversion)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_versions_v3

<a id="opIdget_versions_v3"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v3 HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v3 \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v3', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v3", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3`

*Get CFS service version*

Return the CFS service version that is currently running.

> Example responses

> 200 Response

```json
{
  "major": "1",
  "minor": "0",
  "patch": "10"
}
```

<h3 id="get_versions_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Version information for the service|[Version](#schemaversion)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
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
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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
  "db_status": "string",
  "kafka_status": "string"
}
```

<h3 id="get_healthz-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Status information for the service|[Healthz](#schemahealthz)|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|Status information for the service|[Healthz](#schemahealthz)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

<h1 id="configuration-framework-service-options">options</h1>

## get_options_v2

<a id="opIdget_options_v2"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/options HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/options \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="get_options_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of service-wide configuration options|[V2Options](#schemav2options)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_options_v2

<a id="opIdpatch_options_v2"></a>

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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="patch_options_v2-parameters">Parameters</h3>

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

<h3 id="patch_options_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of service-wide configuration options|[V2Options](#schemav2options)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_options_v3

<a id="opIdget_options_v3"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v3/options HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v3/options \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v3/options', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v3/options", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/options`

*Retrieve the configuration service options*

Retrieve the list of configuration service options.

> Example responses

> 200 Response

```json
{
  "hardware_sync_interval": 5,
  "batcher_check_interval": 5,
  "batch_size": 120,
  "batch_window": 120,
  "default_batcher_retry_policy": 1,
  "default_playbook": "site.yml",
  "default_ansible_config": "cfs-default-ansible-cfg",
  "session_ttl": "24h",
  "additional_inventory_url": "https://api-gw-service-nmn.local/vcs/cray/inventory.git",
  "additional_inventory_source": "example-source",
  "batcher_max_backoff": 3600,
  "batcher_disable": true,
  "batcher_pending_timeout": 1,
  "logging_level": "DEBUG",
  "default_page_size": 1,
  "debug_wait_time": 0,
  "include_ara_links": true
}
```

<h3 id="get_options_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of service-wide configuration options|[V3Options](#schemav3options)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_options_v3

<a id="opIdpatch_options_v3"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v3/options HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v3/options \
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

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v3/options', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v3/options", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/options`

*Update configuration service options*

Update one or more of the configuration service options.

> Body parameter

```json
{
  "hardware_sync_interval": 5,
  "batcher_check_interval": 5,
  "batch_size": 120,
  "batch_window": 120,
  "default_batcher_retry_policy": 1,
  "default_ansible_config": "cfs-default-ansible-cfg",
  "session_ttl": "24h",
  "additional_inventory_url": "https://api-gw-service-nmn.local/vcs/cray/inventory.git",
  "additional_inventory_source": "example-source",
  "batcher_max_backoff": 3600,
  "batcher_disable": true,
  "batcher_pending_timeout": 1,
  "logging_level": "DEBUG",
  "default_page_size": 1,
  "debug_wait_time": 0,
  "include_ara_links": true
}
```

<h3 id="patch_options_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V3Options](#schemav3options)|true|Service-wide configuration options|

> Example responses

> 200 Response

```json
{
  "hardware_sync_interval": 5,
  "batcher_check_interval": 5,
  "batch_size": 120,
  "batch_window": 120,
  "default_batcher_retry_policy": 1,
  "default_playbook": "site.yml",
  "default_ansible_config": "cfs-default-ansible-cfg",
  "session_ttl": "24h",
  "additional_inventory_url": "https://api-gw-service-nmn.local/vcs/cray/inventory.git",
  "additional_inventory_source": "example-source",
  "batcher_max_backoff": 3600,
  "batcher_disable": true,
  "batcher_pending_timeout": 1,
  "logging_level": "DEBUG",
  "default_page_size": 1,
  "debug_wait_time": 0,
  "include_ara_links": true
}
```

<h3 id="patch_options_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of service-wide configuration options|[V3Options](#schemav3options)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

<h1 id="configuration-framework-service-sessions">sessions</h1>

## get_sessions_v2

<a id="opIdget_sessions_v2"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/sessions \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="get_sessions_v2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|age|query|string|false|Return only sessions older than the given age. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h. DEPRECATED: This field has been replaced by min_age and max_age|
|min_age|query|string|false|Return only sessions older than the given age. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h.|
|max_age|query|string|false|Return only sessions younger than the given age. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h.|
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

<h3 id="get_sessions_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of configuration sessions|[V2SessionArray](#schemav2sessionarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## create_session_v2

<a id="opIdcreate_session_v2"></a>

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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="create_session_v2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2SessionCreate](#schemav2sessioncreate)|true|A JSON object for creating Config Framework Sessions|

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

<h3 id="create_session_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration session|[V2Session](#schemav2session)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|A session with the same name already exists.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## delete_sessions_v2

<a id="opIddelete_sessions_v2"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v2/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v2/sessions \
  -H 'Accept: application/problem+json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="delete_sessions_v2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|age|query|string|false|Deletes only sessions older than the given age. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h. DEPRECATED: This field has been replaced by min_age and max_age|
|min_age|query|string|false|Deletes only sessions older than the given age. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h.|
|max_age|query|string|false|Deletes only sessions younger than the given age. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h.|
|status|query|string|false|Deletes only sessions with the given status.|
|name_contains|query|string|false|Delete only sessions whose session name contains the given string.|
|succeeded|query|string|false|Delete only sessions that have succeeded/failed.|
|tags|query|string|false|Deletes only sessions whose have the matching tags.  Key-value pairs should be separated using =, and tags can be a comma-separated list. Only sessions that match all tags will be deleted.|

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

<h3 id="delete_sessions_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_session_v2

<a id="opIdget_session_v2"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="get_session_v2-parameters">Parameters</h3>

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

<h3 id="get_session_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration session|[V2Session](#schemav2session)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_session_v2

<a id="opIdpatch_session_v2"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="patch_session_v2-parameters">Parameters</h3>

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

<h3 id="patch_session_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration session|[V2Session](#schemav2session)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## delete_session_v2

<a id="opIddelete_session_v2"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v2/sessions/{session_name} \
  -H 'Accept: application/problem+json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="delete_session_v2-parameters">Parameters</h3>

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

<h3 id="delete_session_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_sessions_v3

<a id="opIdget_sessions_v3"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v3/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v3/sessions \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v3/sessions', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v3/sessions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/sessions`

*Retrieve configuration framework sessions*

Retrieve all the configuration framework sessions on the system.

<h3 id="get_sessions_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|limit|query|integer|false|When set, CFS will only return a number of sessions up to this limit.  Combined with after_id, this enables paging across results|
|after_id|query|string|false|When set, CFS will only return the sessions after the session specified.  Combined with limit, this enables paging across results.|
|min_age|query|string|false|Return only sessions older than the given age. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h.|
|max_age|query|string|false|Return only sessions younger than the given age. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h.|
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
|status||
|succeeded|none|
|succeeded|true|
|succeeded|false|
|succeeded|unknown|
|succeeded||

> Example responses

> 200 Response

```json
{
  "sessions": [
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
          "ims_job": "5037edd8-e9c5-437d-b54b-db4a8ad2cb15",
          "completion_time": "2019-07-28T03:26:00Z",
          "start_time": "2019-07-28T03:26:00Z",
          "status": "pending",
          "succeeded": "none"
        }
      },
      "tags": {
        "property1": "string",
        "property2": "string"
      },
      "debug_on_failure": false,
      "logs": "string"
    }
  ],
  "next": {
    "limit": 0,
    "after_id": "string"
  }
}
```

<h3 id="get_sessions_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of configuration sessions|[V3SessionDataCollection](#schemav3sessiondatacollection)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## create_session_v3

<a id="opIdcreate_session_v3"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/cfs/v3/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/cfs/v3/sessions \
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

r = requests.post('https://api-gw-service-nmn.local/apis/cfs/v3/sessions', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/cfs/v3/sessions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v3/sessions`

*Create a configuration framework session*

Create a new configuration session. A configuration session stages Ansible inventory, launches one or more Ansible Execution Environments (AEE) as containers in the management services infrastructure, and tears down the environments as required. When a session is targeted for image customization, the inventory staging involves using IMS to expose the requested image roots, tearing down the image roots, and generating new boot artifacts afterwards. The session will checkout the prescribed branch or commit of the configuration repository and populate the configuration manifest to the AEE. The Ansible execution begins with an inventory prescribed by the user through CFS. A configuration session also tracks the status of the different stages of the operation and reports information on the success of its execution.

> Body parameter

```json
{
  "name": "session-20190728032600",
  "configuration_name": "example-config",
  "configuration_limit": "layer1,layer3",
  "ansible_limit": "host1",
  "ansible_config": "cfs-default-ansible-cfg",
  "ansible_verbosity": 0,
  "ansible_passthrough": "",
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
  },
  "debug_on_failure": false
}
```

<h3 id="create_session_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V3SessionCreate](#schemav3sessioncreate)|true|A JSON object for creating Config Framework Sessions|

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
      "ims_job": "5037edd8-e9c5-437d-b54b-db4a8ad2cb15",
      "completion_time": "2019-07-28T03:26:00Z",
      "start_time": "2019-07-28T03:26:00Z",
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {
    "property1": "string",
    "property2": "string"
  },
  "debug_on_failure": false,
  "logs": "string"
}
```

<h3 id="create_session_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|A single configuration session|[V3SessionData](#schemav3sessiondata)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|A session with the same name already exists.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## delete_sessions_v3

<a id="opIddelete_sessions_v3"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v3/sessions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v3/sessions \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/cfs/v3/sessions', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/cfs/v3/sessions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/sessions`

*Delete multiple configuration framework sessions*

Delete multiple configuration sessions.  If filters are provided, only sessions matching all filters will be deleted.  By default only completed sessions will be deleted.

<h3 id="delete_sessions_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|min_age|query|string|false|Deletes only sessions older than the given age. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h.|
|max_age|query|string|false|Deletes only sessions younger than the given age. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h.|
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
|status||
|succeeded|none|
|succeeded|true|
|succeeded|false|
|succeeded|unknown|
|succeeded||

> Example responses

> 200 Response

```json
{
  "session_ids": [
    "string"
  ]
}
```

<h3 id="delete_sessions_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of configuration session IDs|[V3SessionIdCollection](#schemav3sessionidcollection)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_session_v3

<a id="opIdget_session_v3"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/sessions/{session_name}`

*Retrieve a configuration framework session by session_name*

View details about a specific configuration session. This allows you to track the status of the session and the Ansible execution through the session.

<h3 id="get_session_v3-parameters">Parameters</h3>

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
      "ims_job": "5037edd8-e9c5-437d-b54b-db4a8ad2cb15",
      "completion_time": "2019-07-28T03:26:00Z",
      "start_time": "2019-07-28T03:26:00Z",
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {
    "property1": "string",
    "property2": "string"
  },
  "debug_on_failure": false,
  "logs": "string"
}
```

<h3 id="get_session_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration session|[V3SessionData](#schemav3sessiondata)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_session_v3

<a id="opIdpatch_session_v3"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/sessions/{session_name}`

*Update a configuration framework session*

Update the status of an existing configuration framework session

<h3 id="patch_session_v3-parameters">Parameters</h3>

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
      "ims_job": "5037edd8-e9c5-437d-b54b-db4a8ad2cb15",
      "completion_time": "2019-07-28T03:26:00Z",
      "start_time": "2019-07-28T03:26:00Z",
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {
    "property1": "string",
    "property2": "string"
  },
  "debug_on_failure": false,
  "logs": "string"
}
```

<h3 id="patch_session_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration session|[V3SessionData](#schemav3sessiondata)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## delete_session_v3

<a id="opIddelete_session_v3"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name} \
  -H 'Accept: application/problem+json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name}', headers = headers)

print(r.json())

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/cfs/v3/sessions/{session_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/sessions/{session_name}`

*Delete a configuration framework session*

Deleting a configuration session deletes the Kubernetes objects associated with the session and also deletes the session history. The operation cannot be undone.

<h3 id="delete_session_v3-parameters">Parameters</h3>

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

<h3 id="delete_session_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

<h1 id="configuration-framework-service-components">components</h1>

## get_components_v2

<a id="opIdget_components_v2"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/components HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/components \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="get_components_v2-parameters">Parameters</h3>

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

<h3 id="get_components_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component states|[V2ComponentStateArray](#schemav2componentstatearray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## put_components_v2

<a id="opIdput_components_v2"></a>

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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="put_components_v2-parameters">Parameters</h3>

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

<h3 id="put_components_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component states|[V2ComponentStateArray](#schemav2componentstatearray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_components_v2

<a id="opIdpatch_components_v2"></a>

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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="patch_components_v2-parameters">Parameters</h3>

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

<h3 id="patch_components_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component states|[V2ComponentStateArray](#schemav2componentstatearray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_component_v2

<a id="opIdget_component_v2"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="get_component_v2-parameters">Parameters</h3>

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

<h3 id="get_component_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V2ComponentState](#schemav2componentstate)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## put_component_v2

<a id="opIdput_component_v2"></a>

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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="put_component_v2-parameters">Parameters</h3>

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

<h3 id="put_component_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V2ComponentState](#schemav2componentstate)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_component_v2

<a id="opIdpatch_component_v2"></a>

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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="patch_component_v2-parameters">Parameters</h3>

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

<h3 id="patch_component_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V2ComponentState](#schemav2componentstate)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## delete_component_v2

<a id="opIddelete_component_v2"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v2/components/{component_id} \
  -H 'Accept: application/problem+json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="delete_component_v2-parameters">Parameters</h3>

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

<h3 id="delete_component_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_components_v3

<a id="opIdget_components_v3"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v3/components HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v3/components \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v3/components', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v3/components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/components`

*Retrieve the state of a collection of components*

Retrieve the full collection of components in the form of a ComponentArray. Full results can also be filtered by query parameters. Only the first filter parameter of each type is used and the parameters are applied in an AND fashion. If the collection is empty or the filters have no match, an empty array is returned.

<h3 id="get_components_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|limit|query|integer|false|When set, CFS will only return a number of components up to this limit.  Combined with after_id, this enables paging across results|
|after_id|query|string|false|When set, CFS will only return the components after the component specified.  Combined with limit, this enables paging across results.|
|ids|query|string|false|Retrieve the components with the given id (e.g. xname for hardware components). Can be chained for selecting groups of components.|
|status|query|string|false|Retrieve the components with the status. Multiple statuses can be specified in a comma-separated list.|
|enabled|query|boolean|false|Retrieve the components with the "enabled" state.|
|config_name|query|string|false|Retrieve the components with the given configuration set as the desired state.|
|state_details|query|boolean|false|Include the details on the currently applied layers|
|config_details|query|boolean|false|Include the configuration and config status in the response|
|tags|query|string|false|Return only components whose have the matching tags.  Key-value pairs should be separated using =, and tags can be a comma-separated list.  Only components that match all tags will be returned.|

#### Enumerated Values

|Parameter|Value|
|---|---|
|status|unconfigured|
|status|failed|
|status|pending|
|status|configured|
|status||

> Example responses

> 200 Response

```json
{
  "components": [
    {
      "id": "string",
      "state": [
        {
          "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
          "playbook": "site.yml",
          "commit": "string",
          "status": "applied",
          "last_updated": "2019-07-28T03:26:00Z",
          "session_name": "string"
        }
      ],
      "desired_state": [
        {
          "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
          "playbook": "site.yml",
          "commit": "string",
          "status": "applied",
          "last_updated": "2019-07-28T03:26:00Z",
          "session_name": "string"
        }
      ],
      "desired_config": "string",
      "error_count": 0,
      "retry_policy": 0,
      "enabled": true,
      "configuration_status": "unconfigured",
      "tags": {
        "property1": "string",
        "property2": "string"
      },
      "logs": "string"
    }
  ],
  "next": {
    "limit": 0,
    "after_id": "string"
  }
}
```

<h3 id="get_components_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component states|[V3ComponentDataCollection](#schemav3componentdatacollection)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## put_components_v3

<a id="opIdput_components_v3"></a>

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/cfs/v3/components HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/cfs/v3/components \
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

r = requests.put('https://api-gw-service-nmn.local/apis/cfs/v3/components', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/cfs/v3/components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /v3/components`

*Add or Replace a collection of components*

Update the state for a collection of components in the cfs database

> Body parameter

```json
{
  "patch": {
    "id": "string",
    "state": [
      {
        "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "status": "applied",
        "session_name": "string"
      }
    ],
    "state_append": {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "session_name": "string"
    },
    "desired_config": "string",
    "error_count": 0,
    "retry_policy": 0,
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
    "config_name": "string",
    "tags": "string"
  }
}
```

<h3 id="put_components_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|any|true|The configuration/state for an array of components|

> Example responses

> 200 Response

```json
{
  "component_ids": [
    "string"
  ]
}
```

<h3 id="put_components_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component ids|[V3ComponentIdCollection](#schemav3componentidcollection)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_components_v3

<a id="opIdpatch_components_v3"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v3/components HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v3/components \
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

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v3/components', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v3/components", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/components`

*Update a collection of components*

Update the state for a collection of components in the cfs database

> Body parameter

```json
{
  "patch": {
    "id": "string",
    "state": [
      {
        "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "status": "applied",
        "session_name": "string"
      }
    ],
    "state_append": {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "session_name": "string"
    },
    "desired_config": "string",
    "error_count": 0,
    "retry_policy": 0,
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
    "config_name": "string",
    "tags": "string"
  }
}
```

<h3 id="patch_components_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|any|true|The configuration/state for an array of components|

> Example responses

> 200 Response

```json
{
  "component_ids": [
    "string"
  ]
}
```

<h3 id="patch_components_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of component ids|[V3ComponentIdCollection](#schemav3componentidcollection)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_component_v3

<a id="opIdget_component_v3"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/components/{component_id}`

*Retrieve the state of a single component*

Retrieve the configuration and current state of a single component

<h3 id="get_component_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|state_details|query|boolean|false|Include the details on the currently applied layers|
|config_details|query|boolean|false|Include the configuration and config status in the response|
|component_id|path|string|true|Component id. e.g. xname for hardware components|

> Example responses

> 200 Response

```json
{
  "id": "string",
  "state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "last_updated": "2019-07-28T03:26:00Z",
      "session_name": "string"
    }
  ],
  "desired_state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "last_updated": "2019-07-28T03:26:00Z",
      "session_name": "string"
    }
  ],
  "desired_config": "string",
  "error_count": 0,
  "retry_policy": 0,
  "enabled": true,
  "configuration_status": "unconfigured",
  "tags": {
    "property1": "string",
    "property2": "string"
  },
  "logs": "string"
}
```

<h3 id="get_component_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V3ComponentData](#schemav3componentdata)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## put_component_v3

<a id="opIdput_component_v3"></a>

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id} \
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

r = requests.put('https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /v3/components/{component_id}`

*Add or Replace a single component*

Update the state for a given component in the cfs database

> Body parameter

```json
{
  "id": "string",
  "state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "session_name": "string"
    }
  ],
  "state_append": {
    "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
    "playbook": "site.yml",
    "commit": "string",
    "status": "applied",
    "session_name": "string"
  },
  "desired_config": "string",
  "error_count": 0,
  "retry_policy": 0,
  "enabled": true,
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="put_component_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V3ComponentData](#schemav3componentdata)|true|The configuration/state for a single component|
|component_id|path|string|true|Component id. e.g. xname for hardware components|

> Example responses

> 200 Response

```json
{
  "id": "string",
  "state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "last_updated": "2019-07-28T03:26:00Z",
      "session_name": "string"
    }
  ],
  "desired_state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "last_updated": "2019-07-28T03:26:00Z",
      "session_name": "string"
    }
  ],
  "desired_config": "string",
  "error_count": 0,
  "retry_policy": 0,
  "enabled": true,
  "configuration_status": "unconfigured",
  "tags": {
    "property1": "string",
    "property2": "string"
  },
  "logs": "string"
}
```

<h3 id="put_component_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V3ComponentData](#schemav3componentdata)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_component_v3

<a id="opIdpatch_component_v3"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id} \
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

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/components/{component_id}`

*Update a single component*

Update the state for a given component in the cfs database

> Body parameter

```json
{
  "id": "string",
  "state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "session_name": "string"
    }
  ],
  "state_append": {
    "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
    "playbook": "site.yml",
    "commit": "string",
    "status": "applied",
    "session_name": "string"
  },
  "desired_config": "string",
  "error_count": 0,
  "retry_policy": 0,
  "enabled": true,
  "tags": {
    "property1": "string",
    "property2": "string"
  }
}
```

<h3 id="patch_component_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V3ComponentData](#schemav3componentdata)|true|The configuration/state for a single component|
|component_id|path|string|true|Component id. e.g. xname for hardware components|

> Example responses

> 200 Response

```json
{
  "id": "string",
  "state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "last_updated": "2019-07-28T03:26:00Z",
      "session_name": "string"
    }
  ],
  "desired_state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "last_updated": "2019-07-28T03:26:00Z",
      "session_name": "string"
    }
  ],
  "desired_config": "string",
  "error_count": 0,
  "retry_policy": 0,
  "enabled": true,
  "configuration_status": "unconfigured",
  "tags": {
    "property1": "string",
    "property2": "string"
  },
  "logs": "string"
}
```

<h3 id="patch_component_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single component state|[V3ComponentData](#schemav3componentdata)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## delete_component_v3

<a id="opIddelete_component_v3"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id} \
  -H 'Accept: application/problem+json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id}', headers = headers)

print(r.json())

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/cfs/v3/components/{component_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/components/{component_id}`

*Delete a single component*

Delete the given component

<h3 id="delete_component_v3-parameters">Parameters</h3>

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

<h3 id="delete_component_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

<h1 id="configuration-framework-service-configurations">configurations</h1>

## get_configurations_v2

<a id="opIdget_configurations_v2"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/configurations HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/configurations \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="get_configurations_v2-parameters">Parameters</h3>

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
        "branch": "string",
        "specialParameters": {
          "imsRequireDkms": true
        }
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

<h3 id="get_configurations_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of configurations|[V2ConfigurationArray](#schemav2configurationarray)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_configuration_v2

<a id="opIdget_configuration_v2"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="get_configuration_v2-parameters">Parameters</h3>

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
      "branch": "string",
      "specialParameters": {
        "imsRequireDkms": true
      }
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

<h3 id="get_configuration_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration|[V2Configuration](#schemav2configuration)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## put_configuration_v2

<a id="opIdput_configuration_v2"></a>

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
        "Authorization": []string{"Bearer {access-token}"},
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
      "branch": "string",
      "specialParameters": {
        "imsRequireDkms": true
      }
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

<h3 id="put_configuration_v2-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V2Configuration](#schemav2configuration)|true|A desired configuration state|
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
      "branch": "string",
      "specialParameters": {
        "imsRequireDkms": true
      }
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

<h3 id="put_configuration_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration|[V2Configuration](#schemav2configuration)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_configuration_v2

<a id="opIdpatch_configuration_v2"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="patch_configuration_v2-parameters">Parameters</h3>

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
      "branch": "string",
      "specialParameters": {
        "imsRequireDkms": true
      }
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

<h3 id="patch_configuration_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration|[V2Configuration](#schemav2configuration)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## delete_configuration_v2

<a id="opIddelete_configuration_v2"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v2/configurations/{configuration_id} \
  -H 'Accept: application/problem+json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Authorization': 'Bearer {access-token}'
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
        "Authorization": []string{"Bearer {access-token}"},
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

<h3 id="delete_configuration_v2-parameters">Parameters</h3>

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

<h3 id="delete_configuration_v2-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_configurations_v3

<a id="opIdget_configurations_v3"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v3/configurations HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v3/configurations \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v3/configurations', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v3/configurations", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/configurations`

*Retrieve a collection of configurations*

Retrieve the full collection of configurations in the form of a ConfigurationArray.

<h3 id="get_configurations_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|limit|query|integer|false|When set, CFS will only return a number of configurations up to this limit.  Combined with after_id, this enables paging across results|
|after_id|query|string|false|When set, CFS will only return the configurations after the configuration specified.  Combined with limit, this enables paging across results.|
|in_use|query|boolean|false|Query for only configurations that are currently referenced by components.|

> Example responses

> 200 Response

```json
{
  "configurations": [
    {
      "name": "sample-config",
      "description": "string",
      "last_updated": "2019-07-28T03:26:00Z",
      "layers": [
        {
          "name": "sample-config",
          "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
          "source": "string",
          "playbook": "site.yml",
          "commit": "string",
          "branch": "string",
          "special_parameters": {
            "ims_require_dkms": true
          }
        }
      ],
      "additional_inventory": {
        "name": "sample-inventory",
        "clone_url": "https://vcs.domain/vcs/org/inventory.git",
        "source": "string",
        "commit": "string",
        "branch": "string"
      }
    }
  ],
  "next": {
    "limit": 0,
    "after_id": "string"
  }
}
```

<h3 id="get_configurations_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of configurations|[V3ConfigurationDataCollection](#schemav3configurationdatacollection)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_configuration_v3

<a id="opIdget_configuration_v3"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/configurations/{configuration_id}`

*Retrieve a single configuration*

Retrieve the given configuration

<h3 id="get_configuration_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|configuration_id|path|string|true|Name of the target configuration|

> Example responses

> 200 Response

```json
{
  "name": "sample-config",
  "description": "string",
  "last_updated": "2019-07-28T03:26:00Z",
  "layers": [
    {
      "name": "sample-config",
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "source": "string",
      "playbook": "site.yml",
      "commit": "string",
      "branch": "string",
      "special_parameters": {
        "ims_require_dkms": true
      }
    }
  ],
  "additional_inventory": {
    "name": "sample-inventory",
    "clone_url": "https://vcs.domain/vcs/org/inventory.git",
    "source": "string",
    "commit": "string",
    "branch": "string"
  }
}
```

<h3 id="get_configuration_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration|[V3ConfigurationData](#schemav3configurationdata)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## put_configuration_v3

<a id="opIdput_configuration_v3"></a>

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id} \
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

r = requests.put('https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /v3/configurations/{configuration_id}`

*Add or Replace a single configuration*

Add a configuration to CFS or replace an existing configuration.

> Body parameter

```json
{
  "description": "string",
  "layers": [
    {
      "name": "sample-config",
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "source": "string",
      "playbook": "site.yml",
      "commit": "string",
      "branch": "string",
      "special_parameters": {
        "ims_require_dkms": true
      }
    }
  ],
  "additional_inventory": {
    "name": "sample-inventory",
    "clone_url": "https://vcs.domain/vcs/org/inventory.git",
    "source": "string",
    "commit": "string",
    "branch": "string"
  }
}
```

<h3 id="put_configuration_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|drop_branches|query|boolean|false|Don't store the branches after converting each branch to a commit.|
|body|body|[V3ConfigurationData](#schemav3configurationdata)|true|A desired configuration state|
|configuration_id|path|string|true|Name of the target configuration|

> Example responses

> 200 Response

```json
{
  "name": "sample-config",
  "description": "string",
  "last_updated": "2019-07-28T03:26:00Z",
  "layers": [
    {
      "name": "sample-config",
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "source": "string",
      "playbook": "site.yml",
      "commit": "string",
      "branch": "string",
      "special_parameters": {
        "ims_require_dkms": true
      }
    }
  ],
  "additional_inventory": {
    "name": "sample-inventory",
    "clone_url": "https://vcs.domain/vcs/org/inventory.git",
    "source": "string",
    "commit": "string",
    "branch": "string"
  }
}
```

<h3 id="put_configuration_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration|[V3ConfigurationData](#schemav3configurationdata)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_configuration_v3

<a id="opIdpatch_configuration_v3"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/configurations/{configuration_id}`

*Update the commits for a configuration*

Updates the commits for all layers that specify a branch

<h3 id="patch_configuration_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|configuration_id|path|string|true|Name of the target configuration|

> Example responses

> 200 Response

```json
{
  "name": "sample-config",
  "description": "string",
  "last_updated": "2019-07-28T03:26:00Z",
  "layers": [
    {
      "name": "sample-config",
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "source": "string",
      "playbook": "site.yml",
      "commit": "string",
      "branch": "string",
      "special_parameters": {
        "ims_require_dkms": true
      }
    }
  ],
  "additional_inventory": {
    "name": "sample-inventory",
    "clone_url": "https://vcs.domain/vcs/org/inventory.git",
    "source": "string",
    "commit": "string",
    "branch": "string"
  }
}
```

<h3 id="patch_configuration_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single configuration|[V3ConfigurationData](#schemav3configurationdata)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## delete_configuration_v3

<a id="opIddelete_configuration_v3"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id} \
  -H 'Accept: application/problem+json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id}', headers = headers)

print(r.json())

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/cfs/v3/configurations/{configuration_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/configurations/{configuration_id}`

*Delete a single configuration*

Delete the given configuration. This will fail in any components are using the specified configuration.

<h3 id="delete_configuration_v3-parameters">Parameters</h3>

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

<h3 id="delete_configuration_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

<h1 id="configuration-framework-service-sources">sources</h1>

## get_sources_v3

<a id="opIdget_sources_v3"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v3/sources HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v3/sources \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v3/sources', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v3/sources", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/sources`

*Retrieve a collection of sources*

Retrieve the full collection of sources in the form of a SourceArray.

<h3 id="get_sources_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|limit|query|integer|false|When set, CFS will only return a number of sources up to this limit.  Combined with after_id, this enables paging across results|
|after_id|query|string|false|When set, CFS will only return the configurations after the source specified.  Combined with limit, this enables paging across results.|
|in_use|query|boolean|false|Query for only sources that are currently referenced by configurations.|

> Example responses

> 200 Response

```json
{
  "sources": [
    {
      "name": "sample-source",
      "description": "string",
      "last_updated": "2019-07-28T03:26:00Z",
      "clone_url": "string",
      "credentials": {
        "authentication_method": "password",
        "secret_name": "string"
      },
      "ca_cert": {
        "configmap_name": "string",
        "configmap_namespace": "string"
      }
    }
  ],
  "next": {
    "limit": 0,
    "after_id": "string"
  }
}
```

<h3 id="get_sources_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of sources|[V3SourceDataCollection](#schemav3sourcedatacollection)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## post_source_v3

<a id="opIdpost_source_v3"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/cfs/v3/sources HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/cfs/v3/sources \
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

r = requests.post('https://api-gw-service-nmn.local/apis/cfs/v3/sources', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/cfs/v3/sources", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v3/sources`

*Add a single source*

Add a source to CFS

> Body parameter

```json
{
  "name": "sample-source",
  "description": "string",
  "clone_url": "string",
  "credentials": {
    "authentication_method": "password",
    "username": "string",
    "password": "string"
  },
  "ca_cert": {
    "configmap_name": "string",
    "configmap_namespace": "string"
  }
}
```

<h3 id="post_source_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V3SourceCreateData](#schemav3sourcecreatedata)|true|A source|

> Example responses

> 201 Response

```json
{
  "name": "sample-source",
  "description": "string",
  "last_updated": "2019-07-28T03:26:00Z",
  "clone_url": "string",
  "credentials": {
    "authentication_method": "password",
    "secret_name": "string"
  },
  "ca_cert": {
    "configmap_name": "string",
    "configmap_namespace": "string"
  }
}
```

<h3 id="post_source_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|A single source|[V3SourceData](#schemav3sourcedata)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|A source with the same name already exists|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get_source_v3

<a id="opIdget_source_v3"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/sources/{source_id}`

*Retrieve a single source*

Retrieve the given source

<h3 id="get_source_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|source_id|path|string|true|Name of the target source|

> Example responses

> 200 Response

```json
{
  "name": "sample-source",
  "description": "string",
  "last_updated": "2019-07-28T03:26:00Z",
  "clone_url": "string",
  "credentials": {
    "authentication_method": "password",
    "secret_name": "string"
  },
  "ca_cert": {
    "configmap_name": "string",
    "configmap_namespace": "string"
  }
}
```

<h3 id="get_source_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single source|[V3SourceData](#schemav3sourcedata)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## patch_source_v3

<a id="opIdpatch_source_v3"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id} \
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

r = requests.patch('https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/sources/{source_id}`

*Update the commits for a source*

Updates a CFS source

> Body parameter

```json
{
  "description": "string",
  "clone_url": "string",
  "credentials": {
    "authentication_method": "password",
    "username": "string",
    "password": "string"
  },
  "ca_cert": {
    "configmap_name": "string",
    "configmap_namespace": "string"
  }
}
```

<h3 id="patch_source_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[V3SourceUpdateData](#schemav3sourceupdatedata)|true|A source|
|source_id|path|string|true|Name of the target source|

> Example responses

> 200 Response

```json
{
  "name": "sample-source",
  "description": "string",
  "last_updated": "2019-07-28T03:26:00Z",
  "clone_url": "string",
  "credentials": {
    "authentication_method": "password",
    "secret_name": "string"
  },
  "ca_cert": {
    "configmap_name": "string",
    "configmap_namespace": "string"
  }
}
```

<h3 id="patch_source_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A single source|[V3SourceData](#schemav3sourcedata)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## delete_source_v3

<a id="opIddelete_source_v3"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/problem+json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id} \
  -H 'Accept: application/problem+json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/problem+json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id}', headers = headers)

print(r.json())

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/cfs/v3/sources/{source_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/sources/{source_id}`

*Delete a single source*

Delete the given source. This will fail in any components are using the specified source.

<h3 id="delete_source_v3-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|source_id|path|string|true|Name of the target source|

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

<h3 id="delete_source_v3-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|The resource was deleted.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The resource was not found.|[ProblemDetails](#schemaproblemdetails)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

# Schemas

<h2 id="tocS_Version">Version</h2>
<!-- backwards compatibility -->
<a id="schemaversion"></a>
<a id="schema_Version"></a>
<a id="tocSversion"></a>
<a id="tocsversion"></a>

```json
{
  "major": "1",
  "minor": "0",
  "patch": "10"
}

```

Version data

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|major|string|false|none|none|
|minor|string|false|none|none|
|patch|string|false|none|none|

<h2 id="tocS_Healthz">Healthz</h2>
<!-- backwards compatibility -->
<a id="schemahealthz"></a>
<a id="schema_Healthz"></a>
<a id="tocShealthz"></a>
<a id="tocshealthz"></a>

```json
{
  "db_status": "string",
  "kafka_status": "string"
}

```

Service health status

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|db_status|string|false|none|none|
|kafka_status|string|false|none|none|

<h2 id="tocS_V3NextData">V3NextData</h2>
<!-- backwards compatibility -->
<a id="schemav3nextdata"></a>
<a id="schema_V3NextData"></a>
<a id="tocSv3nextdata"></a>
<a id="tocsv3nextdata"></a>

```json
{
  "limit": 0,
  "after_id": "string"
}

```

Information for requesting the next page of data

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|limit|integer|false|none|none|
|after_id|string|false|none|none|

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
|sessionTTL|string|false|none|A time-to-live applied to all completed CFS sessions. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h. Set to an empty string to disable.|
|additionalInventoryUrl|string|false|none|The git clone URL of a repo with additional inventory files.  All files in the repo will be copied into the hosts directory of CFS.|
|batcherMaxBackoff|integer|false|none|The maximum number of seconds that batcher will backoff from session creation if problems are detected.|
|batcherDisable|boolean|false|none|Disables cfs-batcher's automatic session creation if set to True.|
|batcherPendingTimeout|integer|false|none|How long cfs-batcher will wait on a pending session before deleting and recreating it (in seconds).|
|loggingLevel|string|false|none|The logging level for core CFS services.  This does not affect the Ansible logging level.|

<h2 id="tocS_V3Options">V3Options</h2>
<!-- backwards compatibility -->
<a id="schemav3options"></a>
<a id="schema_V3Options"></a>
<a id="tocSv3options"></a>
<a id="tocsv3options"></a>

```json
{
  "hardware_sync_interval": 5,
  "batcher_check_interval": 5,
  "batch_size": 120,
  "batch_window": 120,
  "default_batcher_retry_policy": 1,
  "default_playbook": "site.yml",
  "default_ansible_config": "cfs-default-ansible-cfg",
  "session_ttl": "24h",
  "additional_inventory_url": "https://api-gw-service-nmn.local/vcs/cray/inventory.git",
  "additional_inventory_source": "example-source",
  "batcher_max_backoff": 3600,
  "batcher_disable": true,
  "batcher_pending_timeout": 1,
  "logging_level": "DEBUG",
  "default_page_size": 1,
  "debug_wait_time": 0,
  "include_ara_links": true
}

```

Configuration options for the configuration service.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|hardware_sync_interval|integer|false|none|How frequently the CFS hardware-sync-agent checks with the Hardware State Manager to update its known hardware (in seconds)|
|batcher_check_interval|integer|false|none|How frequently the batcher checks the configuration states to see if work needs to be done (in seconds)|
|batch_size|integer|false|none|The maximum number of nodes the batcher will run a single CFS session against.|
|batch_window|integer|false|none|The maximum number of seconds the batcher will wait to run a CFS session once a node has been detected that needs configuration.|
|default_batcher_retry_policy|integer|false|none|The default maximum number retries per node when configuration fails.|
|default_playbook|string|false|read-only|[DEPRECATED] The default playbook to be used if not specified in a node's desired state. This option is read-only via the v3 API and remains only for compatibility with the v2 API. This option will be removed from v3 when the v2 API is removed.|
|default_ansible_config|string|false|none|The Kubernetes ConfigMap which holds the default ansible.cfg for a given CFS session. This ConfigMap must be present in the same Kubernetes namespace as the CFS service.|
|session_ttl|string|false|none|A time-to-live applied to all completed CFS sessions. Specified in minutes, hours, days, or weeks. e.g. 3d or 24h. Set to an empty string to disable.|
|additional_inventory_url|string|false|none|The git clone URL of a repo with additional inventory files.  All files in the repo will be copied into the hosts directory of CFS. This is mutually exclusive with the additional_inventory_source option and only one can be set.|
|additional_inventory_source|string|false|none|A CFS source with additional inventory files.  All files in the repo will be copied into the hosts directory of CFS. This is mutually exclusive with the additional_source_url option and only one can be set.|
|batcher_max_backoff|integer|false|none|The maximum number of seconds that batcher will backoff from session creation if problems are detected.|
|batcher_disable|boolean|false|none|Disables cfs-batcher's automatic session creation if set to True.|
|batcher_pending_timeout|integer|false|none|How long cfs-batcher will wait on a pending session before deleting and recreating it (in seconds).|
|logging_level|string|false|none|The logging level for core CFS services.  This does not affect the Ansible logging level.|
|default_page_size|integer|false|none|The maximum number of results that a query will return if the limit parameter is not specified.|
|debug_wait_time|integer|false|none|The number of seconds CFS sessions will wait after failure for debugging when debug_on_failure is true.|
|include_ara_links|boolean|false|none|If true, session and component records will include links to ARA dashboards for the logs|

#### Enumerated Values

|Property|Value|
|---|---|
|logging_level|DEBUG|
|logging_level|INFO|
|logging_level|WARNING|
|logging_level|ERROR|

<h2 id="tocS_SessionTargetSection">SessionTargetSection</h2>
<!-- backwards compatibility -->
<a id="schemasessiontargetsection"></a>
<a id="schema_SessionTargetSection"></a>
<a id="tocSsessiontargetsection"></a>
<a id="tocssessiontargetsection"></a>

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

<h2 id="tocS_SessionConfigurationSection">SessionConfigurationSection</h2>
<!-- backwards compatibility -->
<a id="schemasessionconfigurationsection"></a>
<a id="schema_SessionConfigurationSection"></a>
<a id="tocSsessionconfigurationsection"></a>
<a id="tocssessionconfigurationsection"></a>

```json
{
  "name": "example-config",
  "limit": "layer1,layer3"
}

```

The configuration information which the session will apply

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|The name of the CFS configuration to be applied|
|limit|string|false|none|A comma separated list of layers in the configuration to limit the session to. This can be either a list of named layers, or a list of indices.|

<h2 id="tocS_SessionAnsibleSection">SessionAnsibleSection</h2>
<!-- backwards compatibility -->
<a id="schemasessionansiblesection"></a>
<a id="schema_SessionAnsibleSection"></a>
<a id="tocSsessionansiblesection"></a>
<a id="tocssessionansiblesection"></a>

```json
{
  "config": "cfs-default-ansible-cfg",
  "limit": "host1",
  "verbosity": 0,
  "passthrough": "string"
}

```

Additional options that will be used when invoking Ansible.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|config|string|false|none|The Kubernetes ConfigMap which holds the ansible.cfg for a given CFS session. This ConfigMap must be present in the same Kubernetes namespace as the CFS service. If no value is given, the value of the defaultAnsibleConfig field in the /options endpoint will be used.|
|limit|string¦null|false|none|Additional filtering of hosts or groups from the inventory to run against. This is especially useful when running with dynamic inventory and when you want to run on a subset of nodes or groups. This option corresponds to ansible-playbook's --limit and can be used to specify nodes or groups.|
|verbosity|integer|false|none|The verbose mode to use in the call to the ansible-playbook command. 1 = -v, 2 = -vv, etc. Valid values range from 0 to 4. See the ansible-playbook help for more information.|
|passthrough|string¦null|false|none|Additional parameters that are added to all Ansible calls for the session. This field is currently limited to the following Ansible parameters: "--extra-vars", "--forks", "--skip-tags", "--start-at-task", and "--tags". WARNING: Parameters passed to Ansible in this way should be used with caution.  State will not be recorded for components when using these flags to avoid incorrect reporting of partial playbook runs.|

<h2 id="tocS_SessionStatusArtifactsSection">SessionStatusArtifactsSection</h2>
<!-- backwards compatibility -->
<a id="schemasessionstatusartifactssection"></a>
<a id="schema_SessionStatusArtifactsSection"></a>
<a id="tocSsessionstatusartifactssection"></a>
<a id="tocssessionstatusartifactssection"></a>

```json
[
  {
    "image_id": "f34ff35e-d782-4a65-a1b8-243a3cd740af",
    "result_id": "8b782ccd-8706-4145-a6a1-724e29ed5522",
    "type": "ims_customized_image"
  }
]

```

Status of artifacts

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|image_id|string(uuid)|false|none|The IMS id of the original image to be customized via a configuration session.|
|result_id|string(uuid)|false|none|The IMS id of the image that was customized via a configuration session. This is the resultant image of the customization.|
|type|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|type|ims_customized_image|

<h2 id="tocS_V2SessionStatusSessionSection">V2SessionStatusSessionSection</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionstatussessionsection"></a>
<a id="schema_V2SessionStatusSessionSection"></a>
<a id="tocSv2sessionstatussessionsection"></a>
<a id="tocsv2sessionstatussessionsection"></a>

```json
{
  "job": "cray-cfs-job-session-20190728032600",
  "completionTime": "2019-07-28T03:26:00Z",
  "startTime": "2019-07-28T03:26:00Z",
  "status": "pending",
  "succeeded": "none"
}

```

Status of session

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|job|string|false|read-only|The name of the configuration execution environment associated with this session.|
|completionTime|string(date-time)¦null|false|read-only|The date/time when the session completed execution in RFC 3339 format. This has a null value when the session has not yet completed.|
|startTime|string(date-time)|false|read-only|The date/time when the session started execution in RFC 3339 format.|
|status|string|false|read-only|The execution status of the session.|
|succeeded|string|false|read-only|Whether the session executed successfully or not. A 'none'<br>value denotes that the execution has not completed. This<br>field has context when the `status` field is 'complete'.<br>A session may successfully execute even if the underlying<br>tasks do not.|

#### Enumerated Values

|Property|Value|
|---|---|
|status|pending|
|status|running|
|status|complete|
|succeeded|none|
|succeeded|true|
|succeeded|false|
|succeeded|unknown|

<h2 id="tocS_V3SessionStatusSessionSection">V3SessionStatusSessionSection</h2>
<!-- backwards compatibility -->
<a id="schemav3sessionstatussessionsection"></a>
<a id="schema_V3SessionStatusSessionSection"></a>
<a id="tocSv3sessionstatussessionsection"></a>
<a id="tocsv3sessionstatussessionsection"></a>

```json
{
  "job": "cray-cfs-job-session-20190728032600",
  "ims_job": "5037edd8-e9c5-437d-b54b-db4a8ad2cb15",
  "completion_time": "2019-07-28T03:26:00Z",
  "start_time": "2019-07-28T03:26:00Z",
  "status": "pending",
  "succeeded": "none"
}

```

Status of session

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|job|string|false|none|The name of the configuration execution environment associated with this session.|
|ims_job|string|false|none|The name os the IMS job associated with the session when running against an image.|
|completion_time|string(date-time)|false|read-only|The date/time when the session completed execution in RFC 3339 format.|
|start_time|string(date-time)|false|read-only|The date/time when the session started execution in RFC 3339 format.|
|status|string|false|read-only|The execution status of the session.|
|succeeded|string|false|read-only|Whether the session executed successfully or not. A 'none'<br>value denotes that the execution has not completed. This<br>field has context when the `status` field is 'complete'.<br>A session may successfully execute even if the underlying<br>tasks do not.|

#### Enumerated Values

|Property|Value|
|---|---|
|status|pending|
|status|running|
|status|complete|
|succeeded|none|
|succeeded|true|
|succeeded|false|
|succeeded|unknown|

<h2 id="tocS_V2SessionStatusSection">V2SessionStatusSection</h2>
<!-- backwards compatibility -->
<a id="schemav2sessionstatussection"></a>
<a id="schema_V2SessionStatusSection"></a>
<a id="tocSv2sessionstatussection"></a>
<a id="tocsv2sessionstatussection"></a>

```json
{
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
}

```

Status of artifacts, session, and targets. Lists details like session status, session start and completion time, number of successful, failed, or running targets. If the target definition is an image, it also lists the image_id, result_id, and type of image under Artifacts.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|artifacts|[SessionStatusArtifactsSection](#schemasessionstatusartifactssection)|false|none|Status of artifacts|
|session|[V2SessionStatusSessionSection](#schemav2sessionstatussessionsection)|false|none|Status of session|

<h2 id="tocS_V3SessionStatusSection">V3SessionStatusSection</h2>
<!-- backwards compatibility -->
<a id="schemav3sessionstatussection"></a>
<a id="schema_V3SessionStatusSection"></a>
<a id="tocSv3sessionstatussection"></a>
<a id="tocsv3sessionstatussection"></a>

```json
{
  "artifacts": [
    {
      "image_id": "f34ff35e-d782-4a65-a1b8-243a3cd740af",
      "result_id": "8b782ccd-8706-4145-a6a1-724e29ed5522",
      "type": "ims_customized_image"
    }
  ],
  "session": {
    "job": "cray-cfs-job-session-20190728032600",
    "ims_job": "5037edd8-e9c5-437d-b54b-db4a8ad2cb15",
    "completion_time": "2019-07-28T03:26:00Z",
    "start_time": "2019-07-28T03:26:00Z",
    "status": "pending",
    "succeeded": "none"
  }
}

```

Status of artifacts, session, and targets. Lists details like session status, session start and completion time, number of successful, failed, or running targets. If the target definition is an image, it also lists the image_id, result_id, and type of image under Artifacts.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|artifacts|[SessionStatusArtifactsSection](#schemasessionstatusartifactssection)|false|none|Status of artifacts|
|session|[V3SessionStatusSessionSection](#schemav3sessionstatussessionsection)|false|none|Status of session|

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
|configuration|[SessionConfigurationSection](#schemasessionconfigurationsection)|false|none|The configuration information which the session will apply|
|ansible|[SessionAnsibleSection](#schemasessionansiblesection)|false|none|Additional options that will be used when invoking Ansible.|
|target|[SessionTargetSection](#schemasessiontargetsection)|false|none|A target lets you define the nodes or images that you want to customize and consists of two sub-parameters - Definition and groups. By default, Configuration Framework Sessions use dynamic inventory definition to target hosts. When using a session to customize an image, or if a static inventory is required, use this optional section to specify entities (whether images or nodes) for the session to target.|
|status|[V2SessionStatusSection](#schemav2sessionstatussection)|false|none|Status of artifacts, session, and targets. Lists details like session status, session start and completion time, number of successful, failed, or running targets. If the target definition is an image, it also lists the image_id, result_id, and type of image under Artifacts.|
|tags|object|false|none|A collection of key-value pairs containing descriptive information for the session, such as information about the session creator.|
|» **additionalProperties**|string|false|none|none|

<h2 id="tocS_V3SessionData">V3SessionData</h2>
<!-- backwards compatibility -->
<a id="schemav3sessiondata"></a>
<a id="schema_V3SessionData"></a>
<a id="tocSv3sessiondata"></a>
<a id="tocsv3sessiondata"></a>

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
      "ims_job": "5037edd8-e9c5-437d-b54b-db4a8ad2cb15",
      "completion_time": "2019-07-28T03:26:00Z",
      "start_time": "2019-07-28T03:26:00Z",
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {
    "property1": "string",
    "property2": "string"
  },
  "debug_on_failure": false,
  "logs": "string"
}

```

An execution session for the Configuration Framework.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|Name of the session. The length of the name is restricted to 45 characters.|
|configuration|[SessionConfigurationSection](#schemasessionconfigurationsection)|false|none|The configuration information which the session will apply|
|ansible|[SessionAnsibleSection](#schemasessionansiblesection)|false|none|Additional options that will be used when invoking Ansible.|
|target|[SessionTargetSection](#schemasessiontargetsection)|false|none|A target lets you define the nodes or images that you want to customize and consists of two sub-parameters - Definition and groups. By default, Configuration Framework Sessions use dynamic inventory definition to target hosts. When using a session to customize an image, or if a static inventory is required, use this optional section to specify entities (whether images or nodes) for the session to target.|
|status|[V3SessionStatusSection](#schemav3sessionstatussection)|false|none|Status of artifacts, session, and targets. Lists details like session status, session start and completion time, number of successful, failed, or running targets. If the target definition is an image, it also lists the image_id, result_id, and type of image under Artifacts.|
|tags|object|false|none|A collection of key-value pairs containing descriptive information for the session, such as information about the session creator.|
|» **additionalProperties**|string|false|none|none|
|debug_on_failure|boolean|false|none|When true, the ansible container for the session will remain running after an Ansible failure.  The container will remain running for a number of seconds specified by the debug_wait_time options, or until complete flag is touched.|
|logs|string|false|read-only|The link to the ARA UI with logs for this component|

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
|configurationLimit|string|false|none|A comma separated list of layers in the configuration to limit the session to. This can be either a list of named layers, or a list of indices.|
|ansibleLimit|string|false|none|Additional filtering of hosts or groups from the inventory to run against. This is especially useful when running with dynamic inventory and when you want to run on a subset of nodes or groups. This option corresponds to ansible-playbook's --limit and can be used to specify nodes or groups.|
|ansibleConfig|string|false|none|The Kubernetes ConfigMap which holds the ansible.cfg for a given CFS session. This ConfigMap must be present in the same Kubernetes namespace as the CFS service. If no value is given, the value of the defaultAnsibleConfig field in the /options endpoint will be used.|
|ansibleVerbosity|integer|false|none|The verbose mode to use in the call to the ansible-playbook command. 1 = -v, 2 = -vv, etc. Valid values range from 0 to 4. See the ansible-playbook help for more information.|
|ansiblePassthrough|string|false|none|Additional parameters that are added to all Ansible calls for the session. This field is currently limited to the following Ansible parameters: "--extra-vars", "--forks", "--skip-tags", "--start-at-task", and "--tags". WARNING: Parameters passed to Ansible in this way should be used with caution.  State will not be recorded for components when using these flags to avoid incorrect reporting of partial playbook runs.|
|target|[SessionTargetSection](#schemasessiontargetsection)|false|none|A target lets you define the nodes or images that you want to customize and consists of two sub-parameters - Definition and groups. By default, Configuration Framework Sessions use dynamic inventory definition to target hosts. When using a session to customize an image, or if a static inventory is required, use this optional section to specify entities (whether images or nodes) for the session to target.|
|tags|object|false|none|A collection of key-value pairs containing descriptive information for the session, such as information about the session creator.|
|» **additionalProperties**|string|false|none|none|

<h2 id="tocS_V3SessionCreate">V3SessionCreate</h2>
<!-- backwards compatibility -->
<a id="schemav3sessioncreate"></a>
<a id="schema_V3SessionCreate"></a>
<a id="tocSv3sessioncreate"></a>
<a id="tocsv3sessioncreate"></a>

```json
{
  "name": "session-20190728032600",
  "configuration_name": "example-config",
  "configuration_limit": "layer1,layer3",
  "ansible_limit": "host1",
  "ansible_config": "cfs-default-ansible-cfg",
  "ansible_verbosity": 0,
  "ansible_passthrough": "",
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
  },
  "debug_on_failure": false
}

```

The information required to create a Config Framework Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|true|none|Name of the session. The length of the name is restricted to 45 characters.|
|configuration_name|string|true|none|The name of a CFS configuration to apply|
|configuration_limit|string|false|none|A comma separated list of layers in the configuration to limit the session to. This can be either a list of named layers, or a list of indices.|
|ansible_limit|string|false|none|Additional filtering of hosts or groups from the inventory to run against. This is especially useful when running with dynamic inventory and when you want to run on a subset of nodes or groups. This option corresponds to ansible-playbook's --limit and can be used to specify nodes or groups.|
|ansible_config|string|false|none|The Kubernetes ConfigMap which holds the ansible.cfg for a given CFS session. This ConfigMap must be present in the same Kubernetes namespace as the CFS service. If no value is given, the value of the defaultAnsibleConfig field in the /options endpoint will be used.|
|ansible_verbosity|integer|false|none|The verbose mode to use in the call to the ansible-playbook command. 1 = -v, 2 = -vv, etc. Valid values range from 0 to 4. See the ansible-playbook help for more information.|
|ansible_passthrough|string|false|none|Additional parameters that are added to all Ansible calls for the session. This field is currently limited to the following Ansible parameters: "--extra-vars", "--forks", "--skip-tags", "--start-at-task", and "--tags". WARNING: Parameters passed to Ansible in this way should be used with caution.  State will not be recorded for components when using these flags to avoid incorrect reporting of partial playbook runs.|
|target|[SessionTargetSection](#schemasessiontargetsection)|false|none|A target lets you define the nodes or images that you want to customize and consists of two sub-parameters - Definition and groups. By default, Configuration Framework Sessions use dynamic inventory definition to target hosts. When using a session to customize an image, or if a static inventory is required, use this optional section to specify entities (whether images or nodes) for the session to target.|
|tags|object|false|none|A collection of key-value pairs containing descriptive information for the session, such as information about the session creator.|
|» **additionalProperties**|string|false|none|none|
|debug_on_failure|boolean|false|none|When true, the ansible container for the session will remain running after an Ansible failure.  The container will remain running for a number of seconds specified by the debug_wait_time options, or until complete flag is touched.|

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

An array of sessions.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V2Session](#schemav2session)]|false|none|An array of sessions.|

<h2 id="tocS_V3SessionDataCollection">V3SessionDataCollection</h2>
<!-- backwards compatibility -->
<a id="schemav3sessiondatacollection"></a>
<a id="schema_V3SessionDataCollection"></a>
<a id="tocSv3sessiondatacollection"></a>
<a id="tocsv3sessiondatacollection"></a>

```json
{
  "sessions": [
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
          "ims_job": "5037edd8-e9c5-437d-b54b-db4a8ad2cb15",
          "completion_time": "2019-07-28T03:26:00Z",
          "start_time": "2019-07-28T03:26:00Z",
          "status": "pending",
          "succeeded": "none"
        }
      },
      "tags": {
        "property1": "string",
        "property2": "string"
      },
      "debug_on_failure": false,
      "logs": "string"
    }
  ],
  "next": {
    "limit": 0,
    "after_id": "string"
  }
}

```

A collection of session data.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|sessions|[[V3SessionData](#schemav3sessiondata)]|false|none|[An execution session for the Configuration Framework.<br>]|
|next|[V3NextData](#schemav3nextdata)|false|none|Information for requesting the next page of data|

<h2 id="tocS_V3SessionIdCollection">V3SessionIdCollection</h2>
<!-- backwards compatibility -->
<a id="schemav3sessionidcollection"></a>
<a id="schema_V3SessionIdCollection"></a>
<a id="tocSv3sessionidcollection"></a>
<a id="tocsv3sessionidcollection"></a>

```json
{
  "session_ids": [
    "string"
  ]
}

```

A collection of session data.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|session_ids|[string]|false|none|none|

<h2 id="tocS_V2AdditionalInventoryLayer">V2AdditionalInventoryLayer</h2>
<!-- backwards compatibility -->
<a id="schemav2additionalinventorylayer"></a>
<a id="schema_V2AdditionalInventoryLayer"></a>
<a id="tocSv2additionalinventorylayer"></a>
<a id="tocsv2additionalinventorylayer"></a>

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

<h2 id="tocS_V3AdditionalInventoryLayer">V3AdditionalInventoryLayer</h2>
<!-- backwards compatibility -->
<a id="schemav3additionalinventorylayer"></a>
<a id="schema_V3AdditionalInventoryLayer"></a>
<a id="tocSv3additionalinventorylayer"></a>
<a id="tocsv3additionalinventorylayer"></a>

```json
{
  "name": "sample-inventory",
  "clone_url": "https://vcs.domain/vcs/org/inventory.git",
  "source": "string",
  "commit": "string",
  "branch": "string"
}

```

An inventory reference to include in a set of configurations.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|The name of the inventory layer.|
|clone_url|string|true|none|The clone URL of the configuration content repository.|
|source|string|false|none|A CFS source with directions to the configuration content repository|
|commit|string|false|none|The commit hash of the configuration repository when the state is set.|
|branch|string|false|none|The repository branch to use. This will automatically set `commit` to master on the branch<br>when the configuration is added.|

<h2 id="tocS_V2ConfigurationLayer">V2ConfigurationLayer</h2>
<!-- backwards compatibility -->
<a id="schemav2configurationlayer"></a>
<a id="schema_V2ConfigurationLayer"></a>
<a id="tocSv2configurationlayer"></a>
<a id="tocsv2configurationlayer"></a>

```json
{
  "name": "sample-config",
  "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
  "playbook": "site.yml",
  "commit": "string",
  "branch": "string",
  "specialParameters": {
    "imsRequireDkms": true
  }
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
|specialParameters|object|false|none|Optional parameters that do not affect the configuration content or are only used in<br>special circumstances.|
|» imsRequireDkms|boolean|false|none|If true, any image customization sessions that use this configuration will enable DKMS in IMS.|

<h2 id="tocS_V3ConfigurationLayer">V3ConfigurationLayer</h2>
<!-- backwards compatibility -->
<a id="schemav3configurationlayer"></a>
<a id="schema_V3ConfigurationLayer"></a>
<a id="tocSv3configurationlayer"></a>
<a id="tocsv3configurationlayer"></a>

```json
{
  "name": "sample-config",
  "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
  "source": "string",
  "playbook": "site.yml",
  "commit": "string",
  "branch": "string",
  "special_parameters": {
    "ims_require_dkms": true
  }
}

```

A single desired configuration state for a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|The name of the configuration layer.|
|clone_url|string|false|none|The clone URL of the configuration content repository.|
|source|string|false|none|A CFS source with directions to the configuration content repository|
|playbook|string|true|none|The Ansible playbook to run.|
|commit|string|false|none|The commit hash of the configuration repository when the state is set.|
|branch|string|false|none|The configuration branch to use.  This will automatically set commit to master on the branch<br>when the configuration is added.|
|special_parameters|object|false|none|Optional parameters that do not affect the configuration content or are only used in<br>special circumstances.|
|» ims_require_dkms|boolean|false|none|If true, any image customization sessions that use this configuration will enable DKMS in IMS.|

<h2 id="tocS_V2Configuration">V2Configuration</h2>
<!-- backwards compatibility -->
<a id="schemav2configuration"></a>
<a id="schema_V2Configuration"></a>
<a id="tocSv2configuration"></a>
<a id="tocsv2configuration"></a>

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
      "branch": "string",
      "specialParameters": {
        "imsRequireDkms": true
      }
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
|layers|[[V2ConfigurationLayer](#schemav2configurationlayer)]|false|none|A list of ConfigurationLayer(s).|
|additional_inventory|[V2AdditionalInventoryLayer](#schemav2additionalinventorylayer)|false|none|An inventory reference to include in a set of configurations.|

<h2 id="tocS_V3ConfigurationData">V3ConfigurationData</h2>
<!-- backwards compatibility -->
<a id="schemav3configurationdata"></a>
<a id="schema_V3ConfigurationData"></a>
<a id="tocSv3configurationdata"></a>
<a id="tocsv3configurationdata"></a>

```json
{
  "name": "sample-config",
  "description": "string",
  "last_updated": "2019-07-28T03:26:00Z",
  "layers": [
    {
      "name": "sample-config",
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "source": "string",
      "playbook": "site.yml",
      "commit": "string",
      "branch": "string",
      "special_parameters": {
        "ims_require_dkms": true
      }
    }
  ],
  "additional_inventory": {
    "name": "sample-inventory",
    "clone_url": "https://vcs.domain/vcs/org/inventory.git",
    "source": "string",
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
|last_updated|string(date-time)|false|read-only|The date/time when the state was last updated in RFC 3339 format.|
|layers|[[V3ConfigurationLayer](#schemav3configurationlayer)]|false|none|A list of ConfigurationLayer(s).|
|additional_inventory|[V3AdditionalInventoryLayer](#schemav3additionalinventorylayer)|false|none|An inventory reference to include in a set of configurations.|

<h2 id="tocS_V2ConfigurationArray">V2ConfigurationArray</h2>
<!-- backwards compatibility -->
<a id="schemav2configurationarray"></a>
<a id="schema_V2ConfigurationArray"></a>
<a id="tocSv2configurationarray"></a>
<a id="tocsv2configurationarray"></a>

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
        "branch": "string",
        "specialParameters": {
          "imsRequireDkms": true
        }
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
|*anonymous*|[[V2Configuration](#schemav2configuration)]|false|none|An array of configurations.|

<h2 id="tocS_V3ConfigurationDataCollection">V3ConfigurationDataCollection</h2>
<!-- backwards compatibility -->
<a id="schemav3configurationdatacollection"></a>
<a id="schema_V3ConfigurationDataCollection"></a>
<a id="tocSv3configurationdatacollection"></a>
<a id="tocsv3configurationdatacollection"></a>

```json
{
  "configurations": [
    {
      "name": "sample-config",
      "description": "string",
      "last_updated": "2019-07-28T03:26:00Z",
      "layers": [
        {
          "name": "sample-config",
          "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
          "source": "string",
          "playbook": "site.yml",
          "commit": "string",
          "branch": "string",
          "special_parameters": {
            "ims_require_dkms": true
          }
        }
      ],
      "additional_inventory": {
        "name": "sample-inventory",
        "clone_url": "https://vcs.domain/vcs/org/inventory.git",
        "source": "string",
        "commit": "string",
        "branch": "string"
      }
    }
  ],
  "next": {
    "limit": 0,
    "after_id": "string"
  }
}

```

A collection of configuration data.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|configurations|[[V3ConfigurationData](#schemav3configurationdata)]|false|none|[A collection of ConfigurationLayers.]|
|next|[V3NextData](#schemav3nextdata)|false|none|Information for requesting the next page of data|

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

<h2 id="tocS_V3ComponentsFilter">V3ComponentsFilter</h2>
<!-- backwards compatibility -->
<a id="schemav3componentsfilter"></a>
<a id="schema_V3ComponentsFilter"></a>
<a id="tocSv3componentsfilter"></a>
<a id="tocsv3componentsfilter"></a>

```json
{
  "ids": "string",
  "status": "unconfigured",
  "enabled": true,
  "config_name": "string",
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
|config_name|string|false|none|A configuration name.  All components with this configuration set will be patched.|
|tags|string|false|none|Patches all components with the given tags.  Key-value pairs should be separated using =, and tags can be a comma-separated list.  Only components that match all tags will be patched.|

#### Enumerated Values

|Property|Value|
|---|---|
|status|unconfigured|
|status|pending|
|status|failed|
|status|configured|
|status||

<h2 id="tocS_V2ConfigurationStateLayer">V2ConfigurationStateLayer</h2>
<!-- backwards compatibility -->
<a id="schemav2configurationstatelayer"></a>
<a id="schema_V2ConfigurationStateLayer"></a>
<a id="tocSv2configurationstatelayer"></a>
<a id="tocsv2configurationstatelayer"></a>

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

<h2 id="tocS_V3ConfigurationStateLayer">V3ConfigurationStateLayer</h2>
<!-- backwards compatibility -->
<a id="schemav3configurationstatelayer"></a>
<a id="schema_V3ConfigurationStateLayer"></a>
<a id="tocSv3configurationstatelayer"></a>
<a id="tocsv3configurationstatelayer"></a>

```json
{
  "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
  "playbook": "site.yml",
  "commit": "string",
  "status": "applied",
  "last_updated": "2019-07-28T03:26:00Z",
  "session_name": "string"
}

```

The current configuration state for a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|clone_url|string|false|none|The clone URL of the configuration content repository.|
|playbook|string|false|none|The Ansible playbook to run.|
|commit|string|false|none|The commit hash of the configuration repository when the state is set.|
|status|string|false|none|The status of the configuration layer.|
|last_updated|string(date-time)|false|read-only|The date/time when the state was last updated in RFC 3339 format.|
|session_name|string|false|none|The name of the CFS session that last configured the component.|

#### Enumerated Values

|Property|Value|
|---|---|
|status|applied|
|status|failed|
|status|skipped|

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
|state|[[V2ConfigurationStateLayer](#schemav2configurationstatelayer)]|false|none|Information about the desired config and status of the layers|
|stateAppend|object|false|write-only|A single state that will be appended to the list of current states.|
|» cloneUrl|string|false|none|The clone URL of the configuration content repository.|
|» playbook|string|false|none|The Ansible playbook to run.|
|» commit|string|false|none|The commit hash of the configuration repository when the state is set.|
|» sessionName|string|false|none|The name of the CFS session that last configured the component.|
|desiredConfig|string|false|none|A reference to a configuration|
|desiredState|[[V2ConfigurationStateLayer](#schemav2configurationstatelayer)]|false|read-only|Information about the desired config and status of the layers|
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

<h2 id="tocS_V3ComponentData">V3ComponentData</h2>
<!-- backwards compatibility -->
<a id="schemav3componentdata"></a>
<a id="schema_V3ComponentData"></a>
<a id="tocSv3componentdata"></a>
<a id="tocsv3componentdata"></a>

```json
{
  "id": "string",
  "state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "last_updated": "2019-07-28T03:26:00Z",
      "session_name": "string"
    }
  ],
  "state_append": {
    "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
    "playbook": "site.yml",
    "commit": "string",
    "status": "applied",
    "session_name": "string"
  },
  "desired_state": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "last_updated": "2019-07-28T03:26:00Z",
      "session_name": "string"
    }
  ],
  "desired_config": "string",
  "error_count": 0,
  "retry_policy": 0,
  "enabled": true,
  "configuration_status": "unconfigured",
  "tags": {
    "property1": "string",
    "property2": "string"
  },
  "logs": "string"
}

```

The configuration state and desired state for a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string|false|none|The component's id. e.g. xname for hardware components|
|state|[[V3ConfigurationStateLayer](#schemav3configurationstatelayer)]|false|none|Information about the desired config and status of the layers|
|state_append|object|false|write-only|A single state that will be appended to the list of current states.|
|» clone_url|string|false|none|The clone URL of the configuration content repository.|
|» playbook|string|false|none|The Ansible playbook to run.|
|» commit|string|false|none|The commit hash of the configuration repository when the state is set.|
|» status|string|false|none|The status of the configuration layer.|
|» session_name|string|false|none|The name of the CFS session that last configured the component.|
|desired_state|[[V3ConfigurationStateLayer](#schemav3configurationstatelayer)]|false|read-only|Information about the desired config and status of the layers|
|desired_config|string|false|none|A reference to a configuration|
|error_count|integer|false|none|The count of failed configuration attempts.|
|retry_policy|integer|false|none|The maximum number retries per component when configuration fails.|
|enabled|boolean|false|none|A flag indicating if the component should be scheduled for configuration.|
|configuration_status|string|false|read-only|A summary of the component's configuration state.|
|tags|object|false|none|A collection of key-value pairs containing descriptive information for the component, such as information about the component owner.|
|» **additionalProperties**|string|false|none|none|
|logs|string|false|read-only|The link to the ARA UI with logs for this component|

#### Enumerated Values

|Property|Value|
|---|---|
|status|applied|
|status|failed|
|status|skipped|
|configuration_status|unconfigured|
|configuration_status|pending|
|configuration_status|failed|
|configuration_status|configured|

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

<h2 id="tocS_V3ComponentDataArray">V3ComponentDataArray</h2>
<!-- backwards compatibility -->
<a id="schemav3componentdataarray"></a>
<a id="schema_V3ComponentDataArray"></a>
<a id="tocSv3componentdataarray"></a>
<a id="tocsv3componentdataarray"></a>

```json
[
  {
    "id": "string",
    "state": [
      {
        "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "status": "applied",
        "last_updated": "2019-07-28T03:26:00Z",
        "session_name": "string"
      }
    ],
    "state_append": {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "session_name": "string"
    },
    "desired_state": [
      {
        "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "status": "applied",
        "last_updated": "2019-07-28T03:26:00Z",
        "session_name": "string"
      }
    ],
    "desired_config": "string",
    "error_count": 0,
    "retry_policy": 0,
    "enabled": true,
    "configuration_status": "unconfigured",
    "tags": {
      "property1": "string",
      "property2": "string"
    },
    "logs": "string"
  }
]

```

An array of component configurations.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[V3ComponentData](#schemav3componentdata)]|false|none|An array of component configurations.|

<h2 id="tocS_V3ComponentDataCollection">V3ComponentDataCollection</h2>
<!-- backwards compatibility -->
<a id="schemav3componentdatacollection"></a>
<a id="schema_V3ComponentDataCollection"></a>
<a id="tocSv3componentdatacollection"></a>
<a id="tocsv3componentdatacollection"></a>

```json
{
  "components": [
    {
      "id": "string",
      "state": [
        {
          "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
          "playbook": "site.yml",
          "commit": "string",
          "status": "applied",
          "last_updated": "2019-07-28T03:26:00Z",
          "session_name": "string"
        }
      ],
      "state_append": {
        "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "status": "applied",
        "session_name": "string"
      },
      "desired_state": [
        {
          "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
          "playbook": "site.yml",
          "commit": "string",
          "status": "applied",
          "last_updated": "2019-07-28T03:26:00Z",
          "session_name": "string"
        }
      ],
      "desired_config": "string",
      "error_count": 0,
      "retry_policy": 0,
      "enabled": true,
      "configuration_status": "unconfigured",
      "tags": {
        "property1": "string",
        "property2": "string"
      },
      "logs": "string"
    }
  ],
  "next": {
    "limit": 0,
    "after_id": "string"
  }
}

```

A collection of component data.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|components|[[V3ComponentData](#schemav3componentdata)]|false|none|[The configuration state and desired state for a component.<br>]|
|next|[V3NextData](#schemav3nextdata)|false|none|Information for requesting the next page of data|

<h2 id="tocS_V3ComponentIdCollection">V3ComponentIdCollection</h2>
<!-- backwards compatibility -->
<a id="schemav3componentidcollection"></a>
<a id="schema_V3ComponentIdCollection"></a>
<a id="tocSv3componentidcollection"></a>
<a id="tocsv3componentidcollection"></a>

```json
{
  "component_ids": [
    "string"
  ]
}

```

A collection of component ids.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|component_ids|[string]|false|none|none|

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

<h2 id="tocS_V3ComponentsUpdate">V3ComponentsUpdate</h2>
<!-- backwards compatibility -->
<a id="schemav3componentsupdate"></a>
<a id="schema_V3ComponentsUpdate"></a>
<a id="tocSv3componentsupdate"></a>
<a id="tocsv3componentsupdate"></a>

```json
{
  "patch": {
    "id": "string",
    "state": [
      {
        "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "status": "applied",
        "last_updated": "2019-07-28T03:26:00Z",
        "session_name": "string"
      }
    ],
    "state_append": {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
      "playbook": "site.yml",
      "commit": "string",
      "status": "applied",
      "session_name": "string"
    },
    "desired_state": [
      {
        "clone_url": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
        "playbook": "site.yml",
        "commit": "string",
        "status": "applied",
        "last_updated": "2019-07-28T03:26:00Z",
        "session_name": "string"
      }
    ],
    "desired_config": "string",
    "error_count": 0,
    "retry_policy": 0,
    "enabled": true,
    "configuration_status": "unconfigured",
    "tags": {
      "property1": "string",
      "property2": "string"
    },
    "logs": "string"
  },
  "filters": {
    "ids": "string",
    "status": "unconfigured",
    "enabled": true,
    "config_name": "string",
    "tags": "string"
  }
}

```

Information for patching multiple components.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|patch|[V3ComponentData](#schemav3componentdata)|true|none|The configuration state and desired state for a component.|
|filters|[V3ComponentsFilter](#schemav3componentsfilter)|true|none|Information for patching multiple components.|

<h2 id="tocS_V3SourceCredentials">V3SourceCredentials</h2>
<!-- backwards compatibility -->
<a id="schemav3sourcecredentials"></a>
<a id="schema_V3SourceCredentials"></a>
<a id="tocSv3sourcecredentials"></a>
<a id="tocsv3sourcecredentials"></a>

```json
{
  "authentication_method": "password",
  "secret_name": "string",
  "username": "string",
  "password": "string"
}

```

Information on a secret containing the username and password for accessing the git content

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|authentication_method|string|false|none|The git authentication method used.|
|secret_name|string|false|read-only|The name of the credentials vault secret.|
|username|string|false|write-only|The username for authenticating to git|
|password|string|false|write-only|The password for authenticating to git|

#### Enumerated Values

|Property|Value|
|---|---|
|authentication_method|password|

<h2 id="tocS_V3SourceCert">V3SourceCert</h2>
<!-- backwards compatibility -->
<a id="schemav3sourcecert"></a>
<a id="schema_V3SourceCert"></a>
<a id="tocSv3sourcecert"></a>
<a id="tocsv3sourcecert"></a>

```json
{
  "configmap_name": "string",
  "configmap_namespace": "string"
}

```

Information on a configmap containing a CA certificate for authenticating to git

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|configmap_name|string|true|none|The name of the configmap containing a necessary CA cert.|
|configmap_namespace|string|false|none|The namespace of the CA cert configmap in kubernetes.|

<h2 id="tocS_V3SourceData">V3SourceData</h2>
<!-- backwards compatibility -->
<a id="schemav3sourcedata"></a>
<a id="schema_V3SourceData"></a>
<a id="tocSv3sourcedata"></a>
<a id="tocsv3sourcedata"></a>

```json
{
  "name": "sample-source",
  "description": "string",
  "last_updated": "2019-07-28T03:26:00Z",
  "clone_url": "string",
  "credentials": {
    "authentication_method": "password",
    "secret_name": "string",
    "username": "string",
    "password": "string"
  },
  "ca_cert": {
    "configmap_name": "string",
    "configmap_namespace": "string"
  }
}

```

Information for retrieving git content from a source.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|The name of the source.  This field is optional and will default to the clone_url if not specified.|
|description|string|false|none|A user-defined description. This field is not used by CFS.|
|last_updated|string(date-time)|false|read-only|The date/time when the state was last updated in RFC 3339 format.|
|clone_url|string|false|none|The url to access the git content|
|credentials|[V3SourceCredentials](#schemav3sourcecredentials)|false|none|Information on a secret containing the username and password for accessing the git content|
|ca_cert|[V3SourceCert](#schemav3sourcecert)|false|none|Information on a configmap containing a CA certificate for authenticating to git|

<h2 id="tocS_V3SourceDataCollection">V3SourceDataCollection</h2>
<!-- backwards compatibility -->
<a id="schemav3sourcedatacollection"></a>
<a id="schema_V3SourceDataCollection"></a>
<a id="tocSv3sourcedatacollection"></a>
<a id="tocsv3sourcedatacollection"></a>

```json
{
  "sources": [
    {
      "name": "sample-source",
      "description": "string",
      "last_updated": "2019-07-28T03:26:00Z",
      "clone_url": "string",
      "credentials": {
        "authentication_method": "password",
        "secret_name": "string",
        "username": "string",
        "password": "string"
      },
      "ca_cert": {
        "configmap_name": "string",
        "configmap_namespace": "string"
      }
    }
  ],
  "next": {
    "limit": 0,
    "after_id": "string"
  }
}

```

A collection of source data.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|sources|[[V3SourceData](#schemav3sourcedata)]|false|none|[Information for retrieving git content from a source.]|
|next|[V3NextData](#schemav3nextdata)|false|none|Information for requesting the next page of data|

<h2 id="tocS_V3SourceCreateCredentials">V3SourceCreateCredentials</h2>
<!-- backwards compatibility -->
<a id="schemav3sourcecreatecredentials"></a>
<a id="schema_V3SourceCreateCredentials"></a>
<a id="tocSv3sourcecreatecredentials"></a>
<a id="tocsv3sourcecreatecredentials"></a>

```json
{
  "authentication_method": "password",
  "username": "string",
  "password": "string"
}

```

Information for retrieving the git credentials

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|authentication_method|string|false|none|The git authentication method used.|
|username|string|true|write-only|The username for authenticating to git|
|password|string|true|write-only|The password for authenticating to git|

#### Enumerated Values

|Property|Value|
|---|---|
|authentication_method|password|

<h2 id="tocS_V3SourceCreateData">V3SourceCreateData</h2>
<!-- backwards compatibility -->
<a id="schemav3sourcecreatedata"></a>
<a id="schema_V3SourceCreateData"></a>
<a id="tocSv3sourcecreatedata"></a>
<a id="tocsv3sourcecreatedata"></a>

```json
{
  "name": "sample-source",
  "description": "string",
  "clone_url": "string",
  "credentials": {
    "authentication_method": "password",
    "username": "string",
    "password": "string"
  },
  "ca_cert": {
    "configmap_name": "string",
    "configmap_namespace": "string"
  }
}

```

Information for retrieving git content from a source.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|The name of the source.  This field is optional and will default to the clone_url if not specified.|
|description|string|false|none|A user-defined description. This field is not used by CFS.|
|clone_url|string|true|none|The url to access the git content|
|credentials|[V3SourceCreateCredentials](#schemav3sourcecreatecredentials)|true|none|Information for retrieving the git credentials|
|ca_cert|[V3SourceCert](#schemav3sourcecert)|false|none|Information on a configmap containing a CA certificate for authenticating to git|

<h2 id="tocS_V3SourceUpdateData">V3SourceUpdateData</h2>
<!-- backwards compatibility -->
<a id="schemav3sourceupdatedata"></a>
<a id="schema_V3SourceUpdateData"></a>
<a id="tocSv3sourceupdatedata"></a>
<a id="tocsv3sourceupdatedata"></a>

```json
{
  "description": "string",
  "clone_url": "string",
  "credentials": {
    "authentication_method": "password",
    "secret_name": "string",
    "username": "string",
    "password": "string"
  },
  "ca_cert": {
    "configmap_name": "string",
    "configmap_namespace": "string"
  }
}

```

Information for retrieving git content from a source.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|description|string|false|none|A user-defined description. This field is not used by CFS.|
|clone_url|string|false|none|The url to access the git content|
|credentials|[V3SourceCredentials](#schemav3sourcecredentials)|false|none|Information on a secret containing the username and password for accessing the git content|
|ca_cert|[V3SourceCert](#schemav3sourcecert)|false|none|Information on a configmap containing a CA certificate for authenticating to git|

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

