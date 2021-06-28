---
category: numbered
---

# Delete a UAI

Procedure to delete a UAS instance.

A UAI is up and running.

-   **ROLE**

    User, System Administrator

-   **OBJECTIVE**

    The cray uas command allows users to manage UAIs. This procedure deletes one of the user's UAIs. To delete all UAIs on the system, see "List and Delete UAIs" in the *HPE Cray EX System Administration Guide S-8001*.

-   **LIMITATIONS**

    Currently, the user must SSH to the system as `root`.


1.  Log in to an NCN as `root`.

2.  List existing UAIs.

    ```screen
    ncn-w001# cray uas list
    
    username = "user"
    uai_host = "ncn-w001"
    uai_status = "Running: Ready"
    uai_connect_string = "ssh user@203.0.113.0 -i ~/.ssh/id\_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_age = "0m"
    uai_name = "uai-user-be3a6770"
    
    username = "user"
    uai_host = "ncn-s001"
    uai_status = "Running: Ready"
    uai_connect_string = "ssh user@203.0.113.0 -i ~/.ssh/id_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_age = "11m"
    uai_name = "uai-user-f488eef6"
    ```

3.  Delete a UAI.

    ```screen
    ncn-w001# cray uas delete -–uai-list UAI\_NAME
    results = [ "Successfully deleted uai-user-be3a6770",]
    ```


When a UAI is deleted, WLM jobs are not cancelled or cleaned up.

**Parent topic:**[User Access Service \(UAS\)](User_Access_Service_UAS.md)

