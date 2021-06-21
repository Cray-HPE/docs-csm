## Update NCN Passwords

Set a new password for non-compute nodes \(NCNs\) on the system using the standard Linux password change command.

The NCNs deploy with a default password, which are changed during the system install. See [Change NCN Image Root Password and SSH Keys](change_ncn_image_root_password_and_ssh_keys.md) for more information.

It is a recommended best practice for system security to change the root password at least once after the install is complete.

### Procedure

1.  SSH to the NCN where the password is being changed.

    ```bash
    ncn# ssh NCN_HOSTNAME
    ```

2.  Change the root password on the NCN.

    ```bash
    ncn# passwd root
    ```



