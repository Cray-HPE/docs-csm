---
category: [numbered, numbered]
---

# Add a Volume to UAS

How to add a volume to UAS. Adding a volume registers it with UAS and makes it available to UAIs.

Install and initialize the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    This procedure registers and configures a volume in UAS so that the volume can be mounted in UAIs.

-   **LIMITATIONS**

    None.


See [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) for examples of valid volume configurations. Refer to [Elements of a UAI](Elements_of_a_UAI.md) for descriptions of the volume configuration fields and values.

Note the following caveats about adding volumes to UAS:

1.  A volume description may specify an underlying directory that is NFS-mounted on the UAI host nodes. Hard-mounted NFS file systems will stop responding indefinitely on references to their mount points if the NFS server fails or becomes unreachable from the UAI host node. This will cause new UAI creation and migration of existing UAIs to stop responding as well until the NFS issue is remedied.
2.  Multiple volumes can be configured in UAS with the same `mount_path`. UAS cannot create a UAI if that UAI has more than one volume specified for a given `mount_path`. If multiple volumes with the same `mount_path` exist in the UAS configuration all UAIs must be created using UAI classes that specify a workable subset of volumes. A UAI created without a UAI Class under such a UAS configuration will try to use all configured volumes and creation will fail.
3.  The `volumename` is a string that can describe or name the volume. It must be composed of only lowercase letters, numbers, and dashes \('-'\). The `volumename` also must begin and end with an alphanumeric character.
4.  As with UAI images, registering a volume with UAS creates the configuration that will be used to create a UAI. If the underlying object referred to by the volume does not exist at the time the UAI is created, the UAI will, in most cases, wait until the object becomes available before starting up. This will be visible in the UAI state which will eventually move to Waiting

To create a volume, follow this procedure.

1.  Use the cray CLI to create the volume, specifying volumename, mount\_path, and volume\_description.

    The following command creates a /host\_files directory in every UAI configured to use this volume and mounts the file /etc/passwd from the host node into that directory as a file named host\_passwd. Note the form of the --volume-description argument. It is a JSON string encapsulating an entire `volume_description` field as shown in the JSON output in [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md).

    Note the difference between the UAS name for the volume type and the Kubernetes name for that type. Kubernetes uses `camelCase` for its type names, while UAS uses `lower_case_with_underscores`. In the following example, `host_path` is the UAS name for a Kubernetes `hostPath`.

    ```screen
    ncn-w001-pit # cray uas admin config volumes create --mount-path \\
    /host\_files/host\_passwd --volume-description \\
    '\{"host\_path": \{"path": "/etc/passwd", "type": "FileOrCreate"\}\}' \\
    --volumename 'my-volume-with-passwd-from-the-host-node'
    ```

2.  Perform [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) to verify that the new volume is configured.

    The new volume appears in the output of cray uas admin config volumes list.


**Parent topic:**[Create and Register a Custom UAI Image](Create_and_Register_a_Custom_UAI_Image.md)

