# Troubleshoot UAIs by Viewing Log Output

Sometimes a UAI will come up and run but will not work correctly. It is possible to see errors reported by elements of the UAI `entrypoint` script using the `kubectl logs` command.

## Procedure

1. Find the UAI of interest.

   This starts by identifying the UAI name using the CLI:

   ```bash
   ncn-m001-pit# cray uas admin uais list
   ```

   Example output:

   ```bash
   [[results]]
   uai_age = "4h30m"
   uai_connect_string = "ssh broker@10.103.13.162"
   uai_host = "ncn-w001"
   uai_img = "dtr.dev.cray.com/cray/cray-uai-broker:latest"
   uai_ip = "10.103.13.162"
   uai_msg = ""
   uai_name = "uai-broker-2e6ce6b7"
   uai_status = "Running: Ready"
   username = "broker"

   [[results]]
   uai_age = "1h12m"
   uai_connect_string = "ssh vers@10.20.49.135"
   uai_host = "ncn-w001"
   uai_img = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
   uai_ip = "10.20.49.135"
   uai_msg = ""
   uai_name = "uai-vers-6da50e7a"
   uai_status = "Running: Ready"
   username = "vers"
   ```

1. Find the UAI in question, remembering that End-User UAIs run in the `user` Kubernetes namespace and Broker UAIs run in the `uas` Kubernetes namespace.

   * End-User:

     ```bash
     ncn-m001-pit# kubectl get po -n user | grep uai-vers-6da50e7a
     ```

     Example output:

     ```bash
     uai-vers-6da50e7a-54dbc99fdd-csxmk     1/1     Running   0          76m
     ```

   * Broker:

     ```bash
     ncn-m001-pit# kubectl get po -n uas | grep uai-broker-2e6ce6b7
     ```

     Example output:

     ```bash
     uai-broker-2e6ce6b7-68d78c6c95-s28dh     2/2     Running   0          4h34m
     ```

1. Use the pod name and the namespace to get the logs.

   * End-User UAI pod name and the `user` namespace:

     ```bash
     ncn-m001-pit# kubectl logs -n user uai-vers-6da50e7a-54dbc99fdd-csxmk uai-vers-6da50e7a
     ```

     Example output:

     ```bash
     Setting up passwd and group entries for vers
     Setting profile for vers
     Adding vers to groups
     Disabling password based login
     passwd: password expiry information changed.
     Checking to see if /home/users/vers exists
     If this hangs, please ensure that /home/users/vers is properly mounted/working on the host of this pod
     No home directory exists, creating one
     Checking for munge.key
     Setting up munge.key
     Check for pbs.conf
     Generating ssh keys and sshd_config
     ssh-keygen: generating new host keys: RSA DSA ECDSA ED25519

     [...]
     ```

   * Broker UAI pod name and the `uas` namespace:

     ```bash
     ncn-m001-pit# kubectl logs -n uas uai-broker-2e6ce6b7-68d78c6c95-s28dh uai-broker-2e6ce6b7
     ```

     Example output:

     ```bash
     /bin/bash: warning: setlocale: LC_ALL: cannot change locale (C.UTF-8)
     Configure PAM to use sssd...
     Generating broker host keys...
     ssh-keygen: generating new host keys: RSA DSA ECDSA ED25519
     Checking for UAI_CREATION_CLASS...
     Starting sshd...
     Starting sssd...
     (Wed Feb  3 18:34:41:792821 2021) [sssd] [sss_ini_get_config] (0x0020): Config merge error: Directory /etc/sssd/conf.d does not exist.
     ```

     The above is from a successful Broker starting and running.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Troubleshoot Stale Brokered UAIs](Troubleshoot_Stale_Brokered_UAIs.md)
