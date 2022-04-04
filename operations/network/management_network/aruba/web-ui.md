# Web User Interface (WebUI)

A web-based management user interface provides a visual representation of a subset of the current switch configuration and states. The Web-UI allows for easy access from modern browsers to modify some aspects of the configuration. The Web-UI also provides extensive access to the Network Analytics Engine. Many aspects of the hardware can be monitored in a dashboard view and customized.

## Configuration Commands

Enable the WebUI on a VRF:

```text
switch(config)# https-server vrf <mgmt|default|VRF>
```

Configure REST API:

```text
switch(config)# https-server rest access-mode read-<only|write>
```

Show commands to validate functionality:

```text
switch# show https-server
```

## Example Output

```text
switch# config
switch(config)# https-server
  rest  REST API configuration
  vrf   Configure HTTPS Server for VRF
  <cr>
switch(config)# https-server vrf default
switch(config)# https-server vrf mgmt
```

## Expected Results

1. Administrators can connect the management interface to a private network
2. Administrators can enable web-management
3. Administrators can connect to the IP address from a browser login to the management menu

[Back to Index](../index.md)
