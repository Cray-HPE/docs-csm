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

1. (`ncn-mw#`) Locate the desired recipe to download from S3.

    There may be multiple records returned. Ensure that the correct record is selected in the returned data.

    ```bash
    cray ims recipes list
    ```

    Excerpt from example output:

    ```toml
    [[results]]
    id = "76ef564d-47d5-415a-bcef-d6022a416c3c"
    name = "cray-sles15-barebones"
    created = "2020-02-05T19:24:22.621448+00:00"
    arch = "x86_64"
    require_dkms = false

    [results.link]
    path = "s3://ims/recipes/76ef564d-47d5-415a-bcef-d6022a416c3c/cray-sles15-barebones.tgz"
    etag = "28f3d78c8cceca2083d7d3090d96bbb7"
    type = "s3"
    ```

1. (`ncn-mw#`) Create variables for the S3 `bucket` and `key` values from the S3 `path` in the returned data of the previous step.

    ```bash
    S3_ARTIFACT_BUCKET=ims
    S3_ARTIFACT_KEY=recipes/76ef564d-47d5-415a-bcef-d6022a416c3c/cray-sles15-barebones.tgz
    ARTIFACT_FILENAME=cray-sles15-barebones.tgz
    ```

1. (`ncn-mw#`) Download the recipe archive.

    Use the variables created in the previous step when running the following command.

    ```bash
    cray artifacts get $S3_ARTIFACT_BUCKET $S3_ARTIFACT_KEY $ARTIFACT_FILENAME
    ```

1. (`ncn-mw#`) Expand the recipe with `tar`.

    ```bash
    mkdir image-recipe
    tar xvf $ARTIFACT_FILENAME -C image-recipe
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

1. (`ncn-mw#`) Locate the directory containing the Kiwi-NG image description files.

    This step should be done after the recipe has been changed.

    ```bash
    cd image-recipe
    ```

1. (`ncn-mw#`) Set an environment variable for the name of the file that will contain the archive of the image recipe.

    ```bash
    ARTIFACT_FILE=my_recipe.tgz
    ```

1. (`ncn-mw#`) Create a `tgz` archive of the image recipe.

    ```bash
    tar cvfz ../$ARTIFACT_FILE .
    cd ..
    ```

1. (`ncn-mw#`) Create a new IMS recipe record.

    ```bash
    cray ims recipes create --name "My Recipe" \
            --recipe-type kiwi-ng --linux-distribution sles15 \
            --arch x86_64 --reqire-dkms False
    ```

    Example output:

    ```toml
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
    linux_distribution = "sles15"
    name = "my_recipe.tgz"
    recipe_type = "kiwi-ng"
    arch = "x86_64"
    require_dkms = false
    ```

1. (`ncn-mw#`) Create a variable for the `id` value in the returned data.

    ```bash
    IMS_RECIPE_ID=2233c82a-5081-4f67-bec4-4b59a60017a6
    ```

1. (`ncn-mw#`) Upload the customized recipe to S3.

    It is suggested as a best practice that the S3 object name start with `recipes/` and contain the IMS recipe ID,
    in order to remove ambiguity.

    ```bash
    cray artifacts create ims recipes/$IMS_RECIPE_ID/$ARTIFACT_FILE $ARTIFACT_FILE
    ```

1. (`ncn-mw#`) Update the IMS recipe record with the S3 path to the recipe archive.

    ```bash
    cray ims recipes update $IMS_RECIPE_ID --link-type s3 \
            --link-path s3://ims/recipes/$IMS_RECIPE_ID/$ARTIFACT_FILE
    ```

    Example output:

    ```toml
    id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
    recipe_type = "kiwi-ng"
    linux_distribution = "sles15"
    name = "my_recipe.tgz"
    created = "2020-02-05T19:24:22.621448+00:00"
    arch = "x86_64"
    require_dkms = false

    [link]
    path = "s3://ims/recipes/2233c82a-5081-4f67-bec4-4b59a60017a6/my_recipe.tgz"
    etag = ""
    type = "s3"
    ```

## Templating IMS Recipes when Building an IMS Image

IMS can optionally template the contents of an IMS recipe before building the recipe with Kiwi-NG during an IMS `create` job. This
enables variables stored in the recipe to be dynamically replaced with values registered with the IMS recipe record after the
recipe is downloaded from S3, but before it is built by Kiwi-NG. This functionality is used by various Cray products to ensure
that the resulting image is built from the most correct release versions of Nexus-hosted RPM repositories.

Follow the steps below to enable IMS templating within a given recipe. Note that for IMS to properly template a recipe,
the following procedures must all be completed.

### Enable Templating in IMS Recipe Archive `tgz` File

1. Add a file named `.ims_recipe_template.yaml` to the root of the recipe archive.

   ``` bash
   ls -al
   ```

   Example output:

   ```text
   drwxr-xr-x 3 root root    70 Feb 22 19:05 .
   drwxr-xr-x 3 root root    41 Feb 22 17:18 ..
   -rw-r--r-- 1 root root  2744 Feb  4 21:14 config.sh
   -rw-r--r-- 1 root root 24645 Feb  4 21:15 config.xml
   -rw-r--r-- 1 root root  1216 Feb  4 21:14 images.sh
   -rw-r--r-- 1 root root    29 Feb  4 21:14 .ims_recipe_template.yaml
   drwxr-xr-x 3 root root    18 Feb  4 21:15 root
   ```

   The contents of this file must be valid YAML, containing the keyword `template_files`. The `template_files` keyword
   must contain a list of files to be templated within the image recipe archive.

   ``` bash
   cat .ims_recipe_template.yaml
   ```

   Example output:

   ```yaml
   template_files:
   - config.xml
   ```

   IMS will template the indicated files "in place" -- that is, the listed file will be replaced with the templated copy.
   **`NOTE`** Only files listed under the `template_files` key will be templated by IMS.

1. For each indicated file above, add appropriate Jinja2 variables where required to enable the results that are sought.
   In the example below, the Jinja2 variable `{{ CSM_RELEASE_VERSION }}` is used to help identify the fully qualified
   Nexus repository name/path to use when building the recipe.

   ```bash
   cat config.xml
   ```

   Excerpt of example output:

   ```xml
   <repository type="rpm-md" alias="csm-{{ CSM_RELEASE_VERSION }}-sle-{{ SLE_VERSION }}" priority="2" imageinclude="true">
       <source path="https://packages.local/repository/csm-{{ CSM_RELEASE_VERSION }}-sle-{{ SLE_VERSION}}/"/>
   </repository>
   ```

   **`NOTE`** The repository referenced above is for documentation purposes only and may not actually exist.

1. Create a `tgz` archive of the image recipe.

    ```bash
    ARTIFACT_FILENAME=recipe.tar.gz
    tar cvfz ../$ARTIFACT_FILE .
    cd ..
    ```

### Add Template Key/Value Pairs to IMS Recipe Record

1. (`ncn-mw#`) Create a new IMS recipe record with `template_dictionary` key/value pairs.

    ```bash
    cray ims recipes create --name "My Recipe" \
            --recipe-type kiwi-ng --linux-distribution sles15 \
            --template-dictionary-key CSM_RELEASE_VERSION \
            --template-dictionary-value 1.2.5 \
            --arch x86_64
    ```

    Example output:

    ```toml
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
    linux_distribution = "sles15"
    name = "my_recipe.tgz"
    recipe_type = "kiwi-ng"
    arch = "x86_64"
    require_dkms = false
    
    [[template_dictionary]]
    key = "CSM_RELEASE_VERSION"
    value = "1.2.5"
    key = "SLE_VERSION"
    value = "15sp4"
    ```

    Additional key/value pairs can be added by providing a list of comma-separated keys/values to the
    `--template-dictionary-key` and `--template-dictionary-value` parameters.

1. (`ncn-mw#`) Create a variable for the `id` value in the returned data.

    ```bash
    IMS_RECIPE_ID=2233c82a-5081-4f67-bec4-4b59a60017a6
    ```

1. (`ncn-mw#`) Upload the customized recipe to S3.

   It is suggested as a best practice that the S3 object name start with `recipes/` and contain the IMS recipe ID,
   in order to remove ambiguity.

   ```bash
   cray artifacts create ims recipes/$IMS_RECIPE_ID/$ARTIFACT_FILENAME $ARTIFACT_FILENAME
   ```

1. (`ncn-mw#`) Update the IMS recipe record with the S3 path to the recipe archive.

   ```bash
   cray ims recipes update $IMS_RECIPE_ID --link-type s3 \
           --link-path s3://ims/recipes/$IMS_RECIPE_ID/$ARTIFACT_FILENAME
   ```

   Example output:

   ```toml
   id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
   recipe_type = "kiwi-ng"
   linux_distribution = "sles15"
   name = "my_recipe.tgz"
   created = "2020-02-05T19:24:22.621448+00:00"
   arch = "x86_64"
   require_dkms = false

   [[template_dictionary]]
   key = "CSM_RELEASE_VERSION"
   value = "1.2.5"
   key = "SLE_VERSION"
   value = "15sp4
   
   [link]
   path = "s3://ims/recipes/2233c82a-5081-4f67-bec4-4b59a60017a6/recipe.tar.gz"
   etag = ""
   type = "s3"
   ```

### Build an Image from an IMS Templated Recipe

The procedure to build an image from an IMS recipe that uses templating does not change. Follow the normal IMS create
procedure, specifying the recipe's ID value in the job's `--artifact-id` parameter. The IMS job will start as normal,
but after downloading the recipe from S3, there will be an indication that IMS is templating the recipe in the job's
`fetch-recipe` container log.

```bash
kubectl -n ims logs cray-ims-812e9cda-62a8-4d1b-83a3-5891340671ff-create-78z6p -c fetch-recipe
```

Example output:

```text
INFO:/scripts/fetch.py:IMS_JOB_ID=812e9cda-62a8-4d1b-83a3-5891340671ff
INFO:/scripts/fetch.py:Setting job status to 'fetching_recipe'.
INFO:ims_python_helper:image_set_job_status: {{ims_job_id: 812e9cda-62a8-4d1b-83a3-5891340671ff, job_status: fetching_recipe}}
INFO:ims_python_helper:PATCH https://api-gw-service-nmn.local/apis/ims/jobs/812e9cda-62a8-4d1b-83a3-5891340671ff status=fetching_recipe
INFO:/scripts/fetch.py:Fetching recipe https://rgw-vip.nmn/ims/recipes/2233c82a-5081-4f67-bec4-4b59a60017a6/recipe.tar.gz?AWSAccessKeyId=DM1K003SPCSMLHX2Q1SF&Signature=FilGEvPFr0zx3aSA3dW9zrOuEow%3D&Expires=1645470297
/scripts/venv/lib/python3.8/site-packages/urllib3/connectionpool.py:979: InsecureRequestWarning: Unverified HTTPS request is being made to host 'rgw-vip.nmn'. Adding certificate verification is strongly advised. See: https://urllib3.readthedocs.io/en/latest/advanced-usage.html#ssl-warnings
  warnings.warn(
INFO:/scripts/fetch.py:Saving file as '/mnt/recipe/recipe.tgz'
INFO:/scripts/fetch.py:Verifying md5sum of the downloaded file.
INFO:/scripts/fetch.py:Successfully verified the md5sum of the downloaded file.
INFO:/scripts/fetch.py:Uncompressing recipe into /mnt/recipe
INFO:/scripts/fetch.py:Templating recipe
INFO:/scripts/fetch.py:Deleting compressed recipe /mnt/recipe/recipe.tgz
INFO:/scripts/fetch.py:Done
```

Note the third line from the bottom:

```text
INFO:/scripts/fetch.py:Templating recipe
```
