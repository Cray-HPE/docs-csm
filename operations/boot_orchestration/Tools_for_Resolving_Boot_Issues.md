# Tools for Resolving Compute Node Boot Issues

A number of tools can be used to analyze and debug issues encountered during the compute node boot process. The underlying issue and symptoms dictate the type of tool required.

### nmap

Use `nmap` to send out DHCP Discover requests to test DHCP. `nmap` can be installed using the following command:

```bash
ncn-m001# zypper install nmap
```

To reach the DHCP server, the request generally needs to be sent over the Node Management network \(NMN\) from the non-compute node \(NCN\).

In the following example, `nmap` is used to send a broadcast request over the `eth1` interface:

```bash
ncn-m001# nmap --script broadcast-dhcp-discover -e eth1
```

### Wireshark

Use Wireshark to display network traffic. It has powerful display filters that help find information that can be used for debugging. To learn more, visit [https://www.wireshark.org](https://www.wireshark.org)

### tcpdump

Use `tcpdump` to capture network traffic, such as DHCP or TFTP requests. It can be installed using the following mechanisms:

-   Install `tcpdump` inside an Alpine-based pod:

    ```bash
    alpine_pod# apk add --no-cache tcpdump
    ```

-   Install `tcpdump` on an NCN or some other node that is running SUSE:

    ```bash
    ncn-m001# zypper install tcpdump
    ```


Invoking `tcpdump` without any arguments will write all of its output to `stdout`. This is reasonable for some tasks, but the volume of traffic that `tcpdump` can capture is large, so it is often better to write the output to a file.

Use the following command to send `tcpdump` output to stdout:

```bash
pod# tcpdump
```

Use the following command to send `tcpdump` output to a file, such as a filed named tcpdump.output in the following example:

```bash
pod# tcpdump -w /tmp/tcpdump.output
```

Use either `tcpdump` or Wireshark to read from the tcpdump file. Here is how to read the file using `tcpdump`:

```bash
pod# tcpdump -r /tmp/tcpdump.output
```

Filtering the traffic using `tcpdump` filters is not recommended because when a TFTP server answers a client they will usually use an ephemeral port that the user may not be able to identify and will not be captured by `tcpdump`. It is better to capture everything with `tcpdump` and then filter with Wireshark when looking at the resulting output. Filtering on DHCP traffic can be performed because that uses ports 67 and 68 specifically.

### TFTP Client

Use a TFTP client to send TFTP requests to the TFTP server. This will test that the server is functional. TFTP requests can be sent from the NCN, remote node, or laptop, as long as it targets the NMN.

Install the TFTP client using the following command:

```bash
ncn-m001# zypper install atftp
```

The `atftp` TFTP client can be used to request files from the TFTP server. The TFTP server is on the NMN and listens on port 69. The TFTP server sends the ipxe.efi file as the response in this example.

```bash
ncn-m001# atftp
ncn-m001# atftp
tftp> connect 10.100.160.2 69
tftp> get ipxe.efi test-ipxe.efi
tftp> quit
ncn-m001# ls -l test-ipxe.efi
-rw-r--r-- 1 root root 951904 Sep 11 10:44 test-ipxe.efi
```

### Serial Over Lan \(SOL\) Sessions

There are two tools that can be used to access a BMC's console via SOL:

-   ipmitool - ipmitool is a utility for controlling IPMI-enabled devices.

    Use the following command to access a node's SOL via ipmitool:

    ```bash
    ncn-m001# export USERNAME=root
    ncn-m001# export IPMI_PASSWORD=changeme
    ncn-m001# ipmitool -I lanplus -U $USERNAME -E \
    -H node_management_network_IP_address_of_node sol activate
    ```

    Example:

    ```bash
    ncn-m001# ipmitool -I lanplus -U $USERNAME -E -H  10.100.165.2 sol activate
    ```

-   ConMan - The ConMan tool is used to collect logs from nodes. It is also used to attach to the node's SOL console. For more information, refer to [ConMan](../conman/ConMan.md) and [Access Compute Node Logs](../conman/Access_Compute_Node_Logs.md).

