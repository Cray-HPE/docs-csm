# Broker Mode UAI Management

A Broker UAI is a special kind of UAI whose job is not to host users directly but to accept attempts to reach a UAI, locate or create a UAI for the user making the attempt, and then pass the user's connection on to the correct UAI.
Multiple Broker UAIs can be created, each serving users with UAIs of a different classes. This makes it possible to set up UAIs for varying workflows and environments as needed. The following illustrates a system using the Broker mode of UAI management:

![UAS Broker Mode](../../img/uas_broker_mode.svg)

Unlike in the [Legacy Mode](Legacy_Mode_User-Driven_UAI_Management.md), in the Broker Mode users log into their UAIs through the Broker UAI.
The logic in the Broker UAI authenticates the user and assigns the user an [End-User UAI](End_User_UAIs.md). The Broker UAI then forwards the SSH session to the End-User UAI.
This is seamless from the user's perspective, as the SSH session is carried through the Broker UAI and into the End-User UAI.

To make all of this work, the administrator must define at least one [UAI Class](UAI_Classes.md) containing the configuration for the End-User UAIs to be created by the Broker UAI and one UAI class containing the Broker UAI configuration itself.
The Broker UAI should be configured by the site to permit authentication of users. Refer to the example in [Configure a Broker UAI Class](Configure_a_Broker_UAI_Class.md) for more information.
The necessary Broker UAI customization can be achieved using [volumes](Volumes.md) to place configuration files as needed in the file system namespace of the Broker UAI.
Finally, once all of this is prepared, the administrator launches the Broker UAI, and makes the IP address of the Broker UAI available for users to log into.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Configure End-User UAI Classes for Broker Mode](Configure_End-User_UAI_Classes_for_Broker_Mode.md)
