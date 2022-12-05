# Argo Templates

## `vcs-upload-content.yaml`

This template will upload the current product's git content to the `gitea` server. This operation is calling containerized code living here [cf-gitea-import](https://github.com/Cray-HPE/cf-gitea-import).
In the current state of this template, there are a few required parameters:

All of these parameters may be overridden by passing them through argo with:
> -p parameter=foo

- `cf_import_gitea_org` - Defaults to 'cray'
- `cf_import_content_hostpath` - Defaults to /content
- `cf_import_results_hostpath` - Defaults to /results
  - This is the path on the management node where the product's content and results will be stored so it will be used as a `volumeMount` in the template.

### Manifest parameters

Several parameters are being provided to the template through the product manifest json file. This will be abstracted through the CLI API. For clarity, here are the explicit parameters:

To see the exact jsonpath examine the yaml.

- `cf_import_product_name`
- `cf_import_product_version`
