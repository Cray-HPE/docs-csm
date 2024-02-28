# Exporting and Importing IMS Data

IMS public keys, images, and recipes, including associated artifacts stored in Ceph
[Simple Storage Service (S3)](../../glossary.md#simple-storage-service-s3), can be exported and imported
using an automated script.

- [Prerequisites](#prerequisites)
- [Export](#export)
- [Import](#import)

## Prerequisites

- Ensure that the [Cray CLI (`cray`)](../../glossary.md#cray-cli-cray) is authenticated and configured to talk to system management services.
  - See [Configure the Cray CLI](../configure_cray_cli.md).
- The latest CSM documentation RPM must be installed on the node where the procedure is being performed.
  - See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Export

(`ncn-mw#`) The `export_ims_data.py` script will create a tar file backup of the contents of IMS and
the associated S3
artifacts. In addition, it backs up any S3 artifacts whose links are found in
[Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos)
session templates,
[Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) boot parameters, or the Cray product catalog.

> - This tar file may be very large, depending on how many images are in IMS. By default the script
>   will create the tar file in the current directory. If desired, an alternative directory may be
>   specified by appending its path to the command line arguments.
> - Run the script with the `--help` argument to see full usage options.

```bash
/usr/share/doc/csm/scripts/operations/configuration/export_ims_data.py
```

On success, the final lines of output will resemble the following:

```text
Data saved to tar archive: /root/export-ims-data-20231013161618.084854-naswhadt.tar
DONE!
```

## Import

The `import_ims_data.py` script can be used to import the previously exported IMS public keys, images, and recipes.
It also imports the backed up S3 artifacts.

There are three types of imports possible:

- `add`

    In an `add` import, any IMS resources present in the exported data that are not present in IMS will be created.
    No resources in IMS will be deleted or changed.

- `overwrite`

    All jobs and resources in IMS are cleared, including deleted resources and associated S3 artifacts.
    Then an `add` import is performed.

- `soft_overwrite`

    All IMS jobs are deleted. Soft deletes are done on all existing IMS resources whose IDs are not associated with resources
    being imported. Hard deletes (including associated S3 artifacts) are done on all existing IMS resources whose IDs are
    associated with resources being imported. Then an `add` import is performed.

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
/usr/share/doc/csm/scripts/operations/configuration/import_ims_data.py -f <path-to-tar file> <add|overwrite|soft_overwrite|update>
```

On success, the final lines of output will resemble the following:

```text
Waiting for rolling restart to complete (this may take a few minutes)
DONE!
```
