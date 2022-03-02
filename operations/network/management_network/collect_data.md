# Collect Data 

#### Prerequisites 
- SSH access to the switches.
- SLS API access.

* ***Step 1***: Retrieve the most up-to-date SHCD spreadsheet. Accuracy in this spreadsheet is critical. 

For example: 
* Internal repository
* Customer reposotiry

* ***Step 2***: Retrieve SLS file from a Shasta system (log in to ncn-m001) on a NCN, this will output the sls file to a file called sls_file.json in your current working directory. 

##### If this is an upgrade SLS needs to be updated to the correct CSM version first.

Run the command  

```
cray sls dumpstate list  --format json >> sls_file.json   
```
 
* ***Step 3***: Retrieve switch running configs.

CANU can backup all the management network switches using either the SLS input file or the SLS api.
This can also be donw from outside the cluster using the CMN switch IPs.  

```bash
ncn-w001:~ # canu backup network --folder switch_backups/ --sls-file ./sls_input_file_1_2.json
Enter the switch password:
-
Running Configs Saved
---------------------
sw-spine-001.cfg
sw-spine-002.cfg
sw-leaf-001.cfg
sw-leaf-002.cfg
sw-leaf-003.cfg
sw-leaf-004.cfg
sw-leaf-bmc-001.cfg
sw-leaf-bmc-002.cfg
sw-cdu-001.cfg
sw-cdu-002.cfg
```

If the SLS API is up you don't need to provide a sls file.
 

* ***Step 4***: Retrieve customizations file. (log in from ncn-m001) 

Run the command  

```
kubectl -n loftsman get secret site-init -o json | jq -r '.data."customizations.yaml"' | base64 -d > customizations.yaml 
```
 
This will output the customizations file to a file called ***customizations.yaml*** in your current working directory. 