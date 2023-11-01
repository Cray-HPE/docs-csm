<!-- Generator: Widdershins v4.0.1 -->

<h1 id="image-management-service">Image Management Service v3</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The Image Management Service (IMS) creates and customizes boot images which run on compute nodes. A boot image consists of multiple image artifacts including the root file system (rootfs), kernel, and initrd. There are optionally additional artifacts such as debug symbols, etc.
IMS uses the open source Kiwi-NG tool to build image roots from compressed Kiwi image descriptions (recipes). Kiwi-NG is able to build images based on a variety of different Linux distributions, specifically SUSE, RHEL, and their derivatives.
A user may choose to use the provided recipes or customize Kiwi recipes to define the image to be built.
IMS creates and customizes existing boot images and maintains metadata about the images and related artifacts. IMS accesses and stores the recipes, images, and related artifacts in the artifact repository.
## Resources

  ### /images

    Manipulate ImageRecords, which relate multiple image artifact records together.

  ### /jobs

    Initiate image creation or customization.  It creates the image which it uploads to the
    artifact repository, and maintains associated metadata in IMS for subsequent access. It
    also customizes a pre-existing image.

  ### /public-keys

    Manage the public keys which enable SSH access. Public-keys are created and uploaded by the
    administrator to allow access to SSH shells provided by IMS during image creation and
    customization.

  ### /recipes

    Manipulate the RecipeRecord metadata about the Kiwi-NG recipes which are stored in the
    artifact repository. Recipes themselves define how an image is to be created, including the
    RPMs that will be installed, the RPM repositories to use, etc.

## Workflows

  There are two main workflows using the IMS - image creation and image customization.
  The IMS /jobs endpoint directs the creation of a new image, or the customization of an
  existing image, depending on the POST /jobs request job_type body parameter.

  ### Add a New Recipe

    #### GET /recipes

      Obtain list of existing recipes which are registered with IMS.

    #### Upload recipe using CLI

      Upload a new recipe to the artifact repository using the cray artifacts command, if necessary.
      Refer to Administrator's Guide for instructions.

    #### POST /recipes

      Register new recipe with IMS.

  ### Manage Public Keys

    #### GET /public-keys

      Obtain list of available public-keys.

    #### POST /public-keys

      Add a new public-key.

  ### Create a New Image

    #### GET /public-keys

      Get a list of available keys.

    #### GET /recipes

      Get recipe ID.

    #### POST /jobs

      Use Kiwi-NG to create a new IMS image and image artifacts from a recipe. Specify job_type
      "create" in JobRecord. Request body parameters supply the recipe ID and public key ID.
      Upon success, the artifact repository contains the new image and the image artifacts,
      IMS contains a new ImageRecord with metadata for the new image. During the creation
      process, IMS may create an SSH shell for administrator interaction with the image for
      debugging, if necessary.  (enable_debug = true in JobRecord)

  ### Modify an Image

    #### GET /public-keys

      Get a list of available keys.

    #### GET /images

      Obtain a list of available images registered in IMS.

    #### POST /jobs

      To create a modified version of an existing IMS image, specify job_type "customize".
      Specify the IMS ID of the existing image, and public key.  This request creates a copy of
      the existing image, and then an interactive SSH shell in which to modify the copy of the
      image. Upon success, the artifact repository contains the original image and a modified
      version of it. IMS contains a new ImageRecord with metadata for the modified image. The
      original image is still intact.  A user may want to install additional software, install
      licenses, change the timezone, add mount points, etc.

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/ims">https://api-gw-service-nmn.local/apis/ims</a>

* <a href="cray-ims.services.svc.cluster.local">cray-ims.services.svc.cluster.local</a>

License: <a href="http://www.hpe.com/">Hewlett Packard Enterprise Development LP</a>

<h1 id="image-management-service-images">images</h1>

Interact with image records

## get_all_v3_images

<a id="opIdget_all_v3_images"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/images HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/images \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/images`

*List all ImageRecords*

Retrieve a list of ImageRecords indicating images that are registered with IMS. The ImageRecord ID is used to associate multiple image artifacts together (kernel, initrd, rootfs (squashfs)).

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "name": "centos7.5_barebones",
    "link": {
      "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
      "etag": "f04af5f34635ae7c507322985e60c00c-131",
      "type": "s3"
    },
    "arch": "aarch64"
  }
]
```

<h3 id="get_all_v3_images-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of images|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v3_images-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[ImageRecord](#schemaimagerecord)]|false|none|[An Image Record]|
|» id|string(uuid)|false|read-only|Unique ID of the image.|
|» created|string(date-time)|false|read-only|Time the image record was created|
|» name|string|true|none|Name of the image|
|» link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|»» path|string|true|none|Path or location to the artifact in the artifact repository|
|»» etag|string|false|none|Opaque identifier used to uniquely identify the artifact in the artifact repository|
|»» type|string|true|none|Identifier specifying the artifact repository where the artifact is located|
|» arch|string|false|none|Target architecture for the recipe.|

#### Enumerated Values

|Property|Value|
|---|---|
|arch|aarch64|
|arch|x86_64|

<aside class="success">
This operation does not require authentication
</aside>

## post_v3_image

<a id="opIdpost_v3_image"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/ims/v3/images HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/ims/v3/images \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/ims/v3/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/ims/v3/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v3/images`

*Create a new ImageRecord*

Create a new ImageRecord and register the new image with IMS.

> Body parameter

```json
{
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="post_v3_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ImageRecord](#schemaimagerecord)|true|Image record to create|

> Example responses

> 201 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="post_v3_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|New image record|[ImageRecord](#schemaimagerecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v3_images

<a id="opIddelete_all_v3_images"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/images HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/images \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/images`

*Soft delete all ImageRecords*

Delete all ImageRecords. Deleted images are soft deleted and added to the /deleted/images endpoint. The S3 key for the associated image manifests are renamed.

> Example responses

> 500 Response

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

<h3 id="delete_all_v3_images-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Image records deleted successfully|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v3_image

<a id="opIdget_v3_image"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/images/{image_id}`

*Retrieve image by image_id*

Retrieve an image by image_id.

<h3 id="get_v3_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|image_id|path|string(uuid)|true|The unique ID of an image|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="get_v3_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An image record|[ImageRecord](#schemaimagerecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v3_image

<a id="opIdpatch_v3_image"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/images/{image_id}`

*Update an image*

Update an ImageRecord in IMS.

> Body parameter

```json
{
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="patch_v3_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ImagePatchRecord](#schemaimagepatchrecord)|true|Image Patch record|
|image_id|path|string(uuid)|true|The unique ID of an image|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="patch_v3_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Updated Image record|[ImageRecord](#schemaimagerecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Requested resource could not be patched due to conflict.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v3_image

<a id="opIddelete_v3_image"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/images/{image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/images/{image_id}`

*Soft delete ImageRecord by image_id*

Delete an ImageRecord by ID. Deleted images are soft deleted and added to the /deleted/images endpoint. The S3 key for the associated image manifest is renamed.

<h3 id="delete_v3_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|image_id|path|string(uuid)|true|The unique ID of an image|

> Example responses

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

<h3 id="delete_v3_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Image record deleted successfully|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_all_v3_deleted_images

<a id="opIdget_all_v3_deleted_images"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/images HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/images \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/deleted/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/deleted/images`

*List all DeletedImageRecords*

Retrieve a list of DeletedImageRecords indicating images that have been deleted from IMS.

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "deleted": "2018-07-28T03:26:01.234Z",
    "name": "centos7.5_barebones",
    "link": {
      "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
      "etag": "f04af5f34635ae7c507322985e60c00c-131",
      "type": "s3"
    },
    "arch": "aarch64"
  }
]
```

<h3 id="get_all_v3_deleted_images-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of deleted image records|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v3_deleted_images-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[DeletedImageRecord](#schemadeletedimagerecord)]|false|none|[A Deleted Image Record]|
|» id|string(uuid)|false|read-only|Unique ID of the image.|
|» created|string(date-time)|false|read-only|Time the image record was created|
|» deleted|string(date-time)|false|read-only|Time the image record was deleted|
|» name|string|true|none|Name of the image|
|» link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|»» path|string|true|none|Path or location to the artifact in the artifact repository|
|»» etag|string|false|none|Opaque identifier used to uniquely identify the artifact in the artifact repository|
|»» type|string|true|none|Identifier specifying the artifact repository where the artifact is located|
|» arch|string|false|none|Target architecture for the recipe.|

#### Enumerated Values

|Property|Value|
|---|---|
|arch|aarch64|
|arch|x86_64|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v3_deleted_images

<a id="opIddelete_all_v3_deleted_images"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/images HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/images \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/deleted/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/deleted/images`

*Permanently delete all DeletedImageRecords*

Permanently delete all DeletedImageRecords. Associated artifacts are permanently deleted from S3.

> Example responses

> 500 Response

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

<h3 id="delete_all_v3_deleted_images-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Image records were permanently deleted|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_all_v3_deleted_images

<a id="opIdpatch_all_v3_deleted_images"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/images HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/images \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/v3/deleted/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/deleted/images`

*Restore all DeletedImageRecords in IMS.*

Restore all DeletedImageRecords in IMS.

> Body parameter

```json
{
  "operation": "undelete"
}
```

<h3 id="patch_all_v3_deleted_images-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[DeletedImagePatchRecord](#schemadeletedimagepatchrecord)|true|Deleted Recipe Image record|

> Example responses

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

<h3 id="patch_all_v3_deleted_images-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Deleted image records updated successfully|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Requested resource could not be patched due to conflict.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v3_deleted_image

<a id="opIdget_v3_deleted_image"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/deleted/images/{deleted_image_id}`

*Retrieve deleted image details by using deleted_image_id*

Retrieve deleted image details by using deleted_image_id.

<h3 id="get_v3_deleted_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|deleted_image_id|path|string(uuid)|true|The unique ID of a deleted image|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "deleted": "2018-07-28T03:26:01.234Z",
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="get_v3_deleted_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A deleted image record|[DeletedImageRecord](#schemadeletedimagerecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v3_deleted_image

<a id="opIddelete_v3_deleted_image"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/deleted/images/{deleted_image_id}`

*Permanently delete image record by deleted_image_id*

Permanently delete image record associated with deleted_image_id. Associated artifacts are permanently deleted from S3.

<h3 id="delete_v3_deleted_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|deleted_image_id|path|string(uuid)|true|The unique ID of a deleted image|

> Example responses

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

<h3 id="delete_v3_deleted_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|ImageRecord was permanently deleted|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v3_deleted_image

<a id="opIdpatch_v3_deleted_image"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/images/{deleted_image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/deleted/images/{deleted_image_id}`

*Restore a DeletedImageRecord in IMS.*

Restore a DeletedImageRecord in IMS.

> Body parameter

```json
{
  "operation": "undelete"
}
```

<h3 id="patch_v3_deleted_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[DeletedImagePatchRecord](#schemadeletedimagepatchrecord)|true|DeletedImage Patch record|
|deleted_image_id|path|string(uuid)|true|The unique ID of a deleted image|

> Example responses

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

<h3 id="patch_v3_deleted_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Deleted image records updated successfully|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Requested resource could not be patched due to conflict.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_all_v2_images

<a id="opIdget_all_v2_images"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/images HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/images \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /images`

*List all ImageRecords*

Retrieve a list of ImageRecords indicating images that are registered with the IMS. The ImageRecord ID is used to associate multiple image artifacts together (kernel, initrd, rootfs (squashfs)).

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "name": "centos7.5_barebones",
    "link": {
      "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
      "etag": "f04af5f34635ae7c507322985e60c00c-131",
      "type": "s3"
    },
    "arch": "aarch64"
  }
]
```

<h3 id="get_all_v2_images-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of images|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v2_images-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[ImageRecord](#schemaimagerecord)]|false|none|[An Image Record]|
|» id|string(uuid)|false|read-only|Unique ID of the image.|
|» created|string(date-time)|false|read-only|Time the image record was created|
|» name|string|true|none|Name of the image|
|» link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|»» path|string|true|none|Path or location to the artifact in the artifact repository|
|»» etag|string|false|none|Opaque identifier used to uniquely identify the artifact in the artifact repository|
|»» type|string|true|none|Identifier specifying the artifact repository where the artifact is located|
|» arch|string|false|none|Target architecture for the recipe.|

#### Enumerated Values

|Property|Value|
|---|---|
|arch|aarch64|
|arch|x86_64|

<aside class="success">
This operation does not require authentication
</aside>

## post_v2_image

<a id="opIdpost_v2_image"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/ims/images HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/ims/images \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/ims/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/ims/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /images`

*Create a new ImageRecord*

Create a new ImageRecord and register the new image with IMS.

> Body parameter

```json
{
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="post_v2_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ImageRecord](#schemaimagerecord)|true|Image record to create|

> Example responses

> 201 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "deleted": "2018-07-28T03:26:01.234Z",
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="post_v2_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|New image record|[DeletedImageRecord](#schemadeletedimagerecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v2_images

<a id="opIddelete_all_v2_images"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/images HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/images \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/images', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/images", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /images`

*Delete all ImageRecords*

Delete all ImageRecords.

<h3 id="delete_all_v2_images-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|cascade|query|boolean|false|If cascade is true, IMS also deletes the linked artifacts in S3. If cascade is false, the linked artifacts in S3 are not affected.|

> Example responses

> 500 Response

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

<h3 id="delete_all_v2_images-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Image records deleted successfully|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_image

<a id="opIdget_v2_image"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/images/{image_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/images/{image_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/images/{image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/images/{image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /images/{image_id}`

*Retrieve image by image_id*

Retrieve an image by image_id.

<h3 id="get_v2_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|image_id|path|string(uuid)|true|The unique ID of an image|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="get_v2_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|An image record|[ImageRecord](#schemaimagerecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v2_image

<a id="opIdpatch_v2_image"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/images/{image_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/images/{image_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/images/{image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/images/{image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /images/{image_id}`

*Update an image*

Update an ImageRecord in IMS.

> Body parameter

```json
{
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="patch_v2_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ImagePatchRecord](#schemaimagepatchrecord)|true|Image Patch record|
|image_id|path|string(uuid)|true|The unique ID of an image|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}
```

<h3 id="patch_v2_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Updated Image record|[ImageRecord](#schemaimagerecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Requested resource could not be patched due to conflict.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v2_image

<a id="opIddelete_v2_image"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/images/{image_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/images/{image_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/images/{image_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/images/{image_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /images/{image_id}`

*Delete ImageRecord by image_id*

Delete an ImageRecord by image_id.

<h3 id="delete_v2_image-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|cascade|query|boolean|false|If cascade is true, IMS also deletes the linked artifacts in S3. If cascade is false, the linked artifacts in S3 are not affected.|
|image_id|path|string(uuid)|true|The unique ID of an image|

> Example responses

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

<h3 id="delete_v2_image-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Image record deleted successfully|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="image-management-service-healthz">healthz</h1>

Interact with kubernetes healthz checks

## get_healthz_ready

<a id="opIdget_healthz_ready"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/healthz/ready HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/healthz/ready \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/healthz/ready', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/healthz/ready", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /healthz/ready`

*Retrieve IMS Readiness Probe*

Readiness probe for IMS. This is used by Kubernetes to determine if IMS is ready to accept requests.

> Example responses

<h3 id="get_healthz_ready-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|IMS is ready to accept requests|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|IMS is not able to accept requests|None|

<h3 id="get_healthz_ready-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

## get_healthz_live

<a id="opIdget_healthz_live"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/healthz/live HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/healthz/live \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/healthz/live', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/healthz/live", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /healthz/live`

*Retrieve IMS Liveness Probe*

Liveness probe for IMS. This is used by Kubernetes to determine if IMS is responsive

> Example responses

<h3 id="get_healthz_live-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|IMS is responsive|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|IMS is not responsive|None|

<h3 id="get_healthz_live-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="image-management-service-jobs">jobs</h1>

Interact with job records

## get_all_v3_jobs

<a id="opIdget_all_v3_jobs"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/jobs HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/jobs \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/jobs', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/jobs", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/jobs`

*Retrieve a list of JobRecords that are registered with IMS*

Retrieve a list of JobRecords that are registered with IMS

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "job_type": "customize",
    "image_root_archive_name": "cray-sles12-sp3-barebones",
    "kernel_file_name": "vmlinuz",
    "initrd_file_name": "initrd",
    "kernel_parameters_file_name": "kernel-parameters",
    "status": "creating",
    "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
    "kubernetes_job": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-customize",
    "kubernetes_service": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-service",
    "kubernetes_configmap": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-configmap",
    "ssh_containers": [
      {
        "name": "customize",
        "jail": true,
        "status": "pending",
        "connection_info": {
          "property1": {
            "host": "10.100.20.221",
            "port": 22
          },
          "property2": {
            "host": "10.100.20.221",
            "port": 22
          }
        }
      }
    ],
    "enable_debug": true,
    "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
    "build_env_size": 15,
    "kubernetes_namespace": "default",
    "arch": "aarch64",
    "require_dkms": false
  }
]
```

<h3 id="get_all_v3_jobs-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of jobs|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v3_jobs-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[JobRecord](#schemajobrecord)]|false|none|[A Job Record]|
|» id|string(uuid)|false|read-only|Unique ID of the job|
|» created|string(date-time)|false|read-only|Time the image record was created|
|» job_type|[JobTypes](#schemajobtypes)|true|none|Type of job|
|» image_root_archive_name|string|true|none|Name to be given to the imageroot artifact (do not include .sqshfs or other extensions)|
|» kernel_file_name|string|false|none|Name of the kernel file to extract and upload to the artifact repository from the /boot directory of the image root.|
|» initrd_file_name|string|false|none|Name of the initrd image file to extract and upload to the artifact repository from the /boot directory of the image root.|
|» kernel_parameters_file_name|string|false|none|Name of the kernel-parameters file to extract and upload to the artifact repository from the /boot directory of the image root.|
|» status|[JobStatuses](#schemajobstatuses)|false|read-only|Status of the job|
|» artifact_id|string(uuid)|true|none|IMS artifact_id which specifies the recipe (create job_type) or the image (customize job_type) to fetch from the artifact repository.|
|» public_key_id|string(uuid)|true|none|Public key to use to enable passwordless SSH shells|
|» kubernetes_job|string|false|read-only|Name of the underlying kubernetes job|
|» kubernetes_service|string|false|read-only|Name of the underlying kubernetes service|
|» kubernetes_configmap|string|false|read-only|Name of the underlying kubernetes configmap|
|» ssh_containers|[[SshContainer](#schemasshcontainer)]|false|none|List of SSH containers used to customize images being built or modified|
|»» name|string|true|none|Name of the SSH container|
|»» jail|boolean|true|none|If true, establish an SSH jail, or chroot environment.|
|»» status|string|false|read-only|Status of the SSH container (pending, establishing, active, complete)|
|»» connection_info|object|false|none|none|
|»»» **additionalProperties**|object|false|none|none|
|»»»» host|string|false|read-only|IP or host name to use, in combination with the port, to connect to the SSH container|
|»»»» port|integer|false|read-only|Port to use, in combination with the host, to connect to the SSH container|
|» enable_debug|boolean|false|none|Whether to enable debugging of the job|
|» resultant_image_id|string(uuid)|false|read-only|IMS image ID for the resultant image.|
|» build_env_size|integer|false|none|Size (in Gb) to allocate for the image root. Default = 15|
|» kubernetes_namespace|string|false|read-only|Kubernetes namespace where the IMS job resources were created|
|» arch|string|false|read-only|Target architecture for the recipe.|
|» require_dkms|boolean|false|none|Whether enable DKMS for the job|

#### Enumerated Values

|Property|Value|
|---|---|
|job_type|create|
|job_type|customize|
|status|creating|
|status|fetching_image|
|status|fetching_recipe|
|status|waiting_for_repos|
|status|building_image|
|status|waiting_on_user|
|status|error|
|status|success|
|arch|aarch64|
|arch|x86_64|

<aside class="success">
This operation does not require authentication
</aside>

## post_v3_job

<a id="opIdpost_v3_job"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/ims/v3/jobs HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/ims/v3/jobs \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/ims/v3/jobs', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/ims/v3/jobs", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v3/jobs`

*Create JobRecord*

Create a new IMS image or modify an existing IMS image,
depending on request body parameter, job_type.

# Create

* Fetch recipe from the artifact repository and decompress to temp directory.
* Wait for required package repositories to become available
* Call kiwi-ng, which builds the image root using
  the recipe in artifact repository and accesses packages in zypper/yum repositories.
* Upload the new image to the artifact repository, and save metadata to IMS - ImageRecord.
* If there is a failure, establish debug SSH shell, depending on value of enable_debug.  Admin
  can inspect image build root.
  **touch /mnt/image/complete** in a non-jailed environment or
  **touch /tmp/complete** in a jailed (chroot) environment to exit.

# Customize

* The artifact_id in the POST /job request body refers to an IMS ImageRecord. IMS uses
  the ImageRecord to read the Image's manifest.yaml to find the Image's
  root file system (rootfs) artifact.  IMS downloads the rootfs from the artifact
  repository and uncompresses it.
* IMS creates an SSH environment so admin can inspect and modify the image.
  For example, it may be necessary to modify the timezone, or
  modify the programming environment, etc.
  **touch /mnt/image/complete** in a non-jailed
  environment or **touch /tmp/complete** in a jailed (chroot) environment.
  to exit.
* IMS waits for the user to exit the ssh, then creates new IMS image
  record with the modifications, and adds the root
  certificate to the image. Note that IMS does not modify the original image
  but modifies a copy of it.
* IMS creates a new IMS ImageRecord, packages the IMS artifacts
  (kernel, initrd, rootfs), creates a manifest.json manifest file, and uploads
  all new artifacts to the artifact repository. The metadata is recorded by IMS
  and ImageRecord is updated.

> Body parameter

```json
{
  "job_type": "customize",
  "image_root_archive_name": "cray-sles12-sp3-barebones",
  "kernel_file_name": "vmlinuz",
  "initrd_file_name": "initrd",
  "kernel_parameters_file_name": "kernel-parameters",
  "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
  "ssh_containers": [
    {
      "name": "customize",
      "jail": true,
      "connection_info": {
        "property1": {},
        "property2": {}
      }
    }
  ],
  "enable_debug": true,
  "build_env_size": 15,
  "require_dkms": false
}
```

<h3 id="post_v3_job-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[JobRecord](#schemajobrecord)|true|Job record to create|

> Example responses

> 201 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "job_type": "customize",
  "image_root_archive_name": "cray-sles12-sp3-barebones",
  "kernel_file_name": "vmlinuz",
  "initrd_file_name": "initrd",
  "kernel_parameters_file_name": "kernel-parameters",
  "status": "creating",
  "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
  "kubernetes_job": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-customize",
  "kubernetes_service": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-service",
  "kubernetes_configmap": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-configmap",
  "ssh_containers": [
    {
      "name": "customize",
      "jail": true,
      "status": "pending",
      "connection_info": {
        "property1": {
          "host": "10.100.20.221",
          "port": 22
        },
        "property2": {
          "host": "10.100.20.221",
          "port": 22
        }
      }
    }
  ],
  "enable_debug": true,
  "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
  "build_env_size": 15,
  "kubernetes_namespace": "default",
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="post_v3_job-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|New job record|[JobRecord](#schemajobrecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v3_jobs

<a id="opIddelete_all_v3_jobs"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/jobs HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/jobs \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/jobs', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/jobs", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/jobs`

*Delete all JobRecords*

Delete all job records.

<h3 id="delete_all_v3_jobs-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|status|query|array[string]|false|List of job statues. Only jobs with matching statues are considered for deletion.|
|job_type|query|array[string]|false|Only jobs with matching job type are considered for deletion.|
|age|query|string|false|Only jobs older than the given age are considered for deletion.  Age is given in the format "1d" or "6h"|

#### Enumerated Values

|Parameter|Value|
|---|---|
|status|creating|
|status|fetching_image|
|status|fetching_recipe|
|status|waiting_for_repos|
|status|building_image|
|status|waiting_on_user|
|status|error|
|status|success|
|job_type|create|
|job_type|customize|

> Example responses

> 500 Response

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

<h3 id="delete_all_v3_jobs-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Job records deleted successfully|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v3_job

<a id="opIdget_v3_job"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/jobs/{job_id}`

*Retrieve a job by job_id*

Retrieve JobRecord by job_id

<h3 id="get_v3_job-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|job_id|path|string(uuid)|true|The unique ID of a job|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "job_type": "customize",
  "image_root_archive_name": "cray-sles12-sp3-barebones",
  "kernel_file_name": "vmlinuz",
  "initrd_file_name": "initrd",
  "kernel_parameters_file_name": "kernel-parameters",
  "status": "creating",
  "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
  "kubernetes_job": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-customize",
  "kubernetes_service": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-service",
  "kubernetes_configmap": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-configmap",
  "ssh_containers": [
    {
      "name": "customize",
      "jail": true,
      "status": "pending",
      "connection_info": {
        "property1": {
          "host": "10.100.20.221",
          "port": 22
        },
        "property2": {
          "host": "10.100.20.221",
          "port": 22
        }
      }
    }
  ],
  "enable_debug": true,
  "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
  "build_env_size": 15,
  "kubernetes_namespace": "default",
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="get_v3_job-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A job record|[JobRecord](#schemajobrecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v3_job

<a id="opIdpatch_v3_job"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/jobs/{job_id}`

*Update a JobRecord by job_id (Internal Use Only)*

Update a job record. Internal use only. Not for API consumers.

> Body parameter

```json
{
  "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
  "status": "creating"
}
```

<h3 id="patch_v3_job-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[JobPatchRecord](#schemajobpatchrecord)|true|Image Patch record|
|job_id|path|string(uuid)|true|The unique ID of a job|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "job_type": "customize",
  "image_root_archive_name": "cray-sles12-sp3-barebones",
  "kernel_file_name": "vmlinuz",
  "initrd_file_name": "initrd",
  "kernel_parameters_file_name": "kernel-parameters",
  "status": "creating",
  "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
  "kubernetes_job": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-customize",
  "kubernetes_service": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-service",
  "kubernetes_configmap": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-configmap",
  "ssh_containers": [
    {
      "name": "customize",
      "jail": true,
      "status": "pending",
      "connection_info": {
        "property1": {
          "host": "10.100.20.221",
          "port": 22
        },
        "property2": {
          "host": "10.100.20.221",
          "port": 22
        }
      }
    }
  ],
  "enable_debug": true,
  "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
  "build_env_size": 15,
  "kubernetes_namespace": "default",
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="patch_v3_job-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Updated job record|[JobRecord](#schemajobrecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v3_job

<a id="opIddelete_v3_job"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/jobs/{job_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/jobs/{job_id}`

*Delete JobRecord by job_id*

Delete a job record by job_id. This also deletes the underlying Kubernetes resources that were created when the job record was submitted.

<h3 id="delete_v3_job-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|job_id|path|string(uuid)|true|The unique ID of a job|

> Example responses

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

<h3 id="delete_v3_job-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Job record deleted successfully|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_all_v2_jobs

<a id="opIdget_all_v2_jobs"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/jobs HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/jobs \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/jobs', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/jobs", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /jobs`

*Retrieve a list of JobRecords that are registered with IMS*

Retrieve a list of JobRecords that are registered with IMS

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "job_type": "customize",
    "image_root_archive_name": "cray-sles12-sp3-barebones",
    "kernel_file_name": "vmlinuz",
    "initrd_file_name": "initrd",
    "kernel_parameters_file_name": "kernel-parameters",
    "status": "creating",
    "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
    "kubernetes_job": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-customize",
    "kubernetes_service": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-service",
    "kubernetes_configmap": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-configmap",
    "ssh_containers": [
      {
        "name": "customize",
        "jail": true,
        "status": "pending",
        "connection_info": {
          "property1": {
            "host": "10.100.20.221",
            "port": 22
          },
          "property2": {
            "host": "10.100.20.221",
            "port": 22
          }
        }
      }
    ],
    "enable_debug": true,
    "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
    "build_env_size": 15,
    "kubernetes_namespace": "default",
    "arch": "aarch64",
    "require_dkms": false
  }
]
```

<h3 id="get_all_v2_jobs-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of jobs|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v2_jobs-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[JobRecord](#schemajobrecord)]|false|none|[A Job Record]|
|» id|string(uuid)|false|read-only|Unique ID of the job|
|» created|string(date-time)|false|read-only|Time the image record was created|
|» job_type|[JobTypes](#schemajobtypes)|true|none|Type of job|
|» image_root_archive_name|string|true|none|Name to be given to the imageroot artifact (do not include .sqshfs or other extensions)|
|» kernel_file_name|string|false|none|Name of the kernel file to extract and upload to the artifact repository from the /boot directory of the image root.|
|» initrd_file_name|string|false|none|Name of the initrd image file to extract and upload to the artifact repository from the /boot directory of the image root.|
|» kernel_parameters_file_name|string|false|none|Name of the kernel-parameters file to extract and upload to the artifact repository from the /boot directory of the image root.|
|» status|[JobStatuses](#schemajobstatuses)|false|read-only|Status of the job|
|» artifact_id|string(uuid)|true|none|IMS artifact_id which specifies the recipe (create job_type) or the image (customize job_type) to fetch from the artifact repository.|
|» public_key_id|string(uuid)|true|none|Public key to use to enable passwordless SSH shells|
|» kubernetes_job|string|false|read-only|Name of the underlying kubernetes job|
|» kubernetes_service|string|false|read-only|Name of the underlying kubernetes service|
|» kubernetes_configmap|string|false|read-only|Name of the underlying kubernetes configmap|
|» ssh_containers|[[SshContainer](#schemasshcontainer)]|false|none|List of SSH containers used to customize images being built or modified|
|»» name|string|true|none|Name of the SSH container|
|»» jail|boolean|true|none|If true, establish an SSH jail, or chroot environment.|
|»» status|string|false|read-only|Status of the SSH container (pending, establishing, active, complete)|
|»» connection_info|object|false|none|none|
|»»» **additionalProperties**|object|false|none|none|
|»»»» host|string|false|read-only|IP or host name to use, in combination with the port, to connect to the SSH container|
|»»»» port|integer|false|read-only|Port to use, in combination with the host, to connect to the SSH container|
|» enable_debug|boolean|false|none|Whether to enable debugging of the job|
|» resultant_image_id|string(uuid)|false|read-only|IMS image ID for the resultant image.|
|» build_env_size|integer|false|none|Size (in Gb) to allocate for the image root. Default = 15|
|» kubernetes_namespace|string|false|read-only|Kubernetes namespace where the IMS job resources were created|
|» arch|string|false|read-only|Target architecture for the recipe.|
|» require_dkms|boolean|false|none|Whether enable DKMS for the job|

#### Enumerated Values

|Property|Value|
|---|---|
|job_type|create|
|job_type|customize|
|status|creating|
|status|fetching_image|
|status|fetching_recipe|
|status|waiting_for_repos|
|status|building_image|
|status|waiting_on_user|
|status|error|
|status|success|
|arch|aarch64|
|arch|x86_64|

<aside class="success">
This operation does not require authentication
</aside>

## post_v2_job

<a id="opIdpost_v2_job"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/ims/jobs HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/ims/jobs \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/ims/jobs', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/ims/jobs", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /jobs`

*Create JobRecord*

Create a new IMS image or modify an existing IMS image,
depending on request body parameter, job_type.

# Create

* Fetch recipe from the artifact repository and decompress to temp directory.
* Wait for required package repositories to become available.
* Call kiwi-ng, which builds the image root using
  the recipe in artifact repository and accesses packages in zypper/yum repositories.
* Upload the new image to the artifact repository, and save metadata to IMS - ImageRecord.
* If there is a failure, establish debug SSH shell, depending on value of enable_debug.  Admin
  can inspect image build root.
  **touch /mnt/image/complete** in a non-jailed environment or
  **touch /tmp/complete** in a jailed (chroot) environment to exit.

# Customize

* The artifact_id in the POST /job request body refers to an IMS ImageRecord. IMS uses
  the ImageRecord to read the Image's manifest.yaml to find the Image's
  root file system (rootfs) artifact.  IMS downloads the rootfs from the artifact
  repository and uncompresses it.
* IMS creates an SSH environment so admin can inspect and modify the image.
  For example, it may be necessary to modify the timezone, or
  modify the programming environment, etc.
  **touch /mnt/image/complete** in a non-jailed
  environment or **touch /tmp/complete** in a jailed (chroot) environment.
  to exit.
* IMS waits for the user to exit the ssh, then creates new IMS image
  record with the modifications, and adds the root
  certificate to the image. Note that IMS does not modify the original image
  but modifies a copy of it.
* IMS creates a new IMS ImageRecord, packages the IMS artifacts
  (kernel, initrd, rootfs), creates a manifest.json manifest file, and uploads
  all new artifacts to the artifact repository. The metadata is recorded by IMS
  and ImageRecord is updated.

> Body parameter

```json
{
  "job_type": "customize",
  "image_root_archive_name": "cray-sles12-sp3-barebones",
  "kernel_file_name": "vmlinuz",
  "initrd_file_name": "initrd",
  "kernel_parameters_file_name": "kernel-parameters",
  "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
  "ssh_containers": [
    {
      "name": "customize",
      "jail": true,
      "connection_info": {
        "property1": {},
        "property2": {}
      }
    }
  ],
  "enable_debug": true,
  "build_env_size": 15,
  "require_dkms": false
}
```

<h3 id="post_v2_job-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[JobRecord](#schemajobrecord)|true|Job record to create|

> Example responses

> 201 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "job_type": "customize",
  "image_root_archive_name": "cray-sles12-sp3-barebones",
  "kernel_file_name": "vmlinuz",
  "initrd_file_name": "initrd",
  "kernel_parameters_file_name": "kernel-parameters",
  "status": "creating",
  "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
  "kubernetes_job": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-customize",
  "kubernetes_service": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-service",
  "kubernetes_configmap": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-configmap",
  "ssh_containers": [
    {
      "name": "customize",
      "jail": true,
      "status": "pending",
      "connection_info": {
        "property1": {
          "host": "10.100.20.221",
          "port": 22
        },
        "property2": {
          "host": "10.100.20.221",
          "port": 22
        }
      }
    }
  ],
  "enable_debug": true,
  "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
  "build_env_size": 15,
  "kubernetes_namespace": "default",
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="post_v2_job-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|New job record|[JobRecord](#schemajobrecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v2_jobs

<a id="opIddelete_all_v2_jobs"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/jobs HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/jobs \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/jobs', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/jobs", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /jobs`

*Delete all JobRecords*

Delete all job records.

<h3 id="delete_all_v2_jobs-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|status|query|array[string]|false|List of job statues. Only jobs with matching statues are considered for deletion.|
|job_type|query|array[string]|false|Only jobs with matching job type are considered for deletion.|
|age|query|string|false|Only jobs older than the given age are considered for deletion.  Age is given in the format "1d" or "6h"|

#### Enumerated Values

|Parameter|Value|
|---|---|
|status|creating|
|status|fetching_image|
|status|fetching_recipe|
|status|waiting_for_repos|
|status|building_image|
|status|waiting_on_user|
|status|error|
|status|success|
|job_type|create|
|job_type|customize|

> Example responses

> 500 Response

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

<h3 id="delete_all_v2_jobs-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Job records deleted successfully|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_job

<a id="opIdget_v2_job"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/jobs/{job_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/jobs/{job_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/jobs/{job_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/jobs/{job_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /jobs/{job_id}`

*Retrieve a job by job_id*

Retrieve JobRecord by job_id

<h3 id="get_v2_job-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|job_id|path|string(uuid)|true|The unique ID of a job|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "job_type": "customize",
  "image_root_archive_name": "cray-sles12-sp3-barebones",
  "kernel_file_name": "vmlinuz",
  "initrd_file_name": "initrd",
  "kernel_parameters_file_name": "kernel-parameters",
  "status": "creating",
  "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
  "kubernetes_job": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-customize",
  "kubernetes_service": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-service",
  "kubernetes_configmap": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-configmap",
  "ssh_containers": [
    {
      "name": "customize",
      "jail": true,
      "status": "pending",
      "connection_info": {
        "property1": {
          "host": "10.100.20.221",
          "port": 22
        },
        "property2": {
          "host": "10.100.20.221",
          "port": 22
        }
      }
    }
  ],
  "enable_debug": true,
  "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
  "build_env_size": 15,
  "kubernetes_namespace": "default",
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="get_v2_job-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A job record|[JobRecord](#schemajobrecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v2_job

<a id="opIdpatch_v2_job"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/jobs/{job_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/jobs/{job_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/jobs/{job_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/jobs/{job_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /jobs/{job_id}`

*Update a JobRecord by job_id (Internal Use Only)*

Update a job record. Internal use only. Not for API consumers.

> Body parameter

```json
{
  "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
  "status": "creating"
}
```

<h3 id="patch_v2_job-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[JobPatchRecord](#schemajobpatchrecord)|true|Image Patch record|
|job_id|path|string(uuid)|true|The unique ID of a job|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "job_type": "customize",
  "image_root_archive_name": "cray-sles12-sp3-barebones",
  "kernel_file_name": "vmlinuz",
  "initrd_file_name": "initrd",
  "kernel_parameters_file_name": "kernel-parameters",
  "status": "creating",
  "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
  "kubernetes_job": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-customize",
  "kubernetes_service": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-service",
  "kubernetes_configmap": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-configmap",
  "ssh_containers": [
    {
      "name": "customize",
      "jail": true,
      "status": "pending",
      "connection_info": {
        "property1": {
          "host": "10.100.20.221",
          "port": 22
        },
        "property2": {
          "host": "10.100.20.221",
          "port": 22
        }
      }
    }
  ],
  "enable_debug": true,
  "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
  "build_env_size": 15,
  "kubernetes_namespace": "default",
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="patch_v2_job-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A job record|[JobRecord](#schemajobrecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v2_job

<a id="opIddelete_v2_job"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/jobs/{job_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/jobs/{job_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/jobs/{job_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/jobs/{job_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /jobs/{job_id}`

*Delete JobRecord by job_id*

Delete a job record by job_id. This also deletes the underlying Kubernetes resources that were created when the job record was submitted.

<h3 id="delete_v2_job-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|job_id|path|string(uuid)|true|The unique ID of a job|

> Example responses

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

<h3 id="delete_v2_job-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Job record deleted successfully|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="image-management-service-recipes">recipes</h1>

Interact with recipe records

## get_all_v3_recipes

<a id="opIdget_all_v3_recipes"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/recipes HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/recipes \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/recipes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/recipes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/recipes`

*Retrieve RecipeRecords*

Retrieve all RecipeRecords that are registered with the IMS.

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "link": {
      "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
      "etag": "f04af5f34635ae7c507322985e60c00c-131",
      "type": "s3"
    },
    "recipe_type": "kiwi-ng",
    "linux_distribution": "sles12",
    "name": "centos7.5_barebones",
    "template_dictionary": [
      {
        "key": "CSM_RELEASE_VERSION",
        "value": "1.0.0"
      }
    ],
    "arch": "aarch64",
    "require_dkms": false
  }
]
```

<h3 id="get_all_v3_recipes-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of recipes|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v3_recipes-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[RecipeRecord](#schemareciperecord)]|false|none|[A Recipe Record]|
|» id|string(uuid)|false|read-only|Unique ID of the recipe|
|» created|string(date-time)|false|read-only|Time the recipe record was created|
|» link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|»» path|string|true|none|Path or location to the artifact in the artifact repository|
|»» etag|string|false|none|Opaque identifier used to uniquely identify the artifact in the artifact repository|
|»» type|string|true|none|Identifier specifying the artifact repository where the artifact is located|
|» recipe_type|string|true|none|Type of recipe|
|» linux_distribution|string|true|none|Linux distribution being built|
|» name|string|true|none|Name of the image|
|» template_dictionary|[[RecipeKeyValuePair](#schemarecipekeyvaluepair)]|false|none|List of key/value pairs to be templated into the recipe when building the image.|
|»» key|string|true|none|Template variable to replace in the IMS recipe|
|»» value|string|true|none|Value to replace the template variable in the IMS recipe|
|» arch|string|false|none|Target architecture for the recipe.|
|» require_dkms|boolean|false|none|Whether to enable DKMS for the job|

#### Enumerated Values

|Property|Value|
|---|---|
|recipe_type|kiwi-ng|
|recipe_type|packer|
|linux_distribution|sles12|
|linux_distribution|sles15|
|linux_distribution|centos7|
|arch|aarch64|
|arch|x86_64|

<aside class="success">
This operation does not require authentication
</aside>

## post_v3_recipes

<a id="opIdpost_v3_recipes"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/ims/v3/recipes HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/ims/v3/recipes \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/ims/v3/recipes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/ims/v3/recipes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v3/recipes`

*Create a new recipe*

Create a new RecipeRecord in IMS.
A compressed Kiwi-NG image description is actually stored in the artifact repository. This IMS RecipeRecord contains metadata for the recipe.

> Body parameter

```json
{
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones",
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ],
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="post_v3_recipes-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[RecipeRecord](#schemareciperecord)|true|Recipe record|

> Example responses

> 201 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones",
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ],
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="post_v3_recipes-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|New Recipe record|[RecipeRecord](#schemareciperecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v3_recipes

<a id="opIddelete_all_v3_recipes"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/recipes HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/recipes \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/recipes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/recipes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/recipes`

*Soft delete all RecipeRecords*

Delete all RecipeRecords. Deleted recipes are soft deleted and added to the /deleted/recipes endpoint. The S3 key for associated artifacts is renamed.

> Example responses

> 500 Response

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

<h3 id="delete_all_v3_recipes-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Recipe records deleted successfully|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v3_recipe

<a id="opIdget_v3_recipe"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/recipes/{recipe_id}`

*Retrieve RecipeRecord by ID*

Retrieve a RecipeRecord by ID

<h3 id="get_v3_recipe-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|recipe_id|path|string(uuid)|true|The unique ID of a recipe|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones",
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ],
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="get_v3_recipe-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A recipe record|[RecipeRecord](#schemareciperecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v3_recipe

<a id="opIdpatch_v3_recipe"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/recipes/{recipe_id}`

*Update a recipe*

Update a RecipeRecord in IMS.

> Body parameter

```json
{
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64",
  "require_dkms": false,
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ]
}
```

<h3 id="patch_v3_recipe-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[RecipePatchRecord](#schemarecipepatchrecord)|true|Recipe Patch record|
|recipe_id|path|string(uuid)|true|The unique ID of a recipe|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones",
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ],
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="patch_v3_recipe-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Updated Recipe record|[RecipeRecord](#schemareciperecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Requested resource could not be patched due to conflict.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v3_recipe

<a id="opIddelete_v3_recipe"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/recipes/{recipe_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/recipes/{recipe_id}`

*Soft delete a RecipeRecord by ID*

Delete a RecipeRecord by ID. The deleted recipes are soft deleted and added to the /deleted/recipes endpoint. The S3 key for the associated artifact is renamed.

<h3 id="delete_v3_recipe-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|recipe_id|path|string(uuid)|true|The unique ID of a recipe|

> Example responses

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

<h3 id="delete_v3_recipe-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Recipe record deleted successfully|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_all_v3_deleted_recipes

<a id="opIdget_all_v3_deleted_recipes"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/deleted/recipes`

*Retrieve DeletedRecipeRecords*

Retrieve all DeletedRecipeRecords that are registered with the IMS.

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "deleted": "2018-07-28T03:26:01.234Z",
    "link": {
      "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
      "etag": "f04af5f34635ae7c507322985e60c00c-131",
      "type": "s3"
    },
    "recipe_type": "kiwi-ng",
    "arch": "aarch64",
    "require_dkms": false,
    "linux_distribution": "sles12",
    "name": "centos7.5_barebones"
  }
]
```

<h3 id="get_all_v3_deleted_recipes-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of deleted recipes|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v3_deleted_recipes-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[DeletedRecipeRecord](#schemadeletedreciperecord)]|false|none|[A Deleted Recipe Record]|
|» id|string(uuid)|false|read-only|Unique ID of the recipe|
|» created|string(date-time)|false|read-only|Time the recipe record was created|
|» deleted|string(date-time)|false|read-only|Time the recipe record was deleted|
|» link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|»» path|string|true|none|Path or location to the artifact in the artifact repository|
|»» etag|string|false|none|Opaque identifier used to uniquely identify the artifact in the artifact repository|
|»» type|string|true|none|Identifier specifying the artifact repository where the artifact is located|
|» recipe_type|string|true|none|Type of recipe|
|» arch|string|false|none|Target architecture for the recipe.|
|» require_dkms|boolean|false|none|Whether to enable DKMS for the job|
|» linux_distribution|string|true|none|Linux distribution being built|
|» name|string|true|none|Name of the image|

#### Enumerated Values

|Property|Value|
|---|---|
|recipe_type|kiwi-ng|
|recipe_type|packer|
|arch|aarch64|
|arch|x86_64|
|linux_distribution|sles12|
|linux_distribution|sles15|
|linux_distribution|centos7|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v3_deleted_recipes

<a id="opIddelete_all_v3_deleted_recipes"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/deleted/recipes`

*Permanently delete all DeletedRecipeRecords*

Permanently delete all DeletedRecipeRecords. Associated artifacts are permanently deleted from S3.

> Example responses

> 500 Response

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

<h3 id="delete_all_v3_deleted_recipes-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Recipe records were permanently deleted|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_all_v3_deleted_recipes

<a id="opIdpatch_all_v3_deleted_recipes"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/deleted/recipes`

*Restore all DeletedRecipeRecords in IMS.*

Restore all DeletedRecipeRecords in IMS.

> Body parameter

```json
{
  "operation": "undelete"
}
```

<h3 id="patch_all_v3_deleted_recipes-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[DeletedRecipePatchRecord](#schemadeletedrecipepatchrecord)|true|Deleted Recipe Patch record|

> Example responses

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

<h3 id="patch_all_v3_deleted_recipes-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Deleted recipe records updated successfully|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Requested resource could not be patched due to conflict.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v3_deleted_recipe

<a id="opIdget_v3_deleted_recipe"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/deleted/recipes/{recipe_id}`

*Retrieve DeletedRecipeRecord by ID*

Retrieve a DeletedRecipeRecord by ID

<h3 id="get_v3_deleted_recipe-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|recipe_id|path|string(uuid)|true|The unique ID of a deleted recipe|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "deleted": "2018-07-28T03:26:01.234Z",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "arch": "aarch64",
  "require_dkms": false,
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones"
}
```

<h3 id="get_v3_deleted_recipe-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A deleted recipe record|[DeletedRecipeRecord](#schemadeletedreciperecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v3_deleted_recipe

<a id="opIddelete_v3_deleted_recipe"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/deleted/recipes/{recipe_id}`

*Permanently delete a DeletedRecipeRecord by ID*

Permanently delete a DeletedRecipeRecord by ID. Associated artifacts are permanently deleted from S3.

<h3 id="delete_v3_deleted_recipe-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|recipe_id|path|string(uuid)|true|The unique ID of a deleted recipe|

> Example responses

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

<h3 id="delete_v3_deleted_recipe-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|RecipeRecord was permanently deleted|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v3_deleted_recipe

<a id="opIdpatch_v3_deleted_recipe"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/recipes/{recipe_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/deleted/recipes/{recipe_id}`

*Restore a DeletedRecipeRecord in IMS.*

Restore a DeletedRecipeRecord in IMS.

> Body parameter

```json
{
  "operation": "undelete"
}
```

<h3 id="patch_v3_deleted_recipe-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[DeletedRecipePatchRecord](#schemadeletedrecipepatchrecord)|true|Deleted Recipe Patch record|
|recipe_id|path|string(uuid)|true|The unique ID of a deleted recipe|

> Example responses

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

<h3 id="patch_v3_deleted_recipe-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Deleted recipe records updated successfully|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Requested resource could not be patched due to conflict.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_all_v2_recipes

<a id="opIdget_all_v2_recipes"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/recipes HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/recipes \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/recipes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/recipes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /recipes`

*Retrieve RecipeRecords*

Retrieve all RecipeRecords that are registered with the IMS.

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "link": {
      "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
      "etag": "f04af5f34635ae7c507322985e60c00c-131",
      "type": "s3"
    },
    "recipe_type": "kiwi-ng",
    "linux_distribution": "sles12",
    "name": "centos7.5_barebones",
    "template_dictionary": [
      {
        "key": "CSM_RELEASE_VERSION",
        "value": "1.0.0"
      }
    ],
    "arch": "aarch64",
    "require_dkms": false
  }
]
```

<h3 id="get_all_v2_recipes-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of recipes|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v2_recipes-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[RecipeRecord](#schemareciperecord)]|false|none|[A Recipe Record]|
|» id|string(uuid)|false|read-only|Unique ID of the recipe|
|» created|string(date-time)|false|read-only|Time the recipe record was created|
|» link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|»» path|string|true|none|Path or location to the artifact in the artifact repository|
|»» etag|string|false|none|Opaque identifier used to uniquely identify the artifact in the artifact repository|
|»» type|string|true|none|Identifier specifying the artifact repository where the artifact is located|
|» recipe_type|string|true|none|Type of recipe|
|» linux_distribution|string|true|none|Linux distribution being built|
|» name|string|true|none|Name of the image|
|» template_dictionary|[[RecipeKeyValuePair](#schemarecipekeyvaluepair)]|false|none|List of key/value pairs to be templated into the recipe when building the image.|
|»» key|string|true|none|Template variable to replace in the IMS recipe|
|»» value|string|true|none|Value to replace the template variable in the IMS recipe|
|» arch|string|false|none|Target architecture for the recipe.|
|» require_dkms|boolean|false|none|Whether to enable DKMS for the job|

#### Enumerated Values

|Property|Value|
|---|---|
|recipe_type|kiwi-ng|
|recipe_type|packer|
|linux_distribution|sles12|
|linux_distribution|sles15|
|linux_distribution|centos7|
|arch|aarch64|
|arch|x86_64|

<aside class="success">
This operation does not require authentication
</aside>

## post_v3_recipe

<a id="opIdpost_v3_recipe"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/ims/recipes HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/ims/recipes \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/ims/recipes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/ims/recipes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /recipes`

*Create a new recipe*

Create a new RecipeRecord in IMS.
A compressed Kiwi-NG image description is actually stored in the artifact repository. This IMS RecipeRecord contains metadata for the recipe.

> Body parameter

```json
{
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones",
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ],
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="post_v3_recipe-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[RecipeRecord](#schemareciperecord)|true|Recipe record|

> Example responses

> 201 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones",
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ],
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="post_v3_recipe-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|New recipe record|[RecipeRecord](#schemareciperecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v2_recipes

<a id="opIddelete_all_v2_recipes"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/recipes HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/recipes \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/recipes', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/recipes", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /recipes`

*Delete all RecipeRecords*

Delete all RecipeRecords.

<h3 id="delete_all_v2_recipes-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|cascade|query|boolean|false|If cascade is true, IMS also deletes the linked artifacts in S3. If cascade is false, the linked artifacts in S3 are not affected.|

> Example responses

> 500 Response

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

<h3 id="delete_all_v2_recipes-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Recipe records deleted successfully|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_recipe

<a id="opIdget_v2_recipe"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /recipes/{recipe_id}`

*Retrieve RecipeRecord by ID*

Retrieve a RecipeRecord by ID

<h3 id="get_v2_recipe-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|recipe_id|path|string(uuid)|true|The unique ID of a recipe|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones",
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ],
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="get_v2_recipe-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A recipe record|[RecipeRecord](#schemareciperecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v2_recipe

<a id="opIdpatch_v2_recipe"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /recipes/{recipe_id}`

*Update a recipe*

Update a RecipeRecord in IMS.

> Body parameter

```json
{
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64",
  "require_dkms": false,
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ]
}
```

<h3 id="patch_v2_recipe-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[RecipePatchRecord](#schemarecipepatchrecord)|true|Recipe Patch record|
|recipe_id|path|string(uuid)|true|The unique ID of a recipe|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones",
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ],
  "arch": "aarch64",
  "require_dkms": false
}
```

<h3 id="patch_v2_recipe-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Updated Recipe record|[RecipeRecord](#schemareciperecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Requested resource could not be patched due to conflict.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v2_recipe

<a id="opIddelete_v2_recipe"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/recipes/{recipe_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /recipes/{recipe_id}`

*Delete a RecipeRecord by ID*

Delete a recipe by ID.

<h3 id="delete_v2_recipe-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|cascade|query|boolean|false|If cascade is true, IMS also deletes the linked artifacts in S3. If cascade is false, the linked artifacts in S3 are not affected.|
|recipe_id|path|string(uuid)|true|The unique ID of a recipe|

> Example responses

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

<h3 id="delete_v2_recipe-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Recipe record deleted successfully|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="image-management-service-public-keys">public keys</h1>

Interact with public key records

## get_all_v3_public_keys

<a id="opIdget_all_v3_public_keys"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/public-keys HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/public-keys \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/public-keys', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/public-keys", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/public-keys`

*List public SSH keys*

Retrieve a list of public SSH keys that are registered with IMS.

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "name": "Eric's public key",
    "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
  }
]
```

<h3 id="get_all_v3_public_keys-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of keypairs|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v3_public_keys-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[PublicKeyRecord](#schemapublickeyrecord)]|false|none|[A Keypair Record]|
|» id|string(uuid)|false|read-only|Unique ID of the image|
|» created|string(date-time)|false|read-only|Time the image record was created|
|» name|string|true|none|Name of the public key|
|» public_key|string|true|none|The raw public key|

<aside class="success">
This operation does not require authentication
</aside>

## post_v3_public_key

<a id="opIdpost_v3_public_key"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/ims/v3/public-keys HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/ims/v3/public-keys \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/ims/v3/public-keys', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/ims/v3/public-keys", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v3/public-keys`

*Create a new public SSH key record*

Create a new public SSH key record. Uploaded by administrator to allow them to access SSH shells that IMS provides.

> Body parameter

```json
{
  "name": "Eric's public key",
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
}
```

<h3 id="post_v3_public_key-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[PublicKeyRecord](#schemapublickeyrecord)|true|Public key record to create|

> Example responses

> 201 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "Eric's public key",
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
}
```

<h3 id="post_v3_public_key-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|New PublicKey|[PublicKeyRecord](#schemapublickeyrecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v3_public_keys

<a id="opIddelete_all_v3_public_keys"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/public-keys HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/public-keys \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/public-keys', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/public-keys", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/public-keys`

*Soft delete all PublicKeyRecords*

Delete all public key-records. Deleted public-keys are soft deleted and added to the /deleted/public-keys endpoint.

> Example responses

> 500 Response

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

<h3 id="delete_all_v3_public_keys-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Public key records deleted successfully|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v3_public_key

<a id="opIdget_v3_public_key"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/public-keys/{public_key_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/public-keys/{public_key_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/public-keys/{public_key_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/public-keys/{public_key_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/public-keys/{public_key_id}`

*Retrieve a public key by public_key_id*

Retrieve a public key by public_key_id

<h3 id="get_v3_public_key-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|public_key_id|path|string(uuid)|true|The unique ID of a public key|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "Eric's public key",
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
}
```

<h3 id="get_v3_public_key-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A public key record|[PublicKeyRecord](#schemapublickeyrecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v3_public_key

<a id="opIddelete_v3_public_key"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/public-keys/{public_key_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/public-keys/{public_key_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/public-keys/{public_key_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/public-keys/{public_key_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/public-keys/{public_key_id}`

*Soft delete public key by public_key_id*

Delete a PublicKeyRecord by ID. Deleted public-keys are soft deleted and added to the /deleted/public-keys endpoint.

<h3 id="delete_v3_public_key-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|public_key_id|path|string(uuid)|true|The unique ID of a public key|

> Example responses

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

<h3 id="delete_v3_public_key-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Public Key record deleted successfully|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_all_v3_deleted_public_keys

<a id="opIdget_all_v3_deleted_public_keys"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/deleted/public-keys`

*List deleted public SSH keys*

Retrieve a list of deleted public SSH keys that are registered with IMS.

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "deleted": "2018-07-28T03:26:01.234Z",
    "name": "Eric's public key",
    "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
  }
]
```

<h3 id="get_all_v3_deleted_public_keys-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of keypairs|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v3_deleted_public_keys-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[DeletedPublicKeyRecord](#schemadeletedpublickeyrecord)]|false|none|[A Deleted Keypair Record]|
|» id|string(uuid)|false|read-only|Unique ID of the image|
|» created|string(date-time)|false|read-only|Time the image record was created|
|» deleted|string(date-time)|false|read-only|Time the image record was deleted|
|» name|string|true|none|Name of the public key|
|» public_key|string|true|none|The raw public key|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v3_deleted_public_keys

<a id="opIddelete_all_v3_deleted_public_keys"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/deleted/public-keys`

*Permanently delete all DeletedPublicKeyRecords*

Permanently delete all public key-records.

> Example responses

> 500 Response

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

<h3 id="delete_all_v3_deleted_public_keys-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|PublicKey records were permanently deleted|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_all_v3_deleted_public_keys

<a id="opIdpatch_all_v3_deleted_public_keys"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/deleted/public-keys`

*Restore all DeletedPublicKeyRecord in IMS.*

Restore all DeletedPublicKeyRecord in IMS.

> Body parameter

```json
{
  "operation": "undelete"
}
```

<h3 id="patch_all_v3_deleted_public_keys-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[DeletedPublicKeyPatchRecord](#schemadeletedpublickeypatchrecord)|true|Deleted PublicKey Patch record|

> Example responses

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

<h3 id="patch_all_v3_deleted_public_keys-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Deleted public key records updated successfully|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Requested resource could not be patched due to conflict.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v3_deleted_public_key

<a id="opIdget_v3_deleted_public_key"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v3/deleted/public-keys/{deleted_public_key_id}`

*Retrieve a deleted public key by deleted_public_key_id*

Retrieve a deleted public key by deleted_public_key_id

<h3 id="get_v3_deleted_public_key-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|deleted_public_key_id|path|string(uuid)|true|The unique ID of a deleted public key|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "deleted": "2018-07-28T03:26:01.234Z",
  "name": "Eric's public key",
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
}
```

<h3 id="get_v3_deleted_public_key-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A deleted public key record|[DeletedPublicKeyRecord](#schemadeletedpublickeyrecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v3_deleted_public_key

<a id="opIddelete_v3_deleted_public_key"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /v3/deleted/public-keys/{deleted_public_key_id}`

*Permanently delete public key by deleted_public_key_id*

Permanently delete a DeletedPublicKeyRecord by ID.

<h3 id="delete_v3_deleted_public_key-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|deleted_public_key_id|path|string(uuid)|true|The unique ID of a deleted public key|

> Example responses

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

<h3 id="delete_v3_deleted_public_key-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|PublicKeyRecord was permanently deleted|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## patch_v3_deleted_public_key

<a id="opIdpatch_v3_deleted_public_key"></a>

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/ims/v3/deleted/public-keys/{deleted_public_key_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /v3/deleted/public-keys/{deleted_public_key_id}`

*Restore a DeletedPublicKeyRecord in IMS.*

Restore a DeletedPublicKeyRecord in IMS.

> Body parameter

```json
{
  "operation": "undelete"
}
```

<h3 id="patch_v3_deleted_public_key-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[DeletedPublicKeyPatchRecord](#schemadeletedpublickeypatchrecord)|true|DeletedPublicKey Patch record|
|deleted_public_key_id|path|string(uuid)|true|The unique ID of a deleted public key|

> Example responses

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

<h3 id="patch_v3_deleted_public_key-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Deleted public key record updated successfully|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|409|[Conflict](https://tools.ietf.org/html/rfc7231#section-6.5.8)|Requested resource could not be patched due to conflict.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_all_v2_public_keys

<a id="opIdget_all_v2_public_keys"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/public-keys HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/public-keys \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/public-keys', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/public-keys", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /public-keys`

*List public SSH keys*

Retrieve a list of public SSH keys that are registered with IMS.

> Example responses

> 200 Response

```json
[
  {
    "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
    "created": "2018-07-28T03:26:01.234Z",
    "name": "Eric's public key",
    "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
  }
]
```

<h3 id="get_all_v2_public_keys-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of keypairs|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<h3 id="get_all_v2_public_keys-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[PublicKeyRecord](#schemapublickeyrecord)]|false|none|[A Keypair Record]|
|» id|string(uuid)|false|read-only|Unique ID of the image|
|» created|string(date-time)|false|read-only|Time the image record was created|
|» name|string|true|none|Name of the public key|
|» public_key|string|true|none|The raw public key|

<aside class="success">
This operation does not require authentication
</aside>

## post_v2_public_key

<a id="opIdpost_v2_public_key"></a>

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/ims/public-keys HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/ims/public-keys \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/ims/public-keys', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/ims/public-keys", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /public-keys`

*Create a new public SSH key record*

Create a new public SSH key record. Uploaded by administrator to allow them to access SSH shells that IMS provides.

> Body parameter

```json
{
  "name": "Eric's public key",
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
}
```

<h3 id="post_v2_public_key-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[PublicKeyRecord](#schemapublickeyrecord)|true|Public key record to create|

> Example responses

> 201 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "Eric's public key",
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
}
```

<h3 id="post_v2_public_key-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|New public key|[PublicKeyRecord](#schemapublickeyrecord)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|No input provided. Determine the specific information that is missing or invalid and then re-run the request with valid information.|[ProblemDetails](#schemaproblemdetails)|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Input data was understood, but failed validation. Re-run request with valid input values for the fields indicated in the response.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_all_v2_public_keys

<a id="opIddelete_all_v2_public_keys"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/public-keys HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/public-keys \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/public-keys', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/public-keys", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /public-keys`

*Delete all PublicKeyRecords*

Delete all public key records.

> Example responses

> 500 Response

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

<h3 id="delete_all_v2_public_keys-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Public key records deleted successfully|None|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## get_v2_public_key

<a id="opIdget_v2_public_key"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/public-keys/{public_key_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/public-keys/{public_key_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/public-keys/{public_key_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/public-keys/{public_key_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /public-keys/{public_key_id}`

*Retrieve a public key by public_key_id*

Retrieve a public key by public_key_id

<h3 id="get_v2_public_key-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|public_key_id|path|string(uuid)|true|The unique ID of a public key|

> Example responses

> 200 Response

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "Eric's public key",
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
}
```

<h3 id="get_v2_public_key-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A public key record|[PublicKeyRecord](#schemapublickeyrecord)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

## delete_v2_public_key

<a id="opIddelete_v2_public_key"></a>

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/ims/public-keys/{public_key_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/ims/public-keys/{public_key_id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/ims/public-keys/{public_key_id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/ims/public-keys/{public_key_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /public-keys/{public_key_id}`

*Delete public key by public_key_id*

Delete a public key by public_key_id.

<h3 id="delete_v2_public_key-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|public_key_id|path|string(uuid)|true|The unique ID of a public key|

> Example responses

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

<h3 id="delete_v2_public_key-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Public Key record deleted successfully|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Requested resource does not exist. Re-run request with valid ID.|[ProblemDetails](#schemaproblemdetails)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="image-management-service-version">version</h1>

Get version

## getVersion

<a id="opIdgetVersion"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/ims/version HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/ims/version \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/ims/version', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/ims/version", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /version`

*Get IMS version*

Retrieve the version of the IMS Service

> Example responses

> 200 Response

```json
"string"
```

<h3 id="getversion-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|IMS Version|string|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|An internal error occurred. Re-running the request may or may not succeed.|[ProblemDetails](#schemaproblemdetails)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_SSHConnectionInfo">SSHConnectionInfo</h2>
<!-- backwards compatibility -->
<a id="schemasshconnectioninfo"></a>
<a id="schema_SSHConnectionInfo"></a>
<a id="tocSsshconnectioninfo"></a>
<a id="tocssshconnectioninfo"></a>

```json
{
  "host": "10.100.20.221",
  "port": 22
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|host|string|false|read-only|IP or host name to use, in combination with the port, to connect to the SSH container|
|port|integer|false|read-only|Port to use, in combination with the host, to connect to the SSH container|

<h2 id="tocS_SSHConnectionMap">SSHConnectionMap</h2>
<!-- backwards compatibility -->
<a id="schemasshconnectionmap"></a>
<a id="schema_SSHConnectionMap"></a>
<a id="tocSsshconnectionmap"></a>
<a id="tocssshconnectionmap"></a>

```json
{
  "property1": {
    "host": "10.100.20.221",
    "port": 22
  },
  "property2": {
    "host": "10.100.20.221",
    "port": 22
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|**additionalProperties**|[SSHConnectionInfo](#schemasshconnectioninfo)|false|none|none|

<h2 id="tocS_SshContainer">SshContainer</h2>
<!-- backwards compatibility -->
<a id="schemasshcontainer"></a>
<a id="schema_SshContainer"></a>
<a id="tocSsshcontainer"></a>
<a id="tocssshcontainer"></a>

```json
{
  "name": "customize",
  "jail": true,
  "status": "pending",
  "connection_info": {
    "property1": {
      "host": "10.100.20.221",
      "port": 22
    },
    "property2": {
      "host": "10.100.20.221",
      "port": 22
    }
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|true|none|Name of the SSH container|
|jail|boolean|true|none|If true, establish an SSH jail, or chroot environment.|
|status|string|false|read-only|Status of the SSH container (pending, establishing, active, complete)|
|connection_info|[SSHConnectionMap](#schemasshconnectionmap)|false|none|none|

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

<h2 id="tocS_PublicKeyRecord">PublicKeyRecord</h2>
<!-- backwards compatibility -->
<a id="schemapublickeyrecord"></a>
<a id="schema_PublicKeyRecord"></a>
<a id="tocSpublickeyrecord"></a>
<a id="tocspublickeyrecord"></a>

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "Eric's public key",
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
}

```

A Keypair Record

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string(uuid)|false|read-only|Unique ID of the image|
|created|string(date-time)|false|read-only|Time the image record was created|
|name|string|true|none|Name of the public key|
|public_key|string|true|none|The raw public key|

<h2 id="tocS_DeletedPublicKeyRecord">DeletedPublicKeyRecord</h2>
<!-- backwards compatibility -->
<a id="schemadeletedpublickeyrecord"></a>
<a id="schema_DeletedPublicKeyRecord"></a>
<a id="tocSdeletedpublickeyrecord"></a>
<a id="tocsdeletedpublickeyrecord"></a>

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "deleted": "2018-07-28T03:26:01.234Z",
  "name": "Eric's public key",
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
}

```

A Deleted Keypair Record

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string(uuid)|false|read-only|Unique ID of the image|
|created|string(date-time)|false|read-only|Time the image record was created|
|deleted|string(date-time)|false|read-only|Time the image record was deleted|
|name|string|true|none|Name of the public key|
|public_key|string|true|none|The raw public key|

<h2 id="tocS_ArtifactLinkRecord">ArtifactLinkRecord</h2>
<!-- backwards compatibility -->
<a id="schemaartifactlinkrecord"></a>
<a id="schema_ArtifactLinkRecord"></a>
<a id="tocSartifactlinkrecord"></a>
<a id="tocsartifactlinkrecord"></a>

```json
{
  "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
  "etag": "f04af5f34635ae7c507322985e60c00c-131",
  "type": "s3"
}

```

An Artifact Link Record

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|path|string|true|none|Path or location to the artifact in the artifact repository|
|etag|string|false|none|Opaque identifier used to uniquely identify the artifact in the artifact repository|
|type|string|true|none|Identifier specifying the artifact repository where the artifact is located|

<h2 id="tocS_RecipeKeyValuePair">RecipeKeyValuePair</h2>
<!-- backwards compatibility -->
<a id="schemarecipekeyvaluepair"></a>
<a id="schema_RecipeKeyValuePair"></a>
<a id="tocSrecipekeyvaluepair"></a>
<a id="tocsrecipekeyvaluepair"></a>

```json
{
  "key": "CSM_RELEASE_VERSION",
  "value": "1.0.0"
}

```

Key/value pair used to template an IMS recipe

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|key|string|true|none|Template variable to replace in the IMS recipe|
|value|string|true|none|Value to replace the template variable in the IMS recipe|

<h2 id="tocS_RecipeRecord">RecipeRecord</h2>
<!-- backwards compatibility -->
<a id="schemareciperecord"></a>
<a id="schema_RecipeRecord"></a>
<a id="tocSreciperecord"></a>
<a id="tocsreciperecord"></a>

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones",
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ],
  "arch": "aarch64",
  "require_dkms": false
}

```

A Recipe Record

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string(uuid)|false|read-only|Unique ID of the recipe|
|created|string(date-time)|false|read-only|Time the recipe record was created|
|link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|recipe_type|string|true|none|Type of recipe|
|linux_distribution|string|true|none|Linux distribution being built|
|name|string|true|none|Name of the image|
|template_dictionary|[[RecipeKeyValuePair](#schemarecipekeyvaluepair)]|false|none|List of key/value pairs to be templated into the recipe when building the image.|
|arch|string|false|none|Target architecture for the recipe.|
|require_dkms|boolean|false|none|Whether to enable DKMS for the job|

#### Enumerated Values

|Property|Value|
|---|---|
|recipe_type|kiwi-ng|
|recipe_type|packer|
|linux_distribution|sles12|
|linux_distribution|sles15|
|linux_distribution|centos7|
|arch|aarch64|
|arch|x86_64|

<h2 id="tocS_DeletedRecipeRecord">DeletedRecipeRecord</h2>
<!-- backwards compatibility -->
<a id="schemadeletedreciperecord"></a>
<a id="schema_DeletedRecipeRecord"></a>
<a id="tocSdeletedreciperecord"></a>
<a id="tocsdeletedreciperecord"></a>

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "deleted": "2018-07-28T03:26:01.234Z",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "recipe_type": "kiwi-ng",
  "arch": "aarch64",
  "require_dkms": false,
  "linux_distribution": "sles12",
  "name": "centos7.5_barebones"
}

```

A Deleted Recipe Record

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string(uuid)|false|read-only|Unique ID of the recipe|
|created|string(date-time)|false|read-only|Time the recipe record was created|
|deleted|string(date-time)|false|read-only|Time the recipe record was deleted|
|link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|recipe_type|string|true|none|Type of recipe|
|arch|string|false|none|Target architecture for the recipe.|
|require_dkms|boolean|false|none|Whether to enable DKMS for the job|
|linux_distribution|string|true|none|Linux distribution being built|
|name|string|true|none|Name of the image|

#### Enumerated Values

|Property|Value|
|---|---|
|recipe_type|kiwi-ng|
|recipe_type|packer|
|arch|aarch64|
|arch|x86_64|
|linux_distribution|sles12|
|linux_distribution|sles15|
|linux_distribution|centos7|

<h2 id="tocS_RecipePatchRecord">RecipePatchRecord</h2>
<!-- backwards compatibility -->
<a id="schemarecipepatchrecord"></a>
<a id="schema_RecipePatchRecord"></a>
<a id="tocSrecipepatchrecord"></a>
<a id="tocsrecipepatchrecord"></a>

```json
{
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64",
  "require_dkms": false,
  "template_dictionary": [
    {
      "key": "CSM_RELEASE_VERSION",
      "value": "1.0.0"
    }
  ]
}

```

Values to update a RecipeRecord with

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|arch|string|false|none|Target architecture for the recipe.|
|require_dkms|boolean|false|none|Whether enable DKMS for the job|
|template_dictionary|[[RecipeKeyValuePair](#schemarecipekeyvaluepair)]|false|none|List of key/value pairs to be templated into the recipe when building the image.|

#### Enumerated Values

|Property|Value|
|---|---|
|arch|aarch64|
|arch|x86_64|

<h2 id="tocS_ImageRecord">ImageRecord</h2>
<!-- backwards compatibility -->
<a id="schemaimagerecord"></a>
<a id="schema_ImageRecord"></a>
<a id="tocSimagerecord"></a>
<a id="tocsimagerecord"></a>

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}

```

An Image Record

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string(uuid)|false|read-only|Unique ID of the image.|
|created|string(date-time)|false|read-only|Time the image record was created|
|name|string|true|none|Name of the image|
|link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|arch|string|false|none|Target architecture for the recipe.|

#### Enumerated Values

|Property|Value|
|---|---|
|arch|aarch64|
|arch|x86_64|

<h2 id="tocS_DeletedImageRecord">DeletedImageRecord</h2>
<!-- backwards compatibility -->
<a id="schemadeletedimagerecord"></a>
<a id="schema_DeletedImageRecord"></a>
<a id="tocSdeletedimagerecord"></a>
<a id="tocsdeletedimagerecord"></a>

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "deleted": "2018-07-28T03:26:01.234Z",
  "name": "centos7.5_barebones",
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}

```

A Deleted Image Record

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string(uuid)|false|read-only|Unique ID of the image.|
|created|string(date-time)|false|read-only|Time the image record was created|
|deleted|string(date-time)|false|read-only|Time the image record was deleted|
|name|string|true|none|Name of the image|
|link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|arch|string|false|none|Target architecture for the recipe.|

#### Enumerated Values

|Property|Value|
|---|---|
|arch|aarch64|
|arch|x86_64|

<h2 id="tocS_ImagePatchRecord">ImagePatchRecord</h2>
<!-- backwards compatibility -->
<a id="schemaimagepatchrecord"></a>
<a id="schema_ImagePatchRecord"></a>
<a id="tocSimagepatchrecord"></a>
<a id="tocsimagepatchrecord"></a>

```json
{
  "link": {
    "path": "s3://boot-images/1fb58f4e-ad23-489b-89b7-95868fca7ee6/manifest.json",
    "etag": "f04af5f34635ae7c507322985e60c00c-131",
    "type": "s3"
  },
  "arch": "aarch64"
}

```

Values to update an ImageRecord with

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|link|[ArtifactLinkRecord](#schemaartifactlinkrecord)|false|none|An Artifact Link Record|
|arch|string|false|none|Target architecture for the recipe.|

#### Enumerated Values

|Property|Value|
|---|---|
|arch|aarch64|
|arch|x86_64|

<h2 id="tocS_JobRecord">JobRecord</h2>
<!-- backwards compatibility -->
<a id="schemajobrecord"></a>
<a id="schema_JobRecord"></a>
<a id="tocSjobrecord"></a>
<a id="tocsjobrecord"></a>

```json
{
  "id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "created": "2018-07-28T03:26:01.234Z",
  "job_type": "customize",
  "image_root_archive_name": "cray-sles12-sp3-barebones",
  "kernel_file_name": "vmlinuz",
  "initrd_file_name": "initrd",
  "kernel_parameters_file_name": "kernel-parameters",
  "status": "creating",
  "artifact_id": "46a2731e-a1d0-4f98-ba92-4f78c756bb12",
  "public_key_id": "b05c54e3-9fc2-472d-b120-4fd718ff90aa",
  "kubernetes_job": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-customize",
  "kubernetes_service": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-service",
  "kubernetes_configmap": "cray-ims-46a2731e-a1d0-4f98-ba92-4f78c756bb12-configmap",
  "ssh_containers": [
    {
      "name": "customize",
      "jail": true,
      "status": "pending",
      "connection_info": {
        "property1": {
          "host": "10.100.20.221",
          "port": 22
        },
        "property2": {
          "host": "10.100.20.221",
          "port": 22
        }
      }
    }
  ],
  "enable_debug": true,
  "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
  "build_env_size": 15,
  "kubernetes_namespace": "default",
  "arch": "aarch64",
  "require_dkms": false
}

```

A Job Record

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|string(uuid)|false|read-only|Unique ID of the job|
|created|string(date-time)|false|read-only|Time the image record was created|
|job_type|[JobTypes](#schemajobtypes)|true|none|Type of job|
|image_root_archive_name|string|true|none|Name to be given to the imageroot artifact (do not include .sqshfs or other extensions)|
|kernel_file_name|string|false|none|Name of the kernel file to extract and upload to the artifact repository from the /boot directory of the image root.|
|initrd_file_name|string|false|none|Name of the initrd image file to extract and upload to the artifact repository from the /boot directory of the image root.|
|kernel_parameters_file_name|string|false|none|Name of the kernel-parameters file to extract and upload to the artifact repository from the /boot directory of the image root.|
|status|[JobStatuses](#schemajobstatuses)|false|read-only|Status of the job|
|artifact_id|string(uuid)|true|none|IMS artifact_id which specifies the recipe (create job_type) or the image (customize job_type) to fetch from the artifact repository.|
|public_key_id|string(uuid)|true|none|Public key to use to enable passwordless SSH shells|
|kubernetes_job|string|false|read-only|Name of the underlying kubernetes job|
|kubernetes_service|string|false|read-only|Name of the underlying kubernetes service|
|kubernetes_configmap|string|false|read-only|Name of the underlying kubernetes configmap|
|ssh_containers|[[SshContainer](#schemasshcontainer)]|false|none|List of SSH containers used to customize images being built or modified|
|enable_debug|boolean|false|none|Whether to enable debugging of the job|
|resultant_image_id|string(uuid)|false|read-only|IMS image ID for the resultant image.|
|build_env_size|integer|false|none|Size (in Gb) to allocate for the image root. Default = 15|
|kubernetes_namespace|string|false|read-only|Kubernetes namespace where the IMS job resources were created|
|arch|string|false|read-only|Target architecture for the recipe.|
|require_dkms|boolean|false|none|Whether enable DKMS for the job|

#### Enumerated Values

|Property|Value|
|---|---|
|arch|aarch64|
|arch|x86_64|

<h2 id="tocS_JobPatchRecord">JobPatchRecord</h2>
<!-- backwards compatibility -->
<a id="schemajobpatchrecord"></a>
<a id="schema_JobPatchRecord"></a>
<a id="tocSjobpatchrecord"></a>
<a id="tocsjobpatchrecord"></a>

```json
{
  "resultant_image_id": "e564cd0a-f222-4f30-8337-62184e2dd86d",
  "status": "creating"
}

```

Values to update a JobRecord with

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|resultant_image_id|string(uuid)|false|none|IMS image ID for the resultant image.|
|status|[JobStatuses](#schemajobstatuses)|false|none|Status of the job|

<h2 id="tocS_JobStatuses">JobStatuses</h2>
<!-- backwards compatibility -->
<a id="schemajobstatuses"></a>
<a id="schema_JobStatuses"></a>
<a id="tocSjobstatuses"></a>
<a id="tocsjobstatuses"></a>

```json
"creating"

```

Status of the job

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Status of the job|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|creating|
|*anonymous*|fetching_image|
|*anonymous*|fetching_recipe|
|*anonymous*|waiting_for_repos|
|*anonymous*|building_image|
|*anonymous*|waiting_on_user|
|*anonymous*|error|
|*anonymous*|success|

<h2 id="tocS_JobTypes">JobTypes</h2>
<!-- backwards compatibility -->
<a id="schemajobtypes"></a>
<a id="schema_JobTypes"></a>
<a id="tocSjobtypes"></a>
<a id="tocsjobtypes"></a>

```json
"customize"

```

Type of job

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Type of job|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|create|
|*anonymous*|customize|

<h2 id="tocS_DeletedObjectPatchOperations">DeletedObjectPatchOperations</h2>
<!-- backwards compatibility -->
<a id="schemadeletedobjectpatchoperations"></a>
<a id="schema_DeletedObjectPatchOperations"></a>
<a id="tocSdeletedobjectpatchoperations"></a>
<a id="tocsdeletedobjectpatchoperations"></a>

```json
"undelete"

```

Patch operations that can be performed on a deleted IMS object

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Patch operations that can be performed on a deleted IMS object|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|undelete|

<h2 id="tocS_DeletedRecipePatchRecord">DeletedRecipePatchRecord</h2>
<!-- backwards compatibility -->
<a id="schemadeletedrecipepatchrecord"></a>
<a id="schema_DeletedRecipePatchRecord"></a>
<a id="tocSdeletedrecipepatchrecord"></a>
<a id="tocsdeletedrecipepatchrecord"></a>

```json
{
  "operation": "undelete"
}

```

Values to update a DeletedRecipeRecord with

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|operation|[DeletedObjectPatchOperations](#schemadeletedobjectpatchoperations)|false|none|Patch operations that can be performed on a deleted IMS object|

<h2 id="tocS_DeletedImagePatchRecord">DeletedImagePatchRecord</h2>
<!-- backwards compatibility -->
<a id="schemadeletedimagepatchrecord"></a>
<a id="schema_DeletedImagePatchRecord"></a>
<a id="tocSdeletedimagepatchrecord"></a>
<a id="tocsdeletedimagepatchrecord"></a>

```json
{
  "operation": "undelete"
}

```

Values to update a DeletedImageRecord with

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|operation|[DeletedObjectPatchOperations](#schemadeletedobjectpatchoperations)|false|none|Patch operations that can be performed on a deleted IMS object|

<h2 id="tocS_DeletedPublicKeyPatchRecord">DeletedPublicKeyPatchRecord</h2>
<!-- backwards compatibility -->
<a id="schemadeletedpublickeypatchrecord"></a>
<a id="schema_DeletedPublicKeyPatchRecord"></a>
<a id="tocSdeletedpublickeypatchrecord"></a>
<a id="tocsdeletedpublickeypatchrecord"></a>

```json
{
  "operation": "undelete"
}

```

Values to update a DeletedPublicKeyRecord with

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|operation|[DeletedObjectPatchOperations](#schemadeletedobjectpatchoperations)|false|none|Patch operations that can be performed on a deleted IMS object|

