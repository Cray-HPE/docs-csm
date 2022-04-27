# Change Java Security Settings

If Java will not allow a connection to an Intel nodes via SOL or iKVM, change Java security settings to add an exception for the nodes's BMC IP address.

The Intel nodes ship with an insecure certificate, which causes an exception for Java when trying to connect via SOL or iKVM to these nodes. The workaround is to add the node's BMC IP address to the **Exception Site List** in the **Java Control Panel** of the machine attempting to connect to the Intel node.

To add an IP address to the **Exception Site List**:

**Java Control Panel** \> **Security** \> **Edit Site List**

The following figures show examples of the **Security** tab of the **Java Control Panel** on several different operating systems.

### Linux Java Control Panel Security Tab

![Java Control Panel Security Tab: Linux](../../img/operations/Java_Control_Panel_Security_Tab_Linux.png "Java Control Panel Security Tab: Linux")

### MacOS Java Control Panel Security Tab

![Java Control Panel Security Tab: MAC](../../img/operations/Java_Control_Panel_Security_Tab_MAC.png "Java Control Panel Security Tab: MAC")

### Windows Java Control Panel Security Tab

![Java Control Panel Security Tab: Windows](../../img/operations/Java_Control_Panel_Security_Tab_Windows.png "Java Control Panel Security Tab: Windows")

