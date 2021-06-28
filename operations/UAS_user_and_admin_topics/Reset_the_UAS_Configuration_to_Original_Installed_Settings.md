---
category: numbered
---

# Reset the UAS Configuration to Original Installed Settings

How to remove a customized UAS configuration and restore the base installed configuration.

This procedure requires administrator privileges.

-   **LEVEL**

    **Level 2 IaaS.**

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Delete a volume configuration.


The configuration set up using the Cray CLI to interact with UAS persists as long as UAS remains installed and survives upgrades. This is called the running configuration and it is both persistent and malleable. During installation and localization, however, the installer creates a base installed configuration. It may be necessary to return to this base configuration. To do this, delete the running configuration, which will cause the UAS to reset to the base installed configuration.

**Note:** Deleting the running configuration discards all changes that have been made since initial installation and is not recoverable. Be certain you want to do this before you proceed.

To delete the running configuration and reset to the base installed configuration, follow these steps.

1.  Delete the running configuration.

    ```screen
    ncn-w001 # cray uas admin config delete
    This will delete all locally applied configuration, Are you sure? [y/N]:
    ```

2.  Confirm the command. This will delete the running configuration and cannot be undone.

    ```screen
    ncn-w001 # cray uas admin config delete
    This will delete all locally applied configuration, Are you sure? [y/N]: y
    ```

    Alternatively, note that the interactive prompt can be bypassed by supplying the `-y` option.

    ```screen
    ncn-w001 # cray uas admin config delete -y
    ```


**Parent topic:**[Create and Register a Custom UAI Image](Create_and_Register_a_Custom_UAI_Image.md)

