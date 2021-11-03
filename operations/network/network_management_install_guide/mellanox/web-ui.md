# Web user interface (WebUI) 

A web-based management user interface provides a visual representation of a subset of the current switch configuration and states. The Web-UI allows for easy access from modern browsers to modify some aspects of the configuration. 

Relevant Configuration 

Enable the WebUI 

```
switch(config)# web enable
```

Configure REST API

``` 
switch(config)# web enable http|https
```

Show Commands to Validate Functionality 

```
switch# show web
```

Expected Results 

* Step 1: You can connect the management interface to a private network
* Step 2: You can enable web-management
* Step 3: You can connect to the IP address from a browser login to the management menu  


[Back to Index](./index.md)