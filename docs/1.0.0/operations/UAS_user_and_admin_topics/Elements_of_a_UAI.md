# Elements of a UAI

All UAIs can have the following attributes associated with them:

-   A required container image
-   An optional set of volumes
-   An optional resource specification
-   An optional collection of other configuration items

This topic explains each of these attributes.

### UAI container image

The container image for a UAI \(UAI image\) defines and provides the basic environment available to the user. This environment includes, among other things:

-   The operating system \(including version\)
-   Preinstalled packages

A site can customize UAI images and add those images to UAS, allowing them to be used for UAI creation. Any number of UAI images can be configured in UAS, though only one will be used by any given UAI.

UAS provides two UAI images by default. These images enable HPE Cray EX administrators to set up UAIs and run many common tasks. The first image is a standard end-user UAI image that has the software necessary to support a basic Linux login experience. This image also comes with the Slurm and PBS Professional workload management client software installed. These clients allow users to take advantage of one or both of these workload managers if they are installed on the host system. The second image is a broker UAI image. Broker UAIs are a special type of UAIs used in the "broker based" operation model. Broker UAIs present a single SSH endpoint that every user logs into. The broker UAI then locates or creates a suitable end-user UAI and redirects the SSH session to that end-user UAI.

### UAI Volumes

The volumes defined for a UAI provide external access to data provided by the host node. Anything that can be defined as a volume in a Kubernetes pod specification can be configured in UAS as a volume and used within a UAI. Examples include:

-   Kubernetes ConfigMaps and Secrets
-   External file systems used for persistent storage or external data access
-   Host node files and directories

When UAIs are created they mount a list of volumes inside their containers to give them access to various data provided either by Kubernetes resources or through Kubernetes by the host node where the UAI runs. Which volumes are in that list depends on how the UAI is created:

-   UAIs not created using a UAI class mount all volumes configured in UAS.
-   UAIs created using a class only mount the volumes listed in the class and configured in UAS.

The following are some example use cases for UAI volumes:

-   Connecting UAIs to configuration files like /etc/localtime maintained by the host node.
-   Connect end-user UAIs to Slurm or PBS Professional Workload Manager configuration shared through Kubernetes.
-   Connecting end-user UAIs to Programming Environment libraries and tools hosted on the UAI host nodes.
-   Connecting end-user UAIs to Lustre or other external storage for user data.
-   Connecting broker UAIs to a directory service or SSH configuration to authenticate and redirect user sessions.

Every UAS volume includes the following values in its registration information:

-   `mount_path`: Specifies where in the UAI the volume will be mounted.
-   `volume_description`: A dictionary with one entry, whose key identifies the kind of Kubernetes volume is described \(for example, `host_path`, `configmap`, `secret`\). The value is another dictionary containing the Kubernetes volume description itself.
-   `volumename`: A required string chosen by the creator of the volume. This may describe or name the volume. It is used inside the UAI pod specification to identify the volume that is mounted in a given location in a container. A `volumename` is unique within any given UAI, but not necessarily within UAS. These are useful when searching for a volume if they are unique across the UAS configuration.
-   `volume_id`: Used to identify the UAS volume when examining, updating, or deleting a volume and when linking a volume to a UAI class. A `volume_id` is unique within UAS.

Refer to https://kubernetes.io/docs/concepts/storage/volumes for more information about Kubernetes volumes.

### Resource Specifications

A resource request tells Kubernetes the minimum amount of memory and CPU to give to each UAI. A resource limit sets the maximum amount that Kubernetes can give to any UAI. Kubernetes uses resource limits and requests to manage the system resources available to pods. Because UAIs run as pods under Kubernetes, UAS takes advantage of Kubernetes to manage the system resources available to UAIs. In UAS, resource specifications contain that configuration. A UAI that is assigned a resource specification will use that instead of the default resource limits or requests on the Kubernetes namespace containing the UAI. This way, resource specifications can be used to fine-tune resources assigned to UAIs.

UAI resource specifications have three configurable parameters:

-   A limit which is a JSON string describing a Kubernetes resource limit.
-   A request which is a JSON string describing a Kubernetes resource request.
-   An optional comment which is a free-form string containing any information an administrator might find useful about the resource specification.

Resource specifications also contain a resource-id that is used for examining, updating, or deleting the resource specification as well as linking the resource specification into a UAI class.

Resource specifications configured in UAS contain resource requests, limits, or both, that can be associated with a UAI. Any resource request or limit that can be set up on a Kubernetes pod can be set up as a resource specification under UAS.

### Other Configuration Items

There are also smaller configuration items that control things such as:

-   Whether the UAI can talk to compute nodes over the high-speed network \(needed for workload management\).
-   Whether the UAI presents a public facing or private facing IP address for SSH.
-   Kubernetes scheduling priority.

A UAI class template is required to configure such items.

### UAI Configuration and UAI Classes

The container image for a UAI (UAI image), defines the basic environment including the flavor of operating system, the installed packages, and so forth available to the user. UAI images can be customized by a site and added to the UAS configuration to be used in UAI creation. Any number of UAI images can be configured in the UAS, though only one will be used by any given UAI. The UAS comes with some pre-defined UAI images that make it possible to set up UAIs and run many common tasks without further customization. Refer to [Customize End-User UAI Images](Customize_End-User_UAI_Images.md).

The volumes defined for a UAI provide for external access to data provided by the host system. Examples of this range from Kubernetes "configmaps" and "secrets" to external file systems used for persistent storage or external data access. Anything that can be defined as a volume in a Kubernetes pod specification can be configured in UAS as a volume and used within a UAI.

Resource requests and limits tell Kubernetes how much memory and CPU a given UAI wants all the time (request) and how much memory and CPU a UAI can ever be given (limit). Resource specifications configured into UAS contain resource requests and / or limits that can be associated with a UAI. Any resource request or limit that can be set up on a Kubernetes pod can be set up as a resource specification under UAS.

The smaller configuration items control things like whether the UAI can talk to compute nodes over the high-speed network (needed for workload management), whether the UAI presents a public facing or private facing IP address for SSH, Kubernetes scheduling priority and others.

All of the above can be customized on a given set of UAIs by defining a UAI class. UAI classes are templates used to create UAIs, and provide access to fine grained configuration and selection of image, volumes and resource specification. While an end-user UAI can be created by simply specifying its UAI image and the user's public key, to make more precisely constructed UAIs a UAI class must be used.

