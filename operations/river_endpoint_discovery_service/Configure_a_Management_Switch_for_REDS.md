## Configure a Management Switch for REDS

Every switch listed in the River Endpoint Discovery Service \(REDS\) mapping file requires additional configuration for REDS to function properly. This procedure configures a switch to add a group named `cray-reds-group`, add a user to that group \(username\) with appropriate permissions, and create a view named `cray-reds-view`.

The IP address used in example commands in this procedure corresponds to the default IP address for the switch stack that is connected to the management networks \(Node Management Network \(NMN\), High Speed Network \(HSN\), and ClusterStor network\). Performing this procedure using the IP address for the switch stack configures both physical switches in that stack.

This configuration is done automatically during the software installation process. Perform this procedure manually as part of cold-starting a system, which must be done whenever there is a power outage or a new switch is added to the system, such as when a switch fails and needs to be replaced.

The following items used in the examples of this procedure should be replaced with actual values when this procedure is performed:

-   username is used as an example for the SNMP user.
-   password1 is used as an example for the SNMP authentication password.
-   password2 is used as an example for the SNMP privacy password.

### Prerequisites

Ability to connect to the switch using a serial terminal or network.

### Limitations

If a new switch has been added to this system, Cray recommends contacting the Cray customer account representative for this site to help with full switch configuration because this procedure covers only the portion related to REDS.

### Procedure

1.  Connect to the switch.

    The IP address in the following example corresponds to the default IP address for the switch stack that is connected to the management networks \(NMN, HSN, and ClusterStor\).

    ```bash
    ncn-m001# ssh admin@sw-leaf01
    admin@sw-leaf01's password:
    sw-smn1#
    ```

2.  Enter configuration mode.

    ```bash
    sw-smn1# configure
    ```

3.  Add a group named `cray-reds-group`.

    ```bash
    sw-smn1(conf)# snmp-server group cray-reds-group 3 noauth read cray-reds-view
    ```

4.  Add a user named `username` to `cray-reds-group` with the following permissions.

    ```bash
    sw-smn1(conf)# snmp-server user username cray-reds-group 3 auth md5 password1 priv des56 password2
    ```

5.  Add a view named `cray-reds-view`.

    The following command specifies `1.3.6.1.2` as the object ID \(OID\) subtree to be included in the view, which is the same subtree used for this switch in all HPE Cray EX systems.

    ```bash
    sw-smn1(conf)# snmp-server view cray-reds-view 1.3.6.1.2 included
    ```

6.  Exit configuration mode.

    ```bash
    sw-smn1(conf)# end
    ```

7.  Verify the configuration.

    Additional configuration lines may be present in the output of this command, depending on other configuration present on the switch. Hash values displayed in the example, such as `6b7c0616ef0a434c518012ef9d75691c`, will be different on this system.

    ```bash
    sw-smn1# show running-config snmp
    !
    snmp-server group cray-reds-group 3 noauth read cray-reds-view
    snmp-server user username cray-reds-group 3 encrypted auth md5 6b7c0616ef0a434c518012ef9d75691c priv des56 ad2b5b9f6af4f15a93c2d3c2956f5e5e
    snmp-server view cray-reds-view 1.3.6.1.2 included
    sw-smn1#
    ```

8.  Write configuration to permanent storage.

    ```bash
    sw-smn1# write memory
    !
    
    sw-smn1#
    ```

9.  Exit switch configuration console.

    In the following example, xxx.xxx.xxx.xx is the IP address of the client \(`ncn-m001` in the example\) on the switch.

    ```bash
    sw-smn1# quit
    Session terminated for user admin on line vty 0 ( xxx.xxx.xxx.xx )
    Connection to 10.4.255.254 closed.
    ncn-m001# 
    ```


There may be another action to perform after switch configuration is complete. Please consult the use cases in [River Endpoint Discovery Service \(REDS\)](River_Endpoint_Discovery_Service_REDS.md).

