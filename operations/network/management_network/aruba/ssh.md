# Secure Shell (SSH) 

SSH server enables an SSH client to make a secure and encrypted connection to a switch. Currently, switch supports SSH version 2.0 only. The user authentication mechanisms supported for SSH are public key authentication and password authentication (RADIUS, TACACS+ or locally stored password). Secure File Transfer Protocol (SFTP) provides file transfer. SSH Server and sftp-client via the copy command are supported for managing the router. 

## Configuration Commands

Configure SSH authentication: 

```bash
switch(config)# ssh password-authentication
```

Generate SSH server key: 

```bash
switch(config)# ssh host-key <rsa [bits 2048]|ecdsa CURVE|ed25519>
```

Enable SSH on the VRF: 

```bash
switch(config)# ssh server vrf <default|mgmt|VRF>
```

Configure SSH options: 

```bash
switch(config)# ssh certified-algorithms-only
switch(config)# ssh maximum-auth-attempts VALUE
switch(config)# ssh known-host remove <all|IP-ADDR>
```

Show commands to validate functionality:  

```bash
switch# show ssh server [vrf VRF|all-vrfs]
```

## Example Output 

```bash
switch# show ssh server all-vrfs
SSH server configuration on VRF vrf_default :
IP Version
TCP Port
Host-keys
: IPv4 and IPv6        SSH Version
: 22                   Grace Timeout (sec)  : 120
: ECDSA, ED25519, RSA
Ciphers   :  chacha20-poly1305@openssh.com,
             aes128-ctr,aes192-ctr,aes256-ctr,
             aes128-gcm@openssh.com,aes256-gcm@openssh.com
MACs      :  umac-64-etm@openssh.com,umac-128-etm@openssh.com,
             hmac-sha2-256-etm@openssh.com,
             hmac-sha2-512-etm@openssh.com,
             hmac-sha1-etm@openssh.com, umac-64@openssh.com,
             umac-128@openssh.com,
             hmac-sha2-256,hmac-sha2-512,hmac-sha1
```

## Expected Results 

1. Administrators can create the user account
2. Administrators can generate working SSH keys
3. The output of the `show` commands is correct
4. Administrators can successfully connect to the switch via an SSH client using SSH 2.0

[Back to Index](../index.md)
