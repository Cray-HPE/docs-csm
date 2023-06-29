# QLogic driver crash

- [Description](#description)
  - [Signatures](#signatures)
    - [Driver Recovery](#driver-recovery)
    - [Kernel Crash](#kernel-crash)
- [Workaround](#workaround)
- [Fix](#fix)

## Description

In some failover/maintenance scenarios users may experience QLogic driver crash with the following symptoms:

- Sudden loss of connectivity, `mgmt0` and/or `mgmt1` will lose connectivity and the bond will fail.
- Kernel crashing

This is known to be a result of network events, such as a reboot of a switch in the VSX pair, or a sudden flood of
packets due to CEPH recovery. However this can also occur without user intervention in rare cases.

The issue is aggravated by a flaw in the configuration for the storage node back-channel links, and per internal testing
correcting the configuration on the switch significantly reduces the risk of running into this issue.

The configuration is fixed in CANU versions 2.3 and above.

### Signatures

All of the signatures of the crash may be observed through `dmesg`. It is advised if one wants to monitor for the crash
that they run `dmesg -W` in a serial console to monitor live, new messages and to look for the following signatures
listed below.

#### Driver Recovery

The QLogic driver will start a recovery flow after a transmit queue timeout when the firmware crashes, the driver is
attempting to recover from the firmware crash. The following messages may be seen in `dmesg`:

```text
[71980.321853] NETDEV WATCHDOG: mgmt0 (qede): transmit queue 0 timed out
[71980.321864] [qede_tx_timeout:529(mgmt1)]TX timeout on queue 2!
```

```text
watchdog: BUG: soft lockup - CPU#10 stuck for 26s! [tp_osd_tp:11370]
```

To look for these, use:

```bash
dmesg | grep -i 'timeout' | grep qed
```

```bash
dmesg | grep -i 'soft lockup'
```

#### Kernel Crash

In cases where the inbox SLES driver is used (provided by the Kernel), a Kernel crash may be observed and a dump will be
created.

```text
[72201.473386] CPU: 28 PID: 1380762 Comm: sadc Kdump: loaded Tainted: G        W           5.14.21-150400.24.38.1.25440.1.PTF.1204911-default #1 SLE15-SP4 a183b387d1d6082da7a867507e6a04161f95b2be
[72201.491487] Hardware name: HPE ProLiant DL325 Gen10 Plus/ProLiant DL325 Gen10 Plus, BIOS A43 11/17/2022
[72201.501809] RIP: 0010:qed_get_current_link+0x11/0xe0 [qed]
[72201.508225] Code: 48 81 c7 d0 00 00 00 e8 f8 c1 e8 e6 e9 d7 fe ff ff e8 43 18 e9 e6 0f 1f 00 0f 1f 44 00 00 41 55 41 54 49 89 fc 55 53 48 89 f5 <80> bf 54 43 00 00 00 48 8d 9f 90 00 00 00 75 3f 48 89 df e8 f7 f9
[72201.527984] RSP: 0018:ffffb4e18a3dfba8 EFLAGS: 00010246
[72201.534113] RAX: ffffffffc09a6810 RBX: ffffb4e18a3dfc68 RCX: 0000000000000000
[72201.542163] RDX: ffff9cbae6868000 RSI: ffffb4e18a3dfbd0 RDI: 0000000000000000
[72201.550212] RBP: ffffb4e18a3dfbd0 R08: ffff9cbae6868000 R09: ffff9ca69e9e1a40
[72201.558262] R10: ffffb4e18a3dfc68 R11: 0000000000000000 R12: 0000000000000000
[72201.566311] R13: ffff9ca4caa90940 R14: 0000000000000001 R15: 0000000000000001
[72201.574360] FS:  00007f4a2dc1ab80(0000) GS:ffff9cc33f100000(0000) knlGS:0000000000000000
[72201.583370] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[72201.590023] CR2: 0000000000004354 CR3: 000000120fabc000 CR4: 0000000000350ee0
[72201.598073] Call Trace:
[72201.601409]  <TASK>
[72201.604393]  qede_get_link_ksettings+0x75/0x120 [qede ec51249dd817fa184d2346562f8d1f5661029c7c]
[72201.614025]  ? duplex_show+0x8b/0xe0
[72201.618497]  duplex_show+0x8b/0xe0
[72201.622793]  dev_attr_show+0x18/0x50
[72201.627267]  sysfs_kf_seq_show+0x9b/0x110
[72201.632177]  seq_read_iter+0xd9/0x440
[72201.636735]  new_sync_read+0x11c/0x1b0
[72201.641382]  vfs_read+0x16f/0x190
[72201.645591]  ksys_read+0xa5/0xe0
[72201.649713]  do_syscall_64+0x5b/0x80
[72201.654186]  ? vfs_read+0x16f/0x190
[72201.658569]  ? exit_to_user_mode_prepare+0xbb/0x230
[72201.664350]  ? syscall_exit_to_user_mode+0x18/0x40
[72201.670044]  ? do_syscall_64+0x67/0x80
[72201.674690]  ? do_syscall_64+0x67/0x80
[72201.679335]  ? do_syscall_64+0x67/0x80
[72201.683978]  ? exit_to_user_mode_prepare+0x1dc/0x230
[72201.689845]  entry_SYSCALL_64_after_hwframe+0x61/0xcb
[72201.695800] RIP: 0033:0x7f4a2d503a3e 
```

If a crash is observed and a dump is created, generate a support config and send the generated tar plus the dump to
CASM.

- Generate the support config, the command will output the path to the generated archive.

    ```bash
    supportconfig
    ```

- Send the support config and the crash from `/var/crash/` to CASM

## Workaround

Upgrade CANU to version 2.3 or above, regenerate the configuration, and then apply it the VSX-pair that hosts the
storage nodes.

Or manually correct the configuration on both spines.

In this example of the problem we can see that the lags 10,12,14 which are the lags for the storage back channel
communication have applied configuration of `vlan trunk native 1`. Which is wrong.

```text
# Spine 1
interface lag 10 multi-chassis
    description ncn-s001:ocp:2<==sw-spine-001
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
interface lag 12 multi-chassis
    description ncn-s002:ocp:2<==sw-spine-001
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
interface lag 14 multi-chassis
    description ncn-s003:ocp:2<==sw-spine-001
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge

# Spine 2
interface lag 10 multi-chassis
    description ncn-s001:pcie-slot1:2<==sw-spine-002
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
interface lag 12 multi-chassis
    description ncn-s002:pcie-slot1:2<==sw-spine-002
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
interface lag 14 multi-chassis
    description ncn-s003:pcie-slot1:2<==sw-spine-002
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
```

Too correct the issue, log in to both the VSX pair switches and correct the configuration of these lags to
use `vlan trunk native 10`:

```text
# Spine 1
interface lag 10 multi-chassis
    description ncn-s001:ocp:2<==sw-spine-001
    no shutdown
    no routing
    vlan trunk native 10
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
interface lag 12 multi-chassis
    description ncn-s002:ocp:2<==sw-spine-001
    no shutdown
    no routing
    vlan trunk native 10
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
interface lag 14 multi-chassis
    description ncn-s003:ocp:2<==sw-spine-001
    no shutdown
    no routing
    vlan trunk native 10
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge

# Spine 2
# Spine 2
interface lag 10 multi-chassis
    description ncn-s001:pcie-slot1:2<==sw-spine-002
    no shutdown
    no routing
    vlan trunk native 10
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
interface lag 12 multi-chassis
    description ncn-s002:pcie-slot1:2<==sw-spine-002
    no shutdown
    no routing
    vlan trunk native 10
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
interface lag 14 multi-chassis
    description ncn-s003:pcie-slot1:2<==sw-spine-002
    no shutdown
    no routing
    vlan trunk native 10
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
```

## Fix

The vendor is working to fix the QLogic driver drivers and firmware.

Using the `qed` 8.72.1 driver (or newer) defends against the kernel panic, but not the connectivity loss.

If/when a new driver/firmware is released that resolves this issue completely, it will be added to the CSM release
and/or HFP firmware pack.
