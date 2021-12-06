# Exec banners

Banners are custom messages displayed to users attempting to connect to the management interfaces. MOTD banners are displayed pre-login while exec banners are displayed post-login. Multiple lines of text can be stored using a custom delimitator to mark the end of message. 

Relevant Configuration 

Create a banner.

```
switch(config)# banner motd Testing
```

Show commands to validate functionality: . 

```
switch# show banner
```

Example Output 

```
ufmapl [ mgmt-sa ] (config) # show banner
Banners:
    MOTD:
Mellanox UFM Appliance
 
    Login:
Mellanox MLNX-OS UFM Appliance Management
```

Expected Results: 

* Step 1: You can create the banner
* Step 2: The output of the banner looks correct 

[Back to Index](./index.md)