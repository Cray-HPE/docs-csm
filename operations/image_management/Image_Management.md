# Image Management

The Image Management Service \(IMS\) uses the open source Kiwi-NG tool to build image roots from compressed
Kiwi image descriptions. These compressed Kiwi image descriptions are referred to as "recipes." Kiwi-NG builds
images based on a variety of different Linux distributions, specifically SUSE, RHEL, and their derivatives.
Kiwi image descriptions must follow the Kiwi development schema. More information about the development schema
and the Kiwi-NG tool can be found in the documentation:
[https://doc.opensuse.org/projects/kiwi/doc/](https://doc.opensuse.org/projects/kiwi/doc/).

Even though Kiwi recipes can be developed from scratch or found on the Internet, it is recommended that recipes
are based on existing HPE Cray image recipes. HPE Cray provides multiple types of recipes including, but not limited
to the following:

* **Barebones Image Recipes**: The barebones recipes contain only the upstream Linux packages needed to successfully
boot the image on an HPE Cray compute node using upstream packages. Bare-bones recipes are primarily meant to be used
to validate the IMS tools, without requiring HPE Cray Operating System (COS) content.
* **COS Recipes**: COS recipes contain a Linux environment with an HPE Cray customized kernel and optimized HPE Cray
services for our most demanding customers and workloads.

HPE Cray provided recipes are uploaded to the Simple Storage Service \(S3\) and registered with IMS as part of the install.

Images built by IMS contain only the packages and settings that are referenced in the Kiwi-NG recipe used to build the image.
The only exception is that IMS will dynamically install the system's root CA certificate to allow zypper \(via Kiwi-NG\) to
talk securely with the required Nexus RPM repositories. Images that are intended to be used to boot a CN or other node must
be configured with DNS and other settings that enable the image to talk to vital services. A base level of customization is
provided by the default Ansible plays used by the Configuration Framework Service \(CFS\) to enable DNS resolution, which are
typically run against an image after it is built by IMS.

When customizing an image via IMS image customization, once chrooted into the image root \(or if using a \`jailed\` environment\),
the image will only have access to whatever configuration the image already contains. In order to talk to services, including
Nexus RPM repositories, the image root must first be configured with DNS and other settings. A base level of customization is
provided by the default Ansible plays used by the CFS to enable DNS resolution.

The Nexus Repository Manager service provides local RPM repositories for use when building or customizing an image. The Kiwi
image descriptions should reference these repositories as needed. In order to include the custom-repo repository in an
IMS Kiwi-NG recipe, the repository source path should be modified to the URI for a repository instance hosted by Nexus.

```screen
<repository type="rpm-md" alias="custom-repo" imageinclude="true">
<source path="https://packages.local/repository/REPO_NAME" />
</repository>
```

IMS has the ability to create and customize aarch64 images even though the management nodes are running on x86 hardware. This
is done through hardware emulation so be aware that it will be quite a bit slower than the same operations being done on an
x86 image. For more information see [Working With aarch64 Images](Working_With_aarch64_Images.md).
