# Remote Logging

"In its most simplistic terms, the `syslog` protocol provides a transport to allow a machine to send event notification
messages across IP networks to event message collectors - also known as `syslog` servers." – RFC 3164

Note: the default facility is `3(DAEMON)`

## Relevant configuration

(`switch(config)#`) Configure logging:

```console
logging <syslog-ip-address> [trap {<log-level> | override class <class> priority <log-level>}]
```

## Expected results

* Administrators can configure remote logging
* Administrators can see the log files from the switch on the remote server

[Back to Index](../README.md)
