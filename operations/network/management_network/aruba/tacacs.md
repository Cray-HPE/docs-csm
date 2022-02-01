# TACACS

 “TACACS+ provides access control for routers, network access servers and other networked computing devices via one or more centralized servers. TACACS+ provides separate authentication, authorization and accounting services.” –ietf draft-grant-tacacs-02 
 
Relevant Configuration 

Configure TACACS 

```
switch(config)# tacacs-server host IP-ADDR [key <plain|cipher>text KEY]
```

Depending on your TACACS server, change the auth-type from PAP to CHAP 

```
switch(config)# tacacs-server auth-type [pap|chap]
```

Configure AAA 

```
switch(config)# aaa authentication login default group tacacs local
switch(config)# aaa authorization commands default group tacacs
switch(config)# aaa accounting all default start-stop group tacacs
```

Show Commands to Validate Functionality 

```
switch# show tacacs-server [detail]
```

Expected Results 

* Step 0: SSH is enabled
* Step 1: You can configure TACACS between the server and the DUT correctly 
* Step a: The key on the DUT matches the key on the server 
* Step b: You have a valid and working user account in the TACACS configuration file on the server 
* Step 2: You can validate the configuration using the show command listed above
* Step 3: You can log into the switch via SSH from the client, and the CLI available to you is unrestricted 
* Step 4: You can see the start-stop logs in the logfile of the TACACS server
* Step 5: You can log into the switch via SSH from the client, but the CLI available to you is restricted  


[Back to Index](../index.md)