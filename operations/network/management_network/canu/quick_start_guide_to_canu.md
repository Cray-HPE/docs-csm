# Quick start guide to CANU

* [Usage]
* [Validate a fresh system using CSI and CANU](#validate-a-fresh-system-using-csi-and-canu)
  * [Preparation](#preparation)
  * [Check network firmware](#check-network-firmware)
  * [Check network cabling](#check-network-cabling)
  * [Validate BGP status](#validate-bgp-status)
  * [Validate cabling](#validate-cabling)
  * [Validation using the system's SHCD](#validation-using-the-systems-shcd)
    * [Validate the SHCD](#validate-the-shcd)
    * [Validate the SHCD against network cabling](#validate-the-shcd-against-network-cabling)
    * [Generate switch configuration for the network](#generate-switch-configuration-for-the-network)

## Usage

To run, type `canu`. It should run and display help.

To see a list of commands and arguments, just append `--help`.

When running CANU, the Shasta version is required; it can be specified with either `-s` or `--shasta`. For example:

```bash
canu -s 1.5
```

## Validate a fresh system using CSI and CANU

### Preparation

1. Make a new directory to save switch IP addresses.

    ```bash
    mkdir ips_folder
    cd ips_folder
    ```

1. Parse CSI files and save switch IP addresses.

    ```bash
    canu -s 1.5 init --csi-folder /var/www/prep/SYSTEMNAME/ --out ips.txt
    ```

### Check network firmware

```bash
canu -s 1.5 network firmware --ips-file ips.txt
```

### Check network cabling

```bash
canu -s 1.5 network cabling --ips-file ips.txt
```

### Validate BGP status

```bash
canu -s 1.5 validate bgp --ips-file ips.txt –verbose
```

### Validate cabling

```bash
canu -s 1.5 validate cabling --ips-file ips.txt
```

### Validation using the system's SHCD

With the system's SHCD, CANU can also validate the configuration and cabling.

#### Validate the SHCD

```bash
canu -s 1.5 validate shcd --shcd SHCD.xlsx
```

#### Validate the SHCD against network cabling

```bash
canu -s 1.5 validate shcd-cabling --shcd SHCD.xlsx --ips-file ips.txt
```

#### Generate switch configuration for the network

```bash
canu -s 1.5 network config --shcd SHCD.xlsx --csi-folder /var/www/prep/SYSTEMNAME/ --folder configs
```
