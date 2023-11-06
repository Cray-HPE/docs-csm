# Configure Multi-tenancy (Optional)

SAT supports supplying tenant information to CSM services in order to allow
tenant admins to use SAT within their tenant. By default, the tenant name is
not set, and SAT will not send any tenant information with its requests to
CSM services. Configure the tenant name either in the SAT configuration file
or on the command line.

## Configure the Tenant Name in the SAT Configuration File

Set the tenant name in the SAT configuration file using the
`api_gateway.tenant_name` option.

Here is an example:

```toml
[api_gateway]
tenant_name = "my_tenant"
```

## Configure the Tenant Name on the Command Line

Set the tenant name for each `sat` invocation using the `--tenant-name`
option. The `--tenant-name` option must be specified before the subcommand
name.

(`ncn-m001#`) Here is an example:

```bash
sat --tenant-name=my_tenant status
```
