---
category: numbered
---

# Create a UAI Class

Create a UAI class with one command. After the class is created, it can be used to configure UAIs.

Install and initialize the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Add a new UAI class to UAS so that the class can be used to configure UAIs.

-   **LIMITATIONS**

    None.


1.  Add a UAI class by using the command in the following example.

    IMAGE\_ID is the UAI image identifier of the UAI image to be used in creating UAIs of the new class. Any number of classes using the same IMAGE\_ID can be defined. The IMAGE\_ID is required.

    These are the supported optional OPTIONS:

    -   --volume-list VOLUME\_ID\_1, VOLUME\_ID\_2, . . .: a list of one or more UAS volume IDs that will be mounted by UAIs of this class.
    -   --resource-id RESOURCE\_SPECIFICATION\_ID: the ID of a resource specification to be used for UAIs of this class.
    -   --uai-compute-network: this value can be either yes or no and sets the uai\_compute\_network field in the UAI class accordingly.
    -   --opt-ports PORT\_NUMBER\_1,PORT\_NUMBER\_2, . . .: a list of one or more additional TCP ports on which UAIs of this class will listen on their external IP address. These ports are in addition to SSH, which accepts connections on that external IP address.
    -   --uai-creation-class UAI\_CLASS\_ID: the UAS ID of the class of end-user UAIs that a broker UAI will create when handling a login. This option is only used when creating broker UAIs.
    -   --namespace K8S\_NAMESPACE\_NAME: the Kubernetes namespace for the UAIs of this class
    -   --priority-class-name K8S\_PRIORITY\_CLASS: set the Kubernetes priority class of UAIs created with this class.
    -   --public-ip: A yes value means UAIs created with this class will listen on a public IP address provided by LoadBalancer. A no value means UAIs of this class will be given only a private ClusterIP reachable only within the Kubernetes cluster.
    -   --default: This yes or no value specifies whether this UAI class will be used as a default UAI class.
    -   --comment TEXT: a comment on this UAI class in the form of free-form text string.
    ```screen
    ncn-m001-pit# cray uas admin config classes create --image-id IMAGE\_ID OPTIONS
    ```

    See [About UAI Classes](About_UAI_Classes.md) for more information about configuring UAI classes.


