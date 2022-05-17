# UAI Management

UAS supports two manual methods and one automated method of UAI management:

* Direct administrative UAI management
* Legacy mode user driven UAI management
* UAI broker mode UAI management

Direct administrative UAI management is available mostly to allow administrators to set up Broker UAIs for the [Broker Mode UAI Management](Broker_Mode_UAI_Management.md) and to control UAIs that are created under one of the other two methods.
It is unlikely that a site will choose to create End-User UAIs this way, but it is possible to do.
The administrative UAI management API provides an administrative way to list, create, examine, and delete UAIs.

The [legacy mode](Legacy_Mode_User-Driven_UAI_Management.md) of UAI management gives users the authority to create, list, and delete UAIs that belong to them.
While this is a conceptually simple mode, it can lead to an unnecessary proliferation of UAIs belonging to a single user if the user is not careful to create UAIs only when needed.
The legacy mode also cannot take advantage of the breadth of UAI classes to create more than one kind of UAI for different users' needs.
In the legacy mode, UAIs can be created using a default UAI Class as a template and will always be created this way if a default UAI Class is configured,
or, in the absence of a default UAI Class, using any of the registered UAI images and _all_ of the volumes configured in the UAS.
Use of a default UAI Class for legacy mode UAI creation is strongly advised.

Broker UAIs mode creates / re-use UAIs on demand when a user logs into a Broker UAI using SSH.
A site may run multiple Broker UAIs, each configured to create UAIs of a different UAI class and each running with its own externally visible IP address.
By choosing the correct IP address and logging into the broker, a user ultimately arrives in an End-User UAI tailored for a given use case.
Because the broker is responsible for managing the underlying End-User UAIs, users need not be given authority to create UAIs directly and, therefore, cannot cause a proliferation of unneeded UAIs.
Because the Broker UAIs each run separately on different IP addresses with, potentially, different user authorizations configured, a site can control which users are given access to which classes of End-User UAIs.

[Top: User Access Service (UAS)](index.md)

[Next Topic: List UAIs](List_UAIs.md)
