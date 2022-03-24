# Save Management Network Switch Configuration Settings

Switches must be powered on and operating. This procedure is optional if switch configurations have not changed.

**Optional Task:** Save management spine and leaf switch configurations, and other network switch configurations before removing power from cabinets or the CDU. Management switch names are listed in the `/etc/hosts` file.

### Procedure

1.  Connect to all management network Dell leaf switches and write memory configuration to startup.xml.

    The management switches in CDU cabinets are leaf switches.

    Dell leaf switches, for example `sw-leaf-001`:

    ```bash
    ncn-m001# ssh admin@sw-leaf-001
    admin@sw-leaf-001s password:
    sw-leaf-001# write memory
    sw-leaf-001# dir config
    sw-leaf-001# exit
    ```

    Use a for loop:

    ```bash
    ncn-m001# for sw in sw-leaf-001 sw-leaf-002 sw-cdu-001 sw-cdu-002; \
    do ssh admin@$sw; done
    ```

2.  Connect to all management network Mellanox spine switches and write memory configuration.

    Mellanox spine switches, for example `sw-spine-001.nmn`:

    ```bash
    ncn-m001# ssh admin@sw-spine-001.nmn
    admin@sw-spine-001 password:

    sw-spine-001# enable
    sw-spine-001# write memory
    sw-spine-001# exit
    ```

3.  Connect to all management network Aruba switches and write memory configuration.

    ```bash
    ncn-m001# ssh admin@sw-spine-001.nmn
    admin@sw-spine-001 password:

    sw-spine-001# write memory
    sw-spine-001# exit
    ```

4.  Save configuration settings on link aggregation group \(LAG\) switches that connect customer storage networks to the Slingshot network.

    LAG switches are accessible from the ClusterStor management network.

    ```bash
    ncn-m001# ssh admin@cls01053n00
    admin@cls01053n00 password:

    cls01053n00# ssh r0-100gb-sw01
    r0-100gb-sw01# enable
    r0-100gb-sw01# write memory
    r0-100gb-sw01# exit
    ```

