<!-- Generator: Widdershins v4.0.1 -->

<h1 id="user-access-service">User Access Service v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The User Access Service (UAS) creates and deletes
User Access Instances (UAIs). The UAI is a containerized
SSHd environment, built using a specific OS as a base, and
contains libraries, commands, and utilities necessary for application
development.

A user may ssh to a UAI in order to build, run, and debug applications.
The available images and volumes are configured by a system administrator.
The UAI runs on a non-compute node.

## Resources

### /images

An image, identified by its *imagename*, is a UAI container image.
There is potential for different containerized images to be available,
each built using different components/versions.

### /mgr-info

Return the version of this service.

### /uas

Create, delete, or list the User Access Instance(s) belonging to
the requesting user.  When a user requests a new UAI, the UAS
service returns status and connection information about the
newly created UAI or previously created UAIs.

### /uais

List or delete User Access Instance(s).  The operations here are
a subset of what is available in /admin/uais, which provides more
flexible parameterization of searches and deletes.  That path should
be used instead of this.  This path is deprecated but will be kept
for the foreseeable future to support legacy procedures and code.

### /admin/uais

List, retrieve, create, and delete UAIs for all users administratively.
This API path permits an administrator or authorized application to
create UAIs of a specified class for specified users (as opposed to
only creating UAIs for the calling user).  It also permits an
administrator or authorized application to list running UAIs optionally
filtered by user or class and to retrieve information about any given
UAI.  Finally it permits an administrator or authorized application to
delete any given UAI.

### /admin/config/images

This is where an administrator can list, create, get, or delete UAI
image entries in the list of available container image names.

### /admin/config/volumes

This is where an administrator can list, create, get, modify, or
delete entries in the list of available volumes.

### /admin/config/resources

This is where an administrator can list, create, get, modify, or
delete resource limit / request configurations that can be used on
UAI / Broker Classes to specify Kubernetes limits for UAIs of a given
class.

### /admin/config/classes

This is where an administrator can list, create, get, modify, or
delete UAI / Broker Class definitions.  UAI / Broker Classes
provide templates for different UAI or Broker configurations,
allowing an administrator to assign specific volumes, resource
configurations, and images to all UAIs or brokers created using
a given class.

## Workflows

### Single User Workflow

The single user workflow allows individual users to create UAIs
directly through the UAS API that run on behalf of the creating
user and are controlled by the creating user.  To be authorized as
a creating user or to use a UAI in this workflow, a user must have
Linux user attributes configured in the API Gateway authenticator:
uidNumber, gidNumber, userName, name, homeDirectory and
loginShell.  The user may then authenticate with the API Gateway
authenticator and make the calls in this workflow to create and
manage UAIs owned by that user.

There are two modes of operation of the single user workflow,
which are determined by the configuration of the UAS.  The default
mode preserves legacy behavior in which creating a UAI using a
POST operation to the /uas path creates a UAI belonging to the
authenticated user using all configured volumes, the default
resource limits and requests on the UAI Kubernetes namespace, and
the specified (or default) UAI image.  This happens if no default
Class is configured (see Administrative Workflow).  If a
default Class is configured, a POST on the /uas path creates a
UAI using the UAI image, volume list, and resource limits and
requests (if any) configured in the default Class.

#### GET /uas

Get the list of available, user-specific UAIs.

#### POST /uas

Request to create a new User Access Instance (UAI).
When an authenticated user requests a new UAI, the User Access
Service returns status and connection information for the newly
created UAI, which will be available via ssh.
Most properties of UAI are static for the life of a UAI.
UAIs are not shared - they do not have multiple owners.

#### ssh to the new UAI

Build, run, debug applications.

#### DELETE /uas

Cleanup your own UAI.  This operation is restricted to owner of the UAI.

### Administrative Workflow

The Administrative workflow covers two activities: management of UAIs for
users and configuration of the UAS resources used in the creation of UAIs.

#### UAI Management

Administrative UAI Management consists of creating, listing,
retrieving and deleting UAIs for use by specified users.  It is
supported by the following operations:

#### GET /admin/uais

Retrieve a list of UAIs with all their attributes and status, optionally
filtered by the owning user and / or the class-id used to create the UAI.

#### Get /admin/uais/{uai_name}

Retrieve the attributes and status of a specified UAI by name.

#### POST /admin/uais

Create a UAI for a specified user, with a specified Class, /etc/password
string, and SSH public-key.

#### UAS Configuration

UAS Configuration covers the following:

* UAI images
* Volume Mounts
* Resource Limits and Requests
* UAI / Broker Classes

UAI images are the container images used to create UAIs.  In the
Single User Workflow (above) when no default Class is defined,
the user can request a specific UAI image to be used.  In the
Administrative Workflow, a UAI image can be associated with a UAI / Broker
Class and will then be used to create any UAI based on that class.
At most 1 UAI image may be marked as the 'default' image, which
will cause it to be used when creating a UAI in the Single User
Workflow if no image is specified in the POST on the /uas path and
no default Class is configured.

Volume Mounts are used in UAIs to make external data available to
the UAI container.  More information about different types of
Volume Mounts can be found in the Kubernetes documentation.  In
the Single User workflow, when no default Class is configured,
all configured volume mounts are mounted on any UAI created. Each
UAI / Broker Class contains a list of volume mounts which can be any subset
of the total set configured.  When a UAI is created using a UAI / Broker
Class, either administratively or via a default Class in the
single user workflow, only those volumes listed in the Class
are mounted in the resulting UAI.

Resource Limit / Request configurations allow a UAI to override
the default Kubernetes resource limits and requests configured on
the UAI Kubernetes namespace.  For more information on Kubernetes
resource limits and requests, see the Kubernetes documentation.  A
Resource Limit / Request configuration can be associated with a
UAI / Broker Class, in which case any UAI created using that class, either
administratively or using the single user workflow and a default
UAI / Broker Class, will use the specified resource limits and requests
instead of the UAI namespace default setting.

UAI / Broker Classes allow administrators to define templates for creating
UAIs that define the UAI image to be used, the list of Volume
Mounts to be mounted in the UAI and the Resource Limits and
Requests to be used when scheduling the UAI.  At most one UAI / Broker
Class may be marked as 'default' in which case it will be used
unconditionally for all UAIs created using the Single User
Workflow.

#### GET /images

Get a list of container images available for use by a UAI.

#### GET /admin/config/volumes

Get a list of volumes available for use by UAIs and UAI / Broker Classes

#### GET /admin/config/images

Get a list of images available for creating UAIs and UAI / Broker Classes

#### GET /admin/config/resources

Get a list of resource limit / request configurations available for
creating UAI / Broker Classes

#### GET /admin/config/classes

Get a list of available UAI / Broker Classes

#### POST /admin/config/volumes

Add a volume to the list of volumes that will be mounted in new UAIs.

#### POST /admin/config/images

Add image name to list of valid images.

#### POST /admin/config/resources

Create a resource limit / request configuration that can be used for
creating UAI / Broker Classes

#### POST /admin/config/classes

Create a new UAI / Broker Class

#### GET /admin/config/images/{image_id}

Get information about a specific image available for making UAIs.

#### GET /admin/config/volumes/{volume-id}

Get information about a specific volume used in UAIs

#### GET /admin/config/resources/{resource_id}

Get information about a specific resource limit / request configuration
for creating UAI / Broker Classes

#### GET /admin/config/classes/{class_id}

Get information about a specific UAI / Broker Class

#### PATCH /admin/config/images/{image_id}

Update the entry for the specified image in the list of UAI
container images.

#### PATCH /admin/config/volumes/{volume_id}

Update the entry for the specified volume in the list of volumes
mounted in UAI containers.

#### PATCH /admin/config/resources/{resource_id}

Update the contents of a specific resource limit / request configuration
for creating UAI / Broker Classes

#### PATCH /admin/config/classes/{class_id}

Update the contents of a specific UAI / Broker Class

#### DELETE /admin/config/images/{image_id}

Delete the specified image from the list of available UAI
container images.

#### DELETE /admin/config/volumes/{volume_id}

Delete the specified volume from the list of available volumes.

#### DELETE /admin/config/resources/{resource_id}

Delete the specified resource limit / request configuration from the
list of available choices.

Base URLs:

* <a href="/apis/uas-mgr/v1">/apis/uas-mgr/v1</a>

<h1 id="user-access-service-versions">versions</h1>

## root_get

<a id="opIdroot_get"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/ HTTP/1.1

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/

```

```python
import requests

r = requests.get('/apis/uas-mgr/v1/')

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /`

*Return supported UAS API versions*

Return supported UAS API versions.

<h3 id="root_get-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Version response|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="user-access-service-uas">uas</h1>

## get_uais_for_user

<a id="opIdget_uais_for_user"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/uas HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/uas \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/uas', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/uas", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /uas`

*List UAIs*

List all available UAIs for username.

> Example responses

> 200 Response

```json
[
  {
    "uai_name": "uai-swilliams-cc09d2d2",
    "username": "swilliams",
    "class_id": "83156ef8-4286-4d57-8ffa-46ebf6c8f8b5",
    "resource_id": "6f66edda-625f-4be3-b563-dca5844c85cf",
    "image_id": "32ab9d45-f904-40f8-80a0-0881969a4f6e",
    "public_ip": false,
    "publickey": "/Users/user/.ssh/id_rsa.pub",
    "uai_img": "uai_img",
    "uai_status": "Running",
    "uai_reason": "Deploying",
    "uai_host": "ncn-w001",
    "uai_age": "13d8h"
  }
]
```

<h3 id="get_uais_for_user-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|Inline|

<h3 id="get_uais_for_user-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[UAI](#schemauai)]|false|none|none|
|» uai_name|string|false|none|none|
|» username|string|false|none|none|
|» publickey|string|false|none|none|
|» class_id|string|false|none|none|
|» public_ip|boolean|false|none|none|
|» resource_id|string|false|none|none|
|» image_id|string|false|none|none|
|» uai_img|string|false|none|none|
|» uai_status|string|false|none|none|
|» uai_msg|string|false|none|none|
|» uai_connect_string|string|false|none|none|
|» uai_portmap|object|false|none|none|
|»» **additionalProperties**|integer|false|none|none|
|» uai_host|string|false|none|none|
|» uai_age|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## create_uai

<a id="opIdcreate_uai"></a>

> Code samples

```http
POST /apis/uas-mgr/v1/uas HTTP/1.1

Content-Type: multipart/form-data
Accept: application/json

```

```shell
# You can also use wget
curl -X POST /apis/uas-mgr/v1/uas \
  -H 'Content-Type: multipart/form-data' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'multipart/form-data',
  'Accept': 'application/json'
}

r = requests.post('/apis/uas-mgr/v1/uas', headers = headers)

print(r.json())

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
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "/apis/uas-mgr/v1/uas", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /uas`

*Create a UAI*

Create a new UAI using the specified image.  It will be accessible
via ssh, and projected onto ports, if ports are specified.

> Body parameter

```yaml
publickey: string

```

<h3 id="create_uai-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|imagename|query|string|false|Image to use for UAI|
|ports|query|string|false|Additional ports to project from the UAI besides ssh. Restricted|
|body|body|object|false|none|
|» publickey|body|string(binary)|false|File containing public ssh key for the user|

#### Detailed descriptions

**ports**: Additional ports to project from the UAI besides ssh. Restricted
to ports 80, 443, and 8888.

> Example responses

> 201 Response

```json
{}
```

<h3 id="create_uai-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|UAI created|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Unable to create UAI|Inline|

<h3 id="create_uai-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

## delete_uai_by_name

<a id="opIddelete_uai_by_name"></a>

> Code samples

```http
DELETE /apis/uas-mgr/v1/uas?uai_list=uai-asdfgh098,uai-qwerty123 HTTP/1.1

```

```shell
# You can also use wget
curl -X DELETE /apis/uas-mgr/v1/uas?uai_list=uai-asdfgh098,uai-qwerty123

```

```python
import requests

r = requests.delete('/apis/uas-mgr/v1/uas', params={
  'uai_list': [
  "uai-asdfgh098",
  "uai-qwerty123"
]
})

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
    req, err := http.NewRequest("DELETE", "/apis/uas-mgr/v1/uas", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /uas`

*Delete a UAI*

Delete specified UAI(s). Takes a list of UAI names and deletes the
associated UAI(s).

<h3 id="delete_uai_by_name-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|uai_list|query|array[string]|true|comma-separated list of UAI names|

<h3 id="delete_uai_by_name-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAIs deleted|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Failed to delete UAI with {uai_id}|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="user-access-service-images">images</h1>

## get_uas_images

<a id="opIdget_uas_images"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/images HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/images \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /images`

*List UAS images*

List all available UAS images.

> Example responses

> 200 Response

```json
{
  "default_image": "string",
  "image_list": [
    "string"
  ]
}
```

<h3 id="get_uas_images-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAS Image List|[Image_list](#schemaimage_list)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|UAS Images not found|None|

<aside class="success">
This operation does not require authentication
</aside>

## create_uas_image_admin

<a id="opIdcreate_uas_image_admin"></a>

> Code samples

```http
POST /apis/uas-mgr/v1/admin/config/images?imagename=docker.local%2Fcray%2Fcray-uas-sles15sp1%3Alatest HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X POST /apis/uas-mgr/v1/admin/config/images?imagename=docker.local%2Fcray%2Fcray-uas-sles15sp1%3Alatest \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.post('/apis/uas-mgr/v1/admin/config/images', params={
  'imagename': 'docker.local/cray/cray-uas-sles15sp1:latest'
}, headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "/apis/uas-mgr/v1/admin/config/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /admin/config/images`

*Add an image*

Add valid image name to configuration. Does not create or
upload container image.  Optionally, set default.

<h3 id="create_uas_image_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|imagename|query|string|true|Image to create|
|default|query|boolean|false|default image (true/false)|

> Example responses

> 201 Response

```json
{
  "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
  "imagename": "node.local/uas-sles15:latest",
  "default": false
}
```

<h3 id="create_uas_image_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Image added|[Image](#schemaimage)|
|304|[Not Modified](https://tools.ietf.org/html/rfc7232#section-4.1)|Image not added|string|

<aside class="success">
This operation does not require authentication
</aside>

## get_uas_images_admin

<a id="opIdget_uas_images_admin"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/admin/config/images HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/admin/config/images \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/admin/config/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/admin/config/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /admin/config/images`

*List UAS images*

List all available UAS images.

> Example responses

> 200 Response

```json
[
  {
    "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
    "imagename": "node.local/uas-sles15:latest",
    "default": false
  }
]
```

<h3 id="get_uas_images_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAS Image List|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|UAS Images not found|None|

<h3 id="get_uas_images_admin-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Image](#schemaimage)]|false|none|none|
|» image_id|string|false|none|none|
|» imagename|string|false|none|none|
|» default|boolean|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## get_uas_image_admin

<a id="opIdget_uas_image_admin"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/admin/config/images/{image_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/admin/config/images/{image_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/admin/config/images/{image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/admin/config/images/{image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /admin/config/images/{image_id}`

*Get image info*

Get a description of the named image

<h3 id="get_uas_image_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|image_id|path|string|true|The image identifier (UUID) of the image to be retrieved from the|

#### Detailed descriptions

**image_id**: The image identifier (UUID) of the image to be retrieved from the
configuration.

> Example responses

> 200 Response

```json
{
  "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
  "imagename": "node.local/uas-sles15:latest",
  "default": false
}
```

<h3 id="get_uas_image_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAS Image|[Image](#schemaimage)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|UAS Image {image_id} not found|None|

<aside class="success">
This operation does not require authentication
</aside>

## update_uas_image_admin

<a id="opIdupdate_uas_image_admin"></a>

> Code samples

```http
PATCH /apis/uas-mgr/v1/admin/config/images/{image_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH /apis/uas-mgr/v1/admin/config/images/{image_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.patch('/apis/uas-mgr/v1/admin/config/images/{image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "/apis/uas-mgr/v1/admin/config/images/{image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /admin/config/images/{image_id}`

*Update an image*

Update an image, specifically this can set or unset the 'default' flag.

<h3 id="update_uas_image_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|image_id|path|string|true|The image identifier (UUID) of the image to be updated in the|
|imagename|query|string|false|The image name to be used by instances based on this UAI|
|default|query|boolean|false|default image (true/false)|

#### Detailed descriptions

**image_id**: The image identifier (UUID) of the image to be updated in the
configuration.

**imagename**: The image name to be used by instances based on this UAI
instance.

> Example responses

> 201 Response

```json
{
  "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
  "imagename": "node.local/uas-sles15:latest",
  "default": false
}
```

<h3 id="update_uas_image_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Image updated|[Image](#schemaimage)|
|304|[Not Modified](https://tools.ietf.org/html/rfc7232#section-4.1)|No changes made|[Image](#schemaimage)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_uas_image_admin

<a id="opIddelete_uas_image_admin"></a>

> Code samples

```http
DELETE /apis/uas-mgr/v1/admin/config/images/{image_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE /apis/uas-mgr/v1/admin/config/images/{image_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('/apis/uas-mgr/v1/admin/config/images/{image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "/apis/uas-mgr/v1/admin/config/images/{image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /admin/config/images/{image_id}`

*Remove the imagename from set of valid images*

Delete the named image from the set of valid UAI container images.

<h3 id="delete_uas_image_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|image_id|path|string|true|The image identifier (UUID) of the image to be deleted from the|

#### Detailed descriptions

**image_id**: The image identifier (UUID) of the image to be deleted from the
configuration.

> Example responses

> 200 Response

```json
{
  "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
  "imagename": "node.local/uas-sles15:latest",
  "default": false
}
```

<h3 id="delete_uas_image_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Image removed|[Image](#schemaimage)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Failed to delete image {image_id}|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="user-access-service-mgr-info">mgr-info</h1>

## get_uas_mgr_info

<a id="opIdget_uas_mgr_info"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/mgr-info HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/mgr-info \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/mgr-info', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/mgr-info", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /mgr-info`

*List UAS info*

Return User Access Service information.

> Example responses

> 200 Response

```json
{
  "service_name": "cray-uas-mgr",
  "version": "version"
}
```

<h3 id="get_uas_mgr_info-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAS-MGR Info|[UAS_mgr_info](#schemauas_mgr_info)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|UAS-MGR Info not found|Inline|

<h3 id="get_uas_mgr_info-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="user-access-service-uais">uais</h1>

## get_all_uais

<a id="opIdget_all_uais"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/uais HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/uais \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/uais', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/uais", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /uais`

*List UAIs*

List all UAIs on the system.  There is a more general purpose way to
list UAIs that implements a superset of this functionality under the
/admin/uais path.  This path is deprecated in favor of that path.

<h3 id="get_all_uais-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|username|query|string|false|List all UAIs matching this username|
|host|query|string|false|List all UAIs running on this host|

> Example responses

> 200 Response

```json
{}
```

<h3 id="get_all_uais-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAI List|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|No UAIs found|Inline|

<h3 id="get_all_uais-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_uais

<a id="opIddelete_all_uais"></a>

> Code samples

```http
DELETE /apis/uas-mgr/v1/uais HTTP/1.1

```

```shell
# You can also use wget
curl -X DELETE /apis/uas-mgr/v1/uais

```

```python
import requests

r = requests.delete('/apis/uas-mgr/v1/uais')

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
    req, err := http.NewRequest("DELETE", "/apis/uas-mgr/v1/uais", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /uais`

*Delete UAIs*

Delete all UAIs on the system.  There is a more general purpose version
of this operation under the /admin/uais path which implements a superset
of the functionality found here.  This path is deprecated in favor of
/admin/uais.

<h3 id="delete_all_uais-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|username|query|string|false|delete all UAIs matching this username|

<h3 id="delete_all_uais-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|All UAIs Deleted|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|No UAIs found|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="user-access-service-admin">admin</h1>

## get_uais_admin

<a id="opIdget_uais_admin"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/admin/uais HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/admin/uais \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/admin/uais', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/admin/uais", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /admin/uais`

*List all UAIs*

List all UAIs, optionally filtered by Class (specify the Class ID
in the call) and / or owning user (specify the username in the call).

<h3 id="get_uais_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|class_id|query|string|false|The class-id (UUID) of UAIs to retrieve.  If specified only UAIs|
|owner|query|string|false|The owning username of UAIs to retrieve.  If specified only UAIs|

#### Detailed descriptions

**class_id**: The class-id (UUID) of UAIs to retrieve.  If specified only UAIs
of this class will be returned.  If omitted, UAIs of all classes
and meeting all other filtering constraints will be returned.

**owner**: The owning username of UAIs to retrieve.  If specified only UAIs
owned by this user will be returned.  If omitted, UAIs owned by any
user and meeting all other filtering constraints will be returned.

> Example responses

> 200 Response

```json
[
  {
    "uai_name": "uai-swilliams-cc09d2d2",
    "username": "swilliams",
    "class_id": "83156ef8-4286-4d57-8ffa-46ebf6c8f8b5",
    "resource_id": "6f66edda-625f-4be3-b563-dca5844c85cf",
    "image_id": "32ab9d45-f904-40f8-80a0-0881969a4f6e",
    "public_ip": false,
    "publickey": "/Users/user/.ssh/id_rsa.pub",
    "uai_img": "uai_img",
    "uai_status": "Running",
    "uai_reason": "Deploying",
    "uai_host": "ncn-w001",
    "uai_age": "13d8h"
  }
]
```

<h3 id="get_uais_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAI List|Inline|

<h3 id="get_uais_admin-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[UAI](#schemauai)]|false|none|none|
|» uai_name|string|false|none|none|
|» username|string|false|none|none|
|» publickey|string|false|none|none|
|» class_id|string|false|none|none|
|» public_ip|boolean|false|none|none|
|» resource_id|string|false|none|none|
|» image_id|string|false|none|none|
|» uai_img|string|false|none|none|
|» uai_status|string|false|none|none|
|» uai_msg|string|false|none|none|
|» uai_connect_string|string|false|none|none|
|» uai_portmap|object|false|none|none|
|»» **additionalProperties**|integer|false|none|none|
|» uai_host|string|false|none|none|
|» uai_age|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## create_uai_admin

<a id="opIdcreate_uai_admin"></a>

> Code samples

```http
POST /apis/uas-mgr/v1/admin/uais HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X POST /apis/uas-mgr/v1/admin/uais \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.post('/apis/uas-mgr/v1/admin/uais', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "/apis/uas-mgr/v1/admin/uais", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /admin/uais`

*Create a UAI administratively*

Create a UAI of a specified Class for an (optionally) specified user,
providing the (optional) /etc/passwd string to be used for that user
in the UAI and the (optional) SSH public-key that will be used to
access the UAI by the user.

Both UAIs for use by users and Broker UAIs are consider UAIs within
this API.  Some attributes that apply to UAIs for use by users do not
apply to Broker UAIs because the function of a Broker UAI is different.

<h3 id="create_uai_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|class_id|query|string|false|The Class ID (UUID) of the class to be used as a template for|
|owner|query|string|false|The username of the owner of the UAI to be created.  The owner|
|passwd_str|query|string|false|The /etc/passwd style string describing the user inside the UAI.|
|publickey_str|query|string|false|The SSH Public key used to authorize use of the UAI through SSH.  This is a|
|uai_name|query|string|false|An optional name to be assigned to the UAI on creation.  If this is|

#### Detailed descriptions

**class_id**: The Class ID (UUID) of the class to be used as a template for
creating the UAI.  If this is omitted and a default Class is
configured, the default class will be used.  If a default class
is not configured, omitting this results in an error.

**owner**: The username of the owner of the UAI to be created.  The owner
may be omitted for Broker UAIs because Broker UAIs run as
UAS system services and allow SSH connections from any
user.  Alternatively, the username may be used to label a Broker
UAI as needed by the site.  Whether or not the username is used
within a UAI is determined by the code running in the UAI image.
Brokers UAIs will generally not be used in the running Broker UAI
but will be used in formatting the UAI name and similar activities.

**passwd_str**: The /etc/passwd style string describing the user inside the UAI.
The format is: `<name>::<uid>:<gid>::::<full-name>:<home-dir>:<shell>`
This can be omitted for Broker UAIs and UAIs that are connected to an
external authentication source like LDAP.

**publickey_str**: The SSH Public key used to authorize use of the UAI through SSH.  This is a
string in the form of a public key, for example the contents of an id_rsa.pub
file.

**uai_name**: An optional name to be assigned to the UAI on creation.  If this is
not specified, a default name of the form <owner>-uai-<short-uuid>
is used.  The UAI name is used both as the name of the UAI in the
UAS and as the external DNS hostname of a publicly accessible UAI.
If the requested UAI name is the same as an already running UAI,
no new UAI is created, but the information about the existing UAI
is returned.  UAI names may contain up to 63 lower case alphanumeric
or '-' characters, and must start and end with an alphanumeric
character.

> Example responses

> 201 Response

```json
{
  "uai_name": "uai-swilliams-cc09d2d2",
  "username": "swilliams",
  "class_id": "83156ef8-4286-4d57-8ffa-46ebf6c8f8b5",
  "resource_id": "6f66edda-625f-4be3-b563-dca5844c85cf",
  "image_id": "32ab9d45-f904-40f8-80a0-0881969a4f6e",
  "public_ip": false,
  "publickey": "/Users/user/.ssh/id_rsa.pub",
  "uai_img": "uai_img",
  "uai_status": "Running",
  "uai_reason": "Deploying",
  "uai_host": "ncn-w001",
  "uai_age": "13d8h"
}
```

<h3 id="create_uai_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|UAI Created|[UAI](#schemauai)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_uais_admin

<a id="opIddelete_uais_admin"></a>

> Code samples

```http
DELETE /apis/uas-mgr/v1/admin/uais HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE /apis/uas-mgr/v1/admin/uais \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('/apis/uas-mgr/v1/admin/uais', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "/apis/uas-mgr/v1/admin/uais", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /admin/uais`

*Delete all or selected UAIs*

Delete UAIs, optionally selecting by Class (specify the Class
ID in the call) and / or owning user (specify the username in
the call). Alternatively, delete a list of UAI names.  If a
list of UAI names is provided, the other constraints are not
applied. If no selection is done, delete all UAIs on the
system.

<h3 id="delete_uais_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|class_id|query|string|false|The class-id (UUID) of UAIs to delete.  If specified only UAIs|
|owner|query|string|false|The owning username of UAIs to delete.  If specified only UAIs|
|uai_list|query|array[string]|false|Comma-separated list of UAI names.  If this is supplied 'owner'|

#### Detailed descriptions

**class_id**: The class-id (UUID) of UAIs to delete.  If specified only UAIs
of this class will be deleted.  If omitted, UAIs of all classes
and meeting the other selection criteria will be deleted.

**owner**: The owning username of UAIs to delete.  If specified only UAIs
owned by this user will be deleted.  If omitted, UAIs owned by any
user and meeting the other selection criteria will be deleted.

**uai_list**: Comma-separated list of UAI names.  If this is supplied 'owner'
and 'class-id' are ignored.

> Example responses

> 200 Response

```json
[
  {
    "uai_name": "uai-swilliams-cc09d2d2",
    "username": "swilliams",
    "class_id": "83156ef8-4286-4d57-8ffa-46ebf6c8f8b5",
    "resource_id": "6f66edda-625f-4be3-b563-dca5844c85cf",
    "image_id": "32ab9d45-f904-40f8-80a0-0881969a4f6e",
    "public_ip": false,
    "publickey": "/Users/user/.ssh/id_rsa.pub",
    "uai_img": "uai_img",
    "uai_status": "Running",
    "uai_reason": "Deploying",
    "uai_host": "ncn-w001",
    "uai_age": "13d8h"
  }
]
```

<h3 id="delete_uais_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAIs deleted|Inline|

<h3 id="delete_uais_admin-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[UAI](#schemauai)]|false|none|none|
|» uai_name|string|false|none|none|
|» username|string|false|none|none|
|» publickey|string|false|none|none|
|» class_id|string|false|none|none|
|» public_ip|boolean|false|none|none|
|» resource_id|string|false|none|none|
|» image_id|string|false|none|none|
|» uai_img|string|false|none|none|
|» uai_status|string|false|none|none|
|» uai_msg|string|false|none|none|
|» uai_connect_string|string|false|none|none|
|» uai_portmap|object|false|none|none|
|»» **additionalProperties**|integer|false|none|none|
|» uai_host|string|false|none|none|
|» uai_age|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## get_uai_admin

<a id="opIdget_uai_admin"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/admin/uais/{uai_name} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/admin/uais/{uai_name} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/admin/uais/{uai_name}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/admin/uais/{uai_name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /admin/uais/{uai_name}`

*Retrieve information on a UAI*

Retrieve information on the specified UAI.

<h3 id="get_uai_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|uai_name|path|string|true|The name of the UAI to retrieve.|

#### Detailed descriptions

**uai_name**: The name of the UAI to retrieve.

> Example responses

> 200 Response

```json
{
  "uai_name": "uai-swilliams-cc09d2d2",
  "username": "swilliams",
  "class_id": "83156ef8-4286-4d57-8ffa-46ebf6c8f8b5",
  "resource_id": "6f66edda-625f-4be3-b563-dca5844c85cf",
  "image_id": "32ab9d45-f904-40f8-80a0-0881969a4f6e",
  "public_ip": false,
  "publickey": "/Users/user/.ssh/id_rsa.pub",
  "uai_img": "uai_img",
  "uai_status": "Running",
  "uai_reason": "Deploying",
  "uai_host": "ncn-w001",
  "uai_age": "13d8h"
}
```

<h3 id="get_uai_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAI Description|[UAI](#schemauai)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|UAI not found|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="user-access-service-config">config</h1>

## delete_local_config_admin

<a id="opIddelete_local_config_admin"></a>

> Code samples

```http
DELETE /apis/uas-mgr/v1/admin/config HTTP/1.1

```

```shell
# You can also use wget
curl -X DELETE /apis/uas-mgr/v1/admin/config

```

```python
import requests

r = requests.delete('/apis/uas-mgr/v1/admin/config')

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
    req, err := http.NewRequest("DELETE", "/apis/uas-mgr/v1/admin/config", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /admin/config`

*Remove local configuration and revert to default configuration*

Remove any locally applied configuration (configuration applied through
the admin/config API) and revert to the default configuration that
is installed in the system.  This can be used both to reset to
factory defaults and to move to a new set of defaults if the existing
one is replaced.  All locally applied configuration will be lost if
with this request.

<h3 id="delete_local_config_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Local configuration reset to defaults|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="user-access-service-volumes">volumes</h1>

## create_uas_volume_admin

<a id="opIdcreate_uas_volume_admin"></a>

> Code samples

```http
POST /apis/uas-mgr/v1/admin/config/volumes?volumename=my-mount&mount_path=%2Fmnt%2Ftest&volume_description=%7B%20%22config_map%22%3A%20%7B%20%22name%22%3A%20%22my-configmap%22%20%7D%20%7D HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X POST /apis/uas-mgr/v1/admin/config/volumes?volumename=my-mount&mount_path=%2Fmnt%2Ftest&volume_description=%7B%20%22config_map%22%3A%20%7B%20%22name%22%3A%20%22my-configmap%22%20%7D%20%7D \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.post('/apis/uas-mgr/v1/admin/config/volumes', params={
  'volumename': 'my-mount',  'mount_path': '/mnt/test',  'volume_description': '{ "config_map": { "name": "my-configmap" } }'
}, headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "/apis/uas-mgr/v1/admin/config/volumes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /admin/config/volumes`

*Add a volume*

Add a volume to the volume list in the configuration.  The
volume list is used during UAI creation, so this request only
applies to UAIs subsequently created.  Modifying the volume
list does not affect existing UAIs.

<h3 id="create_uas_volume_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|volumename|query|string|true|Volume to create|
|mount_path|query|string|true|Mount path inside the UAI|
|volume_description|query|string|true|JSON description of a Kubernetes volume to be|

#### Detailed descriptions

**volume_description**: JSON description of a Kubernetes volume to be
mounted in UAI containers.  This is the JSON
equivalent of whatever YAML you would normally
apply to Kubernetes to attach the kind of volume
you want to a pod.  There are many kinds of
volumes, the examples given here illustrate some
options:
{
  "host_path": {
    "path": "/data",
    "type": "DirectoryOrCreate"
  }
}
or
{
  "secret": {
    "secretName": "my-secret"
  }
}
or
{
  "config_map": {
    "name": "my-configmap",
    "items": {
      "key": "flaps",
      "path": "flaps"
    }
  }
}

> Example responses

> 201 Response

```json
{
  "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "volumename": "my-mount",
  "mount_path": "/mnt/test",
  "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
}
```

<h3 id="create_uas_volume_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Volume added|[Volume](#schemavolume)|
|304|[Not Modified](https://tools.ietf.org/html/rfc7232#section-4.1)|Volume not added|string|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Invalid type for host, volume not added|string|

<aside class="success">
This operation does not require authentication
</aside>

## get_uas_volumes_admin

<a id="opIdget_uas_volumes_admin"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/admin/config/volumes HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/admin/config/volumes \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/admin/config/volumes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/admin/config/volumes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /admin/config/volumes`

*List volumes*

The volume list in the configuration is used during UAI creation.
This list does not necessarily relate to UAIs previously created.
This call does not affect the k8s volume itself.

> Example responses

> 200 Response

```json
[
  {
    "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
    "volumename": "my-mount",
    "mount_path": "/mnt/test",
    "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
  }
]
```

<h3 id="get_uas_volumes_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAS Volume list|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|UAS Volumes not found|None|

<h3 id="get_uas_volumes_admin-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Volume](#schemavolume)]|false|none|none|
|» volume_id|string|false|none|none|
|» volumename|string|false|none|none|
|» mount_path|string|false|none|none|
|» volume_description|object|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## get_uas_volume_admin

<a id="opIdget_uas_volume_admin"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/admin/config/volumes/{volume_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/admin/config/volumes/{volume_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/admin/config/volumes/{volume_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/admin/config/volumes/{volume_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /admin/config/volumes/{volume_id}`

*Get volume info for volume_id*

Get volume info for volume_id

<h3 id="get_uas_volume_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|volume_id|path|string|true|The volume identifier (UUID) of the volume to retrieve|

#### Detailed descriptions

**volume_id**: The volume identifier (UUID) of the volume to retrieve
from the configuration.

> Example responses

> 200 Response

```json
{
  "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "volumename": "my-mount",
  "mount_path": "/mnt/test",
  "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
}
```

<h3 id="get_uas_volume_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAS Volume|[Volume](#schemavolume)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|UAS Volume {volumename} not found|None|

<aside class="success">
This operation does not require authentication
</aside>

## update_uas_volume_admin

<a id="opIdupdate_uas_volume_admin"></a>

> Code samples

```http
PATCH /apis/uas-mgr/v1/admin/config/volumes/{volume_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH /apis/uas-mgr/v1/admin/config/volumes/{volume_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.patch('/apis/uas-mgr/v1/admin/config/volumes/{volume_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "/apis/uas-mgr/v1/admin/config/volumes/{volume_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /admin/config/volumes/{volume_id}`

*Update a volume*

Update a volume to be mounted in UAS images. This has no
effect on running UAIs and does not change the volume itself
in any way, but it can modify the relationship between
future UAI containers and the volume.

<h3 id="update_uas_volume_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|volume_id|path|string|true|The volume identifier (UUID) of the volume to update|
|volumename|query|string|false|The name of the volume as it is applied to the UAI|
|mount_path|query|string|false|Mount path for the volume inside the UAI|
|volume_description|query|string|false|JSON description of a Kubernetes volume to be|

#### Detailed descriptions

**volume_id**: The volume identifier (UUID) of the volume to update
in the configuration.

**volumename**: The name of the volume as it is applied to the UAI
Kubernetes pod.  Must conform to Kubernetes volume
naming conventions (see Kubernetes documentation for
details).

**volume_description**: JSON description of a Kubernetes volume to be
mounted in UAI containers.  This is the JSON
equivalent of whatever YAML you would normally
apply to Kubernetes to attach the kind of volume
you want to a pod.  There are many kinds of
volumes, the examples given here illustrate some
options:
{
  "host_path": {
    "path": "/data",
    "type": "DirectoryOrCreate"
  }
}
or
{
  "secret": {
    "secretName": "my-secret"
  }
}
or
{
  "config_map": {
    "name": "my-configmap",
    "items": {
      "key": "flaps",
      "path": "flaps"
    }
  }
}

> Example responses

> 201 Response

```json
{
  "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "volumename": "my-mount",
  "mount_path": "/mnt/test",
  "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
}
```

<h3 id="update_uas_volume_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Volume updated|[Volume](#schemavolume)|
|304|[Not Modified](https://tools.ietf.org/html/rfc7232#section-4.1)|No changes made|[Volume](#schemavolume)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Invalid type for host, volume not updated|string|

<aside class="success">
This operation does not require authentication
</aside>

## delete_uas_volume_admin

<a id="opIddelete_uas_volume_admin"></a>

> Code samples

```http
DELETE /apis/uas-mgr/v1/admin/config/volumes/{volume_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE /apis/uas-mgr/v1/admin/config/volumes/{volume_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('/apis/uas-mgr/v1/admin/config/volumes/{volume_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "/apis/uas-mgr/v1/admin/config/volumes/{volume_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /admin/config/volumes/{volume_id}`

*Remove volume from the volume list*

Does not affect existing UAIs.
Remove the volume from the list of valid volumes.
The actual volume itself is not affected in any way.

<h3 id="delete_uas_volume_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|volume_id|path|string|true|The volume identifier (UUID) of the volume to delete|

#### Detailed descriptions

**volume_id**: The volume identifier (UUID) of the volume to delete
from the configuration.

> Example responses

> 200 Response

```json
{
  "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "volumename": "my-mount",
  "mount_path": "/mnt/test",
  "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
}
```

<h3 id="delete_uas_volume_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Volume removed from list|[Volume](#schemavolume)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Failed to delete volume {volume_id}|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="user-access-service-resources">resources</h1>

## create_uas_resource_admin

<a id="opIdcreate_uas_resource_admin"></a>

> Code samples

```http
POST /apis/uas-mgr/v1/admin/config/resources HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X POST /apis/uas-mgr/v1/admin/config/resources \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.post('/apis/uas-mgr/v1/admin/config/resources', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "/apis/uas-mgr/v1/admin/config/resources", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /admin/config/resources`

*Add a resource limit / request configuration*

Add a new resource limit / request configuration for potential use in
creating Classes.  Resource limits and requests are described in
the Kubernetes documentation.

<h3 id="create_uas_resource_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|comment|query|string|false|A descriptive comment explaining the intended use of the resource|
|limit|query|string|false|JSON description of a Kubernetes resource limit to be applied to|
|request|query|string|false|JSON description of a Kubernetes resource request to be|

#### Detailed descriptions

**comment**: A descriptive comment explaining the intended use of the resource
limit / request configuration.  Defaults to no description.

**limit**: JSON description of a Kubernetes resource limit to be applied to
UAIs created using a UAI / Broker Class that references this resource
configuration.  This is the JSON equivalent of whatever you would
normally apply as a limit to a pod.  For example, to limit
a UAI to 300 Millicpus and 250 Mibibytes of memory:
{ "cpu": "300m", "memory": "250Mi" }

**request**: JSON description of a Kubernetes resource request to be
applied to UAIs created using a UAI / Broker Class that references
this resource configuration.  This is the JSON equivalent of
whatever you would normally apply as a request to a pod or
deployment.  For example, to request a UAI with 300
Millicpus and 250 Mibibytes of memory:
{ "cpu": "300m", "memory": "250Mi" }

> Example responses

> 201 Response

```json
{
  "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "comment": "A resource limit for UAIs that only launch jobs",
  "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
  "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
}
```

<h3 id="create_uas_resource_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Resource configuration added|[Resource](#schemaresource)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Invalid limit or request specified|string|

<aside class="success">
This operation does not require authentication
</aside>

## get_uas_resources_admin

<a id="opIdget_uas_resources_admin"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/admin/config/resources HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/admin/config/resources \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/admin/config/resources', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/admin/config/resources", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /admin/config/resources`

*List Resource Limit / Request Configurations*

List all available resource limit / request configurations

> Example responses

> 200 Response

```json
[
  {
    "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
    "comment": "A resource limit for UAIs that only launch jobs",
    "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
    "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
  }
]
```

<h3 id="get_uas_resources_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAS Resource Limit / Request Configuration List|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|UAS Resource Limit / Request Configuration  not found|None|

<h3 id="get_uas_resources_admin-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Resource](#schemaresource)]|false|none|none|
|» resource_id|string|false|none|none|
|» comment|string|false|none|none|
|» limit|string|false|none|none|
|» request|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## get_uas_resource_admin

<a id="opIdget_uas_resource_admin"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/admin/config/resources/{resource_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/admin/config/resources/{resource_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/admin/config/resources/{resource_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/admin/config/resources/{resource_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /admin/config/resources/{resource_id}`

*Get a Resource Limit / Request Configuration item*

Get a description of the specified resource limit / request
configuration item.

<h3 id="get_uas_resource_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|resource_id|path|string|true|The resource identifier (UUID) of the resource limit / request|

#### Detailed descriptions

**resource_id**: The resource identifier (UUID) of the resource limit / request
config to be retrieved from the configuration.

> Example responses

> 200 Response

```json
{
  "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "comment": "A resource limit for UAIs that only launch jobs",
  "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
  "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
}
```

<h3 id="get_uas_resource_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Resource Limit / Request Configuration Item|[Resource](#schemaresource)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Resource Configuration {resource_id} not found|None|

<aside class="success">
This operation does not require authentication
</aside>

## update_uas_resource_admin

<a id="opIdupdate_uas_resource_admin"></a>

> Code samples

```http
PATCH /apis/uas-mgr/v1/admin/config/resources/{resource_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH /apis/uas-mgr/v1/admin/config/resources/{resource_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.patch('/apis/uas-mgr/v1/admin/config/resources/{resource_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "/apis/uas-mgr/v1/admin/config/resources/{resource_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /admin/config/resources/{resource_id}`

*Update a Resource Limit / Request Configuration Item*

Update a resource limit / request configuration item.

<h3 id="update_uas_resource_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|resource_id|path|string|true|The resource identifier (UUID) of the resource limit / request config|
|comment|query|string|false|A descriptive comment explaining the intended use of the resource|
|limit|query|string|false|JSON description of a Kubernetes resource limit to be applied to|
|request|query|string|false|JSON description of a Kubernetes resource request to be|

#### Detailed descriptions

**resource_id**: The resource identifier (UUID) of the resource limit / request config
to be updated in the configuration.

**comment**: A descriptive comment explaining the intended use of the resource
limit / request configuration.  Defaults to no description.

**limit**: JSON description of a Kubernetes resource limit to be applied to
UAIs created using a UAI / Broker Class that references this resource
configuration.  This is the JSON equivalent of whatever you would
normally apply as a limit to a pod.  For example, to limit
a UAI to 300 Millicpus and 250 Mibibytes of memory:
{ "cpu": "300m", "memory": "250Mi" }

**request**: JSON description of a Kubernetes resource request to be
applied to UAIs created using a UAI / Broker Class that references
this resource configuration.  This is the JSON equivalent of
whatever you would normally apply as a request to a pod or
deployment.  For example, to request a UAI with 300
Millicpus and 250 Mibibytes of memory:
{ "cpu": "300m", "memory": "250Mi" }

> Example responses

> 201 Response

```json
{
  "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "comment": "A resource limit for UAIs that only launch jobs",
  "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
  "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
}
```

<h3 id="update_uas_resource_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|Resource updated|[Resource](#schemaresource)|
|304|[Not Modified](https://tools.ietf.org/html/rfc7232#section-4.1)|No changes made|[Resource](#schemaresource)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_uas_resource_admin

<a id="opIddelete_uas_resource_admin"></a>

> Code samples

```http
DELETE /apis/uas-mgr/v1/admin/config/resources/{resource_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE /apis/uas-mgr/v1/admin/config/resources/{resource_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('/apis/uas-mgr/v1/admin/config/resources/{resource_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "/apis/uas-mgr/v1/admin/config/resources/{resource_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /admin/config/resources/{resource_id}`

*Remove a Resource Limit / Request Configuration Item*

Delete the specified Resource Limit / Request configuration item from
the configuration.

<h3 id="delete_uas_resource_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|resource_id|path|string|true|The resource identifier (UUID) of the resource limit / request|

#### Detailed descriptions

**resource_id**: The resource identifier (UUID) of the resource limit / request
configuration to be removed from the configuration.

> Example responses

> 200 Response

```json
{
  "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "comment": "A resource limit for UAIs that only launch jobs",
  "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
  "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
}
```

<h3 id="delete_uas_resource_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Resource configuration removed|[Resource](#schemaresource)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Failed to delete resource configuration {resource_id}|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="user-access-service-classes">classes</h1>

## create_uas_class_admin

<a id="opIdcreate_uas_class_admin"></a>

> Code samples

```http
POST /apis/uas-mgr/v1/admin/config/classes?image_id=af4e59ab-6275-47f9-8f4a-90911eba3f9c HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X POST /apis/uas-mgr/v1/admin/config/classes?image_id=af4e59ab-6275-47f9-8f4a-90911eba3f9c \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.post('/apis/uas-mgr/v1/admin/config/classes', params={
  'image_id': 'af4e59ab-6275-47f9-8f4a-90911eba3f9c'
}, headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "/apis/uas-mgr/v1/admin/config/classes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /admin/config/classes`

*Add a UAI / Broker Class*

Add a new UAI class for use as a template to construct UAIs
administratively.

<h3 id="create_uas_class_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|comment|query|string|false|A descriptive comment explaining the intended use of the Class.|
|default|query|boolean|false|Optionally specify whether this is the default UAI / Broker|
|public_ip|query|boolean|false|A flag indicating whether a UAI or Broker created using this|
|image_id|query|string|true|The image-id of the image to be used in UAIs created from|
|priority_class_name|query|string|false|Optional Kubernetes priority class name to be assigned to|
|namespace|query|string|false|The K8s namespace where UAIs of this class run.  Defaults to the|
|opt_ports|query|string|false|A comma-separated list of port numbers on which software running in a|
|uai_creation_class|query|string|false|For Brokers only, the class ID (UUID)  used to create UAIs|
|uai_compute_network|query|boolean|false|A flag indicating whether a UAI or Broker created using this|
|resource_id|query|string|false|Optional resource-id of the resource limit / request configuration|
|volume_list|query|array[string]|false|Optional comma-separated list of volume-ids specifying the|
|tolerations|query|string|false|Optional JSON string containing a JSON list of JSON objects|
|timeout|query|string|false|Optional JSON string containing a timeout specification|
|service_account|query|string|false|Optional name of a Kubernetes service account to be assigned to|
|replicas|query|string|false|The number of UAI replicas created when a UAI of|

#### Detailed descriptions

**comment**: A descriptive comment explaining the intended use of the Class.
Defaults to no description.

**default**: Optionally specify whether this is the default UAI / Broker
Class. There can be at most one default Class in effect
at any given time.  If a default Class is present, then
UAIs created using the Single User Workflow will use that
Class instead of accepting an image name and using all
of the configured volume mounts and the UAI namespace
default resource configuration.  Additionally, UAIs created
in the Administrative Workflow without a specified class will
use the default Class.  Defaults to False if not specified.

Setting 'default' to true when another UAI / Broker Class is
currently the default will cause the new Class to become
the default and the previous default to stop being the default.

**public_ip**: A flag indicating whether a UAI or Broker created using this
class will present ports on a public IP address or only on a
cluster visible IP address.  If not provided, the default is
false, which makes resulting UAIs or Brokers visible only
within the cluster.

**image_id**: The image-id of the image to be used in UAIs created from
this UAI / Broker Class.

**priority_class_name**: Optional Kubernetes priority class name to be assigned to
all UAIs / Brokers using this class.  The priority class
name is used in Kubernetes to determine scheduling
(i.e. node placement) priority in case of resource
exhaustion and to associate resource quotas with Kubernetes
pods.  If this is omitted, the default class name 'uai-priority'
is used.

**namespace**: The K8s namespace where UAIs of this class run.  Defaults to the
configured UAI namespace.

**opt_ports**: A comma-separated list of port numbers on which software running in a
UAI created using this class may listen.  Unlike `ports` in the
Single User UAI creation API, the port numbers here are not constrained
by any configured range of available ports.  Any valid port number is
legal.

**uai_creation_class**: For Brokers only, the class ID (UUID)  used to create UAIs
created by Brokers of this class.  If this is not specified
on a Broker, and there is a default class specified, the default
class will be used.  If there is no default class, the
broker will fail to create UAIs.  If this is specified on a
non-Broker UAI it has no meaningful effect.

**uai_compute_network**: A flag indicating whether a UAI or Broker created using this
class will include a network route to compute nodes. This option
is likely not necessary for Brokers. Single User UAIs will require
this flag for job launch capabilities.

**resource_id**: Optional resource-id of the resource limit / request configuration
to be used with UAIs created using this Class.  Default is no
resource limit / request configuration, in which case UAIs created
with this Class use the UAI namespace default limits and
requests.

**volume_list**: Optional comma-separated list of volume-ids specifying the
volume mounts to be included in the UAIs created using this
Class.  Defaults to an empty list if not specified, in
which case none of the available volume mounts will be mounted
in UAIs created using this Class.

**tolerations**: Optional JSON string containing a JSON list of JSON objects
describing tolerations that are added to the base toleration
used in UAIs.  Tolerations allow UAIs to run on nodes that
have been otherwise 'tainted' against certain activities. See
Kubernetes documentation of Taints and Tolerations for more
information on how to taint a node or construct a toleration.

**timeout**: Optional JSON string containing a timeout specification
for UAIs created using this class.  The value contains a
JSON string specifying a map with three optional key /
value pairs, 'soft', 'hard', and 'warning'.  The 'soft'
value specifies the number of seconds a UAI will run
before it is eligible for termination due to being idle
(i.e. no user is logged into it).  The 'hard' value
specifies the number of seconds the UAI will run before
being unconditionally terminated, even if a user is logged
into it.  The 'warning' value specifies the number of
seconds before the 'hard' timeout at which a warning
message will be sent to all logged in sessions.  If a
'soft' value is provided with no 'hard' value, the UAI
will remain in place (subject to failure or scheduling
issues) indefinitely as long as there is at least one
active login session running. The UAI will terminate once
the 'soft' value is exceeded and there are no longer any
active login sessions. If a 'hard' value is specified
without a 'soft' value, the UAI will remain in place until
the 'hard' value is reached at which point it will
terminate regardless of logged in sessions.  If both
'soft' and 'hard' values are specified, the UAI will
terminate at the 'soft' value if no active login session
exists and will terminate unconditionally once the 'hard'
value is reached.  If neither 'soft' nor 'hard' is
specified, or no timeout parameter is provided at all, the
UAI will run indefinitely.

**service_account**: Optional name of a Kubernetes service account to be assigned to
UAIs created with this class.  Kubernetes service accounts grant
access to Kubernetes Role Based Access Control (RBAC).  If not
specified, the default service account for the namespace in which
the UAI is created will be used.  Apply service accounts to UAI
classes with care, since they potentially give UAIs access to
Kubernetes functions that could be harmful.

**replicas**: The number of UAI replicas created when a UAI of
this class starts.  For end-user UAI classes this should
be omitted or set to 1 because having multiple replicas of
an end-user UAI only consumes resources and introduces
potential negative interactions with brokers.  For other
UAI classes, especially Broker UAI classes, setting this
to a larger value can improve resiliency of the UAI and
also provide better load-balanced handling of external
connections.

> Example responses

> 201 Response

```json
{
  "class_id": "string",
  "comment": "string",
  "default": true,
  "public_ip": true,
  "priority_class_name": "string",
  "namespace": "string",
  "opt_ports": "string",
  "uai_creation_class": "string",
  "uai_compute_network": true,
  "tolerations": "string",
  "uai_image": {
    "option": {
      "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
      "imagename": "node.local/uas-sles15:latest",
      "default": false
    }
  },
  "resource_config": {
    "option": {
      "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
      "comment": "A resource limit for UAIs that only launch jobs",
      "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
      "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
    }
  },
  "volume_mounts": [
    {
      "option": {
        "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
        "volumename": "my-mount",
        "mount_path": "/mnt/test",
        "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
      }
    }
  ]
}
```

<h3 id="create_uas_class_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|UAI / Broker Class added|[UAIClass](#schemauaiclass)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Invalid UAI / Broker Class specified|string|

<aside class="success">
This operation does not require authentication
</aside>

## get_uas_classes_admin

<a id="opIdget_uas_classes_admin"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/admin/config/classes HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/admin/config/classes \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/admin/config/classes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/admin/config/classes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /admin/config/classes`

*List Available UAI / Broker Classes*

List all available UAI / Broker Classes

> Example responses

> 200 Response

```json
[
  {
    "class_id": "string",
    "comment": "string",
    "default": true,
    "public_ip": true,
    "priority_class_name": "string",
    "namespace": "string",
    "opt_ports": "string",
    "uai_creation_class": "string",
    "uai_compute_network": true,
    "tolerations": "string",
    "uai_image": {
      "option": {
        "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
        "imagename": "node.local/uas-sles15:latest",
        "default": false
      }
    },
    "resource_config": {
      "option": {
        "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
        "comment": "A resource limit for UAIs that only launch jobs",
        "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
        "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
      }
    },
    "volume_mounts": [
      {
        "option": {
          "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
          "volumename": "my-mount",
          "mount_path": "/mnt/test",
          "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
        }
      }
    ]
  }
]
```

<h3 id="get_uas_classes_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAI / Broker Class List|Inline|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|UAI / Broker Classes not found|None|

<h3 id="get_uas_classes_admin-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[UAIClass](#schemauaiclass)]|false|none|none|
|» class_id|string|false|none|none|
|» comment|string|false|none|none|
|» default|boolean|false|none|none|
|» public_ip|boolean|false|none|none|
|» priority_class_name|string|false|none|none|
|» namespace|string|false|none|none|
|» opt_ports|string|false|none|none|
|» uai_creation_class|string|false|none|none|
|» uai_compute_network|boolean|false|none|none|
|» tolerations|string|false|none|none|
|» uai_image|object|false|none|none|
|»» option|[Image](#schemaimage)|false|none|none|
|»»» image_id|string|false|none|none|
|»»» imagename|string|false|none|none|
|»»» default|boolean|false|none|none|
|» resource_config|object|false|none|none|
|»» option|[Resource](#schemaresource)|false|none|none|
|»»» resource_id|string|false|none|none|
|»»» comment|string|false|none|none|
|»»» limit|string|false|none|none|
|»»» request|string|false|none|none|
|» volume_mounts|[object]|false|none|none|
|»» option|[Volume](#schemavolume)|false|none|none|
|»»» volume_id|string|false|none|none|
|»»» volumename|string|false|none|none|
|»»» mount_path|string|false|none|none|
|»»» volume_description|object|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## get_uas_class_admin

<a id="opIdget_uas_class_admin"></a>

> Code samples

```http
GET /apis/uas-mgr/v1/admin/config/classes/{class_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/uas-mgr/v1/admin/config/classes/{class_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/uas-mgr/v1/admin/config/classes/{class_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/apis/uas-mgr/v1/admin/config/classes/{class_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /admin/config/classes/{class_id}`

*Get a UAI / Broker Class*

Get a description of a UAI / Broker Class

<h3 id="get_uas_class_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|class_id|path|string|true|The class identifier (UUID) UAI / Broker Class to be retrieved|

#### Detailed descriptions

**class_id**: The class identifier (UUID) UAI / Broker Class to be retrieved
from the configuration.

> Example responses

> 200 Response

```json
{
  "class_id": "string",
  "comment": "string",
  "default": true,
  "public_ip": true,
  "priority_class_name": "string",
  "namespace": "string",
  "opt_ports": "string",
  "uai_creation_class": "string",
  "uai_compute_network": true,
  "tolerations": "string",
  "uai_image": {
    "option": {
      "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
      "imagename": "node.local/uas-sles15:latest",
      "default": false
    }
  },
  "resource_config": {
    "option": {
      "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
      "comment": "A resource limit for UAIs that only launch jobs",
      "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
      "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
    }
  },
  "volume_mounts": [
    {
      "option": {
        "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
        "volumename": "my-mount",
        "mount_path": "/mnt/test",
        "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
      }
    }
  ]
}
```

<h3 id="get_uas_class_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|UAI / Broker Class|[UAIClass](#schemauaiclass)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|UAI / Broker Class {class_id} not found|None|

<aside class="success">
This operation does not require authentication
</aside>

## update_uas_class_admin

<a id="opIdupdate_uas_class_admin"></a>

> Code samples

```http
PATCH /apis/uas-mgr/v1/admin/config/classes/{class_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH /apis/uas-mgr/v1/admin/config/classes/{class_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.patch('/apis/uas-mgr/v1/admin/config/classes/{class_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "/apis/uas-mgr/v1/admin/config/classes/{class_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /admin/config/classes/{class_id}`

*Update a UAI / Broker Class*

Update the contents of a specified Class.  Changes to a Class
only affect subsequently created UAIs.  UAIs already created using the
class continue to use settings from the previous contents of the
UAI / Broker Class.

<h3 id="update_uas_class_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|class_id|path|string|true|The image identifier (UUID) of the UAI / Broker Class to be updated|
|comment|query|string|false|A descriptive comment explaining the intended use of the Class.|
|default|query|boolean|false|Optionally specify whether this is the default|
|public_ip|query|boolean|false|A flag indicating whether a UAI or Broker created using this|
|image_id|query|string|false|The image-id of the image to be used in UAIs created from|
|priority_class_name|query|string|false|Optional Kubernetes priority class name to be assigned to|
|namespace|query|string|false|The K8s namespace where UAIs of this class run.|
|opt_ports|query|string|false|A comma-separated list of port numbers on which software running in a|
|uai_creation_class|query|string|false|For Brokers only, the class ID (UUID)  used to create UAIs|
|uai_compute_network|query|boolean|false|A flag indicating whether a UAI or Broker created using this|
|resource_id|query|string|false|Optional resource-id of the resource limit / request configuration|
|volume_list|query|array[string]|false|Comma-separated list of volume-ids specifying the|
|tolerations|query|string|false|Optional JSON string containing a JSON list of JSON objects|
|timeout|query|string|false|Optional JSON string containing a timeout specification|
|service_account|query|string|false|Optional name of a Kubernetes service account to be assigned to|
|replicas|query|string|false|The number of UAI replicas created when a UAI of|

#### Detailed descriptions

**class_id**: The image identifier (UUID) of the UAI / Broker Class to be updated

**comment**: A descriptive comment explaining the intended use of the Class.
Defaults to no description.

**default**: Optionally specify whether this is the default
Class. There can be at most one default Class in effect
at any given time.  If a default Class is present, then
UAIs created using the Single User Workflow will use that
Class instead of accepting an image name and using all
of the configured volume mounts and the UAI namespace
default resource configuration.  Additionally, UAIs created
in the Administrative Workflow without a specified class will
use the default Class.

Setting 'default' to true when another Class is currently
the default will cause the new Class to become the default
and the previous default to stop being the default.

**public_ip**: A flag indicating whether a UAI or Broker created using this
class will present ports on a public IP address or only on a
cluster visible IP address.  If not provided, the default is
false, which makes resulting UAIs or Brokers visible only
within the cluster.

**image_id**: The image-id of the image to be used in UAIs created from
this UAI / Broker Class.

**priority_class_name**: Optional Kubernetes priority class name to be assigned to
all UAIs / Brokers using this class.  The priority class
name is used in Kubernetes to determine scheduling
(i.e. node placement) priority in case of resource
exhaustion and to associate resource quotas with Kubernetes
pods.

**namespace**: The K8s namespace where UAIs of this class run.

**opt_ports**: A comma-separated list of port numbers on which software running in a
UAI created using this class may listen.  Unlike `ports` in the
Single User UAI creation API, the port numbers here are not constrained
by any configured range of available ports.  Any valid port number is
legal.

**uai_creation_class**: For Brokers only, the class ID (UUID)  used to create UAIs
created by Brokers of this class.  If this is not specified
on a Broker, and there is a default class specified, the default
class will be used.  If there is no default class, the
broker will fail to create UAIs.  If this is specified on a
non-Broker UAI it has no meaningful effect.

**uai_compute_network**: A flag indicating whether a UAI or Broker created using this
class will include a network route to compute nodes. This option
is likely not necessary for Brokers. Single User UAIs will require
this flag for job launch capabilities.

**resource_id**: Optional resource-id of the resource limit / request configuration
to be used with UAIs created using this UAI / Broker Class.

**volume_list**: Comma-separated list of volume-ids specifying the
volume mounts to be included in the UAIs created using this
UAI / Broker Class.

**tolerations**: Optional JSON string containing a JSON list of JSON objects
describing tolerations that are added to the base toleration
used in UAIs.  Tolerations allow UAIs to run on nodes that
have been otherwise 'tainted' against certain activities. See
Kubernetes documentation of Taints and Tolerations for more
information on how to taint a node or construct a toleration.

**timeout**: Optional JSON string containing a timeout specification
for UAIs created using this class.  The value contains a
JSON string specifying a map with three optional key /
value pairs, 'soft', 'hard', and 'warning'.  The 'soft'
value specifies the number of seconds a UAI will run
before it is eligible for termination due to being idle
(i.e. no user is logged into it).  The 'hard' value
specifies the number of seconds the UAI will run before
being unconditionally terminated, even if a user is logged
into it.  The 'warning' value specifies the number of
seconds before the 'hard' timeout at which a warning
message will be sent to all logged in sessions.  If a
'soft' value is provided with no 'hard' value, the UAI
will remain in place (subject to failure or scheduling
issues) indefinitely as long as there is at least one
active login session running. The UAI will terminate once
the 'soft' value is exceeded and there are no longer any
active login sessions. If a 'hard' value is specified
without a 'soft' value, the UAI will remain in place until
the 'hard' value is reached at which point it will
terminate regardless of logged in sessions.  If both
'soft' and 'hard' values are specified, the UAI will
terminate at the 'soft' value if no active login session
exists and will terminate unconditionally once the 'hard'
value is reached.  If neither 'soft' nor 'hard' is
specified, or no timeout parameter is provided at all, the
UAI will run indefinitely.

**service_account**: Optional name of a Kubernetes service account to be assigned to
UAIs created with this class.  Kubernetes service accounts grant
access to Kubernetes Role Based Access Control (RBAC).  If not
specified, the default service account for the namespace in which
the UAI is created will be used.  Apply service accounts to UAI
classes with care, since they potentially give UAIs access to
Kubernetes functions that could be harmful.

**replicas**: The number of UAI replicas created when a UAI of
this class starts.  For end-user UAI classes this should
be omitted or set to 1 because having multiple replicas of
an end-user UAI only consumes resources and introduces
potential negative interactions with brokers.  For other
UAI classes, especially Broker UAI classes, setting this
to a larger value can improve resiliency of the UAI and
also provide better load-balanced handling of external
connections.

> Example responses

> 201 Response

```json
{
  "class_id": "string",
  "comment": "string",
  "default": true,
  "public_ip": true,
  "priority_class_name": "string",
  "namespace": "string",
  "opt_ports": "string",
  "uai_creation_class": "string",
  "uai_compute_network": true,
  "tolerations": "string",
  "uai_image": {
    "option": {
      "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
      "imagename": "node.local/uas-sles15:latest",
      "default": false
    }
  },
  "resource_config": {
    "option": {
      "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
      "comment": "A resource limit for UAIs that only launch jobs",
      "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
      "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
    }
  },
  "volume_mounts": [
    {
      "option": {
        "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
        "volumename": "my-mount",
        "mount_path": "/mnt/test",
        "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
      }
    }
  ]
}
```

<h3 id="update_uas_class_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|UAI / Broker Class updated|[UAIClass](#schemauaiclass)|
|304|[Not Modified](https://tools.ietf.org/html/rfc7232#section-4.1)|No changes made|[UAIClass](#schemauaiclass)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_uas_class_admin

<a id="opIddelete_uas_class_admin"></a>

> Code samples

```http
DELETE /apis/uas-mgr/v1/admin/config/classes/{class_id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE /apis/uas-mgr/v1/admin/config/classes/{class_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('/apis/uas-mgr/v1/admin/config/classes/{class_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "/apis/uas-mgr/v1/admin/config/classes/{class_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /admin/config/classes/{class_id}`

*Remove a UAI / Broker Class*

Delete the specified UAI / Broker Class

<h3 id="delete_uas_class_admin-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|class_id|path|string|true|The class identifier (UUID) of the UAI / Broker Class to be|

#### Detailed descriptions

**class_id**: The class identifier (UUID) of the UAI / Broker Class to be
removed from the configuration.

> Example responses

> 200 Response

```json
{
  "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "comment": "A resource limit for UAIs that only launch jobs",
  "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
  "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
}
```

<h3 id="delete_uas_class_admin-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Resource configuration removed|[Resource](#schemaresource)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Failed to delete resource configuration {resource_id}|None|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_UAI">UAI</h2>
<!-- backwards compatibility -->
<a id="schemauai"></a>
<a id="schema_UAI"></a>
<a id="tocSuai"></a>
<a id="tocsuai"></a>

```json
{
  "uai_name": "uai-swilliams-cc09d2d2",
  "username": "swilliams",
  "class_id": "83156ef8-4286-4d57-8ffa-46ebf6c8f8b5",
  "resource_id": "6f66edda-625f-4be3-b563-dca5844c85cf",
  "image_id": "32ab9d45-f904-40f8-80a0-0881969a4f6e",
  "public_ip": false,
  "publickey": "/Users/user/.ssh/id_rsa.pub",
  "uai_img": "uai_img",
  "uai_status": "Running",
  "uai_reason": "Deploying",
  "uai_host": "ncn-w001",
  "uai_age": "13d8h"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|uai_name|string|false|none|none|
|username|string|false|none|none|
|publickey|string|false|none|none|
|class_id|string|false|none|none|
|public_ip|boolean|false|none|none|
|resource_id|string|false|none|none|
|image_id|string|false|none|none|
|uai_img|string|false|none|none|
|uai_status|string|false|none|none|
|uai_msg|string|false|none|none|
|uai_connect_string|string|false|none|none|
|uai_portmap|object|false|none|none|
|» **additionalProperties**|integer|false|none|none|
|uai_host|string|false|none|none|
|uai_age|string|false|none|none|

<h2 id="tocS_Volume">Volume</h2>
<!-- backwards compatibility -->
<a id="schemavolume"></a>
<a id="schema_Volume"></a>
<a id="tocSvolume"></a>
<a id="tocsvolume"></a>

```json
{
  "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "volumename": "my-mount",
  "mount_path": "/mnt/test",
  "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|volume_id|string|false|none|none|
|volumename|string|false|none|none|
|mount_path|string|false|none|none|
|volume_description|object|false|none|none|

<h2 id="tocS_Image">Image</h2>
<!-- backwards compatibility -->
<a id="schemaimage"></a>
<a id="schema_Image"></a>
<a id="tocSimage"></a>
<a id="tocsimage"></a>

```json
{
  "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
  "imagename": "node.local/uas-sles15:latest",
  "default": false
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|image_id|string|false|none|none|
|imagename|string|false|none|none|
|default|boolean|false|none|none|

<h2 id="tocS_Resource">Resource</h2>
<!-- backwards compatibility -->
<a id="schemaresource"></a>
<a id="schema_Resource"></a>
<a id="tocSresource"></a>
<a id="tocsresource"></a>

```json
{
  "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
  "comment": "A resource limit for UAIs that only launch jobs",
  "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
  "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|resource_id|string|false|none|none|
|comment|string|false|none|none|
|limit|string|false|none|none|
|request|string|false|none|none|

<h2 id="tocS_UAIClass">UAIClass</h2>
<!-- backwards compatibility -->
<a id="schemauaiclass"></a>
<a id="schema_UAIClass"></a>
<a id="tocSuaiclass"></a>
<a id="tocsuaiclass"></a>

```json
{
  "class_id": "string",
  "comment": "string",
  "default": true,
  "public_ip": true,
  "priority_class_name": "string",
  "namespace": "string",
  "opt_ports": "string",
  "uai_creation_class": "string",
  "uai_compute_network": true,
  "tolerations": "string",
  "uai_image": {
    "option": {
      "image_id": "af4e59ab-6275-47f9-8f4a-90911eba3f9c",
      "imagename": "node.local/uas-sles15:latest",
      "default": false
    }
  },
  "resource_config": {
    "option": {
      "resource_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
      "comment": "A resource limit for UAIs that only launch jobs",
      "limit": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }",
      "request": "{ \"cpu\": \"100m\", \"memory\": \"100Mi\" }"
    }
  },
  "volume_mounts": [
    {
      "option": {
        "volume_id": "e2918379-7df1-4086-92fe-e3ec777a9b2e",
        "volumename": "my-mount",
        "mount_path": "/mnt/test",
        "volume_description": "{\"host_path\":{\"path\": \"/opt/host/path\", \"type\": \"DirectoryOrCreate\"}}\n"
      }
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|class_id|string|false|none|none|
|comment|string|false|none|none|
|default|boolean|false|none|none|
|public_ip|boolean|false|none|none|
|priority_class_name|string|false|none|none|
|namespace|string|false|none|none|
|opt_ports|string|false|none|none|
|uai_creation_class|string|false|none|none|
|uai_compute_network|boolean|false|none|none|
|tolerations|string|false|none|none|
|uai_image|object|false|none|none|
|» option|[Image](#schemaimage)|false|none|none|
|resource_config|object|false|none|none|
|» option|[Resource](#schemaresource)|false|none|none|
|volume_mounts|[object]|false|none|none|
|» option|[Volume](#schemavolume)|false|none|none|

<h2 id="tocS_Image_list">Image_list</h2>
<!-- backwards compatibility -->
<a id="schemaimage_list"></a>
<a id="schema_Image_list"></a>
<a id="tocSimage_list"></a>
<a id="tocsimage_list"></a>

```json
{
  "default_image": "string",
  "image_list": [
    "string"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|default_image|string|false|none|none|
|image_list|[string]|false|none|none|

<h2 id="tocS_UAS_mgr_info">UAS_mgr_info</h2>
<!-- backwards compatibility -->
<a id="schemauas_mgr_info"></a>
<a id="schema_UAS_mgr_info"></a>
<a id="tocSuas_mgr_info"></a>
<a id="tocsuas_mgr_info"></a>

```json
{
  "service_name": "cray-uas-mgr",
  "version": "version"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|service_name|string|false|none|none|
|version|string|false|none|none|

