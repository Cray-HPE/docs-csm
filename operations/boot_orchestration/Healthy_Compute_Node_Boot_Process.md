# Healthy Compute Node Boot Process

In order to investigate node boot-related issues, it is important to understand the flow of a healthy boot process and the associated components. This section outlines the normal flow of components that play a role in booting compute nodes, including DHCP, BSS, and TPTP.

### DHCP

A healthy DHCP exchange between server and client looks like the following:

|Traffic|Description|Sender|
|-------|-----------|------|
|DHCP Discover|A broadcast request from the client requesting an IP address. The request contains the client's MAC address.|Client|
|DHCP Offer|The server offers an IP address to the client.|Server|
|DHCP Request|After testing the IP address to see that it is not in use, the client requests the proffered IP address.|Client|
|DHCP ACK|The server acknowledges that the client owns the lease on the IP address.|Server|

The following figure shows what a healthy DHCP discover process looks like via Wireshark, which is a packet analyzer:

![Healthy DHCP Discover Sequence Displayed on the Wireshark UI](../../img/operations/Wireshark_Healthy_DHCP_Discover_Sequence.png)

The DHCP client uses port 68, whereas the DHCP server uses port 67. Unlike most Kubernetes pods, the DHCP pod is located on the host network.

### TFTP

A healthy TFTP exchange between server and client looks like the following.

|Traffic|Description|Sender|
|-------|-----------|------|
|`Read Request File: filename tsize=0`|The client requests a file with a `tsize` equal to zero.|Client|
|`Option Acknowledgement`|The server acknowledges the request and provides the file's size and block transfer size.|Server|
|`Error Code, Code: Option negotiation failed, Message: User aborted the transfer`|The client aborts the transfer once it determines the file size.|Client|
|`Read Request File: filename`|The client requests the file again.|Client|
|`Option Acknowledgement`|The server acknowledges the request and provides the block transfer size.|Server|
|`Acknowledgement, Block: 0`|The client acknowledges the server.|Client|
|`Data Packet, Block: 1`|The server sends the first data packet.|Server|
|`Acknowledgement, Block: 1`|The client acknowledges reception of block 1.|Client|

The last two steps repeat until the file transfer is complete. The last block from the server will be labeled as \(`Last`\). The TFTP server listens on port 69. Kubernetes forwards port 69 on every node in the Kubernetes cluster to the TFTP pod.

### Boot Script Service \(BSS\)

A healthy transaction with the Boot Script Service \(BSS\) looks similar to the following:

```bash
ncn-m001# cray bss bootscript list --mac a4:bf:01:3e:c0:a2
#!ipxe
kernel --name kernel http://rgw.local:8080/boot-images/29c2cc23-a9d6-4e9a-ab1a-b5fa9270c975/kernel?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=5RN45WD0L8KY8W4317WP%2F20200326%2Fdefault%2Fs3%2Faws4_request&X-Amz-Date=20200326T185958Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=43f5b0c5909ee51dabc564d2b72401983ff8fd03cc6fc309b04cb16e67f1989d initrd=initrd console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999 root=craycps-s3:s3://boot-images/29c2cc23-a9d6-4e9a-ab1a-b5fa9270c975/rootfs:8c274aecef9e1668a8a44e8cfc2b24b5-165:dvs:api-gw-service-nmn.local:300:eth0 xname=x3000c0s17b4n0 nid=4 || goto boot_retry
initrd --name initrd http://rgw.local:8080/boot-images/29c2cc23-a9d6-4e9a-ab1a-b5fa9270c975/initrd?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=5RN45WD0L8KY8W4317WP%2F20200326%2Fdefault%2Fs3%2Faws4_request&X-Amz-Date=20200326T185958Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=d18f8da89108b9f2e659d7bbefcd106d5f13703a59f8ca837bcbc5938a9f9cc5 || goto boot_retry
boot || goto boot_retry
:boot_retry
sleep 30
chain https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?mac=a4:bf:01:3e:f9:28&retry=1
```

