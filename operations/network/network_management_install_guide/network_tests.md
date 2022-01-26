### Network tests

Canu has the ability to run tests against the management network.  (Aruba Only)

Canu has to be on version `1.1.4` or later. run `canu --version` to verify.

The switch inventory is dynamically created from either an sls file `--sls-file` or it will automatically query the sls API if an sls file is not specified.

Tests are found here https://github.com/Cray-HPE/canu/blob/main/canu/test/aruba/test_suite.yaml and more documentation can be found at https://github.com/Cray-HPE/canu/tree/main#test-the-network


##### Examples
- Pulling switch inventory from SLS and logging to screen, this requires the API gateway to be up.
`ncn-w001:~ # canu test --log`

- Pulling switch inventory from sls file and connecting to the switches via their CMN IPs, this can be done outside the shasta cluster.
`ncn-w001:~ # canu test --sls-file ../Hela/sls_input_file.json --network CMN`

- Pulling switch inventory from SLS and having the output be in json format.
`ncn-w001:~ # canu test --json`

Running the tests can take some time if there are a lot of management switches.

Here's a snippet of what the output will look like.

```
+----+-----------------+----------------------------------------------+----------+----------------------+
| 46 | sw-spine-002    | Software version test                        | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 47 | sw-spine-002    | lacp interfaces test                         | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 48 | sw-spine-002    | Interface error check                        | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 49 | sw-spine-002    | running-config different from startup-config | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 50 | sw-spine-002    | STP check for blocked ports                  | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 51 | sw-spine-002    | CPU Utilization over 70%                     | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 52 | sw-spine-002    | Memory Utilization over 70%                  | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 53 | sw-spine-002    | vlan 1 ip-helper test                        | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 54 | sw-spine-002    | vlan 2 ip-helper test                        | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 55 | sw-spine-002    | vlan 4 ip-helper test                        | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 56 | sw-spine-002    | vlan 7 ip-helper test                        | FAIL     | IP-Helper is missing |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 57 | sw-spine-002    | tftp route                                   | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 58 | sw-spine-002    | BGP Test                                     | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 59 | sw-spine-002    | STP check for root bridge spine              | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 60 | sw-leaf-bmc-001 | Software version test                        | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 61 | sw-leaf-bmc-001 | lacp interfaces test                         | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 62 | sw-leaf-bmc-001 | Interface error check                        | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 63 | sw-leaf-bmc-001 | running-config different from startup-config | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 64 | sw-leaf-bmc-001 | STP check for blocked ports                  | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 65 | sw-leaf-bmc-001 | CPU Utilization over 70%                     | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 66 | sw-leaf-bmc-001 | Memory Utilization over 70%                  | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
| 67 | sw-leaf-bmc-001 | STP check for root bridge leaf               | PASS     |                      |
+----+-----------------+----------------------------------------------+----------+----------------------+
```