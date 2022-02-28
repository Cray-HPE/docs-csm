# Mellanox lacp-individual limitations

## Description

In some failover/maintenance scenarios admins may want to shutdown one port of the bond on an NCN.  Due to the way Mellanox handles `lacp-individual` mode the ports need to be shutdown from the switch instead of the NCN.

## Fix

Shut down the port on the switch instead of the NCN.
