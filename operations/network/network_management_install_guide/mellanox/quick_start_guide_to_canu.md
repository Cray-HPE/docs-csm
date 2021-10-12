# Quick start guide to CANU

## Usage

To run, type `canu`, it should run and display help. 

To see a list of commands and arguments, just append `--help`.

When running CANU, the Shasta version is required, you can pass it in with either `-s` or `--shasta` for example:

```
canu -s 1.5
```

To checkout a fresh system using CSI:

* Make a new directory to save switch IP addresses:

```
mkdir ips_folder`, `cd ips_folder
```

* Parse CSI files and save switch IP addresses:

```
canu -s 1.5 init --csi-folder /var/www/prep/SYSTEMNAME/ --out ips.txt
```

* Check network firmware:

```
canu -s 1.5 network firmware --ips-file ips.txt
```

* Check network cabling:

```
canu -s 1.5 network cabling --ips-file ips.txt
```

* Validate BGP status:

```
canu -s 1.5 validate bgp --ips-file ips.txt –verbose
```

* Validate cabling:

```
canu -s 1.5 validate cabling --ips-file ips.txt
```

If you have the system's SHCD, you can use Canu to validate the configuration and cabling:

* Validate the SHCD:

```
canu -s 1.5 validate shcd --shcd SHCD.xlsx
```

* Validate the SHCD against network cabling:

```
canu -s 1.5 validate shcd-cabling --shcd SHCD.xlsx --ips-file ips.txt
```

* Generate switch config for the network:

```
canu -s 1.5 network config --shcd SHCD.xlsx --csi-folder /var/www/prep/SYSTEMNAME/ --folder configs
```

[Back to Index](./index.md)