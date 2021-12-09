
# MAC Authentication 

MAC Authentication (MAC Auth) is a method of authenticating devices for access to the network. The default mode of authentication is RADIUS, through which clients are authenticated by an external RADIUS server. 

## Configuration Commands

Enter MAC Auth context: 

```bash
switch(config)# aaa authentication port-access mac-auth
```

Enable MAC Auth on all interfaces: 

```bash
switch(config-macauth)# enable
```

Configure MAC Auth MAC address format: 

```bash
switch(config-macauth)# addr-format <no-delimiter|single-dash|multi-dash|multi-colon|no-delimiter
```

Enable MAC Auth password: 

```bash
switch(config-macauth)# password <plaintext|ciphertext> PASSWORD
```

Configure mac-auth RADIUS authentication method: 

```bash
switch(config-macauth)# aaa authentication port-access mac-auth auth-method <chap|pap>
```

Configure mac-auth server group: 

```bash
switch(config-macauth)# radius server-group NAME
```

Configure cached reauthentication period on a port: 

```bash
switch(config-macauth)# cached-reauth-period VALUE
```

Configure the quiet period on a port: 

```bash
switch(config-macauth)# quiet-period VALUE
```

Configure the reauthentication period on a port: 

```bash
switch(config-macauth)# reauth-period VALUE
```

Enable reauthentication on the interface: 

```bash
switch(config-macauth)# reauth
```

Enable authorized on the interface: 

```bash
switch(config-macauth)# authorized
```

Enable cached reauthentication on the interface: 

```bash
switch(config-macauth)# cached-reauth
```

Show commands to validate functionality:  

```bash
switch# show aaa authentication port-access mac-auth interface <IFACE|all> <port-statistics|client-status [mac MAC-ADDR]>
```

## Expected Results 

1. You can enable MAC Auth authentication
2. You are able to authenticate using the specified dot1x authentication method 
3. The output of the `show` commands looks correct

[Back to Index](../index.md)