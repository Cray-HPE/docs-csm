# SLS Updates Expert mode

The 1.2 SLS Upgrader aims to make the upgrade of SLS from pre-CMS 1.2 to CSM 1.2 as seamless as possible. However, certain system constraints and subnet sizes quickly necessitate overriding standard input.

* [Key takeaways](#key-takeaways)
* [When to use expert mode](#when-to-use-expert-mode)
* [Minimal input review](#minimal-input-review)
* [Forcing preservation of some existing values](#forcing-preservation-of-some-existing-values)
* [Expert mode: Overriding defaults and forced guiding of upgrades](#expert-mode-overriding-defaults-and-forced-guiding-of-upgrades)
  * [Expert mode: Prerequisites](#expert-mode-prerequisites)
  * [Expert mode: Process](#expert-mode-process)
  * [Expert mode: Example](#expert-mode-example)

## Key takeaways

1. Expert mode requires both an iterative (offline) process and command line override values.
1. The output from the upgrade is a **file**; the configuration is not uploaded live to the system.
1. The output logs from an upgrade run should be reviewed to ensure that input values and upgrader subnetting has the desired effect.

## When to use expert mode

* Both `external-dns` and NCN IP addresses need to be preserved.
* Subnets created by the upgrader are in the wrong order or are too small, or a subnet size and location in a network needs to be enforced.
* Running in non-expert mode generates errors.
* Running in non-expert mode generates warnings for which remediation is desired.

## Minimal input review

The upgrader requires only two inputs:

* SLS input file: This is a file extract of SLS to be upgraded.
* Bifurcated CAN path for non-administrator traffic: Selection of CAN or CHN, depending on whether user traffic (users running jobs, not administrators) will access the system over
  the management network CAN or the highspeed network (CHN).

An example of this would be:

```bash
./sls_updater_csm_1.2.py \
    --sls-input-file sls_input_file.json \
    --bican-user-network-name CAN
```

The above example will use **default values** for all other input values. A list of input parameters and default values can be found by running `./sls_updater_csm_1.2.py --help`.
Likely using default VLAN and network values will not be what is desired: The CAN or CHN are usually site-routable values.

In this case, an example minimal usable input while using CAN could be:

```bash
./sls_updater_csm_1.2.py \
    --sls-input-file sls_input_file.json \
    --bican-user-network-name CAN \
    --customer-access-network <CAN VLAN ID> <CAN NETWORK CIDR>
```

For CHN, the corresponding minimal usable input would be:

```bash
./sls_updater_csm_1.2.py \
        --sls-input-file sls_input_file.json \
        --bican-user-network-name CHN \
        --customer-highspeed-network <CHN VLAN ID> <CHN NETWORK CIDR>
```

## Forcing preservation of some existing values

As part of the upgrade process an existing CAN is migrated to a CSM 1.2 Customer Management Network (CMN). This is because most systems in production use the CAN as an
administrative network. Additionally, system IP addresses shared with the site (external DNS, for example) are administrative IP addresses, and it is often more difficult to
change these IP addresses than it is to make changes in software and avoid operational changes.

To allow some semblance of control over the need to preserve one or more IP addresses (existing CAN, migrated CMN only), the `--preserve-existing-subnet-for-cmn` was introduced.
`--preserve-existing-subnet-for-cmn` has two possible values:

* `external-dns`: This is the IP address by which customer/site DNS lookups to system internal (Kubernetes services) DNS happen. Often changing this **requires** operational change control
  from the site. **NOTE:** Because of this, `--preserve-existing-subnet-for-cmn external-dns` is the most frequent use of this command line flag.
* `ncns`: During the migration of CAN to CMN, all system switches need to be added to a new `network_hardware` subnet inside the CMN. Without guidance, NCN IP addresses for
  the existing CAN (as it is migrated to CMN) will shift to allow room for the new `network_hardware` subnet. Using `--preserve-existing-subnet-for-cmn ncns` will prevent changes to CMN
  NCN IP addresses (managers, workers, and storage only) during the upgrade process.

Note that `external-dns` preservation is mutually exclusive from `ncns`. This is the last "easy button" before full expert mode is required.

For a system desiring the CHN with no change of the `external-dns` value, a very common and recommended next step minimal command line is as follows:

```bash
./sls_updater_csm_1.2.py \
    --sls-input-file sls_input_file.json \
    --bican-user-network-name CHN \
    --customer-highspeed-network <CHN VLAN ID> <CHN NETWORK CIDR> \
    --preserve-existing-subnet-for-cmn external-dns
```

This creates a new CHN and migrates the existing CAN to the new CMN, while maintaining the `external-dns` IP address in the process. Note that this command line would very likely change
existing CAN/CMN addresses on manager, worker, and storage NCNs during the upgrade to CSM 1.2.

**NOTE:** The output of the upgrader is to a file, not the screen. The logged output of the upgrader should be used as a guide and reviewed.

For example, using:

```bash
./sls_updater_csm_1.2.py \
    --sls-input-file sls_input_file.json \
    --bican-user-network-name CAN \
    --customer-access-network 6 10.103.11.128/25 \
    --preserve-existing-subnet-for-cmn external-dns
```

The log output for migration/converting the existing CAN to the new CMN looks like:

```text
    Converting existing CAN network to CMN.
        Attempting to preserve metallb_static pool subnet cmn_metallb_static_pool to pin external-dns IPv4 address
        Creating subnets in the following order ['metallb_static_pool', 'metallb_address_pool', 'network_hardware', 'bootstrap_dhcp']
        Calculating seed/start prefix based on devices in case no further guidance is given
            INFO: Overrides may be provided on the command line with --<can|cmn>-subnet-override.
        Preserving cmn_metallb_static_pool with 10.103.11.60/30
        Remaining subnets: ['10.103.11.64/26', '10.103.11.0/27', '10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']
        Creating cmn_metallb_address_pool with 0 devices:
            A /31 could work and would hold up to 0 devices (including gateway)
            Using 10.103.11.64/26 from 10.103.11.0/25 that can hold up to 62 devices (including gateway)
            Adding gateway IP address
            Adding IPs for 0 Reservations
        Remaining subnets: ['10.103.11.0/27', '10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']
        Subnet network_hardware not found, using HMN as template
        Creating network_hardware with 3 devices:
            A /29 could work and would hold up to 6 devices (including gateway)
            Using 10.103.11.0/27 from 10.103.11.0/25 that can hold up to 30 devices (including gateway)
            Using VLAN 7 to override templating from HMN
            Adding gateway IP address
            Adding IPs for 3 Reservations
        Remaining subnets: ['10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']
        Creating bootstrap_dhcp with 13 devices:
            A /28 could work and would hold up to 14 devices (including gateway)
            Using 10.103.11.32/28 from 10.103.11.0/25 that can hold up to 14 devices (including gateway)
            Adding gateway IP address
            Adding IPs for 13 Reservations
            Setting DHCP Ranges
            WARNING: Insufficient IPv4 addresses to create DHCP ranges - 13 devices in a subnet supporting 14 devices.
                Expert mode --<can|cmn>-subnet-override may be used to change this behavior.
        Remaining subnets: ['10.103.11.48/29', '10.103.11.56/30']
        Applying supernet hack to network_hardware
        Applying supernet hack to bootstrap_dhcp
        Cleaning up remnant CAN switch reservations in bootstrap_dhcp
```

That is quite a bit of output, but some critical points are:

| Output | Interpretation |
| ------ | -------------- |
| `Attempting to preserve metallb_static pool subnet cmn_metallb_static_pool` | This confirms that the upgrader knows that it was asked to preserve the `external-dns` IP address. |
| `['metallb_static_pool', 'metallb_address_pool', 'network_hardware', 'bootstrap_dhcp']` | This is the order in which CAN subnets will be migrated to the CMN. |
| `Remaining subnets: ['10.103.11.0/27', '10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']` | After each subnet is allocated, the remaining subnets available for the next step are listed. |
| `WARNING: Insufficient IPv4 addresses to create DHCP ranges - 13 devices in a subnet supporting 14 devices.` | The `bootstrap_dhcp` subnet (Kubernetes NCNs) is large enough to create the NCNs but NOT large enough to create a DHCP pool effectively. |
| | Technically the SLS file generated by this run will work, but some pool of addresses is likely needed in `bootstrap_dhcp`, so this warning should be remediated. |

## Expert mode: Overriding defaults and forced guiding of upgrades

Due to pre-upgrade subnet sizes or multiple constraints, the "easy" input values might not be sufficient for some systems. This requires "expert mode".

### Expert mode: Prerequisites

* Knowledge of system and site network parameters (IPv4 addresses, subnets, and VLANs).
* The ability to:
  * Create subnets from a given network.
  * Read output subnet values.
  * Based on upgrade output, make an educated decision on how to modify upgrader input values for the next run.
* Slow down, be patient.

### Expert mode: Process

1. Review the existing networks and subnets in the SLS input file.
1. Make an educated guess about how `sls_updater_csm_1.2.py` should work and run the program. A typical first pass is to `--preserve-existing-subnet-for-cmn external-dns`.
1. Review the logged output, noting warnings and errors as well as the location and size of subnets.
    1. Copy the first entry in the log which says `Creating subnets in the following order`.
        1. If `--preserve-existing-subnet-for-cmn external-dns` was used, remove the `metallb_address_pool` from the subnets list.
        1. If `--preserve-existing-subnet-for-cmn external-dns` was used, remove `bootstrap_dhcp` from the subnets list.
    1. Copy the first entry in the log which says `Remaining subnets`. This provides the canonical list from which remaining subnets in the previous entry can be assigned IP addresses.
1. Add override command line values to override the upgrader's default logic and pin subnet allocations for each network. This is a manual step, but is safe
   because the upgrader produced both the list of subnets and the subnet IPAM allocations. Users are simply assigning subnets from a fixed list and a pre-allocated list of IPv4 subnets.
1. Re-run the upgrader with the new parameters.
1. Repeat the process, if necessary.

### Expert mode: Example

Consider the following requirements:

* The user network will be the CHN.
* The `external-dns` IP address must be maintained to avoid operational changes to the site/customer network.
* The upgrade to CSM 1.2 will be a rolling upgrade, not a full outage. In order to prevent race conditions during the rolling upgrade with temporary IP address overlaps,
  preservation of the Kubernetes NCN IP addresses for the CAN (CMN) is required.

The focus of the process that follows will be on the CMN IP address allocations. The same process may be used for the CAN.

#### Process

1. Review of the existing SLS file for CAN shows that NCN addresses are in the range: `10.103.11.2` to `10.103.11.14` with a DHCP pool above this.

1. An educated first pass is to run the updater while preserving the `external-dns` IP address only and look for the CMN output:

    ```bash
    ./sls_updater_csm_1.2.py \
            --sls-input-file sls_input_file.json \
            --bican-user-network-name CHN \
            --customer-highspeed-network 55 172.16.0.0/16 \
            --preserve-existing-subnet-for-cmn external-dns
    ```

    Example log output:

    ```text
    ...snip...
    Converting existing CAN network to CMN.
        Attempting to preserve metallb_static pool subnet cmn_metallb_static_pool to pin external-dns IPv4 address
        Creating subnets in the following order ['metallb_static_pool', 'metallb_address_pool', 'network_hardware', 'bootstrap_dhcp']
        Calculating seed/start prefix based on devices in case no further guidance is given
            INFO: Overrides may be provided on the command line with --<can|cmn>-subnet-override.
        Preserving cmn_metallb_static_pool with 10.103.11.60/30
        Remaining subnets: ['10.103.11.64/26', '10.103.11.0/27', '10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']
    ...snip...
    ```

1. Identify and copy the important log output:

    * `Creating subnets in the following order ['metallb_static_pool', 'metallb_address_pool', 'network_hardware', 'bootstrap_dhcp']`
      * `external-dns` was preserved, so `metallb_static_pool` is removed from the available list.
    * `Remaining subnets: ['10.103.11.64/26', '10.103.11.0/27', '10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']`

1. The task is to map named subnets into IP subnet ranges based on required and desired constraints, and develop `--cmn-subnet-override` parameters from the mapping.

    * Another immediate constraint is to preserve NCN IP addresses for the CAN as it is transformed into the CMN. NCNs are in the `bootstrap_dhcp` subnet and review of SLS data confirms
      that NCNs were previously in a range that fits into the new `Remaining subnet` of `10.103.11.0/27`.
    * Generally another desired constraint is to make the service IP address pool allocated to `metallb_address_pool` as large as possible. After removing NCNs from the previous step, the next
      largest subnet is `10.103.11.64/26`; this will be assigned to `metallb_address_pool`.
    * The best practice at this point is to manually pin the remaining subnets (in this example, only `network_hardware`) to provide a full override. Any remaining IP subnet from the list may be
      used. For the example, this `network_hardware` is pinned to `10.103.11.32/28`.

1. The next run of the upgrader for the example looks like:

    ```bash
    ./sls_updater_csm_1.2.py \
        --sls-input-file sls_input_file.json \
        --bican-user-network-name CHN \
        --customer-highspeed-network 55 172.16.0.0/16 \
        --preserve-existing-subnet-for-cmn external-dns \
        --cmn-subnet-override bootstrap_dhcp 10.103.11.0/27 \
        --cmn-subnet-override cmn_metallb_address_pool 10.103.11.64/26 \
        --cmn-subnet-override network_hardware 10.103.11.32/28
    ```

1. The next run completes successfully and the logs show the following CMN allocations:

    ```text
    Converting existing CAN network to CMN.
        Attempting to preserve metallb_static pool subnet cmn_metallb_static_pool to pin external-dns IPv4 address
        Creating subnets in the following order ['metallb_static_pool', 'metallb_address_pool', 'network_hardware', 'bootstrap_dhcp']
        Calculating seed/start prefix based on devices in case no further guidance is given
            INFO: Overrides may be provided on the command line with --<can|cmn>-subnet-override.
        Preserving cmn_metallb_static_pool with 10.103.11.60/30
        Remaining subnets: ['10.103.11.64/26', '10.103.11.0/27', '10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']
        Subnet cmn_metallb_address_pool was assigned 10.103.11.64/26 from the command command line.
        Creating cmn_metallb_address_pool with 0 devices:
            A /31 could work and would hold up to 0 devices (including gateway)
            Using 10.103.11.64/26 from 10.103.11.0/25 that can hold up to 62 devices (including gateway)
            Adding gateway IP address
            Adding IPs for 0 Reservations
        Remaining subnets: ['10.103.11.0/27', '10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']
        Subnet network_hardware not found, using HMN as template
        Subnet network_hardware was assigned 10.103.11.32/28 from the command command line.
        Creating network_hardware with 3 devices:
            A /29 could work and would hold up to 6 devices (including gateway)
            Using 10.103.11.32/28 from 10.103.11.0/25 that can hold up to 14 devices (including gateway)
            Using VLAN 7 to override templating from HMN
            Adding gateway IP address
            Adding IPs for 3 Reservations
        Remaining subnets: ['10.103.11.0/27', '10.103.11.48/29', '10.103.11.56/30']
        Subnet bootstrap_dhcp was assigned 10.103.11.0/27 from the command command line.
        Creating bootstrap_dhcp with 13 devices:
            A /28 could work and would hold up to 14 devices (including gateway)
            Using 10.103.11.0/27 from 10.103.11.0/25 that can hold up to 30 devices (including gateway)
            Adding gateway IP address
            Adding IPs for 13 Reservations
            Setting DHCP Ranges
        Remaining subnets: ['10.103.11.48/29', '10.103.11.56/30']
        Applying supernet hack to network_hardware
        Applying supernet hack to bootstrap_dhcp
        Cleaning up remnant CAN switch reservations in bootstrap_dhcp
    ```

After review, the allocations for CMN IP addresses in this run are as prescribed. A similar expert override process can be followed if a CAN is desired rather than a CMN.
