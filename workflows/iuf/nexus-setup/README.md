# Argo Templates

## ```nexus-setup-template.yaml```

This template will perform Nexus blobstore and repository setup. In its current form, the template requires a few parameters. Most parameters should be automatically obtained from the product installer's IUF manifest file, but that functionality is not in place yet. The template leverages the cray-nexus-setup container. Since this template is still in development, it is using a specific non-production version of that image to support the IUF.

### Developer usage
Argo will need to be told about the template. This can be done using ```argo template create``` as in the example below:

```bash
ncn-m001:~/rnoska/argo-nexus/test # argo -n argo template create nexus-setup-template.yaml
Name:                nexus-setup-template
Namespace:           argo
Created:             Wed Oct 12 18:18:46 +0000 (now)
```

The example below shows how to run the template using the current required parameters. The workflow will attempt to process the ```nexus_blob_stores``` and ```nexus_repositories``` files (named in iuf-manifest.yaml) relative to the host mounted ```product_host_path```/```product``` directory. This example will execute the template and requires a directory matching ```product_host_path``` which contains the product directory ```foo```.

```bash
argo -n argo submit --from workflowtemplate/nexus-setup-template \
  -p 'product=foo' \
  -p 'product_host_path=/root/rnoska/argo-nexus/products' \
  --parameter-file /root/rnoska/argo-nexus/products/foo/iuf-manifest.yaml \
  --watch 
```

You can view the current template by running:
```bash
argo -n argo template get nexus-setup-template -o yaml
```

If you wish to make changes, edit the template and then update the template in Argo by running:
```bash
argo -n argo template delete nexus-setup-template
argo -n argo template create nexus-setup-template.yaml
```

### Planned Work
Provide a way to obtain a default values for items read from iuf-manifest.yaml (by ```jsonpath```) that may have not been set. Examples are ```nexus_blob_stores``` and ```nexus_repositories```.