# Barebones Boot Test Failure

`/opt/cray/tests/integration/csm/barebones_image_test` returns "Failure of barebones image boot test".

In CSM 1.6.0, the barebones boot image test fails with output similar to the following:

```text
cray.barebones-boot-test: INFO     Barebones image boot test starting
cray.barebones-boot-test: INFO       For complete logs look in the file /opt/cray/tests/integration/logs/csm/barebones_image_test/20250211112322.log
cray.barebones-boot-test: INFO     No architecture, node, or image specified; using default arch: x86
cray.barebones-boot-test: INFO     Latest CSM version found in Product Catalog: 1.6.0
cray.barebones-boot-test: INFO     Querying HSM to find an enabled compute node with 'x86' arch
cray.barebones-boot-test: INFO     Found compute node 'x3000c0s17b3n0' with architecture 'x86'
cray.barebones-boot-test: INFO     Found barebones image in product catalog: 'compute-csm-1.6-6.2.25-x86_64': {'id': '361c1121-0b03-4bb1-b707-d14ff8bd5b2f'}
cray.barebones-boot-test: INFO     Base IMS image '361c1121-0b03-4bb1-b707-d14ff8bd5b2f' from the product catalog has arch 'x86'
cray.barebones-boot-test: INFO     Creating CFS configuration 'example-session'
cray.barebones-boot-test: INFO     Created CFS configuration 'example-session'
cray.barebones-boot-test: INFO     Creating CFS session 'example-session' to customize IMS image '361c1121-0b03-4bb1-b707-d14ff8bd5b2f' with CFS configuration 'example-session'
cray.barebones-boot-test: INFO     Created CFS session 'example-session'
cray.barebones-boot-test: INFO     Waiting for CFS session 'example-session' to complete
cray.barebones-boot-test: INFO     CFS session 'example-session' 'status' field is 'pending'
cray.barebones-boot-test: INFO     CFS session 'example-session' 'status' field is now 'running'
cray.barebones-boot-test: INFO     CFS session 'example-session' 'status' field is now 'complete'
cray.barebones-boot-test: INFO     CFS session 'example-session' 'succeeded' field is now 'true'
cray.barebones-boot-test: INFO     CFS session 'example-session' completed successfully
cray.barebones-boot-test: INFO     Created IMS image '92045173-0735-4d3c-99fc-a198aa72bb29'
cray.barebones-boot-test: INFO     CFS session 'example-session' created customized IMS image '92045173-0735-4d3c-99fc-a198aa72bb29'
cray.barebones-boot-test: INFO     Creating BOS session template 'example-session'
cray.barebones-boot-test: INFO     Created BOS session template 'example-session'
cray.barebones-boot-test: INFO     Creating BOS session 'example-session' with BOS session template 'example-session' on node 'x3000c0s17b3n0'
cray.barebones-boot-test: INFO     Created BOS session 'example-session'
cray.barebones-boot-test: INFO     Waiting for BOS session 'example-session' to complete
cray.barebones-boot-test: INFO     BOS session 'example-session' 'status' field is 'pending'
cray.barebones-boot-test: INFO     BOS session 'example-session' 'status' field is now 'running'
cray.barebones-boot-test: ERROR    BOS session 'example-session' has not completed even after 30 minutes
cray.barebones-boot-test: ERROR    Failure of barebones image boot test.
cray.barebones-boot-test: INFO     For troubleshooting information and manual steps, see https://github.com/Cray-HPE/docs-csm/blob/release/1.6/troubleshooting/cms_barebones_image_boot.md 
```

The test failure is attributed to incorrect network configuration, which causes the node to appear as though it has not booted. In most cases, the node has successfully booted but is inaccessible via the network.

## Fix

There is no fix for the barebones image in CSM 1.6.0. The problem exists in the barebones image as indicated above and has been patched in CSM 1.6.1 and later.

Accessing the node may be done through the use of Cray Console.

1. Find the node xname in the test output.

    Look for text similar to the following in the test output:

    ```text
    Found compute node 'x3000c0s17b3n0' with architecture 'x86'
    ```

1. Follow the [Log in to a Node Using ConMan](../../operations/conman/Log_in_to_a_Node_Using_ConMan.md) procedure, using the xname identified in the previous step.
