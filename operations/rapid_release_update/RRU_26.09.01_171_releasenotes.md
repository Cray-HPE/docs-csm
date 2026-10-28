# Release Notes - `Rapid-Update-sle15-sp7-171-26.09.01`

This document guides an administrator through the deploy of Rapid Release Update on `CSM-1.7.1`.

This page documents the changes introduced by this RRU, compared to the previous RRU version.

* [Expected Kernel Version](#expected-kernel-version)
* [CVE fixes](#cves-fixes)
* [Deploy steps](#deploy-steps)

## Expected Kernel Version

`6.4.0-150700.53.78.1`

## CVEs Fixes

CVEs fixed which have NVD score > 9.

* `CVE-2026-53398` - Linux Kernel NFSD SECINFO_NO_NAME Use-After-Free
* `CVE-2026-53399` - Linux Kernel NFSD Layout stateid Use-After-Free
* `CVE-2026-63795` - Linux Kernel 9p Client Reference Underflow
* `CVE-2026-63912` - Linux Kernel IPsec ESP Page Fragment Handling Flaw
* `CVE-2026-63922` - Linux Kernel IPv6 Extension Header Pointer Handling Flaw
* `CVE-2026-63924` - Linux Kernel IPv6 Jumbo Header Pointer Handling Flaw
* `CVE-2026-63938` - Linux Kernel KVM SEV PSC Buffer Validation Flaw
* `CVE-2026-63939` - Linux Kernel KVM SEV Scratch Buffer Length Calculation Flaw
* `CVE-2026-63940` - Linux Kernel KVM SEV Zero-Length Port I/O Handling Flaw
* `CVE-2026-63984` - Linux Kernel IPv6 RPL Header Length Overflow
* `CVE-2026-63994` - Linux Kernel Tunnel PMTU Use-After-Free
* `CVE-2026-64025` - Linux Kernel BPF sockmap and KTLS Race Condition
* `CVE-2026-64089` - Linux Kernel B.A.T.M.A.N. Advanced Length Handling Flaw
* `CVE-2026-64106` - Linux Kernel KVM ARM64 VGIC ITS Restore Validation Flaw
* `CVE-2026-64564` - Linux Kernel SCTP ASCONF DEL-IP Use-After-Free
* `CVE-2026-64530` - Linux Kernel net/sched cls_api Use-After-Free
* `CVE-2026-53131` - Linux Kernel Netfilter Ethernet Header Out-of-Bounds Access
* `CVE-2026-52986` - Linux Kernel Netfilter SIP Conntrack Out-of-Bounds Read

## Deploy Steps

See [Rapid Release Update (RRU) for CSM kernel CVE fixes](README.md#release-notes).
