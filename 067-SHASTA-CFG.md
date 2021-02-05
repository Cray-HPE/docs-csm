# SHASTA-CFG

SHASTA-CFG is a distinct repository of relatively static, installation-centric artifacts, including:

* Cluster-wide network configuration settings required by Helm Charts deployed by product stream Loftsman Manifests
* [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
* Sealed Secret Generate Blocks -- an form of plain-text input that renders to a Sealed Secret
* Helm Chart value overrides that are merged into Loftsman Manifests by product stream installers

If you have an existing SHASTA-CFG repository, you'll need to update it based on the 'stable' distribution including in the CSM release. If you've previously updated your SHASTA-CFG repository **for the version of CSM you are installing**, no further action is required.

> IMPORTANT: Ensure your SHASTA-CFG repository has been updated for the release of CSM you are installing. 

## Preparation

Prior to either creating a new SHASTA-CFG repository, or updating an existing one, you may wish to make adjustments to the CSM distributed ```/mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml``` (a backup is recommended):

* If you would like to keep your current ```cray_reds_credentials```, ```cray_meds_credentials```, or ```cray_hms_rts_credentials``` credentials (or some subset thereof). Remove them from the ```tracked_secrets``` list under ```spec.kubernetes.sealed_secret```. 

## Update or initialize from stable

1. If you have an existing SHASTA-CFG repo, clone it into ```/mnt/pitdata/prep/site-init```. If not, create an empty directory at this location.

2. Update or initialize ```site-init``` from CSM (noting the output will different on new vs. update):

    ```bash 
    linux# /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/meta/init.sh /mnt/pitdata/prep/site-init
    ...
    **** IMPORTANT: Review and update /mnt/pitdata/prep/customizations.yaml and introduce custom edits (if applicable). ****
    When ready to proceed, execute the following commands:

    # /mnt/pitdata/prep/site-init/utils/secrets-reencrypt.sh /mnt/pitdata/prep/site-init/customizations.yaml /mnt/pitdata/prep/site-init/certs/sealed_secrets.key /mnt/pitdata/prep/site-init/certs/sealed_secrets.crt
    # /mnt/pitdata/prep/site-init/utils/secrets-seed-customizations.sh /mnt/pitdata/prep/site-init/customizations.yaml
    ```

3. Perform the following edits to ```customizations.yaml``` as applicable, also making sure to address any "FIXMEs":

* Review the ```spec.kubernetes.sealed_secrets``` generate blocks for ```cray_reds_credentials```, ```cray_meds_credentials```, and ```cray_hms_rts_credentials```. Replace the ```Password``` references with values appropriate for your system. If you opted to keep these secrets, you can safely skip this instruction.

* If you are federating Keycloak with an upstream LDAP server, and using TLS for LDAP, update the ```cray-keycloak``` sealed secret value by supplying a base64 encoded form of your CA certificate(s). You can use the ```keytool``` command and a PEM-encoded form of your certificate(s) to obtain this value, as follows: 

  ```bash
  linux# keytool -importcert -trustcacerts -file myad-pub-cert.pem -alias myad -keystore certs.jks -storepass password -noprompt
  linux# cat certs.jks | base64
  ```

    > Note: The keytool may not be available on the pit.

* If you would like to customize the PKI Certificate Authority (CA) used by the platform, see [Customizing the Platform CA](055-CERTIFICATE-AUTHORITY.md). Note that the CA can not be modified after install.

* For HPE `INTERNAL` Deployment, configure HPE Datacenter LDAP: 

    Update the ```keycloak_users_localize``` sealed secret

    ```yaml
    spec:
    kubernetes:
        sealed_secrets:
        keycloak_users_localize:
            generate:
            name: keycloak-users-localize
            data:
            - type: static
                args:
                name: ldap_connection_url
                value: ldap://172.30.79.134
    ```

    and configure Helm Chart overrides for ```cray-keycloak-users-localize```

    ```yaml
    spec:
    kubernetes:
        services:
        cray-keycloak-users-localize:
            ldapSearchBase: "dc=datacenter,dc=cray,dc=com"
            localRoleAssignments:
            - {"group": "criemp", "role": "admin", "client": "shasta"}
            - {"group": "criemp", "role": "admin", "client": "cray"}
            - {"group": "craydev", "role": "admin", "client": "shasta"}
            - {"group": "craydev", "role": "admin", "client": "cray"}
            - {"group": "shasta_admins", "role": "admin", "client": "shasta"}
            - {"group": "shasta_admins", "role": "admin", "client": "cray"}
            - {"group": "shasta_users", "role": "user", "client": "shasta"}
            - {"group": "shasta_users", "role": "user", "client": "cray"}
    ```

4. Encrypt ```customizations.yaml``` as earlier directed, e.g.:

    ```bash
    linux:~ # /mnt/pitdata/prep/site-init/utils/secrets-reencrypt.sh /mnt/pitdata/prep/site-init/customizations.yaml /mnt/pitdata/prep/site-init/certs/sealed_secrets.key /mnt/pitdata/prep/site-init/certs/sealed_secrets.crt
    linux:~ # /mnt/pitdata/prep/site-init/utils/secrets-seed-customizations.sh /mnt/pitdata/prep/site-init/customizations.yaml
    Creating Sealed Secret keycloak-certs
    Generating type static_b64...
    Creating Sealed Secret keycloak-master-admin-auth
    Generating type static...
    Generating type static...
    Generating type randstr...
    Generating type static...
    Creating Sealed Secret cray_reds_credentials
    Generating type static...
    Generating type static...
    Creating Sealed Secret cray_meds_credentials
    Generating type static...
    Creating Sealed Secret cray_hms_rts_credentials
    Generating type static...
    Generating type static...
    Creating Sealed Secret vcs-user-credentials
    Generating type randstr...
    Generating type static...
    Creating Sealed Secret generated-platform-ca-1
    Generating type platform_ca...
    Creating Sealed Secret pals-config
    Generating type zmq_curve...
    Generating type zmq_curve...
    Creating Sealed Secret munge-secret
    Generating type randstr...
    Creating Sealed Secret slurmdb-secret
    Generating type static...
    Generating type static...
    Generating type randstr...
    Generating type randstr...
    Creating Sealed Secret keycloak-users-localize
    Generating type static...
    ```

5. Optionally add, commit, and push your git changes to an upstream git repository. If production system or operational security is a concern, **store your sealed secret key-pair outside of git/in a secure offline system**.

    ```bash
     linux:/mnt/pitdata/prep/site-init# git add -A
     linux:/mnt/pitdata/prep/site-init# git commit -m "Updated to $(/mnt/pitdata/${CSM_RELEASE}/lib/version.sh)"
     linux:/mnt/pitdata/prep/site-init# git remote add origin https://your/upstream/repo.git
     linux:/mnt/pitdata/prep/site-init# git push -u origin master
     ```

## Decrypting Sealed Secrets for Review

If you would like to decrypt and review previously encrypted sealed secrets, you can use the ```secrets-decrypt.sh``` utility in SHASTA-CFG.

Syntax: ```secret-decrypt.sh sealed-secret-name sealed-secret-private-key-path customizations-path```

```bash
linux:/mnt/pitdata/prep/site-init# ./utils/secrets-decrypt.sh cray_meds_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_redfish_defaults | sed -e 's/"//g' | base64 -d; echo
{"Username": "root", "Password": "..."}
```