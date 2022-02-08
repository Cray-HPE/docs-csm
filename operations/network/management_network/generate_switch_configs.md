# Generate switch configs

#### Prerequisites 
- Validated SHCD.
    - [Validate SHCD](validate_shcd.md)
- JSON output from validated SHCD.
    - [Validate SHCD](validate_shcd.md)
- sls input file.
    - [Collect data](collect_data.md)

Generating configuration files can be done for singular switch or for the full system. For example; in a case where you suspect a configuration issue on single switch you can generate just that one file for easier debugging purposes.  

* Generating configuration file for single switch:  

```
canu generate switch config --csm 1.2 -a full --ccj cabling.json  --sls-file sls_file.json --name sw-spine-001 --folder generated 
```

* Generating configuration files for full system:  

```
canu generate switch config --csm 1.2 -a full --ccj cabling.json  --sls-file sls_file.json --folder generated 
```
 
***Again***, make sure that you select the correct (-a) architecture specific to your setup: 

* ***Tds*** – Aruba-based Test and Development System. These are small systems characterized by Kubernetes NCNs cabling directly to the spine. 
* ***Full*** – Aruba-based Leaf-Spine systems, usually customer production systems. 
* ***V1*** – Dell and Mellanox based systems of either a TDS or Full layout. 

