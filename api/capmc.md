<!-- Generator: Widdershins v4.0.1 -->

<h1 id="cray-advanced-platform-monitoring-and-control-capmc-">Cray Advanced Platform Monitoring and Control (CAPMC) v3</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

## Deprecation Notice: many CAPMC v1 features are being partially deprecated
#### Effective CSM 1.0 -> removed as part of CSM 1.3
Many CAPMC v1 REST API and CLI features are being deprecated as part of CSM version 1.0; Full removal of the deprecated CAPMC features will happen in CSM version 1.3. Further development of CAPMC service or CLI has stopped. CAPMC has entered end-of-life but will still be generally available. CAPMC is going to be replaced with the Power Control Service (PCS) in a future release. The current API/CLI portfolio for CAPMC are being pruned to better align with the future direction of PCS. More information about PCS and the CAPMC transition will be released as part of subsequent CSM releases.

The API endpoints that remain un-deprecated will remain supported until their 'phased transition' into PCS (e.g. Power Capping is not 'deprecated' and will be supported in PCS; As PCS is developed, CAPMC's Powercapping and PCS's Powercapping will both function, eventually callers of the CAPMC power capping API/CLI will need to will need transition to call PCS as the API will be different.)

Here is a list of deprecated API (CLI) endpoints:
* node control  
  * `/get_node_rules`
  * `/get_node_status`
  * `/node_on`
  * `/node_off`
  * `/node_reinit`
  * `/node_status`
* group control
  * `/group_reinit`
  * `/get_group_status`
  * `/group_on`
  * `/group_off`
* node energy
  * `/get_node_energy`
  * `/get_node_energy_stats`
  * `/get_node_energy_counter`
* system monitor
  * `/get_system_parameters`
  * `/get_system_power`
  * `/get_system_power_details`
* EPO
  * `/emergency_power_off`  
* utilities
  * `/get_nid_map`

## Introduction
The Cray Advanced Platform Monitoring and Control (CAPMC) API provides remote power monitoring and control to agents running externally to the Cray System Management Services.

These controls enable external software to manage the power state of an entire system and to more intelligently manage systemwide power consumption. The following API calls are provided as a means for third party software to implement power control and management strategies as simple or complex as the site-level requirements demand. The simplest power management strategy may be to simply turn off components which may be idle for a significant time interval and turn them back on when demand increases.

This implementation of CAPMC uses Redfish APIs to communicate directly with the hardware. Furthermore, all CAPMC power commands should be viewed as **asynchronous** and require the client to check for status after a CAPMC API call returns.
## Controls
### component control

  CAPMC component power controls implement a simple interface for powering
  off or on components (chassis, modules, nodes), and querying component
  state information using component identifiers known as xnames. These
  controls enable external software to more intelligently manage systemwide
  power consumption or configuration parameters.

### power capping

  CAPMC power capping controls implement a simple interface for
  querying component capabilities and manipulation of node or sub-node
  (accelerator) power constraints. This functionality enables external
  software to establish an upper bound, or estimate a minimum bound, on
  the amount of power a system or a select subset of the system may
  consume. The power capping API calls are provided as a means for third
  party software to implement advanced power management strategies.

Base URLs:

* <a href="http://api-gw-service-nmn.local/apis/capmc/capmc/v1">http://api-gw-service-nmn.local/apis/capmc/capmc/v1</a>

<h1 id="cray-advanced-platform-monitoring-and-control-capmc--component-control">component control</h1>

## post__get_xname_status

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_xname_status HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_xname_status \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_xname_status', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_xname_status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /get_xname_status`

*Return component status*

The `get_xname_status` API returns component state for the full system or a subset of components as specified by a xname list and/or state filter. This status API is intended, but not limited, to be used in conjunction with operations which may modify component state, such as `xname_on` or `xname_off`.

By default, the status returned from this API are the hardware states as reported by Redfish (**on** or **off**). An optional `source` parameter may be passed in the request body to report the states defined by the Cray Hardware Management System (HMS) software.

The `get_xname_status` API does not report **empty** components.

**Filters**

Filters for a status query may be supplied as a pipe-separated (|) list surrounded with double quotes, e.g. "filter1|filter2|filter3". Valid filters are: `show_all`, `show_off`, `show_on`, `show_halt`, `show_standby`, `show_ready`, and `show_disabled`. Valid flag filters are `show_alert`, `show_resvd`, and `show_warn`. Status and flag filters may be intermixed freely. The `show_all` filter overrides any other status or flag filters and is the default.

**Notice**

The Hardware Management System no longer supports a "diag" state, as such the `show_diag` filter is considered deprecated. Specifying only the `show_diag` filter will not return any results.

> Body parameter

```json
{
  "filter": "show_ready|show_standby",
  "source": "hsm",
  "xnames": [
    "x0c0s1b0n0",
    "x0c1s4b0n0",
    "x0c1s6b0n0",
    "x0c1s7b0n0",
    "x0c0s1b0n1",
    "x0c1s4b0n1",
    "x0c1s6b0n1",
    "x0c1s7b0n1"
  ]
}
```

<h3 id="post__get_xname_status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|object|true|A JSON object to get status for selected components.|
|» filter|body|string|false|Optional, pipe concatenated (|) list of filter strings, e.g. "filter1|filter2|filter3". Valid status filters are `show_all`, `show_disabled`, `show_halt`, `show_off`, `show_on`, `show_ready`, and `show_standby`. Valid flag filters are `show_alert`, `show_resvd`, and `show_warn`. Status and flag filters may be intermixed freely. If omitted, the default is `show_all`.|
|» source|body|any|false|A string indicating the source for node status. Valid sources are `HSM` (or its aliases `HMS`, `SM`, `SMD`, or `Software`) and `Redfish` (or its alias `Hardware`). The default, when unspecified, is to use Redfish via the appropriate controller as the source for all status. The Hardware Management System (HMS) returns the largest set of possible status. A Redfish hardware source can *only* report **off** and **on** status for components.  Source strings are normalized to all lower case so `HSM` or `hsm` are both valid.|
|» xnames|body|[string]|false|User specified list of component IDs (xnames) to get the status of. An empty array indicates all components in the system. If invalid xnames are specified then an error will be returned.|

> Example responses

> 200 Response

```json
{
  "e": 0,
  "err_msg": "",
  "ready": [
    "x0c0s1b1n0",
    "x0c1s4b1n0",
    "x0c1s6b1n0",
    "x0c1s7b1n0"
  ],
  "standby": [
    "x0c0s1b1n1",
    "x0c1s4b1n1",
    "x0c1s6b1n1",
    "x0c1s7b1n1"
  ]
}
```

<h3 id="post__get_xname_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|[Bad Request](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.1)|[httpError400_BadRequest](#schemahttperror400_badrequest)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|[Method Not Allowed](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.6)|[httpError405_MethodNotAllowed](#schemahttperror405_methodnotallowed)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|[Internal Server Error](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.1)|[httpError500_InternalServerError](#schemahttperror500_internalservererror)|

<h3 id="post__get_xname_status-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» e|integer(int32)|true|none|Request status code, zero on success, non-zero on error.|
|» err_msg|string|true|none|Message indicating any error encountered.|
|» on|[string]|false|none|Optional, list of powered on components by xname.|
|» off|[string]|false|none|Optional, list of powered off components by xname.|
|» disabled|[string]|false|none|Optional, list of disabled components by xname. The component is physically installed, but ignored by system management software. The Hardware Management System does not treat disabled as a separate state and as such disabled does not indicate the anything about the hardware or software state of a node.|
|» ready|[string]|false|none|Optional, list of booted components by xname. Operating system is fully booted and sending heartbeats.|
|» standby|[string]|false|none|Optional, list of components in standby by xname. Components that were previously booted and but are no longer sending heartbeat.|

<aside class="success">
This operation does not require authentication
</aside>

## post__xname_reinit

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_reinit HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_reinit \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_reinit', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_reinit", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /xname_reinit`

*Restart components*

The `xname_reinit` API issues a **restart** or **off-on** sequence to a selected list of components by xname. These power operations are ordered to allow large sets of components to be reinit'd with a single API call. Not all components support a **restart**, in these cases, the API may issue an **off** and then **on** to those components.

The `xname_reinit` API will return after a power **restart** or **off-on** sequence is attempted to be sent to all of the selected components. The return payload should be examined as it may indicate components that did not receive the power request due to an error. The API may return immediately on an error containing a status result indicating any error encountered. The client must determine overall command status by calling the `get_xname_status` API after this call returns.

`xname_reinit` accepts **all** and **s0** as valid xnames indicating all components in the system.

An optional text message may be provided describing the reason for performing the `xname_reinit` operation.

> Body parameter

```json
{
  "reason": "Changing kernel",
  "xnames": [
    "x0c0s1b0n0",
    "x0c1s4b0n0",
    "x0c1s6b0n0",
    "x0c1rsb0n0"
  ],
  "force": true
}
```

<h3 id="post__xname_reinit-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|object|true|A JSON object to reinit selected components.|
|» reason|body|string|false|Reason for doing a component reinit.|
|» xnames|body|[string]|true|User specified list of component IDs (xnames) to reinit. An empty array is invalid. If invalid xnames are specified then an error will be returned.|
|» force|body|boolean|false|Attempt to restart components disabling any checks for a graceful restart.|

> Example responses

> 200 Response

```json
{
  "e": -1,
  "err_msg": "",
  "xnames": [
    {
      "e": -1,
      "err_msg": "NodeBMC communication error",
      "xname": "x0c0s1b0n0"
    },
    {
      "e": -1,
      "err_msg": "NodeBMC communication error",
      "xname": "x0c1s6b0n0"
    }
  ]
}
```

<h3 id="post__xname_reinit-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|[Bad Request](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.1)|[httpError400_BadRequest](#schemahttperror400_badrequest)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|[Method Not Allowed](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.6)|[httpError405_MethodNotAllowed](#schemahttperror405_methodnotallowed)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|[Internal Server Error](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.1)|[httpError500_InternalServerError](#schemahttperror500_internalservererror)|

<h3 id="post__xname_reinit-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» e|integer(int32)|true|none|Request status code, zero on success, non-zero on error.|
|» err_msg|string|true|none|Message indicating any error encountered.|
|» xnames|[object]|false|none|none|
|»» e|integer(int32)|true|none|Non-zero status code for failed request.|
|»» err_msg|string|true|none|Message indicating any error encountered.|
|»» xname|string|true|none|Component ID failing power restart attempt.|

<aside class="success">
This operation does not require authentication
</aside>

## post__xname_on

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_on HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_on \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_on', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_on", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /xname_on`

*Power on components*

The `xname_on` API powers **on** a selected list of components by xname. Power **on** operations are ordered to allow large sets of components to be powered on with a single API call.

The `xname_on` API will return after a power **on** request is attempted to be sent to all of the selected components. The return payload should be examined as it may indicate components that did not receive the power **on** request due to an error. The API may return immediately on an error containing a status result indicating the error encountered. The client must determine overall command status by calling the `get_xname_status` API after this call returns.

`xname_on` accepts **all** and **s0** as valid xnames indicating all components in the system.

An optional text message may be provided describing the reason for performing the `xname_on` operation.

> Body parameter

```json
{
  "reason": "Power on nodes to expand capacity",
  "xnames": [
    "x0c0s1b0n0",
    "x0c1s4b0n0",
    "x0c1s6b0n0",
    "x0c1rsb0n0"
  ],
  "force": true,
  "recursive": true
}
```

<h3 id="post__xname_on-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|object|true|A JSON object to power on selected components.|
|» reason|body|string|false|Reason for turning components on.|
|» xnames|body|[string]|true|User specified list of component IDs (xnames) to power on. An empty array is invalid. If invalid xnames are specified then an error will be returned. Available wildcards: all, s0.|
|» force|body|boolean|false|Attempt to power on components disabling any checks for a graceful power on.|
|» recursive|body|boolean|false|Attempt to power on the component hierarchy rooted by each component ID (xname). Incompatible with the prereq option.|
|» prereq|body|boolean|false|Attempt to power on the component IDs(xnames) and all of their ancestors. Incompatible with the recursive option.|
|» continue|body|boolean|false|Continue powering on valid component IDs (xnames) ignoring any component ID validation errors. Normally, a failure in validation ceases any attempt to power on any components.|

> Example responses

> 200 Response

```json
{
  "e": -1,
  "err_msg": "",
  "xnames": [
    {
      "e": -1,
      "err_msg": "NodeBMC communication error",
      "xname": "x0c0s1b0n0"
    },
    {
      "e": -1,
      "err_msg": "NodeBMC communication error",
      "xname": "x0c1s6b0n0"
    }
  ]
}
```

<h3 id="post__xname_on-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|[Bad Request](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.1)|[httpError400_BadRequest](#schemahttperror400_badrequest)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|[Method Not Allowed](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.6)|[httpError405_MethodNotAllowed](#schemahttperror405_methodnotallowed)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|[Internal Server Error](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.1)|[httpError500_InternalServerError](#schemahttperror500_internalservererror)|

<h3 id="post__xname_on-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» e|integer(int32)|true|none|Request status code, zero on success, non-zero on error.|
|» err_msg|string|true|none|Message indicating any error encountered.|
|» xnames|[object]|false|none|none|
|»» e|integer(int32)|true|none|Non-zero status code for failed request.|
|»» err_msg|string|true|none|Message indicating any error encountered.|
|»» xname|string|true|none|Component ID failing power up attempt.|

<aside class="success">
This operation does not require authentication
</aside>

## post__xname_off

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_off HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_off \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_off', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/capmc/capmc/v1/xname_off", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /xname_off`

*Power off components*

The `xname_off` API will shutdown and power **off** a selected list of components by xname. Power **off** operations are ordered to allow large sets of components to be powered off with a single API call.

The `xname_off` API will return after a power **off** request is attempted to be sent to all of the selected components. The return payload should be examined as it may indicate components that did not receive the power **off** request due to an error. The API may return immediately on an error containing a status result indicating the error encountered. The client must determine overall command status by calling the `get_xname_status` API after this call returns.

`xname_off` accepts as xnames **all** and **s0** indicating all components in the system.

An optional text message may be provided describing the reason for performing the `xname_off` operation.

> Body parameter

```json
{
  "reason": "Power save, need less capacity",
  "xnames": [
    "x0c0s1b0n0",
    "x0c1s4b0n0",
    "x0c1s6b0n0",
    "x0c1rsb0n0"
  ],
  "force": true,
  "recursive": true
}
```

<h3 id="post__xname_off-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|object|true|A JSON object to power off selected components.|
|» reason|body|string|false|Reason for turning components off.|
|» xnames|body|[string]|true|User specified list of component IDs (xnames) to shutdown and power off. An empty array is invalid. If invalid xnames are specified then an error will be returned. Available wildcards: all, s0.|
|» force|body|boolean|false|Attempt to power off components disabling any checks for a graceful power off.|
|» recursive|body|boolean|false|Attempt to power off the component hierarchy rooted by each component ID (xname). Incompatible with the prereq option.|
|» prereq|body|boolean|false|Attempt to power off the component and all of its ancestors by their component ID (xname). Incompatible with the recursive option.|
|» continue|body|boolean|false|Continue powering on valid component IDs (xnames) ignoring any component ID validation errors. Normally, a failure in validation ceases any attempt to power on any components.|

> Example responses

> 200 Response

```json
{
  "e": -1,
  "err_msg": "",
  "xnames": [
    {
      "e": -1,
      "err_msg": "NodeBMC communication error",
      "xname": "x0c0s1b0n0"
    },
    {
      "e": -1,
      "err_msg": "NodeBMC communication error",
      "xname": "x0c1s6b0n0"
    }
  ]
}
```

<h3 id="post__xname_off-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|[Bad Request](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.1)|[httpError400_BadRequest](#schemahttperror400_badrequest)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|[Method Not Allowed](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.6)|[httpError405_MethodNotAllowed](#schemahttperror405_methodnotallowed)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|[Internal Server Error](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.1)|[httpError500_InternalServerError](#schemahttperror500_internalservererror)|

<h3 id="post__xname_off-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» e|integer(int32)|true|none|Request status code, zero on success, non-zero on error.|
|» err_msg|string|true|none|Message indicating any error encountered.|
|» xnames|[object]|false|none|none|
|»» xname|string|true|none|Component ID failing power down attempt.|
|»» e|integer(int32)|true|none|Non-zero status code for failed request.|
|»» err_msg|string|true|none|Message indicating any error encountered.|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="cray-advanced-platform-monitoring-and-control-capmc--power-capping">power capping</h1>

## post__get_power_cap

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_power_cap HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_power_cap \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_power_cap', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_power_cap", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /get_power_cap`

*Return power capping controls*

The `get_power_cap` API returns the power capping control(s) and currently applied settings for the requested list of NIDs. Control values which are returned as zero indicates the respective control is unconstrained.

> Body parameter

```json
{
  "nids": [
    1,
    40,
    41,
    42,
    43
  ]
}
```

<h3 id="post__get_power_cap-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|object|true|A JSON object to get power capping controls of selected NIDs.|
|» nids|body|[integer]|true|User specified list, or empty array for all NIDs. This list must not contain invalid or duplicate NID numbers. If invalid NID numbers are specified then an error will be returned. If empty, the default is all NIDs. The specified NIDs must be in the `ready` state per the `get_node_status` command.|

> Example responses

> 200 Response

```json
{
  "e": 0,
  "err_msg": "",
  "nids": [
    {
      "nid": 40,
      "e": 0,
      "err_msg": "",
      "controls": [
        {
          "name": "node",
          "val": 350
        },
        {
          "name": "accel",
          "val": 375
        }
      ]
    },
    {
      "nid": 42,
      "e": 0,
      "err_msg": "",
      "controls": [
        {
          "name": "node",
          "val": 325
        },
        {
          "name": "accel",
          "val": 350
        }
      ]
    }
  ]
}
```

<h3 id="post__get_power_cap-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|[Internal Server Error](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.1)|[httpError500_InternalServerError](#schemahttperror500_internalservererror)|

<h3 id="post__get_power_cap-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» e|integer(int32)|true|none|Overall request status code, zero on total success, non-zero if one or more node specific operations fail.|
|» err_msg|string|true|none|Message indicating any error encountered.|
|» nids|[object]|true|none|Object array containing NID specific result data, each element represents a single NID.|
|»» nid|integer(int32)|true|none|NID number owning the returned control objects.|
|»» e|integer(int32)|false|none|Optional, error status, non-zero indicates operation failed on this node.|
|»» err_msg|string|false|none|Optional, message indicating any error encountered.|
|»» controls|[object]|false|none|Optional, array of node level control and status objects which have been queried, one element per control.|
|»»» name|string|true|none|Unique control or status object identifier.|
|»»» val|integer(int32)|true|none|Control object setting, or zero to indicate control is unconstrained, units are dependent upon control type.|

<aside class="success">
This operation does not require authentication
</aside>

## post__get_power_cap_capabilities

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_power_cap_capabilities HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_power_cap_capabilities \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_power_cap_capabilities', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_power_cap_capabilities", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /get_power_cap_capabilities`

*Return power cap capabilities*

The `get_power_cap_capabilities` API returns information about installed hardware and its associated properties. Information returned includes the specific hardware types, NID membership, and power capping controls along with their allowable ranges. Information may be returned for a selected set of NIDs or the system as a whole.

> Body parameter

```json
{
  "nids": [
    40,
    41,
    42,
    43
  ]
}
```

<h3 id="post__get_power_cap_capabilities-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|object|true|A JSON object to get power capping capabilities of selected NIDs.|
|» nids|body|[integer]|true|User specified list, or empty array for all NIDs. This list must not contain invalid or duplicate NID numbers. If invalid NID numbers are specified, then an error will be returned.|

> Example responses

> 200 Response

```json
{
  "e": 0,
  "err_msg": "",
  "groups": [
    {
      "name": "01:000d:306e:0082:000a:0020:3a34:8300",
      "desc": "ComputeANC_IVB_130W_10c_32GB_14900_IntelKNCAccel",
      "supply": 425,
      "host_limit_min": 100,
      "host_limit_max": 200,
      "static": 0,
      "powerup": 120,
      "nids": [
        40,
        41
      ],
      "controls": [
        {
          "name": "accel",
          "desc": "Accelerator control",
          "min": 220,
          "max": 260
        },
        {
          "name": "node",
          "desc": "Node manager control",
          "min": 320,
          "max": 460
        }
      ]
    },
    {
      "name": "01:000d:306e:00e6:0014:0040:3a34:0000",
      "desc": "ComputeANC_IVB_230W_20c_64GB_14900_NoAccel",
      "supply": 425,
      "host_limit_min": 200,
      "host_limit_max": 350,
      "static": 0,
      "powerup": 150,
      "nids": [
        42,
        43
      ],
      "controls": [
        {
          "name": "node",
          "desc": "Node manager control",
          "min": 320,
          "max": 460
        }
      ]
    }
  ]
}
```

<h3 id="post__get_power_cap_capabilities-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|[Internal Server Error](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.1)|[httpError500_InternalServerError](#schemahttperror500_internalservererror)|

<h3 id="post__get_power_cap_capabilities-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» e|integer(int32)|true|none|Request status code, zero on success.|
|» err_msg|string|true|none|Message indicating any error encountered.|
|» groups|[object]|true|none|Object array containing hardware specific information and NID membership, each element represent a unique hardware type.|
|»» name|string|true|none|Opaque identifier which Cray System Management Software uses to uniquely identify a node type.|
|»» desc|string|true|none|Text description of the opaque node type identifier.|
|»» host_limit_max|integer(int32)|true|none|Estimated maximum power, specified in watts, which host CPU(s) and memory may consume.|
|»» host_limit_min|integer(int32)|true|none|Estimated minimum power, specified in watts, which host CPU(s) and memory require to operate.|
|»» static|integer(int32)|true|none|Static per node power overhead, specified in watts, which is unreported.|
|»» supply|integer(int32)|true|none|Maximum capacity of each node level power supply for the given hardware type, specified in watts.|
|»» powerup|integer(int32)|true|none|Typical power consumption of each node during hardware initialization, specified in watts.|
|»» nids|[integer]|true|none|NID members belonging to the given hardware type.|
|»» controls|[object]|true|none|Array of node level control objects which may be assigned or queried, one element per control.|
|»»» name|string|true|none|Unique control object identifier.|
|»»» desc|string|true|none|Message indicating any error encountered.|
|»»» min|integer(int32)|true|none|Minimum value which may be assigned to the control object, units are dependent upon control type.|
|»»» max|integer(int32)|true|none|Maximum value which may be assigned to the control object, units are dependent upon control type.|

<aside class="success">
This operation does not require authentication
</aside>

## post__set_power_cap

> Code samples

```http
POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/set_power_cap HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://api-gw-service-nmn.local/apis/capmc/capmc/v1/set_power_cap \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://api-gw-service-nmn.local/apis/capmc/capmc/v1/set_power_cap', headers = headers)

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
    req, err := http.NewRequest("POST", "http://api-gw-service-nmn.local/apis/capmc/capmc/v1/set_power_cap", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /set_power_cap`

*Set power capping parameters*

The `set_power_cap` API is used to establish an upper bound with respect to power consumption on a per-node, and if applicable, a sub-node basis. Established power cap parameters will revert to the default configuration on the next system boot.

> Body parameter

```json
{
  "nids": [
    {
      "nid": 40,
      "controls": [
        {
          "name": "node",
          "val": 410
        },
        {
          "name": "accel",
          "val": 220
        }
      ]
    },
    {
      "nid": 42,
      "controls": [
        {
          "name": "node",
          "val": 400
        }
      ]
    }
  ]
}
```

<h3 id="post__set_power_cap-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|object|true|A JSON object to set power capping parameters of selected NIDs.|
|» nids|body|[object]|true|Object array containing NID specific input data, each element represents a single NID.|
|»» nid|body|integer(int32)|true|NID to apply the specified power caps. The specified NID must be in the **ready** state per the `get_node_status` command.|
|»» controls|body|[object]|true|Array of node level control objects to be adjusted, one element per control.|
|»»» name|body|string|true|Specifies a node or accelerator as the type to apply a power cap to.|
|»»» val|body|integer(int32)|true|Power cap value to assign to the selected component type. The value given must be within the range returned in the capabilities output. A Value of zero may be supplied to explicitly clear an existing power cap.|

#### Detailed descriptions

**»» controls**: Array of node level control objects to be adjusted, one element per control.
Nodes with a high powered accelerators and high TDP processors will be automatically power capped at the **supply** limit returned per the `get_power_cap_capabilities` command. If a node level power cap is specified that is within the node control range but exceeds the supply limit, the actual power cap assigned will be clamped at the supply limit.
The accelerator power cap value represents a subset of the total node level power cap. If a node level power cap of 400 watts is applied and an accelerator power cap of 180 watts is applied, then the total node power consumption is limited to 400 watts. If the accelerator is actively consuming its entire 180 watt power allocation, then the host processor, memory subsystem, and support logic for that node may consume a maximum of 220 watts.

> Example responses

> 200 Response

```json
{
  "e": 0,
  "err_msg": "",
  "nids": [
    {
      "nid": 40,
      "e": 0,
      "err_msg": ""
    },
    {
      "nid": 42,
      "e": 0,
      "err_msg": ""
    }
  ]
}
```

<h3 id="post__set_power_cap-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|[Internal Server Error](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.1)|[httpError500_InternalServerError](#schemahttperror500_internalservererror)|

<h3 id="post__set_power_cap-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» e|integer(int32)|true|none|Request status code, zero on success.|
|» err_msg|string|true|none|Message indicating any error encountered.|
|» nids|[object]|true|none|Object array containing NID specific error data, NIDs which experienced success are omitted.|
|»» nid|integer(int32)|true|none|NID number owning the returned error data.|
|»» e|integer(int32)|true|none|Error status, non-zero indicates operation failed on this node.|
|»» err_msg|string|true|none|Message indicating any error encountered.|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="cray-advanced-platform-monitoring-and-control-capmc--utilities">utilities</h1>

## get__health

> Code samples

```http
GET http://api-gw-service-nmn.local/apis/capmc/capmc/v1/health HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://api-gw-service-nmn.local/apis/capmc/capmc/v1/health \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://api-gw-service-nmn.local/apis/capmc/capmc/v1/health', headers = headers)

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
    req, err := http.NewRequest("GET", "http://api-gw-service-nmn.local/apis/capmc/capmc/v1/health", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /health`

*Query the health of the service*

The `health` API returns health information about the CAPMC service and its dependencies.  This actively checks the connection between  CAPMC and the following:

  * Credentials vault
  * Hardware State Manager
  * Power telemetry database

Different portions of the CAPMC interface are dependent on combinations of the above services.  If one or more of these services are unavailable, portions of the CAPMC interface will be unavailable.
This is primarily intended as a diagnostic tool to investigate the functioning of the CAPMC service.

> Example responses

> 200 Response

```json
{
  "readiness": "Service Degraded",
  "vault": "No connection established to vault",
  "hsm": "HSM Ready"
}
```

<h3 id="get__health-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|Inline|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|[Method Not Allowed](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.6)|[httpError405_MethodNotAllowed](#schemahttperror405_methodnotallowed)|

<h3 id="get__health-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» readiness|string|true|none|General state of the service - may be Ready, Service Degraded, or Not Ready.|
|» vault|string|true|none|Description of the connection to the credentials vault.  If there is an error returned when attempting to access the vault that will be included here.|
|» hsm|string|true|none|Status of the connection to the Hardware State Manager (HSM).  Any error reported by an attempt to access the HSM will be included in this description.|

<aside class="success">
This operation does not require authentication
</aside>

## get__liveness

> Code samples

```http
GET http://api-gw-service-nmn.local/apis/capmc/capmc/v1/liveness HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://api-gw-service-nmn.local/apis/capmc/capmc/v1/liveness \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://api-gw-service-nmn.local/apis/capmc/capmc/v1/liveness', headers = headers)

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
    req, err := http.NewRequest("GET", "http://api-gw-service-nmn.local/apis/capmc/capmc/v1/liveness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /liveness`

*Kubernetes liveness endpoint to monitor service health*

The `liveness` API works in conjunction with the Kubernetes liveness probe to determine when the service is no longer responding to requests.  Too many failures of the liveness probe will result in the service being shut down and restarted.  

This is primarily an endpoint for the automated Kubernetes system.

> Example responses

> 405 Response

```json
{
  "e": 405,
  "err_msg": "(PATCH) Not Allowed"
}
```

<h3 id="get__liveness-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|[Method Not Allowed](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.6)|[httpError405_MethodNotAllowed](#schemahttperror405_methodnotallowed)|

<aside class="success">
This operation does not require authentication
</aside>

## get__readiness

> Code samples

```http
GET http://api-gw-service-nmn.local/apis/capmc/capmc/v1/readiness HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://api-gw-service-nmn.local/apis/capmc/capmc/v1/readiness \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://api-gw-service-nmn.local/apis/capmc/capmc/v1/readiness', headers = headers)

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
    req, err := http.NewRequest("GET", "http://api-gw-service-nmn.local/apis/capmc/capmc/v1/readiness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /readiness`

*Kubernetes readiness endpoint to monitor service health*

The `readiness` API works in conjunction with the Kubernetes readiness probe to determine when the service is no longer healthy and able to respond correctly to requests.  Too many failures of the readiness probe will result in the traffic being routed away from this service and eventually the service will be shut down and restarted if in an unready state for too long.

This is primarily an endpoint for the automated Kubernetes system.

> Example responses

> 405 Response

```json
{
  "e": 405,
  "err_msg": "(PATCH) Not Allowed"
}
```

<h3 id="get__readiness-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|[Method Not Allowed](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.6)|[httpError405_MethodNotAllowed](#schemahttperror405_methodnotallowed)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_httpError400_BadRequest">httpError400_BadRequest</h2>
<!-- backwards compatibility -->
<a id="schemahttperror400_badrequest"></a>
<a id="schema_httpError400_BadRequest"></a>
<a id="tocShttperror400_badrequest"></a>
<a id="tocshttperror400_badrequest"></a>

```json
{
  "e": 400,
  "err_msg": "Bad Request: invalid URL escape"
}

```

CAPMC Bad Request error payload

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|e|integer(int32)|false|none|Error status code.|
|err_msg|string|false|none|Message indicating any error encountered.|

<h2 id="tocS_httpError405_MethodNotAllowed">httpError405_MethodNotAllowed</h2>
<!-- backwards compatibility -->
<a id="schemahttperror405_methodnotallowed"></a>
<a id="schema_httpError405_MethodNotAllowed"></a>
<a id="tocShttperror405_methodnotallowed"></a>
<a id="tocshttperror405_methodnotallowed"></a>

```json
{
  "e": 405,
  "err_msg": "(PATCH) Not Allowed"
}

```

CAPMC Method Not Allowed error payload

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|e|integer(int32)|false|none|Error status code.|
|err_msg|string|false|none|Message indicating any error encountered.|

<h2 id="tocS_httpError500_InternalServerError">httpError500_InternalServerError</h2>
<!-- backwards compatibility -->
<a id="schemahttperror500_internalservererror"></a>
<a id="schema_httpError500_InternalServerError"></a>
<a id="tocShttperror500_internalservererror"></a>
<a id="tocshttperror500_internalservererror"></a>

```json
{
  "e": 500,
  "err_msg": "Connection to the secure store isn't ready. Cannot get Redfish credentials."
}

```

CAPMC Internal Server Error error payload

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|e|integer(int32)|false|none|Error status code.|
|err_msg|string|false|none|Message indicating any error encountered.|

