# SAT in CSM

In CSM 1.3 and newer, the `sat` command is available on the Kubernetes NCNs without installing the
SAT product stream.

Starting in CSM 1.6.0, SAT is fully included in CSM. There is no longer a separate SAT product
stream to install. SAT 2.6 releases, which accompanied CSM 1.5, are the last releases of SAT as a
separate product.

## Differences from old SAT Product Stream

There are several notable differences between the separate 2.6 releases of SAT and the release of
SAT included in CSM 1.6.0. They are described below.

- There are no longer new entries for SAT added to the `cray-product-catalog` Kubernetes ConfigMap.
  When a system is upgraded from older versions of CSM and SAT, the existing entries for older
  separate versions of SAT are not removed from the `cray-product-catalog`.

- The `sat-install-utility` image is no longer provided. This container image provided uninstall and
  activate functionality when used with the `prodmgr` command. It is still possible to uninstall
  older versions of SAT that were installed as a separate product. However, it is not necessary to
  do so. Doing so will free up a small amount of space in Nexus and will remove old SAT entries from
  the `cray-product-catalog`.

- The `docs-sat` RPM is no longer provided. SAT documentation will be merged into CSM documentation.

- The `sat-config-management` repository in Gitea (VCS) is no longer used. All SAT configuration
  content has been added to the `csm-config-management` repository. It is no longer required to use
  a separate layer which references the `sat-config-management` repository in CFS configurations
  targeting the management nodes.

## Frequently Asked Questions (FAQ)

**Q: How can I tell which version of SAT is installed on a system?**

It is still possible to view the semantic version of the `sat` command that is installed and active
on the system by executing `sat --version`. This is the version of the `sat` command itself. It is
distinct from the versions of the SAT product stream.

(`ncn-m#`) For example:

```bash
sat --version
```

This will output a semantic version like the following:

```text
3.26.0
```

**Q: Which version of SAT takes precedence on a system with both CSM 1.6.0 and older versions of SAT installed?**

When CSM 1.6.0 is installed, it will override any version of SAT installed as a separate product
stream. For example, on a system being upgraded from CSM 1.5 and SAT 2.6 to CSM 1.6, the version of
SAT included in CSM 1.6 will take precedence.

**Q: How do I revert to use older versions of SAT on a CSM 1.6 system?**

Although it is uncommon to need to revert to using an older version of SAT, it is possible to do so
using environment variables. Specifically, the environment variable `SAT_IMAGE` can be set to the
name and tag of the `cray-sat` container image to use. The available image versions in the Nexus
registry can be inspected with `podman image search`.

For detailed instructions, see
[Downgrade: Switch Between SAT Versions](../SAT_Uninstall_and_Downgrade.md#downgrade-switch-between-sat-versions).
