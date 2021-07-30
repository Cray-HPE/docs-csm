## Image Management

The Image Management Service \(IMS\) uses the open source Kiwi-NG tool to build image roots from compressed Kiwi image descriptions. These compressed Kiwi image descriptions are referred to as "recipes." Kiwi-NG builds images based on a variety of different Linux distributions, specifically SUSE, RHEL, and their derivatives. Kiwi image descriptions must follow the Kiwi development schema. More information about the development schema and the Kiwi-NG tool can be found in the documentation: [https://doc.opensuse.org/projects/kiwi/doc/](https://doc.opensuse.org/projects/kiwi/doc/).

Even though Kiwi recipes can be developed from scratch or found on the Internet, Cray suggests that recipes are based on existing Cray image recipes. Cray provides multiple types of recipes including, but not limited to the following:

-   Barebones Image Recipes - The barebones recipes contain only the upstream Linux packages needed to successfully boot the image on a Cray compute node using upstream packages. Bare-bones recipes are primarily meant to be used to validate the Cray IMS tools, without requiring HPE Cray Operating System (COS) content.
-   COS Recipes - COS recipes contain a Linux environment with a Cray customized kernel and optimized Cray services for our most demanding customers and workloads.

Cray provided recipes are uploaded to the Simple Storage Service \(S3\) and registered with IMS as part of the install.

Images built by IMS contain only the packages and settings that are referenced in the Kiwi-NG recipe used to build the image. The only exception is that IMS will dynamically install the system's root CA certificate to allow zypper \(via Kiwi-NG\) to talk securely with the required Nexus RPM repositories. Images that are intended to be used to boot a CN or other node must be configured with DNS and other settings that enable the image to talk to vital services. A base level of customization is provided by the default Ansible plays used by the Configuration Framework Service \(CFS\) to enable DNS resolution, which are typically run against an image after it is built by IMS.

When customizing an image via IMS image customization, once chrooted into the image root \(or if using a \`jailed\` environment\), the image will only have access to whatever configuration the image already contains. In order to talk to services, including Nexus RPM repositories, the image root must first be configured with DNS and other settings. A base level of customization is provided by the default Ansible plays used by the CFS to enable DNS resolution.

The Nexus Repository Manager service provides local RPM repositories for use when building or customizing an image. The Kiwi image descriptions should reference these repositories as needed. In order to include the custom-repo repository in an IMS Kiwi-NG recipe, the repository source path should be modified to the URI for a repository instance hosted by Nexus.

```screen
<repository type="rpm-md" alias="custom-repo" imageinclude="true"> 
<source path="https://packages.local/repository/REPO_NAME" />
</repository>
```

### Table of Contents

* [Image Management Workflows](Image_Management_Workflows.md)
* [Upload and Register an Image Recipe](Upload_and_Register_an_Image_Recipe.md)
* [Build a New UAN Image Using the Default Recipe](Build_a_New_UAN_Image_Using_the_Default_Recipe.md)
* [Build an Image Using IMS REST Service](Build_an_Image_Using_IMS_REST_Service.md)
* [Customize an Image Root Using IMS](Customize_an_Image_Root_Using_IMS.md)
  * [Create UAN Boot Images](Create_UAN_Boot_Images.md)
  * [Convert TGZ Archives to SquashFS Images](Convert_TGZ_Archives_to_SquashFS_Images.md)
  * [Customize an Image Root to Install Singularity](Customize_an_Image_Root_to_Install_Singularity.md)
* [Delete or Recover Deleted IMS Content](Delete_or_Recover_Deleted_IMS_Content.md)
