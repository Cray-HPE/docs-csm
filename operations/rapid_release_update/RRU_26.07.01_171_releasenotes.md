# Release Notes - Rapid-Update-sle15-sp7-171-26.07.01

This document guides an administrator through the deploy of Rapid Release Update on CSM-1.7.1.

This page documents the changes introduced by this RRU, compared to the previous RRU version.

* [Expected Kernel Version](#expected-kernel-version)
* [CVE fixes](#cve-fixes)
* [Deploy steps](#deploy-steps)

## Expected Kernel Version

`6.4.0-150700.53.73.2`

## CVEs Fixes

CVEs fixed which have NVD score > 9.

* `CVE-2026-43074` - Linux Kernel Eventpoll Use-After-Free.
A race condition in the Linux kernel eventpoll subsystem may result in a use-after-free condition when eventpoll structures are accessed concurrently during cleanup. Successful exploitation could lead to memory corruption, information disclosure, denial of service, or privilege escalation.
* `CVE-2026-43456` - Linux Kernel Bonding Type Confusion.
A flaw in the Linux kernel bonding driver may cause a bond interface to invoke a non-Ethernet slave device's header-processing functions with incompatible private data. This type confusion could result in invalid memory access and a kernel crash, leading to a denial of service.
* `CVE-2026-43499` - Linux Kernel rtmutex/Futex Privilege Escalation (GhostLock).
A vulnerability in the Linux kernel real-time mutex and futex locking subsystem may result in a use-after-free condition caused by improper waiter tracking during lock cleanup. Successful exploitation could allow a local attacker to elevate privileges, execute arbitrary code, or cause a denial of service.
* `CVE-2026-46242` - Linux Kernel Eventpoll ep_remove() Use-After-Free ("Bad Epoll").
A race condition in the Linux kernel eventpoll ep_remove() function may allow a concurrent file release to observe a transiently cleared f_ep state and skip the normal eventpoll_release_file() cleanup path. This could result in a use-after-free condition, potentially causing memory corruption, denial of service, or privilege escalation.
* `CVE-2026-46266` - Linux Kernel RAW Socket ICMP Processing Vulnerability.
A flaw in the Linux kernel networking stack could allow specially crafted ICMP packets to interact improperly with RAW sockets using the IPPROTO_RAW protocol. Successful exploitation may alter network-routing state and affect system integrity or availability.
* `CVE-2026-46331` - Linux Kernel Traffic Control Page Cache Corruption.
A vulnerability in the Linux kernel traffic-control subsystem could result in page-cache corruption due to improper copy-on-write handling. A local attacker may exploit this issue to compromise system integrity or obtain elevated privileges.
* `CVE-2026-52943` - Linux Kernel skbuff Zero-Copy Use-After-Free.
A flaw in the kernel socket-buffer subsystem may lead to a use-after-free condition during zero-copy networking operations. Successful exploitation could allow a local attacker to gain elevated privileges and execute arbitrary code with root-level permissions.
* `CVE-2026-53359` - Linux Kernel KVM Shadow Paging Use-After-Free.
A flaw in the Linux kernel KVM x86 shadow-paging subsystem may leave a stale reverse-mapping entry when a memory slot is removed. Subsequent memory-management operations could access a freed shadow page, resulting in a use-after-free condition that may cause memory corruption, denial of service, or other impacts.
* `CVE-2026-53362` - Linux Kernel IPv6 Fragmentation Memory Corruption.
A vulnerability in the Linux kernel IPv6 networking stack could result in an out-of-bounds memory write during packet processing. An unprivileged local user may be able to trigger memory corruption, potentially leading to privilege escalation or denial of service.

## Deploy Steps

See [Rapid Release Update (RRU) for CSM kernel CVE fixes](rru_overview.md#release-notes).
