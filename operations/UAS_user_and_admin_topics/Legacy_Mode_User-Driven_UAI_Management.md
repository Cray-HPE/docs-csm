# Legacy Mode User-Driven UAI Management

In the legacy mode, users create and manage their own UAIs through the Cray CLI. A user may create, list, and delete only UAIs owned by the user.
The user may not create a UAI for another user, nor may the user see or delete UAIs owned by another user.
Once created, the information describing the UAI gives the user the information needed to reach the UAI using SSH and log into it.

The following diagram illustrates a system running with UAIs created in the legacy mode by four users, each of whom has created at least one End-User UAI. Notice that the example user Pat has created two End-User UAIs:

![UAS Legacy Mode](../../img/uas_legacy_mode.svg)

In the simplest UAS configuration, there is some number of UAI images available for use in legacy mode and there is a set of volumes defined.
In this configuration, when a UAI is created, the user may specify the UAI image to use as an option when creating the UAI, or may allow a default UAI image, if one is assigned, to be used.
Every volume defined at the time the UAI is created will be mounted unconditionally in every newly created UAI if this approach is used.
This can lead to problems with conflicting volume mount points (see [Troubleshoot Duplicate Mount Paths in a UAI](Troubleshoot_Duplicate_Mount_Paths_in_a_UAI.md))
and unresolvable volumes (see [Troubleshoot UAI Stuck in `ContainerCreating`](Troubleshoot_UAI_Stuck_in_ContainerCreating.md)) in some configurations of UAS.
Unless UAI classes are used to make UAIs, care must be taken to ensure all volumes have unique mount-path settings and are accessible in the `user` Kubernetes namespace.

## The Benefits of Using UAI Classes with Legacy Mode

A slightly more sophisticated configuration approach defines a default [UAI Class](UAI_Classes.md) that is always used by legacy mode UAI creation.
When this approach is taken, the user can no longer specify the image to use, as it will be supplied by the UAI class, and the volumes mounted in any UAI created in legacy mode will be based on the specified UAI class.
As long as volumes do not conflict within the list of volumes in a given UAI class, there is no need to avoid duplicate mount-path settings in the global list of volumes when this approach is used.
All other configuration in the default UAI Class will also be applied to all new legacy mode UAIs, so, for example, a site can place timeouts or resource specifications on UAIs by defining them in the default UAI Class.

The [UAI Classes](UAI_Classes.md) section provides information on what might go in an End-User UAI Class and what should specifically go in the Non-Brokered UAI Class used in legacy mode.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Configure A Default UAI Class for Legacy Mode](Configure_a_Default_UAI_Class_for_Legacy_Mode.md)
