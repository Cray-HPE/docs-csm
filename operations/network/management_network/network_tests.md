# Network Tests

The CSM Automatic Network Utility (CANU) has the ability to run tests against the management network.

If doing a CSM install or upgrade, a CANU RPM is located in the release tarball. For more information, refer to the
[Update CANU From CSM Tarball](canu/update_canu_from_csm_tarball.md) procedure.

The switch inventory is dynamically created from either a System Layout Service (SLS) file `--sls-file`, or it will
automatically query the SLS API if an SLS file is not specified.

See also:

* [CANU Aruba test suite](https://github.com/Cray-HPE/canu/blob/main/canu/test/aruba/test_suite.yaml)
* [Test The Network with CANU](https://github.com/Cray-HPE/canu/tree/main#test-the-network)

## Prerequisites

* SSH access to the switches
* SLS file or SLS API access
* CANU has to be on version `1.1.4` or later; run `canu --version` to verify

## Examples

* Pulling switch inventory from SLS and logging to screen, this requires the API gateway to be up.

    ```bash
    ncn# canu test --log
    ```

* Pulling switch inventory from SLS file and connecting to the switches via their CMN IP addresses, this can be done outside the Shasta cluster.

    ```bash
    ncn# canu test --sls-file ../Hela/sls_input_file.json --network CMN
    ```

* Pulling switch inventory from SLS and having the output be in JSON format.

    ```bash
    ncn# canu test --json
    ```

Running the tests can take some time if there are a lot of management switches.

The output will look similar to the following:

```text
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
