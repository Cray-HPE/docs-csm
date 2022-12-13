# Configuration Sessions

Once configurations have been created with the required layers and values set in the configuration repositories \(or the additional inventory repository\), create a Configuration Framework Session \(CFS\) session to apply the configuration to the targets.

Sessions are created via the Cray CLI or through the CFS REST API.
A session stages Ansible inventory \(whether dynamic, static, or image customization\), launches Ansible Execution Environments \(AEE\) in order for each configuration layer in the service mesh,
tears down the environments as required, and reports the session status to the CFS API.

When a session target is an Image Management Service \(IMS\) image ID for the purposes of pre-boot image customization, the CFS session workflow varies slightly.
The inventory staging instead calls IMS to expose the requested image root\(s\) via SSH. After the AEE\(s\) finish applying the configuration layers,
CFS then instructs IMS to tear down the image root environment and package up the resultant image and records the new image ID in the session metadata.

## Session Naming Conventions

CFS follows the same naming conventions for session names as Kubernetes does for jobs. Session names must follow the Kubernetes naming conventions and are limited to 45 characters.

Refer to the external [Kubernetes naming conventions](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) documentation for more information.

## Configuration Session Filters

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
  cray cfs sessions list --tags bos_session=BOS_SESSION_NAME
  ```

## Configuration Session Workflow

CFS progresses through a session by running a series of commands in containers located in a Kubernetes job pod. Four container types are present in the job pod which pertain to CFS session setup, execution, and teardown:

* **`git-clone`**

  This `init` container is responsible for cloning the configuration repositories and checking out the branch/commit specified in each configuration layer.
  This `init` container also clones the repository specified in the parameter `additionalInventoryUrl`, if specified.

* **`inventory`**

  This container is responsible for generating the dynamic inventory or for communicating to IMS to stage boot image roots that need to be made available via SSH when the session `--target-definition` is `image`.

* **`ansible`**

  This container runs the AEE after CFS injects the inventory and Git repository content from previous containers. This container runs the Ansible configuration for each layer specified.

* **`teardown`**

  This container waits for the `ansible` to complete and subsequently calls IMS to package up customized image roots. The container only exists when the session `--target-definition` is `image`.
