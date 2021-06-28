---
category: numbered
---

# List Volumes Registered in UAS

How to list the configuration information for the volumes registered in UAS. Use this procedure to obtain the volume IDs required by other UAS commands.

Install and initialize the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    List the details of all volumes registered in UAS with the cray uas admin config volumes list command. Use this command to obtain the volume\_id value of volume, which is required for other UAS administrative commands.


-   **LIMITATIONS**

    None.


1.  List the details of all the volumes registered in UAS.

    -   Print out the list in TOML.

        ```screen
        ncn-m001-pit# cray uas admin config volumes list
        [[results]]
        mount_path = "/lus"
        volume_id = "2b23a260-e064-4f3e-bee5-3da8e3664f29"
        volumename = "lustre"
        
        [results.volume_description.host_path]
        path = "/lus"
        type = "DirectoryOrCreate"
        [[results]]
        mount_path = "/etc/slurm"
        volume_id = "53ea3f18-b202-455f-a8ec-79f9463aeb7b"
        volumename = "slurm-config"
        
        [results.volume_description.config_map]
        name = "slurm-map"
        [[results]]
        mount_path = "/root/slurm_config/munge"
        volume_id = "656aed94-fb5a-4b94-bcb7-19607bd8670f"
        volumename = "munge-key"
        
        [results.volume_description.secret]
        secret_name = "munge-secret"
        [[results]]
        mount_path = "/etc/pbs"
        volume_id = "7ee2bbe9-6428-43c8-b626-0d2316f3aff8"
        volumename = "pbs-config"
        
        [results.volume_description.config_map]
        name = "pbs-config"
        [[results]]
        mount_path = "/opt/forge_license"
        volume_id = "99e705a2-9bde-48cf-934d-ae721403d8fa"
        volumename = "optforgelicense"
        
        [results.volume_description.host_path]
        path = "/opt/forge_license"
        type = "DirectoryOrCreate"
        [[results]]
        mount_path = "/opt/forge"
        volume_id = "de224953-f5de-42f4-9d18-638855799dba"
        volumename = "opt-forge"
        
        [results.volume_description.host_path]
        path = "/opt/forge"
        type = "DirectoryOrCreate"
        [[results]]
        mount_path = "/etc/localtime"
        volume_id = "ef4be476-79c4-4b76-a9ba-e6dccf2a16db"
        volumename = "timezone"
        
        [results.volume_description.host_path]
        path = "/etc/localtime"
        type = "FileOrCreate"
        ```

    -   Print out the list in YAML format.

        ```screen
        ncn-m001-pit# cray uas admin config volumes list --format yaml
        - mount_path: /lus
          volume_description:
            host_path:
              path: /lus
              type: DirectoryOrCreate
          volume_id: 2b23a260-e064-4f3e-bee5-3da8e3664f29
          volumename: lustre
        - mount_path: /etc/slurm
          volume_description:
            config_map:
              name: slurm-map
          volume_id: 53ea3f18-b202-455f-a8ec-79f9463aeb7b
          volumename: slurm-config
        - mount_path: /root/slurm_config/munge
          volume_description:
            secret:
              secret_name: munge-secret
          volume_id: 656aed94-fb5a-4b94-bcb7-19607bd8670f
          volumename: munge-key
        - mount_path: /etc/pbs
          volume_description:
            config_map:
              name: pbs-config
          volume_id: 7ee2bbe9-6428-43c8-b626-0d2316f3aff8
          volumename: pbs-config
        - mount_path: /opt/forge_license
          volume_description:
            host_path:
              path: /opt/forge_license
              type: DirectoryOrCreate
          volume_id: 99e705a2-9bde-48cf-934d-ae721403d8fa
          volumename: optforgelicense
        - mount_path: /opt/forge
          volume_description:
            host_path:
              path: /opt/forge
              type: DirectoryOrCreate
          volume_id: de224953-f5de-42f4-9d18-638855799dba
          volumename: opt-forge
        - mount_path: /etc/localtime
          volume_description:
            host_path:
              path: /etc/localtime
              type: FileOrCreate
          volume_id: ef4be476-79c4-4b76-a9ba-e6dccf2a16db
          volumename: timezone
        ```

    -   Print out the list in JSON format.

        ```screen
        ncn-m001-pit# cray uas admin config volumes list --format json
        [
          {
            "mount_path": "/lus",
            "volume_description": {
              "host_path": {
                "path": "/lus",
                "type": "DirectoryOrCreate"
              }
            },
            "volume_id": "2b23a260-e064-4f3e-bee5-3da8e3664f29",
            "volumename": "lustre"
          },
          {
            "mount_path": "/etc/slurm",
            "volume_description": {
              "config_map": {
                "name": "slurm-map"
              }
            },
            "volume_id": "53ea3f18-b202-455f-a8ec-79f9463aeb7b",
            "volumename": "slurm-config"
          },
          {
            "mount_path": "/root/slurm_config/munge",
            "volume_description": {
              "secret": {
                "secret_name": "munge-secret"
              }
            },
            "volume_id": "656aed94-fb5a-4b94-bcb7-19607bd8670f",
            "volumename": "munge-key"
          },
          {
            "mount_path": "/etc/pbs",
            "volume_description": {
              "config_map": {
                "name": "pbs-config"
              }
            },
            "volume_id": "7ee2bbe9-6428-43c8-b626-0d2316f3aff8",
            "volumename": "pbs-config"
          },
          {
            "mount_path": "/opt/forge_license",
            "volume_description": {
              "host_path": {
                "path": "/opt/forge_license",
                "type": "DirectoryOrCreate"
              }
            },
            "volume_id": "99e705a2-9bde-48cf-934d-ae721403d8fa",
            "volumename": "optforgelicense"
          },
          {
            "mount_path": "/opt/forge",
            "volume_description": {
              "host_path": {
                "path": "/opt/forge",
                "type": "DirectoryOrCreate"
              }
            },
            "volume_id": "de224953-f5de-42f4-9d18-638855799dba",
            "volumename": "opt-forge"
          },
          {
            "mount_path": "/etc/localtime",
            "volume_description": {
              "host_path": {
                "path": "/etc/localtime",
                "type": "FileOrCreate"
              }
            },
            "volume_id": "ef4be476-79c4-4b76-a9ba-e6dccf2a16db",
            "volumename": "timezone"
          }
        ]
        ```

    The JSON formatted output can help guide administrators to construct the volume descriptions required to add or update a volume description in UAS. JSON is the required input format for volume descriptions in UAS. Refer to [Elements of a UAI](Elements_of_a_UAI.md) for descriptions of mount\_path, volume\_description, volume\_id, and volumename.


