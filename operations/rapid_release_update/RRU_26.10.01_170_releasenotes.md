# Release Notes - Rapid-Update-sle15-sp6-170-26.10.01

This document guides an administrator through the deploy of Rapid Release Update on CSM-1.7.0.

This page documents the changes introduced by this RRU, compared to the previous RRU version.

* [Expected Kernel Version](#expected-kernel-version)
* [CVE fixes](#cves-fixes)
* [Deploy steps](#deploy-steps)

## Expected Kernel Version

`6.4.0-150600.23.138.1`

## CVEs Fixes

CVEs fixed which have NVD score > 9.

* `CVE-2026-63795` - Linux Kernel 9p Client Reference Underflow
The 9p client may drop an extra reference to a shared fid on a walk error path, which can clunk a still-in-use fid and trigger a use-after-free or refcount underflow.
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
ip_vs_in_icmp() left stale IPv4 option metadata after rebasing an skb, so a crafted outer timestamp option could point `__ip_options_echo()` at a stale offset and cause a stack out-of-bounds write in __icmp_send().
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
A vulnerability in the Linux kernel IPsec ESP output path may incorrectly allow a fast path when the combined packet fragment length exceeds a page.
A local user could potentially trigger memory corruption in packet processing, impacting confidentiality, integrity, or availability.
* `CVE-2026-63922` - Linux Kernel IPv6 Extension Header Pointer Handling Flaw
A flaw in IPv6 extension header parsing may continue using a stale network header pointer after packet buffer storage changes.
A local user could potentially trigger memory corruption during IPv6 packet processing, leading to privilege escalation or denial of service.
* `CVE-2026-63924` - Linux Kernel IPv6 Jumbo Header Pointer Handling Flaw
A vulnerability in IPv6 jumbo payload option handling may fail to refresh internal packet header pointers after packet buffer changes.
A local user could potentially trigger memory corruption during IPv6 extension header processing, affecting system confidentiality, integrity, or availability.
* `CVE-2026-63984` - Linux Kernel IPv6 RPL Header Length Overflow
A flaw in IPv6 RPL source routing header decompression may allow the computed header length to overflow and truncate.
A local user able to exercise affected RPL packet handling could cause header corruption, potentially leading to denial of service or broader kernel impact.
* `CVE-2026-63994` - Linux Kernel Tunnel PMTU Use-After-Free
A vulnerability in Linux kernel tunnel Path MTU Discovery handling may cache IP header pointers before a socket buffer copy-on-write operation that can move packet memory.
A local user could potentially trigger a use-after-free condition during tunnel ICMP or ICMPv6 processing, impacting confidentiality, integrity, or availability.
* `CVE-2026-64106` - Linux Kernel KVM ARM64 VGIC ITS Restore Validation Flaw
A flaw in KVM ARM64 virtual interrupt controller restore handling may accept a restored ITS device table entry with an out-of-range EventID size.
A local user with access to affected virtual machine restore paths could cause oversized table processing, potentially resulting in information disclosure or denial of service.
* `CVE-2026-64564` - Linux Kernel SCTP ASCONF DEL-IP Use-After-Free
A flaw in SCTP ASCONF DEL-IP processing can free the transport the ASCONF is being processed against, leaving a dangling pointer that is reused by a
following wildcard DEL-IP. This use-after-free can corrupt association state and lead to memory corruption or denial of service.
* `CVE-2026-64530` - Linux Kernel net/sched cls_api Use-After-Free
The traffic-control qevent handler did not account for TC_ACT_CONSUMED, so a socket buffer already consumed by the defragmentation engine
(for example act_ct on out-of-order fragments) could be reused by the RED qdisc, resulting in a use-after-free.
* `CVE-2026-53246` - Linux Kernel SCTP COOKIE_ECHO Cached INIT Out-of-Bounds Read
sctp_unpack_cookie() did not validate the cached peer INIT chunk length against the remaining COOKIE_ECHO buffer, so an inflated length could make the parameter walk run beyond the received data, causing out-of-bounds reads.
* `CVE-2026-53224` - Linux Kernel SCTP Cookie INIT and Address List Out-of-Bounds Read
sctp_unpack_cookie() did not ensure the embedded INIT chunk was large enough for a complete header and did not fully validate the raw address list length,
so a malformed COOKIE_ECHO could trigger out-of-bounds reads during parameter and address parsing.
* `CVE-2026-53131` - Linux Kernel Netfilter Ethernet Header Out-of-Bounds Access
Several netfilter and ipset paths accessed the Ethernet MAC header without first confirming the socket buffer is from an Ethernet device with a valid, fully present header, which could lead to out-of-bounds memory access.
* `CVE-2026-52986` - Linux Kernel Netfilter SIP Conntrack Out-of-Bounds Read
The SIP connection-tracking helper used unsafe port parsing with simple_strtoul() on non-NUL-terminated packet data, allowing out-of-bounds reads on malformed packets; the fix adds a bounds-checked port parser.
* `CVE-2026-64320` - Linux Kernel nvmet Discovery Get Log Page Pre-Auth Out-of-Bounds Heap Read
nvmet_execute_disc_get_log_page() validated only the alignment of the host-supplied log page offset, so an unauthenticated fabric peer could request
data at an offset past the allocated discovery buffer, leaking adjacent kernel memory or crashing the target.
* `CVE-2026-74597` - Linux Kernel IPv6 Tunnel Stale HAO Metadata Out-of-Bounds Access
ip6ip6_err() cloned an outer ICMP error skb and pulled it to the inner packet without clearing IP6CB, so a stale Home Address Option offset left in skb->cb let mip6_addr_swap() run past the quoted inner packet and corrupt skb_shared_info.
* `CVE-2026-74473` - Linux Kernel vxlan route_shortcircuit() Network Header Out-of-Bounds Read
route_shortcircuit() used pskb_may_pull() from skb->data instead of accounting for the MAC header offset, so in vxlan_xmit() the full IP header might not be pulled into the linear buffer, letting later ip_hdr() dereferences read beyond it.
* `CVE-2026-80725` - Linux Kernel GRO BIG TCP Aggregation Validation Out-of-Bounds Write
skb_gro_receive() loosened the BIG TCP checks and tested skb_headroom() instead of the space before the MAC header,
so crafted frames could aggregate beyond 64KB and ipv6_gro_complete()'s HBH jumbo header memmove() wrote out of bounds (stable 6.18.y only).
* `CVE-2026-72129` - Linux Kernel nvmet-rdma Inline Data Offset Length Underflow
nvmet_rdma_use_inline_sg() mapped a host-controlled inline data offset assuming the data began in the first inline page,
so with inline_data_size > PAGE_SIZE an offset past the page made "PAGE_SIZE - off" underflow, setting sg->length to ~4GiB and reading far past the inline page.
* `CVE-2026-90414` - Linux Kernel IB/isert Over-Declared Data Segment Out-of-Bounds Read
isert_recv_done() passed received PDUs to the opcode handlers without checking wc->byte_len, so an initiator declaring a data segment larger than
it actually sent caused out-of-bounds reads of the receive descriptor (and could write heap contents to the backing store).
* `CVE-2026-72398` - Linux Kernel SCTP COOKIE-ECHO Missing INIT Re-Verification
When cookie authentication was disabled, COOKIE-ECHO processing reconstructed the INIT chunk from the cookie without re-validating it, so tampered parameters could be processed; the fix adds sctp_verify_init() checks and tightens cookie unpacking.
* `CVE-2026-89702` - Linux Kernel NFSD fh_verify Tracepoint Sockaddr Slot Overflow
The nfsd_fh_verify tracepoints sized the server sockaddr slot by xpt_remotelen but filled it from xpt_local using xpt_locallen, so on NFS/UDP (where xpt_remotelen stays 0) __assign_sockaddr's memcpy wrote past the reserved ring-buffer slot.
* `CVE-2026-80976` - Linux Kernel seg6 Stale IP6CB Out-of-Bounds Read After Decapsulation
After SRv6 decapsulation, End.DX6/End.DT6 routed the inner IPv6 packet with the outer packet's IP6CB still set, so a stale nhoff from outer extension
headers made ip6_protocol_deliver_rcu() read beyond the skb head; the fix resets IP6CB for the inner packet.
* `CVE-2026-89636` - Linux Kernel SMB Client DFS Cache tgthint Use-After-Free
free_tgts() freed all cache_dfs_tgt structures in ce->tlist but left ce->tgthint pointing at a freed entry, resulting in a use-after-free if tgthint was used later; the fix sets ce->tgthint to NULL.
* `CVE-2026-74616` - Linux Kernel XDP Clone skb_shared_info Tailroom Overrun
xdpf_clone() set frame_sz to PAGE_SIZE, but a source frame from a larger allocation could pass the existing size check while extending into the clone's shared-info area,
so converting back to an skb placed skb_shared_info over live packet bytes; the fix rejects clones that don't fit SKB_WITH_OVERHEAD(PAGE_SIZE).
* `CVE-2026-80714` - Linux Kernel IPVS One-Packet Flag Synced Connection Use-After-Free
ip_vs_bind_dest() copied IP_VS_CONN_F_ONE_PACKET from a destination onto an already-hashed synced connection, so expiry could skip unlinking the conn_tab node,
leaving stale hash nodes pointing at a freed ip_vs_conn; the fix drops the one-packet flag for synced connections.
* `CVE-2026-89533` - Linux Kernel svcrdma read_chunk_range Offset Arithmetic Underflow
svc_rdma_read_chunk_range() used a '>' skip predicate and mis-bracketed the length cap, so a fully consumed segment fell through and
min_t(u32, length, rs_length) - rs_length underflowed to near-UINT_MAX, propagating a huge nr_bvec into a multi-MiB allocation.
* `CVE-2026-74267` - Linux Kernel net/sched sch_codel Peek Backlog Wild Memory Access
codel called qdisc_tree_reduce_backlog() during peek before restoring qlen, so if qlen dropped to zero while peek still returned an skb, the parent's qlen_notify deactivated the class prematurely, causing a wild memory access (e.g. with qfq as parent).
* `CVE-2026-74406` - Linux Kernel vxlan GRO Null Pointer Dereference
udp_tunnel_sock_release() could set sk->sk_user_data to NULL while vxlan_gro_prepare_receive() ran, so the function could dereference a NULL sk_user_data; the fix re-checks for NULL after skb_gro_remcsum_init().
* `CVE-2026-74608` - Linux Kernel SMB Client cifs_try_adding_channels Use-After-Free
cifs_try_adding_channels() dropped its temporary iface reference before incrementing iface->weight_fulfilled, so a concurrent interface-list
refresh could free the iface via the last kref_put, making the later update a use-after-free; the fix updates weight_fulfilled first.
* `CVE-2026-72323` - Linux Kernel IPv4 IGMP Timer Use-After-Free
A race between inetdev_destroy() and igmp_rcv() let igmp_gq_start_timer() re-arm a timer and call in_dev_hold() on an in_device whose refcount had hit 0 (RCU-freed), leading to a use-after-free when the timer fired; the fix uses in_dev_hold_safe().
* `CVE-2026-74476` - Linux Kernel veth frag_list XDP AF_XDP Copy-Mode Crash
veth_convert_skb_to_xdp_buff() exposed frag_list skbs (data_len set, nr_frags zero) to XDP using skb_is_nonlinear(), so AF_XDP copy mode trusted
bogus fragment metadata and crashed in memcpy(); the fix routes non-linear skbs through skb_pp_cow_data() first.
* `CVE-2026-89482` - Linux Kernel nvme-tcp WRITE_ZEROES C2HData Wild Memory Access
The receive side accepted a C2HData based on blk_rq_payload_bytes() alone, which is nonzero for REQ_OP_WRITE_ZEROES (no physical segments),
so nvme_tcp_recv_data() copied into a tag's stale residual iterator; the fix also gates on req->data_len.
* `CVE-2026-74586` - Linux Kernel SCTP new_transport Use-After-Free on Peer Removal
An authenticated ASCONF that added then wildcard-deleted a transport in one chunk removed the new peer without clearing asoc->new_transport,
so sctp_sf_do_asconf() queued a HEARTBEAT to the freed transport, later read by sctp_outq_select_transport() as a use-after-free.
* `CVE-2026-64319` - Linux Kernel nvmet-auth DHCHAP_REPLY Pre-Auth Out-of-Bounds Read
nvmet_auth_reply() accessed the variable-length rval[] array using attacker-controlled hl and dhvlen fields without checking they fit the
tl-byte buffer, so a crafted DHCHAP_REPLY caused pre-authentication out-of-bounds heap reads (up to 526 bytes past the buffer).
* `CVE-2026-72322` - Linux Kernel IPv6 MLD Delayed Work Use-After-Free
A race between device teardown and MLD query processing let igmp6_event_query() schedule delayed work and call in6_dev_hold() on an inet6_dev
whose refcount had hit 0 (RCU-freed), freeing it while the work was scheduled; the fix uses in6_dev_hold_safe().
* `CVE-2026-74480` - Linux Kernel Bridge Fast-Leave Port Group Use-After-Free
br_multicast_leave_group()'s fast-leave path advanced its list pointer through an entry already removed by br_multicast_del_pg(),
so with multicast-to-unicast duplicate port groups it could continue from a stale next pointer, leaving mp->ports dangling; the fix breaks after deletion.
* `CVE-2026-100075` - Linux Kernel RDMA/srpt rw_ctx Unwind Counter Desync
When srpt_alloc_rw_ctxs() failed partway through a multi-buffer descriptor, the unwind path left stale n_rw_ctx/n_rdma values and a dangling
rw_ctxs pointer, so later send-queue credit accounting could subtract the wrong number of credits; the fix resets the counters.
* `CVE-2026-74744` - Linux Kernel ipvlan Missing Headroom/Tailroom Reservation
ipvlan devices inherited hard_header_len but left needed_headroom and needed_tailroom at 0, so when the lower device required extra space
upper layers under-reserved it, causing reallocation, skb headroom underflows, or slab use-after-free; the fix inherits both from phy_dev.
* `CVE-2026-74752` - Linux Kernel SCTP Cookie AUTH State Validation
With cookie authentication disabled, COOKIE_ECHO restored fixed-size AUTH fields directly from peer-controlled cookie bytes, so a forged RANDOM length
or HMAC id caused out-of-bounds reads and a 32-byte write past a zero-length AUTH chunk; the fix validates RANDOM, HMACS, and CHUNKS first.
* `CVE-2026-89674` - Linux Kernel NFSD Layoutget XDR Length Miscalculation
nfsd4_ff_encode_layoutget()'s XDR buffer size calculation mis-sized opaque fields and omitted fields, so it could write up to 5 bytes past the
reserved buffer or leak uninitialized memory to the client; the fix breaks out every field using xdr_align_size().
* `CVE-2026-72098` - Linux Kernel dm-verity FEC Erasure Buffer Overflow
dm-verity-fec allowed *neras to reach roots + 1, which was passed as no_eras to decode_rs8() where the erasure locator loop wrote lambda[] one element past its end, landing on syn[0] and corrupting the syndrome buffer.
* `CVE-2026-90413` - Linux Kernel IB/isert Login PDU Over-Declared Length Out-of-Bounds Read
isert did not validate a login PDU's declared DataSegmentLength against the bytes actually received, so an initiator declaring more than it sent caused out-of-bounds reads past the fixed MAX_KEY_VALUE_PAIRS login buffer in both login paths.
* `CVE-2026-74688` - Linux Kernel SCTP Queued Control Chunk Transport Use-After-Free
sctp_make_heartbeat_ack() cached the destination transport in chunk->transport without a reference, so a HEARTBEAT ACK queued on control_chunk_list
retained a dangling pointer after the peer transport was removed, leading to a use-after-free on transmit; the fix clears queued chunk transports.
* `CVE-2026-74493` - Linux Kernel net/smc Link Group Termination Socket Use-After-Free
__smc_lgr_terminate() dropped conns_lock after finding a connection but before taking a socket reference, so a concurrent close could free the socket before sock_hold() ran; the fix takes the reference while conns_lock still protects the tree entry.
* `CVE-2026-74398` - Linux Kernel IPv6 addrconf DAD Failure State Race Use-After-Free
addrconf_dad_failure() dropped ifp->lock during processing, letting a concurrent ipv6_del_addr() set the state to DEAD and remove the entry,
after which the function overwrote DEAD with ERRDAD and rescheduled work that hit the poisoned list entry; the fix verifies the state is still POSTDAD.
* `CVE-2026-72399` - Linux Kernel enetc XDP Frame BD Count Out-of-Bounds Write
enetc did not check the number of buffer descriptors needed for an xdp_frame against the ENETC_MAX_SKB_FRAGS-sized xdp_redirect_arr array, so an xdp_frame with too many fragments caused an out-of-bounds access.
* `CVE-2026-89479` - Linux Kernel SCTP Bundled Chunk Association Use-After-Free
sctp_endpoint_bh_rcv() cached the association without a reference and had no dead-association check, so a peer bundling COOKIE ECHO,
SHUTDOWN and SHUTDOWN ACK could free the association mid-packet and the next chunk wrote to the freed transport; the fix discards the packet before deletion.
* `CVE-2026-90104` - Linux Kernel NFSv4.1 CB_SEQUENCE Uninitialized Referring Call List
decode_cb_sequence_args() allocated csa_rclists uninitialized and decode_rc_list() left rcl_refcalls unset for zero-referring-call lists, so nfs4_callback_sequence() later passed stale slab contents to kfree(); the fix zero-allocates the lists.
* `CVE-2026-89532` - Linux Kernel svcrdma Empty Chunk Segment Underflow
pcl_for_each_segment computed a zero-segcount chunk's upper bound as &ch_segments[ch_segcount - 1], wrapping the u32 to 0xFFFFFFFF,
so with Send-With-Invalidate a wire chunk advertising zero segments made svc_rdma_get_inv_rkey() read out of bounds; the fix uses a half-open bound.
* `CVE-2026-74737` - Linux Kernel TI AM65 CPSW Source Tag Port ID Out-of-Bounds Access
am65-cpsw-nuss extracted a 16-bit Source Tag as the port_id, but only the lower 8 bits are the MAC port ID (the upper bits are hardware-reserved
arbitrary values), so an invalid port_id indexed past the ports[] array and caused sporadic out-of-bounds access and crashes.
* `CVE-2026-72348` - Linux Kernel netfilter ip6tables Malformed Extension Header Rule Bypass
The ah, hbh and rt ip6tables matches returned false (rule mismatch) instead of setting hotdrop when an advertised extension-header length exceeded the
available skb data, so malformed IPv6 packets could bypass DROP rules; the fix sets hotdrop for these cases.
* `CVE-2026-74743` - Linux Kernel macvlan Missing Headroom/Tailroom Reservation
macvlan devices inherited hard_header_len but left needed_headroom and needed_tailroom at 0, so when the lower device required extra space upper
layers under-reserved it, causing reallocation, skb headroom underflows, or slab use-after-free; the fix inherits both from lowerdev.
* `CVE-2026-72351` - Linux Kernel GUE REMCSUM Private Option Length Validation
guehdr_priv_flags_len() returned 0 even when GUE_PFLAG_REMCSUM was set, so a packet with only the private flags field passed validate_gue_flags() and
gue_remcsum() read the missing REMCSUM start/offset from following bytes; the fix accounts for GUE_PLEN_REMCSUM.
* `CVE-2026-89542` - Linux Kernel SUNRPC gss_krb5_unwrap_v2 Short Token Memory Corruption
gss_krb5_unwrap_v2() read EC/RRC fields and rotated the buffer before validating the token length, so a short or over-declared krb5p token caused
out-of-bounds reads, a u32 wrap, a divide-by-zero, and a dead BUG_ON that let movelen underflow into a ~UINT_MAX memmove().
* `CVE-2026-89631` - Linux Kernel SMB Client Tree Connect ByteCount Underflow
CIFSTCon() computed its byte-area bound as ByteCount minus two, which for ByteCount 0 or 1 went negative and wrapped the __u16 bytes_left,
so cifs_strndup_from_utf16() ran off the ~16KB request object and leaked kernel memory via tcon->nativeFileSystem; the fix rejects undersized byte areas.
* `CVE-2026-74588` - Linux Kernel SCTP chunk->transport Retransmit Use-After-Free
__sctp_outq_flush_rtx() moved a gap-acked chunk onto another transport's list without updating chunk->transport, so if the named transport was removed
the chunk kept a dangling pointer, and a later SACK that reneged the TSN dereferenced the freed transport; the fix rebinds chunk->transport at the move.
* `CVE-2026-89551` - Linux Kernel SUNRPC xdr_buf_trim Length Underflow
xdr_buf_trim() subtracted the consumed byte count from buf->len without clamping, so when buf->len was smaller than the summed iov_lens
(as in gss_krb5_unwrap_v2) the unsigned subtraction wrapped to near UINT_MAX and propagated as the stream bound into XDR decoders; the fix clamps the decrement.

## Deploy Steps

See [Rapid Release Update (RRU) for CSM kernel CVE fixes](README.md#release-notes).
