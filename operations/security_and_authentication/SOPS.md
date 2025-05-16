# SOPS Introduction

Secrets OPerationS (SOPS) is an editor that utilizes a number of different encryption strategies
in order to secure sensitive information in a secure way. SOPS supports multiple
types of encryption service back-ends. CSM uses HashiCorp Vault to encrypt and
store secure information that allows full granularity between defined tenancies
as part of its multi-tenancy package.

More specifically, when SOPS is used as an interactive editor for sensitive
information, all values that are part of common structured files, like YAML,
JSON, or INI files are safely encrypted. Key information within these structures
is not encrypted at all. Use of SOPS as an encryption tool decreases the chances
that sensitive information will become compromised.

## Trust TLS certificates

Sensitive values within these structured files are transferred
between use of the SOPS binary and the encrypting service endpoint, so it is important
that HTTPS/TLS certificates are used to encrypt traffic end to end while using
this feature so that plain text sensitive fields are encrypted and not intercepted
by a man in the middle security exception.

Follow the instructions for trusting this certificate in the local environment before proceeding. See
[Make HTTPS Requests from Sources Outside the Management Kubernetes Cluster](Make_HTTPS_Requests_from_Sources_Outside_the_Management_Kubernetes_Cluster.md).

## Using SOPS with tenant specific TAPMS exposed Vault endpoint

[Tenant and Partition Management System (TAPMS)](../multi-tenancy/Tapms.md)
creates a unique Vault encryption endpoint for each tenant that is created on the system when requested.
When a tenant is created, a new SOPS compatible Vault endpoint unique to the tenant will be created
when `enablekms: true` is supplied when the tenant is created. Refer to the
TAPMS documentation for further details.

Once the tenant has been created, users may infer the `transitname` that has been
created for them.

### Setup procedure

1. (`ncn-mw#`) Set tenancy and [CMN](../../glossary.md#customer-management-network-cmn) address variables.
   These will be used throughout the setup procedure.

   Set the protocol, tenant name, and CMN domain name for the system:

   ```bash
   TENANT_NAME=vcluster-testing-tenant
   PROTOCOL=https
   SYSTEM_NAME=`craysys metadata get system-name`
   DOMAIN_NAME=`craysys metadata get site-domain`
   CMN_NAME=cmn.$SYSTEM_NAME.$DOMAIN_NAME
   ```

1. (`ncn-mw#`) Retrieve tenant's `transitname` and `keyname`.

    ```bash
    TRANSIT_NAME=`kubectl get tenants.tapms.hpe.com -n tenants $TENANT_NAME -ojson | jq -r .status.tenantkms.transitname`
    KEY_NAME=`kubectl get tenants.tapms.hpe.com -n tenants $TENANT_NAME -ojson | jq -r .status.tenantkms.keyname`
    ```

    This value includes a UUID that is different from a tenant's UUID.

1. Construct and export the Vault address location in the form of `VAULT_ADDR`.

    SOPS requires that Vault addresses follow a specific URI pattern of the format:

    ```text
    export VAULT_ADDR=${PROTOCOL}://vault.${CMN_NAME}/v1/${TRANSIT_NAME}/keys/${KEY_NAME}
    ```

    Example value of this variable:

    ```text
    https://vault.cmn.mug.hpc.amslaps.hpecorp.net/v1/cray-tenant-750a987e-c7e5-4a66-8a1d-a82b29594a53/keys/key1
    ```

    SOPS has a requirement that the `VAULT_ADDR` be in the form
    that precludes the typical use of `/api/vault/` as part of its address, which
    is why `vault.cmn.<system name>` is exposed as part of its own DNS record over
    the customer managed network.

1. (`ncn-mw#`) Retrieve the tenant's Kubernetes token from the tenant's secret.

    When TAPMS creates a new tenant, a new Kubernetes namespace is created bearing
    the same name. Within that namespace, there should be a default service account.

    Generate the tenant's Kubernetes service account token.

    ```bash
    TOKEN=`kubectl create token -n ${TENANT_NAME} default`
    ```

1. (`ncn-mw#`) Using the tenant's service account token, obtain a `VAULT_TOKEN` from Vault.

    Log in to Vault to obtain a client token.

    ```bash
    VAULT_LOGIN=$PROTOCOL://vault.$CMN_NAME/v1/auth/kubernetes/login
    export VAULT_TOKEN=$(curl -s --data '{"jwt": "'"$TOKEN"'", "role": "'"$TRANSIT_NAME"'"}' $VAULT_LOGIN | jq -r '.auth.client_token')
    ```

### Example procedure

1. (`ncn-mw#`) Set the name of the tenant.

   ```bash
   TENANT_NAME=vcluster-testing-tenant
   ```

1. (`ncn-mw#`) Obtain `VAULT_ADDR` and create a `VAULT_TOKEN` for use with SOPS:

   ```bash
   PROTOCOL=https
   SYSTEM_NAME=`craysys metadata get system-name`
   DOMAIN_NAME=`craysys metadata get site-domain`
   CMN_NAME=cmn.$SYSTEM_NAME.$DOMAIN_NAME
   TRANSIT_NAME=`kubectl get tenants.tapms.hpe.com -n tenants $TENANT_NAME -ojson | jq -r .status.tenantkms.transitname`
   KEY_NAME=`kubectl get tenants.tapms.hpe.com -n tenants $TENANT_NAME -ojson | jq -r .status.tenantkms.keyname`
   TOKEN=`kubectl create token -n ${TENANT_NAME} default`
   VAULT_LOGIN=$PROTOCOL://vault.$CMN_NAME/v1/auth/kubernetes/login
   export VAULT_ADDR=${PROTOCOL}://vault.${CMN_NAME}/v1/${TRANSIT_NAME}/keys/${KEY_NAME}
   export VAULT_TOKEN=$(curl -s --data '{"jwt": "'"$TOKEN"'", "role": "'"$TRANSIT_NAME"'"}' $VAULT_LOGIN | jq -r '.auth.client_token')
   ```

1. (`ncn-mw#`) Verify Vault information and migrate to SOPS environment

    ```bash
    echo "export VAULT_ADDR=${VAULT_ADDR}"
    echo "export VAULT_TOKEN=${VAULT_TOKEN}"
    ```

### SOPS use case requirements

The `VAULT_TOKEN` will be valid until its duration has expired. These values
may be used on any system with SOPS installed that match these criteria:

* The environment is configured to trust TLS/SSL certificates from CSM.
* The environment has a network connection that can resolve `$VAULT_ADDR` over the customer managed network.
* A version of SOPS that supports HashiCorp Vault is installed.
    * For the latest version and how to install it, see [the SOPS release page](https://github.com/getsops/sops/releases).
    * Mac environments using brew: `brew install sops`
    * Running SOPS from a container: `podman run ghcr.io/getsops/sops:v3.9.1-alpine`
    * From a distribution repository: `zypper install sops`

### SOPS use cases

These are example use cases for how SOPS can be used to secure sensitive information.
The information provided here is a subset of what SOPS can do. The [SOPS `README`](https://github.com/getsops/sops/blob/main/README.rst)
provides more comprehensive examples of how it can be used.

#### Use SOPS to interactively encrypt sensitive values that are unique to a tenant

From a SOPS equipped environment

```bash
sops --hc-vault-transit $VAULT_ADDR new_secret_contents.yml
```

SOPS opens up an interactive text editor allowing creation and modification of a
new file containing secret information.

#### Use SOPS to encrypt an existing file

From a SOPS equipped environment

```bash
sops encrypt --hc-vault-transit $VAULT_ADDR csm_repos.yml > csm_repos.sops.yml
```

#### Use SOPS to decrypt an already encrypted file

From a SOPS equipped environment

```bash
sops decrypt csm_repos.sops.yml > csm_repos.decrypted.yml
```

#### Using SOPS with VCS and CFS with Ansible

The version of Ansible used by the
[Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
is SOPS enabled, meaning it is not necessary to store
sensitive information in variables within the
[Version Control Service (VCS)](../../glossary.md#version-control-service-vcs).
This is important, as only members of a tenancy should have access to the secure information, and no one else.

By convention, Ansible is configured to decrypt any and all `hostvars` and `groupvars`
that are stored within VCS. This allows users to check out the contents of their
Ansible and git repositories, encrypt those files and variables that are considered
sensitive, and then check in the SOPS encrypted version of these files.

Ansible relies on filename hints within`hostvars` and `groupvars` in order to determine
which files, if any, require decryption before Ansible is run. Ansible will decrypt
any `hostvars` or `groupvars` files that include a `*.sops.*` pattern.

1. Perform a local checkout of the CFS configuration from VCS.

    See [Version Control Service (VCS)](../configuration_management/Version_Control_Service_VCS.md).

1. Replace sensitive information with encrypted versions.

    Example from a SOPS equipped environment with a checked out CFS configuration

    ```bash
    cd csm-config
    sops encrypt --hc-vault-transit $VAULT_ADDR user_passwords.yml > user_passwords.sops.yml
    rm user_passwords.yml
    git rm user_passwords.yml
    git add user_passwords.sops.yml
    git commit -m "Securing sensitive information in Vault"
    git push origin HEAD
    ```

1. Check in the updated configuration and register it with CFS.

    See [CFS Configurations](../configuration_management/CFS_Configurations.md).

1. Create a CFS session (either automatically as part of boot or through CFS API).

    See [CFS Sessions](../configuration_management/CFS_Sessions.md).
