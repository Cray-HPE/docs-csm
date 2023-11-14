# Change the BOS Version

By default, SAT uses Boot Orchestration Service (BOS) version two (`v2`).
Select the BOS version to use for individual commands with the `--bos-version`
option. For more information on this option, refer to the man page for a specific
command.

Another way to change the BOS version is by configuring it under the
`api_version` setting in the `bos` section of the SAT configuration file.
If the system is using an existing SAT configuration file from an older
version of SAT, the `bos` section might not exist. In that case, add the `bos`
section with the BOS version desired in the `api_version` setting.

1. Find the SAT configuration file at `~/.config/sat/sat.toml`, and look for a
   section like this:

   ```toml
   [bos]
   api_version = "v2"
   ```

   In this example, SAT is using BOS version `"v2"`.

1. Change the line specifying the `api_version` to the BOS version desired (for
   example, `"v1"`).

   ```toml
   [bos]
   api_version = "v1"
   ```

1. If applicable, uncomment the `api_version` line.

   If the system is using an existing SAT configuration file from a recent
   version of SAT, the `api_version` line might be commented out like this:

   ```toml
   [bos]
   # api_version = "v2"
   ```

   If the line is commented out, SAT will still use the default BOS
   version. To ensure a different BOS version is used, uncomment the
   `api_version` line by removing `#` at the beginning of the line.
