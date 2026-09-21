# Remote Logging

"In its most simplistic terms, the `syslog` protocol provides a transport to allow a machine to send event notification
messages across IP networks to event message collectors - also known as `syslog` servers." – RFC 3164

Configure remote logging to view log files from the switch on a remote server. This functionality is enabled by `syslog`.

> **NOTE** The default facility is `3(DAEMON)`.

## Configuration commands

(`switch(config)#`) Configure logging:

```text
logging IP-ADDR
```

## Expected results

* Administrators can configure remote logging.
* Administrators can see the log files from the switch on the remote server.

[Back to Index](../README.md)
