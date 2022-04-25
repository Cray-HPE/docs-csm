# SLS Updates Expert Mode

The 1.2 SLS Upgrader aims to make the upgrade of SLS from pre-CMS 1.2 to CSM 1.2 as seamless as possible.  However, certain system constraints and subnet sizes quickly necessitate overriding standard input.

***Key Takeaways***

1. *EXPERT MODE:* requires both an iterative (offline) process and command line override values.
2. The output from the upgrade is a *file*, not uploaded live to the system.
3. The output logs from an upgrade run should be reviewed to ensure that input values and upgrader subnetting has the desired effect.

***When to use Expert Mode***

* Both external-dns and ncn IPs need to be preserved.
* Subnets created by the upgrader are in the wrong order, too small or a subnet size and location in a network needs to be enforced.
* Running in non-expert mode generates errors.
* Running in non-expert mode generates warnings for which remediation is desired.

## Simple/Minimal Input Review

At a minimum the upgrader requires only two inputs:

* SLS input file:  This is a file extract of SLS to be upgraded.
* Bifurcated CAN path for non-administrator traffic: Selection of CAN or CHN depending on whether User traffic (users running jobs, not administrators) will access the system over the management network CAN or the highspeed network (CHN).

An example of this would be:

```bash
./sls_updater_csm_1.2.py \
    --sls-input-file sls_input_file.json \
    --bican-user-network-name CAN
```

The above example will use *default values* for all other input values.  A list of input parameters and default values can be found by running `./sls_updater_csm_1.2.py --help`.  Likely using default VLAN and Network values will not be what's desired:  The CAN or CHN are usually site-routable values.

In this case an example minimal usable input while using CAN, would be:

```bash
./sls_updater_csm_1.2.py \
    --sls-input-file sls_input_file.json \
    --bican-user-network-name CAN \
    --customer-access-network <CAN VLAN ID> <CAN NETORK CIDR>
```

For CHN the analog minimal usable input would be:

```bash
./sls_updater_csm_1.2.py \
    --sls-input-file sls_input_file.json \
    --bican-user-network-name CHN \
    --customer-highspeed-network <CHN VLAN ID> <CHN NETWORK CIDR>
```

## Forcing Preservation of (some) Existing Values

As part of the upgrade process an exist CAN is migrated to a CSM 1.2 Customer Management Network (CMN).  The reasoning behind this was that most systems in production currently use the CAN as an administrative network.  Additionally, and more operationally important, system IPs shared with the site (External DNS for instance) are administrative IPs and it's often more difficult to change these IP's than to make changes in software and avoid operational changes.

To allow some semblance of control over the need to preserve one or more IPs (existing CAN, migrated CMN only), the `--preserve-existing-subnet-for-cmn` was introduced.  `--preserve-existing-subnet-for-cmn` has two possible values:

* external-dns:  This is the IP by which customer/site DNS lookups to system internal (K8S services) DNS happen.  Often changing this *requires* operational change control from the site.  *NOTE:  `--preserve-existing-subnet-for-cmn external-dns` is the most frequent use of this command line flag.*
* ncns:  During the migration of CAN to CMN, all system switches need to be added to a (new) network_hardware subnet inside the CMN Network.  Without guidance NCN IPs for the existing CAN (as it's migrated to CMN) will shift to allow the new network_hardware subnet.  Using `--preserve-existing-subnet-for-cmn ncns` will prevent changes to CMN NCN IPs (note: managers, workers and stoage only) during the upgrade process.

Note that `external-dns` preservation is mutually exclusive from `ncns`.  This is the last *easy button* before full "expert" mode is required.

A very common (and recommended) next step minimal command line is as follows for a system desiring the CHN with no change of the external-dns value is:

```bash
./sls_updater_csm_1.2.py \
    --sls-input-file sls_input_file.json \
    --bican-user-network-name CHN \
    --customer-highspeed-network <CHN VLAN ID> <CHN NETWORK CIDR> \
    --preserve-existing-subnet-for-cmn external-dns
```

This would create a new CHN and migrate the existing CAN to the new CMN while maintaining the external-dns IP address in the process.  Note that this command line would very likely change existing CAN/CMN addresses on manager, worker and storage K8S NCNs during the upgrade to CSM 1.2.

**NOTE:  The output of the upgrader is to a file, not the live system.  Additionally, the logged output of the upgrader should be used as a guide and reviewed.**

For example, using:

```bash
./sls_updater_csm_1.2.py --sls-input-file sls_input_file.json --bican-user-network-name CAN --customer-access-network 6 10.103.11.128/25 --preserve-existing-subnet-for-cmn external-dns
```

The log output for migration/converting the existing CAN to the new CMN looks like:

```bash
    Converting existing CAN network to CMN.
        Attempting to preserve metallb_static pool subnet cmn_metallb_static_pool to pin external-dns IPv4 address
        Creating subnets in the following order ['metallb_static_pool', 'metallb_address_pool', 'network_hardware', 'bootstrap_dhcp']
        Calculating seed/start prefix based on devices in case no further guidance is given
            INFO:  Overrides may be provided on the command line with --<can|cmn>-subnet-override.
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
        Cleaning up remnant CAN switch reservations in boostrap_dhcp
```

That is quite a bit of output, but some critical points are:

* The upgrader indeed knows that we have asked to preserve the external-dns IP and is `Attempting to preserve metallb_static pool subnet cmn_metallb_static_pool`.
* The order in which CAN subnets will be migrated to the CMN is: `['metallb_static_pool', 'metallb_address_pool', 'network_hardware', 'bootstrap_dhcp']`.
* After each subnet is allocated the remaining subnets available (for the next step) are listed. E.g. `Remaining subnets: ['10.103.11.0/27', '10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']`.
* The bootstrap_dhcp subnet (K8S NCNs) is large enough to create the NCNs but NOT large enough to create a DHCP pool effectively: `WARNING: Insufficient IPv4 addresses to create DHCP ranges - 13 devices in a subnet supporting 14 devices.`  Technically the SLS file generated by this run will work, but a system or network administrator will likely need some pool of addresses in bootstrap_dhcp and this waring should be remediated.

## Expert Mode:  Overriding Defaults and Forced Guiding of Upgrades

As might be observed from the above example, due to pre-uprade subnet sizes, or multiple constraints, the "easy" input values might not be sufficient for some systems.  This requires *expert mode*.

### Expert Mode Prerequisites

* Knowledge of system and site network parameters (IPv4 addresses and subnets as well as VLANs).
* The ability to create subnets from a given network, or ability to read output subnet values, make an educated decision and modify upgrader input values for the next run.
* Slow down, be patient.

### Expert Mode Process

1. Review the existing networks and subnets in the SLS input file.
2. Make an educated guess about how `sls_updater_csm_1.2.py` should work and run the program.  A typical first pass is to `--preserve-existing-subnet-for-cmn external-dns`.
3. Review the logged output, noting warnings and errors as well as the location and size of subnets.
    1. Copy the first entry in the log which says `Creating subnets in the following order`.
        1. If `--preserve-existing-subnet-for-cmn external-dns` was used, remove the metallb_address_pool from the subnets list.
        2. If `--preserve-existing-subnet-for-cmn external-dns` was used, remove bootstrap_dhcp from the subnets list.
    2. Copy the first entry in the log which says `Remaining subnets`.  This provides the canonical list from which remaining subnets in the previous entry can be assigned IP addresses.
4. Add override command line values to override the upgrader's default logic and pin subnet allocations for each network.  This is a manual step, but is safe because the upgrader produced both the list of subnets and the subnet IPAM allocations.  Users are simply assigning subnets from a fixed list and a pre-allocated list of IPv4 subnets.
5. Re-run the upgrader with the new parameters.
6. Repeat the process, if necessary.

### Example

For this example of expert mode a very common use case is used with the following requirements:

1. The user network will be the CHN.
2. The external-dns IP must be maintained to avoid operational changes to the site/customer network.
3. The upgrade to CSM 1.2 will be a rolling upgrade, not a full outage.  To prevent race conditions during the rolling upgrade with temporary IP overlaps, preservation of the K8S NCN IPs for CAN (CMN) are required.

The focus of the process that follows will be on the CMN IP allocations.  The same process may be used for the CAN.

**Process:**

1. Review of the existing SLS file for CAN shows that NCN addresses are in the range: `10.103.11.2` to `10.103.11.14` with a DHCP Pool above this.
2. An educated first pass is to run the updater while preserving the external-dns IP only and look for the CMN output:

```bash
./sls_updater_csm_1.2.py \
    --sls-input-file sls_input_file.json \
    --bican-user-network-name CHN \
    --customer-highspeed-network 55 172.16.0.0/16 \
    --preserve-existing-subnet-for-cmn external-dns
```

```bash
...snip...
Converting existing CAN network to CMN.
    Attempting to preserve metallb_static pool subnet cmn_metallb_static_pool to pin external-dns IPv4 address
    Creating subnets in the following order ['metallb_static_pool', 'metallb_address_pool', 'network_hardware', 'bootstrap_dhcp']
    Calculating seed/start prefix based on devices in case no further guidance is given
        INFO:  Overrides may be provided on the command line with --<can|cmn>-subnet-override.
    Preserving cmn_metallb_static_pool with 10.103.11.60/30
    Remaining subnets: ['10.103.11.64/26', '10.103.11.0/27', '10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']
...snip...
```

3. Identify and copy the important log output:
    1. `Creating subnets in the following order ['metallb_static_pool', 'metallb_address_pool', 'network_hardware', 'bootstrap_dhcp']`
        1. external-dns was preserved so metallb_static_pool is removed from the available list.
    2. `Remaining subnets: ['10.103.11.64/26', '10.103.11.0/27', '10.103.11.32/28', '10.103.11.48/29', '10.103.11.56/30']`
4. The user task is to map named subnets into IP subnet ranges based on required and desired constraints and develop `--cmn-subnet-override` parameters from the mapping.
    1. Another immediate constraint is to preserve NCN IP addresses for CAN as it's transformed into the CMN.  NCNs are in the `boostrap_dhcp` subnet and review of SLS data confirms that NCNs were previously in a range that fits into the new "Remaining subnet" of `10.103.11.0/27`.
    2. Generally another desired constraint is to make the service IP pool allocated to `metallb_address_pool` as large as possible.  After removing NCNs from the previous step, the next largest subnet is `10.103.11.64/26` and this will be assigned to `metallb_address_pool`.
    3. The best practice from at this point is to also manually pin the remaining subnets, here only `network_hardware` to provide a fully determinate override.  This could be any remaining IP subnet from the list and for the example this becomes `10.103.11.32/28`.
    4. Take a deep breath and assemble the new command line with overrides.
5. The next run of the upgrader for the example looks like:

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

6. The next run completes successfully and the logs show the following CMN allocations:

```bash
Converting existing CAN network to CMN.
    Attempting to preserve metallb_static pool subnet cmn_metallb_static_pool to pin external-dns IPv4 address
    Creating subnets in the following order ['metallb_static_pool', 'metallb_address_pool', 'network_hardware', 'bootstrap_dhcp']
    Calculating seed/start prefix based on devices in case no further guidance is given
        INFO:  Overrides may be provided on the command line with --<can|cmn>-subnet-override.
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
    Cleaning up remnant CAN switch reservations in boostrap_dhcp
```

After review, the allocations for CMN IPs in this run are as precribed.  A similar expert override process can be followed if a CAN is desired rather than a CMN.

This has been a review of the process of using *expert mode* in the 1.2 SLS upgrader.  The focus has been on IP allocation of the CMN network.  A very similar process can be used if the CAN network is desired (instead of a CHN).

**WARNING:** During design and implementation of the SLS upgrader all attempts were made to safely and accurately migrate and update SLS data.
