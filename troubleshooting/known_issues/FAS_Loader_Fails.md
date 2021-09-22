## FAS LOADER FAILS

**NOTE:** this procedure is only for csm-0.9.x releases.

The FAS loader may fail due to issues with the `repomd.xml` file in Nexus.
This will show up in the `fw-loader` job logs with the following message: `CRITICAL: Failed to get repomd.xml from repo`

You may first notice the issue if firmware is not present in the FAS image list (`cray fas images list`) after running the FAS loader or if a firmware update reports `failed to find file, trying again soon`

To view the FAS loader logs:

>Get the fas loader pod name:

>```bash
>    ncn# kubectl get pods -n services | awk 'NR == 1 || /fas-loader/'
>    NAME                      READY   STATUS      RESTARTS    AGE
>    cray-fas-loader-1-pnn6c 2/2 Running 2 9m38s
>```

>Check the logs dumped on screen using this command:

>```bash
>    ncn# kubectl logs -n services cray-fas-loader-1-pnn6c -c cray-fas-loader
>```

If you need to rerun the FAS loader use the following commands:

>Retrieve the job name. In the following example, the returned job name is cray-fas-loader-1, which is the job to rerun in this scenario.

>```bash
>    ncn# kubectl -n services get jobs | grep fas-loader
>    cray-fas-loader-1 1/1 3m11s 3d7h
>```

>Rerun the cray-fas-loader job. Note, after "-f" there is a "-".
Change `cray-fas-loader-1` to the loader job name returned from the last command

>```bash
>    ncn# kubectl -n services get job cray-fas-loader-1 -o json | jq 'del(.spec.selector)' \
>    | jq 'del(.spec.template.metadata.labels."controller-uid")' \
>    | kubectl replace --force -f -

>    job.batch "cray-fas-loader-1" deleted
>    job.batch/cray-fas-loader-1 replaced
>```

>Make sure the FAS Loader job is complete. Depending on the number of images in FAS, this could take 5-7 minutes.

>```bash
>    ncn# kubectl -n services get jobs | awk 'NR == 1 || /fas-loader/'
>    NAME                  COMPLETIONS   DURATION    AGE
>    cray-fas-loader-1         1/1        7m35s     7m35s
>```

>Check the logs using the command above.

### Solution:

To correct the `repomd.xml` file issue, you will need to delete the `shasta-firmware-0.9.3` repo from nexus and rerun the install script.

>```bash
>  ncn# curl -sfkSL -X DELETE  https://packages.local/service/rest/beta/repositories/shasta-firmware-0.9.3
>  ncn# ./install.sh
>```

>Rerun the FAS Loader job using the commands above
