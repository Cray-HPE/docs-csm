# Configure Secure Shell (SSH)

SSH server enables an SSH client to make a secure and encrypted connection to a switch.
Switches support SSH version 2.0 only.
The user authentication mechanisms supported for SSH are public key authentication and password authentication (RADIUS, TACACS+, or locally stored password).
Secure File Transfer Protocol (SFTP) provides file transfer.
SSH Server and `sftp-client` via the `copy` command are supported for managing the router.

## Configuration commands

The SSH server is enabled by default.

To disable the SSH server:

```text
no ip ssh server enable.
```

## Expected results

1. Administrators can create the user account
1. Administrators can generate working SSH keys
1. The output of the `show` commands is correct
1. Administrators can successfully connect to the switch via an SSH client using SSH 2.0

[Back to Index](../README.md)
