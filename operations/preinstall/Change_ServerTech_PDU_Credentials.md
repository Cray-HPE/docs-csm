# Change Credentials on ServerTech PDUs

This procedure changes password used by the `admn` user on ServerTech PDUs.
This procedure should be used to update all ServerTech PDUs in the system to
the same global credentials.

**NOTE:** This procedure only updates the default credentials on the
ServerTech PDU hardware. No credentials are set in any management software.

## Prerequisites

- The ServerTech PDUs must be accessible via a workstation or laptop.
- Workstation or laptop has the `curl` command installed.
- The ServerTech PDU hostnames or IP addresses must be known.
- The default `admn` user password must be known for each PDU.

## Procedure

For each ServerTech PDU:

1. Change password for the `admn` user on the ServerTech PDU.

   ```bash
   linux# curl -i -k -u admn:<OLD-PDU-PASSWORD> -X PATCH \
                  https://<PDU_IP_OR_HOSTNAME>/jaws/config/users/local/admn \
                  -d "{ \"password\": \"<NEW_PDU_PASSWORD>\" }"
   ```

   Expected output upon a successful password change:

   ```
   HTTP/1.1 204 No Content
   Content-Type: text/html
   Transfer-Encoding: chunked
   Server: ServerTech-AWS/v8.0p
   Set-Cookie: C5=1883488164; path=/
   Connection: close
   Pragma: JAWS v1.01
   ```

   **NOTE:** After 5 minutes, the previous credential should stop working as the existing session timed out.

1. Verify that the new password works:

   ```bash
   linux# curl -i -k -u admn:<NEW-PDU-PASSWORD> \
                  https://<PDU_IP_OR_HOSTNAME>/jaws/config/banner
   ```

   Expected output upon a successful password change:

   ```
   HTTP/1.1 200 OK
   Content-Type: application/json
   Content-Length: 23
   Server: ServerTech-AWS/v8.0p
   Set-Cookie: C5=241418521; path=/
   Allow: GET, PATCH
   CacheControl: no-cache,no-store
   Expires: Thu, 26 Oct 1995 00:00:00 GMT
   Pragma: JAWS v1.01

   {
           "message" : ""
   }
   ```

