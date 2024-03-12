# IUF Error: 'exec /usr/local/bin/argoexec: argument list too long'

Follow this procedure if an IUF step fails with the error: `exec /usr/local/bin/argoexec: argument list too long`.

1. Get the name of the template that failed. For example, in the error below the `s3-upload` template failed.

    ```bash
    2024-03-11T20:40:54.348210Z INFO [cpe-23-12-3-s3-upload          ] BEG s3-upload(0)
    2024-03-11T20:40:55.385227Z DBG  [cpe-23-12-3-s3-upload          ]       2024-03-11T20:40:54.569036586Z exec /usr/local/bin/argoexec: argument list too long
    2024-03-11T20:41:03.980113Z ERR  [cpe-23-12-3-s3-upload          ] END s3-upload(0) [Failed]
    ```

1. This error is due to the script in that template being too long. This can be fixed by not echoing 
'{{inputs.parameters.global_params}}' in the template. Instead, write `global_params` to a file and then
reference the file.

    1. `(ncn-m001#)` Navigate to where the workflow templates files are located.

        ```bash
        cd /usr/share/doc/csm/workflows/iuf/operations/
        ```

    1. `(ncn-m001#)` Edit the template where this error occured in the following way.

        1. Search for where `echo '{{inputs.parameters.global_params}}'` is in the template. Below is an example of how it is used.

            ```bash
            CONTENT=$(echo '{{inputs.parameters.global_params}}' | jq -r '.product_manifest.current_product.manifest')
            PARENT_DIR=$(echo '{{inputs.parameters.global_params}}' | jq -r '.stage_params."process-media".current_product.parent_directory')
            ```

        1. Before the first line containing `echo '{{inputs.parameters.global_params}}'`, echo `global_params` to a file.

            ```bash
            echo '{{inputs.parameters.global_params}}' > global.params.data
            ```

        1. Replace all instances of `echo '{{inputs.parameters.global_params}}'` with `cat global.params.data`.

        1. Save the file and update the argo templates by running the following command.

            ```bash
            /usr/share/doc/csm/workflows/scripts/upload-rebuild-templates.sh
            ```

## Example of editing a template

If the error happened in the `s3-upload` step, then edit the `/usr/share/doc/csm/workflows/iuf/operations/s3-upload/s3-upload-template.yaml`.

Before making changes, the template will have the following script content. 

```bash
...
- - name: s3-upload
      templateRef:
        name: iuf-base-template
        template: shell-script
      arguments:
        parameters:
          - name: dryRun
            value: false
          - name: scriptContent
            value: |
              CONTENT=$(echo '{{inputs.parameters.global_params}}' | jq -r '.product_manifest.current_product.manifest')
              PARENT_DIR=$(echo '{{inputs.parameters.global_params}}' | jq -r '.stage_params."process-media".current_product.parent_directory')
              PRODUCT=$(echo '{{inputs.parameters.global_params}}' | jq -r '.product_manifest.current_product.manifest.name')
              VERSION=$(echo '{{inputs.parameters.global_params}}' | jq -r '.product_manifest.current_product.manifest.version')
              ...
```

After making the changes above, the resulting template should have the following script content.

```bash
...
- - name: s3-upload
      templateRef:
        name: iuf-base-template
        template: shell-script
      arguments:
        parameters:
          - name: dryRun
            value: false
          - name: scriptContent
            value: |
              echo '{{inputs.parameters.global_params}}' > global.params.data
              CONTENT=$(cat global.params.data | jq -r '.product_manifest.current_product.manifest')
              PARENT_DIR=$(cat global.params.data | jq -r '.stage_params."process-media".current_product.parent_directory')
              PRODUCT=$(cat global.params.data | jq -r '.product_manifest.current_product.manifest.name')
              VERSION=$(cat global.params.data | jq -r '.product_manifest.current_product.manifest.version')
              ...
```
