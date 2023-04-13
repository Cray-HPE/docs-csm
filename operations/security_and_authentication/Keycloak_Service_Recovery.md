# Keycloak Service Recovery

The following covers redeploying the Keycloak service and restoring the data.

## Prerequisites

- The system is fully installed and has transitioned off of the LiveCD.
- All activities required for site maintenance are complete.
- A backup or export of the data already exists.
- The latest CSM documentation has been installed on the master nodes. See [Check for Latest Documentation](../../update_product_stream/index.md#check-for-latest-documentation).
- The Cray CLI has been configured on the node where the procedure is being performed. See [Configure the Cray CLI](../configure_cray_cli.md).

## Service recovery for Keycloak

1. (`ncn-mw#`) Verify that a backup of the Keycloak Postgres data exists.

   1. Verify a completed backup exists.

      ```bash
      cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("keycloak"))'
      ```

      Example output:

      ```text
      keycloak-postgres-2022-09-14T02:10:05.manifest
      keycloak-postgres-2022-09-14T02:10:05.psql
      ```

1. (`ncn-mw#`) Uninstall the chart and wait for the resources to terminate.

   1. Note the version of the chart that is currently deployed.

      ```bash
      helm history -n services cray-keycloak
      ```

      Example output:

      ```text
      REVISION    UPDATED                     STATUS      CHART               APP VERSION DESCRIPTION
      1           Tue Aug  2 22:14:31 2022    deployed    cray-keycloak-3.3.1 3.1.1       Install complete
      ```

   1. Uninstall the chart.

      ```bash
      helm uninstall -n services cray-keycloak
      ```

      Example output:

      ```text
      release "cray-keycloak" uninstalled
      ```

   1. Wait for the resources to terminate.

      ```bash
      watch "kubectl get pods -n services | grep keycloak | grep -v 'keycloak-users-localize\|keycloak-vcs-user'"
      ```

     Example output:

      ```text
      No resources found in services namespace.
      ```

1. (`ncn-mw#`) Redeploy the chart and wait for the resources to start.

   1. Create the manifest.

      ```bash
      kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
      kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}' > cray-keycloak.yaml
      for i in $(yq r cray-keycloak.yaml 'spec.charts[*].name' | grep -Ev '^cray-keycloak$'); do yq d -i cray-keycloak.yaml 'spec.charts(name=='"$i"')'; done
      yq w -i cray-keycloak.yaml metadata.name cray-keycloak
      yq d -i cray-keycloak.yaml spec.sources
      yq w -i cray-keycloak.yaml spec.sources.charts[0].location 'https://packages.local/repository/charts'
      yq w -i cray-keycloak.yaml spec.sources.charts[0].name csm-algol60
      yq w -i cray-keycloak.yaml spec.sources.charts[0].type repo
      manifestgen -c customizations.yaml -i cray-keycloak.yaml -o manifest.yaml
      ```

   1. Check that the chart version is correct based on the earlier `helm history`.

      ```bash
      grep "version:" manifest.yaml 
      ```

      Example output:

      ```yaml
            version: 3.3.1
      ```

   1. Redeploy the chart.

      ```bash
      loftsman ship --manifest-path ${PWD}/manifest.yaml
      ```

      Example output contains:

      ```text
      NAME: cray-keycloak
      ...
      STATUS: deployed
      ```

   1. Wait for the resources to start.

      ```bash
      watch "kubectl get pods -n services | grep keycloak"
      ```

      Example output:

      ```text
      cray-keycloak-0                                                   2/2     Running     0          32m
      cray-keycloak-1                                                   2/2     Running     0          32m
      cray-keycloak-2                                                   2/2     Running     0          32m
      keycloak-postgres-0                                               3/3     Running     0          32m
      keycloak-postgres-1                                               3/3     Running     0          31m
      keycloak-postgres-2                                               3/3     Running     0          30m
      keycloak-setup-1-9kdl2                                            0/2     Completed   0          32m
      keycloak-users-localize-1-jjb9b                                   2/2     Running     0          32m
      keycloak-vcs-user-1-gqftw                                         0/2     Completed   0          31m
      keycloak-wait-for-postgres-1-xt4nv                                0/2     Completed   0          32m
      ```

1. (`ncn-mw#`) Restore the critical data.

   See [Restore Postgres for Keycloak](../kubernetes/Restore_Postgres.md#restore-postgres-for-keycloak).
