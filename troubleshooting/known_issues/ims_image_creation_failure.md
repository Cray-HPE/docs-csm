# Known Issue: IMS image creation failure

On some systems, IMS image creation will fail with the following error in the CFS pod log:

```text
Traceback (most recent call last):
  File "/usr/lib/python3.9/multiprocessing/process.py", line 315, in _bootstrap
    self.run()
  File "/usr/lib/python3.9/multiprocessing/process.py", line 108, in run
    self._target(*self._args, **self._kwargs)
  File "/usr/lib/python3.9/site-packages/cray/cfs/inventory/image/__init__.py", line 239, in _request_ims_ssh
    mpq.put(ImageRootInventory._wait_for_ssh_container(ims_id, job_id, cfs_session))
  File "/usr/lib/python3.9/site-packages/cray/cfs/inventory/image/__init__.py", line 290, in _wait_for_ssh_container
    raise CFSInventoryError(
cray.cfs.inventory.CFSInventoryError: ('IMS status=error for IMS image=%r job=%r, SSH container was not created.', 'b72ca306-965c-4139-a8db-fb84233b2c1f', '68d681ca-cf5e-44f8-b089-8b482e009ea1')
2022-11-02 16:53:21,764 - INFO    - cray.cfs.inventory.image - Removing public key from IMS.
2022-11-02 16:53:21,822 - ERROR   - cray.cfs.inventory - An error occurred while attempting to generate the inventory. Error: One or more IMS jobs failed to launch.
 
```

When this happens, the IMS pod creating the image may contain this error:

```text
  File "/scripts/fetch.py", line 221, in download_file
    for chunk in response.iter_content(chunk_size=1024*1024):
  File "/scripts/venv/lib/python3.9/site-packages/requests/models.py", line 754, in generate
    raise ChunkedEncodingError(e)
requests.exceptions.ChunkedEncodingError: ("Connection broken: ConnectionResetError(104, 'Connection reset by peer')", ConnectionResetError(104, 'Connection reset by peer'))
```

## Fix

Run the following command from a master node. Be sure to change the `-w ncn-w[0-n]` argument reflects all the worker nodes for the system (`pdsh` supports multiple `-w` arguments):

```bash
pdsh -w ncn-w00[1-n] 'sysctl -w net.netfilter.nf_conntrack_tcp_be_liberal=1'
```

Once the `sysctl` command is complete, the `Connection reset by peer` errors in the IMS pod should no longer appear and the CFS job should complete successfully.
