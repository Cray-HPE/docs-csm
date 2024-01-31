<!-- Generator: Widdershins v4.0.1 -->

<h1 id="cray-sts-token-generator">Cray STS Token Generator v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/sts">https://api-gw-service-nmn.local/apis/sts</a>

# Authentication

- HTTP Authentication, scheme: bearer 

<h1 id="cray-sts-token-generator-default">Default</h1>

## sts.routes.put_token

<a id="opIdsts.routes.put_token"></a>

> Code samples

```http
PUT https://api-gw-service-nmn.local/apis/sts/token HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT https://api-gw-service-nmn.local/apis/sts/token \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.put('https://api-gw-service-nmn.local/apis/sts/token', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PUT", "https://api-gw-service-nmn.local/apis/sts/token", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /token`

*Generate STS token*

Generates a STS Token.

> Example responses

> 201 Response

```json
{
  "Credentials": {
    "EndpointURL": "http://foo.bar:8080",
    "AccessKeyId": "foo",
    "SecretAccessKey": "bar",
    "SessionToken": "baz",
    "Expiration": "2019-09-24T02:17:51.739673+00:00"
  }
}
```

<h3 id="sts.routes.put_token-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|A generated STS Token|[Token](#schematoken)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

<h1 id="cray-sts-token-generator-cli_ignore">cli_ignore</h1>

## sts.routes.get_healthz

<a id="opIdsts.routes.get_healthz"></a>

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/sts/healthz HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/sts/healthz \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/sts/healthz', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/sts/healthz", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /healthz`

*Return health status*

Return health status

> Example responses

> 200 Response

```json
{
  "Status": "ok"
}
```

<h3 id="sts.routes.get_healthz-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Everything is ok|Inline|

<h3 id="sts.routes.get_healthz-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» Status|string|false|read-only|none|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

# Schemas

<h2 id="tocS_Token">Token</h2>
<!-- backwards compatibility -->
<a id="schematoken"></a>
<a id="schema_Token"></a>
<a id="tocStoken"></a>
<a id="tocstoken"></a>

```json
{
  "Credentials": {
    "EndpointURL": "http://foo.bar:8080",
    "AccessKeyId": "foo",
    "SecretAccessKey": "bar",
    "SessionToken": "baz",
    "Expiration": "2019-09-24T02:17:51.739673+00:00"
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Credentials|object|false|none|none|
|» EndpointURL|string|false|read-only|none|
|» AccessKeyId|string|false|read-only|none|
|» SecretAccessKey|string|false|read-only|none|
|» SessionToken|string|false|read-only|none|
|» Expiration|string|false|read-only|none|

