# Customer Access Networks

Customer access to Shasta services is provided by a Customer Access Network (CAN).

## Enabling Customer High-speed Network Routing

By default, the Customer Access Network (CAN) is provided by the Node Management Network (NMN). CSM 1.3 allows for the system to be optionally configured to allow the CAN to be provided by the High-speed Network (HSN).
When customer access is provided by the HSN, this is called the Customer High-speed Network (CHN).

If the CHN is the network for customer access, the following procedures will guide administrators through changing the system configuration and applying the change to the Management Nodes, UANs, UAIs, Compute Nodes, Management Switches, and Edge Switches.

This feature has additional requirements which include.

- Customer edge switches
- Cabling from HSN to edge switches
- Additional IP address space

**WARNING**: This procedure is intended to be run after an upgrade to CSM 1.3 has been completed. Future releases may introduce changes that impact this procedure. It is important that this procedure only be run on healthy systems running CSM 1.3.

## Procedure

- [Configure the system to enable the Customer High-speed Network (CHN)](network/chn_enable.md)
- [Apply the CHN configuration change to the system](network/network_upgrade_1.2_to_1.3.md)

## Additional Customer Accessible Documentation

- [Customer Accessible Networks](../Customer_Accessible_Networks.md)
- [BICAN support matrix](../../management_network/bican_support_matrix.md)
- [BICAN technical details](../../management_network/bican_technical_details.md)
- [BICAN technical summary](../../management_network/bican_technical_summary.md)
