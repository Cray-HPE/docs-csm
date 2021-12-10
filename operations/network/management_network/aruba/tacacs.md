# TACACS

 “TACACS+ provides access control for routers, network access servers and other networked computing devices via one or more centralized servers. TACACS+ provides separate authentication, authorization and accounting services.” –ietf draft-grant-tacacs-02 
 
## Configuration Commands

Configure TACACS: 

```bash
switch(config)# tacacs-server host IP-ADDR [key <plain|cipher>text KEY]
```

Depending on the TACACS server, change the auth-type from PAP to CHAP: 

```bash
switch(config)# tacacs-server auth-type [pap|chap]
```

Configure AAA: 

```bash
switch(config)# aaa authentication login default group tacacs local
switch(config)# aaa authorization commands default group tacacs
switch(config)# aaa accounting all default start-stop group tacacs
```

Show commands to validate functionality:  

```bash
switch# show tacacs-server [detail]
```

## Expected Results 

1. SSH is enabled
1. You can configure TACACS between the server and the DUT correctly
   1. The key on the DUT matches the key on the server
   2. You have a valid and working user account in the TACACS configuration file on the server 
1. You can validate the configuration using the show command listed above
1. You can log into the switch via SSH from the client, and the CLI available to you is unrestricted 
1. You can see the start-stop logs in the logfile of the TACACS server
1. You can log into the switch via SSH from the client, but the CLI available to you is restricted  


[Back to Index](../index_aruba.md)