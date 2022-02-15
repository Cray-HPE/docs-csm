
# Configure Secure Shell (SSH)

SSH server enables an SSH client to make a secure and encrypted connection to a switch. Currently, switch supports SSH version 2.0 only. The user authentication mechanisms supported for SSH are public key authentication and password authentication (RADIUS, TACACS+ or locally stored password). Secure File Transfer Protocol (SFTP) provides file transfer. SSH Server and sftp-client via the `copy` command are supported for managing the router.

## Configuration Commands

The SSH server is enabled by default.

Administrators can disable the SSH server using:  

```
no ip ssh server enable.
```

## Expected Results

1. Administrators can create the user account
2. Administrators can generate working SSH keys
3. The output of the `show` commands is correct
4. Administrators can successfully connect to the switch via an SSH client using SSH 2.0

[Back to Index](index.md)

