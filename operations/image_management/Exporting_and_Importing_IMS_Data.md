# Exporting and Importing IMS Data

IMS public keys, images, and recipes, including associated artifacts stored in Ceph S3, can be exported and imported
using an automated script.

- [Prerequisites](#prerequisites)
- [Export](#export)
- [Import](#import)

## Prerequisites

- Ensure that the `cray` command line interface (CLI) is authenticated and configured to talk to system management services.
  - See [Configure the Cray CLI](../configure_cray_cli.md).
- The latest CSM documentation RPM must be installed on the node where the procedure is being performed.
  - See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Export

(`ncn-mw#`) The `export_ims_data.py` script will create a tar file backup of the contents of IMS and
the associated S3 artifacts.

> - This tar file may be very large, depending on how many images are in IMS. By default the script
>   will create the tar file in the current directory. If desired, an alternative directory may be
>   specified by appending its path to the command line arguments.
> - Run the script with the `--help` argument to see full usage options.

```bash
/usr/share/doc/csm/scripts/operations/configuration/export_ims_data.py
```

On success, the final lines of output will resemble the following:

```text
2023-10-13 16:30:27 INFO     Data saved to tar archive: /root/export-ims-data-20231013161618.084854-naswhadt.tar
2023-10-13 16:30:27 INFO     DONE!
```

## Import

The `import_ims_data.py` script can be used to import the previously exported IMS public keys, images, and recipes.

There are three types of imports possible:

- `add`

    In an `add` import, any IMS resources present in the exported data that are not present in IMS will be created.
    No resources in IMS will be deleted or changed.

- `overwrite`

    All data in IMS is cleared. Then an `add` import is performed.

- `update`

    For any resources which exist in both IMS and the exported data, if there is a difference, then IMS is
    updated to match the exported data. In addition, an `add` import is performed. No resources in IMS
    are deleted.

(`ncn-mw#`) Run the script and specify the type of import and the path to the tar file created by the export script.

> - This tar file may be very large, depending on how many images it contains. By default the script
>   will expand the tar file in the current directory. If desired, an alternative directory may be
>   specified with the `-w` argument.
> - Run the script with the `--help` argument to see full usage options.

```bash
/usr/share/doc/csm/scripts/operations/configuration/import_ims_data.py -f <path-to-tar file> <add|overwrite|update>
```

On success, the final lines of output will resemble the following:

```text
2023-10-13 16:58:47 INFO     Waiting for rolling restart to complete (this may take a few minutes)
2023-10-13 17:00:11 INFO     DONE!
```
