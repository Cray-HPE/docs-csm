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

3. (Optional) Change Keycloak OAuth token lifetime.

   Perform procedure(s) in [Change Keycloak token lifetime](../security_and_authentication/Change_Keycloak_Token_Lifetime.md).

4. (Optional) Remove Kiali.

   Perform procedure(s) in [Remove Kiali](../system_management_health/Remove_Kiali.md).
