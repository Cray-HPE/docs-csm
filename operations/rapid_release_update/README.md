# Rapid Release Update (RRU) for CSM kernel CVE fixes

* [Overview](#overview)
* [Terminology](#terminology)
* [Release Notes](#release-notes)
* [Valid upgrade paths](#valid-update-paths)
* [Update NCNs with Rapid Release Update](#update-ncns-with-rapid-release-update)
* [Further Reading](#further-reading)

## Overview

A Rapid Release Update (RRU) for kernel CVE fixes is a separately versioned add-on product called `csm-security` that delivers approved security
content for a specific CSM base release and its corresponding SLE version. It does not upgrade the installed CSM release. RRU updates the NCN with
SUSE kernel security (CVE) fixes by adding a new CFS layer and rebuilding the images (Kubernetes and Storage). The NCNs are then rebooted with the new image.

## Terminology

| Term | Meaning |
| --- | --- |
| CVE | Common Vulnerabilities and Exposures — (e.g. `CVE-2025-26465`). A CVE is looked up at [SUSE URL](https://www.suse.com/security/cve/CVE-2025-26465.html) to find the severity, the SUSE advisory, and the fixed RPM versions. |
| CSM base version | The installed CSM release that the RRU is built and qualified for. The RRU does not change this version. |
| RRU version | The independent version of the `csm-security` product, for example `csm-security-1.2.3`. |
| SLE version | The SUSE Linux Enterprise release/service pack used by the target NCN images and specified by the RRU. |
| IUF | Install and Upgrade Framework; delivers the product and coordinates configuration, image preparation, and rollout stages. |
| CFS | Configuration Framework Service; applies configuration layers when preparing or configuring node images. |
| NCN | Non-Compute Node, including management, worker, and storage nodes in the CSM management system. |
| Bootprep | The YAML input defining image configurations and their ordered CFS layers. |
| CFS layer | A configuration/playbook unit applied to an image. The `csm-security` layer applies the RRU's security content. |
| Kernel version | The SUSE kernel the NCN runs (e.g. kernel-default=6.4.0-150600.23.50.1). A security fix usually means moving to a kernel NVR that contains the patch. The 150600 / 150700 encoding identifies the SLE service pack (SP6 / SP7). |

## Release notes

[`Rapid-Update-sle15-sp6-170-26.07.01` Release Notes](RRU_26.07.01_170_releasenotes.md)

[`Rapid-Update-sle15-sp6-170-26.10.01` Release Notes](RRU_26.10.01_170_releasenotes.md)

[`Rapid-Update-sle15-sp7-171-26.07.01` Release Notes](RRU_26.07.01_171_releasenotes.md)

[`Rapid-Update-sle15-sp7-171-26.09.01` Release Notes](RRU_26.09.01_171_releasenotes.md)

## Valid update paths

The below table gives mapping between CSM version and the latest Rapid Release Update version along with the SLES kernel version getting updated.
Use only an RRU whose release information explicitly matches the installed CSM and SLE versions.

| Installed CSM base version | Base SLE version | RRU version | Kernel version |
| --- | --- | --- | --- |
| 1.6.2 | SLE SP6 | `Rapid-Update-sle15-sp6-162-26.10.01` | 6.4.0-150600.23.135.1 |
| 1.7.0 | SLE SP6 | `Rapid-Update-sle15-sp6-170-26.10.01` | 6.4.0-150600.23.138.1 |
| 1.7.1 | SLE SP7 | `Rapid-Update-sle15-sp7-171-26.09.01` | 6.4.0-150700.53.78.1 |

> **Note:** RRU Version mentioned above is the latest released version. Previous versions can be found in the [Release Notes](#release-notes).

## Update NCNs with Rapid Release Update

1. For updating NCNs with RRU, see [Deploying Rapid Release Update with IUF](installation_iuf.md).
2. For troubleshooting common failures, see [Troubleshooting Guide](troubleshooting.md).

## Further Reading

For comprehensive IUF documentation including advanced workflows, stage details,
and troubleshooting, refer to the official CSM documentation for your installed
CSM version:

* **Online:** <https://cray-hpe.github.io/docs-csm/en-17/operations/iuf/iuf/>
* **On-system:** If the `docs-csm` RPM matching your CSM version is installed,
  IUF documentation is available locally at `/usr/share/doc/csm/operations/iuf/`

Install or update the docs RPM:

```bash
zypper install -y docs-csm
```

> **Note:** IUF behavior and available stages may differ between CSM versions. Always reference the documentation that matches your installed CSM release.
