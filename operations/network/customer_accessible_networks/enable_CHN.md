# Enable CHN

## Prerequisites

- Slingshot installed and fully functional.
- LAG configured from customer edge router to the high speed network.
  - http://web.us.cray.com/~ekoen/slingshot_portal/1.7/portal/public/developer-portal/admin_general/
- Updated SHCD/CCJ with proper cabling, this includes the customer edge router.
- Example configuration [BI-CAN Aruba/Arista Configuration](bi-can_arista_aruba_config.md)


### Cabling

- Customer edge router is cabled to the HSN as described in slingshot docs.
- Customer edge router is cabled to the management network.
- Below is an SHCD example of how the edge switches should be cabled to the management network.

![CHN](../../../img/network/edge_shcd.png "CHN Cabling")

### Update SLS

- If SLS does not have the CHN network entry it will need to be updated.

### Generate Switch Configuration (Arista Only)

#### Prerequesites

- SLS Updated
- CANU 1.6.14
- Custom site switch configuration
