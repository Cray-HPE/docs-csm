# SOPS Introduction

SOPS is an editor that utilizes a number of different encryption strategies
in order to secure sensitive information in a secure way. SOPS supports multiple
types of encryption service back-ends. CSM uses HashiCorp Vault to encrypt and
store secure information that allows full granularity between defined tenancies
as part of its multi-tenancy package.

More specifically, when SOPS is used as an interactive editor for sensitive
information, all values that are part of common structured files, like YAML,
JSON, or INI files are safely encrypted. Key information within these structures
is not encrypted at all. Use of SOPS as an encryption tool decreases the chances
that sensitive information will become compromised.

## Trust TLS Certificates

Sensitive values within these structured files are transferred
between use of the SOPS binary and the encrypting service endpoint, so it is important
that HTTPS/TLS certificates are used to encrypt traffic end to end while using
this feature so that plain text sensitive fields are encrypted and not intercepted
by a man in the middle security exception.

Please follow [instructions used for trusting this certificate](./Make_HTTPS_Requests_from_Sources_Outside_the_Management_Kubernetes_Cluster.md) in your local environment
before proceeding.

## Using SOPS with Tenant Specific TAPMS Exposed Vault Endpoint

[TAPMS](../multi-tenancy/Tapms.md) creates a unique vault encryption endpoint
for each tenant that is created on the system when requested. When a tenant is
created, a new SOPS compatible vault endpoint unique to the tenant will be created
when `enablekms: true` is supplied when the tenant is created. Please refer to the
TAPMS documentation for further details.

Once the tenant has been created, users may infer the `transitname` that has been
created for them.

### Setup Procedure

1. Set your tenancy and CMN Address Variables. These will be used throughout
    the setup procedure.

    (`ncn-m001#`) Set the protocol, tenant Name and CMN domain name for your system

   ```bash
   TENANT_NAME=vcluster-testing-tenant
   TENANT_NAME=vcluster-eholen-testing-tenant
   PROTOCOL=https
   SYSTEM_NAME=`craysys metadata get system-name`
   DOMAIN_NAME=`craysys metadata get site-domain`
   CMN_NAME=cmn.$SYSTEM_NAME.$DOMAIN_NAME
    ```

2. (`ncn-m001#`) Retrieve and set tenant's `transitname`.

    ```bash
    TRANSIT_NAME=`kubectl get tenants.tapms.hpe.com -n tenants $TENANT_NAME -ojson | jq -r .status.tenantkms.transitname`
    ```

    Please note that this value includes a UUID that is different from a tenant's UUID.

3. Construct and export the Vault address location in the form of `VAULT_ADDR`.

    SOPS requires that vault addresses follow a specific URI pattern of
    the format:

    ```text
    export VAULT_ADDR=${PROTOCOL}://vault.${CMN_NAME}/v1/${TRANSIT_NAME}/keys/key1
    ```

    Example output from checking this variable:

    ```text
    echo $VAULT_ADDR
    https://vault.cmn.mug.hpc.amslaps.hpecorp.net/v1/cray-tenant-750a987e-c7e5-4a66-8a1d-a82b29594a53/keys/key1
    ```

    SOPS has a requirement that the VAULT_ADDR be in the form
    that precludes the typical use of `/api/vault/` as part of its address, which
    is why we expose `vault`.cmn.`system name` as part of its own DNS record over
    the customer managed network.

4. Export your tenant's Kubernetes token from your tenant's secret.

    When TAPMS creates a new tenant, a new Kubernetes namespace is created bearing
    the same name. Within that namespace, there should be exactly one tenant name
    that is part of your namespace.

    (`ncn-m001#`) Retrieve, parse, decrypt and export your tenant's Kubernetes service account token.

    ```bash
    TOKEN=`kubectl get secret -n ${TENANT_NAME} -ojson | jq -r .items[].data.token | base64 -d`
    ```

5. Using your tenant's service account token, obtain a `VAULT_TOKEN` from vault.

    (`ncn-m001#`) Login to Vault to obtain a vault client token.

   ```bash
   VAULT_LOGIN=$PROTOCOL://vault.$CMN_NAME/v1/auth/kubernetes/login
   export VAULT_TOKEN=$(curl -s --data '{"jwt": "'"$TOKEN"'", "role": "'"$TRANSIT_NAME"'"}' $VAULT_LOGIN | jq -r '.auth.client_token')
   ```

6. Summary of steps 1-5.

   (`ncn-m001#`) Set the name of  your tenant.

   ```bash
   TENANT_NAME=vcluster-testing-tenant
   ```

   (`ncn-m001#`) Obtain `VAULT_ADDR` and create a `VAULT_TOKEN` for use with SOPS:

   ```bash
   PROTOCOL=https
   SYSTEM_NAME=`craysys metadata get system-name`
   DOMAIN_NAME=`craysys metadata get site-domain`
   CMN_NAME=cmn.$SYSTEM_NAME.$DOMAIN_NAME
   TRANSIT_NAME=`kubectl get tenants.tapms.hpe.com -n tenants $TENANT_NAME -ojson | jq -r .status.tenantkms.transitname`
   TOKEN=`kubectl get secret -n ${TENANT_NAME} -ojson | jq -r .items[].data.token | base64 -d`
   VAULT_LOGIN=$PROTOCOL://vault.$CMN_NAME/v1/auth/kubernetes/login
   export VAULT_ADDR=${PROTOCOL}://vault.${CMN_NAME}/v1/${TRANSIT_NAME}/keys/key1
   export VAULT_TOKEN=$(curl -s --data '{"jwt": "'"$TOKEN"'", "role": "'"$TRANSIT_NAME"'"}' $VAULT_LOGIN | jq -r '.auth.client_token')
   ```

   (`ncn-m001#`) Verify Vault Information and migrate to SOPS environment

    ```bash
    echo "export VAULT_ADDR=${VAULT_ADDR}"
    echo "export VAULT_TOKEN=${VAULT_TOKEN}"
    ```

### SOPS Use Case Requirements

The `VAULT_TOKEN` will be valid until its duration has expired. These values
may be used on any system with SOPS installed that match these criteria:

1. The environment is configured to trust TLS/SSL Certificates from CSM.
2. The environment has a network connection that can resolve `$VAULT_ADDR` over
the customer managed network.
3. A version of SOPS that supports HashiCorp Vault is installed.
   1. [For the latest version and how to install it](https://github.com/getsops/sops/releases)
   2. Mac environments using brew: `brew install sops`
   3. Running SOPS from a container: `podman run ghcr.io/getsops/sops:v3.9.1-alpine`
   4. From a distribution repository: `zypper install sops`

### SOPS Use Cases

These are example use cases for how SOPS can be used to secure sensitive information.
The information provided here is a subset of what SOPS can do. The [SOPS readme](https://github.com/getsops/sops/blob/main/README.rst)
provides more comprehensive examples of how it can be used.

#### Use SOPS to interactively encrypt sensitive values that are unique to a tenant

(`From a SOPS Equipped Environment`)

```bash
sops --hc-vault-transit $VAULT_ADDR new_secret_contents.yml
```

SOPS opens up an interactive text editor allowing you to create and modify a
new file containing secret information.

#### Use SOPS to encrypt an existing file

(`From a SOPS Equipped Environment`)

```bash
sops encrypt --hc-vault-transit $VAULT_ADDR csm_repos.yml > csm_repos.sops.yml
```

#### Use SOPS to decrypt an already encrypted file

(`From a SOPS Equipped Environment`)

```bash
sops decrypt csm_repos.sops.yml > csm_repos.decrypted.yml
```

#### Using SOPS with VCS and CFS with Ansible

CFS' version of Ansible is SOPS enabled, meaning it is not necessary to store
sensitive information in variables within VCS. This is important, as only members
of your tenancy should have access to the secure information, and no one else.

By convention, Ansible is configured to decrypt any and all `hostvars` and `groupvars`
that are stored within VCS. This allows users to checkout the contents of their
Ansible and git repositories, encrypt those files and variables that are considered
sensitive, and then check in the SOPS encrypted version of these files.

Ansible relies on filename hints within`hostvars` and `groupvars` in order to determine
which files, if any, require decryption before Ansible is run. Ansible will decrypt
any `hostvars` or `groupvars` files that include a `*.sops.*` pattern.

1. [Perform a local checkout of your CFS Configuration from VCS](../configuration_management/Version_Control_Service_VCS.md)
2. Replace sensitive information with Encrypted Versions

    (`Example from a SOPS Equipped Environment with a checked out CFS Configuration`)

    ```bash
    cd csm-config
    sops encrypt --hc-vault-transit $VAULT_ADDR user_passwords.yml > user_passwords.sops.yml
    rm user_passwords.yml
    git rm user_passwords.yml
    git add user_passwords.sops.yml
    git commit -m "Securing sensitive information in vault"
    git push origin HEAD
    ```

3. Check in updated CSM Config and register configuration with CFS
4. Create a CFS Session (either automatically as part of boot or through CFS API)
