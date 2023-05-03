# Generate Switch Configurations

Generating configuration files can be done for a single switch or for the full system.

For example, if there is a suspected configuration issue on single switch, a configuration file can be generated for only that switch in order to simplify debugging.

## Prerequisites

* CANU installed with 1.6.13 or later versions.
  * Run `canu --version` to see version.
  * If doing a CSM install or upgrade, a CANU RPM is located in the release tarball.
    * See [Update CANU From CSM Tarball](canu/update_canu_from_csm_tarball.md).
  * Alternatively, upgrade or install the latest version of CANU from GitHub.
    * See [Install/Upgrade CANU](canu_install_update.md).
* Validated SHCD.
  * See [Validate SHCD](validate_shcd.md).
* JSON output from validated SHCD.
  * See [Validate SHCD](validate_shcd.md).
* System Layout Service (SLS) input file.
  * If generating CSM 1.2 configurations, the SLS file must be updated prior to generating configurations.
  * See [Collect Data](collect_data.md).
* Generate custom switch configuration.
  * See [CANU custom configuration](https://github.com/Cray-HPE/canu/blob/main/docs/network_configuration_and_upgrade/custom_config.md).

## Generate configuration files

Ensure that the correct architecture (`-a` parameter) is selected for the setup in use.

The following are the different architectures that can be specified:

* `Tds` – Aruba-based Test and Development System. These are small systems characterized by Kubernetes NCNs cabled directly to the spine.
* `Full` – Aruba-based Leaf-Spine systems. These are usually customer production systems.
* `V1` – Any Dell and Mellanox-based systems.

Generating a configuration file can be done for a single switch, or for the full system. Below are example commands for both scenarios:

**Important:** Modify the following items in the command:

* `--csm` : Which CSM version configuration do you want to use? For example, `1.3`, `1.2` or `1.0`
NOTE: Only major and minor versions of CSM are tracked at this time. CANU bug fixes are captured in the latest CANU version and do not align with CSM bug fix versions.
* `--a`   : What is the system architecture? (See above)
* `--ccj` : Match the `ccj.json` file to the one you created for your system.
* `--sls` : Match the `sls_file.json` to the one you created for your system.
* `--custom-config` : Pass in a switch configuration file that CANU will inject into the generated configuration. More documentation can be found from the official [CANU documentation](https://github.com/Cray-HPE/canu/blob/main/docs/network_configuration_and_upgrade/custom_config.md).

* (`ncn#`) Generate a CSM 1.3 configuration file for a single switch:

    ```bash
    canu generate switch config --csm 1.3 -a full --ccj system-ccj.json  --sls-file sls_file.json --name sw-spine-001
    ```

* (`ncn#`) Generate CSM 1.2 configuration files for a full system:

    ```bash
    canu generate network config --csm 1.2 -a full --ccj system-ccj.json  --sls-file sls_file.json --custom-config system-custom-config.yaml --folder generated
    ```
