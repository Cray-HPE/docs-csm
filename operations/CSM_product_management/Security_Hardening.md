# Security Hardening

This is an overarching guide to further harden the security posture of a Cray System Management (CSM) system.

If you have completed a subset of the steps of the procedure as a consequence of install, upgrade, or other guidance, you can safely skip said subset following a review.

## Prerequisites

None

## Procedure

### 1. Change Passwords and Credentials

1. Perform procedure(s) in [Change Passwords and Credentials](Change_Passwords_and_Credentials.md).

### 2. Restrict Access to ncn-images s3 Bucket

1. Perform procedure(s) in [Restrict Access to NCN Images S3 Bucket](../security_and_authentication/Restrict_Access_to_NCN_Images_S3_Bucket.md). 

### 3. Optional: Change Keycloak OAuth Token Lifetime

1. Perform procedure(s) in [Change Keycloak Token Lifetime](../security_and_authentication/Change_Keycloak_Token_Lifetime.md).

### 4. Optional: Remove Kiali

1. Perform procedure(s) in [Remove Kiali](../system_management_health/Remove_Kiali.md).