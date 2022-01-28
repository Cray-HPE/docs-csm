# Collect Data 

 

* ***Step 1***: Retrieve the most up-to-date SHCD spreadsheet. Accuracy in this spreadsheet is critical. 

For example: 
* Internal repository
* Customer reposotiry

* ***Step 2***: Retrieve SLS file from a Shasta system (log in to ncn-m001) on a NCN, this will output the sls file to a file called sls_file.json in your current working directory. 

Run the command  

```
cray sls dumpstate list  --format json >> sls_file.json   
```
 
* ***Step 3***: Retrieve switch running configs (log in to ncn-m001) 

Log into the management network switches, you can get the ips/hostnames by running this command on a NCN:   

```
cat /etc/hosts | grep sw- 
```

If /etc/hosts is not available because the system is being installed you will be on the pit and will need to run:  

```
cat /var/www/ephemeral/prep/redbull/sls_input_file.json | jq ‘.Networks | .HMN | .ExtraProperties.Subnets | .[] | select(.Name==“network_hardware”)' 
```

Run the script below to automatically collect all switch configs.  If the command fails then log in to each individual switch and run show run. 
 

* ***Step 4***: Retrieve customizations file. (log in from ncn-m001) 

Run the command  

```
kubectl -n loftsman get secret site-init -o json | jq -r '.data."customizations.yaml"' | base64 -d > customizations.yaml 
```
 
This will output the customizations file to a file called ***customizations.yaml*** in your current working directory. 