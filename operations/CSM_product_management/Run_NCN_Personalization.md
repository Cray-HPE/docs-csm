# Run NCN Personalization

NCN personalization is the process of applying product-specific configuration
to NCN nodes post-boot. Prior to running this procedure, gather the following
information required by [CFS](../configuration_management/Configuration_Management.md)
to create a [configuration layer](../configuration_management/Configuration_Layers.md):

* HTTP clone URL for the configuration repository in [VCS](../configuration_management/Version_Control_Service_VCS.md),
* Path to the Ansible play to run in the repository,
* Commit ID in the repository for CFS to pull and run on the nodes.

Products may supply multiple plays to run, in which case multiple configuration
layers must be created.

<a name="ncn_personalization_determine_existence"></a>
## Determine if NCN Personalization CFS Configuration Exists

If upgrading a product to a new version, an NCN personalization configuration in
CFS should already exist. By default the configuration is named `ncn-personalization`.

1. Determine if a configuration already exists.
   ```bash
   ncn# cray cfs configurations describe ncn-personalization --format json > ncn-personalization.json
   ```

If the configuration exists, the `ncn-personalization.json` file will be
populated with configuration layers. If it does not exist, the file will be
empty and the command will respond with an error.

<a name="ncn_personalization_add_layer"></a>
## Add Layer(s) to the CFS Configuration

1. Add a configuration layer to the `ncn-personalization.json` file.
   1. If the `ncn-personalization.json` file is empty, overwrite the file with
      the configuration layer(s) information gathered from the product that is
      configuring the NCNs. Use the [sample file with a single layer](../configuration_management/Configuration_Layers.md#configuration_layer_example_configuration_single)
      as a template.
   1. If a CFS configuration exists with one or more layers, add (or replace)
      the corresponding layer entry(ies) with the configuration layer
      information gathered for this specific product. For example:
   ```bash
   ncn# cat ncn-personalization.json
   {
      "layers": [
         # ...
         {
            "name": "<product-release-etc>",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/<product>-config-management.git",
            "playbook": "site.yml",
            "commit": "<git commit>"
         },
         # ... 
      ]
   }
   ```
   CFS executes the configuration layers in order. Consult the product
   documentation to determine if its configuration layer requires special
   placement in the layer list.

<a name="ncn_personalization_update_cfs_configuration"></a>
### Create/Update the NCN Personalization CFS Configuration Layer

1. Upload the configuration file to CFS to update or create the
   `ncn-personalization` CFS configuration.
   ```bash
   ncn# cray cfs configurations update ncn-personalization --file ncn-personalization.json --format json
   {
      "lastUpdated": "2021-07-28T03:26:01Z",
      "layers": [
         { ... layer information here ... },
      ],
      "name": "ncn-personalization"
   }
   ```
   > **WARNING**:
   > When running the above step, the CFS session may fail due to the node's
   > sshd configuration being corrupted by a different process. Run the
   > following command on all NCNs to fix the issue.
   >
   > ```bash
   > ncn# systemctl restart cfs-state-reporter
   > ```

<a name="ncn_personalization_set_component_config"></a>
### Set the Desired Configuration on all NCNs

1. Update the desired configuration for all NCNs.

   ```bash
   ncn# for xname in $(cray hsm state components list --role Management--format json | jq -r .Components[].ID)
   do
       cray cfs components update --desired-config ncn-personalization --enabled true --format json $xname
   done
   ```
   After this command is issued, the CFS Batcher service will dispatch a CFS
   session to configure the NCNs. Since the NCN is now managed by CFS by setting
   a desired configuration, the same will happen every time the NCN boots.

   > **WARNING**:
   > When running the above step, the CFS session may fail due to the node's
   > sshd configuration being corrupted by a different process. Run the
   > following command on all NCNs to fix the issue.
   >
   > ```bash
   > ncn# systemctl restart cfs-state-reporter
   > ```

1. Query the status of the NCN Personalization process. The status will be
   `pending` while the node is being configured by CFS, and will change to
   `configured` when the configuration has completed.

   ```bash
   ncn# export CRAY_FORMAT=json
   ncn# for xname in $(cray hsm state components list --role Management | jq -r .Components[].ID)
   do
       cray cfs components describe $xname | jq -r ' .id+" status="+.configurationStatus'
   done
   x3000c0s17b0n0 status=configured
   x3000c0s19b0n0 status=pending
   x3000c0s21b0n0 status=configured
   ...
   ```

   The NCN personalization step is complete and the NCNs are now configured as
   specified in the `ncn-personalization` configuration layers.

   See [Configuration Management of System Components](../configuration_management/Configuration_Management_of_System_Components.md)
   for information on setting desired configuration on specific nodes with CFS.

<a name="rerun_ncn_personalization"></a>
## Re-running NCN Personalization

If no changes have been made to the configuration layers (such as a new layer,
different playbook, or new commit made), but NCN personalization needs to be
run again, CFS can re-run NCN personalization.

Rerun the configuration for an NCN by clearing the state of the node. Clearing
the node will cause CFS to reconfigure the node, so long as the desired
configuration was [set previously](#ncn_personalization_set_component_config).

1. Clear the state of the node using CFS.

   Replace the XNAME value in the following command with the xname of the node
   being reconfigured.

   ```bash
   ncn# cray cfs components update --state '[]' <XNAME>
   ```

1. Clear the error count for the node in CFS.

   Replace the XNAME value in the following command with the xname of the node
   being reconfigured.
   ```bash
   ncn# cray cfs components update --error-count 0 <XNAME>
   ```

1. [Optional] To rerun NCN personalization on all NCNs at once, use the
   following loop:
   ```bash
   ncn# export CRAY_FORMAT=json
   ncn# for xname in $(cray hsm state components list --role Management | jq -r .Components[].ID)
   do
       cray cfs components update --error-count 0 $xname
       cray cfs components update --state '[]' $xname
   done
   ```
