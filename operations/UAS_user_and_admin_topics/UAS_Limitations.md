# UAS Limitations

Functionality that is currently not supported while using UAS.

## Functionality Not Currently Supported by the User Access Service

* Lustre (`lfs`) commands within the UAS service pod
* Executing Singularity containers within the UAS service
* Building Docker containers within the UAS environment
* Building `containerd` containers within the UAS environment
* `dmesg` cannot run inside a UAI because of container security limitations
* Users cannot SSH from `ncn-w001` to a UAI because UAIs use `LoadBalancer` IP addresses on the Customer Access Network \(CAN\) instead of `NodePorts` and the `LoadBalancer` IP addresses are not accessible from `ncn-w001`

## Other Limitations

* There is a known issue where X11 traffic may not forward DISPLAY correctly if the user logs into an NCN node before logging into a UAI
* The `cray uas uais` commands are not restricted to operating on UAIs owned by the user authenticated with `cray auth login`

## Limitations Related To Restarts

Changes made to a running UAI will be lost if the UAI is restarted or deleted. The only changes in a UAI that will persist are those written to an externally mounted file system \(such as Lustre or NFS\).
To make changes to the base image for a UAI, see [Customize End-User UAI Images](Customize_End-User_UAI_Images.md).

A UAI may restart because of an issue on the physical node, scheduled node maintenance, or intentional restarts by a site administrator.
In this case, any running processes \(such as compiles\), Slurm interactive jobs, or changes made to the UAI \(such as package installations\) are lost.
A UAI may also terminate and have to be restarted if its `hard` timeout is reached while a user is logged in or if its `soft` timeout is reached while it is idle -- defined as having no logged in user sessions -- or before it becomes idle.

If a UAI restarts on a node that was recently rebooted, some of the configured volumes may not be ready and it could appear that content in the UAI is missing. In this case, restart the UAI.

[Top: User Access Service (UAS)](index.md)

[Next Topic: List UAS Version Information](List_UAS_Information.md)
