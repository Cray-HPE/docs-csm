# Build NCN Images Locally

Build and test NCN images locally by using the following procedure. This procedure can be done on any x86 machine with the following prerequisites.

## Necessary Software

The listed software below will equip a local machine or build server to build for any medium (`.squashfs`, `.vbox`, `.qcow2`, `.iso`).

* media (`.iso`, `.ovf`, or `.qcow2`) (depending on the layer)
* `packer`
* `qemu`
* `envsubst`

## Media

Packer can intake any ISO, the sections below detail utilized base ISOs in CRAY HPCaaS.

For any ISO, copy it into the `iso` directory.

### SuSE Linux Enterprise

The file name is either:

* `SLE-15-SP2-Full-x86_64-GM-Media1.iso`
* `SLE-15-SP3-Full-x86_64-GM-Media1.iso`

## Repositories

You will need access to the appropriate SLES repositories in the form of official access, self-hosted access, or the provided Nexus access.

To build locally you will need to provide your own repositories file and the `custom_repos_file` variable must be passed with the packer command.
The `custom_repos_file` variable is a filename that is placed into the `custom` folder of the project.
The file must be formatted with the following fields: `url name flags`

* `-var 'custom_repos_file=custom.repos'`

And example entry for a custom repo:

`https://myserver.net/sles-mirror/Products/SLE-Module-Basesystem/15-SP3/x86_64/product     SUSE-SLE-Module-Basesystem-15-SP3-x86_64-Pool     -g -p 99  suse/SLE-Module-Basesystem/15-SP3/x86_64/product`

## Build Steps

* There are two Providers that can be built; VirtualBox and QEMU
* VirtualBox is best for local development.
* QEMU is best for pipeline and portability on Linux machines.
* Both outputs are capable of creating the Kernel, Initrd, and SquashFS required to boot nodes.

### Setup

* Install packer from a reputable endpoint, like [this one](https://www.packer.io/downloads.html).

If you are building QEMU images in MacOS, you will need to adjust specific QEMU options:

* MacOS requires HVF for acceleration
* MacOS uses Cocoa for output
* `-var 'qemu_display=cocoa' -var 'qemu_accelerator=hvf'`

#### Notes

* Setup environment variables by copying `scripts/environment.template` to `scripts/environment` and modifying the values for your environment.
* Ensure that `SLE-15-SP3-Full-x86_64-GM-Media1.iso` is in the `iso/` folder
* Check out `csm-rpms` repository and create a symlink to it in the root directory of the project.
* Execute `source scripts/environment`
* Execute `./scripts/setup.sh`
* Render the `autoinst` template

### Quick Start

```bash
git clone <csm-rpms-repo>
git clone https://github.com/Cray-HPE/node-image-build.git
cd node-image-build
ln -s ../csm-rpms/ csm-rpms
cp scripts/environment.template scripts/environment
vim scripts/environment
source scripts/environment
mkdir -p iso
wget https://<somepath>/SLE-15-SP3-Full-x86_64-GM-Media1.iso -O iso/SLE-15-SP3-Full-x86_64-GM-Media1.iso
./scripts/setup.sh
```

### Base Layer

The base layer will install SLES 15 and prepare the image for the installation of Kubernetes and Ceph.

Execute the following commands from the top level of the project

To build with QEMU, run the following command.

* Run `packer build -only=qemu.sles15-base -var 'ssh_password=$SLES15_INITIAL_ROOT_PASSWORD' boxes/sles15-base/`

To build with VirtualBox, run the following command.

* Run `packer build -only=virtualbox-iso.sles15-base -var 'ssh_password=$SLES15_INITIAL_ROOT_PASSWORD' boxes/sles15-base/`

If you want to view the output of the build, disable `headless` mode:

* Run `packer build -var 'ssh_password=$SLES15_INITIAL_ROOT_PASSWORD' -var 'headless=false' boxes/sles15-base/`

Once the images are built, the output will be placed in the `output-sles15-base` directory in the root of the project.

### Common Layer

The common layer starts from the output of the base layer. As such the base layer must be created before building common.

To build with QEMU, run the following command.

* Run `packer build -only=qemu.ncn-common -var 'ssh_password=$SLES15_INITIAL_ROOT_PASSWORD' boxes/ncn-common/`

To build with VirtualBox, run the following command.

* Run `packer build -only=virtualbox-ovf.ncn-common -var 'ssh_password=$SLES15_INITIAL_ROOT_PASSWORD' boxes/ncn-common/`

Once the image is built, the output will be placed in the `output-ncn-common` directory in the root of the project.

### Non-Compute Node Image Layer

The `ncn-node-images` stage builds on top of the common layer to create functional images for Kubernetes and Ceph.

To build with QEMU, run the following command.

* Run `packer build -only=qemu.* -var 'ssh_password=$SLES15_INITIAL_ROOT_PASSWORD' boxes/ncn-node-images/`

To build with VirtualBox, run the following command.

* Run `packer build -only=virtualbox-ovf.* -var 'ssh_password=$SLES15_INITIAL_ROOT_PASSWORD' boxes/ncn-node-images/`

Once the images are built, the output will be placed in the `output-sles15-images` directory in the root of the project.

## Artifacts

Each layer creates a certain set of artifacts that can be used in different ways.

* Each layer creates a VM disk image that can be directly booted and/or used to create the next layer's image.
* Each layer after `sles15-base` creates a list of packages and repos.
* `ncn-common` creates kernel and initrd artifacts.
* `ncn-node-images` creates Kernel, Initrd, and SquashFS artifacts.

## Versioning

* The version of the build is passed with the `packer build` command as the `artifact_version` var:

```bash
packer build -only=qemu.sles15-base -var "artifact_version=`git rev-parse --short HEAD`" -var 'ssh_password=$SLES15_INITIAL_ROOT_PASSWORD' -var 'headless=false' boxes/sles15-base/
````

* If no version is passed to the builder then the version `none` is used when generating the archive.
