# Validate `BOOTRAID` Artifacts

Perform the following steps **on ncn-m001**.

1. Initialize the `cray` command and follow the prompts (required for the next step).

   ```screen
   ncn-m001# cray init
   ```

1. Run the script to ensure the local BOOTRAID has a valid kernel and initrd.

    ```screen
    ncn-m001# /opt/cray/tests/install/ncn/scripts/validate-bootraid-artifacts.sh
    ```

## Workaround: CASMINST-2015

As a result of rebuilding any NCN(s), remove any dynamically assigned interface IP addresses that did not get released automatically by running the CASMINST-2015 script:

```bash
ncn-m001# /usr/share/doc/csm/scripts/CASMINST-2015.sh
```

Once that is done only follow the steps in the section for the node type that was rebuilt:

[Storage Node](Re-add_Storage_Node_to_Ceph.md)
