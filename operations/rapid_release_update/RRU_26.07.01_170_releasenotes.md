# Release Notes - `Rapid-Update-sle15-sp6-170-26.07.01`

This document guides an administrator through the deploy of Rapid Release Update on `CSM-1.7.0`.

This page documents the changes introduced by this RRU, compared to the previous RRU version.

* [Expected Kernel Version](#expected-kernel-version)
* [CVE fixes](#cves-fixes)
* [Deploy steps](#deploy-steps)

## Expected Kernel Version

`6.4.0-150600.23.125.1`

## CVEs Fixes

CVEs fixed which have NVD score > 9.

* `CVE-2026-46242` - Linux Kernel eventpoll ep_remove Use-After-Free
* `CVE-2026-43499` - Linux Kernel rtmutex remove_waiter() Use-After-Free
* `CVE-2026-53362` - Linux Kernel IPv6 Paged Allocation Heap Overflow
* `CVE-2026-52943` - Linux Kernel skbuff pskb_carve Zerocopy Use-After-Free
* `CVE-2026-46331` - Linux Kernel net/sched pedit Partial COW Out-of-Bounds Write
* `CVE-2026-43074` - Linux Kernel eventpoll struct eventpoll Use-After-Free
* `CVE-2026-46266` - Linux Kernel RAW Socket IPPROTO_RAW ICMP Route Cache Poisoning
* `CVE-2026-53359` - Linux Kernel KVM x86 Shadow Paging Role Confusion Use-After-Free

## Deploy Steps

See [Rapid Release Update (RRU) for CSM kernel CVE fixes](README.md#release-notes).
