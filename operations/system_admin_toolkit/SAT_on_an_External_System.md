# SAT on an External System

The `sat` command-line utility can optionally be installed and configured on an
external system to interact with CSM over the CAN.

## Limitations

Most `sat` commands work by accessing APIs which are reachable via the CAN.
However, certain `sat` commands depend on host-based functionality on the
management NCNs and will not work from an external system. This includes the
following:

- The `platform-services` and `ncn-power` stages of `sat bootsys`
- The local host information displayed by the `--local` option of `sat showrev`

Installing the `sat` CLI on an external system is not an officially supported
configuration. These instructions are provided "as-is" with the hope that they
can be useful for users who desire additional flexibility.

Certain additional steps may need to be taken to install and configure SAT
depending on the configuration of the external system in use. These additional
steps may include provisioning virtual machines, installing packages, or
configuring TLS certificates, and these steps are outside the scope of this
documentation. This section covers only the steps needed to configure SAT to
use externally-accessible API endpoints exposed by CSM.

## Install and Configure SAT

### Prerequisites

- The external system must be on the Customer Access Network (CAN).
- Python 3.7 or newer is installed on the external system.
- `kubectl`, `openssh`, `git`, and `curl` are installed on the external system.
- The root CA certificates used when installing CSM have been added to the
  external system's trust store such that authenticated TLS connections can be
  made to the CSM REST API gateway. For more information, refer to
  [Certificate Authority](../../background/certificate_authority.md).

### Procedure

1. (`user@hostname>`) Create a Python virtual environment.

   ```bash
   SAT_VENV_PATH="$(pwd)/venv"
   python3 -m venv ${SAT_VENV_PATH}
   . ${SAT_VENV_PATH}/bin/activate
   ```

1. (`(venv) user@hostname>`) Clone the SAT source code.

   To use SAT version 3.26, this example clones the `release/3.26` branch of
   `Cray-HPE/sat`.

   ```bash
   git clone --branch=release/3.26 https://github.com/Cray-HPE/sat.git
   ```

1. Set up the SAT CSM Python dependencies to be installed from their source code.

   SAT CSM Python dependency packages are not currently distributed publicly as
   source packages or binary distributions. They must be installed from
   their source code hosted on GitHub. Also, to install the `cray-product-catalog`
   Python package, first clone it locally. Use the following steps to
   modify the SAT CSM Python dependencies so they can be installed from their source
   code.

   1. (`(venv) user@hostname>`) Clone the source code for `cray-product-catalog`.

      ```bash
      git clone --branch v1.6.0 https://github.com/Cray-HPE/cray-product-catalog
      ```

   1. (`(venv) user@hostname>`) In the `cray-product-catalog` directory, create a file named `.version`
      that contains the version of `cray-product-catalog`.

      ```bash
      echo 1.6.0 > cray-product-catalog/.version
      ```

   1. (`(venv) user@hostname>`) Open the "locked" requirements file in a text editor.

      ```bash
      vim sat/requirements.lock.txt
      ```

   1. Update the line containing `cray-product-catalog` so that it reflects the
      local path to `cray-product-catalog`.

      It should read as follows:

      ```text
      ./cray-product-catalog
      ```

   1. For versions of SAT newer than 3.19, change the line containing `csm-api-client`
      to read as follows.

      ```text
      csm-api-client@git+https://github.com/Cray-HPE/python-csm-api-client@release/1.1
      ```

   1. (Optional) (`(venv) user@hostname>`) Confirm that `requirements.lock.txt` is modified as expected.

      ```bash
      grep -E 'cray-product-catalog|csm-api-client' sat/requirements.lock.txt
      ```

      Example output:

      ```text
      ./cray-product-catalog
      csm-api-client@git+https://github.com/Cray-HPE/python-csm-api-client@release/1.1
      ```

      **Note:** For versions newer than 3.19, the output will show both
      `cray-product-catalog` and `csm-api-client`. For version 3.19 and older,
      the output will only show `cray-product-catalog`.

1. (`(venv) user@hostname>`) Install the modified SAT dependencies.

   ```bash
   pip install -r sat/requirements.lock.txt
   ```

1. (`(venv) user@hostname>`) Install the SAT Python package.

   ```bash
   pip install ./sat
   ```

1. (Optional) (`(venv) user@hostname>`) Add the `sat` virtual environment to the user's `PATH` environment
   variable.

   If a shell other than `bash` is in use, replace `~/.bash_profile` with the
   appropriate profile path.

   If the virtual environment is not added to the user's `PATH` environment
   variable, then `source ${SAT_VENV_PATH}/bin/activate` will need to be run before
   running any SAT commands.

   ```bash
   deactivate
   echo export PATH=\"${SAT_VENV_PATH}/bin:${PATH}\" >> ~/.bash_profile
   source ~/.bash_profile
   ```

1. (`user@hostname>`) Copy the file `/etc/kubernetes/admin.conf` from `ncn-m001` to `~/.kube/config`
   on the external system.

   Note that this file contains credentials to authenticate against the Kubernetes
   API as the administrative user, so it should be treated as sensitive.

   ```bash
   mkdir -p ~/.kube
   scp ncn-m001:/etc/kubernetes/admin.conf ~/.kube/config\
   ```

   Example output:

   ```text
   admin.conf                                       100% 5566   3.0MB/s   00:00
   ```

1. (`user@hostname>`) Find the CAN IP address on `ncn-m001` to determine the
   corresponding `kubernetes` hostname.

   - On CSM 1.2 and newer, query the IP address of the `bond0.cmn0`
     interface.

     ```bash
     ssh ncn-m001 ip addr show bond0.cmn0
     ```

     Example output:

     ```text
     13: bond0.cmn0@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
     link/ether b8:59:9f:1d:d9:0e brd ff:ff:ff:ff:ff:ff
     inet 10.102.1.11/24 brd 10.102.1.255 scope global vlan007
        valid_lft forever preferred_lft forever
     inet6 fe80::ba59:9fff:fe1d:d90e/64 scope link
        valid_lft forever preferred_lft forever
     ```

   - On CSM versions prior to 1.2, query the IP address of the `vlan007` interface.

     ```bash
     ssh ncn-m001 ip addr show vlan007
     ```

     Example output:

     ```text
     13: vlan007@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
     link/ether b8:59:9f:1d:d9:0e brd ff:ff:ff:ff:ff:ff
     inet 10.102.1.10/24 brd 10.102.1.255 scope global vlan007
        valid_lft forever preferred_lft forever
     inet6 fe80::ba59:9fff:fe1d:d90e/64 scope link
        valid_lft forever preferred_lft forever
     ```

1. (`user@hostname>`) Set the `IP_ADDRESS` variable to the value found in the
   previous step.

   ```bash
   IP_ADDRESS=10.102.1.11
   ```

1. (`user@hostname>`) Add an entry to `/etc/hosts` mapping the IP address to
   the hostname `kubernetes`.

   ```bash
   echo "${IP_ADDRESS} kubernetes" | sudo tee -a /etc/hosts
   10.102.1.11 kubernetes
   ```

1. (`user@hostname>`) Modify `~/.kube/config` to set the cluster server address.

   The value of the `server` key for the `kubernetes` cluster under the `clusters`
   section should be set to `https://kubernetes:6443`.

   ```yaml
   ---
   clusters:
   - cluster:
       certificate-authority-data: REDACTED
       server: https://kubernetes:6443
     name: kubernetes
   ...
   ```

1. (`user@hostname>`) Confirm that `kubectl` can access the CSM Kubernetes cluster.

   ```bash
   kubectl get nodes
   ```

   Example output:

   ```text
   NAME       STATUS   ROLES    AGE    VERSION
   ncn-m001   Ready    master   135d   v1.19.9
   ncn-m002   Ready    master   136d   v1.19.9
   ncn-m003   Ready    master   136d   v1.19.9
   ncn-w001   Ready    <none>   136d   v1.19.9
   ncn-w002   Ready    <none>   136d   v1.19.9
   ncn-w003   Ready    <none>   136d   v1.19.9
   ```

1. (`user@hostname>`) Use `sat init` to create a configuration file for SAT.

   ```bash
   sat init
   ```

   Example output:

   ```text
   INFO: Configuration file "/home/user/.config/sat/sat.toml" generated.
   ```

1. (`user@hostname>`) Copy the platform CA certificates from the management NCN
   and configure the certificates for use with SAT.

   If a shell other than `bash` is in use, replace `~/.bash_profile` with the
   appropriate profile path.

   ```bash
   scp ncn-m001:/etc/pki/trust/anchors/platform-ca-certs.crt .
   echo export REQUESTS_CA_BUNDLE=\"$(realpath platform-ca-certs.crt)\" >> ~/.bash_profile
   source ~/.bash_profile
   ```

1. Edit the SAT configuration file to set the API and S3 hostnames.

   Externally available API endpoints are given domain names in PowerDNS, so the
   endpoints in the configuration file should each be set to the format
   `subdomain.system-name.site-domain`. Here `system-name` and `site-domain` are
   replaced with the values specified during `csi config init`, and `subdomain`
   is the DNS name for the externally available service. For more information,
   refer to [Externally Exposed Services](../network/customer_accessible_networks/Externally_Exposed_Services.md).

   The API gateway has the subdomain `api`, and S3 has the subdomain `s3`. The
   S3 endpoint runs on port 8080. The following options should be set in the
   SAT configuration file.

   ```toml
   [api_gateway]
   host = "api.system-name.site-domain"

   [s3]
   endpoint = "http://s3.system-name.site-domain:8080"
   ```

1. Edit the SAT configuration file to specify the Keycloak user who will be
   accessing the REST API.

   ```toml
   [api_gateway]
   username = "user"
   ```

1. (`user@hostname>`) Run `sat auth`, and enter the password when prompted.

   ```bash
   sat auth
   ```

   Example output:

   ```text
   Password for user:
   Succeeded!
   ```

   For more information on authenticating SAT to the API gateway, see
   [Authenticate SAT Commands](configuration/Authenticate_SAT_Commands.md).

1. (`user@hostname>`) Ensure the files are readable only by the current user.

    ```bash
    touch ~/.config/sat/s3_access_key \
        ~/.config/sat/s3_secret_key
    ```

    ```bash
    chmod 600 ~/.config/sat/s3_access_key \
        ~/.config/sat/s3_secret_key
    ```

1. (`user@hostname>`) Write the credentials to local files using `kubectl`.

   Generate S3 credentials and write them to a local file so the SAT user can
   access S3 storage. In order to use the SAT S3 bucket, the user must generate
   the S3 access key and secret keys and write them to a local file. SAT uses
   S3 storage for several purposes, most importantly to store the site-specific
   information set with `sat setrev`.

   ```bash
   kubectl get secret sat-s3-credentials -o json -o \
       jsonpath='{.data.access_key}' | base64 -d > \
       ~/.config/sat/s3_access_key
   ```

   ```bash
   kubectl get secret sat-s3-credentials -o json -o \
       jsonpath='{.data.secret_key}' | base64 -d > \
       ~/.config/sat/s3_secret_key
   ```
