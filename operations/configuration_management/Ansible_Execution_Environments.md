# Ansible Execution Environments

Configuration Framework Service \(CFS\) sessions are comprised of a single Kubernetes pod with several containers. The `inventory` and `git-clone` containers run first, and a `teardown` container runs last \(if the session is running an image customization\).

The container that runs the Ansible code cloned from the Git repositories in the configuration layers is the Ansible Execution Environments \(AEE\).
The AEE is provided as a SLES-based docker image, which includes Ansible version 2.9.11 installed using Python 3.6.
In addition to the base Ansible installation, CFS also includes several Ansible modules and plug-ins that are required for CFS and Ansible to work properly on the system.

The following modules and plug-ins are available:

* **`cfs_aggregator.py` Callback Plug-in**

  This callback plug-in is included to relay playbook execution results back to CFS for the purpose of tracking session status and component state.

  > **WARNING:** This plug-in is required for CFS to function properly and must not be removed from the `ansible.cfg` file.

* **`cfs_linear` and `cfs_free` Strategy Plug-ins**

  CFS provides two strategy plug-ins, `cfs_linear` and `cfs_free`, which should be used in place of the stock Ansible `free` and `linear` playbook execution strategies.

  For more information about Ansible strategies, see the external [Ansible playbook strategies](https://docs.ansible.com/ansible/latest/user_guide/playbooks_strategies.html) documentation.

* **`shasta_s3_cred.py` Module**

  This module is provided to obtain access to S3 credentials stored in Kubernetes secrets in the cluster, specifically secrets with names such as `<service\>-s3-credentials`.

  An example of using this module is as follows:

  ```yaml
  - name: Retrieve credentials from abc-s3-credentials k8s secret
    shasta_s3_creds:
      k8s_secret: abc-s3-credentials
      k8s_namespace: services
    register: creds
    no_log: true
  ```

  The access key is available at `\{\{ creds.access\_key \}\}` and the secret key is at `\{\{ creds.secret\_key \}\}`.
