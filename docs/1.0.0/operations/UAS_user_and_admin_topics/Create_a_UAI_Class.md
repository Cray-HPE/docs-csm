# Create a UAI Class

Add a new User Access Instance (UAI) class to the User Access Service (UAS) so that the class can be used to configure UAIs.

### Prerequisites

Install and initialize the `cray` administrative CLI.

### Procedure

1.  Add a UAI class by using the command in the following example.

    ```
    ncn-m001-pit# cray uas admin config classes create --image-id <image-id> [options]
    ```
    `--image-id <image-id>` specifies the UAI image identifier of the UAI image to be used in creating UAIs of the new class. Any number of classes using the same image id can be defined.

    The following options are available:

    * `--image-id <image-id>` set the UAI image to be used creating UAIs of this class (included here for completeness, this option is required for creation, not for updates)
    * `--volume-list '<volume-id>[,<volume-id[,...]]'` set up the list of volumes mounted by UAIs of this class
    * `--resource-id <resource-id>` set a resource specification to be used for UAIs of this class
    * `--uai-compute-network yes|no` set the `uai_compute_network` flag described above in the UAI class
    * `--opt-ports '<port-number>[,<port-number[,...]]'` sets up TCP ports in addition to SSH on which UAIs of this class will listen on their external IP address (i.e. the address SSH is listening on)
    * `-uai-creation-class <class-id>` for broker UAIs only, the class of end-user UAIs the broker will create when handling a login
    * `--namespace '<namespace-name>'` sets the Kubernetes namespace where UAIs of this class will run
    * `--priority-class-name '<priority-class-name>'` set the Kubernetes priority class of UAIs created with this class
    * `--public-ip yes|no` specify whether UAIs created with this class will listen on a public (LoadBalancer) IP address (`yes`) or a Kubernetes private (ClusterIP) IP address (`no`)
    * `--default yes|no` specify whether this UAI class should be used as a default UAI class or not (see description in the previous section)
    * `--comment 'text'` set a free-form text comment on the UAI class

    Only the `--image-id` option is required to create a UAI class. In that case, a UAI class with the specified UAI Image and no volumes will be created.

