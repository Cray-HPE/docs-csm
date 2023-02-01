# Non-Compute Nodes

This page gives a high-level overview of the environment present on the Non-Compute Nodes (NCNs).

## Topics

* [Pre-Install Toolkit](#pre-install-toolkit)
* [Certificate Authority](#certificate-authority)
* [Hardware Requirements](#hardware-requirements)
  * [Firmware](#firmware)
* [Operating System](#operating-system)
  * [Kernel](#kernel)
  * [Kernel Dumps](#kernel-dumps)
  * [Kubernetes](#kubernetes)
  * [Python](#python)

## Pre-Install Toolkit

The Pre-Install Toolkit (PIT) is a framework for deploying NCNs from an "NCN-like" environment. The PIT can
be used for:

* bare-metal discovery and deployment
* fresh installations and reinstallation of Cray System Management (CSM)
* recovery of one or more NCNs

## Certificate Authority

For information pertaining to the non-compute node certificate authority (CA), see [certificate authority](certificate_authority.md).

## Hardware Requirements

The hardware requirements are flexible, and outlined in the [NCN plan of record](ncn_plan_of_record.md) page.

### Firmware

For information about firmware, such as minimum firmware requirements, see [firmware](./ncn_firmware.md).

### BIOS

BIOS setting information can be found in [NCN BIOS](ncn_bios.md).

### BOOT Workflow

Boot workflow information can be found in [NCN Boot Workflow](ncn_boot_workflow.md).

### Mounts and Filesystem

Mount and filesystem information can be found in [NCN Mounts and Filesystems](ncn_mounts_and_filesystems.md)

### Networking

Networking information can be found in [NCN Networking](ncn_networking.md).

## Operating System

A general overview of the operating system for the non-compute nodes is given in [NCN Operating System Releases](ncn_operating_system_releases.md).

### Kernel

Information about the kernel, such as its version and parameters, can be found in [`kernel`](./ncn_kernel.md).

### Kernel Dumps

Information about kernel dumps can be found in [`kdump`](./ncn_kdump.md).

### Kubernetes

Kubernetes is installed on all non-compute nodes with some variation.

* `kubeadm` is only installed on Kubernetes nodes
* `kubectl` is installed on all non-compute nodes (`kubernetes` and `storage-ceph`), as well as the pre-install toolkit
* `kubelet` is only installed on Kubernetes nodes

### Python

The non-compute node and pre-install toolkit come with multiple versions of Python.

* The default Python version provided by SUSE (e.g. `python3-base`)
* The new/upcoming Python version provided by SUSE's (e.g. `python3X-base` where `X` is the latest version offered)

The defined versions are as follows (this list will update as the non-compute node adopts/replaces new versions):

* Python 3.6.15 (`/usr/bin/python3`)
* Python 3.10.8 (`/usr/local/bin/python3`)

Each Python installation contains these packages (at a minimum) for building and/or running virtual environments:

```bash
build
pip
setuptools
virtualenv
wheel
```
