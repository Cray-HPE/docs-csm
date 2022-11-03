# Configure a Default UAI Class for Legacy Mode

Using a default UAI class is optional but recommended for any site using the legacy UAI management mode that wants to have some control over UAIs created by users. UAI classes used for this purpose need to have certain minimum configuration in them:

* The `image_id` field set to identify the image used to construct UAIs
* The `volume_list` field set to the list of volumes to mount in UAIs
* The `public_ip` field set to `true`
* The `uai_compute_network` flag set to `true` (if workload management will be used)
* The `default` flag set to `true` to make this the default UAI class

To make UAIs useful, there is a minimum set of volumes that should be defined in the UAS configuration:

* `/etc/localtime` for default timezone information
* whatever directory on the host nodes holds persistent end-user storage, typically `/lus`

In addition to this, there may be volumes defined to support a workload manager (Slurm or PBS Professional) or the Cray Programming Environment (PE) or other packages the full extent of these volumes is outside the scope of this document, but whatever list of these other volumes is needed to get a suitable end-user UAI should be included in the default UAI class configuration.

### Example Minimal Default UAI Class

The following is an example set of volumes and an example of how to create a UAI class that would use those volumes for a minimal system:

```
ncn-m001-pit# cray uas admin config volumes list --format json
[
  {
    "mount_path": "/etc/localtime",
    "volume_description": {
      "host_path": {
        "path": "/etc/localtime",
        "type": "FileOrCreate"
      }
    },
    "volume_id": "55a02475-5770-4a77-b621-f92c5082475c",
    "volumename": "timezone"
  },
  {
    "mount_path": "/lus",
    "volume_description": {
      "host_path": {
        "path": "/lus",
        "type": "DirectoryOrCreate"
      }
    },
    "volume_id": "9fff2d24-77d9-467f-869a-235ddcd37ad7",
    "volumename": "lustre"
  }
]

ncn-m001-pit# cray uas admin config images list
[[results]]
default = false
image_id = "c5dcb261-5271-49b3-9347-afe7f3e31941"
imagename = "dtr.dev.cray.com/cray/cray-uai-broker:latest"

[[results]]
default = false
image_id = "c5f6377a-dfc0-41da-89c9-6c88c8a2cda8"
imagename = "dtr.dev.cray.com/cray/cray-uas-sles15:latest"

[[results]]
default = true
image_id = "ff86596e-9699-46e8-9d49-9cb20203df8c"
imagename = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"

ncn-m001-pit# cray uas admin config classes create --image-id ff86596e-9699-46e8-9d49-9cb20203df8c --volume-list '55a02475-5770-4a77-b621-f92c5082475c,9fff2d24-77d9-467f-869a-235ddcd37ad7' --uai-compute-network yes --public-ip yes --comment "my default legacy mode uai class" --default yes
class_id = "e2ea4845-5951-4c79-93d7-186ced8ce8ad"
comment = "my default legacy mode uai class"
default = true
namespace = "user"
opt_ports = []
priority_class_name = "uai-priority"
public_ip = true
uai_compute_network = true
[[volume_mounts]]
mount_path = "/etc/localtime"
volume_id = "55a02475-5770-4a77-b621-f92c5082475c"
volumename = "timezone"

[volume_mounts.volume_description.host_path]
path = "/etc/localtime"
type = "FileOrCreate"
[[volume_mounts]]
mount_path = "/lus"
volume_id = "9fff2d24-77d9-467f-869a-235ddcd37ad7"
volumename = "lustre"

[volume_mounts.volume_description.host_path]
path = "/lus"
type = "DirectoryOrCreate"

[uai_image]
default = true
image_id = "ff86596e-9699-46e8-9d49-9cb20203df8c"
imagename = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
```

### Example Default UAI Class with Slurm Support

The following is an example of a default UAI class configured for Slurm support if Slurm has been installed on the host system:

```
ncn-m001-pit# cray uas admin config volumes list --format json
[
  {
    "mount_path": "/etc/localtime",
    "volume_description": {
      "host_path": {
        "path": "/etc/localtime",
        "type": "FileOrCreate"
      }
    },
    "volume_id": "55a02475-5770-4a77-b621-f92c5082475c",
    "volumename": "timezone"
  },
  {
    "mount_path": "/root/slurm_config/munge",
    "volume_description": {
      "secret": {
        "secret_name": "munge-secret"
      }
    },
    "volume_id": "7aeaf158-ad8d-4f0d-bae6-47f8fffbd1ad",
    "volumename": "munge-key"
  },
  {
    "mount_path": "/lus",
    "volume_description": {
      "host_path": {
        "path": "/lus",
        "type": "DirectoryOrCreate"
      }
    },
    "volume_id": "9fff2d24-77d9-467f-869a-235ddcd37ad7",
    "volumename": "lustre"
  },
  {
    "mount_path": "/etc/slurm",
    "volume_description": {
      "config_map": {
        "name": "slurm-map"
      }
    },
    "volume_id": "ea97325c-2b1d-418a-b3b5-3f6488f4a9e2",
    "volumename": "slurm-config"
  }
]

ncn-m001-pit# cray uas admin config images list
[[results]]
default = false
image_id = "c5dcb261-5271-49b3-9347-afe7f3e31941"
imagename = "dtr.dev.cray.com/cray/cray-uai-broker:latest"

[[results]]
default = false
image_id = "c5f6377a-dfc0-41da-89c9-6c88c8a2cda8"
imagename = "dtr.dev.cray.com/cray/cray-uas-sles15:latest"

[[results]]
default = true
image_id = "ff86596e-9699-46e8-9d49-9cb20203df8c"
imagename = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"

ncn-m001-pit# cray uas admin config classes create --image-id ff86596e-9699-46e8-9d49-9cb20203df8c --volume-list '55a02475-5770-4a77-b621-f92c5082475c,9fff2d24-77d9-467f-869a-235ddcd37ad7,7aeaf158-ad8d-4f0d-bae6-47f8fffbd1ad,ea97325c-2b1d-418a-b3b5-3f6488f4a9e2' --uai-compute-network yes --public-ip yes --comment "my default legacy mode uai class" --default yes
class_id = "c0a6dfbc-f74c-4f2c-8c8e-e278ff0e14c6"
comment = "my default legacy mode uai class"
default = true
namespace = "user"
opt_ports = []
priority_class_name = "uai-priority"
public_ip = true
uai_compute_network = true
[[volume_mounts]]
mount_path = "/etc/localtime"
volume_id = "55a02475-5770-4a77-b621-f92c5082475c"
volumename = "timezone"

[volume_mounts.volume_description.host_path]
path = "/etc/localtime"
type = "FileOrCreate"
[[volume_mounts]]
mount_path = "/lus"
volume_id = "9fff2d24-77d9-467f-869a-235ddcd37ad7"
volumename = "lustre"

[volume_mounts.volume_description.host_path]
path = "/lus"
type = "DirectoryOrCreate"
[[volume_mounts]]
mount_path = "/root/slurm_config/munge"
volume_id = "7aeaf158-ad8d-4f0d-bae6-47f8fffbd1ad"
volumename = "munge-key"

[volume_mounts.volume_description.secret]
secret_name = "munge-secret"
[[volume_mounts]]
mount_path = "/etc/slurm"
volume_id = "ea97325c-2b1d-418a-b3b5-3f6488f4a9e2"
volumename = "slurm-config"

[volume_mounts.volume_description.config_map]
name = "slurm-map"

[uai_image]
default = true
image_id = "ff86596e-9699-46e8-9d49-9cb20203df8c"
imagename = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
```

