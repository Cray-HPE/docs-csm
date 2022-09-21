# Security Hardening

This is an overarching guide to further harden the security posture of a Cray System Management (CSM) system.

If a subset of the steps in this procedure were completed as a consequence of an install, upgrade, or other guidance, then it is safe to skip that subset following a review.

## Prerequisites

None.

## Procedure

1. Change passwords and credentials.

   Perform procedure(s) in [Change Passwords and Credentials](Change_Passwords_and_Credentials.md).

2. Restrict access to `ncn-images` S3 Bucket.

   Perform procedure(s) in [Restrict Access to `ncn-images` S3 Bucket](../security_and_authentication/Restrict_Access_to_NCN_Images_S3_Bucket.md).

3. Limit Kubernetes Audit Log Retention.

   If Kubernetes API Auditing was enabled at install, perform procedure(s) in [Limit Kubernetes API Audit Log Maximum Backups](../kubernetes/Limit_Kubernetes_API_Audit_Log_Maxbackups.md).

   Failure to apply the referenced configuration could result in NCN disk space exhaustion on Kubernetes Master Nodes.

4. Update IMS Job Access Network.

   Perform procedure(s) in [Update IMS Job Access Network](../../operations/image_management/Update_IMS_Job_Access_Network.md).

5. (Optional) Change Keycloak OAuth token lifetime.

   Perform procedure(s) in [Change Keycloak token lifetime](../security_and_authentication/Change_Keycloak_Token_Lifetime.md).

6. (Optional) Remove Kiali.

   Perform procedure(s) in [Remove Kiali](../system_management_health/Remove_Kiali.md).
