# Secure shell (SSH) 
SSH server enables an SSH client to make a secure and encrypted connection to a switch. Currently, switch supports SSH version 2.0 only. The user authentication mechanisms supported for SSH are public key authentication and password authentication (RADIUS, TACACS+ or locally stored password). Secure File Transfer Protocol (SFTP) provides file transfer. SSH Server and sftp-client via the copy command are supported for managing the router. 

Relevant Configuration 

Configure SSH authentication 

```
switch(config)# ssh server enable
```

Generate SSH server key 

```
switch(config)# ssh server host-key dsa2 private-key
```

NOTE: 

key-type

* rsa1 – RSAv1
* rsa2 – RSAv2
* dsa2 – DSAv2

private-key	Sets new private-key for the host keys of the specified type

public-key	Sets new public-key for the host keys of the specified type

generate	Generates new RSA and DSA host keys for SSH

Enable SSH to listen for incoming connections 

```
switch(config)# ssh server listen enable
```

Show Commands to Validate Functionality 

```
switch# show ssh server 
```

Expected Results 

* Step 1: You can create the user account
* Step 2: You can generate working SSH keys
* Step 3: The output of the show commands is correct
* Step 4: You can successfully connect to the switch via an SSH client using SSH 2.0.


[Back to Index](./index.md)