# Non-Compute Nodes

This page gives a high-level overview of the environment present on the non-compute nodes (NCNs).

* [Pre-Install Toolkit](#pre-install-toolkit)
* [Certificate authority](#certificate-authority)
* [Hardware](#hardware)
  * [Firmware](#firmware)
  * [BIOS](#bios)
* [Boot workflow](#boot-workflow)
* [Mounts and filesystem](#mounts-and-filesystem)
* [Networking](#networking)
* [Operating system](#operating-system)
  * [Kernel](#kernel)
  * [Kernel dumps](#kernel-dumps)
  * [Kubernetes](#kubernetes)
  * [Python](#python)
  * [Images](#images)

## Pre-Install Toolkit

The Pre-Install Toolkit (PIT) is a framework for deploying NCNs from an "NCN-like" environment.
The PIT can be used for:

* bare-metal discovery and deployment
* fresh installations and reinstallation of Cray System Management (CSM)
* recovery of one or more NCNs

## Certificate authority

For information pertaining to the NCN certificate authority (CA), see [Certificate Authority](certificate_authority.md).

## Hardware

The hardware requirements are flexible, and outlined in the [NCN Plan of Record](ncn_plan_of_record.md) page.

### Firmware

For information about firmware, such as minimum firmware requirements, see [NCN Firmware](ncn_firmware.md).

### BIOS

BIOS setting information can be found in [NCN BIOS](ncn_bios.md).

## Boot workflow

Boot workflow information can be found in [NCN Boot Workflow](ncn_boot_workflow.md).

## Mounts and filesystem

Mount and filesystem information can be found in [NCN Mounts and Filesystems](ncn_mounts_and_filesystems.md)

## Networking

Networking information can be found in [NCN Networking](ncn_networking.md).

## Operating system

A general overview of the operating system for the non-compute nodes is given in [NCN Operating System Releases](ncn_operating_system_releases.md).

### Kernel

Information about the kernel, such as its version and parameters, can be found in [NCN Kernel](ncn_kernel.md).

### Kernel dumps

Information about kernel dumps can be found in [Kernel Dumps](ncn_kdump.md).

### Kubernetes

Kubernetes is installed on all management NCNs with some variation.

* `kubeadm` and `kubelet` are only installed on Kubernetes nodes
* `kubectl` is installed on all NCNs (Kubernetes and Ceph storage), as well as the PIT

### Python

The NCN and PIT come with multiple versions of Python.

* The default Python version provided by SUSE (e.g. `python3-base`)
* The new/upcoming Python version provided by SUSE's (e.g. `python3X-base` where `X` is the latest version offered)

The defined versions are as follows (this list will update as the NCN adopts/replaces new versions):

* Python 3.6.15 (`/usr/bin/python3`)
* Python 3.10.8 (`/usr/local/bin/python3`)

Each Python installation contains these packages (at a minimum) for building and/or running virtual environments:

```text
build
pip
setuptools
virtualenv
wheel
```

### Images

Information about the images used for NCNs can be found in [NCN Images](ncn_images.md).
