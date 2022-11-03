# Broker Mode UAI Management

A UAI broker is a special kind of UAI whose job is not to host users directly but to field attempts to reach a UAI, locate or create a UAI for the user making the attempt, and then pass the connection on to the correct UAI. Multiple UAI brokers can be created, each serving a UAI of a different class, making it possible to set up UAIs for varying workflows and environments as needed. The following illustrates a system using the UAI broker mode of UAI management:

![UAS Broker Mode](../../img/uas_broker_mode.svg)

Unlike in the legacy model, in this model users log into their UAIs through the UAI broker. After that, each user is assigned an end-user UAI by the broker and the SSH session is forwarded to the end-user UAI. This is seamless from the user's perspective, as the SSH session is carried through the UAI broker and into the end-user UAI.

To make all of this work, the administrator must define at least one UAI class containing the configuration for the end-user UAIs to be created by the UAI broker and one UAI class containing the UAI broker configuration itself. The UAI broker should be configured by the site to permit authentication of users. Refer to the example in [Configure a Broker UAI Class](Configure_a_Broker_UAI_Class.md) for more information. This can be carried out using volumes to place configuration files as needed in the file system namespace of the broker UAI. Finally, once all of this is prepared, the administrator launches the broker UAI, and makes the IP address of the broker UAI available for users to log into.
