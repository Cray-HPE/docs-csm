# Web User Interface (Web UI)

A web-based management user interface provides a visual representation of a subset of the current switch configuration and states.
The Web UI allows for easy access from modern browsers to modify some aspects of the configuration.

## Configuration commands

(`switch(config)#`) Enable the web UI:

```console
web enable
```

(`switch(config)#`) Configure REST API:

```console
web enable http|https
```

## Show commands to validate functionality

(`switch#`)

```console
show web
```

## Expected results

* Administrators can connect the management interface to a private network.
* Administrators can enable web-management.
* Administrators can connect to the IP address from a browser login to the management menu.

[Back to Index](../README.md)
