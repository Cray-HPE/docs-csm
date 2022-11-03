# Obtain the Configuration of a UAS Volume

View the configuration information of a specific UAS volume. This procedure requires the `volume_ID` of that volume.

### Prerequisites

-   Install and initialize the `cray` administrative CLI.
-   Obtain the UAS volume ID of a volume. Perform [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) if needed.

### Procedure

1.  View the configuration of a specific UAS volume.

    This command returns output in TOML format by default. JSON or YAML formatted output can be obtained by using the `--format json` or `--format yaml` options respectively.

    ```bash
    ncn-m001-pit# cray uas admin config volumes describe \
    a0066f48-9867-4155-9268-d001a4430f5c --format json
    {
      "mount_path": "/host_files/host_passwd",
      "volume_description": {
        "host_path": {
          "path": "/etc/passwd",
          "type": "FileOrCreate"
        }
      },
      "volume_id": "a0066f48-9867-4155-9268-d001a4430f5c",
      "volumename": "my-volume-with-passwd-from-the-host-node"
    }
    ```

