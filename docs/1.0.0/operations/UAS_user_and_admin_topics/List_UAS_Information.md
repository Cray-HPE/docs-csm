# List UAS Information

Use the `cray uas` command to gather information about the User Access Service's version, images, and running User Access Instances \(UAIs\).

### List UAS Version with `cray uas mgr-info list`

```screen
ncn-w001# cray uas mgr-info list
service_name = "cray-uas-mgr",
version = "0.11.3"
```

### List Available UAS Images with `cray uas images list`

```bash
ncn-w001# cray uas images list
default_image = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
image_list = [ "registry.local/cray/cray-uas-sles15sp1-slurm:latest", "registry.local/cray/cray-uas-sles15sp1:latest",]
```

### List All Running UAIs with `cray uas uais list`

```bash
ncn-w001# cray uas uais list
[[results]]
username = "user"
uai_host = "ncn-w001"
uai_status = "Running: Ready"
uai_connect_string = "ssh user@203.0.113.0 -i ~/.ssh/id_rsa"
uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
uai_age = "11m"
uai_name = "uai-user-be3a6770"

[[results]]

username = "user"
uai_host = "ncn-w001"
uai_status = "Running: Ready"
uai_connect_string = "ssh user@203.0.113.0 -i ~/.ssh/id_rsa"
uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
uai_age = "14m"
uai_name = "uai-user-f488eef6"
```

### List UAI Information for Current User with `cray uas list`

```bash
ncn-w001# cray uas list
[[results]]
username = "user"
uai_host = "ncn-w001"
uai_status = "Running: Ready"
uai_connect_string = "ssh user@203.0.113.0 -i ~/.ssh/id\_rsa"
uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
uai_age = "11m"
uai_name = "uai-user-be3a6770"
```

### List UAIs on a Specific Host Node

```bash
ncn-w001# cray uas uais list --host ncn-w001
[[results]]
username = "user"
uai_host = "ncn-w001"
uai_status = "Running: Ready"
uai_connect_string = "ssh user@203.0.113.0 -i ~/.ssh/id_rsa"
uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
uai_age = "2h56m"
uai_name = "uai-user-f3b8eee0"
[[results]]
username = "user"
uai_host = "ncn-w001"
uai_status = "Running: Ready"
uai_connect_string = "ssh user@203.0.113.0 -i ~/.ssh/id_rsa"
uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
uai_age = "1d5h"
uai_name = "uai-user-f8671d33"
```

