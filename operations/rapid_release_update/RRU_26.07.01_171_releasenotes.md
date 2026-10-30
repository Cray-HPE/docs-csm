# Release Notes - `Rapid-Update-sle15-sp7-171-26.07.01`

This document guides an administrator through the deploy of Rapid Release Update on `CSM-1.7.1`.

This page documents the changes introduced by this RRU, compared to the previous RRU version.

* [Kernel Version](#kernel-version)
* [CVE fixes](#cves-fixes)
* [Deploy steps](#deploy-steps)

## Kernel Version

`6.4.0-150700.53.73.2`

## CVEs Fixes

CVEs fixed which have NVD score > 9.

* `CVE-2026-43074` - Linux Kernel Eventpoll Use-After-Free.
* `CVE-2026-43456` - Linux Kernel Bonding Type Confusion.
* `CVE-2026-43499` - Linux Kernel rtmutex/Futex Privilege Escalation (GhostLock).
* `CVE-2026-46242` - Linux Kernel Eventpoll ep_remove() Use-After-Free ("Bad Epoll").
* `CVE-2026-46266` - Linux Kernel RAW Socket ICMP Processing Vulnerability.
* `CVE-2026-46331` - Linux Kernel Traffic Control Page Cache Corruption.
* `CVE-2026-52943` - Linux Kernel skbuff Zero-Copy Use-After-Free.
* `CVE-2026-53359` - Linux Kernel KVM Shadow Paging Use-After-Free.
* `CVE-2026-53362` - Linux Kernel IPv6 Fragmentation Memory Corruption.

## Deploy Steps

See [Rapid Release Update (RRU) for CSM kernel CVE fixes](README.md#release-notes).
