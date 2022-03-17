# Validate cabling 

***Warning:***  If this step is completed when NCNs are offline or shutdown, the 
information compared here would not match the actual connections. Therefore this 
step should be re-run once whole system is up. 

To validate the cabling, you can run a command similar to the following:

```bash
linux# canu validate shcd-cabling --shcd ./SHCD.xlsx --tabs 40G_10G --corners J12,T36 --ips 10.252.0.2,10.252.0.3 
```

***Note:*** Modify the command to have your SHCD file and the correct `--tabs`, `--corners`, and IP addresses. 

The output should look as follows: 

```text
sw-spine-001
Rack: x3000    Elevation: u24

--------------------------------------------------------------
Port | SHCD                   | Cabling 
--------------------------------------------------------------

1      ncn-w001:pcie-slot1:1    ncn-w001:pcie-slot1:2
2      ncn-w002:pcie-slot1:1    ncn-w002:pcie-slot1:1
3      ncn-w003:pcie-slot1:1    ncn-w003:pcie-slot1:1

sw-spine-002
Rack: x3000    Elevation: u24

--------------------------------------------------------------
Port | SHCD                   | Cabling 
--------------------------------------------------------------

1     ncn-w001:pcie-slot1:2    ncn-w001:pcie-slot1:2
2     ncn-w002:pcie-slot1:2    ncn-w002:pcie-slot1:2
3     ncn-w003:pcie-slot1:2    ncn-w003:pcie-slot1:2
```

Look for the differences between the SHCD and the actual network configuration.

In the above example, incorrect cabling was detected on the `sw-spine-001` switch on port 1:

1      ncn-w001:***pcie-slot1:1***    ncn-w001:***pcie-slot1:2****

The SHCD has the correct information on port 1 but the actual switch configuration is mismatched. 

To fix this issue, re-cable `ncn-w001` so that it is correctly connected to `sw-spine-001`.

