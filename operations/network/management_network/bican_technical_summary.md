# BICAN Summary
Bifurcated CAN was designed to separate admin network traffic and user network traffic.
# add summary from features sections#
![](img/network_traffic_pattern.png)

## BiCAN Terminology
- BiCAN – Bificrated Customer Access Network
- CAN – Customer Access Network
- CMN – Customer Management Network
- CHN – Customer High Speed Network
- NMN – Node Management Network
- HMN – Hardware Management Network


## BiCAN Features
- Bifurcation or splitting of the Customer Access Network (CAN) enables customization of customer traffic to and from the system.  Customization will be performed during installation.  For CSM-1.2.x there are two new CAN networks being introduced as part of the process to split the existing monolithic CAN.
- High Speed CAN - CHN: This feature adds the ability to connect to Application Nodes (UAN), UAI, Compute Nodes and Kubernetes API endpoints from the customer site via the High Speed Network (HSN).
- Management CAN - CMN:  Using a new VLAN on the Management Network, this feature allows system administrative access from the customer site.  Administrative access was previously available on the original CAN and this feature provides a traffic path and access split.
