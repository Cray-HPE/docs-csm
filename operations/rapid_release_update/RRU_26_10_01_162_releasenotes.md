# Release Notes - `Rapid-Update-sle15-sp6-162-26.10.01`

This document guides an administrator through the deploy of Rapid Release Update on `CSM-1.6.2`.

This page documents the changes introduced by this RRU, compared to the previous RRU version.

* [Kernel Version](#kernel-version)
* [CVE fixes](#cves-fixes)
* [Deploy steps](#deploy-steps)

## Kernel Version

`6.4.0-150600.23.135.1`

## CVEs Fixes

CVEs fixed which have NVD score > 9.

* `CVE-2026-63886` - Linux Kernel iSCSI Target CHAP_R Base64 Heap Overflow
* `CVE-2026-63887` - Linux Kernel iSCSI Target Text Response Heap Overrun
* `CVE-2026-63888` - Linux Kernel iSCSI Target Text Command CRC Overread and Double-Free
* `CVE-2026-63992` - Linux Kernel Tunnel PMTU ICMP Out-of-Bounds Access
* `CVE-2026-64000` - Linux Kernel HSR Supervision Frame Out-of-Bounds Read
* `CVE-2026-64007` - Linux Kernel Netfilter SYNPROXY Stale TCP Header Use-After-Free
* `CVE-2026-64018` - Linux Kernel MANA Out-of-Bounds Array Access
* `CVE-2026-64034` - Linux Kernel MANA TOCTOU Double-Fetch
* `CVE-2026-74669` - Linux Kernel IPVS Tunnel ICMP Stack Out-of-Bounds Write
* `CVE-2026-74612` - Linux Kernel veth XDP skb Length Accounting Flaw
* `CVE-2026-74581` - Linux Kernel IPv6 Suppressed FIB6 Rule Use-After-Free
* `CVE-2026-74556` - Linux Kernel libiscsi_tcp SCSI Response Buffer Overflow
* `CVE-2026-74394` - Linux Kernel RDMA/srpt Immediate Data Integer Overflow
* `CVE-2026-74345` - Linux Kernel RDMA/siw Endpoint Socket Use-After-Free
* `CVE-2026-72339` - Linux Kernel qede Off-by-One BD Ring Desynchronization
* `CVE-2026-72317` - Linux Kernel SUNRPC TLS connect_worker Use-After-Free
* `CVE-2026-72289` - Linux Kernel KVM arm64 vGIC Interrupt Migration Use-After-Free
* `CVE-2026-72288` - Linux Kernel KVM arm64 vGIC LPI Disable Race Use-After-Free
* `CVE-2026-72251` - Linux Kernel Netfilter nf_nat_sip Stale Data Pointer
* `CVE-2026-72222` - Linux Kernel SUNRPC TLS Handshake Callback Use-After-Free
* `CVE-2026-72221` - Linux Kernel SUNRPC TLS Cancel Race Use-After-Free
* `CVE-2026-72084` - Linux Kernel SCSI Target PR-OUT TransportID Out-of-Bounds Read
* `CVE-2026-72083` - Linux Kernel SCSI Target REGISTER AND MOVE Use-After-Free
* `CVE-2026-72069` - Linux Kernel locking/rt rt_spin_unlock() RCU Use-After-Free
* `CVE-2026-72020` - Linux Kernel IPVS ip_vs_conn_new Uninitialized Sequence Data
* `CVE-2026-68426` - Linux Kernel xfrm Async Crypto Stale skb Use-After-Free
* `CVE-2026-68160` - Linux Kernel Ceph Pre-Auth Snaptrace Out-of-Bounds Read
* `CVE-2026-68159` - Linux Kernel libceph pg_temp/pg_upmap Stack Out-of-Bounds Write
* `CVE-2026-68158` - Linux Kernel libceph OSDMap Multiplication Overflow
* `CVE-2026-68136` - Linux Kernel GRO Double Aggregation NULL Dereference
* `CVE-2026-64541` - Linux Kernel net/smc smc_cdc_rx_handler() Socket Use-After-Free
* `CVE-2026-64450` - Linux Kernel TIPC Broadcast Gap ACK Out-of-Bounds Read
* `CVE-2026-64387` - Linux Kernel SMB Client Query Directory Replay Double-Free
* `CVE-2026-64386` - Linux Kernel SMB Client Query Info Replay Double-Free
* `CVE-2026-64385` - Linux Kernel SMB Client IOCTL Replay Double-Free
* `CVE-2026-64384` - Linux Kernel SMB Client Change Notify Replay Double-Free
* `CVE-2026-64383` - Linux Kernel SMB Client Flush Replay Double-Free
* `CVE-2026-64355` - Linux Kernel BPF devmap Fragmented Frame Out-of-Bounds Access
* `CVE-2026-64268` - Linux Kernel RDMA/siw Read Response Out-of-Bounds Write
* `CVE-2026-63912` - Linux Kernel IPsec ESP Page Fragment Handling Flaw
* `CVE-2026-63922` - Linux Kernel IPv6 Extension Header Pointer Handling Flaw
* `CVE-2026-63924` - Linux Kernel IPv6 Jumbo Header Pointer Handling Flaw
* `CVE-2026-63984` - Linux Kernel IPv6 RPL Header Length Overflow
* `CVE-2026-63994` - Linux Kernel Tunnel PMTU Use-After-Free
* `CVE-2026-64106` - Linux Kernel KVM ARM64 VGIC ITS Restore Validation Flaw
* `CVE-2026-64564` - Linux Kernel SCTP ASCONF DEL-IP Use-After-Free
* `CVE-2026-64530` - Linux Kernel net/sched cls_api Use-After-Free
* `CVE-2026-53246` - Linux Kernel SCTP COOKIE_ECHO Cached INIT Out-of-Bounds Read
* `CVE-2026-53224` - Linux Kernel SCTP Cookie INIT and Address List Out-of-Bounds Read
* `CVE-2026-53131` - Linux Kernel Netfilter Ethernet Header Out-of-Bounds Access
* `CVE-2026-52986` - Linux Kernel Netfilter SIP Conntrack Out-of-Bounds Read

## Deploy Steps

See [Rapid Release Update (RRU) for CSM kernel CVE fixes](README.md#release-notes).