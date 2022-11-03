# ConMan

ConMan is a tool used for connecting to remote consoles and collecting console logs. These node logs can then be used for various administrative purposes, such as troubleshooting node boot issues.

ConMan runs on the system as a containerized service. It runs in a set of Docker containers within Kubernetes pods named `cray-console-operator` and `cray-console-node`.
Node console logs are stored locally within the `cray-console-node` pods in the `/var/log/conman/` directory, as well as being collected by the System Monitoring Framework \(SMF\).

In CSM versions 1.0 and later, the ConMan logs and interactive consoles are accessible through one of the `cray-console-node` pods.
There are multiple `cray-console-node` pods, scaled to the size of the system.

## How to use

- [Log in to a Node Using ConMan](Log_in_to_a_Node_Using_ConMan.md)
- [Access Compute Node Logs](Access_Compute_Node_Logs.md)
- [Manage Node Consoles](Manage_Node_Consoles.md)
- [Establish a Serial Connection to an NCN](Establish_a_Serial_Connection_to_NCNs.md)
- [Disable ConMan After System Software Installation](Disable_ConMan_After_System_Software_Installation.md)
- [Access Console Log Data Via the System Monitoring Framework (SMF)](Access_Console_Log_Data_Via_the_System_Monitoring_Framework_SMF.md)

## Troubleshooting

- [Troubleshoot ConMan Asking for Password on SSH Connection](Troubleshoot_ConMan_Asking_for_Password_on_SSH_Connection.md)
- [Troubleshoot ConMan Blocking Access to a Node BMC](Troubleshoot_ConMan_Blocking_Access_to_a_Node_BMC.md)
- [Troubleshoot ConMan Failing to Connect to a Console](Troubleshoot_ConMan_Failing_to_Connect_to_a_Console.md)
- [Troubleshoot ConMan Node Pod Stuck in Terminating](Troubleshoot_ConMan_Node_Pod_Stuck_Terminating.md)
