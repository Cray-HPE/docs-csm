<!-- Generator: Widdershins v4.0.1 -->

<h1 id="tapms-tenant-status-api">TAPMS Tenant Status API v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

Read-Only APIs to Retrieve Tenant Status

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/tapms/">https://api-gw-service-nmn.local/apis/tapms/</a>

# Authentication

- HTTP Authentication, scheme: bearer 

<h1 id="tapms-tenant-status-api-tenant-and-partition-management-system">Tenant and Partition Management System</h1>

## get__v1alpha3_tenants

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1alpha3/tenants`

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
      "tenanthooks": [
        {
          "blockingcall": true,
          "eventtypes": [
            "CREATE",
            " UPDATE",
            " DELETE"
          ],
          "hookcredentials": {
            "secretname": "string",
            "secretnamespace": "string"
          },
          "name": "string",
          "url": "http://<url>:<port>"
        }
      ],
      "tenantkms": {
        "enablekms": true,
        "keyname": "string",
        "keytype": "string"
      },
      "tenantname": "vcluster-blue",
      "tenantresources": [
        {
          "enforceexclusivehsmgroups": true,
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
      "tenanthooks": [
        {
          "blockingcall": true,
          "eventtypes": [
            "CREATE",
            " UPDATE",
            " DELETE"
          ],
          "hookcredentials": {
            "secretname": "string",
            "secretnamespace": "string"
          },
          "name": "string",
          "url": "http://<url>:<port>"
        }
      ],
      "tenantkms": {
        "keyname": "string",
        "keytype": "string",
        "publickey": "string",
        "transitname": "string"
      },
      "tenantresources": [
        {
          "enforceexclusivehsmgroups": true,
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

<h3 id="get__v1alpha3_tenants-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<h3 id="get__v1alpha3_tenants-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Tenant](#schematenant)]|false|none|[The primary schema/definition of a tenant]|
|» spec|[TenantSpec](#schematenantspec)|true|none|The desired state of Tenant|
|»» childnamespaces|[string]|false|none|none|
|»» state|string|false|none|+kubebuilder:validation:Optional|
|»» tenanthooks|[[TenantHook](#schematenanthook)]|false|none|+kubebuilder:validation:Optional|
|»»» blockingcall|boolean|false|none|+kubebuilder:default:=false<br>+kubebuilder:validation:Optional|
|»»» eventtypes|[string]|false|none|none|
|»»» hookcredentials|[HookCredentials](#schemahookcredentials)|false|none|+kubebuilder:validation:Optional|
|»»»» secretname|string|false|none|+kubebuilder:validation:Optional<br>Optional Kubernetes secret name containing credentials for calling webhook|
|»»»» secretnamespace|string|false|none|+kubebuilder:validation:Optional<br>Optional Kubernetes namespace for the secret|
|»»» name|string|false|none|none|
|»»» url|string|false|none|none|
|»» tenantkms|[TenantKmsResource](#schematenantkmsresource)|false|none|+kubebuilder:validation:Optional|
|»»» enablekms|boolean|false|none|+kubebuilder:default:=false<br>+kubebuilder:validation:Optional<br>Create a Vault transit engine for the tenant if this setting is true.|
|»»» keyname|string|false|none|+kubebuilder:default:=key1<br>+kubebuilder:validation:Optional<br>Optional name for the transit engine key.|
|»»» keytype|string|false|none|+kubebuilder:default:=rsa-3072<br>+kubebuilder:validation:Optional<br>Optional key type. See https://developer.hashicorp.com/vault/api-docs/secret/transit#type<br>The default of 3072 is the minimal permitted under the Commercial National Security Algorithm (CNSA) 1.0 suite.|
|»» tenantname|string|true|none|none|
|»» tenantresources|[[TenantResource](#schematenantresource)]|true|none|The desired resources for the Tenant|
|»»» enforceexclusivehsmgroups|boolean|false|none|none|
|»»» hsmgrouplabel|string|false|none|none|
|»»» hsmpartitionname|string|false|none|none|
|»»» type|string|true|none|none|
|»»» xnames|[string]|true|none|none|
|» status|[TenantStatus](#schematenantstatus)|false|none|The observed state of Tenant|
|»» childnamespaces|[string]|false|none|none|
|»» tenanthooks|[[TenantHook](#schematenanthook)]|false|none|[The webhook definition to call an API for tenant CRUD operations]|
|»» tenantkms|[TenantKmsStatus](#schematenantkmsstatus)|false|none|The Vault KMS transit engine status for the tenant|
|»»» keyname|string|false|none|The Vault transit key name.|
|»»» keytype|string|false|none|The Vault transit key type.|
|»»» publickey|string|false|none|The Vault public key.|
|»»» transitname|string|false|none|The generated Vault transit engine name.|
|»» tenantresources|[[TenantResource](#schematenantresource)]|false|none|The desired resources for the Tenant|
|»» uuid|string(uuid)|false|none|none|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## post__v1alpha3_tenants

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants \
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

r = requests.post('https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /v1alpha3/tenants`

*Get list of tenants' spec/status with xname ownership*

> Body parameter

```json
"[\"x1000c0s0b0n0\", \"x1000c0s0b1n0\"]"
```

<h3 id="post__v1alpha3_tenants-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|string|true|Array of Xnames|

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
      "tenanthooks": [
        {
          "blockingcall": true,
          "eventtypes": [
            "CREATE",
            " UPDATE",
            " DELETE"
          ],
          "hookcredentials": {
            "secretname": "string",
            "secretnamespace": "string"
          },
          "name": "string",
          "url": "http://<url>:<port>"
        }
      ],
      "tenantkms": {
        "enablekms": true,
        "keyname": "string",
        "keytype": "string"
      },
      "tenantname": "vcluster-blue",
      "tenantresources": [
        {
          "enforceexclusivehsmgroups": true,
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
      "tenanthooks": [
        {
          "blockingcall": true,
          "eventtypes": [
            "CREATE",
            " UPDATE",
            " DELETE"
          ],
          "hookcredentials": {
            "secretname": "string",
            "secretnamespace": "string"
          },
          "name": "string",
          "url": "http://<url>:<port>"
        }
      ],
      "tenantkms": {
        "keyname": "string",
        "keytype": "string",
        "publickey": "string",
        "transitname": "string"
      },
      "tenantresources": [
        {
          "enforceexclusivehsmgroups": true,
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

<h3 id="post__v1alpha3_tenants-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<h3 id="post__v1alpha3_tenants-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Tenant](#schematenant)]|false|none|[The primary schema/definition of a tenant]|
|» spec|[TenantSpec](#schematenantspec)|true|none|The desired state of Tenant|
|»» childnamespaces|[string]|false|none|none|
|»» state|string|false|none|+kubebuilder:validation:Optional|
|»» tenanthooks|[[TenantHook](#schematenanthook)]|false|none|+kubebuilder:validation:Optional|
|»»» blockingcall|boolean|false|none|+kubebuilder:default:=false<br>+kubebuilder:validation:Optional|
|»»» eventtypes|[string]|false|none|none|
|»»» hookcredentials|[HookCredentials](#schemahookcredentials)|false|none|+kubebuilder:validation:Optional|
|»»»» secretname|string|false|none|+kubebuilder:validation:Optional<br>Optional Kubernetes secret name containing credentials for calling webhook|
|»»»» secretnamespace|string|false|none|+kubebuilder:validation:Optional<br>Optional Kubernetes namespace for the secret|
|»»» name|string|false|none|none|
|»»» url|string|false|none|none|
|»» tenantkms|[TenantKmsResource](#schematenantkmsresource)|false|none|+kubebuilder:validation:Optional|
|»»» enablekms|boolean|false|none|+kubebuilder:default:=false<br>+kubebuilder:validation:Optional<br>Create a Vault transit engine for the tenant if this setting is true.|
|»»» keyname|string|false|none|+kubebuilder:default:=key1<br>+kubebuilder:validation:Optional<br>Optional name for the transit engine key.|
|»»» keytype|string|false|none|+kubebuilder:default:=rsa-3072<br>+kubebuilder:validation:Optional<br>Optional key type. See https://developer.hashicorp.com/vault/api-docs/secret/transit#type<br>The default of 3072 is the minimal permitted under the Commercial National Security Algorithm (CNSA) 1.0 suite.|
|»» tenantname|string|true|none|none|
|»» tenantresources|[[TenantResource](#schematenantresource)]|true|none|The desired resources for the Tenant|
|»»» enforceexclusivehsmgroups|boolean|false|none|none|
|»»» hsmgrouplabel|string|false|none|none|
|»»» hsmpartitionname|string|false|none|none|
|»»» type|string|true|none|none|
|»»» xnames|[string]|true|none|none|
|» status|[TenantStatus](#schematenantstatus)|false|none|The observed state of Tenant|
|»» childnamespaces|[string]|false|none|none|
|»» tenanthooks|[[TenantHook](#schematenanthook)]|false|none|[The webhook definition to call an API for tenant CRUD operations]|
|»» tenantkms|[TenantKmsStatus](#schematenantkmsstatus)|false|none|The Vault KMS transit engine status for the tenant|
|»»» keyname|string|false|none|The Vault transit key name.|
|»»» keytype|string|false|none|The Vault transit key type.|
|»»» publickey|string|false|none|The Vault public key.|
|»»» transitname|string|false|none|The generated Vault transit engine name.|
|»» tenantresources|[[TenantResource](#schematenantresource)]|false|none|The desired resources for the Tenant|
|»» uuid|string(uuid)|false|none|none|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get__v1alpha3_tenants_{id}

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants/{id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants/{id} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants/{id}', headers = headers)

print(r.json())

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
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/tapms/v1alpha3/tenants/{id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /v1alpha3/tenants/{id}`

*Get a tenant's spec/status*

<h3 id="get__v1alpha3_tenants_{id}-parameters">Parameters</h3>

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
    "tenanthooks": [
      {
        "blockingcall": true,
        "eventtypes": [
          "CREATE",
          " UPDATE",
          " DELETE"
        ],
        "hookcredentials": {
          "secretname": "string",
          "secretnamespace": "string"
        },
        "name": "string",
        "url": "http://<url>:<port>"
      }
    ],
    "tenantkms": {
      "enablekms": true,
      "keyname": "string",
      "keytype": "string"
    },
    "tenantname": "vcluster-blue",
    "tenantresources": [
      {
        "enforceexclusivehsmgroups": true,
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
    "tenanthooks": [
      {
        "blockingcall": true,
        "eventtypes": [
          "CREATE",
          " UPDATE",
          " DELETE"
        ],
        "hookcredentials": {
          "secretname": "string",
          "secretnamespace": "string"
        },
        "name": "string",
        "url": "http://<url>:<port>"
      }
    ],
    "tenantkms": {
      "keyname": "string",
      "keytype": "string",
      "publickey": "string",
      "transitname": "string"
    },
    "tenantresources": [
      {
        "enforceexclusivehsmgroups": true,
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

<h3 id="get__v1alpha3_tenants_{id}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[Tenant](#schematenant)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

# Schemas

<h2 id="tocS_HookCredentials">HookCredentials</h2>
<!-- backwards compatibility -->
<a id="schemahookcredentials"></a>
<a id="schema_HookCredentials"></a>
<a id="tocShookcredentials"></a>
<a id="tocshookcredentials"></a>

```json
{
  "secretname": "string",
  "secretnamespace": "string"
}

```

Optional credentials for calling webhook

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|secretname|string|false|none|+kubebuilder:validation:Optional<br>Optional Kubernetes secret name containing credentials for calling webhook|
|secretnamespace|string|false|none|+kubebuilder:validation:Optional<br>Optional Kubernetes namespace for the secret|

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
    "tenanthooks": [
      {
        "blockingcall": true,
        "eventtypes": [
          "CREATE",
          " UPDATE",
          " DELETE"
        ],
        "hookcredentials": {
          "secretname": "string",
          "secretnamespace": "string"
        },
        "name": "string",
        "url": "http://<url>:<port>"
      }
    ],
    "tenantkms": {
      "enablekms": true,
      "keyname": "string",
      "keytype": "string"
    },
    "tenantname": "vcluster-blue",
    "tenantresources": [
      {
        "enforceexclusivehsmgroups": true,
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
    "tenanthooks": [
      {
        "blockingcall": true,
        "eventtypes": [
          "CREATE",
          " UPDATE",
          " DELETE"
        ],
        "hookcredentials": {
          "secretname": "string",
          "secretnamespace": "string"
        },
        "name": "string",
        "url": "http://<url>:<port>"
      }
    ],
    "tenantkms": {
      "keyname": "string",
      "keytype": "string",
      "publickey": "string",
      "transitname": "string"
    },
    "tenantresources": [
      {
        "enforceexclusivehsmgroups": true,
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

<h2 id="tocS_TenantHook">TenantHook</h2>
<!-- backwards compatibility -->
<a id="schematenanthook"></a>
<a id="schema_TenantHook"></a>
<a id="tocStenanthook"></a>
<a id="tocstenanthook"></a>

```json
{
  "blockingcall": true,
  "eventtypes": [
    "CREATE",
    " UPDATE",
    " DELETE"
  ],
  "hookcredentials": {
    "secretname": "string",
    "secretnamespace": "string"
  },
  "name": "string",
  "url": "http://<url>:<port>"
}

```

The webhook definition to call an API for tenant CRUD operations

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|blockingcall|boolean|false|none|+kubebuilder:default:=false<br>+kubebuilder:validation:Optional|
|eventtypes|[string]|false|none|none|
|hookcredentials|[HookCredentials](#schemahookcredentials)|false|none|+kubebuilder:validation:Optional|
|name|string|false|none|none|
|url|string|false|none|none|

<h2 id="tocS_TenantKmsResource">TenantKmsResource</h2>
<!-- backwards compatibility -->
<a id="schematenantkmsresource"></a>
<a id="schema_TenantKmsResource"></a>
<a id="tocStenantkmsresource"></a>
<a id="tocstenantkmsresource"></a>

```json
{
  "enablekms": true,
  "keyname": "string",
  "keytype": "string"
}

```

The Vault KMS transit engine specification for the tenant

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|enablekms|boolean|false|none|+kubebuilder:default:=false<br>+kubebuilder:validation:Optional<br>Create a Vault transit engine for the tenant if this setting is true.|
|keyname|string|false|none|+kubebuilder:default:=key1<br>+kubebuilder:validation:Optional<br>Optional name for the transit engine key.|
|keytype|string|false|none|+kubebuilder:default:=rsa-3072<br>+kubebuilder:validation:Optional<br>Optional key type. See https://developer.hashicorp.com/vault/api-docs/secret/transit#type<br>The default of 3072 is the minimal permitted under the Commercial National Security Algorithm (CNSA) 1.0 suite.|

<h2 id="tocS_TenantKmsStatus">TenantKmsStatus</h2>
<!-- backwards compatibility -->
<a id="schematenantkmsstatus"></a>
<a id="schema_TenantKmsStatus"></a>
<a id="tocStenantkmsstatus"></a>
<a id="tocstenantkmsstatus"></a>

```json
{
  "keyname": "string",
  "keytype": "string",
  "publickey": "string",
  "transitname": "string"
}

```

The Vault KMS transit engine status for the tenant

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|keyname|string|false|none|The Vault transit key name.|
|keytype|string|false|none|The Vault transit key type.|
|publickey|string|false|none|The Vault public key.|
|transitname|string|false|none|The generated Vault transit engine name.|

<h2 id="tocS_TenantResource">TenantResource</h2>
<!-- backwards compatibility -->
<a id="schematenantresource"></a>
<a id="schema_TenantResource"></a>
<a id="tocStenantresource"></a>
<a id="tocstenantresource"></a>

```json
{
  "enforceexclusivehsmgroups": true,
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
  "tenanthooks": [
    {
      "blockingcall": true,
      "eventtypes": [
        "CREATE",
        " UPDATE",
        " DELETE"
      ],
      "hookcredentials": {
        "secretname": "string",
        "secretnamespace": "string"
      },
      "name": "string",
      "url": "http://<url>:<port>"
    }
  ],
  "tenantkms": {
    "enablekms": true,
    "keyname": "string",
    "keytype": "string"
  },
  "tenantname": "vcluster-blue",
  "tenantresources": [
    {
      "enforceexclusivehsmgroups": true,
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
|state|string|false|none|+kubebuilder:validation:Optional|
|tenanthooks|[[TenantHook](#schematenanthook)]|false|none|+kubebuilder:validation:Optional|
|tenantkms|[TenantKmsResource](#schematenantkmsresource)|false|none|+kubebuilder:validation:Optional|
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
  "tenanthooks": [
    {
      "blockingcall": true,
      "eventtypes": [
        "CREATE",
        " UPDATE",
        " DELETE"
      ],
      "hookcredentials": {
        "secretname": "string",
        "secretnamespace": "string"
      },
      "name": "string",
      "url": "http://<url>:<port>"
    }
  ],
  "tenantkms": {
    "keyname": "string",
    "keytype": "string",
    "publickey": "string",
    "transitname": "string"
  },
  "tenantresources": [
    {
      "enforceexclusivehsmgroups": true,
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
|tenanthooks|[[TenantHook](#schematenanthook)]|false|none|[The webhook definition to call an API for tenant CRUD operations]|
|tenantkms|[TenantKmsStatus](#schematenantkmsstatus)|false|none|The Vault KMS transit engine status for the tenant|
|tenantresources|[[TenantResource](#schematenantresource)]|false|none|The desired resources for the Tenant|
|uuid|string(uuid)|false|none|none|

