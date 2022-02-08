
# Address Resolution Protocol (ARP) 

ARP is commonly used for mapping IPv4 addresses to MAC addresses. 

## Procedure

1. Configure static ARP on an interface.

    ```bash
    switch(config-if)# arp ipv4 IP-ADDR mac MAC-ADDR
    ```

1. Show commands to validate functionality: . 

    ```bash
    switch# show arp
    ```

## Expected Results 

1. You are able to ping the connected device 
1. You can view the ARP entries 


[Back to Index](index_aruba.md)