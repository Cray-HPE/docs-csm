# Quick start guide to CANU

* [Usage](#usage)
* [Validate a fresh system using CSI and CANU](#validate-a-fresh-system-using-csi-and-canu)
    1. [Preparation](#1-preparation)
    1. [Check network firmware](#2-check-network-firmware)
    1. [Check network cabling](#3-check-network-cabling)
    1. [Validate cabling](#4-validate-cabling)
    1. [Validation using the system's SHCD](#5-validation-using-the-systems-shcd)
        * [Validate the SHCD](#validate-the-shcd)
        * [Validate the SHCD against network cabling](#validate-the-shcd-against-network-cabling)
* [Generate switch configuration for the network](#generate-switch-configuration-for-the-network)

## Usage

Running `canu` with no arguments displays high level help.
To see a list of commands and arguments, append `--help`. For example:

```bash
canu --help
```

To get help for a specific command (in this example, validating network cabling):

```bash
canu validate network cabling --help
```

When running CANU, the CSM version is required; it is specified with `--csm`. For example:

```bash
canu --csm 1.5
```

## Validate a fresh system using CSI and CANU

### 1. Preparation

1. Make a new directory to save switch IP addresses.

    ```bash
    mkdir ips_folder
    cd ips_folder
    ```

1. Parse the CSI generated `sls_input_file.json` and save switch IP addresses.

    ```bash
    canu init --sls-file sls_input_file.json --out ips.txt
    ```

### 2. Check network firmware

```bash
canu report network firmware --csm 1.5 --ips-file ips.txt
```

### 3. Check network cabling

```bash
canu report network cabling --ips-file ips.txt
```

### 4. Validate cabling

```bash
canu validate network cabling --ips-file ips.txt
```

### 5. Validation using the system's SHCD

With the system's SHCD, CANU can also validate the configuration and cabling.

#### Validate the SHCD

```bash
canu validate shcd --shcd SHCD.xlsx
```

#### Validate the SHCD against network cabling

```bash
canu validate shcd-cabling --shcd SHCD.xlsx --ips-file ips.txt
```

## Generate switch configuration for the network

```bash
canu generate network config --ccj ccj.json --sls-file sls_input_file.json  --folder configs
```
