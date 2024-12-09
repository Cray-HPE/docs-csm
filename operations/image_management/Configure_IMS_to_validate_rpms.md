# Configure IMS to Validate RPMs

Configuring the Image Management Service (IMS) to validate the GPG signatures of RPMs during IMS Build operations involves the following two steps:

1. Create and update IMS to use a new Kiwi-NG Image with the Signing Keys embedded.

   > **`NOTE`** The default IMS Kiwi-NG Image is already configured with the signing keys needed to
   validate HPE and SuSE RPMs and repositories.

2. Update IMS Recipes to require GPG verification of RPMs, repositories, or both.

## Create and Update IMS to Use a New Kiwi-NG Image with an Embedded Signing Key

1. (`ncn-mw#`) Create a temporary directory to perform the actions necessary to configure IMS to validate
   RPM signatures.

    ```bash
    mkdir ims-validate
    cd ims-validate/
    ```

1. (`ncn-mw#`) Determine the container version for the IMS Kiwi-NG container.

   ```bash
   kubectl -n services get cm cray-configmap-ims-v2-image-create-kiwi-ng -o yaml | grep cray-ims-kiwi-ng-opensuse-x86_64-builder
   ```

   Example output:

   ```yaml
        - image: artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:1.7.0
            value: "artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:1.7.0"
   ```

   If successful, make note of the version of the listed container. In this case, the version is `1.7.0`.
   Create an environment variable for this value.

    ```bash
    export KIWI_VERSION=1.7.0
    ```

1. (`ncn-mw#`) Create a file containing the public portion of the Signing Key to be added to the IMS Kiwi-NG image.

    ```bash
    cat my-signing-key.asc
    -----BEGIN PGP PUBLIC KEY BLOCK-----
    ...
    -----END PGP PUBLIC KEY BLOCK-----
    ```

1. (`ncn-mw#`) Obtain a copy of the `entrypoint.sh` script from `cray-ims-kiwi-ng-opensuse-x86_64-builder`.

   ```bash
   podman run -it --entrypoint "" --rm registry.local/artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:${KIWI_VERSION} cat /scripts/entrypoint.sh | tee entrypoint.sh
   ```

1. (`ncn-mw#`) Set the correct permissions on the script file.

    ```bash
   chmod 755 entrypoint.sh
   ```

    Verify the correct permissions:

    ```bash
    ls -la entrypoint.sh
    ```

    Expected output:

    ```text
    -rwxr-xr-x 1 root root 8955 Jul 24 15:27 entrypoint.sh
    ```

1. (`ncn-mw#`) Modify the `entrypoint.sh` script to pass the signing key to the `kiwi-ng` command.

    ```bash
    cat entrypoint.sh
    ```

    Example output:

    ```text
    [...]

    # Call kiwi to build the image recipe. Note that the command line --add-bootstrap-package
    # causes kiwi to install the cray-ca-cert RPM into the image root.
    kiwi-ng $DEBUG_FLAGS --logfile=$PARAMETER_FILE_KIWI_LOGFILE --type tbz system build --description $RECIPE_ROOT_PARENT \
    --target $IMAGE_ROOT_PARENT --add-bootstrap-package file:///mnt/ca-rpm/cray_ca_cert-1.0.1-1.x86_64.rpm \
    --signing-key /signing-keys/my-signing-key.asc   # <--- ADD SIGNING-KEY FILE

    [...]
    ```

1. (`ncn-mw#`) (CSM 1.5.0 and later) Obtain a copy of the `armentry.sh` script from `cray-ims-kiwi-ng-opensuse-x86_64-builder`.

   ```bash
   podman run -it --entrypoint "" --rm registry.local/artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:${KIWI_VERSION} cat /scripts/armentry.sh | tee armentry.sh
   ```

1. (`ncn-mw#`) (CSM 1.5.0 and later) Set the correct permissions on the script file.

    ```bash
   chmod 755 armentry.sh
   ```

    Verify the correct permissions:

    ```bash
    ls -la armentry.sh
    ```

    Expected output:

    ```text
    -rwxr-xr-x 1 root root 8955 Jul 24 15:27 armentry.sh
    ```

1. (`ncn-mw#`) (CSM 1.5.0 and later) Modify the `armentry.sh` script to pass the signing key to the `kiwi-ng` command.

    ```bash
    cat armentry.sh
    ```

    Example output:

    ```text
    [...]

    # Call kiwi to build the image recipe. Note that the command line --add-bootstrap-package
    # causes kiwi to install the cray-ca-cert RPM into the image root.
    kiwi-ng $DEBUG_FLAGS --logfile=$PARAMETER_FILE_KIWI_LOGFILE --type tbz system build --description $RECIPE_ROOT_PARENT \
    --target $IMAGE_ROOT_PARENT --add-bootstrap-package file:///mnt/ca-rpm/cray_ca_cert-1.0.1-1.x86_64.rpm \
    --signing-key /signing-keys/my-signing-key.asc   # <--- ADD SIGNING-KEY FILE

    [...]
    ```

1. (`ncn-mw#`) (CSM 1.5.2 and later) Obtain a copy of the `remote_build_entrypoint.sh` script from `cray-ims-kiwi-ng-opensuse-x86_64-builder`.

   ```bash
   podman run -it --entrypoint "" --rm registry.local/artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:${KIWI_VERSION} cat /scripts/remote_build_entrypoint.sh | tee remote_build_entrypoint.sh
   ```

1. (`ncn-mw#`) (CSM 1.5.2 and later) Set the correct permissions on the script file.

    ```bash
   chmod 755 remote_build_entrypoint.sh
   ```

    Verify the correct permissions:

    ```bash
    ls -la remote_build_entrypoint.sh
    ```

    Expected output:

    ```text
    -rwxr-xr-x 1 root root 8955 Jul 24 15:27 remote_build_entrypoint.sh
    ```

1. (`ncn-mw#`) (CSM 1.5.2 and later) Modify the `remote_build_entrypoint.sh` script to pass the signing key to the `kiwi-ng` command.

    ```bash
    cat remote_build_entrypoint.sh
    ```

    Example output:

    ```text
    [...]

    # Call kiwi to build the image recipe. Note that the command line --add-bootstrap-package
    # causes kiwi to install the cray-ca-cert RPM into the image root.
    kiwi-ng $DEBUG_FLAGS --logfile=$PARAMETER_FILE_KIWI_LOGFILE --type tbz system build --description $RECIPE_ROOT_PARENT \
    --target $IMAGE_ROOT_PARENT --add-bootstrap-package file:///mnt/ca-rpm/cray_ca_cert-1.0.1-1.x86_64.rpm \
    --signing-key /signing-keys/my-signing-key.asc   # <--- ADD SIGNING-KEY FILE

    [...]
    ```

1. (`ncn-mw#`) Create a `Dockerfile` to create a new `cray-ims-kiwi-ng-opensuse-x86_64-builder` image.

    ```text
    FROM registry.local/artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:${KIWI_VERSION}

    RUN mkdir -p /signing-keys
    COPY my-signing-key.asc /signing-keys

    COPY entrypoint.sh /scripts/entrypoint.sh
    RUN sed -i -e 's/\r$//' /scripts/entrypoint.sh

    # ONLY for CSM 1.5.0 and later
    COPY armentry.sh /scripts/armentry.sh
    RUN sed -i -e 's/\r$//' /scripts/armentry.sh

    # ONLY for CSM 1.5.2 and later
    COPY remote_build_entrypoint.sh /scripts/remote_build_entrypoint.sh
    RUN sed -i -e 's/\r$//' /scripts/remote_build_entrypoint.sh

    ENTRYPOINT ["/scripts/entrypoint.sh"]
    ```

    > **`NOTE`** Make sure that the version of the `cray-ims-kiwi-ng-opensuse-x86_64-builder`
    image in the `FROM` line matches the version of the image above.

1. (`ncn-mw#`) Verify that the following files are in the temporary directory.

    ```text
    Dockerfile  entrypoint.sh  my-signing-key.asc
    ```

1. (`ncn-mw#`) (CSM 1.5.0 and later) Verify that the following file is in the temporary directory.

    ```text
    armentry.sh
    ```

1. (`ncn-mw#`) (CSM 1.5.2 and later) Verify that the following file is in the temporary directory.

    ```text
    remote_build_entrypoint.sh
    ```

1. (`ncn-mw#`) (CSM 1.5.0 and later with aarch64 hardware) Install QEMU emulation software.

    For cross compiling aarch64 images, QEMU emulation software must be installed on the
    node where this operation is taking place. If QEMU is already installed this step may
    be skipped.

    1. Download and install the QEMU emulation package.

        ```bash
        wget https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-aarch64-static
        mv ./qemu-aarch64-static /usr/bin/qemu-aarch64-static
        chmod +x /usr/bin/qemu-aarch64-static
        ```

    1. Set up `binfmt_misc` for handling emulation.

        ```bash
        if [ ! -d /proc/sys/fs/binfmt_misc ] ; then
            echo "- binfmt_misc does not appear to be loaded or isn't built in."
            echo "  Trying to load it..."
            if ! modprobe binfmt_misc ; then
                echo "FATAL: Unable to load binfmt_misc"
                exit 1;
            fi
        fi
        ```

    1. Mount the emulation file system.

        ```bash
        if [ ! -f /proc/sys/fs/binfmt_misc/register ] ; then
            echo "- The binfmt_misc filesystem does not appear to be mounted."
            echo "  Trying to mount it..."
            if ! mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc ; then
                echo "FATAL:  Unable to mount binfmt_misc filesystem."
                exit 1
            fi
        fi
        ```

    1. Register QEMU for aarch64 emulation.

        ```bash
        if [ ! -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ] ; then
            echo "- Setting up QEMU for ARM64"
            echo ":qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F" >> /proc/sys/fs/binfmt_misc/register
        fi
        ```

1. (`ncn-mw#`) Using the `podman` command, build and tag a new `cray-ims-kiwi-ng-opensuse-x86_64-builder` image.

    For versions prior to CSM 1.5.0 or for systems with only `x86_64` hardware, use the following command:

    ```bash
    podman build -t registry.local/artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:${KIWI_VERSION}-validate .
    ```

    For CSM 1.5.0 or later and systems that include aarch64 hardware, use the following command:

    ```bash
    podman buildx build --platform=linux/amd64,linux/arm64 -t registry.local/artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:${KIWI_VERSION}-validate .
    ```

    Expected output:

    ```text
    STEP 1: FROM registry.local/artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:1.7.0
    STEP 2: RUN mkdir /signing-keys
    --> Using cache 5d64aadcffd3f9f8f112cca75b886cecfccbfe903d4b0d4176882f0e78ccd4d0
    --> 5d64aadcffd
    STEP 3: COPY my-signing-key.asc /signing-keys
    --> Using cache c10ffb877529bdbe855522af93827503f76d415e2e129d171a7fc927f896095a
    --> c10ffb87752
    STEP 4: COPY entrypoint.sh /scripts/entrypoint.sh
    --> Using cache 6e388b60f42b6cd26df65ec1798ad771bdb835267126f16aa86e90aec78b0f32
    --> 6e388b60f42
    STEP 5: ENTRYPOINT ["/scripts/entrypoint.sh"]
    --> Using cache 46c78827eb62c66c9f42aeba12333281b073dcc80212c4547c8cc806fe5519b3
    STEP 6: COMMIT registry.local/artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:1.7.0-validate
    --> 46c78827eb6
    46c78827eb62c66c9f42aeba12333281b073dcc80212c4547c8cc806fe5519b3
    ```

1. (`ncn-mw#`) Obtain Nexus credentials.

    ```bash
    NEXUS_USERNAME="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.username}} | base64 -d)"
    NEXUS_PASSWORD="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.password}} | base64 -d)"
    ```

1. (`ncn-mw#`) Push the new image to the Nexus image registry.

    ```bash
    podman push registry.local/artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:${KIWI_VERSION}-validate --creds="$NEXUS_USERNAME:$NEXUS_PASSWORD"
    ```

1. (`ncn-mw#`) Update the IMS `cray-configmap-ims-v2-image-create-kiwi-ng` ConfigMap to use this new image.

    ```bash
    kubectl -n services edit cm cray-configmap-ims-v2-image-create-kiwi-ng
    ```

    Example output:

    ```text
    [...]

    - image: cray/cray-ims-kiwi-ng-opensuse-x86_64-builder:1.7.0-validate

    [...]
    ```

   > **`NOTE`** It may take several minutes for this change to take effect. Restarting IMS is not necessary.

1. (`ncn-mw#`) Cleanup and remove the temporary directory

    ```bash
    cd ..
    rm -rfv ims-validate/
    ```

## Update IMS Recipes to Require GPG Verification of RPMs/Repos

1. (`ncn-mw#`) List the IMS recipes and determine which recipes need to be updated.

    ```bash
    cray ims recipes list --format json
    ```

    Example output:

    ```json
    [

      ...

      {
        "created": "2021-06-29T21:50:38.319526+00:00",
        "id": "1aab3dbb-a654-4c84-b820-a293bd4ab2b4",
        "link": {
          "etag": "",
          "path": "s3://ims/recipes/1aab3dbb-a654-4c84-b820-a293bd4ab2b4/my_recipe.tgz",
          "type": "s3"
        },
        "linux_distribution": "sles15",
        "name": "cos-2.1.51-slingshot-1.2.1",
        "recipe_type": "kiwi-ng"
      },

      ...

    ]
    ```

1. (`ncn-mw#`) Download the recipe archive for any recipe that will be updated.

    ```bash
    cray artifacts get ims recipes/1aab3dbb-a654-4c84-b820-a293bd4ab2b4/recipe.tar.gz recipe.tar.gz
    ```

1. (`ncn-mw#`) Uncompress the recipe archive into a temporary directory.

    ```bash
    mkdir -v recipe
    tar xvfz recipe.tar.gz -C recipe/
    cd recipe/
    ```

1. Modify the recipe's `config.xml` file and enable GPG validation on any repos that should be validated.
   To validate each package's GPG signature, add `package_gpgcheck="true"`. To validate the repository signature,
   add `repository_gpgcheck="true"`.

    ```xml
    <repository type="rpm-md" alias="..." priority="2" imageinclude="true" package_gpgcheck="true">
        ...
    </repository>
    <repository type="rpm-md" alias="..." priority="2" imageinclude="true" repository_gpgcheck="true">
        ...
    </repository>
    ```

1. (`ncn-mw#`) Create a new recipe tar file.

    ```bash
    tar cvfz ../recipe-new.tgz .
    ```

1. (`ncn-mw#`) Move to the parent directory.

   ```bash
   cd ..
   ```

1. (`ncn-mw#`) Create a new IMS recipe record.

    ```bash
    cray ims recipes create --name "My Recipe" \
         --recipe-type kiwi-ng --linux-distribution sles15
    ```

    Example output:

    ```text
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
    linux_distribution = "sles15"
    name = "my_recipe.tgz"
    recipe_type = "kiwi-ng"
    ```

    If successful, create a variable for the `id` value in the returned data.

    ```bash
    IMS_RECIPE_ID=2233c82a-5081-4f67-bec4-4b59a60017a6
    ```

1. (`ncn-mw#`) Upload the customized recipe to S3.

    It is suggested as a best practice that the S3 object name start with `recipes/` and contain the IMS recipe ID to remove ambiguity.

    ```bash
    cray artifacts create ims recipes/$IMS_RECIPE_ID/recipe.tgz recipe-new.tgz
    ```

1. (`ncn-mw#`) Update the IMS recipe record with the S3 path to the recipe archive.

    ```bash
    cray ims recipes update $IMS_RECIPE_ID \
              --link-type s3 \
              --link-path s3://ims/recipes/$IMS_RECIPE_ID/recipe.tgz
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

1. (`ncn-mw#`) Cleanup and remove the temporary directory.

    ```bash
    cd ..
    rm -rf recipe/
    ```
