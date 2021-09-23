

## Provisioning a Liquid-Cooled EX Cabinet CEC with Default Credentials

This procedure provisions a Glibc compatible SHA-512 administrative password hash to a cabinet environmental controller (CEC). This password becomes the Redfish endpoint superuser credential to access the CMM controllers, node controllers, and switch controllers (BMCs) in the cabinet. 

### Prerequisites

- The administrator must have physical access to the CEC LCD panel to enable privileged command mode. The CEC does not enable users to set, display, or clear the password hash in restricted command mode. 

- A Apple Mac or Linux Laptop that supports 10/100 IPv6 Ethernet connectivity to the CEC Ethernet port.

- A customer-generated hash for the CEC credentials:

   - The `passhash` tool that is installed on the CMMs can be used to generate a SHA-512 password hash. This HPE tool is provided for convenience, but any tool that generates an SHA-512 hash that is compatible with glibc can be used. The salt portion must be between 8 and 16 chars inclusive. The CEC does not support the optional "rounds=" parameter in the hash.
   - See the `man 3 crypt` page for a description: https://man7.org/linux/man-pages/man3/crypt.3.html

  ```screen
  remote# passhash PASSWORD $6$v5YlqxKB$scBci.GbT8Uf3ZPcGwrW07zEjGdq6q7/FdQGCclxh05IPCINm9SOt2RLHfdPE9UE/Ng5dtc5qCBCoSLHSW84L1
  ```

### Procedure

1. Connect an Ethernet cable from an Apple Mac or Linux laptop to the CEC Ethernet port.
   The CEC Ethernet PHY will auto negotiate to either 10/100Mb speed and it supports auto crossover functionality. Any standard Ethernet patch cord should work for this.
   
   
   
   ![](CEC_Front_Panel.svg)
   
2. On an Apple Mac or Linux laptop, start the "terminal" program and use Netcat `'nc'` to connect to CEC command shell. Specify the CEC IPv6 link local address shown on the CEC front panel display.

   ```screen
   # nc -t -6 'fe80::a1:2328:0%en14' 23
   ```

   - The CEC IPv6 link local address is shown on the front panel display. 

   - Specific the Ethernet interface name for the laptop. In this example the wired Ethernet interface is named `en14`. 

3.  From the CEC> prompt, enter help to view the list of commands.

      ```screen
      CEC> help
      ```

   **CAUTION**: Modifications to the CEC settings should be made only under advisement from HPE support.

4. From the CEC> prompt, generate an unlock token for the CEC. Use the enable command (alias for unlock command) without arguments to display a random unlock token on the CEC LCD panel.

   ```screen
   CEC> enable
   ab12903c
   ```

5. Record the unlock token displayed on the CEC front panel.

   The unlock code is valid as long as the remote shell connection is open to the CEC.

6. Enter the enable command again but supply the token as an argument to unlock the CEC and enter privileged command mode.

   ```screen
   CEC> enable ab12903c
   EXE>
   ```

   If the token code is typed in incorrectly a new one is generated on screen. When unlocked the LCD screen displays UNLOCKED and the shell prompt changes to `EXE>`.

7. Enter `set_hash` and provide the hash value as the argument.

   The CEC validates the input syntax of the hash. Adding an extra char or omitting a character is flagged as an error. I a character is changed, the password entered in the serial console login shell or the Redfish `root` account will not work. If that happens, rerun the`set_hash` command on the CEC and reboot the CMMs.
   [end]

      ```screen
      EXE> set_hash $6$v5YlqxKB$scBci.GbT8Uf3ZPcGwrW07zEjGdq6q7/FdQGCclxh05IPCINm9SOt2RLHfdPE9UE/Ng5dtc5qCBCoSLHSW84L1
      ```

8. Exit privileged command mode.

   ```screen
   EXE> lock
   CEC>
   ```

   The CEC remains in privileged mode until it is reset with the `lock` command, or if the X button on the CEC front panel is pressed. Typing `exit` or terminating the connection will drop out of privileged mode. There is no connection timeout.

9. Reboot the CMMs attached to this CEC to load the new credential. The following command reboots all the even numbered, or odd numbered CMMs, depending on which CEC is issuing the commands.

   ```screen
   CEC> reset_cmm cmm0
   CEC> reset_cmm cmm1
   CEC> reset_cmm cmm2
   CEC> reset_cmm cmm3
   ```

   The CMMs can also be reset from the front panel controls:


   ![Front Panel Controls](./CEC_Display_Controls_CEC_Actions.svg)



10. To test the password, connect to the CMM serial console though the CEC. This can also be done with `nc` but it requires different arguments. The IPv6 address is the same, but the port numbers are different. 

    ```screen
    #!/bin/bash
    trap "stty sane && echo ''" EXIT
    stty -icanon -echo
    nc -6 'fe80::a1:2328:0%en14' 50000
    ```

    - The even number CEC handles the CMM serial console for chassis 0, 2, 4, 6 on TCP port numbers 50000-50003 respectively. 
    - The odd numbered CEC handles the CMM serial console for chassis 1, 3, 5, 7 on TCP port numbers 50000-50003 respectively. 
    - If using this script snippet to connect to the CMM console type `exit` to get back to the CMM login prompt and enter ctrl-c to close the console connection.

11. Repeat this procedure for the other CEC in the cabinet. HPE Cray EX2000 cabinets (Hill) have a single CEC.
