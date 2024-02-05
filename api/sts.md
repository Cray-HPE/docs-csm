<!-- Generator: Widdershins v4.0.1 -->

<h1 id="cray-sts-token-generator">Cray STS Token Generator v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

Base URLs:

* <a href="http://localhost:9090/">http://localhost:9090/</a>

<h1 id="cray-sts-token-generator-default">Default</h1>

## sts.routes.put_token

<a id="opIdsts.routes.put_token"></a>

> Code samples

```http
PUT http://localhost:9090/token HTTP/1.1
Host: localhost:9090
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT http://localhost:9090/token \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.put('http://localhost:9090/token', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("PUT", "http://localhost:9090/token", data)
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

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="cray-sts-token-generator-cli_ignore">cli_ignore</h1>

## sts.routes.get_healthz

<a id="opIdsts.routes.get_healthz"></a>

> Code samples

```http
GET http://localhost:9090/healthz HTTP/1.1
Host: localhost:9090
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://localhost:9090/healthz \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://localhost:9090/healthz', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "http://localhost:9090/healthz", data)
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

<aside class="success">
This operation does not require authentication
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

