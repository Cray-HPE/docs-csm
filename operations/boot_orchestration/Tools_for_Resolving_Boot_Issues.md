# Tools for Resolving Compute Node Boot Issues

A number of tools can be used to analyze and debug issues encountered during the compute node boot process. The underlying issue and symptoms dictate the type of tool required.

## BOS

BOS component records offer a history of operations that have been applied to a node.

```bash
cray bos components describe x3000c0s19b4n0
```

Additionally, nodes that are unable to boot may also be disabled. BOS will not apply power actions to disabled nodes,
allowing an administrator to debug the node environment interactively.

```bash
cray bos components update --enabled False x3000c0s19b4n0
```

Once the problem has been isolated and fixed, you can return the node back over to BOS so that it may resume its boot
session. Note: when re-enabling a node, BOS may first power cycle it to return it to working order depending on elapsed
time and BOS options.

```bash
cray bos components update --enabled True x3000c0s19b4n0
```

## `nmap`

Use `nmap` to send out DHCP discover requests to test DHCP. `nmap` can be installed using the following command:

```bash
zypper install nmap
```

To reach the DHCP server, the request generally needs to be sent over the Node Management network \(NMN\) from a non-compute node \(NCN\).

In the following example, `nmap` is used to send a broadcast request over the `eth1` interface:

```bash
nmap --script broadcast-dhcp-discover -e eth1
```

## Wireshark

Use Wireshark to display network traffic. It has powerful display filters that help find information that can be used for debugging. To learn more, visit [the Wireshark home page](https://www.wireshark.org).

## `tcpdump`

Use `tcpdump` to capture network traffic, such as DHCP or TFTP requests. It can be installed using the following mechanisms:

- Install `tcpdump` inside an Alpine-based pod:

    ```bash
    apk add --no-cache tcpdump
    ```

- Install `tcpdump` on an NCN or some other node that is running SUSE:

    ```bash
    zypper install tcpdump
    ```

Invoking `tcpdump` without any arguments will write all of its output to `stdout`. This is reasonable for some tasks, but the volume of traffic that `tcpdump` can capture is
large, so it is often better to write the output to a file.

Use the following command to send `tcpdump` output to `stdout`:

```bash
tcpdump
```

Use the following command to send `tcpdump` output to a file (`/tmp/tcpdump.output` in the following example):

```bash
tcpdump -w /tmp/tcpdump.output
```

Use either `tcpdump` or Wireshark to read from the `tcpdump` file. Here is how to read the file using `tcpdump`:

```bash
tcpdump -r /tmp/tcpdump.output
```

Filtering the traffic using `tcpdump` filters is not recommended because when a TFTP server answers a client, it will usually use an ephemeral port that the user may not be able
to identify and will not be captured by `tcpdump`. It is better to capture everything with `tcpdump` and then filter with Wireshark when looking at the resulting output.
Filtering on DHCP traffic can be performed because that uses ports 67 and 68 specifically.

## TFTP client

Use a TFTP client to send TFTP requests to the TFTP server. This will test that the server is functional. TFTP requests can be sent from the NCN, remote node, or laptop, as
long as it targets the NMN.

Install the TFTP client using the following command:

```bash
zypper install atftp
```

The `atftp` TFTP client can be used to request files from the TFTP server. The TFTP server is on the NMN and listens on port 69. The TFTP server sends the `ipxe.efi` file as the
response in this example.

Request the files:

```console
atftp
tftp> connect 10.100.160.2 69
tftp> get ipxe.efi test-ipxe.efi
tftp> quit
```

List the files:

```bash
ls -l test-ipxe.efi
```

Example output:

```text
-rw-r--r-- 1 root root 951904 Sep 11 10:44 test-ipxe.efi
```

## Serial Over LAN \(SOL\) sessions

There are two tools that can be used to access a BMC's console via SOL:

- `ipmitool`

    `ipmitool` is a utility for controlling IPMI-enabled devices.

    Use the following command to access a node's SOL via `ipmitool`:

    > `read -s` is used to prevent the password from being written to the screen or the shell history.

    ```bash
    USERNAME=root
    read -r -s -p "BMC ${USERNAME} password: " IPMI_PASSWORD
    ```

    ```bash
    export IPMI_PASSWORD
    ipmitool -I lanplus -U "${USERNAME}" -E -H <node_management_network_IP_address_of_node> sol activate
    ```

    Example:

    ```bash
    ipmitool -I lanplus -U "${USERNAME}" -E -H  10.100.165.2 sol activate
    ```

- ConMan

    The ConMan tool is used to collect logs from nodes. It is also used to attach to the node's SOL console. For more information, refer to [ConMan](../conman/ConMan.md)
    and [Access Compute Node Logs](../conman/Access_Compute_Node_Logs.md).
