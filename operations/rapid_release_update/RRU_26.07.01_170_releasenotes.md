# Release Notes - Rapid-Update-sle15-sp6-170-26.07.01

This document guides an administrator through the deploy of Rapid Release Update on CSM-1.7.0.

This page documents the changes introduced by this RRU, compared to the previous RRU version.

* [Expected Kernel Version](#expected-kernel-version)
* [CVE fixes](#cves-fixes)
* [Deploy steps](#deploy-steps)

## Expected Kernel Version

`6.4.0-150600.23.125.1`

## CVEs Fixes

CVEs fixed which have NVD score > 9.

* `CVE-2026-46242` - Linux Kernel eventpoll ep_remove Use-After-Free
ep_remove() cleared file->f_ep but kept using the file inside the critical section, so a concurrent __fput() could observe the transient NULL, 
skip eventpoll_release_file(), and free the watched eventpoll, leading to a use-after-free and attacker-controllable wrong-cache free.
* `CVE-2026-43499` - Linux Kernel rtmutex remove_waiter() Use-After-Free
remove_waiter() operated on current instead of waiter::task during futex_requeue() proxy-lock rollback, dequeuing the rbtree without the correct
pi_lock and leaving a dangling pi_blocked_on pointer, resulting in a use-after-free and PI-chain corruption.
* `CVE-2026-53362` - Linux Kernel IPv6 Paged Allocation Heap Overflow
__ip6_append_data() mis-accounted for fraggap on the paged-allocation path, undersizing the linear area while overstating pagedlen,
so a UDPv6 socket using MSG_MORE with MSG_SPLICE_PAGES could write past skb->end into skb_shared_info. This flaw is listed in the CISA Known Exploited Vulnerabilities catalog.
* `CVE-2026-52943` - Linux Kernel skbuff pskb_carve Zerocopy Use-After-Free
pskb_carve_inside_header() and pskb_carve_inside_nonlinear() copied the shared-info destructor_arg (uarg) without calling net_zcopy_get(),
prematurely driving the ubuf_info refcount to zero and freeing it while TX skbs still referenced it; a local unprivileged user can achieve root privilege escalation.
* `CVE-2026-46331` - Linux Kernel net/sched pedit Partial COW Out-of-Bounds Write
tcf_pedit_act() computed the copy-on-write range once before the key loop without accounting for runtime header offsets from typed keys, leaving part of the write region un-COW'd and causing an out-of-bounds write that corrupts page cache memory.
* `CVE-2026-43074` - Linux Kernel eventpoll struct eventpoll Use-After-Free
ep_free() could kfree() the eventpoll struct while another concurrent thread was still using it during a nested-epoll RCU walk; the fix defers the free to an RCU grace period to prevent the use-after-free.
* `CVE-2026-46266` - Linux Kernel RAW Socket IPPROTO_RAW ICMP Route Cache Poisoning
A RAW socket on protocol IPPROTO_RAW (255) could match a malicious incoming ICMP packet whose inner protocol was set to 255, letting a remote attacker
inject attacker-controlled PMTU and gateway values into the FNHE route exception cache; the fix drops such incoming ICMP.
* `CVE-2026-53359` - Linux Kernel KVM x86 Shadow Paging Role Confusion Use-After-Free
When a modified PDE pointed to a non-leaf page, kvm_mmu_get_child_sp() reused a shadow page without comparing its role,
so a leaf SPTE's rmap entry survived after the shadow page was freed on memslot removal, causing a use-after-free exploitable as a guest-to-host escape.

## Deploy Steps

See [Rapid Release Update (RRU) for CSM kernel CVE fixes](README.md#release-notes).
