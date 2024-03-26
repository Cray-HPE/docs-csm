# IUF fails with 'Not a directory: /etc/cray/upgrade/csm/media/...'

## Error

The following error can be seen when running the IUF stages 'process-media' and 'deliver-product'.

```bash
...
INFO [IUF SESSION: update-products-lauqr                ] BEG Started at 2024-03-23 02:32:13.608312
ERR  An unexpected error occurred: [Errno 20] Not a directory: '/etc/cray/upgrade/csm/media/update-products/Slingshot_Hardware_Guide.pdf'
Traceback (most recent call last):
  File "iuf.py", line 879, in <module>
  File "iuf.py", line 867, in main
  File "iuf.py", line 333, in process_install
  File "lib/Activity.py", line 956, in run_stages
  File "lib/Activity.py", line 1146, in run_stage
  File "lib/Activity.py", line 1109, in watch_next_wf
NotADirectoryError: [Errno 20] Not a directory: '/etc/cray/upgrade/csm/media/update-products/Slingshot_Hardware_Guide.pdf'
[2325025] Failed to execute script 'iuf' due to unhandled exception!

Error Summary:
   An unexpected error occurred: [Errno 20] Not a directory: '/etc/cray/upgrade/csm/media/update-products/Slingshot_Hardware_Guide.pdf'
```

## Problem Description

This error occurs because product documentation tar files have different structures than product tar files.
Certain product documentation tar files extract files directly into the media directory. This can cause
the 'NotADirectoryError' error in the IUF-CLI. This problem has been fixed in the IUF-CLI rpm version 1.5.12 which is in CSM 1.5.1 and more recent releases.
For the fix for CSM 1.4.X and CSM 1.5.0, please refer to the work around below.

## Work Around

Move all product documentation tar files to a directory outside of the media directory being used by the IUF activity.
The media directory for the IUF activity should now only contain product tar files.
