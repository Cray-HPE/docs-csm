# Security Hardening

This is an overarching guide to further harden the security posture of a Cray System Management (CSM) system.

If a subset of the steps in this procedure were completed as a consequence of an install, upgrade, or other guidance, then it is safe to skip that subset following a review.

## Prerequisites

None.

## Procedure

1. Change passwords and credentials.

   Perform procedure(s) in [Change Passwords and Credentials](Change_Passwords_and_Credentials.md).

2. Limit Kubernetes Audit Log Retention.

   If Kubernetes API Auditing was enabled at install, perform procedure(s) in [Limit Kubernetes API Audit Log Maximum Backups](../kubernetes/Limit_Kubernetes_API_Audit_Log_Maxbackups.md).

   Failure to apply the referenced configuration could result in NCN disk space exhaustion on Kubernetes Master Nodes.

3. Customize ("randomize") iPXE Binary Name.

   Perform procedure(s) in [Customize iPXE Binary Names](../boot_orchestration/Customize_iPXE_Binary_Names.md).

4. (Optional) Enable Spire and OPA Xname Validation.

    Perform procedure(s) in [Xname Validation](../spire/xname_validation.md).

5. (Optional) Enable Kubernetes API Encryption

    Perform procedure(s) in [Kubernetes Encryption](../kubernetes/encryption/README.md).

6. (Optional) Change Keycloak OAuth token lifetime.

   Perform procedure(s) in [Change Keycloak token lifetime](../security_and_authentication/Change_Keycloak_Token_Lifetime.md).

7. (Optional) Remove Kiali.

   Perform procedure(s) in [Remove Kiali](../system_management_health/Remove_Kiali.md).