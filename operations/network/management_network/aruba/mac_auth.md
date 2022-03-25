# MAC Authentication 

MAC Authentication (MAC Auth) is a method of authenticating devices for access to the network. The default mode of authentication is RADIUS, through which clients are authenticated by an external RADIUS server. 

## Configuration Commands

Enter MAC Auth context: 

```text
switch(config)# aaa authentication port-access mac-auth
```

Enable MAC Auth on all interfaces: 

```text
switch(config-macauth)# enable
```

Configure MAC Auth MAC address format: 

```text
switch(config-macauth)# addr-format <no-delimiter|single-dash|multi-dash|multi-colon|no-delimiter
```

Enable MAC Auth password: 

```text
switch(config-macauth)# password <plaintext|ciphertext> PASSWORD
```

Configure mac-auth RADIUS authentication method: 

```text
switch(config-macauth)# aaa authentication port-access mac-auth auth-method <chap|pap>
```

Configure mac-auth server group: 

```text
switch(config-macauth)# radius server-group NAME
```

Configure cached reauthentication period on a port: 

```text
switch(config-macauth)# cached-reauth-period VALUE
```

Configure the quiet period on a port: 

```text
switch(config-macauth)# quiet-period VALUE
```

Configure the reauthentication period on a port: 

```text
switch(config-macauth)# reauth-period VALUE
```

Enable reauthentication on the interface: 

```text
switch(config-macauth)# reauth
```

Enable authorized on the interface: 

```text
switch(config-macauth)# authorized
```

Enable cached reauthentication on the interface: 

```text
switch(config-macauth)# cached-reauth
```

Show commands to validate functionality:  

```text
switch# show aaa authentication port-access mac-auth interface <IFACE|all> <port-statistics|client-status [mac MAC-ADDR]>
```

## Expected Results 

1. Administrators can enable MAC auth authentication
2. Administrators are able to authenticate using the specified dot1x authentication method 
3. The output of the `show` commands looks correct

[Back to Index](../index.md)