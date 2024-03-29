# Barebones Image Boot Test

The CSM barebones image boot test verifies that the CSM services needed to boot a node are available and working properly.
This test is **very important to run**, particularly during the CSM install prior to rebooting the
[PIT](../glossary.md#pre-install-toolkit-pit) node, because it validates all of the services required for nodes to
PXE boot from the cluster.

This page gives some information about the CSM barebones image and describes how the test script works.

* [Notes on the CSM barebones images](#notes-on-the-csm-barebones-images)
  * [Compute barebones images](#compute-barebones-images)
  * [Minimal barebones image](#minimal-barebones-image)
* [Test prerequisites](#test-prerequisites)
* [Test overview](#test-overview)
* [Test options](#test-options)
  * [Controlling which node is used](#controlling-which-node-is-used)
  * [Controlling which image is used](#controlling-which-image-is-used)
  * [Controlling how the image is customized](#controlling-how-the-image-is-customized)
  * [Controlling which product catalog entry is used](#controlling-which-product-catalog-entry-is-used)
  * [Controlling which architecture is used](#controlling-which-architecture-is-used)
  * [Controlling test script output level](#controlling-test-script-output-level)
  * [Preventing resource deletion](#preventing-resource-deletion)

## Notes on the CSM barebones images

Every CSM release includes a few different pre-build barebones node images.
They are listed in the Cray Product Catalog entry for that CSM release.

(`ncn-mw#`) To view all of the CSM release entries in the Cray Product Catalog, run the following command.

```bash
kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
```

Here is an example of what the images stanza looks like for a CSM release entry in the Cray Product Catalog.

```yaml
  images:
    compute-csm-1.5-5.2.52-aarch64:
      id: a836494a-0a50-4e26-96de-db8b4b9f75f2
    compute-csm-1.5-5.2.52-x86_64:
      id: 66eb3319-c0fb-4086-9b62-71347ccb6b8d
    cray-shasta-csm-sles15sp5-barebones-csm-1.5:
      id: a6d0611b-1993-4ecb-93dc-e49888ca1844
    secure-kubernetes-5.2.52-x86_64.squashfs:
      id: fcbaf6a2-3c82-4532-97da-efee21e8d861
    secure-storage-ceph-5.2.52-x86_64.squashfs:
      id: 2a1b5a95-7f15-4d74-847b-eeb46200bf3b
```

* [Compute barebones images](#compute-barebones-images)
* [Minimal barebones image](#minimal-barebones-image)

### Compute barebones images

In the example Cray Product Catalog output above, the two compute barebones images are
`compute-csm-1.5-5.2.52-aarch64` (ARM architecture) and `compute-csm-1.5-5.2.52-x86_64` (x86 architecture).
These images include everything necessary to fully boot a compute node to a login prompt. However,
[Boot Orchestration Service (BOS)](../glossary.md#boot-orchestration-service-bos) sessions used to boot them
**will never report success**. This is because they do not have the necessary credentials built-in to allow the
BOS state reporter to notify BOS of the successful boot.
These credentials can be added by customizing the image using the
[Configuration Framework Service (CFS)](../glossary.md#configuration-framework-service-cfs)
(the `compute_nodes.yaml` playbook from the CSM
[Version Control Service (VCS)](../glossary.md#version-control-service-vcs) repository will work for this).

### Minimal barebones image

In the example Cray Product Catalog output above, `cray-shasta-csm-sles15sp5-barebones-csm-1.5` is
the minimal barebones image.

This image contains only the minimal set of RPMs and configuration required to boot a compute node, and is not
suitable for production usage. To run production work loads, it is suggested that an image from the
[Cray Operating System (COS)](../glossary.md#cray-operating-system-cos) product, or similar, be used.

Unlike the [compute barebones images](#compute-barebones-images),
this image **will not successfully complete a boot** beyond the `dracut` stage of the boot process.
However, if the `dracut` stage is reached, then the boot can be considered successful, because this
demonstrates that the necessary CSM services needed to boot a node are up and available.

In addition to the minimal barebones image, the CSM release also includes an
[Image Management Service (IMS)](../glossary.md#image-management-service-ims) recipe that
can be used to build the CSM barebones image. However, the CSM barebones recipe currently requires
RPMs that are not installed with the CSM product. The CSM barebones recipe can be built after the
COS product stream is installed on the system.

## Test prerequisites

* This test can be run on any master or worker [NCN](../glossary.md#non-compute-node-ncn), but not the PIT node.
* The test script uses the Kubernetes API gateway to access CSM services. The gateway must be properly configured to allow an access token to be generated by the script.
* The test script is installed as part of the `cray-cmstools-crayctldeploy` RPM.

## Test overview

The script file location is `/opt/cray/tests/integration/csm/barebones_image_test`.
Review the [Test prerequisites](#test-prerequisites) before proceeding.

If no parameters are specified, this script does the following steps:

1. Obtain the Kubernetes API gateway access token.
1. Reads the CSM entries in the Cray Product Catalog and finds the entry for the most
   recent CSM version. From this entry, it gets the following information:

   * The IMS ID of the x86 [compute barebones image](#compute-barebones-images)
   * The `clone_url` and `commit` from the `configuration` stanza.

1. Queries [Hardware State Manager (HSM)](../glossary.md#hardware-state-manager-hsm) to find an enabled x86 compute node.
1. Creates a single-layer CFS configuration to run the `compute_nodes.yml` playbook,
   using the Git commit and clone URL found earlier.
1. Creates a CFS session to customize the barebones image using the new CFS configuration.
   Waits for the session to complete successfully.
1. Creates a BOS session template to boot the resulting customized IMS image.
1. Creates a BOS session to restart the chosen compute note using the new BOS session template.
   Waits for the session to complete successfully.
1. If the test passed, it deletes the resources it created during execution (CFS configuration,
   CFS session, customized IMS image, BOS session template, and BOS session).

The script provides output along the way to report progress, and also provides a link to a log
file with more detailed information. If the test fails, the place to begin the investigation is
whatever service was being used at the time of the failure.

The image customization step may take up to 10 or 15 minutes, as may the boot step.

## Test options

(`ncn-mw#`) The script usage message can be displayed by running it with the `--help` argument.

```bash
/opt/cray/tests/integration/csm/barebones_image_test --help
```

The following sections cover some of the most commonly used options.

* [Controlling which node is used](#controlling-which-node-is-used)
* [Controlling which image is used](#controlling-which-image-is-used)
* [Controlling how the image is customized](#controlling-how-the-image-is-customized)
* [Controlling which product catalog entry is used](#controlling-which-product-catalog-entry-is-used)
* [Controlling which architecture is used](#controlling-which-architecture-is-used)
* [Controlling test script output level](#controlling-test-script-output-level)
* [Preventing resource deletion](#preventing-resource-deletion)

### Controlling which node is used

By default, the script will list all enabled x86 compute nodes in HSM and use the first one
as the target for the test. This may be overridden by using the `--xname` command line argument
to specify the component name (xname) of the target compute node. The target
compute node must be enabled and present in HSM.

If an ARM node is specified, then the test will choose the ARM
[compute barebones image](#compute-barebones-images) from the product catalog.

When specifying a node, the test can fail if:

* The specified node is not found in HSM
* The specified node is not enabled in HSM
* The specified node is not marked as a compute node in HSM
* An image with non-matching architecture has also been specified

(`ncn-mw#`) An example of specifying the target node:

```bash
/opt/cray/tests/integration/csm/barebones_image_test --xname x3000c0s10b1n0
```

> Troubleshooting: If any compute nodes are missing from HSM database, then refer to
> [2.2.2 Known issues with HSM discovery validation](../operations/validate_csm_health.md#222-known-issues-with-hsm-discovery-validation)
> in order to troubleshoot any node BMCs that have not been discovered.

### Controlling which image is used

By default, the script will customize the [compute barebones image](#compute-barebones-images) from
the product catalog.

The `--base-id` argument can be used to specify a different IMS image to be customized.
Or the customization can be skipped entirely by specifying an image with the `--id` argument.
In either case, the image is specified using its IMS ID.

When specifying an image, the test can fail if:

* The specified image is not found in IMS
* The specified IMS image does not have a linked S3 artifact
* No compute node can be found with an architecture that matches the specified image
* A node with non-matching architecture has also been specified

(`ncn-mw#`) An example of specifying the image for the test:

```bash
/opt/cray/tests/integration/csm/barebones_image_test --id 0eacdcaa-74ad-40d6-b2b3-801f244ef868
```

(`ncn-mw#`) Available IMS images on the system can be listed using the Cray Command Line Interface (CLI)
with the following command:

```bash
cray ims images list --format json
```

For help configuring the Cray CLI, see [Configure the Cray CLI](../operations/configure_cray_cli.md).

Another way to change which image is used is to specify a different CSM version to use in the product catalog.
See [Controlling which product catalog entry is used](#controlling-which-product-catalog-entry-is-used).

### Controlling how the image is customized

By default, the script creates a CFS configuration to customize the image, using the Git
commit and clone URL from the latest CSM version in the product catalog.
This can be altered in a few different ways.

* A pre-existing CFS configuration can be used by specified its name with the `--cfs-config` argument.
* A Git commit can be specified with the `--git-commit` argument.
* A clone URL can be specified with the `--vcs-url` argument.
* An Ansible playbook (to override the default `compute_nodes.yml`) can be specified with the `--playbook` argument.
* A different CSM version in the product catalog can be specified.
  See [Controlling which product catalog entry is used](#controlling-which-product-catalog-entry-is-used).

### Controlling which product catalog entry is used

By default the test will get information from the latest CSM version in the product catalog.
A different CSM version in the product catalog can be used by specifying the alternate version
using the `--csm-version` argument.

### Controlling which architecture is used

If an image or node is specified to the test, then those will be used to determine the architecture for the test.
If neither is specified, then the test default to x86 architecture. However, the test can be run using its default
behavior but on ARM architecture instead by specifying `--arch arm`. In this case, it will follow the default
procedure (documented in [Test overview](#test-overview)), except for ARM architecture.

### Controlling test script output level

Output is directed to both the console calling the script as well as a log file that will hold
more detailed information on the run and any potential problems found. The log file is written
to `/tmp/cray.barebones-boot-test.log` and will overwrite any existing file at that location on
each new run of the script.

The messages output to the console and the log file may be controlled separately through
environment variables. To control the information being sent to the console, set the variable
`CONSOLE_LOG_LEVEL`. To control the information being sent to the log file, set the variable
`FILE_LOG_LEVEL`. Valid values in increasing levels of detail are: `CRITICAL`, `ERROR`,
`WARNING`, `INFO`, `DEBUG`. The default for the console output is `INFO` and the default for
the log file is `DEBUG`.

(`ncn-mw#`) Here is an example of running the script with more information displayed on the console
during the execution of the test:

```bash
CONSOLE_LOG_LEVEL=DEBUG /opt/cray/tests/integration/csm/barebones_image_test
```

### Preventing resource deletion

By default, when the test passes, it deletes all of the resources that it created during its execution.
This behavior can be overridden by specifying the `--no-cleanup` argument. In that case,
it will never delete the resources that it creates.
