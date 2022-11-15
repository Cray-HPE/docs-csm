# Argo Templates

## `nexus-setup-template.yaml`

This template will perform Nexus `blobstore` and `repository` setup. In its current form, the template requires a few parameters.
Most parameters should be automatically obtained from the product installer's IUF manifest file, but that functionality is not
in place yet. The template leverages the `cray-nexus-setup` container. Since this template is still in development, it is using a
specific non-production version of that image to support the IUF.

### Developer usage

Argo will need to be told about the template. This can be done using `argo template create` as in the example below:

```bash
ncn-m001:~/rnoska/argo-nexus/test # argo -n argo template create nexus-setup-template.yaml
Name:                nexus-setup-template
Namespace:           argo
Created:             Wed Oct 12 18:18:46 +0000 (now)
```

The example below shows how to run the template using the current required parameters. The workflow will attempt to process the
`nexus_blob_stores` and `nexus_repositories` files (named in `iuf-manifest.yaml`) relative to the host mounted
`product_host_path`/`product` directory. This example will execute the workflow and requires a directory matching
`product_host_path` which contains the product directory `foo`. The `nexus_setup_image` parameter specifies the current image and
tag that is used to perform the underlying Nexus functions.

```bash
argo -n argo submit --from workflowtemplate/nexus-setup-template \
  -p product=foo \
  -p product_host_path=/root/rnoska/argo-nexus/products \
  -p nexus_setup_image=artifactory.algol60.net/csm-docker/unstable/cray-nexus-setup:0.8.0-20221021164623_e8d3d3d \
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

## `nexus-docker-upload-template.yaml`

This template will upload docker images into Nexus. In its current form, the template requires a few parameters.
Most parameters should be automatically obtained from the product installer's IUF manifest file, but that functionality is not
in place yet. The template requires a `skopeo` container image.

Create the template in Argo by running:

```bash
argo -n argo template create nexus-setup-template.yaml
```

The example below shows how to submit the template using the current required parameters. This example requires the existence
of the product at `$PRODUCTS_DIR`/`$PRODUCT` and requires the `$SKOPEO_IMAGE` to be present in Nexus.

```bash
PRODUCTS_DIR=/admin/rnoska/argo-nexus/nexus-upload/products
PRODUCT=cos-2.5.38-20221024172946
artifactory.algol60.net/csm-docker/unstable/cray-nexus-setup:0.8.1-20221101230212_86ad20d

argo -n argo submit --from workflowtemplate/nexus-docker-upload-template \
  -p product=$PRODUCT \
  -p product_host_path=$PRODUCTS_DIR \
  -p nexus_docker_skopeo_image=$SKOPEO_IMAGE \
  --parameter-file $PRODUCTS_DIR/$PRODUCT/iuf-manifest.yaml \
  --watch
```

## `nexus-rpm-upload-template.yaml`

This template will upload content for one or more type "raw" or "yum" repositories into Nexus.

Create the template in Argo by running:

```bash
argo -n argo template create nexus-rpm-upload-template.yaml
```

The example below shows how to submit the template using the current required parameters. This example requires the existence
of the product at `$PRODUCTS_DIR`/`$PRODUCT` and requires the `$NEXUS_SETUP_IMAGE` to be present in Nexus.

```bash
argo -n argo submit --from workflowtemplate/nexus-rpm-upload-template \
  -p product=$PRODUCT \
  -p product_host_path=$PRODUCTS_DIR \
  -p nexus_setup_image=$NEXUS_SETUP_IMAGE \
  --parameter-file $PRODUCTS_DIR/$PRODUCT/iuf-manifest.yaml \
  --watch
```
