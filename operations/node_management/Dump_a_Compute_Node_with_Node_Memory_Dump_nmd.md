## Dump a Compute Node with Node Memory Dump \(NMD\)

This procedure describes how to generate a remote node memory dump using the nmd command to help debug compute node crashes. Note that before nmd can be used on a compute node that has crashed, the node's dump-capture kernel must be booted.

The NMD service includes the following features:

-   Provides concurrent dump capability.
-   Controls automated kdump so that the dump is generated only for the requested nodes.
-   Provides a configurable makedumpfile dump level option for the selected node at dump time, which contrasts with kdump, where this is a preconfigured option that cannot be changed when the node goes down.
    -   Use the dumplevel argument of the makedumpfile command to specify makedumpfile's dump level, which is 31 by default. Use 16 if it is required to retrieve user process core dump \(user data pages\) or none-private cache pages.

Cray recommends keeping nmd enabled. In cases where this service is not needed, rather than disabling the service, remove the `crashkernel=360M` kernel parameter from BSS for the node\(s\) in question. This will prevent kdump from running and will free up that reserved kernel memory to be used for system RAM. The `cray nmd` command is used to manage compute node memory dumps on the system. For more information about the NMD Cray CLI commands, use the `--help` option with any of the cray nmd commands.

The expected states of a node memory dump are described below:

-   **waiting**

    The node is crashed and the dump capture kernel is booted to run the kdump service.

-   **dump**

    A node memory dump was requested and is in the process of getting dumped. While in this state, the progress percentage of the dump will increase.

-   **done**

    The node memory dump is finished. This state occurs before the status data in NMD gets deleted.

-   **error**

    The node memory dump failed. NMD will be in this state until the next dump is requested or the state gets removed with the cray nmd status delete command.

-   **cancel**

    The node memory dump is cancelled via the cray nmd dumps delete --force XNAME command.

### Prerequisites

-   The Boot Script Service \(BSS\) is running in one or more pods in the Kubernetes cluster.
-   The `crashkernel=360M` boot parameter has been added to BSS for the compute node.
-   The `kdump` service customized for the NMD is enabled in the compute node image. It is enabled while the image is getting customized via the Configuration Framework Service \(CFS\).
-   Cray kdump helper \(ckdump-helper\) for NMD is enabled.
-   A compute node has crashed or an admin has triggered a node crash.
-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Limitations

    Limitations inherent to kdump that are not imposed by Cray:

    -   In order to reboot into dump-capture kernel, dump-capture kernel needs to be loaded into memory by the kdump service with nmd's support, while the node is initially booting. Therefore, the node will not be in a dumpable state if the node has not booted far enough and the kdump service has not yet started up.
    -   Because kdump has to boot into a dump-capture kernel, it cannot do a live node dump.

### Procedure

1.  Ensure that the compute node is ready for nmd to be invoked.

    Choose one of the following, depending on whether this is an unexpected node crash or a node crash is to be triggered for testing or other purpose.

    -   To determine the readiness of a node that has unexpectedly crashed, run the following command:

        ```bash
        ncn-w001# cray nmd status describe XNAME
        hbrate = 120
        progress = 0
        state = "waiting"
        timestamp = "2020-03-02T17:25:53.253230-06:00"
        heartbeat = "2020-03-02T23:25:53.268386+00:00"
        bosid = "NA"
        endpoint_url = "http://rgw.local:8080"
        ```

        Look at the state field in the returned output to determine the readiness of the node. Refer to the introductory text above for more information on the meaning of each state.

        The node memory dump is done when the kdump service finishes. The node dump status entry gets removed and starts showing the following message:

        ```bash
        ncn-w001# cray nmd status describe XNAME
        Usage: cray nmd status describe [OPTIONS] XNAME
        Try 'cray nmd status describe --help' for help.Error: Data not found: status_xname_get: xname=x3000c0s19b3n0 not found
        ```

    -   To trigger a node crash and then determine its readiness for nmd, set up a serial-over-LAN connection to the node, trigger a crash, and then monitor its console log. For more information about setting up a serial-over-LAN connection to the node, refer to "Log in to a Node Using ConMan" in the *HPE Cray EX System Administration Guide S-8001*.

        Execute the following to trigger a node crash:

        ```bash
        x0c0s18b0n0# echo c >/proc/sysrq-trigger
        ```

        The following key sequences trigger a crash dump for non-responsive nodes:

        -   Use either the ConMan or ipmitool key sequences for Air Cooled NCNs and compute nodes:

            ```bash
            conman: &B<action>
            ipmitool: ~~B<action>
            ```

            The <action\> variable in the commands above represents one of the many SysRq options.

        -   Connect through the node controller \(nC\) serial console to trigger a crash dump for Liquid Cooled compute nodes:

            ```bash
            ctrl-a ctrl-b <action>
            ```

2.  Request a node dump.

    ```bash
    ncn-w001# cray nmd dumps create --xname XNAME
    requestID = "bf6afadf-5cdf-11ea-b9d2-76b3ec213338" <<-- Note this ID
    
    [info]
    created = "2020-03-02T23:44:24.714431+00:00"
    image = "NA"
    bosid = "NA"
    state = "dump"
    requestid = "bf6afadf-5cdf-11ea-b9d2-76b3ec213338"
    objectkeys = [ "2020/03/02/23/44/24/bf6afadf-5cdf-11ea-b9d2-76b3ec213338/x3000c0s7b0n0/x3000c0s7b0n0-bf6afadf-5cdf-11ea-b9d2-76b3ec213338.dump-config", "2020/03/02/23/44/24/bf6afadf-5cdf-11ea-b9d2-76b3ec213338/x3000c0s7b0n0/x3000c0s7b0n0-bf6afadf-5cdf-11ea-b9d2-76b3ec213338.dump-info",]
    xname = "x3000c0s7b0n0"
    ```

    The request ID can be retrieved from the request output. Use the returned request ID to retrieve the current dump state.

    **Troubleshooting information**:

    -   Normally, the dump-capture boot process takes about 1-2 minutes after the node crashes. If the dump-capture kernel did not boot for some reason, or the dump-capture is not fully booted, the node may not be in a dumpable state. When this happens, the system will return an error similar to the following:

        ```bash
        ncn-w001# cray nmd dumps create --xname x0c0s21b0n0 --sysrestart halt
        Usage: cray nmd dumps create [OPTIONS]
        Try "cray nmd dumps create --help" for help.Error: 
         
        Error: Dump State Error: dumps_post req_data=
        
        {'dumplevel': 31, 'requestid': '303f2217-5ce0-11ea-9b2f-76b3ec213338', 'sysrestart': 'halt', 'xname': 'x3000c0s7b0n0'}
        failed: request ID is 25d39f21-5ce0-11ea-8119-76b3ec213338 and dump state is dump
        ```

        If this error is returned, make sure that the dump-capture kernel has fully booted.

    -   At times, the node may crash and go into a state that prevents it from booting into the dump-capture kernel. If this happens, check the console output to make sure that the node rebooted into the dump-capture kernel. for more information, refer to [Access Compute Node Logs](../conman/Access_Compute_Node_Logs.md). The following output indicates that the node has successfully booted and the node memory dump is ready to run:

        ```bash
        API Gateway is https://api-gw-service-nmn.local
        xname is x3000c0s7b0n0
        kdump starting
        ```

3.  Request a dump status using the request ID retrieved.

    In the following examples, it is assumed that the request ID is `413d8311-c6bf-4a7e-9e36-0364e660f7b3`.

    ```bash
    ncn-w001# cray nmd dumps describe REQUEST_ID
    requestID = "f74f6b54-5ce0-11ea-a861-76b3ec213338"
    
    [info]
    created = "2020-03-02T23:53:07.982937+00:00"
    image = "NA"
    bosid = "NA"
    state = "dump"
    requestid = "f74f6b54-5ce0-11ea-a861-76b3ec213338"
    objectkeys = [ "2020/03/02/23/53/07/f74f6b54-5ce0-11ea-a861-76b3ec213338/x3000c0s7b0n0/x3000c0s7b0n0-f74f6b54-5ce0-11ea-a861-76b3ec213338.dump-config", "2020/03/02/23/53/07/f74f6b54-5ce0-11ea-a861-76b3ec213338/x3000c0s7b0n0/x3000c0s7b0n0-f74f6b54-5ce0-11ea-a861-76b3ec213338.dump-info",]
    xname = "x3000c0s7b0n0"
    ```

4.  Wait for the dump state to change from `dump` to `done`.

5.  Verify that the state has changed to `done`.

    ```bash
    ncn-w001# cray nmd dumps describe REQUEST_ID
    requestID = "f74f6b54-5ce0-11ea-a861-76b3ec213338"
    
    [info]
    created = "2020-03-02T23:53:07.982937+00:00"
    image = "NA"
    bosid = "NA"
    state = "done"
    requestid = "f74f6b54-5ce0-11ea-a861-76b3ec213338"
    objectkeys = [ "2020/03/02/23/53/07/f74f6b54-5ce0-11ea-a861-76b3ec213338/x3000c0s7b0n0/x3000c0s7b0n0-f74f6b54-5ce0-11ea-a861-76b3ec213338.dump-config", "2020/03/02/23/53/07/f74f6b54-5ce0-11ea-a861-76b3ec213338/x3000c0s7b0n0/x3000c0s7b0n0-f74f6b54-5ce0-11ea-a861-76b3ec213338.dump-info",]
    xname = "x3000c0s7b0n0"
    ```

    It can be seen that `state` is updated to `done`.

6.  Collect the dump data using the System Dump Utility \(SDU\).

    See the documentation in the SDU repository for more information about collecting data.

7.  Remove the dump if needed.

    1.  Retrieve the request ID of the dump.

        ```bash
        ncn-w001# cray nmd dumps list |grep requestID
        requestid = "7fd43a46-5743-11ea-9f7a-76b3ec213338"
        requestid = "3e72d39f-57b6-11ea-890d-76b3ec213338"
        requestid = "4c1c4da1-57b6-11ea-9823-76b3ec213338"
        requestid = "9b1e21b1-57bc-11ea-a3b5-76b3ec213338"
        requestid = "d6051c44-57c7-11ea-a1f2-76b3ec213338"
        requestid = "f7be74fb-57ce-11ea-a23f-76b3ec213338"
        requestid = "6c34a18a-57d2-11ea-99f7-76b3ec213338"
        requestid = "e73cb179-589b-11ea-a91b-76b3ec213338"
        requestid = "de9d039c-589c-11ea-a04c-76b3ec213338"
        requestid = "bf6afadf-5cdf-11ea-b9d2-76b3ec213338"
        ...
        ```

    2.  Delete the dump, specifying the request ID.

        The delete command will list all of the objects deleted as a result of the dump being deleted. An ongoing dump can be canceled by appending the `--force true` option to the end of the delete command. An ongoing dump cancelled with this command will be deleted.

        ```bash
        ncn-w001# cray nmd dumps delete REQUEST_ID
        [[Deleted]]
        Key = "2020/03/02/23/53/07/f74f6b54-5ce0-11ea-a861-76b3ec213338/x3000c0s7b0n0/x3000c0s7b0n0-f74f6b54-5ce0-11ea-a861-76b3ec213338.dump-config"
        
        [[Deleted]]
        Key = "2020/03/02/23/53/07/f74f6b54-5ce0-11ea-a861-76b3ec213338/x3000c0s7b0n0/x3000c0s7b0n0-f74f6b54-5ce0-11ea-a861-76b3ec213338.dump-info"
        
        [ResponseMetadata]
        HostId = ""
        RetryAttempts = 0
        HTTPStatusCode = 200
        RequestId = "tx00000000000000004a188-005e5d9e3d-119e-default"
        
        [ResponseMetadata.HTTPHeaders]
        transfer-encoding = "chunked"
        server = "envoy"
        x-envoy-upstream-service-time = "2"
        x-amz-request-id = "tx00000000000000004a188-005e5d9e3d-119e-default"
        date = "Tue, 03 Mar 2020 00:01:00 GMT"
        content-type = "application/xml"
        ```


