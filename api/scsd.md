<!-- Generator: Widdershins v4.0.1 -->

<h1 id="system-configuration-service">System Configuration Service v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

Commercial off-the-shelf BMCs and HPE-built controllers will need to have various parameters configured on them such as NTP server, syslog server, SSH keys, access credentials. These parameters are automatically configured when the targets like BMC and controllers are discovered.
The System Configuration Service makes it possible for administrators to configure these parameters at anytime on multiple targets in a single operation. The System Configuration Service runs on the non-compute worker node.

The REST API provides the following functions:
* Set or retrieve network protocol (NWP) parameters (NTP, syslog servers, SSH keys) for specified targets (xnames or groups). Only Redfish access credentials can be configured for Commercial off-the-shelf BMCs or BMC's in air cooled hardware. The other parameters are not applicable.
* Set Redfish access credentials for specified targets
* Check service health
## Resources
### /bmc/dumpcfg
Retrieve network protocol parameters like NTP, syslog server, and SSH keys for a set of controllers.
### /bmc/loadcfg
Configure NTP, syslog server, and SSH keys for a set of controllers.
### /bmc/cfg/{xname}
Retrieve or set NTP, syslog server, and SSH keys for a single controller.
### /bmc/discreetcreds
Configure discrete access credentials for target BMCs or controllers.
### /bmc/creds/{xname}
Configure or fetch (with authorization) access credentials for a single BMC or controller.
### /bmc/globalcreds
Configure the same access credentials for multiple BMCs or controllers.
### /bmc/createcerts
Create BMC TLS cert/key pairs and store securely for later use.
### /bmc/deletecerts
Delet BMC TLS cert/key pairs and store securely for later use.
### /bmc/fetchcerts
Fetch previously created BMC TLS certs for viewing.
### /bmc/setcerts
Apply previously created BMC TLS cert/key pairs to target Redfish BMCs.
### /bmc/setcert/{xname}
Apply previously created BMC TLS cert/key pairs to a single target Redfish BMCs.
### /health
Retrieve the current health state of the service.
## Workflows
### Retrieve syslog, NTP server and/or SSH key information on a single or multiple targets
#### POST /bmc/dumpcfg
Send a JSON payload with targets to retrieve. Targets can be xnames of BMCs or controllers, or group IDs. Returns a JSON payload containing NTP server information on specified targets.
#### GET /bmc/cfg/{xname}?params=NTPServer+SyslogServer
Returns a JSON payload containing only NTP and syslog server from a single target.
### Set syslog and NTP server and/or SSH key information on a single or multiple targets
#### POST /bmc/loadcfg
Send a JSON payload with parameters to set and a list of targets.  Targets can be xnames of BMCs or controllers, or group IDs. Returns a JSON payload with the results of the operation.
#### POST /bmc/cfg/{xname}?params=NTPServer+SSHKey
Returns a JSON payload containing NTP and SSH key information from a single target.
### Set login credentials on controllers
#### POST /bmc/discreetcreds
Sets login credentials on a set of controllers.  Targets can be xnames of controllers or group IDs.
### Create or delete BMC TLS cert/key pairs
#### POST /bmc/createcerts
Send a JSON payload with BMC domain and targets.  Creates a TLS cert/key pair for each BMC domain (e.g. cabinet) and stores it in secure storage for later use.
#### POST /bmc/deletecerts
Send a JSON payload with BMC domain and targets.  Deletes all applicable TLS cert/key pairs from secure storage.
### Fetch and view TLS certs
#### POST /bmc/fetchcerts
Send a JSON payload with BMC targets.  Fetches applicable TLS certs and returns them in a JSON payload.  Note that cert data is fetched, but not the private key data.
### Apply TLS Certs to BMCs
#### POST /bmc/setcerts
Send a JSON payload with BMC targets.  Fetch applicable TLS certs/keys from secure storage.  Apply cert/key pairs to target BMCs.
#### POST /bmc/setcert/{xname}?Force=true&Domain=cabinet
No JSON payload needed.  Fetch TLS cert/key pair from secure storage for target BMC specified by {xname}.  Apply cert/key pair to target BMC. Force defaults to false, Domain defaults to cabinet.
### Bios
#### GET /bmc/bios/{xname}/{bios_field}
Get TPM State in the BIOS settings.
#### PATCH /bmc/bios/{xname}/{bios_field}
Set TPM State in the BIOS settings.

Base URLs:

* <a href="http://api-gw-service-nmn.local/apis/scsd/v1">http://api-gw-service-nmn.local/apis/scsd/v1</a>

* <a href="http://cray-scsd/v1">http://cray-scsd/v1</a>

 License: Cray Proprietary

<h1 id="system-configuration-service-nwp">nwp</h1>

Endpoints that set or get Redfish Network Protocol information

## post__bmc_dumpcfg

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/dumpcfg HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/dumpcfg \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/dumpcfg', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/dumpcfg", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/dumpcfg`

*Retrieve the Redfish network protocol data for a set of targets*

Get the Redfish Network Protocol data (NTP server, syslog server, SSH key) for a set of targets.  The POST payload contains the parameters to retrieve  along with a list of targets.

> Body parameter

```json
{
  "Targets": [
    "x0c0s0b0"
  ],
  "Params": [
    "NTPServerInfo"
  ]
}
```

<h3 id="post__bmc_dumpcfg-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[bmc_dumpcfg_request](#schemabmc_dumpcfg_request)|false|none|

> Example responses

> 200 Response

```json
{
  "Targets": [
    {
      "StatusCode": 0,
      "StatusMsg": "string",
      "Xname": "x0c0s0b0",
      "Params": {
        "NTPServerInfo": {
          "NTPServers": "sms-ncn-w001",
          "Port": 0,
          "ProtocolEnabled": true
        },
        "SyslogServerInfo": {
          "SyslogServers": "sms-ncn-w001",
          "Port": 0,
          "ProtocolEnabled": true
        },
        "SSHKey": "xyzabc123...",
        "SSHConsoleKey": "xyzabc123..."
      }
    }
  ]
}
```

<h3 id="post__bmc_dumpcfg-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully retrieved|[bmc_dumpcfg_response](#schemabmc_dumpcfg_response)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

## post__bmc_loadcfg

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/loadcfg HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/loadcfg \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/loadcfg', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/loadcfg", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/loadcfg`

*Set the Redfish network protocol data for a set of targets*

Set the Redfish network protocol data (NTP server, syslog server, SSH key) for a set of targets. The POST payload contains the parameters to set  along with a list of targets.

The Force field is optional. If present, and set to 'true', the Redfish operations will be attempted without contacting HSM and without verifying if the targets are present or are in a good state. If the "Force" field is not present or is present but set to 'false', HSM will be used.

> Body parameter

```json
{
  "Force": true,
  "Targets": [
    "x0c0s0b0"
  ],
  "Params": {
    "NTPServer": {
      "NTPServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SyslogServer": {
      "SyslogServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SSHKey": "xyzabc123...",
    "SSHConsoleKey": "xyzabc123..."
  }
}
```

<h3 id="post__bmc_loadcfg-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[bmc_loadcfg_request](#schemabmc_loadcfg_request)|false|none|

> Example responses

> 200 Response

```json
{
  "Targets": [
    {
      "Xname": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK"
    }
  ]
}
```

<h3 id="post__bmc_loadcfg-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully retrieved|[multi_post_response](#schemamulti_post_response)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

## get__bmc_cfg_{xname}

> Code samples

```http
GET http://api-gw-service-nmn.local/apis/scsd/v1/bmc/cfg/{xname} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://api-gw-service-nmn.local/apis/scsd/v1/bmc/cfg/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/cfg/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/cfg/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /bmc/cfg/{xname}`

*Retrieve Redfish network protocol data for a single target*

Retrieve selected Redfish network protocol data for a single target. You can select NTP server, Syslog server, or SSH key. If nothing is specified, all Redfish network protocol parameters are returned.

<h3 id="get__bmc_cfg_{xname}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|[xname](#schemaxname)|true|none|
|param|query|string|false|none|

> Example responses

> 200 Response

```json
{
  "Force": true,
  "Params": {
    "NTPServerInfo": {
      "NTPServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SyslogServerInfo": {
      "SyslogServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SSHKey": "xyzabc123...",
    "SSHConsoleKey": "xyzabc123..."
  }
}
```

<h3 id="get__bmc_cfg_{xname}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully retrieved|[cfg_get_single](#schemacfg_get_single)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only GET,POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

## post__bmc_cfg_{xname}

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/cfg/{xname} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/cfg/{xname} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/cfg/{xname}', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/cfg/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/cfg/{xname}`

*Set Redfish network protocol data for a single target*

Set selected Redfish network protocol data for a single target. Payload body specifies NTP server, syslog server, or SSH key.

The Force field is optional. If present, and set to 'true', the Redfish operations will be attempted without contacting HSM and without verifying if the targets are present or are in a good state. If the "Force" field is not present or is present but set to 'false', HSM will be used.

> Body parameter

```json
{
  "Force": true,
  "Params": {
    "NTPServerInfo": {
      "NTPServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SyslogServerInfo": {
      "SyslogServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SSHKey": "xyzabc123...",
    "SSHConsoleKey": "xyzabc123..."
  }
}
```

<h3 id="post__bmc_cfg_{xname}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[cfg_post_single](#schemacfg_post_single)|false|none|
|xname|path|[xname](#schemaxname)|true|none|
|param|query|string|false|none|

> Example responses

> 200 Response

```json
{
  "StatusMsg": "OK"
}
```

<h3 id="post__bmc_cfg_{xname}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully set|[cfg_rsp_status](#schemacfg_rsp_status)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only GET,POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="system-configuration-service-creds">creds</h1>

Endpoints that set Redfish access credentials

## post__bmc_discreetcreds

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/discreetcreds HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/discreetcreds \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/discreetcreds', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/discreetcreds", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/discreetcreds`

*Set the controller login credentials for a set of targets*

Set discrete controller login credentials for a set of targets.  The POST payload contains the parameters to set along with a list of targets.

The Force field is optional. If present, and set to 'true', the Redfish operations will be attempted without contacting HSM and without verifying if the targets are present or are in a good state. If the "Force" field is not present or is present but set to 'false', HSM will be used.

> Body parameter

```json
{
  "Force": true,
  "Targets": [
    {
      "Xname": "x0c0s0b0",
      "Creds": {
        "Username": "admin-user",
        "Password": "admin-pw"
      }
    }
  ]
}
```

<h3 id="post__bmc_discreetcreds-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[creds_components](#schemacreds_components)|false|none|

> Example responses

> 200 Response

```json
{
  "Targets": [
    {
      "Xname": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK"
    }
  ]
}
```

<h3 id="post__bmc_discreetcreds-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully set|[multi_post_response](#schemamulti_post_response)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

## post__bmc_creds_{xname}

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/creds/{xname} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/creds/{xname} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/creds/{xname}', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/creds/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/creds/{xname}`

*Set controller login credentials for a single target*

Set controller login credentials for a single target.  The POST payload contains the parameters to set along with a list of targets.

The Force field is optional. If present, and set to 'true', the Redfish operations will be attempted without contacting HSM and without verifying if the targets are present or are in a good state. If the "Force" field is not present or is present but set to 'false', HSM will be used.

> Body parameter

```json
{
  "Force": true,
  "Creds": {
    "Username": "admin-user",
    "Password": "admin-pw"
  }
}
```

<h3 id="post__bmc_creds_{xname}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[creds_single](#schemacreds_single)|false|none|
|xname|path|[xname](#schemaxname)|true|none|

> Example responses

> 200 Response

```json
{
  "StatusMsg": "OK"
}
```

<h3 id="post__bmc_creds_{xname}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully set|[cfg_rsp_status](#schemacfg_rsp_status)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only GET,POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

## get__bmc_creds

> Code samples

```http
GET http://api-gw-service-nmn.local/apis/scsd/v1/bmc/creds HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://api-gw-service-nmn.local/apis/scsd/v1/bmc/creds \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/creds', headers = headers)

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
    req, err := http.NewRequest("GET", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/creds", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /bmc/creds`

*Fetch controller login credentials for specified targets and types.*

Fetch controller login credentials for a specified targets.  Targets are specified as a comma-separated list of xnames.  A component type may also be specified.  The xname list is 'ANDed' with the component type; any xname that has a type other than the specified type will be discarded.   If no type is specified, all BMC types are used. If no query parameters are specified at all, all BMCs in the system are used.

<h3 id="get__bmc_creds-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|targets|query|[xname_list](#schemaxname_list)|false|Comma separated list of XNames.  No query string results in fetching creds for all known BMCs.|
|type|query|string|false|Target component type.  A maximum of one type is allowed.  If no type is specified, all known BMC types are returned.|

> Example responses

> 200 Response

```json
[
  {
    "Xname": "x0c0s0b0",
    "Username": "admin",
    "Password": "pwstring",
    "StatusCode": 200,
    "StatusMsg": "OK"
  }
]
```

<h3 id="get__bmc_creds-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully set|[creds_fetch_rsp](#schemacreds_fetch_rsp)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only GET, POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

## post__bmc_globalcreds

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/globalcreds HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/globalcreds \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/globalcreds', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/globalcreds", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/globalcreds`

*Set the the same controller login credentials for a set of targets*

Set controller login credentials for a set of targets.  The POST payload contains the parameters to set along with a list of targets. The same credentials are set on all targets.

The Force field is optional. If present, and set to 'true', the Redfish operations will be attempted without contacting HSM and without verifying if the targets are present or are in a good state. If the "Force" field is not present or is present but set to 'false', HSM will be used.

> Body parameter

```json
{
  "Force": true,
  "Username": "string",
  "Password": "string",
  "Targets": [
    "x0c0s0b0"
  ]
}
```

<h3 id="post__bmc_globalcreds-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[creds_global](#schemacreds_global)|false|none|

> Example responses

> 200 Response

```json
{
  "Targets": [
    {
      "Xname": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK"
    }
  ]
}
```

<h3 id="post__bmc_globalcreds-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully set|[multi_post_response](#schemamulti_post_response)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="system-configuration-service-bios">bios</h1>

Endpoints that set or get BIOS information

## get__bmc_bios_{xname}_{bios_field}

> Code samples

```http
GET http://api-gw-service-nmn.local/apis/scsd/v1/bmc/bios/{xname}/{bios_field} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://api-gw-service-nmn.local/apis/scsd/v1/bmc/bios/{xname}/{bios_field} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/bios/{xname}/{bios_field}', headers = headers)

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
    req, err := http.NewRequest("GET", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/bios/{xname}/{bios_field}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /bmc/bios/{xname}/{bios_field}`

*Fetch the current BIOS setting for the TPM State.*

Fetch the current BIOS setting for the TPM State.

<h3 id="get__bmc_bios_{xname}_{bios_field}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|[xname_for_node](#schemaxname_for_node)|true|Locational xname of BMC.|
|bios_field|path|[bios_field](#schemabios_field)|true|Name of the BIOS field|

#### Enumerated Values

|Parameter|Value|
|---|---|
|bios_field|tpmstate|

> Example responses

> 200 Response

```json
{
  "Current": "Enabled",
  "Future": "Enabled"
}
```

<h3 id="get__bmc_bios_{xname}_{bios_field}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.|[bmc_bios_tpm_state](#schemabmc_bios_tpm_state)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Xname was not for a bmc.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error including failures communicating with the server.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__bmc_bios_{xname}_{bios_field}

> Code samples

```http
PATCH http://api-gw-service-nmn.local/apis/scsd/v1/bmc/bios/{xname}/{bios_field} HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH http://api-gw-service-nmn.local/apis/scsd/v1/bmc/bios/{xname}/{bios_field} \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/bios/{xname}/{bios_field}', headers = headers)

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
    req, err := http.NewRequest("PATCH", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/bios/{xname}/{bios_field}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /bmc/bios/{xname}/{bios_field}`

*Set the TPM State field in the BIOS settings*

Set the TPM State in the BIOS settings.

> Body parameter

```json
{
  "Future": "Enabled"
}
```

<h3 id="patch__bmc_bios_{xname}_{bios_field}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|[xname_for_node](#schemaxname_for_node)|true|Locational xname of the BMC.|
|bios_field|path|[bios_field](#schemabios_field)|true|Name of the BIOS field|
|body|body|[bmc_bios_tpm_state_put](#schemabmc_bios_tpm_state_put)|false|none|

#### Enumerated Values

|Parameter|Value|
|---|---|
|bios_field|tpmstate|

> Example responses

> 400 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="patch__bmc_bios_{xname}_{bios_field}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|OK. The value was set.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad request.|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Xname was not for a bmc.|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal server error including failures communicating with the server.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="system-configuration-service-version">version</h1>

Endpoints that perform health and version checks

## get__version

> Code samples

```http
GET http://api-gw-service-nmn.local/apis/scsd/v1/version HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://api-gw-service-nmn.local/apis/scsd/v1/version \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://api-gw-service-nmn.local/apis/scsd/v1/version', headers = headers)

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
    req, err := http.NewRequest("GET", "http://api-gw-service-nmn.local/apis/scsd/v1/version", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /version`

*Retrieve service version information*

Retrieve service version information.  Version is returned in vmaj.min.bld format

> Example responses

> 200 Response

```json
{
  "Version": "v1.2.3"
}
```

<h3 id="get__version-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Information retrieved successfully|[version](#schemaversion)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only GET,POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="system-configuration-service-certs">certs</h1>

Endpoints that create, delete, fetch, and apply TLS certs

## post__bmc_createcerts

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/createcerts HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/createcerts \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/createcerts', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/createcerts", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/createcerts`

*Create TLS cert/key pairs for a set of targets*

Create TLS cert/key pairs for a set of BMC targets.  A TLS cert/key is created per BMC 'domain', the default being one cert per cabinet to be used by all BMCs in that cabinet.  TLS cert/key info is stored in secure storage for subsequent application or viewing.

> Body parameter

```json
{
  "Domain": "Cabinet",
  "DomainIDs": [
    "x0c0s0b0"
  ]
}
```

<h3 id="post__bmc_createcerts-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[bmc_managecerts_request](#schemabmc_managecerts_request)|false|none|

> Example responses

> 200 Response

```json
{
  "DomainIDs": [
    {
      "ID": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK"
    }
  ]
}
```

<h3 id="post__bmc_createcerts-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully retrieved|[bmc_managecerts_response](#schemabmc_managecerts_response)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only POST or DELETE is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

## post__bmc_deletecerts

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/deletecerts HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/deletecerts \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/deletecerts', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/deletecerts", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/deletecerts`

*Delete TLS cert/key pairs for a set of targets*

Delete TLS cert/key information for domain-level TLS certs based on the given targets.  There will be one TLS cert/key per BMC 'domain' which will be deleted from secure storage.

> Body parameter

```json
{
  "Domain": "Cabinet",
  "DomainIDs": [
    "x0c0s0b0"
  ]
}
```

<h3 id="post__bmc_deletecerts-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[bmc_managecerts_request](#schemabmc_managecerts_request)|false|none|

> Example responses

> 200 Response

```json
{
  "DomainIDs": [
    {
      "ID": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK"
    }
  ]
}
```

<h3 id="post__bmc_deletecerts-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully retrieved|[bmc_managecerts_response](#schemabmc_managecerts_response)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only POST or DELETE is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

## post__bmc_fetchcerts

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/fetchcerts HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/fetchcerts \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/fetchcerts', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/fetchcerts", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/fetchcerts`

*Fetch previously created BMC TLS certs for viewing.*

Fetches BMC TLS certs previously created using the /bmc/createcerts endpoint and stored in secure storage.  This API does not interact with Redfish BMCs.

> Body parameter

```json
{
  "Domain": "Cabinet",
  "DomainIDs": [
    "x0c0s0b0"
  ]
}
```

<h3 id="post__bmc_fetchcerts-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[bmc_managecerts_request](#schemabmc_managecerts_request)|false|none|

> Example responses

> 200 Response

```json
{
  "DomainIDs": [
    {
      "ID": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK",
      "Cert": {
        "CertType": "PEM",
        "CertData": "-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----"
      }
    }
  ]
}
```

<h3 id="post__bmc_fetchcerts-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully retrieved|[bmc_fetchcerts_response](#schemabmc_fetchcerts_response)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

## post__bmc_setcerts

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/setcerts HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/setcerts \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/setcerts', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/setcerts", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/setcerts`

*Apply previously-generated TLS cert/key data to target BMCs*

Apply TLS cert/key pairs, previously generated using the /bmc/createcerts endpoint, to target BMCs. The Force field is optional. If present, and set to 'true', the Redfish operations will be attempted without contacting HSM and without verifying if the targets are present or are in a good state. If the "Force" field is not present or is present but set to 'false', HSM will be used.

> Body parameter

```json
{
  "Force": false,
  "CertDomain": "Cabinet",
  "Targets": [
    "x0c0s0b0"
  ]
}
```

<h3 id="post__bmc_setcerts-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[bmc_rfcerts_request](#schemabmc_rfcerts_request)|false|none|

> Example responses

> 200 Response

```json
{
  "Targets": [
    {
      "ID": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK"
    }
  ]
}
```

<h3 id="post__bmc_setcerts-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully retrieved|[bmc_rfcerts_response](#schemabmc_rfcerts_response)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

## post__bmc_setcert_{xname}

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/setcert/{xname} HTTP/1.1
Host: api-gw-service-nmn.local

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/scsd/v1/bmc/setcert/{xname}

```

```python
import requests

r = requests.post('http://api-gw-service-nmn.local/apis/scsd/v1/bmc/setcert/{xname}')

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/scsd/v1/bmc/setcert/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /bmc/setcert/{xname}`

*Apply previously-generated TLS cert/key data to the target BMC*

Apply a TLS cert/key pairs previously generated using the /bmc/createcerts endpoint to the target BMC. The Force parameter is optional. If present, and set to 'true', the Redfish operations will be attempted without contacting HSM and without verifying if the targets are present or are in a good state. If the "Force" parameter is not present or is present but set to 'false', HSM will be used.

<h3 id="post__bmc_setcert_{xname}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|[xname](#schemaxname)|true|none|
|Force|query|boolean|false|If true do not verify xname with HSM|
|Domain|query|string|false|none|

<h3 id="post__bmc_setcert_{xname}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The cert was succesfully applied to BMC target|None|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Endpoint not found|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Invalid method, only POST is allowed|None|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="system-configuration-service-cli_ignore">cli_ignore</h1>

## get__liveness

> Code samples

```http
GET http://api-gw-service-nmn.local/apis/scsd/v1/liveness HTTP/1.1
Host: api-gw-service-nmn.local

```

```shell
# You can also use wget
curl -X GET http://api-gw-service-nmn.local/apis/scsd/v1/liveness

```

```python
import requests

r = requests.get('http://api-gw-service-nmn.local/apis/scsd/v1/liveness')

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
    req, err := http.NewRequest("GET", "http://api-gw-service-nmn.local/apis/scsd/v1/liveness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /liveness`

*Get liveness status of the service*

Get liveness status of the service

<h3 id="get__liveness-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|The service is not taking HTTP requests|None|

<aside class="success">
This operation does not require authentication
</aside>

## get__readiness

> Code samples

```http
GET http://api-gw-service-nmn.local/apis/scsd/v1/readiness HTTP/1.1
Host: api-gw-service-nmn.local

```

```shell
# You can also use wget
curl -X GET http://api-gw-service-nmn.local/apis/scsd/v1/readiness

```

```python
import requests

r = requests.get('http://api-gw-service-nmn.local/apis/scsd/v1/readiness')

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
    req, err := http.NewRequest("GET", "http://api-gw-service-nmn.local/apis/scsd/v1/readiness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /readiness`

*Get readiness status of the service*

Get readiness status of the service

<h3 id="get__readiness-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|The service is not taking HTTP requests|None|

<aside class="success">
This operation does not require authentication
</aside>

## get__health

> Code samples

```http
GET http://api-gw-service-nmn.local/apis/scsd/v1/health HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://api-gw-service-nmn.local/apis/scsd/v1/health \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://api-gw-service-nmn.local/apis/scsd/v1/health', headers = headers)

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
    req, err := http.NewRequest("GET", "http://api-gw-service-nmn.local/apis/scsd/v1/health", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /health`

*Get readiness status of the service*

Get readiness status of the service

> Example responses

> 200 Response

```json
{
  "TaskRunnerStatus": "OK",
  "TaskRunnerMode": "Local",
  "VaultStatus": "Connected"
}
```

<h3 id="get__health-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK. All health parameters are operational.|[health](#schemahealth)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|The service encountered an error when gathering health information|None|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|The service is not taking HTTP requests|None|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_xname">xname</h2>
<!-- backwards compatibility -->
<a id="schemaxname"></a>
<a id="schema_xname"></a>
<a id="tocSxname"></a>
<a id="tocsxname"></a>

```json
"x0c0s0b0"

```

The xname of this piece of hardware

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The xname of this piece of hardware|

<h2 id="tocS_xname_for_node">xname_for_node</h2>
<!-- backwards compatibility -->
<a id="schemaxname_for_node"></a>
<a id="schema_xname_for_node"></a>
<a id="tocSxname_for_node"></a>
<a id="tocsxname_for_node"></a>

```json
"x0c0s0b0n0"

```

The xname of this piece of hardware

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The xname of this piece of hardware|

<h2 id="tocS_xname_list">xname_list</h2>
<!-- backwards compatibility -->
<a id="schemaxname_list"></a>
<a id="schema_xname_list"></a>
<a id="tocSxname_list"></a>
<a id="tocsxname_list"></a>

```json
"x1000c0s0b0,x1000c0s1b0"

```

Comma separated list of xnames

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Comma separated list of xnames|

<h2 id="tocS_bios_field">bios_field</h2>
<!-- backwards compatibility -->
<a id="schemabios_field"></a>
<a id="schema_bios_field"></a>
<a id="tocSbios_field"></a>
<a id="tocsbios_field"></a>

```json
"tpmstate"

```

The name of the BIOS field

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The name of the BIOS field|

#### Enumerated Values

|Property|Value|
|---|---|
|*anonymous*|tpmstate|

<h2 id="tocS_ntp_server_info_kw">ntp_server_info_kw</h2>
<!-- backwards compatibility -->
<a id="schemantp_server_info_kw"></a>
<a id="schema_ntp_server_info_kw"></a>
<a id="tocSntp_server_info_kw"></a>
<a id="tocsntp_server_info_kw"></a>

```json
"NTPServerInfo"

```

NTP server

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|NTP server|

<h2 id="tocS_syslog_server_info_kw">syslog_server_info_kw</h2>
<!-- backwards compatibility -->
<a id="schemasyslog_server_info_kw"></a>
<a id="schema_syslog_server_info_kw"></a>
<a id="tocSsyslog_server_info_kw"></a>
<a id="tocssyslog_server_info_kw"></a>

```json
"SyslogServerInfo"

```

Syslog server

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Syslog server|

<h2 id="tocS_sshkey_kw">sshkey_kw</h2>
<!-- backwards compatibility -->
<a id="schemasshkey_kw"></a>
<a id="schema_sshkey_kw"></a>
<a id="tocSsshkey_kw"></a>
<a id="tocssshkey_kw"></a>

```json
"SSHKey"

```

SSH key

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|SSH key|

<h2 id="tocS_sshconkey_kw">sshconkey_kw</h2>
<!-- backwards compatibility -->
<a id="schemasshconkey_kw"></a>
<a id="schema_sshconkey_kw"></a>
<a id="tocSsshconkey_kw"></a>
<a id="tocssshconkey_kw"></a>

```json
"SSHConsoleKey"

```

SSH console key

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|SSH console key|

<h2 id="tocS_cfg_types">cfg_types</h2>
<!-- backwards compatibility -->
<a id="schemacfg_types"></a>
<a id="schema_cfg_types"></a>
<a id="tocScfg_types"></a>
<a id="tocscfg_types"></a>

```json
"NTPServerInfo"

```

Redfish Network Protocol parameter names

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Redfish Network Protocol parameter names|

<h2 id="tocS_target_ntp_server">target_ntp_server</h2>
<!-- backwards compatibility -->
<a id="schematarget_ntp_server"></a>
<a id="schema_target_ntp_server"></a>
<a id="tocStarget_ntp_server"></a>
<a id="tocstarget_ntp_server"></a>

```json
{
  "NTPServers": "sms-ncn-w001",
  "Port": 0,
  "ProtocolEnabled": true
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|NTPServers|string|false|none|NTP service server name|
|Port|integer|false|none|none|
|ProtocolEnabled|boolean|false|none|none|

<h2 id="tocS_target_syslog_server">target_syslog_server</h2>
<!-- backwards compatibility -->
<a id="schematarget_syslog_server"></a>
<a id="schema_target_syslog_server"></a>
<a id="tocStarget_syslog_server"></a>
<a id="tocstarget_syslog_server"></a>

```json
{
  "SyslogServers": "sms-ncn-w001",
  "Port": 0,
  "ProtocolEnabled": true
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|SyslogServers|string|false|none|Syslog service server name|
|Port|integer|false|none|none|
|ProtocolEnabled|boolean|false|none|none|

<h2 id="tocS_target_ssh_key">target_ssh_key</h2>
<!-- backwards compatibility -->
<a id="schematarget_ssh_key"></a>
<a id="schema_target_ssh_key"></a>
<a id="tocStarget_ssh_key"></a>
<a id="tocstarget_ssh_key"></a>

```json
"xyzabc123..."

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|none|

<h2 id="tocS_params">params</h2>
<!-- backwards compatibility -->
<a id="schemaparams"></a>
<a id="schema_params"></a>
<a id="tocSparams"></a>
<a id="tocsparams"></a>

```json
{
  "NTPServerInfo": {
    "NTPServers": "sms-ncn-w001",
    "Port": 0,
    "ProtocolEnabled": true
  },
  "SyslogServerInfo": {
    "SyslogServers": "sms-ncn-w001",
    "Port": 0,
    "ProtocolEnabled": true
  },
  "SSHKey": "xyzabc123...",
  "SSHConsoleKey": "xyzabc123..."
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|NTPServerInfo|[target_ntp_server](#schematarget_ntp_server)|false|none|none|
|SyslogServerInfo|[target_syslog_server](#schematarget_syslog_server)|false|none|none|
|SSHKey|[target_ssh_key](#schematarget_ssh_key)|false|none|none|
|SSHConsoleKey|[target_ssh_key](#schematarget_ssh_key)|false|none|none|

<h2 id="tocS_target_cfg_item">target_cfg_item</h2>
<!-- backwards compatibility -->
<a id="schematarget_cfg_item"></a>
<a id="schema_target_cfg_item"></a>
<a id="tocStarget_cfg_item"></a>
<a id="tocstarget_cfg_item"></a>

```json
{
  "StatusCode": 0,
  "StatusMsg": "string",
  "Xname": "x0c0s0b0",
  "Params": {
    "NTPServerInfo": {
      "NTPServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SyslogServerInfo": {
      "SyslogServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SSHKey": "xyzabc123...",
    "SSHConsoleKey": "xyzabc123..."
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|StatusCode|integer|true|none|none|
|StatusMsg|string|true|none|none|
|Xname|[xname](#schemaxname)|true|none|The xname of this piece of hardware|
|Params|[params](#schemaparams)|false|none|none|

<h2 id="tocS_cfg_get_single">cfg_get_single</h2>
<!-- backwards compatibility -->
<a id="schemacfg_get_single"></a>
<a id="schema_cfg_get_single"></a>
<a id="tocScfg_get_single"></a>
<a id="tocscfg_get_single"></a>

```json
{
  "Force": true,
  "Params": {
    "NTPServerInfo": {
      "NTPServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SyslogServerInfo": {
      "SyslogServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SSHKey": "xyzabc123...",
    "SSHConsoleKey": "xyzabc123..."
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Force|boolean|false|none|none|
|Params|[params](#schemaparams)|false|none|none|

<h2 id="tocS_cfg_post_single">cfg_post_single</h2>
<!-- backwards compatibility -->
<a id="schemacfg_post_single"></a>
<a id="schema_cfg_post_single"></a>
<a id="tocScfg_post_single"></a>
<a id="tocscfg_post_single"></a>

```json
{
  "Force": true,
  "Params": {
    "NTPServerInfo": {
      "NTPServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SyslogServerInfo": {
      "SyslogServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SSHKey": "xyzabc123...",
    "SSHConsoleKey": "xyzabc123..."
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Force|boolean|false|none|none|
|Params|[params](#schemaparams)|false|none|none|

<h2 id="tocS_cfg_rsp_status">cfg_rsp_status</h2>
<!-- backwards compatibility -->
<a id="schemacfg_rsp_status"></a>
<a id="schema_cfg_rsp_status"></a>
<a id="tocScfg_rsp_status"></a>
<a id="tocscfg_rsp_status"></a>

```json
{
  "StatusMsg": "OK"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|StatusMsg|string|false|none|none|

<h2 id="tocS_bmc_dumpcfg_request">bmc_dumpcfg_request</h2>
<!-- backwards compatibility -->
<a id="schemabmc_dumpcfg_request"></a>
<a id="schema_bmc_dumpcfg_request"></a>
<a id="tocSbmc_dumpcfg_request"></a>
<a id="tocsbmc_dumpcfg_request"></a>

```json
{
  "Targets": [
    "x0c0s0b0"
  ],
  "Params": [
    "NTPServerInfo"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Targets|[[xname](#schemaxname)]|true|none|[The xname of this piece of hardware]|
|Params|[[cfg_types](#schemacfg_types)]|false|none|[Redfish Network Protocol parameter names]|

<h2 id="tocS_multi_post_response_elem">multi_post_response_elem</h2>
<!-- backwards compatibility -->
<a id="schemamulti_post_response_elem"></a>
<a id="schema_multi_post_response_elem"></a>
<a id="tocSmulti_post_response_elem"></a>
<a id="tocsmulti_post_response_elem"></a>

```json
{
  "Xname": "x0c0s0b0",
  "StatusCode": 200,
  "StatusMsg": "OK"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Xname|[xname](#schemaxname)|false|none|The xname of this piece of hardware|
|StatusCode|integer|false|none|none|
|StatusMsg|string|false|none|none|

<h2 id="tocS_multi_post_response">multi_post_response</h2>
<!-- backwards compatibility -->
<a id="schemamulti_post_response"></a>
<a id="schema_multi_post_response"></a>
<a id="tocSmulti_post_response"></a>
<a id="tocsmulti_post_response"></a>

```json
{
  "Targets": [
    {
      "Xname": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Targets|[[multi_post_response_elem](#schemamulti_post_response_elem)]|false|none|none|

<h2 id="tocS_bmc_dumpcfg_response">bmc_dumpcfg_response</h2>
<!-- backwards compatibility -->
<a id="schemabmc_dumpcfg_response"></a>
<a id="schema_bmc_dumpcfg_response"></a>
<a id="tocSbmc_dumpcfg_response"></a>
<a id="tocsbmc_dumpcfg_response"></a>

```json
{
  "Targets": [
    {
      "StatusCode": 0,
      "StatusMsg": "string",
      "Xname": "x0c0s0b0",
      "Params": {
        "NTPServerInfo": {
          "NTPServers": "sms-ncn-w001",
          "Port": 0,
          "ProtocolEnabled": true
        },
        "SyslogServerInfo": {
          "SyslogServers": "sms-ncn-w001",
          "Port": 0,
          "ProtocolEnabled": true
        },
        "SSHKey": "xyzabc123...",
        "SSHConsoleKey": "xyzabc123..."
      }
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Targets|[[target_cfg_item](#schematarget_cfg_item)]|false|none|none|

<h2 id="tocS_bmc_loadcfg_request">bmc_loadcfg_request</h2>
<!-- backwards compatibility -->
<a id="schemabmc_loadcfg_request"></a>
<a id="schema_bmc_loadcfg_request"></a>
<a id="tocSbmc_loadcfg_request"></a>
<a id="tocsbmc_loadcfg_request"></a>

```json
{
  "Force": true,
  "Targets": [
    "x0c0s0b0"
  ],
  "Params": {
    "NTPServer": {
      "NTPServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SyslogServer": {
      "SyslogServers": "sms-ncn-w001",
      "Port": 0,
      "ProtocolEnabled": true
    },
    "SSHKey": "xyzabc123...",
    "SSHConsoleKey": "xyzabc123..."
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Force|boolean|false|none|none|
|Targets|[[xname](#schemaxname)]|true|none|[The xname of this piece of hardware]|
|Params|object|false|none|none|
|» NTPServer|[target_ntp_server](#schematarget_ntp_server)|false|none|none|
|» SyslogServer|[target_syslog_server](#schematarget_syslog_server)|false|none|none|
|» SSHKey|[target_ssh_key](#schematarget_ssh_key)|false|none|none|
|» SSHConsoleKey|[target_ssh_key](#schematarget_ssh_key)|false|none|none|

<h2 id="tocS_creds_data">creds_data</h2>
<!-- backwards compatibility -->
<a id="schemacreds_data"></a>
<a id="schema_creds_data"></a>
<a id="tocScreds_data"></a>
<a id="tocscreds_data"></a>

```json
{
  "Username": "admin-user",
  "Password": "admin-pw"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Username|string|false|none|none|
|Password|string|false|none|none|

<h2 id="tocS_creds_target">creds_target</h2>
<!-- backwards compatibility -->
<a id="schemacreds_target"></a>
<a id="schema_creds_target"></a>
<a id="tocScreds_target"></a>
<a id="tocscreds_target"></a>

```json
{
  "Xname": "x0c0s0b0",
  "Creds": {
    "Username": "admin-user",
    "Password": "admin-pw"
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Xname|[xname](#schemaxname)|false|none|The xname of this piece of hardware|
|Creds|[creds_data](#schemacreds_data)|false|none|none|

<h2 id="tocS_creds_components">creds_components</h2>
<!-- backwards compatibility -->
<a id="schemacreds_components"></a>
<a id="schema_creds_components"></a>
<a id="tocScreds_components"></a>
<a id="tocscreds_components"></a>

```json
{
  "Force": true,
  "Targets": [
    {
      "Xname": "x0c0s0b0",
      "Creds": {
        "Username": "admin-user",
        "Password": "admin-pw"
      }
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Force|boolean|false|none|none|
|Targets|[[creds_target](#schemacreds_target)]|false|none|none|

<h2 id="tocS_creds_single">creds_single</h2>
<!-- backwards compatibility -->
<a id="schemacreds_single"></a>
<a id="schema_creds_single"></a>
<a id="tocScreds_single"></a>
<a id="tocscreds_single"></a>

```json
{
  "Force": true,
  "Creds": {
    "Username": "admin-user",
    "Password": "admin-pw"
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Force|boolean|false|none|none|
|Creds|[creds_data](#schemacreds_data)|false|none|none|

<h2 id="tocS_creds_global">creds_global</h2>
<!-- backwards compatibility -->
<a id="schemacreds_global"></a>
<a id="schema_creds_global"></a>
<a id="tocScreds_global"></a>
<a id="tocscreds_global"></a>

```json
{
  "Force": true,
  "Username": "string",
  "Password": "string",
  "Targets": [
    "x0c0s0b0"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Force|boolean|false|none|none|
|Username|string|false|none|none|
|Password|string|false|none|none|
|Targets|[[xname](#schemaxname)]|false|none|[The xname of this piece of hardware]|

<h2 id="tocS_creds_fetch_rsp">creds_fetch_rsp</h2>
<!-- backwards compatibility -->
<a id="schemacreds_fetch_rsp"></a>
<a id="schema_creds_fetch_rsp"></a>
<a id="tocScreds_fetch_rsp"></a>
<a id="tocscreds_fetch_rsp"></a>

```json
[
  {
    "Xname": "x0c0s0b0",
    "Username": "admin",
    "Password": "pwstring",
    "StatusCode": 200,
    "StatusMsg": "OK"
  }
]

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[creds_fetch_rsp_elmt](#schemacreds_fetch_rsp_elmt)]|false|none|none|

<h2 id="tocS_creds_fetch_rsp_elmt">creds_fetch_rsp_elmt</h2>
<!-- backwards compatibility -->
<a id="schemacreds_fetch_rsp_elmt"></a>
<a id="schema_creds_fetch_rsp_elmt"></a>
<a id="tocScreds_fetch_rsp_elmt"></a>
<a id="tocscreds_fetch_rsp_elmt"></a>

```json
{
  "Xname": "x0c0s0b0",
  "Username": "admin",
  "Password": "pwstring",
  "StatusCode": 200,
  "StatusMsg": "OK"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Xname|[xname](#schemaxname)|false|none|The xname of this piece of hardware|
|Username|string|false|none|none|
|Password|string|false|none|none|
|StatusCode|integer|false|none|none|
|StatusMsg|string|false|none|none|

<h2 id="tocS_bmc_managecerts_request">bmc_managecerts_request</h2>
<!-- backwards compatibility -->
<a id="schemabmc_managecerts_request"></a>
<a id="schema_bmc_managecerts_request"></a>
<a id="tocSbmc_managecerts_request"></a>
<a id="tocsbmc_managecerts_request"></a>

```json
{
  "Domain": "Cabinet",
  "DomainIDs": [
    "x0c0s0b0"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Domain|string|false|none|none|
|DomainIDs|[[xname](#schemaxname)]|false|none|[The xname of this piece of hardware]|

<h2 id="tocS_bmc_managecerts_response">bmc_managecerts_response</h2>
<!-- backwards compatibility -->
<a id="schemabmc_managecerts_response"></a>
<a id="schema_bmc_managecerts_response"></a>
<a id="tocSbmc_managecerts_response"></a>
<a id="tocsbmc_managecerts_response"></a>

```json
{
  "DomainIDs": [
    {
      "ID": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|DomainIDs|[[cert_rsp](#schemacert_rsp)]|false|none|none|

<h2 id="tocS_bmc_fetchcerts_response">bmc_fetchcerts_response</h2>
<!-- backwards compatibility -->
<a id="schemabmc_fetchcerts_response"></a>
<a id="schema_bmc_fetchcerts_response"></a>
<a id="tocSbmc_fetchcerts_response"></a>
<a id="tocsbmc_fetchcerts_response"></a>

```json
{
  "DomainIDs": [
    {
      "ID": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK",
      "Cert": {
        "CertType": "PEM",
        "CertData": "-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----"
      }
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|DomainIDs|[[cert_rsp_with_cert](#schemacert_rsp_with_cert)]|false|none|none|

<h2 id="tocS_cert_rsp">cert_rsp</h2>
<!-- backwards compatibility -->
<a id="schemacert_rsp"></a>
<a id="schema_cert_rsp"></a>
<a id="tocScert_rsp"></a>
<a id="tocscert_rsp"></a>

```json
{
  "ID": "x0c0s0b0",
  "StatusCode": 200,
  "StatusMsg": "OK"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[xname](#schemaxname)|false|none|The xname of this piece of hardware|
|StatusCode|integer|false|none|none|
|StatusMsg|string|false|none|none|

<h2 id="tocS_cert_rsp_with_cert">cert_rsp_with_cert</h2>
<!-- backwards compatibility -->
<a id="schemacert_rsp_with_cert"></a>
<a id="schema_cert_rsp_with_cert"></a>
<a id="tocScert_rsp_with_cert"></a>
<a id="tocscert_rsp_with_cert"></a>

```json
{
  "ID": "x0c0s0b0",
  "StatusCode": 200,
  "StatusMsg": "OK",
  "Cert": {
    "CertType": "PEM",
    "CertData": "-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----"
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|[xname](#schemaxname)|false|none|The xname of this piece of hardware|
|StatusCode|integer|false|none|none|
|StatusMsg|string|false|none|none|
|Cert|object|false|none|none|
|» CertType|string|false|none|none|
|» CertData|string|false|none|none|

<h2 id="tocS_bmc_rfcerts_request">bmc_rfcerts_request</h2>
<!-- backwards compatibility -->
<a id="schemabmc_rfcerts_request"></a>
<a id="schema_bmc_rfcerts_request"></a>
<a id="tocSbmc_rfcerts_request"></a>
<a id="tocsbmc_rfcerts_request"></a>

```json
{
  "Force": false,
  "CertDomain": "Cabinet",
  "Targets": [
    "x0c0s0b0"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Force|boolean|false|none|none|
|CertDomain|string|false|none|none|
|Targets|[[xname](#schemaxname)]|false|none|[The xname of this piece of hardware]|

<h2 id="tocS_bmc_rfcerts_response">bmc_rfcerts_response</h2>
<!-- backwards compatibility -->
<a id="schemabmc_rfcerts_response"></a>
<a id="schema_bmc_rfcerts_response"></a>
<a id="tocSbmc_rfcerts_response"></a>
<a id="tocsbmc_rfcerts_response"></a>

```json
{
  "Targets": [
    {
      "ID": "x0c0s0b0",
      "StatusCode": 200,
      "StatusMsg": "OK"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Targets|[[cert_rsp](#schemacert_rsp)]|false|none|none|

<h2 id="tocS_bmc_bios_tpm_state">bmc_bios_tpm_state</h2>
<!-- backwards compatibility -->
<a id="schemabmc_bios_tpm_state"></a>
<a id="schema_bmc_bios_tpm_state"></a>
<a id="tocSbmc_bios_tpm_state"></a>
<a id="tocsbmc_bios_tpm_state"></a>

```json
{
  "Current": "Enabled",
  "Future": "Enabled"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Current|string|false|none|The current BIOS setting|
|Future|string|false|none|The future BIOS setting which will take affect when the node is rebooted|

#### Enumerated Values

|Property|Value|
|---|---|
|Current|Disabled|
|Current|Enabled|
|Current|NotPresent|
|Future|Disabled|
|Future|Enabled|
|Future|NotPresent|

<h2 id="tocS_bmc_bios_tpm_state_put">bmc_bios_tpm_state_put</h2>
<!-- backwards compatibility -->
<a id="schemabmc_bios_tpm_state_put"></a>
<a id="schema_bmc_bios_tpm_state_put"></a>
<a id="tocSbmc_bios_tpm_state_put"></a>
<a id="tocsbmc_bios_tpm_state_put"></a>

```json
{
  "Future": "Enabled"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Future|string|false|none|The future BIOS setting which will take affect when the node is rebooted|

#### Enumerated Values

|Property|Value|
|---|---|
|Future|Disabled|
|Future|Enabled|

<h2 id="tocS_version">version</h2>
<!-- backwards compatibility -->
<a id="schemaversion"></a>
<a id="schema_version"></a>
<a id="tocSversion"></a>
<a id="tocsversion"></a>

```json
{
  "Version": "v1.2.3"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Version|string|false|none|none|

<h2 id="tocS_health">health</h2>
<!-- backwards compatibility -->
<a id="schemahealth"></a>
<a id="schema_health"></a>
<a id="tocShealth"></a>
<a id="tocshealth"></a>

```json
{
  "TaskRunnerStatus": "OK",
  "TaskRunnerMode": "Local",
  "VaultStatus": "Connected"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|TaskRunnerStatus|string|false|none|none|
|TaskRunnerMode|string|false|none|none|
|VaultStatus|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|TaskRunnerMode|Local|
|TaskRunnerMode|Worker|

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

