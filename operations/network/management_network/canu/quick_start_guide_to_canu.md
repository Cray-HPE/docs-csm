# Quick start guide to CANU

* [Usage]
* [Validate a fresh system using CSI and CANU](#validate-a-fresh-system-using-csi-and-canu)
    * [Preparation](#preparation)
    * [Check network firmware](#check-network-firmware)
    * [Check network cabling](#check-network-cabling)
    * [Validate cabling](#validate-cabling)
    * [Validation using the system's SHCD](#validation-using-the-systems-shcd)
        * [Validate the SHCD](#validate-the-shcd)
        * [Validate the SHCD against network cabling](#validate-the-shcd-against-network-cabling)
        * [Generate switch configuration for the network](#generate-switch-configuration-for-the-network)

## Usage

To run, type `canu`. It should run and display help.

To see a list of commands and arguments, just append `--help`. For example:

```bash
canu --help
```
or for a specific command:

```bash
canu validate network cabling --help
```

When running CANU, CSM version is required; it can be specified with `--csm`. For example:

```bash
canu --csm 1.5
```

## Validate a fresh system using CSI and CANU

### Preparation

1. Make a new directory to save switch IP addresses.

    ```bash
    mkdir ips_folder
    cd ips_folder
    ```

1. Parse the CSI-generated sls_input_file.json and save switch IP addresses.

    ```bash
    canu init --sls-file sls_input_file.json --out ips.txt
    ```

### Check network firmware

```bash
canu report network firmware --csm 1.5 --ips-file ips.txt
```

### Check network cabling

```bash
canu report network cabling --ips-file ips.txt
```

### Validate cabling

```bash
canu validate network cabling --ips-file ips.txt
```

### Validation using the system's SHCD

With the system's SHCD, CANU can also validate the configuration and cabling.

#### Validate the SHCD

```bash
canu validate shcd --shcd SHCD.xlsx
```

#### Validate the SHCD against network cabling

```bash
canu validate shcd-cabling --shcd SHCD.xlsx --ips-file ips.txt

```

#### Generate switch configuration for the network

```bash
canu generate network config --ccj ccj.json --sls-file sls_input_file.json  --folder configs
```
