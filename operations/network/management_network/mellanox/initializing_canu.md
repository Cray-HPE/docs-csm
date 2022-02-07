# Initializing CANU

To help creating the switch configuration. CANU can automatically parse CSI output or the Shasta SLS API for switch IPv4 addresses.

### CSI Input

- In order to parse CSI output, use the `--csi-folder FOLDER` flag to pass in the folder where the _sls_input_file.json_ file is located.

The _sls_input_file.json_ file is generally stored in one of two places depending on how far the system is in the install process.

Early in the install process, when running off of the LiveCD the _sls_input_file.json_ file is normally found in the the directory `/var/www/ephemeral/prep/SYSTEMNAME/`

Later in the install process, the _sls_input_file.json_ file is generally in `/mnt/pitdata/prep/SYSTEMNAME/`

To get the switch IP addresses from CSI output, run the command:

```
canu -s 1.4 init --csi-folder /CSI/OUTPUT/FOLDER/ADDRESS --out output.txt
```

8 IP addresses saved to output.txt


### SLS API Input

To parse the Shasta SLS API for IP addresses, ensure that you have a valid token. The token file can either be passed in with the `--auth-token TOKEN_FILE` flag, or it can be automatically read if the environmental variable **SLS_TOKEN** is set. The SLS address is default set to _api-gw-service-nmn.local_, if you are operating on a system with a different address, you can set it with the `--sls-address SLS_ADDRESS` flag.

To get the switch IP addresses from the Shasta SLS API, run the command:


```
canu -s 1.4 init --auth-token ~./config/cray/tokens/ --sls-address 1.2.3.4 --out output.txt
```

The output file for the `canu init` command is set with the `--out FILENAME` flag.

[Back to Index](./index.md)