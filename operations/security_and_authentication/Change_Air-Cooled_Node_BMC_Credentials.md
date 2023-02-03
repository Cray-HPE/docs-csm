# Change Air-Cooled Node BMC Credentials Using SAT

This procedure describes how to use the System Admin Toolkit's (SAT) `sat bmccreds`
command to set a global credential for all BMCs on air-cooled nodes.

For more information including alternate methods of using `sat bmccreds`, see: [Set BMC Credentials Using SAT](../../operations/system_configuration_service/Set_BMC_Credentials.md),
or the `sat-bmccreds(8)` man page by running `sat-man bmccreds`.

## Limitations

All air-cooled and liquid-cooled BMCs share the same global credentials. The air-cooled Slingshot switch controllers (Router BMCs) must have the same credentials as the liquid-cooled Slingshot switch controllers.

The `sat bmccreds` command is only able to target specific Node BMCs by their component name (xname). To target just the air-cooled node BMCs, a list of their xnames must be passed into the command.

## Prerequisites

SAT is installed and configured.

## Procedure

1. (`ncn-m#`) Get the xnames for all air-cooled nodes.

    The following operation will store the xnames in a variable named `RIVER_NODEBMC_XNAMES`.

    ```bash
    RIVER_NODEBMC_XNAMES=$(cray hsm state components list --class River --type NodeBMC \
        --format json | jq -r '[.Components[] | .ID ]| join(",")')
    ```

1. (`ncn-m#`) Set the same random password for every BMC on an air-cooled node.

   The command will generate a single random string and apply it to every node BMC in the system.

    ```bash
    sat bmccreds --xnames $RIVER_NODEBMC_XNAMES --random-password --pw-domain system
    ```

1. (Optional) View the generated password in Vault. The `sat bmccreds` command will not print the generated
   random password, so it is necessary to view it in Vault.

    1. (`ncn-m#`) Set the Vault alias, if it is not already set.

        ```bash
        VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
        alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN="$VAULT_PASSWD" VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
        ```

    1. (`ncn-m#`) View the password for a node BMC, for example by using the `RIVER_NODEBMC_XNAMES` environment
       variable.

        ```bash
        echo $RIVER_NODEBMC_XNAMES
        vault kv get secret/hms-creds/<XNAME>
        ```
