# SSH Keys

An SSH key is required by Ansible and several other system management services on the system. If an SSH key is not available, the Configuration Framework Service \(CFS\) is unusable, and Ansible cannot be invoked from `ncn-w001`. The SSH key is created in two parts, with a public and private key. The `id_rsa.pub` and `id_rsa` key values are located in the /root/.ssh directory on `ncn-w001`.

**Important:** Changing the SSH key can have serious implications. The loss of the private key can result in administrators no longer being able to connect to other nodes or containers via SSH. Ansible also uses SSH as the root user, so Ansible plays will fail as a result of the loss of the private key.

There is only one copy of the private part of the key, and that resides on `ncn-w001`. If that is lost, then passwordless SSH is no longer possible between `ncn-w001` and the rest of the system.
