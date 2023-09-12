# CFS Sessions

Configuration Framework Service \(CFS\) sessions apply a configuration, including any number of layers, to a target or set of targets, which can be live nodes or images mounted by IMS.

A session clones down Ansible content, creates an Ansible inventory \(whether dynamic, static, or image customization\), launches an Ansible Execution Environment \(AEE\), and reports the session status to the CFS API.
When configuring an image, the CFS session also calls Image Management Service \(IMS\) to start a configuration job and tears down the IMS job after configuration is complete.
IMS then tears down the image root environment, packages up the resultant image and CFS records the new image ID in the session metadata.

Sessions can be created manually via the Cray CLI or through the CFS REST API, or created automatically by setting a desired configuration for components.
See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information on automatic sessions.

## Configuration session workflow

CFS progresses through a session by running a series of commands in containers located in a Kubernetes job pod.
Up to four container types are present in the job pod which pertain to CFS session setup, execution, and teardown:

* **`git-clone`**

  This `init` container is responsible for cloning the configuration repositories and checking out the branch/commit specified in each configuration layer.
  This `init` container also clones the repository specified in the parameter `additional_inventory_url`, if specified.

* **`inventory`**

  This container is responsible for generating the dynamic inventory or for communicating to IMS to stage boot image roots that need to be made available via SSH when the session `--target-definition` is `image`.

* **`ansible`**

  This container runs the AEE after CFS injects the inventory and Git repository content from previous containers. This container runs the Ansible configuration for each layer specified.

* **`teardown`**

  This container waits for the `ansible` container to complete and subsequently calls IMS to package up customized image roots. The container only exists when the session `--target-definition` is `image`.
  
## Session data

The following fields are comprise a session record, including both the session definition used to setup and session, as well as any information on the session results.

* **`configuration_status`**

  The status of the component's configuration. Valid status values are:

  * **`unconfigured`** - The component has no recorded state and no desired configuration or no valid desired configuration.
  * **`failed`** - One of the configuration layers for the component has failed and the retry limit has been exceeded.
  * **`pending`** - The component's desired state and actual state do not match. The component will be configured automatically if enabled.
  * **`configured`** - The component's desired state and actual state match.

## Viewing sessions

(`ncn-mw#`) To view a session, use the `describe` command for the session name:

```bash
cray cfs v3 sessions describe <session name> --format json
```

Example output:

```json
{
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": null,
    "passthrough": null,
    "verbosity": 4
  },
  "configuration": {
    "limit": "",
    "name": "example-config"
  },
  "debug_on_failure": false,
  "logs": "ara.cmn.site/hosts?label=example-session",
  "name": "example-session",
  "status": {
    "artifacts": [],
    "session": {
      "completion_time": null,
      "job": "cfs-df176eb7-85bd-4559-9fc6-43e0a78f97de",
      "start_time": "2023-09-06T15:34:26",
      "status": "complete",
      "succeeded": "false"
    }
  },
  "tags": {},
  "target": {
    "definition": "image",
    "groups": [
      {
        "members": [
          "902b4a80-3ac2-40d5-b65e-86ac3e12f209"
        ],
        "name": "Application"
      }
    ],
    "image_map": [
      {
        "result_name": "example-session-customized",
        "source_id": "902b4a80-3ac2-40d5-b65e-86ac3e12f209"
      }
    ]
  }
}
```

## Creating sessions

(`ncn-mw#`) To create a session, use the `create` command for the session name:

```bash
cray cfs v3 sessions create --name <session-name> --configuration-name <example-config>
```

For more information on creating sessions to configure live nodes, see [Create a Node Personalization CFS Session](Create_a_Node_Personalization_CFS_Session.md).

For more information on creating sessions to configure images, see [Create an Image Customization CFS Session](Create_an_Image_Customization_CFS_Session.md).

## Deleting sessions

(`ncn-mw#`) To delete a session, use the `delete` command for the session name:

```bash
cray cfs v3 sessions delete <session name>
```

(`ncn-mw#`) To delete multiple sessions, use the `deleteall` command.
This command can also filter the sessions to delete based on tags, name, status, age, and success or failure.
By default, if no other filter is specified, this command only deletes completed sessions:

```bash
cray cfs v3 sessions deleteall <session name>
```

Completed CFS sessions can be automatically deleted based on age. See the [Automatic Session Deletion with `session_ttl`](Automatic_Session_Deletion_with_session_ttl.md) section.

## Configuration session filters

CFS provides several filters for use when listing sessions or using the bulk delete option. These following filters are available:

* `--status`: Session status options include `pending`, `running`, and `complete`.
* `--succeeded`: If the session has not yet completed, this will be set to `none`. Otherwise, this
will be set to `true`, `false`, or `unknown` in the event that CFS was unable to find the Kubernetes
job associated with the session.
* `--min-age`/`--max-age`: Returns only the sessions that fall within the given age. For example,
`--max-age` could be used to list only the recent sessions, or `--min-age` could be used to find old sessions
for cleanup. Age is given in the format `1d` for days, or `6h` for hours.
* `--tags`: Sessions can be created with searchable tags. By default, this includes the
`bos_session` tag when CFS is triggered by BOS. This can be searched using the following command:

  ```bash
  cray cfs v3 sessions list --tags bos_session=BOS_SESSION_NAME
  ```

## Session naming conventions

CFS follows the same naming conventions for session names as Kubernetes does for jobs. Session names must follow the Kubernetes naming conventions and are limited to 45 characters.

Refer to the external [Kubernetes naming conventions](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) documentation for more information.
