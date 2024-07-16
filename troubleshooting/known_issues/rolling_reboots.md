# Known Issue: Boot Orchestration Service (BOS) / Rolling reboots

* Using the BOS v2 "applystaged" endpoint is broken in CSM 1.5. This endpoint is used to execute a rolling reboot.
* This means the following:
    * POSTING to the applystaged endpoint will result in an error.
    * Using the 'cray bos v2 applystaged create --xnames <NODE>' command will fail.
* This is expected to be fixed in CSM 1.6.