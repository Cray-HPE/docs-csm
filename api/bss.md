<!-- Generator: Widdershins v4.0.1 -->

<h1 id="boot-script-service">Boot Script Service v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

Boot Script Service (BSS) manages the iPXE boot scripts that coordinate the boot process for nodes, and enables basic association of boot scripts with nodes. When nodes initially power on, boot, or reboot, they consult BSS for their target artifacts and boot parameters. The boot scripts are generated on demand from the information that is entered and delivered to the requester during an iPXE boot. The boot scripts supply a booting node with a pointer to the necessary images (kernel and initrd) that are stored in the artifact repository and a set of boot-time parameters.
The BSS API allows the caller to retrieve an iPXE boot script from the boot script server, and to set, update, delete, and retrieve boot script parameters for each host in a system. BSS works with all nodes that are known to HSM and do not have the hardware role as Management in HSM.
## Resources
### /boot/v1/bootscript
Retrieve the iPXE boot script for a host. One of the three parameters is required - name, MAC, or NID.
### /boot/v1/bootparameters
Set, update, delete, and retrieve boot script parameters for specific hosts.
### /boot/v1/hosts
Retrieve the latest host information like state, NID, and ID from HSM.
### /boot/v1/dumpstate
Dump internal state of boot script service for debugging purposes.
## Workflows
### Define Boot Parameters for all Nodes
#### POST /boot/v1/bootparameters
Define boot parameters. Specify the host as Default. While BSS allows for fine grained control of individual nodes, the Default tag is typically more convenient, especially for a large system.

Along with the host, the kernel, initrd, and params should be defined. The kernel is required for BSS to generate a boot script, but initrd and params are typically needed for the node to boot successfully. The kernel and initrd fields contain a URL to the respective images. The params field is a string that will be passed to the kernel during the boot process.
#### GET /boot/v1/bootscript
Verify the boot script to ensure it's what you want
### Update Boot Parameters
#### GET /boot/v1/hosts
Retrieve list of hosts known to HSM and select the host for which the boot parameters need to be changed.
#### GET /boot/v1/bootparameters
Retrieve the boot parameters for the specific host.
#### PUT /boot/v1/bootparameters
Update boot parameters for the host.
#### GET /boot/v1/bootparameters
Verify the boot parameters for the specific host.

Base URLs:

* <a href="http://bootscriptserver:27778/apis/bss">http://bootscriptserver:27778/apis/bss</a>

<h1 id="boot-script-service-cli_ignore">cli_ignore</h1>

## meta_data_get

<a id="opIdmeta_data_get"></a>

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/meta-data HTTP/1.1
Host: bootscriptserver:27778
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/meta-data \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/meta-data', headers = headers)

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
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/meta-data", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /meta-data`

*Retrieve cloud-init meta-data*

<h3 id="meta_data_get-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|key|query|string|false|Specific sub key(s) to query. Separated by periods.|

> Example responses

> 200 Response

```json
{}
```

<h3 id="meta_data_get-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|meta-data for node|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Either the host, MAC or NID are unknown and there is no Default, or the existing entry does not specify a kernel image for boot.|[Error](#schemaerror)|
|default|Default|Unexpected error|[Error](#schemaerror)|

<h3 id="meta_data_get-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

## user_data_get

<a id="opIduser_data_get"></a>

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/user-data HTTP/1.1
Host: bootscriptserver:27778
Accept: text/yaml

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/user-data \
  -H 'Accept: text/yaml'

```

```python
import requests
headers = {
  'Accept': 'text/yaml'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/user-data', headers = headers)

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
        "Accept": []string{"text/yaml"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/user-data", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /user-data`

*Retrieve cloud-init user-data*

> Example responses

> 200 Response

<h3 id="user_data_get-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|user-data for node|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Either the host, MAC or NID are unknown and there is no Default, or the existing entry does not specify a kernel image for boot.|[Error](#schemaerror)|
|default|Default|Unexpected error|[Error](#schemaerror)|

<h3 id="user_data_get-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

## phone_home_post

<a id="opIdphone_home_post"></a>

> Code samples

```http
POST http://bootscriptserver:27778/apis/bss/phone-home HTTP/1.1
Host: bootscriptserver:27778
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://bootscriptserver:27778/apis/bss/phone-home \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://bootscriptserver:27778/apis/bss/phone-home', headers = headers)

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
    req, err := http.NewRequest("POST", "http://bootscriptserver:27778/apis/bss/phone-home", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /phone-home`

*Post cloud-init*

> Body parameter

```json
{
  "pub_key_dsa": "string",
  "pub_key_rsa": "string",
  "pub_key_ecdsa": "string",
  "pub_key_ed25519": "string",
  "instance_id": "string",
  "hostname": "string",
  "fqdn": "string"
}
```

<h3 id="phone_home_post-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[CloudInitPhoneHome](#schemacloudinitphonehome)|false|none|

> Example responses

> 200 Response

```json
{
  "hosts": [
    "x0c0s2b0n0",
    "x0c0s3b0n0"
  ],
  "macs": [
    "00:40:a6:82:f6:c5",
    "a4:bf:01:3e:c0:a2",
    "00:40:a6:82:f7:0c"
  ],
  "nids": [
    1,
    2,
    3,
    4
  ],
  "params": "console=tty0 console=ttyS0,115200n8 initrd=initrd-4.12.14-15.5_8.1.96-cray_shasta_c root=crayfs nfsserver=10.2.0.1nfspath=/var/opt/cray/boot_images imagename=/SLES selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M htburl=https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/heartbeat bad_page=panic hugepagelist=2m-2g intel_iommu=off iommu=pt numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet turbo_boost_limit=999",
  "kernel": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/kernel",
  "initrd": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/initrd",
  "cloud-init": {
    "user-data": {
      "foo": "bar"
    },
    "meta-data": {
      "foo": "bar"
    }
  }
}
```

<h3 id="phone_home_post-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Meta data for node|[BootParams](#schemabootparams)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Either the host, MAC or NID are unknown and there is no Default, or the existing entry does not specify a kernel image for boot.|[Error](#schemaerror)|
|default|Default|Unexpected error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-script-service-bootscript">bootscript</h1>

## bootscript_get

<a id="opIdbootscript_get"></a>

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/boot/v1/bootscript HTTP/1.1
Host: bootscriptserver:27778
Accept: text/plain

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/boot/v1/bootscript \
  -H 'Accept: text/plain'

```

```python
import requests
headers = {
  'Accept': 'text/plain'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/boot/v1/bootscript', headers = headers)

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
        "Accept": []string{"text/plain"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/boot/v1/bootscript", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /boot/v1/bootscript`

*Retrieve iPXE boot script*

Retrieve iPXE boot script for the host specified by the MAC parameter. Alternatively, for test/convenience purposes, use the name or the NID parameter to specify the host name or xname. Do not specify more than one parameter (MAC, name, or NID) in the request as results are undefined if they do not all refer to the same node.

<h3 id="bootscript_get-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|mac|query|string|false|MAC address of host requesting boot script|
|name|query|string|false|Name of host requesting boot script or xname|
|nid|query|integer|false|Node ID (NID) of host requesting boot script|
|retry|query|integer|false|Number of times requesting script without a successful boot. This parameter is mostly used by the software itself to keep track of retries.|
|arch|query|string|false|The architecture value from the iPXE variable ${buildarch}. This parameter is mostly used by the software itself.|
|ts|query|integer|false|Timestamp for when the HSM state info needs to be up to date by.  This is the Unix concept of time, the number of seconds since Jan 1, 1970 UTC. This parameter is mostly used by the software itself.|

> Example responses

> 200 Response

```
"#!ipxe\nkernel --name kernel http://rgw-vip.nmn/boot-images/00000000-0000-0000-0000-000000000000/kernel initrd=initrd console=ttyS0,115200 bad_page=panic crashkernel=512M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu.passthrough=on numa_interleave_omit=headless oops=panic pageblock_order=14 rd.neednet=1 rd.retry=10 rd.shell systemd.unified_cgroup_hierarchy=1 ip=dhcp quiet spire_join_token=00000000-0000-0000-0000-000000000000 root=craycps-s3:s3://boot-images/00000000-0000-0000-0000-000000000000/rootfs:00000000000000000000000000000000-000:dvs:api-gw-service-nmn.local:300:hsn0,nmn0:0 nmd_data=url=s3://boot-images/00000000-0000-0000-0000-000000000000/rootfs bos_session_id=000000-0000-0000-0000-000000000000 xname=x3000c0s17b3n0 nid=3 bss_referral_token=00000000-0000-0000-0000-000000000000 ds=nocloud-net;s=http://10.92.100.81:8888/ || goto boot_retry\ninitrd --name initrd http://rgw-vip.nmn/boot-images/00000000-0000-0000-0000-000000000000/initrd || goto boot_retry\nboot || goto boot_retry\n:boot_retry\nsleep 30\nchain https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?mac=b4:2e:99:df:eb:bf&retry=1\n"
```

<h3 id="bootscript_get-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Boot script for requested MAC address|string|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Either the host, MAC, or NID are unknown and there is no Default, or the existing entry does not specify a kernel image for boot.|[Error](#schemaerror)|
|default|Default|Unexpected error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-script-service-bootparameters">bootparameters</h1>

## get__boot_v1_bootparameters

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters HTTP/1.1
Host: bootscriptserver:27778
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters', headers = headers)

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
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /boot/v1/bootparameters`

*Retrieve boot parameters*

Retrieve the boot parameters for one or more hosts. If no parameters are provided, then all known parameters are returned. Filtering can be accomplished by either providing a body of the boot parameters or one of the three query parameters: host names, MAC addresses, and/or NIDs. The body of boot parameters can also provide a kernel or initrd path which will be returned along with any bootparameter settings as well. Alternatively, query parameters name=, mac=, and/or nid= can provide the filtering of individual items or comma-separated lists of items. The response is a list of boot parameter items. These items will include the individual kernel and initrd images, along with any related boot parameters. If filtering parameters are provided, each parameter will provide a result if one exists. Note that the kernel and initrd images are specified with a URL or path. A plain path will result in a TFTP download from this server. If a URL is provided, it can be from any available service which iPXE supports, and any location that the iPXE client has access to.

> Body parameter

```json
{
  "hosts": [
    "x0c0s2b0n0",
    "x0c0s3b0n0"
  ],
  "macs": [
    "00:40:a6:82:f6:c5",
    "a4:bf:01:3e:c0:a2",
    "00:40:a6:82:f7:0c"
  ],
  "nids": [
    1,
    2,
    3,
    4
  ],
  "params": "console=tty0 console=ttyS0,115200n8 initrd=initrd-4.12.14-15.5_8.1.96-cray_shasta_c root=crayfs nfsserver=10.2.0.1nfspath=/var/opt/cray/boot_images imagename=/SLES selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M htburl=https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/heartbeat bad_page=panic hugepagelist=2m-2g intel_iommu=off iommu=pt numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet turbo_boost_limit=999",
  "kernel": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/kernel",
  "initrd": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/initrd",
  "cloud-init": {
    "user-data": {
      "foo": "bar"
    },
    "meta-data": {
      "foo": "bar"
    }
  }
}
```

<h3 id="get__boot_v1_bootparameters-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|name|query|string|false|Host name or tag name of boot parameters to return|
|mac|query|string|false|MAC Address of host of boot parameters to return|
|nid|query|integer|false|NID of host of boot parameters to return|
|body|body|[BootParams](#schemabootparams)|false|none|

> Example responses

> 200 Response

```json
[
  {
    "hosts": [
      "x0c0s2b0n0",
      "x0c0s3b0n0"
    ],
    "macs": [
      "00:40:a6:82:f6:c5",
      "a4:bf:01:3e:c0:a2",
      "00:40:a6:82:f7:0c"
    ],
    "nids": [
      1,
      2,
      3,
      4
    ],
    "params": "console=tty0 console=ttyS0,115200n8 initrd=initrd-4.12.14-15.5_8.1.96-cray_shasta_c root=crayfs nfsserver=10.2.0.1nfspath=/var/opt/cray/boot_images imagename=/SLES selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M htburl=https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/heartbeat bad_page=panic hugepagelist=2m-2g intel_iommu=off iommu=pt numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet turbo_boost_limit=999",
    "kernel": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/kernel",
    "initrd": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/initrd",
    "cloud-init": {
      "user-data": {
        "foo": "bar"
      },
      "meta-data": {
        "foo": "bar"
      }
    }
  }
]
```

<h3 id="get__boot_v1_bootparameters-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|List of currently known boot parameters|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request - BootParams value incorrect|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Cannot find host, MAC, or NID|[Error](#schemaerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Error](#schemaerror)|
|default|Default|Unexpected error|[Error](#schemaerror)|

<h3 id="get__boot_v1_bootparameters-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[BootParams](#schemabootparams)]|false|none|[When used as a request body, the caller sets boot parameters and specifies hosts, along with the kernel image path/URL and initrd path/URL. To specify hosts, use one of the three parameters - hosts, MACs, or NIDs. If MAC addresses are used, they are mapped to host names based on information retrieved from the hardware state manager.  Likewise, if NIDs are used, they are mapped to host names with the same hardware state manager info.  While the expected usage is to specify hosts based on their host names, the "macs" and "nids" alternatives may be more convenient in some contexts.<br>You can also specify a general tag for hosts. A tag is 'Default', or one of the roles that a node may be defined as in the hardware state manager (HSM). Some of the HSM roles like 'Compute', 'Storage', 'System', and 'Application' can be specified as hosts and are managed similar to specific hosts. While BSS allows for fine grained control of individual nodes, the tags are typically more convenient, especially for a large system.<br><br>Alternatively, if you specify a kernel or initrd image and params, but no host, MAC, or NID, the boot script service will associate the specified params with the specified kernel or initrd image. When used as a response body, identifies the hosts available for booting using either hosts, MACs, or NIDs, depending on which parameter was used in the request.]|
|» hosts|[string]|false|none|host names|
|» macs|[string]|false|none|MAC addresses|
|» nids|[integer]|false|none|Node ID|
|» params|string|false|none|Specific to the kernel that is being booted.|
|» kernel|string|false|none|URL or file system path specifying kernel image.|
|» initrd|string|false|none|URL or file system path specifying initrd image.|
|» cloud-init|[CloudInit](#schemacloudinit)|false|none|Cloud-Init data for the hosts|
|»» meta-data|[CloudInitMetadata](#schemacloudinitmetadata)|false|none|Cloud-Init Instance Metadata for a host.|
|»» user-data|[CloudInitUserData](#schemacloudinituserdata)|false|none|Cloud-Init User data for a host.|
|»» phone-home|[CloudInitPhoneHome](#schemacloudinitphonehome)|false|none|Data sent from the Phone Home Cloud-Init module after a host's boot is complete.|
|»»» pub_key_dsa|string|false|none|none|
|»»» pub_key_rsa|string|false|none|none|
|»»» pub_key_ecdsa|string|false|none|none|
|»»» pub_key_ed25519|string|false|none|none|
|»»» instance_id|string|false|none|none|
|»»» hostname|string|false|none|none|
|»»» fqdn|string|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## post__boot_v1_bootparameters

> Code samples

```http
POST http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters HTTP/1.1
Host: bootscriptserver:27778
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters', headers = headers)

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
    req, err := http.NewRequest("POST", "http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /boot/v1/bootparameters`

*Create boot parameters*

Define boot parameters. Specify a list of one of the following parameters: hosts, MACs, or NIDs along with the boot parameters to associate with those hosts. You can either use specific hosts or specify a general tag for hosts. Specific hosts can be specified either by a hostname (xname), a NID, or a MAC address. It is recommended to use the xname. Otherwise, a tag can be used for the hosts parameter. A tag is "Default", or one of the roles that a node may be defined as in the hardware state manager (HSM). Some of the HSM roles like 'Compute', 'Storage', 'System', and 'Application' can be specified as hosts and are managed similar to specific hosts. While BSS allows for fine grained control of individual nodes, the tags are typically more convenient, especially for a large system.

Along with the hosts, there must be a kernel image reference in order for the boot script service to be able to generate a boot script. In most cases, there should also be an initrd image reference, unless the kernel being booted is standalone and does not require an initrd image. Finally, the params entry can be used to specify boot parameters for the specified hosts.
Note that if there is no existing params entry for a host, a new entry for the host is created. If an entry already exists for the host, this request will fail.

Special entries for HSM roles like 'Compute', 'Storage' and 'Application' can also be specified as hosts, and are managed similar to specific hosts. If an error occurs during the save/update, processing will stop after the first error. Subsequent hosts in the list will not be processed.

> Body parameter

```json
{
  "hosts": [
    "x0c0s2b0n0",
    "x0c0s3b0n0"
  ],
  "macs": [
    "00:40:a6:82:f6:c5",
    "a4:bf:01:3e:c0:a2",
    "00:40:a6:82:f7:0c"
  ],
  "nids": [
    1,
    2,
    3,
    4
  ],
  "params": "console=tty0 console=ttyS0,115200n8 initrd=initrd-4.12.14-15.5_8.1.96-cray_shasta_c root=crayfs nfsserver=10.2.0.1nfspath=/var/opt/cray/boot_images imagename=/SLES selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M htburl=https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/heartbeat bad_page=panic hugepagelist=2m-2g intel_iommu=off iommu=pt numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet turbo_boost_limit=999",
  "kernel": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/kernel",
  "initrd": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/initrd",
  "cloud-init": {
    "user-data": {
      "foo": "bar"
    },
    "meta-data": {
      "foo": "bar"
    }
  }
}
```

<h3 id="post__boot_v1_bootparameters-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[BootParams](#schemabootparams)|false|none|

> Example responses

> 400 Response

```json
{
  "type": "string",
  "title": "string",
  "status": 0,
  "detail": "string",
  "instance": "string"
}
```

<h3 id="post__boot_v1_bootparameters-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|successfully created boot parameters|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request - Invalid BootParams value|[Error](#schemaerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Error](#schemaerror)|
|default|Default|Unexpected error|[Error](#schemaerror)|

### Response Headers

|Status|Header|Type|Format|Description|
|---|---|---|---|---|
|201|BSS-Referral-Token|string||The UUID that will be included in the boot script. A new UUID is generated on each POST and PUT request.|

<aside class="success">
This operation does not require authentication
</aside>

## put__boot_v1_bootparameters

> Code samples

```http
PUT http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters HTTP/1.1
Host: bootscriptserver:27778
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters', headers = headers)

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
    req, err := http.NewRequest("PUT", "http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /boot/v1/bootparameters`

*Set boot parameters*

Set or update boot parameters for one or more hosts. Specify a list of one of the following parameters: hosts, MACs, or NIDs along with the boot parameters to associate with those hosts.

You can either use specific hosts or specify a general tag for hosts. Specific hosts can be specified either by a hostname (xname), a NID, or a MAC address. It is recommended to use the xname. Otherwise, a tag can be used for the hosts parameter. A tag is "Default", or one of the roles that a node may be defined as in the hardware state manager (HSM). Some of the HSM roles like 'Compute', 'Storage', 'System', and 'Application' can be specified as hosts and are managed similar to specific hosts. While BSS allows for fine grained control of individual nodes, the tags are typically more convenient, especially for a large system.

Along with the hosts, there must be a kernel image reference in order for the boot script service to be able to generate a boot script. In most cases, there should also be an initrd image reference, unless the kernel being booted is standalone and does not require an initrd image. Finally, the params entry can be used to specify boot parameters specific to the specified hosts. If there are no boot params stored for one or more hosts, then a new entry for that host will be created. For kernel, initrd and params values, an existing value will be replaced. The params value is a replacement of the existing values. If the params value does not specify one or more values, any existing values are removed. If an error occurs during the save/update, processing will stop after the first error.  Subsequent hosts in the list will not be processed.

> Body parameter

```json
{
  "hosts": [
    "x0c0s2b0n0",
    "x0c0s3b0n0"
  ],
  "macs": [
    "00:40:a6:82:f6:c5",
    "a4:bf:01:3e:c0:a2",
    "00:40:a6:82:f7:0c"
  ],
  "nids": [
    1,
    2,
    3,
    4
  ],
  "params": "console=tty0 console=ttyS0,115200n8 initrd=initrd-4.12.14-15.5_8.1.96-cray_shasta_c root=crayfs nfsserver=10.2.0.1nfspath=/var/opt/cray/boot_images imagename=/SLES selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M htburl=https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/heartbeat bad_page=panic hugepagelist=2m-2g intel_iommu=off iommu=pt numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet turbo_boost_limit=999",
  "kernel": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/kernel",
  "initrd": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/initrd",
  "cloud-init": {
    "user-data": {
      "foo": "bar"
    },
    "meta-data": {
      "foo": "bar"
    }
  }
}
```

<h3 id="put__boot_v1_bootparameters-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[BootParams](#schemabootparams)|false|none|

> Example responses

> 400 Response

```json
{
  "type": "string",
  "title": "string",
  "status": 0,
  "detail": "string",
  "instance": "string"
}
```

<h3 id="put__boot_v1_bootparameters-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|successfully update boot parameters|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request - Invalid BootParams value|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Cannot find specified host, MAC, or NID|[Error](#schemaerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Error](#schemaerror)|
|default|Default|Unexpected error|[Error](#schemaerror)|

### Response Headers

|Status|Header|Type|Format|Description|
|---|---|---|---|---|
|200|BSS-Referral-Token|string||The UUID that will be included in the boot script. A new UUID is generated on each POST and PUT request.|

<aside class="success">
This operation does not require authentication
</aside>

## patch__boot_v1_bootparameters

> Code samples

```http
PATCH http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters HTTP/1.1
Host: bootscriptserver:27778
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters', headers = headers)

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
    req, err := http.NewRequest("PATCH", "http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /boot/v1/bootparameters`

*Update existing boot parameters*

Update an existing entry with new boot parameters while retaining existing settings for the kernel and initrd settings. The entry only needs to specify one or more hosts and the new boot parameters without the need to specify the kernel and initrd entries.

> Body parameter

```json
{
  "hosts": [
    "x0c0s2b0n0",
    "x0c0s3b0n0"
  ],
  "macs": [
    "00:40:a6:82:f6:c5",
    "a4:bf:01:3e:c0:a2",
    "00:40:a6:82:f7:0c"
  ],
  "nids": [
    1,
    2,
    3,
    4
  ],
  "params": "console=tty0 console=ttyS0,115200n8 initrd=initrd-4.12.14-15.5_8.1.96-cray_shasta_c root=crayfs nfsserver=10.2.0.1nfspath=/var/opt/cray/boot_images imagename=/SLES selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M htburl=https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/heartbeat bad_page=panic hugepagelist=2m-2g intel_iommu=off iommu=pt numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet turbo_boost_limit=999",
  "kernel": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/kernel",
  "initrd": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/initrd",
  "cloud-init": {
    "user-data": {
      "foo": "bar"
    },
    "meta-data": {
      "foo": "bar"
    }
  }
}
```

<h3 id="patch__boot_v1_bootparameters-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[BootParams](#schemabootparams)|false|none|

> Example responses

> 400 Response

```json
{
  "type": "string",
  "title": "string",
  "status": 0,
  "detail": "string",
  "instance": "string"
}
```

<h3 id="patch__boot_v1_bootparameters-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Successfully update boot parameters|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request - Invalid BootParams value.|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Cannot find entry for specified host, MAC, or NID|[Error](#schemaerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

## delete__boot_v1_bootparameters

> Code samples

```http
DELETE http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters HTTP/1.1
Host: bootscriptserver:27778
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.delete('http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters', headers = headers)

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
    req, err := http.NewRequest("DELETE", "http://bootscriptserver:27778/apis/bss/boot/v1/bootparameters", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /boot/v1/bootparameters`

*Delete existing boot parameters*

Remove an existing boot parameter settings for one or more hosts, as specified by hosts, MACs, or NIDs. If you specify a kernel or initrd image, the image entry is removed, and the references by any existing hosts are removed. Note that this can leave a host unbootable, and so will need to be updated with new image references before they will be bootable.

> Body parameter

```json
{
  "hosts": [
    "x0c0s2b0n0",
    "x0c0s3b0n0"
  ],
  "macs": [
    "00:40:a6:82:f6:c5",
    "a4:bf:01:3e:c0:a2",
    "00:40:a6:82:f7:0c"
  ],
  "nids": [
    1,
    2,
    3,
    4
  ],
  "params": "console=tty0 console=ttyS0,115200n8 initrd=initrd-4.12.14-15.5_8.1.96-cray_shasta_c root=crayfs nfsserver=10.2.0.1nfspath=/var/opt/cray/boot_images imagename=/SLES selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M htburl=https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/heartbeat bad_page=panic hugepagelist=2m-2g intel_iommu=off iommu=pt numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet turbo_boost_limit=999",
  "kernel": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/kernel",
  "initrd": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/initrd",
  "cloud-init": {
    "user-data": {
      "foo": "bar"
    },
    "meta-data": {
      "foo": "bar"
    }
  }
}
```

<h3 id="delete__boot_v1_bootparameters-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[BootParams](#schemabootparams)|false|none|

> Example responses

> 400 Response

```json
{
  "type": "string",
  "title": "string",
  "status": 0,
  "detail": "string",
  "instance": "string"
}
```

<h3 id="delete__boot_v1_bootparameters-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Successfully deleted the appropriate entry or entries|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request - Invalid BootParams value.|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Does Not Exist - Cannot find specified host, MAC, or NID|[Error](#schemaerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-script-service-hosts">hosts</h1>

## get__boot_v1_hosts

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/boot/v1/hosts HTTP/1.1
Host: bootscriptserver:27778
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/boot/v1/hosts \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/boot/v1/hosts', headers = headers)

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
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/boot/v1/hosts", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /boot/v1/hosts`

*Retrieve hosts*

Retrieve list of known hosts obtained from HSM. This list can be filtered by specifying one or more of the query parameters name=, mac=, and/or nid=. If any of these parameters are specified, then only host information for those items are returned in the response. Multiple hosts can be specified for any of these parameters by specifying a comma-separated list of items, or by providing the query parameter itself more than once. If the same host is referenced more than once, its information will be returned multiple times. In particular, if a host is referenced by both its host name and NID and/or MAC address, this same host information will be returned once for each reference.

<h3 id="get__boot_v1_hosts-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|name|query|string|false|Host name or tag name of boot parameters to return|
|mac|query|string|false|MAC Address of host of boot parameters to return|
|nid|query|integer|false|NID of host of boot parameters to return|

> Example responses

> 200 Response

```json
[
  {
    "ID": "x0c0s21b0n0",
    "Type": "Node",
    "State": "Ready",
    "Flag": "OK",
    "Enabled": true,
    "Role": "Compute",
    "RubeRole": "Worker",
    "NID": 2,
    "NetType": "Sling",
    "Arch": "X86",
    "Class": "string",
    "ReservationDisabled": false,
    "Locked": false,
    "FQDN": "string",
    "MAC": [
      "00:40:a6:82:f6:c5",
      "a4:bf:01:3e:c0:a2",
      "00:40:a6:82:f7:0c"
    ],
    "EndpointEnabled": true
  }
]
```

<h3 id="get__boot_v1_hosts-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Return list of hosts and associated attributes known to BSS|[HostInfo](#schemahostinfo)|

<aside class="success">
This operation does not require authentication
</aside>

## post__boot_v1_hosts

> Code samples

```http
POST http://bootscriptserver:27778/apis/bss/boot/v1/hosts HTTP/1.1
Host: bootscriptserver:27778
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://bootscriptserver:27778/apis/bss/boot/v1/hosts \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.post('http://bootscriptserver:27778/apis/bss/boot/v1/hosts', headers = headers)

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
    req, err := http.NewRequest("POST", "http://bootscriptserver:27778/apis/bss/boot/v1/hosts", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /boot/v1/hosts`

*Retrieve hosts*

Retrieve the latest host information from HSM.

> Example responses

> 400 Response

```json
{
  "type": "string",
  "title": "string",
  "status": 0,
  "detail": "string",
  "instance": "string"
}
```

<h3 id="post__boot_v1_hosts-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|Successfully retrieved current state from HSM.|None|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Error](#schemaerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-script-service-dumpstate">dumpstate</h1>

## get__boot_v1_dumpstate

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/boot/v1/dumpstate HTTP/1.1
Host: bootscriptserver:27778
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/boot/v1/dumpstate \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/boot/v1/dumpstate', headers = headers)

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
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/boot/v1/dumpstate", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /boot/v1/dumpstate`

*Retrieve dumpstate*

Dump internal state of boot script service for debugging purposes. Return known hosts and associated information, along with the known boot parameter info.

> Example responses

> 200 Response

```json
{
  "components": [
    {
      "schema": {
        "ID": "x0c0s21b0n0",
        "Type": "Node",
        "State": "Ready",
        "Flag": "OK",
        "Enabled": true,
        "Role": "Compute",
        "RubeRole": "Worker",
        "NID": 2,
        "NetType": "Sling",
        "Arch": "X86",
        "Class": "string",
        "ReservationDisabled": false,
        "Locked": false,
        "FQDN": "string",
        "MAC": [
          "00:40:a6:82:f6:c5",
          "a4:bf:01:3e:c0:a2",
          "00:40:a6:82:f7:0c"
        ],
        "EndpointEnabled": true
      }
    }
  ],
  "params": [
    {
      "schema": {
        "hosts": [
          "x0c0s2b0n0",
          "x0c0s3b0n0"
        ],
        "macs": [
          "00:40:a6:82:f6:c5",
          "a4:bf:01:3e:c0:a2",
          "00:40:a6:82:f7:0c"
        ],
        "nids": [
          1,
          2,
          3,
          4
        ],
        "params": "console=tty0 console=ttyS0,115200n8 initrd=initrd-4.12.14-15.5_8.1.96-cray_shasta_c root=crayfs nfsserver=10.2.0.1nfspath=/var/opt/cray/boot_images imagename=/SLES selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M htburl=https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/heartbeat bad_page=panic hugepagelist=2m-2g intel_iommu=off iommu=pt numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet turbo_boost_limit=999",
        "kernel": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/kernel",
        "initrd": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/initrd",
        "cloud-init": {
          "user-data": {
            "foo": "bar"
          },
          "meta-data": {
            "foo": "bar"
          }
        }
      }
    }
  ]
}
```

<h3 id="get__boot_v1_dumpstate-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Return internal service state|[StateInfo](#schemastateinfo)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Error](#schemaerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-script-service-endpoint-history">endpoint-history</h1>

## get__boot_v1_endpoint-history

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/boot/v1/endpoint-history HTTP/1.1
Host: bootscriptserver:27778
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/boot/v1/endpoint-history \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/boot/v1/endpoint-history', headers = headers)

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
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/boot/v1/endpoint-history", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /boot/v1/endpoint-history`

*Retrieve access information for xname and endpoint*

Retrieve access information for xname and endpoint. Every time a node requests special types of endpoint (its boot script or cloud-init data) that is recorded in the database. This is useful for determining a number of things most notably as a way to monitor boot progress.

<h3 id="get__boot_v1_endpoint-history-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|name|query|string|false|Xname of the node.|
|endpoint|query|string|false|The endpoint to get the last access information for.|

#### Enumerated Values

|Parameter|Value|
|---|---|
|endpoint|bootscript|
|endpoint|user-data|

> Example responses

> 200 Response

```json
[
  {
    "name": "x3000c0s1b0n0",
    "endpoint": "bootscript",
    "last_epoch": 1635284155
  }
]
```

<h3 id="get__boot_v1_endpoint-history-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Endpoint access information|Inline|

<h3 id="get__boot_v1_endpoint-history-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[EndpointAccess](#schemaendpointaccess)]|false|none|[This data structure is used to return the endpoint access information for a given resource.]|
|» name|string|false|none|Xname of the node|
|» endpoint|string|false|none|none|
|» last_epoch|integer|false|none|Unix epoch time of last request. An epoch of 0 indicates a request has not taken place.|

#### Enumerated Values

|Property|Value|
|---|---|
|endpoint|bootscript|
|endpoint|user-data|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="boot-script-service-service-status">service-status</h1>

## get__boot_v1_service_status

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/boot/v1/service/status HTTP/1.1
Host: bootscriptserver:27778
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/boot/v1/service/status \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/boot/v1/service/status', headers = headers)

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
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/boot/v1/service/status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /boot/v1/service/status`

*Retrieve the current status of BSS*

Retrieve the current status of the BSS service itself.

This endpoint can be used as a liveness probe for the BSS to determine if it is alive or dead.

> Example responses

> 200 Response

```json
{
  "bss-status": "running"
}
```

<h3 id="get__boot_v1_service_status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|The BSS REST API is alive and accessible.|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[Error](#schemaerror)|

<h3 id="get__boot_v1_service_status-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» bss-status|string|false|none|Current status of BSS.|

#### Enumerated Values

|Property|Value|
|---|---|
|bss-status|running|

<aside class="success">
This operation does not require authentication
</aside>

## get__boot_v1_service_etcd

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/boot/v1/service/etcd HTTP/1.1
Host: bootscriptserver:27778
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/boot/v1/service/etcd \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/boot/v1/service/etcd', headers = headers)

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
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/boot/v1/service/etcd", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /boot/v1/service/etcd`

*Retrieve the current connection status to ETCD*

Retrieve the current connection status to the BSS ETCD database.

The connection to ETCD will be tested by writing a value to ETCD, and then reading it
back from the database. If the value is successfully writen to ETCD and read back as the 
same value, then the connection to ETCD is considered to be connected. Otherwise, there
is a connection error.

> Example responses

> 200 Response

```json
{
  "bss-status-etcd": "connected"
}
```

<h3 id="get__boot_v1_service_etcd-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|The ETCD database connection is healthy.|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|The ETCD database connection is unhealthy.|Inline|

<h3 id="get__boot_v1_service_etcd-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» bss-status-etcd|string|false|none|Current connection status to ETCD.|

#### Enumerated Values

|Property|Value|
|---|---|
|bss-status-etcd|connected|

Status Code **500**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» bss-status-etcd|string|false|none|Current connection status to ETCD.|

#### Enumerated Values

|Property|Value|
|---|---|
|bss-status-etcd|error|

<aside class="success">
This operation does not require authentication
</aside>

## get__boot_v1_service_hsm

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/boot/v1/service/hsm HTTP/1.1
Host: bootscriptserver:27778
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/boot/v1/service/hsm \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/boot/v1/service/hsm', headers = headers)

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
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/boot/v1/service/hsm", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /boot/v1/service/hsm`

*Retrieve the current connection status to HSM*

Retrieve the current connection status to the Hardware State Manager (HSM).

The connection to HSM will be tested by querying a HSM endpoint to verify HSM
is alive.

> Example responses

> 200 Response

```json
{
  "bss-status-hsm": "connected"
}
```

<h3 id="get__boot_v1_service_hsm-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|The HSM connection is healthy.|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|The HSM connection is unhealthy.|Inline|

<h3 id="get__boot_v1_service_hsm-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» bss-status-hsm|string|false|none|Current connection status to HSM.|

#### Enumerated Values

|Property|Value|
|---|---|
|bss-status-hsm|connected|

Status Code **500**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» bss-status-hsm|string|false|none|Current connection status to HSM.|

#### Enumerated Values

|Property|Value|
|---|---|
|bss-status-hsm|error|

<aside class="success">
This operation does not require authentication
</aside>

## get__boot_v1_service_version

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/boot/v1/service/version HTTP/1.1
Host: bootscriptserver:27778
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/boot/v1/service/version \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/boot/v1/service/version', headers = headers)

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
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/boot/v1/service/version", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /boot/v1/service/version`

*Retrieve the service version*

Retrieve the current service version.

> Example responses

> 200 Response

```json
{
  "bss-version": "1.21.0"
}
```

<h3 id="get__boot_v1_service_version-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|The current running service version.|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error. Unable to determine current running service version.|Inline|

<h3 id="get__boot_v1_service_version-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» bss-version|string|false|none|none|

Status Code **500**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» bss-version|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|bss-version|error|

<aside class="success">
This operation does not require authentication
</aside>

## get__boot_v1_service_status_all

> Code samples

```http
GET http://bootscriptserver:27778/apis/bss/boot/v1/service/status/all HTTP/1.1
Host: bootscriptserver:27778
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://bootscriptserver:27778/apis/bss/boot/v1/service/status/all \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://bootscriptserver:27778/apis/bss/boot/v1/service/status/all', headers = headers)

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
    req, err := http.NewRequest("GET", "http://bootscriptserver:27778/apis/bss/boot/v1/service/status/all", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /boot/v1/service/status/all`

*Retrieve the overall service health*

Retrieve the overall health of the service, and determine if the service is healthy to serve
requests as a readiness probe.

This will retrieve the current BSS version and status, along with the connection status to HSM and ETCD.

> Example responses

> 200 Response

```json
{
  "bss-status": "running",
  "bss-status-etcd": "connected",
  "bss-status-hsm": "connected",
  "bss-version": "1.21.0"
}
```

<h3 id="get__boot_v1_service_status_all-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|All service checks reported a healthy status.|Inline|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|One or more service checks reported an unhealthy status.|Inline|

<h3 id="get__boot_v1_service_status_all-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» bss-status|string|false|none|none|
|» bss-status-etcd|string|false|none|Current connection status to ETCD.|
|» bss-status-hsm|string|false|none|Current connection status to HSM.|
|» bss-version|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|bss-status|running|
|bss-status-etcd|connected|
|bss-status-hsm|connected|

Status Code **500**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» bss-status|string|false|none|none|
|» bss-status-etcd|string|false|none|Current connection status to ETCD.|
|» bss-status-hsm|string|false|none|Current connection status to HSM.|
|» bss-version|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|bss-status|running|
|bss-status-etcd|connected|
|bss-status-etcd|error|
|bss-status-hsm|connected|
|bss-status-hsm|error|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_BootParams">BootParams</h2>
<!-- backwards compatibility -->
<a id="schemabootparams"></a>
<a id="schema_BootParams"></a>
<a id="tocSbootparams"></a>
<a id="tocsbootparams"></a>

```json
{
  "hosts": [
    "x0c0s2b0n0",
    "x0c0s3b0n0"
  ],
  "macs": [
    "00:40:a6:82:f6:c5",
    "a4:bf:01:3e:c0:a2",
    "00:40:a6:82:f7:0c"
  ],
  "nids": [
    1,
    2,
    3,
    4
  ],
  "params": "console=tty0 console=ttyS0,115200n8 initrd=initrd-4.12.14-15.5_8.1.96-cray_shasta_c root=crayfs nfsserver=10.2.0.1nfspath=/var/opt/cray/boot_images imagename=/SLES selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M htburl=https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/heartbeat bad_page=panic hugepagelist=2m-2g intel_iommu=off iommu=pt numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet turbo_boost_limit=999",
  "kernel": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/kernel",
  "initrd": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/initrd",
  "cloud-init": {
    "user-data": {
      "foo": "bar"
    },
    "meta-data": {
      "foo": "bar"
    }
  }
}

```

When used as a request body, the caller sets boot parameters and specifies hosts, along with the kernel image path/URL and initrd path/URL. To specify hosts, use one of the three parameters - hosts, MACs, or NIDs. If MAC addresses are used, they are mapped to host names based on information retrieved from the hardware state manager.  Likewise, if NIDs are used, they are mapped to host names with the same hardware state manager info.  While the expected usage is to specify hosts based on their host names, the "macs" and "nids" alternatives may be more convenient in some contexts.
You can also specify a general tag for hosts. A tag is 'Default', or one of the roles that a node may be defined as in the hardware state manager (HSM). Some of the HSM roles like 'Compute', 'Storage', 'System', and 'Application' can be specified as hosts and are managed similar to specific hosts. While BSS allows for fine grained control of individual nodes, the tags are typically more convenient, especially for a large system.

Alternatively, if you specify a kernel or initrd image and params, but no host, MAC, or NID, the boot script service will associate the specified params with the specified kernel or initrd image. When used as a response body, identifies the hosts available for booting using either hosts, MACs, or NIDs, depending on which parameter was used in the request.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|hosts|[string]|false|none|host names|
|macs|[string]|false|none|MAC addresses|
|nids|[integer]|false|none|Node ID|
|params|string|false|none|Specific to the kernel that is being booted.|
|kernel|string|false|none|URL or file system path specifying kernel image.|
|initrd|string|false|none|URL or file system path specifying initrd image.|
|cloud-init|[CloudInit](#schemacloudinit)|false|none|Cloud-Init data for the hosts|

<h2 id="tocS_CloudInit">CloudInit</h2>
<!-- backwards compatibility -->
<a id="schemacloudinit"></a>
<a id="schema_CloudInit"></a>
<a id="tocScloudinit"></a>
<a id="tocscloudinit"></a>

```json
{
  "user-data": {
    "foo": "bar"
  },
  "meta-data": {
    "foo": "bar"
  }
}

```

Cloud-Init data for the hosts

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|meta-data|[CloudInitMetadata](#schemacloudinitmetadata)|false|none|Cloud-Init Instance Metadata for a host.|
|user-data|[CloudInitUserData](#schemacloudinituserdata)|false|none|Cloud-Init User data for a host.|
|phone-home|[CloudInitPhoneHome](#schemacloudinitphonehome)|false|none|Data sent from the Phone Home Cloud-Init module after a host's boot is complete.|

<h2 id="tocS_CloudInitMetadata">CloudInitMetadata</h2>
<!-- backwards compatibility -->
<a id="schemacloudinitmetadata"></a>
<a id="schema_CloudInitMetadata"></a>
<a id="tocScloudinitmetadata"></a>
<a id="tocscloudinitmetadata"></a>

```json
{}

```

Cloud-Init Instance Metadata for a host.

### Properties

*None*

<h2 id="tocS_CloudInitUserData">CloudInitUserData</h2>
<!-- backwards compatibility -->
<a id="schemacloudinituserdata"></a>
<a id="schema_CloudInitUserData"></a>
<a id="tocScloudinituserdata"></a>
<a id="tocscloudinituserdata"></a>

```json
{}

```

Cloud-Init User data for a host.

### Properties

*None*

<h2 id="tocS_CloudInitPhoneHome">CloudInitPhoneHome</h2>
<!-- backwards compatibility -->
<a id="schemacloudinitphonehome"></a>
<a id="schema_CloudInitPhoneHome"></a>
<a id="tocScloudinitphonehome"></a>
<a id="tocscloudinitphonehome"></a>

```json
{
  "pub_key_dsa": "string",
  "pub_key_rsa": "string",
  "pub_key_ecdsa": "string",
  "pub_key_ed25519": "string",
  "instance_id": "string",
  "hostname": "string",
  "fqdn": "string"
}

```

Data sent from the Phone Home Cloud-Init module after a host's boot is complete.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|pub_key_dsa|string|false|none|none|
|pub_key_rsa|string|false|none|none|
|pub_key_ecdsa|string|false|none|none|
|pub_key_ed25519|string|false|none|none|
|instance_id|string|false|none|none|
|hostname|string|false|none|none|
|fqdn|string|false|none|none|

<h2 id="tocS_Component">Component</h2>
<!-- backwards compatibility -->
<a id="schemacomponent"></a>
<a id="schema_Component"></a>
<a id="tocScomponent"></a>
<a id="tocscomponent"></a>

```json
{
  "ID": "x0c0s21b0n0",
  "Type": "Node",
  "State": "Ready",
  "Flag": "OK",
  "Enabled": true,
  "Role": "Compute",
  "RubeRole": "Worker",
  "NID": 2,
  "NetType": "Sling",
  "Arch": "X86",
  "Class": "string",
  "ReservationDisabled": false,
  "Locked": false,
  "FQDN": "string",
  "MAC": [
    "00:40:a6:82:f6:c5",
    "a4:bf:01:3e:c0:a2",
    "00:40:a6:82:f7:0c"
  ],
  "EndpointEnabled": true
}

```

This data structure is used to return host info for debug purposes

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|ID|string|false|none|none|
|Type|string|false|none|none|
|State|string|false|none|none|
|Flag|string|false|none|none|
|Enabled|boolean|false|none|none|
|Role|string|false|none|none|
|RubeRole|string|false|none|none|
|NID|integer|false|none|none|
|NetType|string|false|none|none|
|Arch|string|false|none|none|
|Class|string|false|none|none|
|ReservationDisabled|boolean|false|none|none|
|Locked|boolean|false|none|none|
|FQDN|string|false|none|none|
|MAC|[string]|false|none|none|
|EndpointEnabled|boolean|false|none|none|

<h2 id="tocS_StateInfo">StateInfo</h2>
<!-- backwards compatibility -->
<a id="schemastateinfo"></a>
<a id="schema_StateInfo"></a>
<a id="tocSstateinfo"></a>
<a id="tocsstateinfo"></a>

```json
{
  "components": [
    {
      "schema": {
        "ID": "x0c0s21b0n0",
        "Type": "Node",
        "State": "Ready",
        "Flag": "OK",
        "Enabled": true,
        "Role": "Compute",
        "RubeRole": "Worker",
        "NID": 2,
        "NetType": "Sling",
        "Arch": "X86",
        "Class": "string",
        "ReservationDisabled": false,
        "Locked": false,
        "FQDN": "string",
        "MAC": [
          "00:40:a6:82:f6:c5",
          "a4:bf:01:3e:c0:a2",
          "00:40:a6:82:f7:0c"
        ],
        "EndpointEnabled": true
      }
    }
  ],
  "params": [
    {
      "schema": {
        "hosts": [
          "x0c0s2b0n0",
          "x0c0s3b0n0"
        ],
        "macs": [
          "00:40:a6:82:f6:c5",
          "a4:bf:01:3e:c0:a2",
          "00:40:a6:82:f7:0c"
        ],
        "nids": [
          1,
          2,
          3,
          4
        ],
        "params": "console=tty0 console=ttyS0,115200n8 initrd=initrd-4.12.14-15.5_8.1.96-cray_shasta_c root=crayfs nfsserver=10.2.0.1nfspath=/var/opt/cray/boot_images imagename=/SLES selinux=0 rd.shell rd.net.timeout.carrier=40 rd.retry=40 ip=dhcp rd.neednet=1 crashkernel=256M htburl=https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/heartbeat bad_page=panic hugepagelist=2m-2g intel_iommu=off iommu=pt numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet turbo_boost_limit=999",
        "kernel": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/kernel",
        "initrd": "s3://boot-images/1dbb777c-2527-449b-bd6d-fb4d1cb79e88/initrd",
        "cloud-init": {
          "user-data": {
            "foo": "bar"
          },
          "meta-data": {
            "foo": "bar"
          }
        }
      }
    }
  ]
}

```

This data structure is used to return the full component and boot parameter info of the dumpstate request.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|components|[object]|false|none|none|
|» schema|[Component](#schemacomponent)|false|none|This data structure is used to return host info for debug purposes|
|params|[object]|false|none|none|
|» schema|[BootParams](#schemabootparams)|false|none|When used as a request body, the caller sets boot parameters and specifies hosts, along with the kernel image path/URL and initrd path/URL. To specify hosts, use one of the three parameters - hosts, MACs, or NIDs. If MAC addresses are used, they are mapped to host names based on information retrieved from the hardware state manager.  Likewise, if NIDs are used, they are mapped to host names with the same hardware state manager info.  While the expected usage is to specify hosts based on their host names, the "macs" and "nids" alternatives may be more convenient in some contexts.<br>You can also specify a general tag for hosts. A tag is 'Default', or one of the roles that a node may be defined as in the hardware state manager (HSM). Some of the HSM roles like 'Compute', 'Storage', 'System', and 'Application' can be specified as hosts and are managed similar to specific hosts. While BSS allows for fine grained control of individual nodes, the tags are typically more convenient, especially for a large system.<br><br>Alternatively, if you specify a kernel or initrd image and params, but no host, MAC, or NID, the boot script service will associate the specified params with the specified kernel or initrd image. When used as a response body, identifies the hosts available for booting using either hosts, MACs, or NIDs, depending on which parameter was used in the request.|

<h2 id="tocS_HostInfo">HostInfo</h2>
<!-- backwards compatibility -->
<a id="schemahostinfo"></a>
<a id="schema_HostInfo"></a>
<a id="tocShostinfo"></a>
<a id="tocshostinfo"></a>

```json
[
  {
    "ID": "x0c0s21b0n0",
    "Type": "Node",
    "State": "Ready",
    "Flag": "OK",
    "Enabled": true,
    "Role": "Compute",
    "RubeRole": "Worker",
    "NID": 2,
    "NetType": "Sling",
    "Arch": "X86",
    "Class": "string",
    "ReservationDisabled": false,
    "Locked": false,
    "FQDN": "string",
    "MAC": [
      "00:40:a6:82:f6:c5",
      "a4:bf:01:3e:c0:a2",
      "00:40:a6:82:f7:0c"
    ],
    "EndpointEnabled": true
  }
]

```

This data structure is used to return the component info for a /hosts get request

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[Component](#schemacomponent)]|false|none|This data structure is used to return the component info for a /hosts get request|

<h2 id="tocS_EndpointAccess">EndpointAccess</h2>
<!-- backwards compatibility -->
<a id="schemaendpointaccess"></a>
<a id="schema_EndpointAccess"></a>
<a id="tocSendpointaccess"></a>
<a id="tocsendpointaccess"></a>

```json
{
  "name": "x3000c0s1b0n0",
  "endpoint": "bootscript",
  "last_epoch": 1635284155
}

```

This data structure is used to return the endpoint access information for a given resource.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|Xname of the node|
|endpoint|string|false|none|none|
|last_epoch|integer|false|none|Unix epoch time of last request. An epoch of 0 indicates a request has not taken place.|

#### Enumerated Values

|Property|Value|
|---|---|
|endpoint|bootscript|
|endpoint|user-data|

<h2 id="tocS_Error">Error</h2>
<!-- backwards compatibility -->
<a id="schemaerror"></a>
<a id="schema_Error"></a>
<a id="tocSerror"></a>
<a id="tocserror"></a>

```json
{
  "type": "string",
  "title": "string",
  "status": 0,
  "detail": "string",
  "instance": "string"
}

```

Return an RFC7808 error response.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|type|string|false|none|none|
|title|string|false|none|none|
|status|integer|false|none|none|
|detail|string|false|none|none|
|instance|string|false|none|none|

