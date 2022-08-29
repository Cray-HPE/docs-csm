# System Admin Toolkit (SAT) in CSM

The System Admin Toolkit (SAT) is a command-line interface that can assist administrators with common tasks, such as
troubleshooting and querying information about the HPE Cray EX System, system boot and shutdown, and replacing hardware
components. In CSM 1.3 and newer, the `sat` command is available on the Kubernetes NCNs without installing the SAT
product stream.

## SAT product stream components

It is still possible to install SAT as a separate product stream. Installing the SAT product stream results in
additional supporting components being installed.

- Installing the SAT product stream creates an entry for SAT in the `cray-product-catalog` Kubernetes ConfigMap.
  Without installing the SAT product stream, there will be no entry for this version of SAT in the output of
  `sat showrev`.

- The `sat-install-utility` container image is only available with the full SAT product stream. This container image
  provides uninstall and activate functionality when used with the `prodmgr` command. It is still possible to uninstall
  previous versions of the SAT product stream.

- The `sat-config-management` git repository in Gitea (VCS) and thus the SAT layer of NCN CFS configuration is
  only available with the full SAT product stream. See [SAT CFS configuration details](#sat-cfs-configuration-details)
  below.

- The `docs-sat` RPM package is only available with the full SAT product stream. SAT documentation can be found
  at the links below (see: [SAT documentation](#sat-documentation)).

### SAT CFS configuration details

When the SAT product stream has not been installed, there will be no configuration content for SAT in VCS. Therefore,
CFS configurations that apply to NCNs (for example, `ncn-personalization`) should not include a SAT layer.

This configuration layer modifies the permissions of files left over from prior installs of SAT, so that the Keycloak
username used to authenticate to the API gateway cannot be read by users other than `root`. Specifically, it does the
following:

- Modify the `sat.toml` configuration file which contains the username so that it is only readable by `root`.

- Modify the `/root/.config/sat/tokens` directory so that the directory is only readable by `root`, because the
  names of the files within the `tokens` directory contain the username.

Regardless of this configuration being applied, the contents of the tokens are never readable by other users, nor are
any passwords. These permission changes only apply to files created by previous installs of SAT; in the current version
of SAT all files and directories are created with the appropriate permissions.

## SAT documentation

For full SAT documentation, see the [SAT Documentation](https://cray-hpe.github.io/docs-sat/en-24).

If SAT has not been installed before, then some initial configuration is required; for example to authenticate to the
API gateway with `sat auth`.

- [SAT Authentication](https://cray-hpe.github.io/docs-sat/en-24/install/#sat-authentication)
- [Generate SAT S3 Credentials](https://cray-hpe.github.io/docs-sat/en-24/install/#generate-sat-s3-credentials)
- [Set System Revision Information](https://cray-hpe.github.io/docs-sat/en-24/install/#set-system-revision-information)

If the full SAT product stream is not being installed, then it may be wise to uninstall old versions of the SAT product
stream to avoid confusion in the output of `sat showrev`.

- [Uninstall: Removing a Version of SAT](https://cray-hpe.github.io/docs-sat/en-24/install/#uninstall-removing-a-version-of-sat)
