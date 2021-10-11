# Web user interface (WebUI) 

A web-based management user interface provides a visual representation of a subset of the current switch configuration and states. The Web-UI allows for easy access from modern browsers to modify some aspects of the configuration. The Web-UI also provides extensive access to the Network Analytics Engine. Many aspects of the hardware can be monitored in a dashboard view and customized. 

Relevant Configuration 

Enable the WebUI on a VRF 

```
switch(config)# https-server vrf <mgmt|default|VRF>
```

Configure REST API 

```
switch(config)# https-server rest access-mode read-<only|write>
```

Show Commands to Validate Functionality 

```
switch# show https-server
```

Example Output 

```
switch# config
switch(config)# https-server
  rest  REST API configuration
  vrf   Configure HTTPS Server for VRF
  <cr>
switch(config)# https-server vrf default
switch(config)# https-server vrf mgmt
```

Expected Results 

* Step 1: You can connect the management interface to a private network
* Step 2: You can enable web-management
* Step 3: You can connect to the IP address from a browser login to the management menu  

[Back to Index](/docs-csm/operations/network/network_management_install_guide/aruba/index)
