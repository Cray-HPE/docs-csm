

## Change Cray EX Cabinet Global Default Password

This procedure changes the global default credential on HPE Cray EX liquid-cooled cabinet embedded controllers (BMCs). The chassis management module (CMM) controller (cC), node controller (nC), and Slingshot switch controller (sC) are generically referred to as "BMCs" in these procedures.  

### Prerequisites

- HPE Cray EX 1.4.2 software is installed and operating.
- The Cray command line interface (CLI) tool is initialized and configured on the system. See "Configure the Cray Command Line Interface (CLI)" in the HPE Cray EX System Administration Guide (1.4) S-8001 for more information.
- Review the procedures in section 8.1 "Manage System Passwords" the *HPE Cray EX System Administration Guide (1.4) S-8001*.

### Procedure

1. Perform procedures in ["Provisioning a Liquid-Cooled EX Cabinet CEC with Default Credentials."](Provisioning_a_Liquid-Cooled_EX_Cabinet_CEC_with_Default_Credentials.md)

2. Perform procedures in ["Updating the Liquid-Cooled EX Cabinet Default Credentials after a CEC Password Change."](Updating_the_Liquid-Cooled_EX_Cabinet_Default_Credentials_after_a_CEC_Password_Change.md) 

3. To update Slingshot switch BMCs, refer to "Change Rosetta Login and Redfish API Credentials" in the *Slingshot Operations Guide* (1.6.0). 

