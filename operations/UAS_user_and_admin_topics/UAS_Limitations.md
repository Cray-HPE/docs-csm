---
category: numbered
---

# UAS Limitations

Functionality that is currently not supported while using UAS.

## Functionality Not Currently Supported by the User Access Service

-   Lustre \(lfs\) commands within the UAS service pod
-   Executing Singularity containers within the UAS service
-   Building Docker containers within the UAS environment
-   Building containerd containers within the UAS environment
-   `dmesg` cannot run inside a UAI due to container security limitations
-   Users cannot ssh from `ncn-w001` to a UAI. This is because UAIs use LoadBalancer IPs on the Customer Access Network \(CAN\) instead of NodePorts and the LoadBalancer IPs are not accessible from `ncn-w001`.

## Other Limitations

-   There is a known issue where X11 traffic may not forward DISPLAY correctly if the user logs into an NCN node before logging into a UAI.
-   The cray uas uais commands are not restricted to the user authenticated with cray auth login.

## Limitations Related To Restarts

Changes made to a running UAI will be lost if the UAI is restarted or deleted. The only changes in a UAI that will persist are those written to an externally mounted file system \(such as Lustre or NFS\). To make changes to the base image for a UAI, see [Create and Register a Custom UAI Image](Create_and_Register_a_Custom_UAI_Image.md#).

A UAI may restart due to an issue on the physical node, scheduled node maintenance, or intentional restarts by a site administrator. In this case, any running processes \(such as compiles\), Slurm interactive jobs, or changes made to the UAI \(such as package installations\) are lost.

If a UAI restarts on a node that was recently rebooted, some of the configured volumes may not be ready and it could appear that content in the UAI is missing. In this case, restart the UAI.

**Parent topic:**[User Access Service \(UAS\)](User_Access_Service_UAS.md)

