# CSM 1.0.11 CVE Patch/Upgrade Procedure

## Introduction

This document is intended to guide an administrator through the process going from Cray Systems Management v1.0.0, v1.0.1 or v1.0.10 to v1.0.11. This top-level README.md file should be followed top to bottom.

## Contents

TODO: Add CVE descriptions here

## Terminology

Throughout the guide the terms "stable" and "upgrade" are used in the context of the management nodes (NCNs). The
"stable" NCN is the master NCN from which all of these commands will be run and therefore cannot have its power state
affected. The "upgrade" NCN is the NCN to upgrade next.

When doing a rolling upgrade of the entire cluster, at some point you will need to transfer the
responsibility of the "stable" NCN to another master NCN. However, you do not need to do this before you are ready to
upgrade the "stable" NCN.

>**`IMPORTANT:`**
>
> For TDS systems with only three worker nodes, prior to proceeding with this upgrade CPU limits **MUST** be lowered on several services in order for this upgrade to succeed.  See [TDS Lower CPU Requests](../../operations/kubernetes/TDS_Lower_CPU_Requests.md) for information on how to accomplish this.
>

## Upgrade Stages

- [Stage 0 - Prerequisites](Stage_0_Prerequisites.md)
- [Stage 1 - Ceph Node Image Upgrade](Stage_1.md)
- [Stage 2 - Kubernetes Node Image Upgrade](Stage_2.md)
- [Stage 3 - CSM Services Upgrade](Stage_3.md)
- [Stage 4 - Rollout DNS Unbound Deployment Restart](Stage_4.md)
- [Stage 5 - Verification](Stage_5.md)

**`Important:`** Please see [Upgrade Troubleshooting](./upgrade_troubleshooting.md) for troubleshooting purposes in the case that you encounter issues.
