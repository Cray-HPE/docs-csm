# Domain name 

A domain name is a name to identify the person, group, or organization that controls the devices within an area. An example of a domain name could be us.cray.com 

Relevant Configuration 

Creating a domain name 

```
switch(config)# domain-name NAME
```

Show Commands to Validate Functionality 

```
switch# show domain-name
```

Example Output 

```
switch(config)# domain-name us.cray.com
switch(config)# end
switch-test# show domain-name
arubanetworks.com
```

Expected Results 

* Step 1: You can configure the domain name
* Step 2: The output of all show commands is correct  
 
[Back to Index](#index)
