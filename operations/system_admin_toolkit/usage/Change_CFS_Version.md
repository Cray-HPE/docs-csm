# Change the CFS Version

SAT supports specifying the version of the Configuration Framework Service (CFS)
API used by the `sat status` command. By default, the `sat status` command uses
version three (V3) of the CFS API. Currently, the `sat bootsys` and `sat
bootprep` commands can only use CFS V2, but support will be added for CFS V3 in
the future.

Select the CFS version to use for individual commands with the `--cfs-version`
option. For more information on this option, refer to the man page for a specific
command.

Another way to change the CFS version is by configuring it under the
`api_version` setting in the `cfs` section of the SAT configuration file.
If the system is using an existing SAT configuration file from an older
version of SAT, the `cfs` section might not exist. In that case, add the `cfs`
section with the CFS version desired in the `api_version` setting.

1. Find the SAT configuration file at `~/.config/sat/sat.toml`, and look for a
   section like this:

   ```toml
   [cfs]
   api_version = "v3"
   ```

   In this example, SAT is using CFS version `"v3"`.

2. Change the line specifying the `api_version` to the CFS version desired (for
   example, `"v2"`).

   ```toml
   [cfs]
   api_version = "v2"
   ```

3. If applicable, uncomment the `api_version` line.

   If the system is using an existing SAT configuration file from a recent
   version of SAT, the `api_version` line might be commented out like this:

   ```toml
   [cfs]
   # api_version = "v3"
   ```

   If the line is commented out, SAT will still use the default CFS
   version. To ensure a different CFS version is used, uncomment the
   `api_version` line by removing `#` at the beginning of the line.

## Key Changes and Improvements with CFS V3

- CFS V3 on SAT provides optimized results for larger systems, offering quicker responses.
- Paging is only available when using the CFS V3 API. This ensures that even with a large number
  of components, SAT can retrieve configurations more efficiently.
- When the number of components exceeds the CFS page size, CFS V3 is able to handle the
  system by paginating the results. This is an improvement over CFS v2 on SAT, which would
  return an error when number of components exceeds the response limit.
  For more information on paging see [Paging CFS Records](../../configuration_management/Paging_CFS_Records.md).

## Limitations with CFS V2

- When using CFS V2, the number of entries returned in a single query is
  limited by the `default_page_size` parameter, which is 1000.
- If the system contains more than 1000 components, CFS V2 will return
  an error as the response size is too large for the system to handle in a
  single query.

## Limitations on CFS V3 Support

As mentioned above, usage of the CFS V3 API is only supported for the `sat
status` command. The following commands use CFS V2:

- `sat bootprep` uses the CFS V2 API to create configurations.
- `sat bootsys` uses the CFS V2 API to check for active CFS sessions.
