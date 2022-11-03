# Initializing CANU

Initialize the CSM Automatic Network Utility (CANU) in order to help create the switch configurations. CANU can automatically parse CSI output or
the Shasta System Layout Service (SLS) API for switch IPv4 addresses. Using the SLS API is only possible after the CSM install has been completed
at least to the point where CSM Services have been deployed. Prior to that, parsing CSI output is the only option.

## CANU output file

The output file for the `canu init` command is set with the `--out FILENAME` argument.

## CSI input

In order to parse CSI output, use the `--csi-folder FOLDER` flag to pass in the folder where the `sls_input_file.json` file is located.

The `sls_input_file.json` file is generally stored in one of two places, depending on how far the system is in the install process.

When running off of the LiveCD, the `sls_input_file.json` file is normally found in the `/var/www/ephemeral/prep/SYSTEMNAME/` directory on the PIT node.

After the PIT node has been redeployed, the `sls_input_file.json` file may be found in the `/metal/bootstrap/prep/SYSTEMNAME/` directory on `ncn-m001` or `ncn-m003`.

To get the switch IP addresses from CSI output, run the following command:

```bash
canu -s 1.4 init --csi-folder /CSI/OUTPUT/FOLDER/ADDRESS --out output.txt
```

Eight IP addresses are saved to `output.txt`.

## SLS API input

Parsing the SLS API for IP addresses requires a valid API token. Either the token file can be passed in with the
`--auth-token TOKEN_FILE` flag, or the token can be read from the `SLS_TOKEN` environment variable, if it is exported.

The SLS address is by default set to `api-gw-service-nmn.local`. If needed, a different address can be specified using the `--sls-address SLS_ADDRESS` flag.

To get the switch IP addresses from the Shasta SLS API, run the following command:

```bash
canu -s 1.4 init --auth-token ~./config/cray/tokens/ --sls-address 1.2.3.4 --out output.txt
```

[Back to index](README.md).
