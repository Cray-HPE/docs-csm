# Cray System Management Documentation

## Scope and Audience

The documentation included here describes the Cray System Management (CSM) software, how to install
or upgrade CSM software, and related supporting operational procedures to manage an HPE Cray EX system.
CSM software is the foundation upon which other software product streams for the HPE Cray EX system depend.

The CSM installation prepares and deploys a distributed system across a group of management
nodes organized into a Kubernetes cluster which uses Ceph for utility storage. These nodes
perform their function as Kubernetes master nodes, Kubernetes worker nodes, or utility storage
nodes with the Ceph storage.

System services on these nodes are provided as containerized micro-services packaged for deployment
as helm charts. These services are orchestrated by Kubernetes to be scheduled on Kubernetes worker
nodes with horizontal scaling to increase or decrease the number of instances of some services as
demand for them varies, such as when booting many compute nodes or application nodes.

This information is intended for system installers, system administrators, and network administrators
of the system. It assumes some familiarity with standard Linux and open source tools, such as shell
scripts, revision control with git, configuration management with Ansible, YAML, JSON, and TOML file formats, etc.

## Table of Contents

1. [Introduction to CSM Installation](introduction/index.md)

   This chapter provides an introduction to using the CSM software to manage the HPE Cray EX system which
   also describes the scenarios for installation and upgrade of CSM software, how product stream updates
   for CSM are delivered, the operational activities done after installation for on-going management
   of the HPE Cray EX system, differences between previous release and this release, and conventions
   used in this documentation.

1. [Update CSM Product Stream](update_product_stream/index.md)

   This chapter explains how to get the CSM product release, any patches, update to the latest set of
   documenation and any installation workarounds, and check for any Field Notices or Hotfixes.


1. [Install CSM](install/index.md)

   This chapter provides an order list of procedures which can be used for CSM software installation or reinstall
   that indicate when to do operational tasks as part of the installation workflow. Updating software is in another chapter.
   Installation of the CSM product stream has many steps in multiple procedures which should be done in a
   specific order. Information about the HPE Cray EX system and the site is used to prepare the configuration
   payload. The initial node used to bootstrap the installation process is called the PIT node because the
   Pre-Install Toolkit is installed there. Once the management network switches have been configured, the other
   management nodes can be deployed with an operating system and the software to create a Kubernetes cluster
   utilizing Ceph storage. The CSM services provide essential software infrastructure including the API gateway
   and many micro-services with REST APIs for managing the system. Once administrative access has been configured,
   the installation of CSM software and nodes can be validated with health checks before doing operational tasks
   like the check and update of firmware on system components or the preparation of compute nodes.

1. [Upgrade CSM](upgrade/index.md)

   This chapter provides an order list of procedures which can be used to update CSM software that indicate when
   to do operational tasks as part of the software upgrade workflow. There are procedures to prepare the
   HPE Cray system for the upgrade, and update the management network, the management nodes, and the CSM services.
   After the upgrade of CSM software, the CSM health checks are used to validate the system before doing any other
   operational tasks like the check and update of firmware on system components.

1. [CSM Operational Activities](operations/index.md)

   This chapter provides an unordered set of administrative procedures required to operate an HPE Cray EX system with CSM software and grouped into several major areas:
   * CSM Product Management
   * Artifact Management
   * Boot Orchestration
   * Compute Rolling Upgrade
   * Configuration Management
   * Console Management
   * Firmware Management
   * Hardware State Manager
   * Image Management
   * Kubernetes
   * Network Management
   * Node Management
   * Package Repository Management
   * Power Management
   * Resiliency
   * River Endpoint Discovery Service
   * Security And Authentication
   * System Configuration Service
   * System Layout Service
   * System Management Health
   * UAS User And Admin Topics
   * Utility Storage
   * Validate CSM Health

1. [CSM Troubleshooting Information](troubleshooting/index.md)

   This chapter provides information about some known issues in the system and tips for troubleshooting Kubernetes.

1. [CSM Background Information](background/index.md)

   This chapter provides background information about the NCNs (non-compute nodes) which function as
   management nodes for the HPE Cray EX system. This information is not normally needed to install
   or upgrade software, but provides background which might be helpful for troubleshooting an installation.

1. [Glossary](glossary.md)

   This chapter provides explanations of terms and acronyms used throughout the rest of this documentation.
   
## Copyright and License

MIT License

(C) Copyright [2020-2022] Hewlett Packard Enterprise Development LP

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
