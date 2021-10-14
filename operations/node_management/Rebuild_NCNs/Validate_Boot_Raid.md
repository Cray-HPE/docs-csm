# 6. Validate `BOOTRAID` artifacts

Perform the following steps **on ncn-m001**.

1. Initialize the `cray` command and follow the prompts (required for the next step):

    ```
    ncn-m001# cray init
    ```

1. Run the script to ensure the local BOOTRAID has a valid kernel and initrd

    ```
    ncn-m001# /opt/cray/tests/install/ncn/scripts/validate-bootraid-artifacts.sh
    ```