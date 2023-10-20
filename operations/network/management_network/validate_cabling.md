# Validate Cabling

> **Warning:**  If this step is completed when NCNs are offline or shutdown, the information compared here will not match the actual connections. Therefore, this step should be re-run again once the whole system is up.

1. To validate the cabling you can run command similar to below:

    ```bash
    canu validate shcd-cabling --ips 10.252.0.2,10.252.0.3 --tabs 40G_10G --corners J12,T36 --shcd ./SHCD.xlsx
    ```

    > **`NOTE`** Modify the command to use the correct SHCD file and correct `--tabs`, `--corners`, and IP addresses.

    The output should look as follows:

    ```text
    sw-spine-001
    Rack: x3000    Elevation: u24

    --------------------------------------------------------------
    Port | SHCD                   | Cabling
    --------------------------------------------------------------

    1      ncn-w001:pcie-slot1:1    ncn-w001:pcie-slot1:2
    2      ncn-w002:pcie-slot1:1    ncn-w002:pcie-slot1:1
    3      ncn-w003:pcie-slot1:1    ncn-w003:pcie-slot1:1

    sw-spine-002
    Rack: x3000    Elevation: u24

    --------------------------------------------------------------
    Port | SHCD                   | Cabling
    --------------------------------------------------------------

    1     ncn-w001:pcie-slot1:2    ncn-w001:pcie-slot1:2
    2     ncn-w002:pcie-slot1:2    ncn-w002:pcie-slot1:2
    3     ncn-w003:pcie-slot1:2    ncn-w003:pcie-slot1:2
    ```

    In the returned output, look for differences between the SHCD and actual network configuration.

    In the above example, incorrect cabling was detected on the `sw-spine-001` switch on port 1:

    1      ncn-w001:***pcie-slot1:1***    ncn-w001:***pcie-slot1:2****

    The SHCD has the correct information on port 1 but the actual switch configuration is mismatched.

    To fix this issue, re-cable `ncn-w001` so that it is correctly connected to `sw-spine-001`.

1. Return to [deploying the management nodes](../../../install/deploy_non-compute_nodes.md#23-check-lvm-on-kubernetes-ncns).

> **`NOTE`** The values for `--tabs` is the sheet within `SHCD.xlsx` file with a name in format `<number>G_<number>G`. For example, `25G_10G`, `40G_10G`, and so on.
> The values for `--corners` options are start cell and end cell of rightmost table (including table headers) on sheet specified with `--tabs` option.
> The value for `--shcd` is the path of `SHCD.xlsx` file to be used for the cluster under install.
> The cluster type, such as Full, TDS, or V1, can be obtained from [Generate Switch Configurations](generate_switch_configs.md).
