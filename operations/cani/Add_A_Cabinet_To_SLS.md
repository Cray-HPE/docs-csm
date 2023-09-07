# Add A Cabinet To SLS using CANI

1. (`ncn#`|`external#`) Begin by [initializing a session](https://cray-hpe.github.io/cani/latest/commands/cani_alpha_session_init/), which will import data from SLS and create metadata in SLS' `ExtraProperties` field allowing the process to continue.

    ```shell
    cani alpha session init csm \
      --csm-keycloak-username username \
      --csm-keycloak-password password \
      --csm-api-host api-gw-service-nmn.local # initialize a session by importing SLS data to cani
    ```

    > Note: SLS data may be unstable if `cani` has never been run against it, in which case `cani` will not continue.  Resolve any of the data integrity errors before running the above command again.  Known issues and solutions can be found [here](https://cray-hpe.github.io/cani/latest/troubleshooting/known_errors/).

1. (`ncn#`|`external#`) [View available cabinet types and add one](https://cray-hpe.github.io/cani/latest/commands/cani_alpha_add_cabinet/) using suggested values.

    ```shell
    cani alpha add cabinet -L # see supported cabinet types
    cani alpha add cabinet <cabinet type> --auto # add a cabinet using recommended values
    ```

    > **Note**: A newly-added cabinet will be empty.  [Blades can be added](../cani/Add_A_Blade_To_A_Cabinet_In_SLS.md) in a manner similiar to the cabinet.

1. (`ncn#`|`external#`) [Apply](https://cray-hpe.github.io/cani/latest/commands/cani_alpha_session_apply/) the changes, writing the new data directly to SLS.

    ```text
    cani alpha session apply # push changes to SLS
    ```

    > **`NOTE`**: No hardware in these new cabinets will be discovered until the management network has been reconfigured to support the new cabinets, and routes have been added to the management NCNs in the system.
