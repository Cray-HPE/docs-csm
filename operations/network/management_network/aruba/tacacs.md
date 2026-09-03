# TACACS

 "TACACS+ provides access control for routers, network access servers and other
 networked computing devices via one or more centralized servers. TACACS+ provides
 separate authentication, authorization and accounting services."
 –IETF `draft-grant-tacacs-02`

## Configuration commands

(`switch(config)#`) Configure TACACS:

```text
tacacs-server host IP-ADDR [key <plain|cipher>text KEY]
```

(`switch(config)#`) Depending on the TACACS server, change the `auth-type` from PAP to CHAP:

```text
tacacs-server auth-type [pap|chap]
```

(`switch(config)#`) Configure AAA:

```text
aaa authentication login default group tacacs local
aaa authorization commands default group tacacs
aaa accounting all default start-stop group tacacs
```

## Show commands to validate functionality

(`switch(config)#`)

```text
show tacacs-server [detail]
```

## Expected results

* SSH is enabled
* Administrators can configure TACACS between the server and the DUT correctly.
    * The key on the DUT matches the key on the server.
    * Administrators have a valid and working user account in the TACACS configuration file on the server.
* Administrators can validate the configuration using the `show` command listed above.
* Administrators can log into the switch via SSH from the client, and the available CLI is unrestricted.
* Administrators can see the start-stop logs in the logfile of the TACACS server.
* Administrators can log into the switch via SSH from the client, but the available CLI is restricted.

[Back to Index](../README.md)
