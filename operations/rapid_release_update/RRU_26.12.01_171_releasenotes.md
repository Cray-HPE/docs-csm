# Release Notes - `Rapid-Update-sle15-sp7-171-26.12.01`

This document guides an administrator through the deploy of Rapid Release Update on `CSM-1.7.1` and its patch releases.

This page documents the changes introduced by this RRU, compared to the previous RRU version.

* [Kernel Version](#kernel-version)
* [CVE fixes](#cves-fixes)
* [Deploy steps](#deploy-steps)

## Kernel Version

`6.4.0-150700.53.90.1`

## CVEs Fixes

CVEs fixed which have NVD score > 9.

* `CVE-2026-63808` - Linux Kernel `exFAT` Directory Entry Lookup Use-After-Free
* `CVE-2026-63886` - Linux Kernel iSCSI Target `CHAP_R` Base64 Heap Overflow
* `CVE-2026-63887` - Linux Kernel iSCSI Target Text Response Heap Overrun
* `CVE-2026-63888` - Linux Kernel iSCSI Target Text Command CRC Overread and Double-Free
* `CVE-2026-63992` - Linux Kernel Tunnel PMTU ICMP Out-of-Bounds Access
* `CVE-2026-64000` - Linux Kernel HSR Supervision Frame Out-of-Bounds Read
* `CVE-2026-64007` - Linux Kernel Netfilter SYNPROXY Stale TCP Header Use-After-Free
* `CVE-2026-64018` - Linux Kernel MANA Out-of-Bounds Array Access
* `CVE-2026-64033` - Linux Kernel RDMA/`rtrs` Path File Creation Cleanup Use-After-Free
* `CVE-2026-64034` - Linux Kernel MANA TOCTOU Double-Fetch
* `CVE-2026-64047` - Linux Kernel TLS Wrapped `sk_msg` Ring Chain Off-by-One
* `CVE-2026-64055` - Linux Kernel Cortina Gemini Ethernet RX Fragment Counter Reset
* `CVE-2026-64056` - Linux Kernel Cortina Gemini Ethernet Shared RX SKB Race
* `CVE-2026-64102` - Linux Kernel RDMA/siw MPA FPDU Length Underflow
* `CVE-2026-64113` - Linux Kernel `ixgbevf` VEPA Multicast Source Pruning Use-After-Free
* `CVE-2026-64125` - Linux Kernel `bcmgenet` RBUF EEE/PM RX Stall
* `CVE-2026-64136` - Linux Kernel SMB Client Unprotected `tcon` Reference Count Increment
* `CVE-2026-53384` - Linux Kernel serial `8250_dw` Port Leak on Clock Notifier Failure
* `CVE-2026-63993` - Linux Kernel vxlan Cached IP Header Use-After-Free After PMTU Check
* `CVE-2026-64046` - Linux Kernel TLS Plaintext Scatterlist Chain-After-Chain
* `CVE-2026-63830` - Linux Kernel skmsg sg.copy Ownership Bit Loss
* `CVE-2026-74712` - Linux Kernel `vdpa`/`mlx5` create_direct_keys() Buffer Length Out-of-Bounds Read
* `CVE-2026-74669` - Linux Kernel IPVS Tunnel ICMP Stack Out-of-Bounds Write
* `CVE-2026-74581` - Linux Kernel IPv6 Suppressed FIB6 Rule Use-After-Free
* `CVE-2026-74556` - Linux Kernel `libiscsi_tcp` SCSI Response Buffer Overflow
* `CVE-2026-74495` - Linux Kernel `igbvf` TX DMA Error Cleanup Off-by-One Leak
* `CVE-2026-74474` - Linux Kernel vxlan Transmit Path Header Pull Out-of-Bounds Read
* `CVE-2026-74394` - Linux Kernel RDMA/`srpt` Immediate Data Integer Overflow
* `CVE-2026-74345` - Linux Kernel RDMA/siw Endpoint Socket Use-After-Free
* `CVE-2026-74269` - Linux Kernel `bnxt` XDP Head-Grow Underflow
* `CVE-2026-72496` - Linux Kernel RDMA/`bnxt_re` Missing Rollback on `ioremap` Failure
* `CVE-2026-72495` - Linux Kernel RDMA/`bnxt_re` Repeated WC Page Allocation Race
* `CVE-2026-72494` - Linux Kernel RDMA/`irdma` CQP Request Completion Race
* `CVE-2026-72473` - Linux Kernel `xprtrdma` Request Recycling Use-After-Free
* `CVE-2026-72466` - Linux Kernel `xprtrdma` Backchannel Reply Leak and Unbounded Peek
* `CVE-2026-72463` - Linux Kernel `xfrm` Async Resumption Device Use-After-Free
* `CVE-2026-72317` - Linux Kernel SUNRPC TLS `connect_worker` Use-After-Free
* `CVE-2026-72296` - Linux Kernel net/sched IFE Decode Inner Ethernet Header Out-of-Bounds Read
* `CVE-2026-72289` - Linux Kernel KVM arm64 vGIC Interrupt Migration Use-After-Free
* `CVE-2026-72288` - Linux Kernel KVM arm64 vGIC LPI Disable Race Use-After-Free
* `CVE-2026-72251` - Linux Kernel Netfilter `nf_nat_sip` Stale Data Pointer
* `CVE-2026-72222` - Linux Kernel SUNRPC TLS Handshake Callback Use-After-Free
* `CVE-2026-72221` - Linux Kernel SUNRPC TLS Cancel Race Use-After-Free
* `CVE-2026-72084` - Linux Kernel SCSI Target PR-OUT TransportID Out-of-Bounds Read
* `CVE-2026-72083` - Linux Kernel SCSI Target REGISTER AND MOVE Use-After-Free
* `CVE-2026-72069` - Linux Kernel locking/rt `rt_spin_unlock`() RCU Use-After-Free
* `CVE-2026-72046` - Linux Kernel `gve` Header-Split `HW-GRO` Header Buffer Corruption
* `CVE-2026-72020` - Linux Kernel IPVS `ip_vs_conn_new` Uninitialized Sequence Data
* `CVE-2026-68426` - Linux Kernel `xfrm` Async Crypto Stale skb Use-After-Free
* `CVE-2026-68343` - Linux Kernel SMB Client DFS Referral PathConsumed Out-of-Bounds Read
* `CVE-2026-68302` - Linux Kernel AMT Stale skb Header Pointer Use-After-Free
* `CVE-2026-68300` - Linux Kernel SCTP AUTH Verification Bypass When `auth_chunk` Is NULL
* `CVE-2026-68161` - Linux Kernel SCTP UDP Tunnel Socket Leak on Netns Teardown
* `CVE-2026-68160` - Linux Kernel Ceph Pre-Auth `Snaptrace` Out-of-Bounds Read
* `CVE-2026-68159` - Linux Kernel libceph `pg_temp`/`pg_upmap` Stack Out-of-Bounds Write
* `CVE-2026-68158` - Linux Kernel libceph `OSDMap` Multiplication Overflow
* `CVE-2026-68156` - Linux Kernel libceph Stale Authorizer Buffer Use-After-Free
* `CVE-2026-68154` - Linux Kernel libceph CRUSH Zero Bucket Type Negative Index
* `CVE-2026-68137` - Linux Kernel X.25 `x25_kill_by_neigh`() Socket Use-After-Free
* `CVE-2026-68136` - Linux Kernel GRO Double Aggregation NULL Dereference
* `CVE-2026-68127` - Linux Kernel ILA Checksum Adjust Stale IPv6 Header Use-After-Free
* `CVE-2026-68124` - Linux Kernel MCTP Serial Zero-Length Frame RX Buffer Overflow
* `CVE-2026-68123` - Linux Kernel Open `vSwitch` GSO `Userspace` Truncation Underflow
* `CVE-2026-68117` - Linux Kernel TIPC Socket Create Failure Dangling `sk` Pointer
* `CVE-2026-68082` - Linux Kernel libceph `decode_lockers`() Out-of-Bounds Read
* `CVE-2026-64597` - Linux Kernel SMB Client `SMB2_close`() Replay Double-Free
* `CVE-2026-64551` - Linux Kernel SCTP `STALE_COOKIE` Cause Length Out-of-Bounds Read
* `CVE-2026-64541` - Linux Kernel net/smc `smc_cdc_rx_handler`() Socket Use-After-Free
* `CVE-2026-64450` - Linux Kernel TIPC Broadcast Gap ACK Out-of-Bounds Read
* `CVE-2026-64387` - Linux Kernel SMB Client Query Directory Replay Double-Free
* `CVE-2026-64386` - Linux Kernel SMB Client Query Info Replay Double-Free
* `CVE-2026-64385` - Linux Kernel SMB Client IOCTL Replay Double-Free
* `CVE-2026-64384` - Linux Kernel SMB Client Change Notify Replay Double-Free
* `CVE-2026-64383` - Linux Kernel SMB Client Flush Replay Double-Free
* `CVE-2026-64355` - Linux Kernel BPF `devmap` Fragmented Frame Out-of-Bounds Access
* `CVE-2026-64303` - Linux Kernel `fsl-lpspi` RX DMA Not Terminated on TX Prepare Failure
* `CVE-2026-64269` - Linux Kernel RDMA/`rtrs-srv` RDMA-Write Length Out-of-Bounds Read
* `CVE-2026-64268` - Linux Kernel RDMA/siw Read Response Out-of-Bounds Write
* `CVE-2026-64257` - Linux Kernel SMB Client Overlapping SMB2 Response Data Area
* `CVE-2026-64320` - Linux Kernel `nvmet` Discovery Get Log Page Pre-Auth Out-of-Bounds Heap Read
* `CVE-2026-80603` - Linux Kernel Netfilter IRC Helper `parse_dcc`() Off-by-One Read
* `CVE-2026-74597` - Linux Kernel IPv6 Tunnel Stale HAO Metadata Out-of-Bounds Access
* `CVE-2026-74475` - Linux Kernel vxlan route_shortcircuit() Torn Neighbour Address Read
* `CVE-2026-90151` - Linux Kernel NFSv4 Callback IDR Entry Use-After-Free on Client Allocation Failure
* `CVE-2026-89697` - Linux Kernel NFSD v2 SETATTR Missing Mount Write Reference
* `CVE-2026-89672` - Linux Kernel NFSD NFSv2 SETACL Unrequested ACL Removal
* `CVE-2026-89662` - Linux Kernel NFSD Lock Owner Use-After-Free During Client Teardown
* `CVE-2026-74473` - Linux Kernel vxlan route_shortcircuit() Network Header Out-of-Bounds Read
* `CVE-2026-80725` - Linux Kernel GRO BIG TCP Aggregation Validation Out-of-Bounds Write
* `CVE-2026-72129` - Linux Kernel `nvmet-rdma` Inline Data Offset Length Underflow
* `CVE-2026-90414` - Linux Kernel IB/`isert` Over-Declared Data Segment Out-of-Bounds Read
* `CVE-2026-80589` - Linux Kernel Block Layer Timeout Timer Use-After-Free on Unadded Disk
* `CVE-2026-72398` - Linux Kernel SCTP COOKIE-ECHO Missing INIT Re-Verification
* `CVE-2026-89702` - Linux Kernel NFSD fh_verify Tracepoint Sockaddr Slot Overflow
* `CVE-2026-74384` - Linux Kernel nvme-multipath current_path Array Out-of-Bounds Access
* `CVE-2026-72421` - Linux Kernel IPv4 FIB Error Route Ignored in Merged Tables
* `CVE-2026-80976` - Linux Kernel seg6 Stale IP6CB Out-of-Bounds Read After Decapsulation
* `CVE-2026-89538` - Linux Kernel SUNRPC krb5 v2 Wrap Token Oversized EC Field
* `CVE-2026-89636` - Linux Kernel SMB Client DFS Cache tgthint Use-After-Free
* `CVE-2026-74616` - Linux Kernel XDP Clone skb_shared_info Tailroom Overrun
* `CVE-2026-72085` - Linux Kernel xen-scsiback Unsubmitted Command Double Put
* `CVE-2026-89712` - Linux Kernel NFSD SSC Expire Unmount List Use-After-Free
* `CVE-2026-80714` - Linux Kernel IPVS One-Packet Flag Synced Connection Use-After-Free
* `CVE-2026-89533` - Linux Kernel svcrdma read_chunk_range Offset Arithmetic Underflow
* `CVE-2026-74267` - Linux Kernel net/sched sch_codel Peek Backlog Wild Memory Access
* `CVE-2026-74406` - Linux Kernel vxlan GRO Null Pointer Dereference
* `CVE-2026-74608` - Linux Kernel SMB Client cifs_try_adding_channels Use-After-Free
* `CVE-2026-80693` - Linux Kernel idpf Interrupt Vector Register Array Overflow
* `CVE-2026-72323` - Linux Kernel IPv4 IGMP Timer Use-After-Free
* `CVE-2026-74476` - Linux Kernel veth frag_list XDP AF_XDP Copy-Mode Crash
* `CVE-2026-89485` - Linux Kernel lockd nlm_traverse_files() Next File Use-After-Free
* `CVE-2026-89482` - Linux Kernel nvme-tcp WRITE_ZEROES C2HData Wild Memory Access
* `CVE-2026-74586` - Linux Kernel SCTP new_transport Use-After-Free on Peer Removal
* `CVE-2026-89550` - Linux Kernel SUNRPC svcauth_gss krb5 Token Minimum Length
* `CVE-2026-89448` - Linux Kernel Intel VT-d ACS Not Requested with tboot
* `CVE-2026-80681` - Linux Kernel vxlan Stale Ethernet Header After route_shortcircuit()
* `CVE-2026-72322` - Linux Kernel IPv6 MLD Delayed Work Use-After-Free
* `CVE-2026-72299` - Linux Kernel TIPC Enqueue Tracepoint Socket Queue Use-After-Free
* `CVE-2026-74480` - Linux Kernel Bridge Fast-Leave Port Group Use-After-Free
* `CVE-2026-100075` - Linux Kernel RDMA/srpt rw_ctx Unwind Counter Desync
* `CVE-2026-74744` - Linux Kernel ipvlan Missing Headroom/Tailroom Reservation
* `CVE-2026-89713` - Linux Kernel NFSD Truncate Permission Check TOCTOU
* `CVE-2026-74752` - Linux Kernel SCTP Cookie AUTH State Validation
* `CVE-2026-72491` - Linux Kernel 9p RDMA Transport State Race
* `CVE-2026-89674` - Linux Kernel NFSD Layoutget XDR Length Miscalculation
* `CVE-2026-72098` - Linux Kernel dm-verity FEC Erasure Buffer Overflow
* `CVE-2026-90413` - Linux Kernel IB/`isert` Login PDU Over-Declared Length Out-of-Bounds Read
* `CVE-2026-74688` - Linux Kernel SCTP Queued Control Chunk Transport Use-After-Free
* `CVE-2026-74493` - Linux Kernel net/smc Link Group Termination Socket Use-After-Free
* `CVE-2026-72130` - Linux Kernel nvmet-auth Short AUTH_RECEIVE Buffer Heap Overflow
* `CVE-2026-74398` - Linux Kernel IPv6 addrconf DAD Failure State Race Use-After-Free
* `CVE-2026-97413` - Linux Kernel RDMA/`rtrs-srv` process_read/process_write Integer Underflow
* `CVE-2026-72399` - Linux Kernel enetc XDP Frame BD Count Out-of-Bounds Write
* `CVE-2026-89479` - Linux Kernel SCTP Bundled Chunk Association Use-After-Free
* `CVE-2026-80557` - Linux Kernel libceph decode_watchers() Out-of-Bounds Read
* `CVE-2026-89536` - Linux Kernel SUNRPC Client TLS Handshake Callback Use-After-Free
* `CVE-2026-74376` - Linux Kernel md/raid10 Discard Replacement Bio Leak
* `CVE-2026-93207` - Linux Kernel SUNRPC GSS Credential Decode Stale Data
* `CVE-2026-80586` - Linux Kernel MPTCP Malformed DSS Option Stale Fields
* `CVE-2026-80585` - Linux Kernel MPTCP Fast Open Data-Less SYN State Confusion
* `CVE-2026-90104` - Linux Kernel NFSv4.1 CB_SEQUENCE Uninitialized Referring Call List
* `CVE-2026-89532` - Linux Kernel svcrdma Empty Chunk Segment Underflow
* `CVE-2026-72339` - Linux Kernel qede Off-by-One BD Ring Desynchronization
* `CVE-2026-74737` - Linux Kernel TI AM65 CPSW Source Tag Port ID Out-of-Bounds Access
* `CVE-2026-74665` - Linux Kernel Generic XDP Fragment Adjust skb Length Accounting Flaw
* `CVE-2026-72348` - Linux Kernel Netfilter ip6tables Malformed Extension Header Rule Bypass
* `CVE-2026-74743` - Linux Kernel macvlan Missing Headroom/Tailroom Reservation
* `CVE-2026-74268` - Linux Kernel TCP BPF sock_ops Flags on Force-Closed Child Socket
* `CVE-2026-68477` - Linux Kernel IPVS Incorrect IPv6 Transport Header Offsets
* `CVE-2026-72436` - Linux Kernel Netfilter ipset Lockless RCU Reader Ordering
* `CVE-2026-72351` - Linux Kernel GUE REMCSUM Private Option Length Validation
* `CVE-2026-89671` - Linux Kernel NFSD NFSv3 SETACL Unrequested ACL Removal
* `CVE-2026-74255` - Linux Kernel TIPC tipc_l2_send_msg() Use-After-Free
* `CVE-2026-89686` - Linux Kernel NFSD Layout Stateid BUG_ON on Delegation Revoke Race
* `CVE-2026-89542` - Linux Kernel SUNRPC gss_krb5_unwrap_v2 Short Token Memory Corruption
* `CVE-2026-89541` - Linux Kernel SUNRPC gss_unwrap_resp_priv() Length Check Overflow
* `CVE-2026-74310` - Linux Kernel vhost-net Zerocopy ubuf Multiple Completion
* `CVE-2026-74705` - Linux Kernel UDP Tunnel Segmentation Use-After-Free
* `CVE-2026-89631` - Linux Kernel SMB Client Tree Connect ByteCount Underflow
* `CVE-2026-74588` - Linux Kernel SCTP chunk->transport Retransmit Use-After-Free
* `CVE-2026-74612` - Linux Kernel veth XDP skb Length Accounting Flaw
* `CVE-2026-74723` - Linux Kernel Btrfs LZO Inline Extent Out-of-Bounds Read
* `CVE-2026-74587` - Linux Kernel SCTP Cached ASCONF Chunk Use-After-Free
* `CVE-2026-72041` - Linux Kernel espintcp Partial Send skmsg Accounting Flaw
* `CVE-2026-90011` - Linux Kernel iSCSI Target Login Payload Missing Terminator Overread
* `CVE-2026-89778` - Linux Kernel isofs zisofs Empty Block Page Array Out-of-Bounds Access
* `CVE-2026-98323` - Linux Kernel RDMA/siw Fragmented Header Copy Out-of-Bounds Write
* `CVE-2026-74611` - Linux Kernel TLS 1.3 RX Optimistic Retry Iterator Overwrite
* `CVE-2026-89669` - Linux Kernel nfsd Copy-Notify Stateid Publish Race Use-After-Free
* `CVE-2026-99999` - Linux Kernel IPv4 Checksum Start Validation
* `CVE-2026-72493` - Linux Kernel Backlog netif_running() TOCTOU Use-After-Free
* `CVE-2026-72319` - Linux Kernel IPVS ICMP Error Inner Header Validation
* `CVE-2026-98365` - Linux Kernel RDMA/rxe mr_check_range() Integer Overflow
* `CVE-2026-64535` - Linux Kernel nvmet-tcp Data Digest Mismatch Use-After-Free
* `CVE-2026-68388` - Linux Kernel SMB Client fallocate Overlapping Range Skips Holes
* `CVE-2026-72226` - Linux Kernel batman-adv TT TVLV Length Overflow
* `CVE-2026-89846` - Linux Kernel qla2xxx rsp_info_len Sense Data Out-of-Bounds Read
* `CVE-2026-74279` - Linux Kernel Cavium CPT DMA Cleanup Wrong Loop Index
* `CVE-2026-74287` - Linux Kernel SCTP ASCONF Embedded Address Parameter Length
* `CVE-2026-80600` - Linux Kernel batman-adv DAT ARP Source Use-After-Free
* `CVE-2026-89857` - Linux Kernel qla2xxx NVMe LS Reject Missing qpair Lock
* `CVE-2026-89786` - Linux Kernel ext4 ext4_read_inline_dir() Out-of-Bounds Read
* `CVE-2026-89637` - Linux Kernel SMB Client Malformed Secondary TRANSACT2 Use-After-Free
* `CVE-2026-74746` - Linux Kernel Netfilter Flowtable Partially Installed Flow Use-After-Free
* `CVE-2026-72318` - Linux Kernel SMB Client DFS Referral String Offset Out-of-Bounds Read
* `CVE-2026-72234` - Linux Kernel batman-adv unicast_ttvn Use-After-Free
* `CVE-2026-80609` - Linux Kernel qede cqe->len_list Out-of-Bounds Read
* `CVE-2026-89656` - Linux Kernel libceph CRUSH Bucket ID Mismatch Workspace Overflow
* `CVE-2026-90042` - Linux Kernel Ceph Encrypted Filename Decryption from vmalloc Buffers
* `CVE-2026-89494` - Linux Kernel OCFS2 DLM Migrate Lockres Length Validation
* `CVE-2026-74439` - Linux Kernel Intel VT-d Torn Scalable-Mode Context Entry
* `CVE-2026-89537` - Linux Kernel SUNRPC Short RFC 4121 MIC Token Out-of-Bounds Read
* `CVE-2026-72064` - Linux Kernel MANA Missing RX Page Pool DMA Sync
* `CVE-2026-89495` - Linux Kernel OCFS2 DLM Migrate Request Name Length Overflow
* `CVE-2026-72065` - Linux Kernel MANA Unvalidated RX Packet Length
* `CVE-2026-89649` - Linux Kernel Ceph xattr Value Length Out-of-Bounds Read
* `CVE-2026-89654` - Linux Kernel Ceph check_new_map() Session Use-After-Free
* `CVE-2026-98432` - Linux Kernel IPv4 inet_opt/ireq_opt RCU Free Use-After-Free
* `CVE-2026-89847` - Linux Kernel qla2xxx Async IOCB Timeout Double Completion
* `CVE-2026-89655` - Linux Kernel Ceph __kick_flushing_caps() Use-After-Free
* `CVE-2026-64534` - Linux Kernel nvmet-tcp Digest Error Refcount Underflow
* `CVE-2026-80684` - Linux Kernel KVM s390 PCI AIBV Allocation NULL Dereference
* `CVE-2026-74280` - Linux Kernel Marvell OcteonTX DMA Cleanup Wrong Loop Index

## Deploy Steps

See [Rapid Release Update (RRU) for CSM kernel CVE fixes](README.md#release-notes).
