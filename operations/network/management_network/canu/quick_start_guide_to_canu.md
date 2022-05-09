# Quick start guide to CANU

## Usage

To run, type `canu`. It should run and display help.

To see a list of commands and arguments, just append `--help`.

When running CANU, the Shasta version is required, you can pass it in with either `-s` or `--shasta` for example:

```bash
ncn# canu -s 1.5
```

To checkout a fresh system using CSI:

* Make a new directory to save switch IP addresses:

```bash
ncn# mkdir ips_folder
ncn# cd ips_folder
```

* Parse CSI files and save switch IP addresses:

```bash
ncn# canu -s 1.5 init --csi-folder /var/www/prep/SYSTEMNAME/ --out ips.txt
```

* Check network firmware:

```bash
ncn# canu -s 1.5 network firmware --ips-file ips.txt
```

* Check network cabling:

```bash
ncn# canu -s 1.5 network cabling --ips-file ips.txt
```

* Validate BGP status:

```bash
ncn# canu -s 1.5 validate bgp --ips-file ips.txt –verbose
```

* Validate cabling:

```bash
ncn# canu -s 1.5 validate cabling --ips-file ips.txt
```

If you have the system's SHCD, you can use CANU to validate the configuration and cabling:

* Validate the SHCD:

```bash
ncn# canu -s 1.5 validate shcd --shcd SHCD.xlsx
```

* Validate the SHCD against network cabling:

```bash
ncn# canu -s 1.5 validate shcd-cabling --shcd SHCD.xlsx --ips-file ips.txt
```

* Generate switch configuration for the network:

```bash
ncn# canu -s 1.5 network config --shcd SHCD.xlsx --csi-folder /var/www/prep/SYSTEMNAME/ --folder configs
```
