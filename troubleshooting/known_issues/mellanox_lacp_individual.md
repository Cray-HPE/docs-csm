# Mellanox lacp-individual limitations

- Limitation

If you shut down a port while on an NCN via `ip link set dev mgmt0 down` and have lacp-individual running on either one or both the MLAG ports on a mellanox MLAG pair you will lose connection to that NCN.

- Workaround

Shut down the port on the switch instead of the NCN.