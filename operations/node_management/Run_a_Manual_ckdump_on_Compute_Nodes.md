## Run a Manual ckdump on Compute Nodes

If a crashed node is not recognized by NMD, but the node is crashed and the network is initialized, run ckdump manually to upload the node dump.

The crashed node requires a working spire-agent to communicate with NMD. However, sometimes restarting spire-agent on the dump capture boot fails. When the spire-agent restart on the crashed node fails, it cannot access NMD through the API gateway and it cannot be dumped using NMD. When this happens, assuming that the network for the node is working, the ckdump\_helper program can be run manually with the serial console to capture a node dump. The dump taken with this manual dump will show up when running cray nmd dumps describe <request-uuid\>, and the System Dump Utility \(SDU\) can collect the manual dump along with the other NMD dumps.

### Prerequisites

-   The crashed node is running ckdump\_helper version 2.4.2 or newer.
-   Not necessary, but if Node Memory Dump \(NMD\) has manual dump support, it makes things much simpler. Manual dump support is included in release 1.4.1, with docker image 2.4.6 and COS 2.0.30. If it is not running the supported version, restarting NMD will pick up the dumps taken manually.

### Procedure

1.  Verify that NMD cannot communicate with the crashed node.

    Even though the node is crashed, look for the "Error: Data not found..." response to validate NMD cannot communicate with the node.

    ```bash
    ncn-m001# cray nmd status describe XNAME
    ```

2.  Access the node console through ConMan and check for the spire-agent error.

    1.  Retrieve the ConMan pod ID.

        ```bash
        ncn-m001# CONPOD=$(kubectl get pods -n services \
        -o wide|grep cray-conman|awk '{print $1}')
        ncn-m001# echo $CONPOD
        cray-conman-77fdfc9f66-m2s9k
        ```

    2.  Log in to the cray-conman pod.

        ```bash
        ncn-m001# kubectl exec -it -n services $CONPOD /bin/bash
        ```

    3.  Use the node ID to connect to the node's Serial Over Lan \(SOL\).

        ```bash
        [root@cray-conman-POD_ID app]# conman -j NODE_ID
        <ConMan> Connection to console [x3000c0s25b1] opened.
        nid000009 login:
        ```

        **Troubleshooting:** If the login prompt is not there, type **Ctrl-C** to get the command prompt.

    4.  Validate the network is working on the node.

        The following command is one way to check:

        ```bash
        # ip addr show
        ```

3.  Create a manual dump data file with S3 access and dump the requested JSON data on an NCN.

    Storing the required S3 access information in a file is not required, but it will make it easier to import the JSON string in the run\_manual\_ckdump.sh script that is run in a future step.

    The following values are required to create a manual dump data file with S3 access. The values flagged as "Required" must be provided.

    -   `AccessKey`: S3 access key \(Required\).

        Retrieve this value on the NMD pod at /conf/creds/access\_key, or with the following command:

        ```bash
        ncn-m001# kubectl get secrets -o yaml nmd-s3-credentials \
        -ojsonpath='{.data.access_key}' | base64 -d
        ```

    -   `SecretKey`: S3 secret key \(Required\).

        Retrieve this value on the NMD pod at /conf/creds/secret\_key, or with the following command:

        ```bash
        ncn-m001# kubectl get secrets -o yaml nmd-s3-credentials \
        -ojsonpath='{.data.secret_key}' | base64 -d
        ```

    -   `EndpointUrl`: S3 endpoint URL.

        The URL is typically https://rgw-vip.nmn. Exec into the NMD pod and verify the value in /conf/creds/s3\_endpoint.

    -   `BucketName`: S3 bucket name.

        This value will be "nmd".

    -   RequestID: the uuid value \(Required\).

        Create this value using the uuidgen command on an NCN.

    These values will not show up in a log. The ConMan \(serial console\) will log everything being entered. The following is an example of the JSON data:

    ```bash
    { "AccessKey": "VO5ZT4NNS0Y5QGSQ9QD5", "SecretKey": "V5nq7BTGZmNNeE6cJxuRR3RMM8vuvjnpLzeHi3Pp", "EndpointUrl": "https://rgw-vip.nmn", "BucketName": "nmd", "RequestId": "cc97af84-b538-49cf-b585-9b5e7b03a83c" }
    ```

4.  Run the manual dump with the following script by creating the run\_manual\_ckdump.sh through the serial console.

    1.  Create the run\_manual\_ckdump.sh script.

        "stty -echo" in the script hides the JSON S3 data that must be provided to the ckdump\_helper so that it does not appear in the logs.

        ```bash
        :/root# cat >run_manual_ckdump.sh
        #!/bin/bash
        if [[ $# -lt 1 ]]
        then
            echo "need xname"
            exit 1
        fi
        xname=$1
        data_file="./data.json"
        # makedumpfile dump level:  Example
        # 16 : Exclude the free pages. Keeps user data and files etc
        # 31 : Exclude all.  This is the NMD default
        dump_level=31
        # default 8388608
        chunk_size=$((1<<23))
        # time format: "2021-03-16T00:05:18+00:00
        timestamp=$(date "+%FT%H:%M:%S+00:00")
        # api-gw
        api_gw=https://api-gw-service-nmn.local
         
        echo "Enter data"
        stty_orig=$(stty -g)
        stty -echo
        read -s data
        echo $data >$data_file
        stty $stty_orig
         
        echo "run manual dump"
        echo "/usr/sbin/ckdump_helper -api-gw $api_gw -timestamp $timestamp -s3-chunk-size $chunk_size -xname $xname -manual-dump ./data.json -dump-level $dump_level"
        /usr/sbin/ckdump_helper -api-gw $api_gw -timestamp "$timestamp" -s3-chunk-size $chunk_size -xname $xname -manual-dump ./data.json -dump-level $dump_level
        ```

    2.  Update the permissions for the script.

        ```bash
        :/root# chmod -x run_manual_ckdump.sh
        ```

    3.  Run the manual dump for the compute node.

        Give the S3 access and dump data from step [3](#step_jgm_qhg_dpb) as a single-line string, and press **enter** so that "read -s data" in the script can get all input and create a valid JSON file.

        ```bash
        :/root# ./run_manual_ckdump.sh x3000c0s17b3n0
        Enter data   <<-- NOTE: A single line json data string for S3 access and dump data.
        run manual dump
        /usr/sbin/ckdump_helper -api-gw https://api-gw-service-nmn.local -timestamp 2021-03-25T13:09:42+00:00 -s3-chunk-size 8388608 -xname x3000c0s19b1n0 -manual-dump ./data.json -dump-level 31
        ...
        2021/03/25 13:10:00 Uploaded part  28  of size  8388608
        2021/03/25 13:10:00 progress:  48
        2021/03/25 13:10:01 NewNmdS3Config() set https://rgw-vip.nmn WithDisableSSL(false)
        2021/03/25 13:10:01 Uploaded part  29  of size  2225904
        2021/03/25 13:10:01 progress:  49
        2021/03/25 13:10:01 progress:  50
        2021/03/25 13:10:01 2021/03/25/13/09/42/cc97af84-b538-49cf-b585-9b5e7b03a83c/x3000c0s19b1n0/x3000c0s19b1n0-cc97af84-b538-49cf-b585-9b5e7b03a83c.ckdump  Success:  {
          Bucket: "nmd",
          ETag: "ab7573f0e9ee97c27a4aa79ab45e5ec2-29",
          Key: "2021/03/25/13/09/42/cc97af84-b538-49cf-b585-9b5e7b03a83c/x3000c0s19b1n0/x3000c0s19b1n0-cc97af84-b538-49cf-b585-9b5e7b03a83c.ckdump",
          Location: "http://rgw-vip.nmn/nmd/2021/03/25/13/09/42/cc97af84-b538-49cf-b585-9b5e7b03a83c/x3000c0s19b1n0/x3000c0s19b1n0-cc97af84-b538-49cf-b585-9b5e7b03a83c.ckdump"
        }
        Bytes:  237106928
        Chunks:  29
        ...
        ```

5.  Exit the connection to the console with the `&.` command.

6.  Exit the ConMan pod.

    ```bash
    [root@cray-conman-POD_ID app]# exit
    ncn-m001#
    ```

