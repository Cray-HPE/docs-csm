# Release Notes - `Rapid-Update-sle15-sp6-170-26.10.01`

This document guides an administrator through the deploy of Rapid Release Update on `CSM-1.7.0`.

This page documents the changes introduced by this RRU, compared to the previous RRU version.

* [Kernel Version](#kernel-version)
* [CVE fixes](#cves-fixes)
* [Deploy steps](#deploy-steps)

## Kernel Version

`6.4.0-150600.23.138.1`

## CVEs Fixes

CVEs fixed which have NVD score > 9.

* `CVE-2026-63795` - Linux Kernel 9p Client Reference Underflow
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
* `CVE-2026-64320` - Linux Kernel nvmet Discovery Get Log Page Pre-Auth Out-of-Bounds Heap Read
* `CVE-2026-74597` - Linux Kernel IPv6 Tunnel Stale HAO Metadata Out-of-Bounds Access
* `CVE-2026-74473` - Linux Kernel vxlan route_shortcircuit() Network Header Out-of-Bounds Read
* `CVE-2026-80725` - Linux Kernel GRO BIG TCP Aggregation Validation Out-of-Bounds Write
* `CVE-2026-72129` - Linux Kernel nvmet-rdma Inline Data Offset Length Underflow
* `CVE-2026-90414` - Linux Kernel IB/isert Over-Declared Data Segment Out-of-Bounds Read
* `CVE-2026-72398` - Linux Kernel SCTP COOKIE-ECHO Missing INIT Re-Verification
* `CVE-2026-89702` - Linux Kernel NFSD fh_verify Tracepoint Sockaddr Slot Overflow
* `CVE-2026-80976` - Linux Kernel seg6 Stale IP6CB Out-of-Bounds Read After Decapsulation
* `CVE-2026-89636` - Linux Kernel SMB Client DFS Cache tgthint Use-After-Free
* `CVE-2026-74616` - Linux Kernel XDP Clone skb_shared_info Tailroom Overrun
* `CVE-2026-80714` - Linux Kernel IPVS One-Packet Flag Synced Connection Use-After-Free
* `CVE-2026-89533` - Linux Kernel svcrdma read_chunk_range Offset Arithmetic Underflow
* `CVE-2026-74267` - Linux Kernel net/sched sch_codel Peek Backlog Wild Memory Access
* `CVE-2026-74406` - Linux Kernel vxlan GRO Null Pointer Dereference
* `CVE-2026-74608` - Linux Kernel SMB Client cifs_try_adding_channels Use-After-Free
* `CVE-2026-72323` - Linux Kernel IPv4 IGMP Timer Use-After-Free
* `CVE-2026-74476` - Linux Kernel veth frag_list XDP AF_XDP Copy-Mode Crash
* `CVE-2026-89482` - Linux Kernel nvme-tcp WRITE_ZEROES C2HData Wild Memory Access
* `CVE-2026-74586` - Linux Kernel SCTP new_transport Use-After-Free on Peer Removal
* `CVE-2026-64319` - Linux Kernel nvmet-auth DHCHAP_REPLY Pre-Auth Out-of-Bounds Read
* `CVE-2026-72322` - Linux Kernel IPv6 MLD Delayed Work Use-After-Free
* `CVE-2026-74480` - Linux Kernel Bridge Fast-Leave Port Group Use-After-Free
* `CVE-2026-100075` - Linux Kernel RDMA/srpt rw_ctx Unwind Counter Desync
* `CVE-2026-74744` - Linux Kernel ipvlan Missing Headroom/Tailroom Reservation
* `CVE-2026-74752` - Linux Kernel SCTP Cookie AUTH State Validation
* `CVE-2026-89674` - Linux Kernel NFSD Layoutget XDR Length Miscalculation
* `CVE-2026-72098` - Linux Kernel dm-verity FEC Erasure Buffer Overflow
* `CVE-2026-90413` - Linux Kernel IB/isert Login PDU Over-Declared Length Out-of-Bounds Read
* `CVE-2026-74688` - Linux Kernel SCTP Queued Control Chunk Transport Use-After-Free
* `CVE-2026-74493` - Linux Kernel net/smc Link Group Termination Socket Use-After-Free
* `CVE-2026-74398` - Linux Kernel IPv6 addrconf DAD Failure State Race Use-After-Free
* `CVE-2026-72399` - Linux Kernel enetc XDP Frame BD Count Out-of-Bounds Write
* `CVE-2026-89479` - Linux Kernel SCTP Bundled Chunk Association Use-After-Free
* `CVE-2026-90104` - Linux Kernel NFSv4.1 CB_SEQUENCE Uninitialized Referring Call List
* `CVE-2026-89532` - Linux Kernel svcrdma Empty Chunk Segment Underflow
* `CVE-2026-74737` - Linux Kernel TI AM65 CPSW Source Tag Port ID Out-of-Bounds Access
* `CVE-2026-72348` - Linux Kernel netfilter ip6tables Malformed Extension Header Rule Bypass
* `CVE-2026-74743` - Linux Kernel macvlan Missing Headroom/Tailroom Reservation
* `CVE-2026-72351` - Linux Kernel GUE REMCSUM Private Option Length Validation
* `CVE-2026-89542` - Linux Kernel SUNRPC gss_krb5_unwrap_v2 Short Token Memory Corruption
* `CVE-2026-89631` - Linux Kernel SMB Client Tree Connect ByteCount Underflow
* `CVE-2026-74588` - Linux Kernel SCTP chunk->transport Retransmit Use-After-Free
* `CVE-2026-89551` - Linux Kernel SUNRPC xdr_buf_trim Length Underflow
* `CVE-2026-99999` - Linux Kernel IPv4 Checksum Start Validation
* `CVE-2026-74611` - Linux Kernel TLS 1.3 RX Optimistic Retry Iterator Overwrite
* `CVE-2026-72493` - Linux Kernel Backlog netif_running() TOCTOU Use-After-Free
* `CVE-2026-98323` - Linux Kernel RDMA/siw Fragmented Header Copy Out-of-Bounds Write
* `CVE-2026-74587` - Linux Kernel SCTP Cached ASCONF Chunk Use-After-Free
* `CVE-2026-89669` - Linux Kernel nfsd Copy-Notify Stateid Publish Race Use-After-Free
* `CVE-2026-72041` - Linux Kernel espintcp Partial Send skmsg Accounting Flaw
* `CVE-2026-90011` - Linux Kernel iSCSI Target Login Payload Missing Terminator Overread
* `CVE-2026-98432` - Linux Kernel IPv4 inet_opt/ireq_opt RCU Free Use-After-Free

## Deploy Steps

See [Rapid Release Update (RRU) for CSM kernel CVE fixes](README.md#release-notes).
