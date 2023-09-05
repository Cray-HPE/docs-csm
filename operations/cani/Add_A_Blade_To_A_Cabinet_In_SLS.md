# Add A Blade To A Cabinet In SLS Using CANI

1. (`ncn#`|`external#`) Begin by [initializing a session](https://cray-hpe.github.io/cani/latest/commands/cani_alpha_session_init/), which will import data from SLS and create metadata in SLS' `ExtraProperties` field allowing the process to continue.

    ```shell
    cani alpha session init csm \
      --csm-keycloak-username username \
      --csm-keycloak-password password \
      --csm-api-host api-gw-service-nmn.local # initialize a session by importing SLS data to cani
    ```

    > Note: SLS data may be unstable if `cani` has never been run against it, in which case `cani` will not continue.  Resolve any of the data integrity errors before running the above command again.  Known issues and solutions can be found [here](https://cray-hpe.github.io/cani/latest/troubleshooting/known_errors/).

1. (`ncn#`|`external#`) [View available blade types and add one](https://cray-hpe.github.io/cani/latest/commands/cani_alpha_add_blade/) using suggested values.

    ```shell
    cani alpha add blade -L # see supported blade types
    cani alpha add blade <blade type> --auto # add a blade using recommended values
    ```

1. (`ncn#`|`external#`) [Apply](https://cray-hpe.github.io/cani/latest/commands/cani_alpha_session_apply/) the changes, writing the new data directly to SLS.

    ```shell
    cani alpha session apply # push changes to SLS
    ```
