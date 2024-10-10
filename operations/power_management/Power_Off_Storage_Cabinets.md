# Power Off Storage Cabinets

Power off storage nodes and management switches in standard racks.

## Power off standard rack PDU circuit breakers

**CAUTION:** The Lustre or Spectrum Scale (GPFS) file systems on nodes and switches in storage cabinets should only
be powered off when it has been confirmed that the file systems have been cleanly shut down. See the procedures in
[Power Off the External File Systems](System_Power_Off_Procedures.md#Power_off_the_External_File_systems).

1. Set each cabinet PDU circuit breaker to `OFF`.

    A slotted screwdriver may be required to open PDU circuit breakers.

1. To power off Motivair liquid-cooled chilled doors and CDUs, locate the power off switch on the CDU control panel and set it to `OFF`.

    Refer to vendor documentation for the chilled-door cooling system for power control procedures when chilled doors are installed on standard racks.

## Next step

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
