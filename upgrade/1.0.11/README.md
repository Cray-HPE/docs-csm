# CSM 1.0.11 CVE Patch/Upgrade Procedure

## Introduction

This document is intended to guide an administrator through the process going from Cray Systems Management v1.0.0, v1.0.1 or v1.0.10 to v1.0.11. This top-level README.md file should be followed top to bottom.

## Contents

CSM v1.0.11 is a security patch release, which addresses the following CVE's:

### CVE-2022-0185: Linux kernel buffer overflow/container escape 
More info: https://nvd.nist.gov/vuln/detail/CVE-2022-0185 \
Remediation: upgrade Linux kernel to patched version `5.3.18-24.99`.

### CVE-2021-4034: pwnkit: Local Privilege Escalation in polkit's pkexec
More info: https://nvd.nist.gov/vuln/detail/CVE-2021-4034 \
Remediation:  upgrade polkit and associated libpolkit0 packages to patched version `0.116-3.6.1`.

### CVE-2022-23302: affects log4j 1.x when it is configured with JMSSink
More info: https://nvd.nist.gov/vuln/detail/CVE-2022-23302 \
Remediation: Removed the impacted JMSSink class from the jar file.

### CVE-2022-23305: affects log4j 1.x when it is configured with JDBCAppender
More info: https://nvd.nist.gov/vuln/detail/CVE-2022-23305 \
Remediation: removed the impacted JDBCAppender class from the jar file.

### CVE-2022-23307: deserialization issue in chainsaw used in log4j 1.2.x
More info: https://nvd.nist.gov/vuln/detail/CVE-2022-23307 \
Remediation: removed the chainsaw from the jar file.

### CVE-2021-4104: affects log4j 1.x when it is configured with JMSAppender
More info: https://nvd.nist.gov/vuln/detail/CVE-2021-4104 \
Remediation: removed the impacted JMSAppender class from the jar file.


>**`NOTE:`**
>
>After this patch/upgrade is installed, scanning may still flag CVE-2022-2330[257] and CVE-2021-4104 CVEs.  This is due to the version of the log4j library/jar file remains the same, though the offending features are removed.
>

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
