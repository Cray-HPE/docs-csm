# Platform Install

This page will go over how to install the Platform Manifest


1. Install kubectl on the LiveCD

    > NOTE:  This is only needed until CASMINST-110 is resolved.

    ```bash
    spit:~ # curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl"
    spit:~ # chmod +x ./kubectl
    spit:~ # mv ./kubectl /usr/local/bin/kubectl
    spit:~ # mkdir ~/.kube
    spit:~ # scp ncn-m001.nmn:/etc/kubernetes/admin.conf ~/.kube/config
    ```
    Now you can run `kubectl get nodes` to see the nodes in the cluster.

2. Generate the platform and keycloak-gatekeeper manifests. (Replace <system-name> with the system you are installing.)

    > NOTE: the call to manifestgen should be done via <system-name>/deploy/generate.sh when we're ready to use all manifests

    ```bash
    spit:~ # git clone https://stash.us.cray.com/scm/shasta-cfg/<system-name>.git
    spit:~ # cd <system-name>
    spit:~ # mkdir -p ./build/manifests
    spit:~ # manifestgen -c customizations.yaml -i ./manifests/platform.yaml > ./build/manifests/platform.yaml
    spit:~ # manifestgen -c customizations.yaml -i ./manifests/keycloak-gatekeeper.yaml > ./build/manifests/keycloak-gatekeeper.yaml
    ```

3. Run the deploydecryptionkey.sh script provided by the shasta-cfg/<system-name>.git repo.

    ```bash
    spit:~ # ./deploy/deploydecryptionkey.sh
    ```

4. Run loftsman against the platform manifest using shasta-cfg/<system-name> provided-script.

    ```bash
    spit:~ # ./deploy/deploy.sh ./build/manifests/platform.yaml dtr.dev.cray.com http://packages.local:8081/repository/helmrepo.dev.cray.com/
    ```

   This should execute the full platform manifest. Make sure the shasta-cfg repo for your system is up-to-date with the shasta-cfg/stable repo.

5. Run loftsman against the keycloak-gatekeeper manifest using shasta-cfg/<system-name> provided-script.

    ```bash
    spit:~ # ./deploy/deploy.sh ./build/manifests/keycloak-gatekeeper.yaml dtr.dev.cray.com http://packages.local:8081/repository/helmrepo.dev.cray.com/
    ```
