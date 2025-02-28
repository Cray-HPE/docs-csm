# Managing Sensitive Tenant Information in \(VCS\) with SOPS

For added security, CFS enables native [SOPS](../security_and_authentication/SOPS.md) integration for `host_vars` and `group_vars`
encryption as part of its security policy. Members of a tenancy, as defined by [TAPMS](../multi-tenancy/Tapms.md),
may choose to encrypt any configuration information deemed sensitive. When a new tenant is created, TAPMS enables and
exposes a new endpoint and transit engine through [HashiCorp Vault](../multi-tenancy/Vault.md). Tenant administrators may select
and convert standard Ansible `host_vars` and `group_vars` files in an encrypted format
and check them into [Version Control Service](Version_Control_Service_VCS.md) \(VCS\).

## Overview

Global administrators are able to manage CFS configurations for all tenants, including creation of new configurations
to be specifically owned by a tenant, and removal of any configuration that belonged to a tenant that no longer exists.

Tenant administrators are able to create CFS configurations that are specific to their tenancy, and they are only able
to modify and delete a CFS configuration that they own. List operations related to tenancy only show CFS configurations
that are owned by that tenant. No other tenant specific interactions are intended with the CFS API at this time.

### SOPS Encryption

Tenants may use the standard set of version control tools in concert with best practices outlined in instructions for
encrypting variables using the SOPS binary to perform encryption.

While using version control system to author and encrypt variables, the standard Ansible inventory and directory layout
applies for issuing `host_vars` and `group_vars` in the top level directory of your checkout. By convention, Ansible's
SOPS module denotes files that contain a `.sops.` suffix in concert with their file format suffixes (e.g. `.yaml`,
`.ini`, `.json`) in order to denote that the contents of the files are encrypted and require decryption before use as
Ansible runs.

Here is an example of how this might look within a check-in in a way that takes advantage of this encryption:

```bash
cd csm-config-management
find . | grep sops
```

```example output
./group_vars/all/static_tenant_passwords.sops.ini
./group_vars/all/super_secret.sops.yaml
./group_vars/privilaged_nodes_group/the_answer_to_life_the_universe_and_everything.sops.json
./host_vars/x3001c0s31b0n0/extra_secret_information_for_a_specific_node.sops.yaml
```

### SOPS Decryption

When CFS sessions are created, they are always associated with exactly one CFS configuration. If that CFS configuration
is owned by a tenant, then CFS will coordinate efforts with TAPMS and Vault to look up the associated `VAULT_TOKEN` for
that tenant and expose this as an environment variable to be used by Ansible within a CFS launched session.

By default, Ansible is shipped with the SOPS module turned on, so any `host_vars` and `group_vars` that are within the
associated VCS checkouts when run will automatically decrypt any encrypted values in memory.

## Security Considerations

When Ansible runs, encrypted variables are automatically decrypted for use. Standard good practices and safety
using Ansible tasks with `no_log: True` should be used in conjunction with any tasks that handle sensitive
information that would otherwise output sensitive information during task execution.

SOPS provides a means to secure information within a VCS checkout or checkouts, however the global administrator must
ensure that Ansible configurations run against the cluster are not considered harmful or inappropriate for a given
tenant.

Currently, no mechanism exists to completely separate launched CFS sessions against cluster resources that a particular
tenant does not own or should not access. This includes accessing cluster internal system resources to affect resources
that do not belong to a tenant, as well as Ansible tasks that are authored to use the `delegate_to` stanza within
defined roles and tasks that target resources outside the associated tenancy. For this reason, system  administrators
have a global view of all configurations defined within CFS to better aid in auditing.
