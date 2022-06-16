# UAI Classes

UAI Classes provide templates for the creation of UAIs. They permit precise configuration of the behavior, volumes, resources, and other elements of the UAI.
When a UAI is created using a UAI Class, it is configured to use exactly what that UAI Class has in it at the time the UAI was created.
UIA Classes permit Broker UAIs to create different kinds of UAIs based on the UAI Creation Class setting of the Broker UAI.
UAI Classes also provide the foundation on which Broker UAIs are built, defining specific configuration options without which it would not be possible to construct a Broker UAI.

In the [Legacy UAI Creation mode](Legacy_Mode_User-Driven_UAI_Management.md), default UAI classes allow the precise configuration of user-created UAIs.
This is particularly useful with regard to volumes, since, without a default UAI Class, all user-created UAIs would simply try to attach all configured volumes.
Finally, default UAI Classes enable the Legacy UAI Creation mode to access Resource Specifications and other configuration not normally available to user-created UAIs.

This topic describes the content and purpose of the the fields in a UAI Class and gives guidance on setting those when creating UAI classes or various kinds.

## Example Listing and Overview

The following is JSON-formatted example output from the `cray uas admin config classes list` command \(see [List Available UAI Classes](List_Available_UAI_Classes.md)\).

This output contains examples of three UAI classes:

* A brokered End-User UAI class
* A UAI broker class
* A non-brokered End-User UAI class

```bash
ncn-m001-pit# cray uas admin config classes list --format json
```

Example output:

```json
[
  {
    "class_id": "bdb4988b-c061-48fa-a005-34f8571b88b4",
    "comment": "UAI Class to Create Brokered End-User UAIs",
    "default": false,
    "image_id": "1996c7f7-ca45-4588-bc41-0422fe2a1c3d",
    "namespace": "user",
    "opt_ports": [],
    "priority_class_name": "uai-priority",
    "public_ip": false,
    "replicas": 1,
    "resource_config": {
      "comment": "Resource Specification to use with Brokered End-User UAIs",
      "limit": "{\"cpu\": \"1\", \"memory\": \"1Gi\"}",
      "request": "{\"cpu\": \"1\", \"memory\": \"1Gi\"}",
      "resource_id": "f26ee12c-6215-4ad1-a15e-efe4232f45e6"
    },
    "resource_id": "f26ee12c-6215-4ad1-a15e-efe4232f45e6",
    "service_account": null,
    "timeout": {
      "hard": "86400",
      "soft": "1800",
      "warning": "60"
    },
    "tolerations": null,
    "uai_compute_network": true,
    "uai_creation_class": null,
    "uai_image": {
      "default": true,
      "image_id": "1996c7f7-ca45-4588-bc41-0422fe2a1c3d",
      "imagename": "registry.local/cray/cray-uai-sles15sp2:1.2.4"
    },
    "volume_list": [
      "11a4a22a-9644-4529-9434-d296eef2dc48",
      "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a"
    ],
    "volume_mounts": [
      {
        "mount_path": "/etc/localtime",
        "volume_description": {
          "host_path": {
            "path": "/etc/localtime",
            "type": "FileOrCreate"
          }
        },
        "volume_id": "11a4a22a-9644-4529-9434-d296eef2dc48",
        "volumename": "timezone"
      },
      {
        "mount_path": "/lus",
        "volume_description": {
          "host_path": {
            "path": "/lus",
            "type": "DirectoryOrCreate"
          }
        },
        "volume_id": "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a",
        "volumename": "lustre"
      }
    ]
  },
  {
    "class_id": "d764c880-41b8-41e8-bacc-f94f7c5b053d",
    "comment": "UAI broker class",
    "default": false,
    "image_id": "8f180ddc-37e5-4ead-b261-2b401914a79f",
    "namespace": "uas",
    "opt_ports": [],
    "priority_class_name": "uai-priority",
    "public_ip": true,
    "replicas": 3,
    "resource_config": null,
    "resource_id": null,
    "service_account": null,
    "timeout": null,
    "tolerations": null,
    "uai_compute_network": false,
    "uai_creation_class": "bdb4988b-c061-48fa-a005-34f8571b88b4",
    "uai_image": {
      "default": false,
      "image_id": "8f180ddc-37e5-4ead-b261-2b401914a79f",
      "imagename": "registry.local/cray/cray-uai-broker:1.2.4"
    },
    "volume_list": [
      "11a4a22a-9644-4529-9434-d296eef2dc48",
      "1ec36af0-d5b6-4ad9-b3e8-755729765d76",
      "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a"
    ],
    "volume_mounts": [
      {
        "mount_path": "/etc/localtime",
        "volume_description": {
          "host_path": {
            "path": "/etc/localtime",
            "type": "FileOrCreate"
          }
        },
        "volume_id": "11a4a22a-9644-4529-9434-d296eef2dc48",
        "volumename": "timezone"
      },
      {
        "mount_path": "/etc/sssd",
        "volume_description": {
          "secret": {
            "default_mode": 384,
            "secret_name": "broker-sssd-conf"
          }
        },
        "volume_id": "1ec36af0-d5b6-4ad9-b3e8-755729765d76",
        "volumename": "broker-sssd-config"
      },
      {
        "mount_path": "/lus",
        "volume_description": {
          "host_path": {
            "path": "/lus",
            "type": "DirectoryOrCreate"
          }
        },
        "volume_id": "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a",
        "volumename": "lustre"
      }
    ]
  },
  {
    "class_id": "5eb523ba-a3b7-4a39-ba19-4cfe7d19d296",
    "comment": "UAI Class to Create Non-Brokered End-User UAIs",
    "default": true,
    "image_id": "1996c7f7-ca45-4588-bc41-0422fe2a1c3d",
    "namespace": "user",
    "opt_ports": [],
    "priority_class_name": "uai-priority",
    "public_ip": true,
    "replicas": 1,
    "resource_config": null,
    "resource_id": null,
    "service_account": null,
    "timeout": {
      "hard": "86400",
      "soft": "1800",
      "warning": "60"
    },
    "tolerations": null,
    "uai_compute_network": true,
    "uai_creation_class": null,
    "uai_image": {
      "default": true,
      "image_id": "1996c7f7-ca45-4588-bc41-0422fe2a1c3d",
      "imagename": "registry.local/cray/cray-uai-sles15sp2:1.2.4"
    },
    "volume_list": [
      "11a4a22a-9644-4529-9434-d296eef2dc48",
      "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a"
    ],
    "volume_mounts": [
      {
        "mount_path": "/etc/localtime",
        "volume_description": {
          "host_path": {
            "path": "/etc/localtime",
            "type": "FileOrCreate"
          }
        },
        "volume_id": "11a4a22a-9644-4529-9434-d296eef2dc48",
        "volumename": "timezone"
      },
      {
        "mount_path": "/lus",
        "volume_description": {
          "host_path": {
            "path": "/lus",
            "type": "DirectoryOrCreate"
          }
        },
        "volume_id": "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a",
        "volumename": "lustre"
      }
    ]
  }
]
```

## UAI Class Parameters

The following selection is the core of a UAI Class configuration:

```json
    "class_id": "bdb4988b-c061-48fa-a005-34f8571b88b4",
    "comment": "UAI Class to Create Brokered End-User UAIs",
    "default": false,
    "image_id": "1996c7f7-ca45-4588-bc41-0422fe2a1c3d",
    "namespace": "user",
    "opt_ports": [],
    "priority_class_name": "uai-priority",
    "public_ip": false,
    "replicas": 1,
    "resource_id": "f26ee12c-6215-4ad1-a15e-efe4232f45e6",
    "service_account": null,
    "timeout": {
      "hard": "86400",
      "soft": "1800",
      "warning": "60"
    },
    "tolerations": null,
    "uai_compute_network": true,
    "uai_creation_class": null,
```

The following table explains each of these fields.

|Field|Description|Notes|
|-----|-----------|-----|
|`class_id`|The identifier used for this class when examining, updating, and deleting the class.|This identifier is also used to create UAIs using this class with the `cray uas admin uais create` command, and by Broker UAI Classes to specify what kind of End-User UAIs to create using the `uai_creation_class` field of the Broker UAI Class|
|`comment`|A free-form string describing the UAI class| |
|`default`|A boolean value \(flag\) indicating whether this class is the default class.|When this field is set to `true`, this class overrides both the default UAI image and any specified image name when the `cray uas create` command is used to create an End-User UAI for a user. Setting a class to `"default": true`, gives the administrator fine-grained control over the behavior of End-User UAIs that are created by authorized users in legacy mode.|
|`namespace`|The Kubernetes namespace in which this UAI will run.|The default setting is `user`. Broker UAIs should be configured to run in the `uas` namespace|
|`opt_ports`|An optional list of TCP port numbers that will be opened on the external IP address of the UAI when it runs.|This field controls whether services other than SSH can be run and reached publicly on the UAI. If this list is empty \(as in this example\), only SSH will be externally accessible. In order for any service other than SSH to be publicly reachable the `public_ip` field must be set to `true`|
|`priority_class_name`|The Kubernetes priority class of the UAI.|`uai_priority` is the default. Using other values affects both Kubernetes default resource limit and request assignments and the Kubernetes scheduling priority for the UAI.|
|`public_ip`|A boolean value that indicates whether the UAI will be given an external IP address from the `LoadBalancer` service. Such an address enables clients outside the Kubernetes cluster to reach the UAI.|This field controls whether the UAI is reachable by SSH from external clients, but it also controls whether the ports in opt\_ports are reachable. If this field is set to `false`, the UAI will have only an internal IP address, reachable from within the Kubernetes cluster.|
|`replicas`|The number of replica UAI pods to be created when a UAI of this class is created.|This defaults to 1 and should not be set or should be set to 1 on End-User UAI Classes, since replica UAI pods for End-User UAIs only consume resources and potentially confuse the Broker UAI mechanism. For Broker UAI Classes, however, setting `replicas` to a larger value establishes both a degree of Broker UAI resiliency and a degree of load balancing, both for the purpose increasing network throughput on End-User UAI connections and for the purpose of avoiding overload of a single Broker UAI's resources.|
|`resource\id`|The ID of the Resource Specification used by this UAI Class|By configuring a [Resource Specification](Resource_Specifications.md) in a UAI Class the default resource requests and limits can be overridden when creating a UAI from that UAI Class|
|`service_account`|An optional Kubernetes Service Account name to be granted to UAIs using this class|This is normally not set on End-User UAIs or Broker UAIs. It can be used to confer specific Kubernetes Role Based Access Control \(RBAC\) permissions on UAIs created using a UAI Class|
|`timeout`|An optional specification of `hard` and `soft` timeouts used to control the life-cycle of UAIs created using this UAI Class|If either timeout setting is omitted that timeout will never expire. When a `soft` timeout, expires, the UAI terminates and is removed if it is or becomes idle, defined as having no logged in user sessions. When a `hard` timeout expires the UAI is terminated and removed immediately regardless of logged in user sessions. A `warning` may also be configured, specifying the number of seconds before a `hard` timeout that a warning will be sent to logged in users telling them of impending termination. The example here sets a `hard` timeout of 24 hours, a `soft` timeout of 30 minutes and a `warning` 60 seconds prior to arriving at the `hard` timeout.|
|`tolerations`|An optional list of Kubernetes tolerations that can be used in combination with "taints" on Kubernetes worker nodes to permit only UAIs of this class to run on those nodes.|Tolerations and Taints can be used to designate certain Kubernetes Worker NCNs as hosts for UAIs and not for general management plane activities. They can also be used to specify that UAIs of a given class run only on nodes with specific resources. By default, all UAIs receive a toleration of `uai_only op=Exists` meaning that all UAIs can run on nodes that are tainted with a `uai_only` setting.|
|`uai_compute_network`|A flag that indicates whether this UAI uses the `macvlan` mechanism to gain access to the HPE Cray EX compute node network.|This field must be true to support workload management from UAIs created by this class. It should be set to `false` on Broker UAIs.|
|`uai_creation_class`|A field used in Broker UAI Classes to tell the Broker UAI what kind of UAI to create when automatically creating a UAI.|This field is not set in the preceding example.|

## UAI Image Descriptions, Resource Descriptions, and Volume Descriptions in UAI Classes

The following image description is provided as a convenience to allow the user to see the image information used when creating UAIs of this class:

```json
    "uai_image": {
      "default": true,
      "image_id": "1996c7f7-ca45-4588-bc41-0422fe2a1c3d",
      "imagename": "registry.local/cray/cray-uai-sles15sp2:1.2.4"
    },
```

The following Resource Specification description is provided as a convenience to allow the user to see the resource configuration used when creating UAIs of this UAI Class:

```json
    "resource_config": {
      "comment": "Resource Specification to use with Brokered End-User UAIs",
      "limit": "{\"cpu\": \"1\", \"memory\": \"1Gi\"}",
      "request": "{\"cpu\": \"1\", \"memory\": \"1Gi\"}",
      "resource_id": "f26ee12c-6215-4ad1-a15e-efe4232f45e6"
    },
```

The following list of volume descriptions is provided as a convenience to allow the user to see the specific volume configuration used when creating UAIs of this class:

```json
    "volume_mounts": [
      {
        "mount_path": "/etc/localtime",
        "volume_description": {
          "host_path": {
            "path": "/etc/localtime",
            "type": "FileOrCreate"
          }
        },
        "volume_id": "11a4a22a-9644-4529-9434-d296eef2dc48",
        "volumename": "timezone"
      },
      {
        "mount_path": "/lus",
        "volume_description": {
          "host_path": {
            "path": "/lus",
            "type": "DirectoryOrCreate"
          }
        },
        "volume_id": "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a",
        "volumename": "lustre"
      }
    ]
```

Refer to [Elements of a UAI](Elements_of_a_UAI.md) for a full explanation of UAI images, Resource Specifications and volumes.

In the preceding section of output, the End-User UAI inherits the timezone from the host node by importing `/etc/localtime`. This UAI also gains access to the Lustre file system mounted on the host node.
On the host node, the file system is mounted at `/lus` and the UAI mounts the file system at the same mount point as the host node.

## Specifics of a Broker UAI Class

Notice the following settings in the Broker UAI class example above:

```json
    "default": false,
    ...
    "image_id": "8f180ddc-37e5-4ead-b261-2b401914a79f",
    "namespace": "uas",
    ...
    "public_ip": true,
    "replicas": 3,
    ...
    "timeout": null,
    ...
    "uai_compute_network": false,
    "uai_creation_class": "bdb4988b-c061-48fa-a005-34f8571b88b4",
    "uai_image": {
      "default": false,
      "image_id": "8f180ddc-37e5-4ead-b261-2b401914a79f",
      "imagename": "registry.local/cray/cray-uai-broker:1.2.4"
    },
```

### Default is False

Usually a site will not want or need to set a Broker UAI's `default` flag to `true` because Broker UAIs will be administratively launched, not launched through the legacy mode UAI management procedure.

### Image ID specifies the HPE Supplied Broker UAI Image

A Broker UAI runs in a special image that knows how to authenticate multiple users, find or create End-User UAIs on behalf of those users, and forward SSH connections to those End-User UAIs.
HPE provides a Broker UAI image with this logic built into it.

### Namespace is `uas`

Broker UAIs run in the `uas` namespace which is configured to set up pods with access to the API gateway.
This is needed by Broker UAIs so that they can call UAS APIs to create, find and manage End-User UAIs.

### Public IP is True

Broker UAIs accept incoming SSH connections from external hosts, so they need to have a presence on an external network. Setting `public_ip` to `true` makes this work.

### Replicas is greater than 1

While it is not required to make the number of replicas for a Broker UAI greater than 1, setting a larger number makes the Broker UAI more resilient to node outages, resource starvation, and other possible issues.
A larger replica count also reduces the networking and computational load on individual Broker UAI pods by permitting connections to be load balanced across the replicas.
The replica count should not exceed the number of Kubernetes Worker Nodes permitted to host Broker UAIs.

### No Timeout is Specified

Broker UAIs cannot time out (there is no timeout mechanism in them) so setting a timeout on Broker UAIs is meaningless.
Furthermore, since Broker UAIs are resources that should remain in place on a running system, putting a timeout on a Broker UAI would be counterproductive. Broker UAIs should have either no `timeout` specified or an empty `timeout`.

### UAI Compute Network is False

Broker UAIs do not need access to workload management services, so they should not run with UAI Compute Network access.
Setting this to `true` would consume IP addresses on the UAI Compute Network unnecessarily and reduce the number of End-User UAIs available on the system.

## Specifics of a Brokered End-User UAI Class

Notice the following settings in the Brokered End-User UAI Class:

```json
    "default": false,
    "image_id": "8f180ddc-37e5-4ead-b261-2b401914a79f",
    "namespace": "user",
    ...
    "public_ip": false,
    "replicas": 1,
    ...
    "timeout": {
      "hard": "86400",
      "soft": "1800",
      "warning": "60"
    },
    "uai_compute_network": true,
    "uai_creation_class": null,
    "uai_image": {
      "default": false,
      "image_id": "8f180ddc-37e5-4ead-b261-2b401914a79f",
      "imagename": "registry.local/cray/cray-uai-broker:1.2.4"
    },
```

### `default` is False

The UAI Class used for Brokered End-User UAIs has characteristics that do not make it suitable for use as a Non-Brokered UAI, so a Brokered UAI Class should never be the default UAI Class.

### UAI Image is an End-User UAI Image

In this example, the UAI image used is the HPE provided basic End-User UAI image. This could also be a [custom End-User UAI image](Customize_End-User_UAI_Images.md).
The important thing for any End-User UAI Class is that the image is an End-User UAI image of some kind.

### Namespace is `user`

In this example the `namespace` setting is `user`. This is the default setting and causes UAIs created by this UAI Class to run in the `user` namespace.
The `user` namespace is isolated from Kubernetes resources in other namespaces and does not set up a connection to the API Gateway for pods running inside it.
This, or a similarly isolated namespace should always be used for End-User UAIs since it keeps End-User UAIs isolated from management plane activities even though they are running inside the Kubernetes cluster.

### Public IP Is False

Brokered UAIs are always reached through Broker UAIs, so they do not need to and should not expose public IP access.

### Replicas is 1 or Not Specified

Using replica pods in an End-User UAI simply wastes UAI Compute Network IP addresses, thereby limiting the number of End-User UAIs that can be created. The default value of 1 should be used for `replicas` in all End-User UAI Classes.

### Timeout is Provided

While setting a timeout on End-User UAIs is not required, it is a good idea. Stale and idle UAIs consume resources that could be used by active fresh UAIs.
By setting, at least, a `soft` timeout on End-User UAI Classes, the administrator can ensure that resources are released to the system when a user's UAI becomes idle for an extended time.
The above `timeout` specification will terminate the UAI, even if it is not idle, after 24 hours, with a 60 second warning. It will terminate an idle UAI after 30 minutes.

### UAI Compute Network is True

End-User UAIs generally require access to workload management, so they require access the compute node network. Setting `uai_compute_network` to `true` makes this work.

### UAI Creation Class is not specified

UAI Creation Class is only meaningful to UAIs that create other UAIs (specifically Broker UAIs).

## Specifics of a Non-Brokered End-User UAI Class

Non-Brokered End-User UAIs are very similar to Brokered End-User UAIs, but Non-Brokered End-User UAIs have some special traits.
Notice the specific settings in the Non-Brokered End-User UAI Class that are different from those in the Brokered End-User UAI Class:

```json
    "default": true,
    "public_ip": true,
```

### Default is True

The UAI Class used for Non-Brokered End-User UAIs must be the default UAI Class.
There is no way to create a UAI from a class in the Legacy Mode UAI Creation procedures.

### Public IP Is True

Manually created UAIs must be reached by direct SSH from external hosts, so they need to have a presence on an external network. Setting `public_ip` to `true` makes this work.

[Top: User Access Service (UAS)](index.md)

[Next Topic: List Available UAI Classes](List_Available_UAI_Classes.md)
