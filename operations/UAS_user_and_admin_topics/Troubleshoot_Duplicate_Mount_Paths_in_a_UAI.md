# Troubleshoot Duplicate Mount Paths in a UAI

If a user attempts to create a UAI in the legacy mode and cannot create the UAI at all, a good place to look is at volumes. Duplicate `mount_path` specifications in the list of volumes in a UAI will cause a failure that looks like this:

```bash
ncn-m001-pit# cray uas create --publickey ~/.ssh/id_rsa.pub
```

Example output:

```bash
Usage: cray uas create [OPTIONS]
Try 'cray uas create --help' for help.

Error: Unprocessable Entity: Failed to create deployment uai-erl-543cdbbc: Unprocessable Entity
```

Currently, there is not a lot of UAS log information available from this error (this is a known problem), but a likely cause is duplicate `mount_path` specifications in volumes. Looking through the configured volumes for duplicates can be helpful.

```bash
ncn-m001-pit# cray uas admin config volumes list | grep -e mount_path -e volumename -e volume_id
```

Example output:

```bash
mount_path = "/app/broker"
volume_id = "1f3bde56-b2e7-4596-ab3a-6aa4327d29c7"
volumename = "broker-entrypoint"
mount_path = "/etc/sssd"
volume_id = "4dc6691e-e7d9-4af3-acde-fc6d308dd7b4"
volumename = "broker-sssd-config"
mount_path = "/etc/localtime"
volume_id = "55a02475-5770-4a77-b621-f92c5082475c"
volumename = "timezone"
mount_path = "/root/slurm_config/munge"
volume_id = "7aeaf158-ad8d-4f0d-bae6-47f8fffbd1ad"
volumename = "munge-key"
mount_path = "/opt/forge"
volume_id = "7b924270-c9e9-4b0e-85f5-5bc62c02457e"
volumename = "delete-me"
mount_path = "/lus"
volume_id = "9fff2d24-77d9-467f-869a-235ddcd37ad7"
volumename = "lustre"
mount_path = "/etc/switchboard"
volume_id = "d5058121-c1b6-4360-824d-3c712371f042"
volumename = "broker-sshd-config"
mount_path = "/etc/slurm"
volume_id = "ea97325c-2b1d-418a-b3b5-3f6488f4a9e2"
volumename = "slurm-config"
mount_path = "/opt/forge_license"
volume_id = "ecfae4b2-d530-4c06-b757-49b30061c90a"
volumename = "optforgelicense"
mount_path = "/opt/forge"
volume_id = "fc95d0da-6296-4d0b-8f26-2d4338604991"
volumename = "optforge"
```

Looking through this list, the mount path for the volume named `delete-me` and the mount path for the volume named `optforge` are the same. The obvious candidate for deletion in this case is `delete-me`, so it can be deleted.

```bash
ncn-m001-pit# cray uas admin config volumes delete 7b924270-c9e9-4b0e-85f5-5bc62c02457e
```

Example output:

```bash
mount_path = "/opt/forge"
volume_id = "7b924270-c9e9-4b0e-85f5-5bc62c02457e"
volumename = "delete-me"

[volume_description.host_path]
path = "/tmp/foo"
type = "DirectoryOrCreate"
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Troubleshoot Missing or Incorrect UAI Images](Troubleshoot_Missing_or_Incorrect_UAI_Images.md)
