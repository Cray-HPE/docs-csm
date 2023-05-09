<!-- Generator: Widdershins v4.0.1 -->

<h1 id="lock-and-reservation-service">Lock & Reservation Service v2</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

Hello world

Base URLs:

* <a href="https://rocket-ncn-w001.us.cray.com/apis/ifs/v1">https://rocket-ncn-w001.us.cray.com/apis/ifs/v1</a>

* <a href="http://localhost:28800/v1">http://localhost:28800/v1</a>

* <a href="http://localhost:28800/">http://localhost:28800/</a>

<h1 id="lock-and-reservation-service-admin-reservations">admin-reservations</h1>

## patch__locks_reservations_remove

> Code samples

```http
PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations/remove HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations/remove \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations/remove', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations/remove", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /locks/reservations/remove`

*Forcibly deletes existing reservations.*

Given a list of components, forcibly deletes any existing reservation. Does not change lock state; does not disable the reservation ability of the component. An empty set of xnames will delete reservations on all xnames. This functionality should be used sparingly, the normal flow should be to release reservations, versus removing them.

> Body parameter

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker"
}
```

<h3 id="patch__locks_reservations_remove-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminReservationRemove.1.0.0](#schemaadminreservationremove.1.0.0)|true|list of xnames to remove reservations. A `rigid` processing model will result in the entire set of xnames not having their reservation removed if an xname does exist, or isnt reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="patch__locks_reservations_remove-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted. Returns a count + list of xnames that succeeded or failed the operation.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure recieved. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__locks_reservations_release

> Code samples

```http
PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations/release HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations/release \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations/release', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations/release", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /locks/reservations/release`

*Releases existing reservations.*

Given a list of {xname & reservation key}, releases the associated reservations.

> Body parameter

```json
{
  "ReservationKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ],
  "ProcessingModel": "rigid"
}
```

<h3 id="patch__locks_reservations_release-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ReservedKeys.1.0.0](#schemareservedkeys.1.0.0)|true|list of {xname and reservation key} to release reservations. A `rigid` processing model will result in the entire set of xnames not having their reservation released if an xname does exist, or isnt reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="patch__locks_reservations_release-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted. Returns a count + list of xnames that succeeded or failed the operation.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure recieved. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__locks_reservations

> Code samples

```http
PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/reservations", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /locks/reservations`

*Create reservations*

Creates reservations on a set of xnames of infinite duration.  Component must be locked to create a reservation.

> Body parameter

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker"
}
```

<h3 id="patch__locks_reservations-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminReservationCreate.1.0.0](#schemaadminreservationcreate.1.0.0)|true|List of components to create reservations. A `rigid` processing model will result in the entire set of xnames not having reservations created if an xname does exist, or isnt locked, or if already reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "347068b9-dbe0-4830-bf75-819cb2cd0712",
      "ReservationKey": "fdf03933-aef4-43bb-b6bf-551af3fbaa64"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="patch__locks_reservations-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|accepted request.  See response for details.|[AdminReservationCreate_Response.1.0.0](#schemaadminreservationcreate_response.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure recieved. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not accept reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="lock-and-reservation-service-service-reservations">service-reservations</h1>

## patch__locks_service_reservations_release

> Code samples

```http
PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/release HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/release \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/release', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/release", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /locks/service/reservations/release`

*Releases existing reservations.*

Given a list of {xname & reservation key}, releases the associated reservations.

> Body parameter

```json
{
  "ReservationKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ],
  "ProcessingModel": "rigid"
}
```

<h3 id="patch__locks_service_reservations_release-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ReservedKeys.1.0.0](#schemareservedkeys.1.0.0)|true|list of {xname and reservation key} to release reservations. A `rigid` processing model will result in the entire set of xnames not having their reservation released if an xname does exist, or isnt reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="patch__locks_service_reservations_release-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted. Returns a count + list of xnames that succeeded or failed the operation.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure recieved. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## post__locks_service_reservations

> Code samples

```http
POST https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/service/reservations`

*Create reservations*

Creates reservations on a set of xnames of infinite duration.  Component must be locked to create a reservation.

> Body parameter

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker",
  "ReservationDuration": 1
}
```

<h3 id="post__locks_service_reservations-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ServiceReservationCreate.1.0.0](#schemaservicereservationcreate.1.0.0)|true|List of components to create reservations. A `rigid` processing model will result in the entire set of xnames not having reservations created if an xname does exist, or isnt locked, or if already reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "347068b9-dbe0-4830-bf75-819cb2cd0712",
      "ReservationKey": "fdf03933-aef4-43bb-b6bf-551af3fbaa64",
      "ExpirationTime": "2019-08-24T14:15:22Z"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="post__locks_service_reservations-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|accepted request.  See response for details.|[ServiceReservationCreate_Response.1.0.0](#schemaservicereservationcreate_response.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure recieved. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not accept reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__locks_service_reservations_renew

> Code samples

```http
PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/renew HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/renew \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/renew', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/renew", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /locks/service/reservations/renew`

*Renew existing reservations.*

Given a list of {xname & reservation key}, renews the associated reservations.

> Body parameter

```json
{
  "ReservationKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ],
  "ProcessingModel": "rigid",
  "ReservationDuration": 1
}
```

<h3 id="patch__locks_service_reservations_renew-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[ReservedKeysWithRenewal.1.0.0](#schemareservedkeyswithrenewal.1.0.0)|true|list of {xname and reservation key} to renew reservations. A `rigid` processing model will result in the entire set of xnames not having their reservation renewed if an xname does exist, or isnt reserved. A `flexible` processing model will perform all actions possible.|

> Example responses

> 202 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="patch__locks_service_reservations_renew-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted. Returns a count + list of xnames that succeeded or failed the operation.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request; something is wrong with the structure recieved. Will not be used to represent failure to accomplish the operation, that will be returned in the standard payload.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__locks_service_reservations_check

> Code samples

```http
PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/check HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/check \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/check', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/service/reservations/check", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /locks/service/reservations/check`

*check the validity of reservations*

using xname + reservation key check on the validity of reservations.  

> Body parameter

```json
{
  "DeputyKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ]
}
```

<h3 id="patch__locks_service_reservations_check-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[DeputyKeys.1.0.0](#schemadeputykeys.1.0.0)|true|List of components & deputy keys to check on validity of reservations.|

> Example responses

> 202 Response

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "347068b9-dbe0-4830-bf75-819cb2cd0712",
      "ExpirationTime": "2019-08-24T14:15:22Z"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="patch__locks_service_reservations_check-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|created reservations|[ServiceReservationCheck_Response.1.0.0](#schemaservicereservationcheck_response.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="lock-and-reservation-service-admin-locks">admin-locks</h1>

## post__locks_status

> Code samples

```http
POST https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/status HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/status \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/status', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /locks/status`

*Retrieve lock status for component IDs*

Using component ID retrieve the status of any lock and/or reservation

> Body parameter

```json
{
  "ComponentIDs": [
    "string"
  ]
}
```

<h3 id="post__locks_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[Xnames](#schemaxnames)|true|list of components to retrieve status|

> Example responses

> 202 Response

```json
{
  "Components": [
    {
      "ID": "x1001c0s0b0",
      "Locked": false,
      "Reserved": true,
      "ExpirationTime": "2019-08-24T14:15:22Z",
      "ReservationDisabled": false
    }
  ],
  "NotFound": [
    "x1000c0s0b0"
  ]
}
```

> 400 Response

<h3 id="post__locks_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|created reservations|[AdminStatusCheck_Response.1.0.0](#schemaadminstatuscheck_response.1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__locks_lock

> Code samples

```http
PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/lock HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/lock \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/lock', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/lock", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /locks/lock`

*locks components*

Using a component create a lock.  Cannot be locked if already locked, or if there is a current reservation. 

> Body parameter

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker"
}
```

<h3 id="patch__locks_lock-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminLock.1.0.0](#schemaadminlock.1.0.0)|true|list of xnames to delete|

> Example responses

> 200 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="patch__locks_lock-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Zero (success) error code - one or more entries deleted. Message contains count of deleted items.|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__locks_unlock

> Code samples

```http
PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/unlock HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/unlock \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/unlock', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/unlock", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /locks/unlock`

*unlocks components*

Using a component unlock a lock.  Cannot be unlocked if already unlocked. 

> Body parameter

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker"
}
```

<h3 id="patch__locks_unlock-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminLock.1.0.0](#schemaadminlock.1.0.0)|true|list of xnames to delete|

> Example responses

> 200 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="patch__locks_unlock-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ss|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__locks_repair

> Code samples

```http
PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/repair HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/repair \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/repair', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/repair", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /locks/repair`

*repair components lock and reservation ability*

Repairs the broken status of an xname allowing new reservations to be created.  

> Body parameter

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker"
}
```

<h3 id="patch__locks_repair-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminLock.1.0.0](#schemaadminlock.1.0.0)|true|list of xnames to delete|

> Example responses

> 200 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="patch__locks_repair-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ss|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__locks_disable

> Code samples

```http
PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/disable HTTP/1.1
Host: rocket-ncn-w001.us.cray.com
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/disable \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/disable', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PATCH", "https://rocket-ncn-w001.us.cray.com/apis/ifs/v1/locks/disable", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /locks/disable`

*disables the ability to create a reservation on components.*

Disables the ability to create a reservation on components, deletes any existing reservations. Does not change lock state. Can disable a currently disabled component.

> Body parameter

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker"
}
```

<h3 id="patch__locks_disable-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[AdminLock.1.0.0](#schemaadminlock.1.0.0)|true|list of xnames to delete|

> Example responses

> 200 Response

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}
```

> 400 Response

<h3 id="patch__locks_disable-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|ss|[XnameResponse_1.0.0](#schemaxnameresponse_1.0.0)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Server error, could not delete reservations|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

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

<h2 id="tocS_ServiceReservationCreate.1.0.0">ServiceReservationCreate.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaservicereservationcreate.1.0.0"></a>
<a id="schema_ServiceReservationCreate.1.0.0"></a>
<a id="tocSservicereservationcreate.1.0.0"></a>
<a id="tocsservicereservationcreate.1.0.0"></a>

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker",
  "ReservationDuration": 1
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[string]|false|none|An array of XName/ID values for the components to query.|
|ProcessingModel|string|false|none|rigid is all or nothing, felxible is best attempt.|
|Role|[HMSRole.1.0.0](#schemahmsrole.1.0.0)|false|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|SubRole|[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|ReservationDuration|integer|false|none|length of time in minutes for the reservation to be valid for.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_AdminReservationCreate.1.0.0">AdminReservationCreate.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaadminreservationcreate.1.0.0"></a>
<a id="schema_AdminReservationCreate.1.0.0"></a>
<a id="tocSadminreservationcreate.1.0.0"></a>
<a id="tocsadminreservationcreate.1.0.0"></a>

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[string]|false|none|An array of XName/ID values for the components to query.|
|ProcessingModel|string|false|none|rigid is all or nothing, felxible is best attempt.|
|Role|[HMSRole.1.0.0](#schemahmsrole.1.0.0)|false|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|SubRole|[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_ServiceReservationCreate_Response.1.0.0">ServiceReservationCreate_Response.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaservicereservationcreate_response.1.0.0"></a>
<a id="schema_ServiceReservationCreate_Response.1.0.0"></a>
<a id="tocSservicereservationcreate_response.1.0.0"></a>
<a id="tocsservicereservationcreate_response.1.0.0"></a>

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "347068b9-dbe0-4830-bf75-819cb2cd0712",
      "ReservationKey": "fdf03933-aef4-43bb-b6bf-551af3fbaa64",
      "ExpirationTime": "2019-08-24T14:15:22Z"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Success|[[XnameKeys.1.0.0](#schemaxnamekeys.1.0.0)]|false|none|none|
|Failure|[[FailedXnames.1.0.0](#schemafailedxnames.1.0.0)]|false|none|none|

<h2 id="tocS_AdminReservationCreate_Response.1.0.0">AdminReservationCreate_Response.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaadminreservationcreate_response.1.0.0"></a>
<a id="schema_AdminReservationCreate_Response.1.0.0"></a>
<a id="tocSadminreservationcreate_response.1.0.0"></a>
<a id="tocsadminreservationcreate_response.1.0.0"></a>

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "347068b9-dbe0-4830-bf75-819cb2cd0712",
      "ReservationKey": "fdf03933-aef4-43bb-b6bf-551af3fbaa64"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Success|[[XnameKeysNoExpire.1.0.0](#schemaxnamekeysnoexpire.1.0.0)]|false|none|none|
|Failure|[[FailedXnames.1.0.0](#schemafailedxnames.1.0.0)]|false|none|none|

<h2 id="tocS_ComponentStatus.1.0.0">ComponentStatus.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemacomponentstatus.1.0.0"></a>
<a id="schema_ComponentStatus.1.0.0"></a>
<a id="tocScomponentstatus.1.0.0"></a>
<a id="tocscomponentstatus.1.0.0"></a>

```json
{
  "ID": "x1001c0s0b0",
  "Locked": false,
  "Reserved": true,
  "ExpirationTime": "2019-08-24T14:15:22Z",
  "ReservationDisabled": false
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|Locked|boolean|false|none|none|
|Reserved|boolean|false|none|none|
|ExpirationTime|string(date-time)|false|none|none|
|ReservationDisabled|boolean|false|none|none|

<h2 id="tocS_AdminStatusCheck_Response.1.0.0">AdminStatusCheck_Response.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaadminstatuscheck_response.1.0.0"></a>
<a id="schema_AdminStatusCheck_Response.1.0.0"></a>
<a id="tocSadminstatuscheck_response.1.0.0"></a>
<a id="tocsadminstatuscheck_response.1.0.0"></a>

```json
{
  "Components": [
    {
      "ID": "x1001c0s0b0",
      "Locked": false,
      "Reserved": true,
      "ExpirationTime": "2019-08-24T14:15:22Z",
      "ReservationDisabled": false
    }
  ],
  "NotFound": [
    "x1000c0s0b0"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Components|[[ComponentStatus.1.0.0](#schemacomponentstatus.1.0.0)]|false|none|none|
|NotFound|[string]|false|none|none|

<h2 id="tocS_ServiceReservationCheck_Response.1.0.0">ServiceReservationCheck_Response.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaservicereservationcheck_response.1.0.0"></a>
<a id="schema_ServiceReservationCheck_Response.1.0.0"></a>
<a id="tocSservicereservationcheck_response.1.0.0"></a>
<a id="tocsservicereservationcheck_response.1.0.0"></a>

```json
{
  "Success": [
    {
      "ID": "string",
      "DeputyKey": "347068b9-dbe0-4830-bf75-819cb2cd0712",
      "ExpirationTime": "2019-08-24T14:15:22Z"
    }
  ],
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Success|[[XnameKeysDeputyExpire.1.0.0](#schemaxnamekeysdeputyexpire.1.0.0)]|false|none|none|
|Failure|[[FailedXnames.1.0.0](#schemafailedxnames.1.0.0)]|false|none|none|

<h2 id="tocS_AdminLock.1.0.0">AdminLock.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaadminlock.1.0.0"></a>
<a id="schema_AdminLock.1.0.0"></a>
<a id="tocSadminlock.1.0.0"></a>
<a id="tocsadminlock.1.0.0"></a>

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[string]|false|none|An array of XName/ID values for the components to query.|
|ProcessingModel|string|false|none|rigid is all or nothing, felxible is best attempt.|
|Role|[HMSRole.1.0.0](#schemahmsrole.1.0.0)|false|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|SubRole|[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_AdminReservationRemove.1.0.0">AdminReservationRemove.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaadminreservationremove.1.0.0"></a>
<a id="schema_AdminReservationRemove.1.0.0"></a>
<a id="tocSadminreservationremove.1.0.0"></a>
<a id="tocsadminreservationremove.1.0.0"></a>

```json
{
  "ComponentIDs": [
    "string"
  ],
  "ProcessingModel": "rigid",
  "Role": "Management",
  "SubRole": "Worker"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[string]|false|none|An array of XName/ID values for the components to query.|
|ProcessingModel|string|false|none|rigid is all or nothing, felxible is best attempt.|
|Role|[HMSRole.1.0.0](#schemahmsrole.1.0.0)|false|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|
|SubRole|[HMSSubRole.1.0.0](#schemahmssubrole.1.0.0)|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_Xnames">Xnames</h2>
<!-- backwards compatibility -->
<a id="schemaxnames"></a>
<a id="schema_Xnames"></a>
<a id="tocSxnames"></a>
<a id="tocsxnames"></a>

```json
{
  "ComponentIDs": [
    "string"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ComponentIDs|[string]|false|none|none|

<h2 id="tocS_XnameResponse_1.0.0">XnameResponse_1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnameresponse_1.0.0"></a>
<a id="schema_XnameResponse_1.0.0"></a>
<a id="tocSxnameresponse_1.0.0"></a>
<a id="tocsxnameresponse_1.0.0"></a>

```json
{
  "Counts": {
    "Total": 0,
    "Success": 0,
    "Failure": 0
  },
  "Success": {
    "ComponentIDs": [
      "string"
    ]
  },
  "Failure": [
    {
      "ID": "string",
      "Reason": "NotFound"
    }
  ]
}

```

This is a simple CAPMC-like response,intended mainly for non-error messages.  For client errors, we now use RFC7807 responses.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Counts|[Counts.1.0.0](#schemacounts.1.0.0)|false|none|none|
|Success|[Xnames](#schemaxnames)|false|none|none|
|Failure|[[FailedXnames.1.0.0](#schemafailedxnames.1.0.0)]|false|none|none|

<h2 id="tocS_HMSRole.1.0.0">HMSRole.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahmsrole.1.0.0"></a>
<a id="schema_HMSRole.1.0.0"></a>
<a id="tocShmsrole.1.0.0"></a>
<a id="tocshmsrole.1.0.0"></a>

```json
"Management"

```

This is a possibly reconfigurable role for a component, especially a node. Valid values are:
- Compute
- Service
- System
- Application
- Storage
- Management
Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is a possibly reconfigurable role for a component, especially a node. Valid values are:<br>- Compute<br>- Service<br>- System<br>- Application<br>- Storage<br>- Management<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|

<h2 id="tocS_FailedXnames.1.0.0">FailedXnames.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemafailedxnames.1.0.0"></a>
<a id="schema_FailedXnames.1.0.0"></a>
<a id="tocSfailedxnames.1.0.0"></a>
<a id="tocsfailedxnames.1.0.0"></a>

```json
{
  "ID": "string",
  "Reason": "NotFound"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|Reason|string|false|none|the key that can be passed to a delegate|

#### Enumerated Values

|Property|Value|
|---|---|
|Reason|NotFound|
|Reason|Locked|
|Reason|Disabled|
|Reason|Reserved|
|Reason|ServerError|

<h2 id="tocS_HMSSubRole.1.0.0">HMSSubRole.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahmssubrole.1.0.0"></a>
<a id="schema_HMSSubRole.1.0.0"></a>
<a id="tocShmssubrole.1.0.0"></a>
<a id="tocshmssubrole.1.0.0"></a>

```json
"Worker"

```

This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:
- Master
- Worker
- Storage
Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|This is a possibly reconfigurable subrole for a component, especially a node. Valid values are:<br>- Master<br>- Worker<br>- Storage<br>Additional valid values may be added via configuration file. See the results of 'GET /service/values/role' for the complete list.|

<h2 id="tocS_XnameKeysNoExpire.1.0.0">XnameKeysNoExpire.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamekeysnoexpire.1.0.0"></a>
<a id="schema_XnameKeysNoExpire.1.0.0"></a>
<a id="tocSxnamekeysnoexpire.1.0.0"></a>
<a id="tocsxnamekeysnoexpire.1.0.0"></a>

```json
{
  "ID": "string",
  "DeputyKey": "347068b9-dbe0-4830-bf75-819cb2cd0712",
  "ReservationKey": "fdf03933-aef4-43bb-b6bf-551af3fbaa64"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|DeputyKey|string(uuid)|false|none|the key that can be passed to a delegate|
|ReservationKey|string(uuid)|false|none|the key that can be used to renew/release the reservation. Should not be delegated or shared.|

<h2 id="tocS_XnameKeys.1.0.0">XnameKeys.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamekeys.1.0.0"></a>
<a id="schema_XnameKeys.1.0.0"></a>
<a id="tocSxnamekeys.1.0.0"></a>
<a id="tocsxnamekeys.1.0.0"></a>

```json
{
  "ID": "string",
  "DeputyKey": "347068b9-dbe0-4830-bf75-819cb2cd0712",
  "ReservationKey": "fdf03933-aef4-43bb-b6bf-551af3fbaa64",
  "ExpirationTime": "2019-08-24T14:15:22Z"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|DeputyKey|string(uuid)|false|none|the key that can be passed to a delegate|
|ReservationKey|string(uuid)|false|none|the key that can be used to renew/release the reservation. Should not be delegated or shared.|
|ExpirationTime|string(date-time)¦null|false|none|none|

<h2 id="tocS_XnameKeysDeputyExpire.1.0.0">XnameKeysDeputyExpire.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamekeysdeputyexpire.1.0.0"></a>
<a id="schema_XnameKeysDeputyExpire.1.0.0"></a>
<a id="tocSxnamekeysdeputyexpire.1.0.0"></a>
<a id="tocsxnamekeysdeputyexpire.1.0.0"></a>

```json
{
  "ID": "string",
  "DeputyKey": "347068b9-dbe0-4830-bf75-819cb2cd0712",
  "ExpirationTime": "2019-08-24T14:15:22Z"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|DeputyKey|string(uuid)|false|none|the key that can be passed to a delegate|
|ExpirationTime|string(date-time)|false|none|none|

<h2 id="tocS_XnameWithKey.1.0.0">XnameWithKey.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxnamewithkey.1.0.0"></a>
<a id="schema_XnameWithKey.1.0.0"></a>
<a id="tocSxnamewithkey.1.0.0"></a>
<a id="tocsxnamewithkey.1.0.0"></a>

```json
{
  "ID": "string",
  "Key": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|Key|string|false|none|none|

<h2 id="tocS_DeputyKeys.1.0.0">DeputyKeys.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemadeputykeys.1.0.0"></a>
<a id="schema_DeputyKeys.1.0.0"></a>
<a id="tocSdeputykeys.1.0.0"></a>
<a id="tocsdeputykeys.1.0.0"></a>

```json
{
  "DeputyKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|DeputyKeys|[[XnameWithKey.1.0.0](#schemaxnamewithkey.1.0.0)]|false|none|none|

<h2 id="tocS_ReservedKeys.1.0.0">ReservedKeys.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemareservedkeys.1.0.0"></a>
<a id="schema_ReservedKeys.1.0.0"></a>
<a id="tocSreservedkeys.1.0.0"></a>
<a id="tocsreservedkeys.1.0.0"></a>

```json
{
  "ReservationKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ],
  "ProcessingModel": "rigid"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ReservationKeys|[[XnameWithKey.1.0.0](#schemaxnamewithkey.1.0.0)]|false|none|none|
|ProcessingModel|string|false|none|rigid is all or nothing, felxible is best attempt.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_ReservedKeysWithRenewal.1.0.0">ReservedKeysWithRenewal.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemareservedkeyswithrenewal.1.0.0"></a>
<a id="schema_ReservedKeysWithRenewal.1.0.0"></a>
<a id="tocSreservedkeyswithrenewal.1.0.0"></a>
<a id="tocsreservedkeyswithrenewal.1.0.0"></a>

```json
{
  "ReservationKeys": [
    {
      "ID": "string",
      "Key": "string"
    }
  ],
  "ProcessingModel": "rigid",
  "ReservationDuration": 1
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ReservationKeys|[[XnameWithKey.1.0.0](#schemaxnamewithkey.1.0.0)]|false|none|none|
|ProcessingModel|string|false|none|rigid is all or nothing, felxible is best attempt.|
|ReservationDuration|integer|false|none|length of time in minutes for the reservation to be valid for.|

#### Enumerated Values

|Property|Value|
|---|---|
|ProcessingModel|rigid|
|ProcessingModel|flexible|

<h2 id="tocS_Counts.1.0.0">Counts.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemacounts.1.0.0"></a>
<a id="schema_Counts.1.0.0"></a>
<a id="tocScounts.1.0.0"></a>
<a id="tocscounts.1.0.0"></a>

```json
{
  "Total": 0,
  "Success": 0,
  "Failure": 0
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Total|integer|false|none|none|
|Success|integer|false|none|none|
|Failure|integer|false|none|none|

