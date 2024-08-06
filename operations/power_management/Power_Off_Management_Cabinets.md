# Power Off Management Cabinets

Power off PDUs and any remaining components in management cabinets which are powered on, such as Slingshot switches, management switches, and a KVM device.

## Power Off Management Cabinet PDU circuit breakers

**CAUTION:** The nodes and switches in management cabinets should only
be powered off once it has been confirmed that the management Kuberenets cluster and any Lustre or Spectrum Scale filesystems in the cabinets have been cleanly shut down. See the procedures in
[Power Off the External File Systems](System_Power_Off_Procedures.md#Power_off_the_External_File_systems.md)
and 
[Shut Down and Power Off the Management Kubernetes Cluster](file:///Users/htg/git/shasta/20240717/docs-csm-1.4/operations/power_management/Shut_Down_and_Power_Off_the_Management_Kubernetes_Cluster.md).

1. (Optional) Power down Modular coolant distribution unit (MDCU) in a liquid-cooled HPE Cray EX2000 cabinet.

   CAUTION: The modular coolant distribution unit (MDCU) in a liquid-cooled HPE Cray EX2000 cabinet (also referred to as a Hill or TDS cabinet) typically receives power from its management cabinet PDUs. If the system includes an EX2000 cabinet, then do not power off the management cabinet PDUs until the MDCU has been powered off. Powering off the MDCU will cause an emergency power off (EPO) of the cabinet and may result in data loss or equipment damage.

1. Set each management cabinet PDU circuit breaker to `OFF`.

   A slotted screwdriver may be required to open PDU circuit breakers.

1. To power off Motivair liquid-cooled chilled doors and CDUs, locate the power off switch on the CDU control panel and set it to `OFF`.

    Refer to vendor documentation for the chilled-door cooling system for power control procedures when chilled doors are installed on standard racks.

## Next step

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
