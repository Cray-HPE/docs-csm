# Volumes

Volumes provide a way to connect UAIs to external data, whether they be Kubernetes managed objects, external file systems or files, host node files and directories, or remote networked data to be used within the UAI.

The following are examples of how volumes are commonly used by UAIs:

* To connect UAIs to configuration files like `/etc/localtime` maintained by the host node
* To connect End-User UAIs to Slurm or PBS Professional Workload Manager configuration shared through Kubernetes
* To connect End-User UAIs to Programming Environment libraries and tools hosted on the UAI host nodes
* To connect End-User UAIs to Lustre or other external storage for user data
* To connect Broker UAIs to a directory service (see [Configure a Broker UAI Class](Configure_a_Broker_UAI_Class.md)) or SSH configuration (see [Customize the Broker UAI Image](Customize_the_Broker_UAI_Image.md)) needed to authenticate and redirect user sessions

Any kind of volume recognized by the Kubernetes installation can be installed as a volume within UAS. In the case of Legacy Mode UAI creation without a default UAI Class, all configured volumes are used when creating UAIs.
This can be controlled more precisely by defining and using [UAI Classes](UAI_Classes.md). There is more information on Kubernetes volumes in the [Kubernetes Documentation](https://kubernetes.io/docs/concepts/storage/volumes).

**NOTE:** As with UAI images, registering a volume with UAS creates the configuration that will be used to create a UAI. If the underlying object referred to by the volume does not exist at the time the UAI is created,
the UAI will, in most cases, wait until the object becomes available before starting up. This will be visible in the UAI state which will eventually move to `waiting`.

[Top: User Access Service (UAS)](index.md)

[Next Topic: List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md)
