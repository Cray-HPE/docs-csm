# Mellanox `lacp-individual` Limitations

## Description

In some failover/maintenance scenarios, administrators may want to shut down one port of the bond on an NCN.
Because of the way Mellanox handles `lacp-individual` mode, the ports need to be shut down from the switch instead of the NCN.

## Fix

Shut down the port on the switch instead of the NCN.
