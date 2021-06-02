## Configuration Sessions

Once configurations have been created with the required layers and values set in the configuration repositories \(or the additional inventory repository\), create a Configuration Framework Session \(CFS\) session to apply the configuration to the targets.

Sessions are created via the Cray CLI or through the CFS REST API. A session stages ansible inventory \(whether dynamic, static, or image customization\), launches Ansible Execution Environments \(AEE\) in order for each configuration layer in the service mesh, tears down the environments as required, and reports the session status to the CFS API.

When a session target is an Image Management Service \(IMS\) image ID for the purposes of pre-boot image customization, the CFS session workflow varies slightly. The inventory staging instead calls IMS to expose the requested image root\(s\) via SSH. After the AEE\(s\) finish applying the configuration layers, CFS then instructs IMS to tear down the image root environment and package up the resultant image and records the new image ID in the session metadata.

### Session Naming Conventions

CFS follows the same naming conventions for session names as Kubernetes does for jobs. Session names must follow the Kubernetes naming conventions and are limited to 45 characters.

Refer to the external [Kubernetes naming conventions](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) documentation for more information.

### Configuration Session Workflow

CFS progresses through a session by running a series of commands in containers located in a Kubernetes job pod. Four container types are present in the job pod which pertain to CFS session setup, execution, and teardown:

-   **`git-clone-*`**

    These init containers are responsible for cloning the configuration repository and checking out the branch/commit specified in each configuration layer.

    These containers are run in the same order as the layers are specified, and their names are indexed appropriately: `git-clone-0`, `git-clone-1`, and so on.

-   **`git-clone-hosts`**

    This init container clones the repository specified in the parameter `additionalInventoryUrl`, if specified.

-   **`inventory`**

    This container is responsible for generating the dynamic inventory or for communicating to IMS to stage boot image roots that need to be made available via SSH when the session `--target-definition` is `image`.

-   **`ansible-*`**

    These containers run the AEE after CFS injects the inventory and Git repository content from previous containers. One container is executed for each configuration layer specified.

    These containers are run in the same order as the layers are specified, and their names are indexed appropriately: `ansible-0`, `ansible-1`, and so on.

-   **`teardown`**

    This container waits for the last `ansible-*` to complete and subsequently calls IMS to package up customized image roots. The container only exists when the session `--target-definition` is `image`.




