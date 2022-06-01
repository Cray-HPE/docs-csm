# Upload and Register an Image Recipe

Download and expand recipe archives from S3 and IMS. Modify and upload a recipe archive, and then register that recipe archive with IMS.

## Prerequisites

* The Cray command line interface \(CLI\) tool is initialized and configured on the system.
* System management services \(SMS\) are running in a Kubernetes cluster on non-compute nodes \(NCNs\) and include the following deployment:
  * `cray-ims`, the Image Management Service \(IMS\)
* The NCN Certificate Authority \(CA\) public key has been properly installed into the CA cache for this system.
* A token providing Simple Storage Service \(S3\) credentials has been generated.

## Limitations

* The commands in this procedure must be run as the `root` user.
* The IMS tool currently only supports Kiwi-NG recipe types.

## Procedure

1. Locate the desired recipe to download from S3.

    There may be multiple records returned. Ensure that the correct record is selected in the returned data.

    ```bash
    ncn# cray ims recipes list
    ```

    Excerpt from example output:

    ```toml
    [[results]]
    id = "76ef564d-47d5-415a-bcef-d6022a416c3c"
    name = "cray-sles15-barebones"
    created = "2020-02-05T19:24:22.621448+00:00"
    
    [results.link]
    path = "s3://ims/recipes/76ef564d-47d5-415a-bcef-d6022a416c3c/cray-sles15-barebones.tgz"
    etag = "28f3d78c8cceca2083d7d3090d96bbb7"
    type = "s3"
    ```

1. Create variables for the S3 `bucket` and `key` values from the S3 `path` in the returned data of the previous step.

    ```bash
    ncn# S3_ARTIFACT_BUCKET=ims
    ncn# S3_ARTIFACT_KEY=recipes/76ef564d-47d5-415a-bcef-d6022a416c3c/cray-sles15-barebones.tgz
    ncn# ARTIFACT_FILENAME=cray-sles15-barebones.tgz
    ```

1. Download the recipe archive.

    Use the variables created in the previous step when running the following command.

    ```bash
    ncn# cray artifacts get $S3_ARTIFACT_BUCKET $S3_ARTIFACT_KEY $ARTIFACT_FILENAME
    ```

1. Expand the recipe with `tar`.

    ```bash
    ncn# mkdir image-recipe
    ncn# tar xvf $ARTIFACT_FILENAME -C image-recipe
    ```

1. Modify the recipe by editing the files and subdirectories in the `image-recipe` directory.

    A Kiwi recipe consists of multiple files and directories, which together define the repositories, packages, and post-install actions to
    take during the Kiwi build process.

    * Edit the `config.xml` file to modify the name of the recipe, the set of RPM packages being installed, or the RPM repositories being
      referenced.
    * Kiwi-NG supports multiple ways to modify the post-install configuration of the image root, including some shell scripts
      \(`config.sh`, `images.sh`\) and the root/overlay directory. To learn how these can be used to add specific configuration to the image
      root, see the [Kiwi-NG documentation](https://doc.opensuse.org/projects/kiwi/doc/).
    * Recipes built by IMS are required to reference repositories that are hosted on the NCN by the Nexus service.

1. Locate the directory containing the Kiwi-NG image description files.

    This step should be done after the recipe has been changed.

    ```bash
    ncn# cd image-recipe
    ```

1. Set an environment variable for the name of the file that will contain the archive of the image recipe.

    ```bash
    ncn# ARTIFACT_FILE=my_recipe.tgz
    ```

1. Create a `tgz` archive of the image recipe.

    ```bash
    ncn# tar cvfz ../$ARTIFACT_FILE .
    ncn# cd ..
    ```

1. Create a new IMS recipe record.

    ```bash
    ncn# cray ims recipes create --name "My Recipe" \
            --recipe-type kiwi-ng --linux-distribution sles15
    ```

    Example output:

    ```toml
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
    linux_distribution = "sles15"
    name = "my_recipe.tgz"
    recipe_type = "kiwi-ng"
    ```

1. Create a variable for the `id` value in the returned data.

    ```bash
    ncn# IMS_RECIPE_ID=2233c82a-5081-4f67-bec4-4b59a60017a6
    ```

1. Upload the customized recipe to S3.

    It is suggested as a best practice that the S3 object name start with `recipes/` and contain the IMS recipe ID,
    in order to remove ambiguity.

    ```bash
    ncn# cray artifacts create ims recipes/$IMS_RECIPE_ID/$ARTIFACT_FILE $ARTIFACT_FILE
    ```

1. Update the IMS recipe record with the S3 path to the recipe archive.

    ```bash
    ncn# cray ims recipes update $IMS_RECIPE_ID --link-type s3 \
            --link-path s3://ims/recipes/$IMS_RECIPE_ID/$ARTIFACT_FILE
    ```

    Example output:

    ```toml
    id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
    recipe_type = "kiwi-ng"
    linux_distribution = "sles15"
    name = "my_recipe.tgz"
    created = "2020-02-05T19:24:22.621448+00:00"

    [link]
    path = "s3://ims/recipes/2233c82a-5081-4f67-bec4-4b59a60017a6/my_recipe.tgz"
    etag = ""
    type = "s3"
    ```
