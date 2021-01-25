1. Firmware - to get 8325 100G
1. Base config incl OSPFv3
1. enable sw-leaf-001 access from m001
  1. Serial connection to sw-leaf-01 connected to m001 
  1. config leaf VSX and MC-LAG to enable m001 connection via IPv6 VLAN1
1. Config all switches via IPv6 connection from m001
  1. Layer 2 config: VLANs, VSX pairs, MTU, BMC access ports, switch uplink ports
  1. Create the CAN
  1. Layer 3 config: L3 interfaces, static CAN routes, ACLs.
  1. Layer 3 dynamic routing: OSPFv2


  TODO:  
  * links to json templates and json configs
  * focus on the manual steps
  * all links need to be resolvable by customers or pulled in locally
  ** switch matrix of model and purpose **
  * make links to other install docs
  