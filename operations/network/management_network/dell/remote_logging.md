"In its most simplistic terms, the syslog protocol provides a transport to allow a machine to send event notification messages across IP networks to event message collectors - also known as syslog servers." –rfc3164

Relevant Configuration

Configure logging

```
switch(config)# logging server dell.com severity log-info
```

Expected Results

* Step 1: You can configure remote logging
* Step 2: You can see the log files from the switch on the remote server

[Back to Index](../index.md)

