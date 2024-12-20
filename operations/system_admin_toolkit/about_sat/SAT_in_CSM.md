# SAT in CSM

The `sat` command is available on the Kubernetes control plane nodes in CSM 1.3, 1.4, and 1.5
without installing the SAT product stream. Starting in CSM 1.6.0, SAT is fully included in CSM.
There is no longer a separate SAT product stream to install. SAT 2.6 releases, which accompanied
CSM 1.5, are the last releases of SAT as a separate product.

## Differences from Old SAT Product Stream

There are several notable differences between the separate 2.6 releases of SAT and the release of
SAT included in CSM 1.6. They are described below.

- There are no longer new entries for SAT added to the `cray-product-catalog` Kubernetes ConfigMap.

  When a system is upgraded from older versions of CSM and SAT, the existing entries for older,
  separate versions of SAT are not removed from the `cray-product-catalog`.

- The `sat-install-utility` image is no longer provided.

  This container image gave uninstall and activate functionality when used with the `prodmgr` command.
  It is still possible to uninstall older versions of SAT that were installed as a separate product.
  However, it is not necessary to do so. Doing so will free up a small amount of space in Nexus and
  remove old SAT entries from the `cray-product-catalog`.
  
  For more information, see [Uninstall: Remove a Version of SAT](../SAT_Uninstall_and_Downgrade.md#uninstall-remove-a-version-of-sat).

- The `docs-sat` RPM is no longer provided.

  The SAT documentation moved to be fully included within the
  [System Admin Toolkit (SAT) section](https://cray-hpe.github.io/docs-csm/en-16/operations/system_admin_toolkit/)
  of the [CSM Administration Guide](https://cray-hpe.github.io/docs-csm/en-16/operations/).

- The `sat-config-management` repository in Gitea (VCS) is no longer used.

  All SAT configuration content has been added to the `csm-config-management` repository. It is no
  longer required to use a separate layer which references the `sat-config-management` repository
  in CFS configurations targeting the management nodes.

## Frequently Asked Questions (FAQs)

**Question: How can I tell which version of SAT is installed on a system?**

It is still possible to view the semantic version of the `sat` command that is installed and
active on a system. The semantic version is distinct from versions of the SAT product stream.

(`ncn-m#`) To show the semantic version of the `sat` command itself:

```bash
sat --version
```

This command outputs the semantic version on the system:

```text
3.26.0
```

**Question: Which version of SAT takes precedence on a system with both CSM 1.6 and older versions of SAT installed?**

When CSM 1.6 is installed, it overrides any version of SAT installed as a separate product stream.
For example, on a system being upgraded from CSM 1.5 and SAT 2.6 to CSM 1.6, the version of SAT
included in CSM 1.6 takes precedence.

**Question: How do I revert to using older versions of SAT on a CSM 1.6 system?**

Although needing to revert to an older version of SAT is uncommon, it can be done using environment
variables. Specifically, set the environment variable `SAT_IMAGE` to the name and tag of the
`cray-sat` container image to use on the system. To review the available image versions in the Nexus
registry, use `podman image search`.

For more information, see
[Downgrade: Switch Between SAT Versions](../SAT_Uninstall_and_Downgrade.md#downgrade-switch-between-sat-versions).

**Question: Do SAT commands have any dependencies?**

Most `sat` subcommands depend on services or components from CSM or from other products in the
HPE Cray EX software stack.

For more information, see [SAT Dependencies](SAT_Dependencies.md).
