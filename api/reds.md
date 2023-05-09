<!-- Generator: Widdershins v4.0.1 -->

<h1 id="river-endpoint-discovery-service">River Endpoint Discovery Service v2</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The River Endpoint Discovery Service (REDS) manages the endpoint discovery, configuration and geolocation of Redfish-enabled BMCs on River compute nodes. It does so through a combination of methods: watching switches for new MAC addresses via SNMP and booting a "discovery ramdisk".
This API assumes that you have a general familiarity with SNMP, IPMI, and Redfish protocols and the operation of network switches.
REDS involves the following tasks:
* **Endpoint discovery**: This process determines that a new Redfish Endpoint (IPMI-capable BMC) is available on the network. 
* **Configuration**: This process sets the minimum information for the node being discovered so that it can interact with the rest of the system. This typically consists of information such as credentials.
* **Geolocation**: This process assigns a location-based identity to the node (typically based on the network wiring). It assigns an xname to the node based on its physical location and adds the node to the Hardware State Manager (HSM) service.

The SNMP scanning performs the discovery and geolocation components. SNMP scanning allows the service to observe when a new River compute node is attached to the network. It also detects which port on which switch the new hardware is attached to. This is correlated with a pre-built map of the system to determine the logical name (xname) that should be associated with the newly detected BMC.

When the new node first powers on, it is unknown to the rest of the system and boots to the discovery ramdisk. The discovery ramdisk handles bootstrapping the BMC with the correct username, password and other configuration. It does not assign an IP to the node, as the logical identity (xname) is not known. It does, however, collect the IP in use, meaning assignment could be carried out via DHCP or other similar mechanism.

## Workflows
### Add River Compute Nodes
SLS is now used to add components. See "Expand System" in the SLS documentation.
### Remove River Compute Nodes
SLS is now used to remove components. See "Remove Hardware" in the SLS documentation.

Base URLs:

* <a href="https://sms/apis/reds/v1">https://sms/apis/reds/v1</a>

 License: MIT

<h1 id="river-endpoint-discovery-service-service-info">Service Info</h1>

Service information APIs such as readiness and liveness.

## readiness_get

<a id="opIdreadiness_get"></a>

> Code samples

```http
GET https://sms/apis/reds/v1/readiness HTTP/1.1
Host: sms

```

```shell
# You can also use wget
curl -X GET https://sms/apis/reds/v1/readiness

```

```python
import requests

r = requests.get('https://sms/apis/reds/v1/readiness')

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
    req, err := http.NewRequest("GET", "https://sms/apis/reds/v1/readiness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /readiness`

*Kubernetes readiness endpoint to monitor service health*

The `readiness` resource works in conjunction with the Kubernetes readiness probe to determine when the service is no longer healthy and able to respond correctly to requests.  Too many failures of the readiness probe will result in the traffic being routed away from this service and eventually the service will be shut down and restarted if in an unready state for too long.

This is primarily an endpoint for the automated Kubernetes system.

<h3 id="readiness_get-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|The service is unhealthy and not ready.|None|
|default|Default|Unexpected error.|None|

<aside class="success">
This operation does not require authentication
</aside>

## liveness_get

<a id="opIdliveness_get"></a>

> Code samples

```http
GET https://sms/apis/reds/v1/liveness HTTP/1.1
Host: sms

```

```shell
# You can also use wget
curl -X GET https://sms/apis/reds/v1/liveness

```

```python
import requests

r = requests.get('https://sms/apis/reds/v1/liveness')

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
    req, err := http.NewRequest("GET", "https://sms/apis/reds/v1/liveness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /liveness`

*Kubernetes liveness endpoint to monitor service health*

The `liveness` resource works in conjunction with the Kubernetes liveness probe to determine when the service is no longer responding to requests.  Too many failures of the liveness probe will result in the service being shut down and restarted.

This is primarily an endpoint for the automated Kubernetes system.

<h3 id="liveness_get-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|default|Default|Unexpected error.|None|

<aside class="success">
This operation does not require authentication
</aside>

