# Dump a Non-Compute Node

Trigger an NCN memory dump and send the dump for analysis. This procedure is helpful for debugging NCN crashes.

### Prerequisites

A non-compute node \(NCN\) has crashed or an admin has triggered a node crash.

### Procedure

1.  Force a dump on an NCN.

    ```bash
    ncn-m001# echo c > /proc/sysrq-trigger
    ```

2.  Wait for the node to reboot.

    The NCN dump is stored in /var/crash is on local disk after the node is rebooted.

3.  Collect the dump data using the System Diagnostic Utility (SDU).

    Refer to the "Run a Triage Collection with SDU" procedure in the SDU product stream documentation for more information about collecting dump data.

    The `--start_time` command option can be customized. For example, "-1 day", "-2 hours", or a date/time string can be used. For more information on the SDU command options, use the `sdu --help` command.

    ```bash
    ncn-m001# sdu --scenario triage --start_time DATE_OR_TIME_STRING --end_time DATE_OR_TIME_STRING \
    --plugin ncn.gather.nodes --plugin ncn.gather.kernel.dumps
    ```

    Refer to the [https://documentation.suse.com/](https://documentation.suse.com/) for more information on memory dumps or crash dumps.

