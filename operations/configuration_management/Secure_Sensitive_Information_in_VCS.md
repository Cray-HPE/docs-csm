# Managing Sensitive Information in \(VCS\)

For added security, the [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
enables native [SOPS](../security_and_authentication/SOPS.md) integration for `hostvars` and `groupvars`
encryption as part of its security policy. Members of a tenancy, as defined by the
[Tenant and Partition Management System (TAPMS)](../multi-tenancy/Tapms.md),
may choose to encrypt any configuration information deemed sensitive. When a new tenant is created, TAPMS enables and
exposes a new endpoint and transit engine through [HashiCorp Vault](../multi-tenancy/Vault.md). Tenant administrators may select
and convert standard Ansible `hostvars` and `groupvars` files in an encrypted format
and check them into [Version Control Service (VCS)](Version_Control_Service_VCS.md).

When Ansible runs, encrypted variables are automatically decrypted for use. Standard good practices and safety
using Ansible tasks with `no_log: True` should be used in conjunction with any tasks that handle sensitive
information.
