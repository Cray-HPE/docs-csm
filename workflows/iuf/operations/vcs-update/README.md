# Argo Templates

## `vcs-update-working-branch.yaml`

This template will update the current integration or customer branch to the latest pristine branch. This operation is calling containerized code living here [cf-gitea-update](https://github.com/Cray-HPE/cf-gitea-update).
In the current state of this template, there are a few required parameters:

All of these parameters may be overridden by passing them through argo with:
> -p parameter=foo

- `customer_branch`
- `pristine_branch`

### Manifest parameters

Several parameters are being provided to the template through the product manifest json file. This will be abstracted through the CLI API. For clarity, here are the explicit parameters:

To see the exact jsonpath examine the yaml.

- `cf_update_product_name`
- `cf_update_product_version`
