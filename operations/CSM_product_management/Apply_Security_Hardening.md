# Security Hardening

This is an overarching guide to further harden the security posture of a Cray System Management (CSM) system.

If a subset of the steps in this procedure were completed as a consequence of an install, upgrade, or other guidance, then it is safe to skip that subset following a review.

## Prerequisites

None.

## Procedure

1. Change passwords and credentials.

   Perform procedures in [Change Passwords and Credentials](Change_Passwords_and_Credentials.md).

1. Randomize iPXE binary name.

   Perform procedures in [Customize iPXE Binary Names](../boot_orchestration/Customize_iPXE_Binary_Names.md).

1. (Optional) Enable Spire and OPA xname validation.

    Perform procedures in [xname validation](../spire/xname_validation.md).

1. (Optional) Enable Kubernetes API encryption.

    Perform procedures in [Kubernetes Encryption](../kubernetes/encryption/README.md).

1. (Optional) Change Keycloak OAuth token lifetime.

   Perform procedures in [Change Keycloak token lifetime](../security_and_authentication/Change_Keycloak_Token_Lifetime.md).

1. (Optional) Remove Kiali.

   Perform procedures in [Remove Kiali](../system_management_health/Remove_Kiali.md).

1. (Optional) Kubernetes API audit log file parameter settings.

   If Kubernetes API Auditing is enabled, then it is recommended to set `--audit-log-maxage` to 30 or appropriate value

   and `--audit-log-maxsize` parameter to 100 or appropriate value.

   For more information on setting the audit parameters refer [Audit parameter settings](../security_and_authentication/Audit_Logs.md).
