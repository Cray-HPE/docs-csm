# Secure Shell (SSH)

An SSH server enables an SSH client to make a secure and encrypted connection to a switch.
Switches support SSH version 2.0 only. The user authentication mechanisms supported for SSH
are public key authentication and password authentication (RADIUS, `TACACS+`, or locally stored password).
Secure File Transfer Protocol (SFTP) provides file transfer. SSH server and `sftp-client` (via the copy command)
are supported for managing the router.

## Relevant configuration

(`switch(config)#`) Configure SSH authentication:

```console
ssh server enable
```

(`switch(config)#`) Generate SSH server key:

```console
ssh server host-key dsa2 private-key
```

NOTE:

`key-type`

* `rsa1` – `RSAv1`
* `rsa2` – `RSAv2`
* `dsa2` – `DSAv2`

* `private-key` – Sets new `private-key` for the host keys of the specified type
* `public-key` – Sets new `public-key` for the host keys of the specified type
* `generate` – Generates new RSA and DSA host keys for SSH

(`switch(config)#`) Enable SSH to listen for incoming connections:

```console
ssh server listen enable
```

## Show commands to validate functionality

(`switch#`)

```console
show ssh server
```

## Expected results

* Administrators can create the user account
* Administrators can generate working SSH keys
* The output of the show commands is correct
* Administrators can successfully connect to the switch via an SSH client using SSH 2.0.

[Back to Index](../README.md)
