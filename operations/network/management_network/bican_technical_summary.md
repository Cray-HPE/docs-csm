# BICAN Summary

Bifurcated CAN was designed to separate administrative network traffic and user network traffic.

## add summary from features sections

![network traffic pattern](img/network_traffic_pattern.png)

## BiCAN terminology

- BiCAN – Bifurcated Customer Access Network
- CAN – Customer Access Network
- CMN – Customer Management Network
- CHN – Customer High Speed Network
- NMN – Node Management Network
- HMN – Hardware Management Network

## BiCAN features

- Bifurcation or splitting of the Customer Access Network (CAN) enables customization of customer traffic to and from the system.
Customization will be performed during installation.
In CSM 1.2, as part of the process to split the existing monolithic CAN, two new CAN networks are introduced:
- High Speed CAN - CHN: This feature adds the ability to connect to Application Nodes (UAN), UAI, Compute Nodes,
and Kubernetes API endpoints from the customer site via the High Speed Network (HSN).
- Management CAN - CMN:  Using a new VLAN on the Management Network, this feature allows system administrative access from the customer site.
Administrative access was previously available on the original CAN; this feature provides a traffic path and access split.
