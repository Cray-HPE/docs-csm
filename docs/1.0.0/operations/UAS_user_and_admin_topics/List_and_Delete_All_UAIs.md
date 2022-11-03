# List and Delete All UAIs

Delete all UAIs currently on the system.

### Prerequisites

At least one UAI is running.

### Procedure

1.  Log in to an NCN as `root`.

2.  List all the UAIs on the system.

    ```bash
    ncn-m001# cray uas uais list
    [[results]]
    username = "uastest"
    uai_host = "ncn-w001"
    uai_status = "Running: Ready"
    uai_connect_string = "ssh uastest@203.0.113.0 -p 32486 -i ~/.ssh/id_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_age = "2m"
    uai_name = "uai-uastest-f488eef6"

    [[results]]
    username = "uastest"
    uai_host = "ncn-w001"
    uai_status = "Running: Ready"
    uai_connect_string = "ssh uastest@203.0.113.0 -p 31833 -i ~/.ssh/id_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_age = "11m"
    uai_name = "uai-uastest-391da133"

    [[results]]
    username = "uasuser"
    uai_host = "ncn-w001"
    uai_status = "Running: Ready"
    uai_connect_string = "ssh uasuser@203.0.113.0 -p 32736 -i ~/.ssh/id_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_name = "uai-uasuser-66f8a478"
    ```

3.  Delete all the UAIs on the system.

    ```bash
    ncn-m001 # cray uas uais delete
    This will delete all running UAIs, Are you sure? [y/N]: y
    [
    "Successfully deleted uai-uastest-f488eef6",
    "Successfully deleted uai-uastest-391da133",
    "Successfully deleted uai-uasuser-66f8a478",
    ]
    ```

4.  Verify all UAIs are in the "Terminating" status.

    ```bash
    ncn-m001# cray uas uais list
    [[results]]
    username = "uastest"
    uai_host = "ncn-w001"
    uai_status = "Terminating"
    uai_connect_string = "ssh uastest@203.0.113.0 -p 32486 -i ~/.ssh/id_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_age = "2m"
    uai_name = "uai-uastest-f488eef6"

    [[results]]
    username = "uastest"
    uai_host = "ncn-w001"
    uai_status = "Terminating"
    uai_connect_string = "ssh uastest@203.0.113.0 -p 31833 -i ~/.ssh/id_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_age = "11m"
    uai_name = "uai-uastest-391da133"

    [[results]]
    username = "uasuser"
    uai_host = "ncn-w001"
    uai_status = "Terminating"
    uai_connect_string = "ssh uasuser@203.0.113.0 -p 32736 -i ~/.ssh/id_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_name = "uai-uasuser-66f8a478"
    ```

5.  Verify there are no running UAIs on the system.

    ```bash
    ncn-m001# cray uas uais list
    [[results]]
    ```

