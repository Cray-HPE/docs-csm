# Generate SAT S3 Credentials

Generate S3 credentials and write them to a local file so the SAT user can access S3 storage. In
order to use the SAT S3 bucket, the System Administrator must generate the S3 access key and secret
keys and write them to a local file.  This must be done on every Kubernetes control plane node where
SAT commands are run.

SAT uses S3 storage for several purposes, most importantly to store the site-specific information
set with `sat setrev` (see [Set System Revision Information](Set_System_Revision_Information.md)).

## Prerequisites

- CSM has been installed.
- The SAT configuration file has been created as described in
  [Authenticate SAT Commands](Authenticate_SAT_Commands.md).

## Procedure

1. (`ncn-m001#`) Ensure the files are readable only by `root`.

    ```bash
    touch /root/.config/sat/s3_access_key \
        /root/.config/sat/s3_secret_key
    ```

    ```bash
    chmod 600 /root/.config/sat/s3_access_key \
        /root/.config/sat/s3_secret_key
    ```

1. (`ncn-m001#`) Write the credentials to local files using `kubectl`.

   ```bash
   kubectl get secret sat-s3-credentials -o json -o \
       jsonpath='{.data.access_key}' | base64 -d > \
       /root/.config/sat/s3_access_key
   ```

   ```bash
   kubectl get secret sat-s3-credentials -o json -o \
       jsonpath='{.data.secret_key}' | base64 -d > \
       /root/.config/sat/s3_secret_key
   ```

1. Verify the S3 endpoint specified in the SAT configuration file is correct.

   1. (`ncn-m001#`) Get the SAT configuration file's endpoint value.

      **Note:** If the command's output is commented out, indicated by an initial `#`
      character, the SAT configuration will take the default value – `"https://rgw-vip.nmn"`.

      ```bash
      grep endpoint ~/.config/sat/sat.toml
      ```

      Example output:

      ```text
      # endpoint = "https://rgw-vip.nmn"
      ```

   1. (`ncn-m001#`) Get the `sat-s3-credentials` secret's endpoint value.

      ```bash
      kubectl get secret sat-s3-credentials -o json -o \
          jsonpath='{.data.s3_endpoint}' | base64 -d | xargs
      ```

      Example output:

      ```text
      https://rgw-vip.nmn
      ```

   1. Compare the two endpoint values.

      If the values differ, change the SAT configuration file's endpoint value to
      match the secret's.

1. (`ncn-m001#`) Copy SAT configurations to each Kubernetes control plane (`ncn-m`) node on the
   system.

   ```bash
   for i in ncn-m002 ncn-m003; do echo $i; ssh ${i} \
       mkdir -p /root/.config/sat; \
       scp -pr /root/.config/sat ${i}:/root/.config; done
   ```

   **Note:** Depending on how many Kubernetes control plane (`ncn-m`) nodes are on the system, the
   list of nodes may be different. This example assumes three `ncn-m` nodes, where the configuration
   files must be copied from `ncn-m001` to `ncn-m002` and `ncn-m003`. Therefore, the list of hosts
   above is `ncn-m002` and `ncn-m003`.
