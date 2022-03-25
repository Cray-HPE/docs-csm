# Address Resolution Protocol (ARP) 

ARP is commonly used for mapping IPv4 addresses to MAC addresses. 

## Procedure

1. Configure static ARP on an interface.

    ```text
    switch(config-if)# arp ipv4 IP-ADDR mac MAC-ADDR
    ```

1. Show commands to validate functionality: . 

    ```text
    switch# show arp
    ```

## Expected Results 

1. Administrators are able to ping the connected device 
1. Administrators can view the ARP entries 


[Back to Index](index.md)