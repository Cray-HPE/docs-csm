# System Admin Toolkit (SAT) in CSM

The System Admin Toolkit (SAT) is a command-line interface that can assist administrators with common tasks, such as
troubleshooting and querying information about the HPE Cray EX System, system boot and shutdown, and replacing hardware
components. In CSM 1.3 and newer, the `sat` command is available on the Kubernetes NCNs without installing the SAT
product stream.

## SAT product stream components

It is still possible to install SAT as a separate product stream. Any version of SAT installed as a separate product
stream overrides the `sat` command available in CSM. Installing the SAT product stream allows additional supporting
components to be added:

- An entry for SAT in the `cray-product-catalog` Kubernetes ConfigMap is only created by installing the SAT product
  stream. Otherwise, there will be no entry for this version of SAT in the output of `sat showrev`.

- The `sat-install-utility` container image is only available with the full SAT product stream. This container image
  provides uninstall and activate functionality when used with the `prodmgr` command. (In SAT 2.3 and older, SAT was
  only available to install as a separate product stream. Because these versions were packaged with
  `sat-install-utility`, it is still possible to uninstall these versions of SAT.)

- The `docs-sat` RPM package is only available with the full SAT product stream. You can find SAT documentation at
  the links below (see [SAT documentation](#sat-documentation)).

- The `sat-config-management` git repository in Gitea (VCS) and thus the SAT layer of NCN CFS configuration is
  only available with the full SAT product stream.

If the SAT product stream is not installed, there will be no configuration content for SAT in VCS. Therefore, CFS
configurations that apply to NCNs should not include a SAT layer.

The SAT configuration layer modifies the permissions of files left over from prior installations of SAT, so that the
Keycloak username that authenticates to the API gateway cannot be read by users other than `root`. Specifically, it
it does the following:

- Modifies the `sat.toml` configuration file which contains the username so that it is only readable by `root`.

- Modifies the `/root/.config/sat/tokens` directory so that the directory is only readable by `root`. This is needed
  because the names of the files within the `tokens` directory contain the username.

Regardless of the SAT configuration being applied, passwords and the contents of the tokens are never readable by other
users. These permission changes only apply to files created by previous installations of SAT. In the current version of
SAT, all files and directories are created with the appropriate permissions.

## SAT documentation

For full SAT documentation, refer to the [*HPE Cray EX System Admin Toolkit (SAT) Guide*](https://cray-hpe.github.io/docs-sat/).

If SAT has not been installed before, some initial configuration is required (for example, authenticating to the API
gateway with `sat auth`). To complete the initial configuration of SAT, refer to the following post-installation procedures in the SAT documentation:

- **Authenticate SAT Commands**
- **Generate SAT S3 Credentials**
- **Set System Revision Information**

If the full SAT product stream is not being installed, it is recommended that you uninstall old versions of the
SAT product stream to avoid confusion in the output of `sat showrev`. For more information,
refer to **SAT Uninstall and Downgrade** in the SAT documentation.
