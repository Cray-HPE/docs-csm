# Known Issue: FAS Loader / HFP script `post-deliver-product.sh`

* Loading firmware from Nexus using the FAS Loader will intermittently crash with HFP release 23.12 or later. Rerunning the FAS Loader will be required.
* This affects the HFP script `post-deliver-product.sh` which will hang when the FAS Loader crashes. Rerunning the script will be required.
* IUF procedure calls the `post-deliver-product.sh` script and may require restarting that IUF process.
* This is expected to be fixed in CSM 1.5.1.

## Fix

* Rerunning FAS loader / HFP Script / IUF process will eventually work as the issue is intermittent.
