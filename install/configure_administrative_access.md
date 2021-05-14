# Configure Administrative Access
  
There are several operations which configure administrative access to different parts of the system.
Ensuring that the `cray` CLI can be used by administrative credentials enables use of many management
services via commands.  The management nodes can be locked from accidental manipulation by the
`cray capmc` and `cray fas` commands when then intent is to work on the entire system except the
management nodes.  The `cray scsd` command can change the SSH keys, NTP server, syslog server, and
BMC/controller passwords.

### Topics: 

   1. [Configure Keycloak Account](#configure_keycloak_account)
   1. [Configure the Cray Command Line Interface (cray CLI)](#configure_cray_cli)
   1. [Lock Management Nodes](#lock_management_nodes)
   1. [Configure BMC and Controller Parameters with SCSD](#configure_with_scsd)
   1. [Next Topic](#next-topic)

   Note: The procedures in this section of installation documentation are intended to be done in order, even though the topics are
   administrative or operational procedures.  The topics themselves do not have navigational links to the next topic in the sequence.

## Details

   <a name="configure_keycloak_account"></a>

   1. Configure Keycloak Account

   Upcoming steps in the installation workflow require an account to be configured in Keycloak for
   authentication.  This can be either a local keycloak account or an external Identity Provider (IdP),
   such as LDAP.  Having an account in keycloak with adminstrative credentials enables the use of many
   management services via the `cray` command.

   See [Configure Keycloak Account](../operations/configure_keycloak_account.md)

   <a name="configure_cray_cli"></a>

   1. Configure the Cray Command Line Interface (cray CLI)

   The `cray` command line interface (CLI) is a framework created to integrate all of the system management REST
   APIs into easily usable commands.

   Later procedures in the installation workflow use the `cray` command to interact with multiple services.
   The `cray` CLI configuration needs to be initialized for the Linux account and the keycloak user credentials
   used in initialization running the procedure needs to be authorized for administrative actions.

   See [Configure the Cray Command Line Interface (cray CLI)](../operations/configure_cray_cli.md)

   <a name="lock_management_nodes"></a>

   1. Lock Management Nodes

   The management nodes are unlocked at this point in the installation.  Locking them will prevent actions from FAS to
   update their firmware or CAPMC to power off or do a power reset.  Doing any of these by accident will take down a
   management node.  If the management node is a Kubernetes master or worker node, this can have serious negative effects
   on system operation.

   If a single node is taken down by mistake, it is possible that things will recover. However, if all management
   nodes are taken down, or all Kubernetes worker nodes are taken down by mistake, the system is dead and has to be
   completely restarted.

   Lock the management nodes **now**!

   See [Lock and Unlock Nodes](../operations/lock_and_unlock_nodes.md)

   <a name="configure_with_scsd"></a>

   1. Configure BMC and Controller Parameters with SCSD

   The System Configuration Service (SCSD) allows admins to set various BMC and controller parameters for 
   components in liquid-cooled cabinets.  At this point in the install, SCSD should be used to set the
   SSH key in the node contollers (BMCs) to enable troubleshooting.  If any of the nodes fail to power
   down or power up as part of the compute node booting process, it may be necessary to look at the logs
   on the BMC for node power down or node power up.

   Note: If there are no liquid-cooled cabinets present in the HPE Cray EX system, then this procedure can be skipped.

   See [Configure BMC and Controller Parameters with SCSD](../operations/configure_with_scsd.md)

   <a name="next-topic"></a>
   1. Next Topic

   After completing the operational procedures above which configure administrative access, the next step is to validate the health of management nodes and CSM services.

   See [Validate CSM Health](index.md#validate_csm_health)

