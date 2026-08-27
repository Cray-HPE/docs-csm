# Web User Interface (Web UI)

A web-based management user interface provides a visual representation of a subset
of the current switch configuration and states. The Web-UI allows for easy access
from modern browsers to modify some aspects of the configuration. The Web UI also
provides extensive access to the Network Analytics Engine. Many aspects of the
hardware can be monitored in a dashboard view and customized.

## Configuration commands

Enable the Web UI on a VRF:

```text
switch(config)# https-server vrf <mgmt|default|VRF>
```

Configure REST API:

```text
switch(config)# https-server rest access-mode read-<only|write>
```

Show commands to validate functionality:

```text
show https-server
```

## Example output

```text
config
switch(config)# https-server
  rest  REST API configuration
  vrf   Configure HTTPS Server for VRF
  <cr>
switch(config)# https-server vrf default
switch(config)# https-server vrf mgmt
```

## Expected results

- Administrators can connect the management interface to a private network.
- Administrators can enable web-management.
- Administrators can connect to the IP address from a browser login to the management menu.

[Back to Index](../README.md)
