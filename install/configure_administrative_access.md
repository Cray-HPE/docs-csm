# Configure Administrative Access
  
TODO Add about this task
### About this task

#### Role
System installer

#### Objective

#### Limitations
None.

### Topics: 

   1. [Configure Keycloak Account](#configure_keycloak_account)
   1. [Configure the Cray Command Line Interface (cray CLI)](#configure_cray_cli)
   1. [Lock Management Nodes](#lock_management_nodes)
   1. [Configure BMC and Controller Parameters with SCSD](#configure_with_scsd)

   Note: The procedures in this section of installation documentation are intended to be done in order, even though the topics are
   administrative or operational procedures.  The topics themselves do not have navigational links to the next topic in the sequence.

## Details

   <a name="configure_keycloak_account"></a>

   1. Configure Keycloak Account

   Upcoming steps in the installation workflow require an account to be configured in Keycloak for authentication.  This can be either a local keycloak account or an external Identity Provider (IdP), such as LDAP.

   See [Configure Keycloak Account](../operations/configure_keycloak_account.md)

   <a name="configure_cray_cli"></a>

   1. Configure the Cray Command Line Interface (cray CLI)

   TODO description of cray CLI and its usefulness for upcoming commands. 

   See [Configure the Cray Command Line Interface (cray CLI)](../operations/configure_cray_cli.md)

   <a name="lock_management_nodes"></a>

   1. Lock Management Nodes

   The management nodes are unlocked at this point in the installation.  Locking them will prevent actions from FAS to
   update their firmware or CAPMC to power off or do a power reset.  Doing any of these by accident will take down an
   management node.  If the management node is a Kubernetes master or worker node, this can have serious negative effects
   on system operation.

   If a single node is taken down by mistake, it is possible that things will recover. However, if all management
   nodes are taken down, or all Kubernetes worker nodes are taken down
   by mistake, the system is dead and has to be completely restarted.

   Lock the management nodes **now** using the procedure in [Lock and Unlock Nodes](../operations/lock_and_unlock_nodes.md)

   <a name="configure_with_scsd"></a>

   1. Configure BMC and Controller Parameters with SCSD

   TODO description of SCSD to enable passwordless access to the Mountain node BMCs which might be needed for debugging of the power up or power down as part of the compute node booting process.

   See [Configure BMC and Controller Parameters with SCSD](../operations/configure_with_scsd.md)

<a name="next-topic"></a>
# Next topic

   After completing this procedure, the next step is to validate the health of management nodes and CSM services.

   * See [Validate CSM Health](index.md#validate_csm_health)

