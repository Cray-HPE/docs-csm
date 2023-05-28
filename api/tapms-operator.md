<!-- Generator: Widdershins v4.0.1 -->

<h1 id="tapms-tenant-status-api">TAPMS Tenant Status API v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

Read-Only APIs to Retrieve Tenant Status

Base URLs:

* <a href="//cray-tapms/apis/tapms/">//cray-tapms/apis/tapms/</a>

<h1 id="tapms-tenant-status-api-tenant-and-partition-management-system">Tenant and Partition Management System</h1>

## get__v1alpha2_tenants

> Code samples

```http
GET /cray-tapms/apis/tapms/v1alpha2/tenants HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /cray-tapms/apis/tapms/v1alpha2/tenants \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/cray-tapms/apis/tapms/v1alpha2/tenants', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/cray-tapms/apis/tapms/v1alpha2/tenants", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1alpha2/tenants`

*Get list of tenants' spec/status*

> Example responses

> 200 Response

```json
[
  {
    "spec": {
      "childnamespaces": [
        "vcluster-blue-slurm"
      ],
      "state": "New,Deploying,Deployed,Deleting",
      "tenantname": "vcluster-blue",
      "tenantresources": [
        {
          "enforceexclusivehsmgroups": true,
          "forcepoweroff": true,
          "hsmgrouplabel": "green",
          "hsmpartitionname": "blue",
          "type": "compute",
          "xnames": [
            "x0c3s5b0n0",
            "x0c3s6b0n0"
          ]
        }
      ]
    },
    "status": {
      "childnamespaces": [
        "vcluster-blue-slurm"
      ],
      "tenantresources": [
        {
          "enforceexclusivehsmgroups": true,
          "forcepoweroff": true,
          "hsmgrouplabel": "green",
          "hsmpartitionname": "blue",
          "type": "compute",
          "xnames": [
            "x0c3s5b0n0",
            "x0c3s6b0n0"
          ]
        }
      ],
      "uuid": "550e8400-e29b-41d4-a716-446655440000"
    }
  }
]
```

<h3 id="get__v1alpha2_tenants-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<h3 id="get__v1alpha2_tenants-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Tenant](#schematenant)]|false|none|[The primary schema/definition of a tenant]|
|» spec|[TenantSpec](#schematenantspec)|true|none|The desired state of Tenant|
|»» childnamespaces|[string]|false|none|none|
|»» state|string|false|none|none|
|»» tenantname|string|true|none|none|
|»» tenantresources|[[TenantResource](#schematenantresource)]|true|none|The desired resources for the Tenant|
|»»» enforceexclusivehsmgroups|boolean|false|none|none|
|»»» forcepoweroff|boolean|false|none|none|
|»»» hsmgrouplabel|string|false|none|none|
|»»» hsmpartitionname|string|false|none|none|
|»»» type|string|true|none|none|
|»»» xnames|[string]|true|none|none|
|» status|[TenantStatus](#schematenantstatus)|false|none|The observed state of Tenant|
|»» childnamespaces|[string]|false|none|none|
|»» tenantresources|[[TenantResource](#schematenantresource)]|false|none|The desired resources for the Tenant|
|»» uuid|string(uuid)|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## get__v1alpha2_tenants_{id}

> Code samples

```http
GET /cray-tapms/apis/tapms/v1alpha2/tenants/{id} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /cray-tapms/apis/tapms/v1alpha2/tenants/{id} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/cray-tapms/apis/tapms/v1alpha2/tenants/{id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "/cray-tapms/apis/tapms/v1alpha2/tenants/{id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1alpha2/tenants/{id}`

*Get a tenant's spec/status*

<h3 id="get__v1alpha2_tenants_{id}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|path|string|true|Either the Name or UUID of the Tenant|

> Example responses

> 200 Response

```json
{
  "spec": {
    "childnamespaces": [
      "vcluster-blue-slurm"
    ],
    "state": "New,Deploying,Deployed,Deleting",
    "tenantname": "vcluster-blue",
    "tenantresources": [
      {
        "enforceexclusivehsmgroups": true,
        "forcepoweroff": true,
        "hsmgrouplabel": "green",
        "hsmpartitionname": "blue",
        "type": "compute",
        "xnames": [
          "x0c3s5b0n0",
          "x0c3s6b0n0"
        ]
      }
    ]
  },
  "status": {
    "childnamespaces": [
      "vcluster-blue-slurm"
    ],
    "tenantresources": [
      {
        "enforceexclusivehsmgroups": true,
        "forcepoweroff": true,
        "hsmgrouplabel": "green",
        "hsmpartitionname": "blue",
        "type": "compute",
        "xnames": [
          "x0c3s5b0n0",
          "x0c3s6b0n0"
        ]
      }
    ],
    "uuid": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

<h3 id="get__v1alpha2_tenants_{id}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[Tenant](#schematenant)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_ResponseError">ResponseError</h2>
<!-- backwards compatibility -->
<a id="schemaresponseerror"></a>
<a id="schema_ResponseError"></a>
<a id="tocSresponseerror"></a>
<a id="tocsresponseerror"></a>

```json
{
  "message": "Error Message..."
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|message|string|false|none|none|

<h2 id="tocS_Tenant">Tenant</h2>
<!-- backwards compatibility -->
<a id="schematenant"></a>
<a id="schema_Tenant"></a>
<a id="tocStenant"></a>
<a id="tocstenant"></a>

```json
{
  "spec": {
    "childnamespaces": [
      "vcluster-blue-slurm"
    ],
    "state": "New,Deploying,Deployed,Deleting",
    "tenantname": "vcluster-blue",
    "tenantresources": [
      {
        "enforceexclusivehsmgroups": true,
        "forcepoweroff": true,
        "hsmgrouplabel": "green",
        "hsmpartitionname": "blue",
        "type": "compute",
        "xnames": [
          "x0c3s5b0n0",
          "x0c3s6b0n0"
        ]
      }
    ]
  },
  "status": {
    "childnamespaces": [
      "vcluster-blue-slurm"
    ],
    "tenantresources": [
      {
        "enforceexclusivehsmgroups": true,
        "forcepoweroff": true,
        "hsmgrouplabel": "green",
        "hsmpartitionname": "blue",
        "type": "compute",
        "xnames": [
          "x0c3s5b0n0",
          "x0c3s6b0n0"
        ]
      }
    ],
    "uuid": "550e8400-e29b-41d4-a716-446655440000"
  }
}

```

The primary schema/definition of a tenant

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|spec|[TenantSpec](#schematenantspec)|true|none|The desired state of Tenant|
|status|[TenantStatus](#schematenantstatus)|false|none|The observed state of Tenant|

<h2 id="tocS_TenantResource">TenantResource</h2>
<!-- backwards compatibility -->
<a id="schematenantresource"></a>
<a id="schema_TenantResource"></a>
<a id="tocStenantresource"></a>
<a id="tocstenantresource"></a>

```json
{
  "enforceexclusivehsmgroups": true,
  "forcepoweroff": true,
  "hsmgrouplabel": "green",
  "hsmpartitionname": "blue",
  "type": "compute",
  "xnames": [
    "x0c3s5b0n0",
    "x0c3s6b0n0"
  ]
}

```

The desired resources for the Tenant

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|enforceexclusivehsmgroups|boolean|false|none|none|
|forcepoweroff|boolean|false|none|none|
|hsmgrouplabel|string|false|none|none|
|hsmpartitionname|string|false|none|none|
|type|string|true|none|none|
|xnames|[string]|true|none|none|

<h2 id="tocS_TenantSpec">TenantSpec</h2>
<!-- backwards compatibility -->
<a id="schematenantspec"></a>
<a id="schema_TenantSpec"></a>
<a id="tocStenantspec"></a>
<a id="tocstenantspec"></a>

```json
{
  "childnamespaces": [
    "vcluster-blue-slurm"
  ],
  "state": "New,Deploying,Deployed,Deleting",
  "tenantname": "vcluster-blue",
  "tenantresources": [
    {
      "enforceexclusivehsmgroups": true,
      "forcepoweroff": true,
      "hsmgrouplabel": "green",
      "hsmpartitionname": "blue",
      "type": "compute",
      "xnames": [
        "x0c3s5b0n0",
        "x0c3s6b0n0"
      ]
    }
  ]
}

```

The desired state of Tenant

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|childnamespaces|[string]|false|none|none|
|state|string|false|none|none|
|tenantname|string|true|none|none|
|tenantresources|[[TenantResource](#schematenantresource)]|true|none|The desired resources for the Tenant|

<h2 id="tocS_TenantStatus">TenantStatus</h2>
<!-- backwards compatibility -->
<a id="schematenantstatus"></a>
<a id="schema_TenantStatus"></a>
<a id="tocStenantstatus"></a>
<a id="tocstenantstatus"></a>

```json
{
  "childnamespaces": [
    "vcluster-blue-slurm"
  ],
  "tenantresources": [
    {
      "enforceexclusivehsmgroups": true,
      "forcepoweroff": true,
      "hsmgrouplabel": "green",
      "hsmpartitionname": "blue",
      "type": "compute",
      "xnames": [
        "x0c3s5b0n0",
        "x0c3s6b0n0"
      ]
    }
  ],
  "uuid": "550e8400-e29b-41d4-a716-446655440000"
}

```

The observed state of Tenant

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|childnamespaces|[string]|false|none|none|
|tenantresources|[[TenantResource](#schematenantresource)]|false|none|The desired resources for the Tenant|
|uuid|string(uuid)|false|none|none|

