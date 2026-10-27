# Release Notes - Rapid-Update-sle15-sp6-170-26.10.01

This document guides an administrator through the deploy of Rapid Release Update on CSM-1.7.1

This page documents the changes introduced by this RRU, compared to the previous RRU version. 

* [Expected Kernel Version](#expected-kernel-version)
* [CVE fixes](#cve-fixes)
* [Deploy steps](#deploy-steps)

## Expected Kernel Version

`6.4.0-150600.23.138.1`

## CVEs Fixes

CVEs fixed which have NVD score > 9.

* `CVE-2026-63886` - Linux Kernel iSCSI Target CHAP_R Base64 Heap Overflow
The iSCSI target CHAP authentication path base64-decoded a CHAP_R response without validating its length, so an oversized response could write past the fixed-size client_digest buffer, causing a heap overflow.
* `CVE-2026-63887` - Linux Kernel iSCSI Target Text Response Heap Overrun
iscsi_encode_text_output() appended "key=value" records into the fixed 8 KiB login response buffer without bounds checking, so a crafted Login PDU expanding many unknown keys could overrun the kmalloc-8k slab.
* `CVE-2026-63888` - Linux Kernel iSCSI Target Text Command CRC Overread and Double-Free
iscsit_handle_text_cmd() read 4 bytes past the text_in allocation when computing the DataDigest CRC, and on an ERL>0 bad-digest drop left a stale pointer that could be freed again, leading to an out-of-bounds read and double-free.
* `CVE-2026-63992` - Linux Kernel Tunnel PMTU ICMP Out-of-Bounds Access
iptunnel_pmtud_check_icmp() assumed the skb transport header was set, so when it was not, the computed offset caused an out-of-bounds access while decoding the ICMP header during tunnel PMTU handling.
* `CVE-2026-64000` - Linux Kernel HSR Supervision Frame Out-of-Bounds Read
The HSR supervision frame handler did not linearize the entire TLV header before accessing it, so a truncated frame could trigger an out-of-bounds read.
* `CVE-2026-64007` - Linux Kernel Netfilter SYNPROXY Stale TCP Header Use-After-Free
synproxy_tstamp_adjust() cached a TCP header pointer that could be freed by skb_ensure_writable() on a cloned or non-linear skb, so the later checksum update wrote into freed memory or produced a stale on-wire checksum.
* `CVE-2026-64018` - Linux Kernel MANA Out-of-Bounds Array Access
In mana_hwc_rx_event_handler(), rx_req_idx was derived from DMA-coherent memory without a bounds check, allowing an out-of-bounds access into the reqs[] array, especially in Confidential VMs where the memory is host-modifiable.
* `CVE-2026-64034` - Linux Kernel MANA TOCTOU Double-Fetch
hwc_msg_id was read twice from a shared DMA buffer in the MANA driver, allowing a time-of-check/time-of-use double-fetch that could bypass the bounds check and corrupt memory, particularly in Confidential VMs.
* `CVE-2026-74669` - Linux Kernel IPVS Tunnel ICMP Stack Out-of-Bounds Write
ip_vs_in_icmp() left stale IPv4 option metadata after rebasing an skb, so a crafted outer timestamp option could point __ip_options_echo() at a stale offset and cause a stack out-of-bounds write in __icmp_send().
* `CVE-2026-74612` - Linux Kernel veth XDP skb Length Accounting Flaw
After an XDP program adjusted the fragment area, veth_xdp_rcv_skb() left skb->len out of sync with the linear area, causing copies past the linear tail that leaked shared-info and kernel pointers to userspace and could trigger SKB_LINEAR_ASSERT().
* `CVE-2026-74581` - Linux Kernel IPv6 Suppressed FIB6 Rule Use-After-Free
fib6_rule_suppress() released a suppressed route but left res->rt6 pointing at it, so a suppressing rule could leak a freed route back to rt6_lookup(), leading to a use-after-free on the next put.
* `CVE-2026-74556` - Linux Kernel libiscsi_tcp SCSI Response Buffer Overflow
The iSCSI TCP code copied the SCSI Command Response data segment into the fixed 8192-byte conn->data buffer without checking DataSegmentLength, so a target returning an oversized response could overflow the buffer.
* `CVE-2026-74394` - Linux Kernel RDMA/srpt Immediate Data Integer Overflow
A user-controlled immediate data length was added to an offset without overflow checking in the SRP target, so a malicious initiator could wrap req_size, bypass the bounds check, and pass a ~4GB length to sg_init_one().
* `CVE-2026-74345` - Linux Kernel RDMA/siw Endpoint Socket Use-After-Free
siw_socket_disassoc() could release the last reference on an endpoint and free it, but the caller then cleared the endpoint's socket pointer afterward, causing a slab-use-after-free when processing a malformed MPA request.
* `CVE-2026-72339` - Linux Kernel qede Off-by-One BD Ring Desynchronization
qede_rx_build_skb() and qede_tpa_rx_build_skb() did not check for a NULL return from qede_build_skb(), so under memory pressure an extra BD was consumed, desynchronizing the ring and corrupting DMA refcounts and the SLUB freelist.
* `CVE-2026-72317` - Linux Kernel SUNRPC TLS connect_worker Use-After-Free
Nothing pinned the upper rpc_clnt across the delayed TLS connect_worker, so on a fatal handshake failure the rpc_clnt could be freed before xs_tcp_tls_setup_socket() dereferenced it, causing a use-after-free and refcount underflow.
* `CVE-2026-72289` - Linux Kernel KVM arm64 vGIC Interrupt Migration Use-After-Free
vgic_prune_ap_list() assumed an interrupt with unchanged affinity was still queued on the vCPU's ap_list, so if it was removed while the locks were dropped, list_del() ran a second time on an already-removed entry.
* `CVE-2026-72288` - Linux Kernel KVM arm64 vGIC LPI Disable Race Use-After-Free
A race between interrupt affinity change and LPI disabling let vgic_prune_ap_list() drop and reacquire locks while an IRQ was freed, causing a use-after-free; the fix takes a reference and stops migrating the pending bit.
* `CVE-2026-72251` - Linux Kernel Netfilter nf_nat_sip Stale Data Pointer
nf_nat_sip() failed to reload the data pointer after skb_ensure_writable() could reallocate a cloned skb, so it used a freed buffer and could also misapply UDP mangling to TCP streams; the fix rebuilds the pointer and restricts to UDP.
* `CVE-2026-72222` - Linux Kernel SUNRPC TLS Handshake Callback Use-After-Free
svc_tcp_handshake() did not pin the svc_xprt across the asynchronous TLS handshake callback, so a close race could free the svc_sock while the in-flight callback was still writing through it, corrupting slab memory.
* `CVE-2026-72221` - Linux Kernel SUNRPC TLS Cancel Race Use-After-Free
When tls_handshake_cancel() lost the cancellation race in svc_tcp_handshake(), the code inspected xpt_flags before the callback committed, allowing double handshake invocation and corruption of the embedded wait queue.
* `CVE-2026-72084` - Linux Kernel SCSI Target PR-OUT TransportID Out-of-Bounds Read
The PERSISTENT RESERVE OUT TransportID parser used an unbounded strstr() on an iSCSI name with no length limit, so a malformed TransportID without a separator or terminator could run the scan off the end of the parameter buffer.
* `CVE-2026-72083` - Linux Kernel SCSI Target REGISTER AND MOVE Use-After-Free
core_scsi3_emulate_pro_register_and_move() unmapped the parameter buffer before dereferencing an iSCSI ISID pointer into it, so for multi-page (vmap) buffers every later dereference was a use-after-free of the unmapped region.
* `CVE-2026-72069` - Linux Kernel locking/rt rt_spin_unlock() RCU Use-After-Free
rt_spin_unlock() released RCU protection before unlocking, opening a use-after-free window where a concurrent reader could free the object before the unlock completed; the fix moves rcu_read_unlock() past the unlock.
* `CVE-2026-72020` - Linux Kernel IPVS ip_vs_conn_new Uninitialized Sequence Data
ip_vs_conn_new() left init_seq and previous_delta of the ip_vs_seq members uninitialized, so a crafted sync message could hash a connection with SEQ flags set but stale slab data, letting forwarded TCP packets carry stale bytes.
* `CVE-2026-68426` - Linux Kernel xfrm Async Crypto Stale skb Use-After-Free
When async crypto stole the last GSO segment in validate_xmit_xfrm(), the list head's ->prev was left pointing at the freed segment, so validate_xmit_skb_list() wrote through a stale pointer, causing a use-after-free.
* `CVE-2026-68160` - Linux Kernel Ceph Pre-Auth Snaptrace Out-of-Bounds Read
ceph_handle_caps() used an attacker-controlled snap_trace_len to build a fake end pointer without validation, so a malicious MDS setting hdr.version=1 could reach the IMPORT path and trigger out-of-bounds reads past the message buffer.
* `CVE-2026-68159` - Linux Kernel libceph pg_temp/pg_upmap Stack Out-of-Bounds Write
__decode_pg_temp() did not bound the decoded length to CEPH_PG_MAX_SIZE, so a monitor sending an oversized pg_temp/pg_upmap entry could overflow the fixed-size on-stack ceph_osds.osds array, causing a stack out-of-bounds write.
* `CVE-2026-68158` - Linux Kernel libceph OSDMap Multiplication Overflow
decode_new_up_state_weight() computed the new_state length with a multiplication that could overflow, producing an incorrect bounds check and allowing out-of-bounds reads when decoding a corrupted osdmap; the fix uses check_mul_overflow().
* `CVE-2026-68136` - Linux Kernel GRO Double Aggregation NULL Dereference
skb_gro_receive_list() lacked the flush check present in skb_gro_receive(), so flush-marked packets could be re-aggregated, corrupting the frag_list chain and causing a kernel panic in skb_segment() on a NULL/corrupted pointer.
* `CVE-2026-64541` - Linux Kernel net/smc smc_cdc_rx_handler() Socket Use-After-Free
smc_cdc_rx_handler() dereferenced the connection and socket after dropping conns_lock without holding a reference, so a concurrent close could free the smc_sock before the handler's sock_hold() ran, causing a use-after-free (SMC-R only).
* `CVE-2026-64450` - Linux Kernel TIPC Broadcast Gap ACK Out-of-Bounds Read
tipc_get_gap_ack_blks() verified only internal consistency of a broadcast Gap ACK record, not that it fit in the message data area, so the broadcast path copied the record with an attacker-controlled count, reading off the end of the skb.
* `CVE-2026-64387` - Linux Kernel SMB Client Query Directory Replay Double-Free
In SMB2_query_directory(), a replayable error freed the response buffer but retained the stale buffer type, so if the next init failed before sending, cleanup freed the same response again; the fix resets response bookkeeping per attempt.
* `CVE-2026-64386` - Linux Kernel SMB Client Query Info Replay Double-Free
SMB2_query_info() retained stale response bookkeeping across replay attempts, so a replayable error followed by an init failure caused the previous response buffer to be freed a second time.
* `CVE-2026-64385` - Linux Kernel SMB Client IOCTL Replay Double-Free
SMB2_ioctl() kept its response buffer bookkeeping across replay attempts, so a replayable error and a failed subsequent init led to a double-free of the stale response buffer.
* `CVE-2026-64384` - Linux Kernel SMB Client Change Notify Replay Double-Free
SMB2 change-notify handling retained the previous buffer type across replay attempts, so a replayable error followed by a failed init freed the stale response buffer a second time.
* `CVE-2026-64383` - Linux Kernel SMB Client Flush Replay Double-Free
SMB2_flush() kept its response buffer bookkeeping across replay attempts, so a replayable flush response followed by a failed retry freed the stale response pointer a second time; the fix reinitializes state at the top of the replay loop.
* `CVE-2026-64355` - Linux Kernel BPF devmap Fragmented Frame Out-of-Bounds Access
Devmap broadcast redirect cloning copied only the linear xdp_frame data, so cloning a fragmented frame left HAS_FRAGS set without valid metadata, causing an out-of-bounds access on frame return; the fix rejects fragmented frames.
* `CVE-2026-64268` - Linux Kernel RDMA/siw Read Response Out-of-Bounds Write
siw_proc_rresp() never checked the accumulated Read Response placement offset against the sink buffer length on continuation segments, so a peer could drive wqe->processed past the buffer and write out of bounds at sge->laddr + wqe->processed.
* `CVE-2026-63912` - Linux Kernel IPsec ESP Page Fragment Handling Flaw
A vulnerability in the Linux kernel IPsec ESP output path may incorrectly allow a fast path when the combined packet fragment length exceeds a page. A local user could potentially trigger memory corruption in packet processing, impacting confidentiality, integrity, or availability.
* `CVE-2026-63922` - Linux Kernel IPv6 Extension Header Pointer Handling Flaw
A flaw in IPv6 extension header parsing may continue using a stale network header pointer after packet buffer storage changes. A local user could potentially trigger memory corruption during IPv6 packet processing, leading to privilege escalation or denial of service.
* `CVE-2026-63924` - Linux Kernel IPv6 Jumbo Header Pointer Handling Flaw
A vulnerability in IPv6 jumbo payload option handling may fail to refresh internal packet header pointers after packet buffer changes. A local user could potentially trigger memory corruption during IPv6 extension header processing, affecting system confidentiality, integrity, or availability.
* `CVE-2026-63984` - Linux Kernel IPv6 RPL Header Length Overflow
A flaw in IPv6 RPL source routing header decompression may allow the computed header length to overflow and truncate. A local user able to exercise affected RPL packet handling could cause header corruption, potentially leading to denial of service or broader kernel impact.
* `CVE-2026-63994` - Linux Kernel Tunnel PMTU Use-After-Free
A vulnerability in Linux kernel tunnel Path MTU Discovery handling may cache IP header pointers before a socket buffer copy-on-write operation that can move packet memory. A local user could potentially trigger a use-after-free condition during tunnel ICMP or ICMPv6 processing, impacting confidentiality, integrity, or availability.
* `CVE-2026-64106` - Linux Kernel KVM ARM64 VGIC ITS Restore Validation Flaw
A flaw in KVM ARM64 virtual interrupt controller restore handling may accept a restored ITS device table entry with an out-of-range EventID size. A local user with access to affected virtual machine restore paths could cause oversized table processing, potentially resulting in information disclosure or denial of service.
* `CVE-2026-64564` - Linux Kernel SCTP ASCONF DEL-IP Use-After-Free
A flaw in SCTP ASCONF DEL-IP processing can free the transport the ASCONF is being processed against, leaving a dangling pointer that is reused by a following wildcard DEL-IP. This use-after-free can corrupt association state and lead to memory corruption or denial of service.
* `CVE-2026-64530` - Linux Kernel net/sched cls_api Use-After-Free
The traffic-control qevent handler did not account for TC_ACT_CONSUMED, so a socket buffer already consumed by the defragmentation engine (for example act_ct on out-of-order fragments) could be reused by the RED qdisc, resulting in a use-after-free.
* `CVE-2026-53246` - Linux Kernel SCTP COOKIE_ECHO Cached INIT Out-of-Bounds Read
sctp_unpack_cookie() did not validate the cached peer INIT chunk length against the remaining COOKIE_ECHO buffer, so an inflated length could make the parameter walk run beyond the received data, causing out-of-bounds reads.
* `CVE-2026-53224` - Linux Kernel SCTP Cookie INIT and Address List Out-of-Bounds Read
sctp_unpack_cookie() did not ensure the embedded INIT chunk was large enough for a complete header and did not fully validate the raw address list length, so a malformed COOKIE_ECHO could trigger out-of-bounds reads during parameter and address parsing.
* `CVE-2026-53131` - Linux Kernel Netfilter Ethernet Header Out-of-Bounds Access
Several netfilter and ipset paths accessed the Ethernet MAC header without first confirming the socket buffer is from an Ethernet device with a valid, fully present header, which could lead to out-of-bounds memory access.
* `CVE-2026-52986` - Linux Kernel Netfilter SIP Conntrack Out-of-Bounds Read
The SIP connection-tracking helper used unsafe port parsing with simple_strtoul() on non-NUL-terminated packet data, allowing out-of-bounds reads on malformed packets; the fix adds a bounds-checked port parser.

## Deploy Steps

See [Rapid Release Update (RRU) for CSM kernel CVE fixes](rru_overview.md#release-notes).