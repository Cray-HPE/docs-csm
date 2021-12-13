
# Remote Logging 

“In its most simplistic terms, the syslog protocol provides a transport to allow a machine to send event notification messages across IP networks to event message collectors - also known as syslog servers.” –rfc3164 

> **NOTE:** The default facility is three (DAEMON). 

## Configuration Commands 

Configure logging: 

```bash
switch(config)# logging IP-ADDR
```

## Expected Results 

1. You can configure remote logging
1. You can see the log files from the switch on the remote server  


[Back to Index](index_aruba.md)
