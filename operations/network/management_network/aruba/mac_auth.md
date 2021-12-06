# MAC authentication 

MAC Authentication (MAC Auth) is a method of authenticating devices for access to the network. The default mode of authentication is RADIUS, through which clients are authenticated by an external RADIUS server. 

Relevant Configuration 

Enter MAC Auth context 

```
switch(config)# aaa authentication port-access mac-auth
```

Enable MAC Authentication on all interfaces 

```
switch(config-macauth)# enable
```

Configure MAC authentication MAC address format 

```
switch(config-macauth)# addr-format <no-delimiter|single-dash|multi-dash|multi-colon|no-delimiter
```

Enable MAC authentication password 

```
switch(config-macauth)# password <plaintext|ciphertext> PASSWORD
```

Configure mac-auth RADIUS authentication method 

```
switch(config-macauth)# aaa authentication port-access mac-auth auth-method <chap|pap>
```

Configure mac-auth server group 

```
switch(config-macauth)# radius server-group NAME
```

Configure cached reauthentication period on a port 

```
switch(config-macauth)# cached-reauth-period VALUE
```

Configure the quiet period on a port 

```
switch(config-macauth)# quiet-period VALUE
```

Configure the reauthentication period on a port 

```
switch(config-macauth)# reauth-period VALUE
```

Enable reauthentication on the interface 

```
switch(config-macauth)# reauth
```

Enable authorized on the interface 

```
switch(config-macauth)# authorized
```

Enable cached reauthentication on the interface 

```
switch(config-macauth)# cached-reauth
```

Show commands to validate functionality:  

```
switch# show aaa authentication port-access mac-auth interface <IFACE|all> <port-statistics|client-status [mac MAC-ADDR]>
```

Expected Results 

* Step 1: You can enable MAC auth authentication
* Step 2: You are able to authenticate using the specified dot1x authentication method 
* Step 3: The output of the show commands looks correct

[Back to Index](./index.md)