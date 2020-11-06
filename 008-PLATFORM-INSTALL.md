# Platform Install

This page will go over how to install the Platform Manifest


1. Install kubectl on the LiveCD

    > NOTE:  This is only needed until CASMINST-110 is resolved.

    ```bash
    spit:~ # curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl"
    spit:~ # chmod +x ./kubectl
    spit:~ # mv ./kubectl /usr/local/bin/kubectl
    spit:~ # mkdir ~/.kube
    spit:~ # scp ncn-m002.nmn:/etc/kubernetes/admin.conf ~/.kube/config
    ```
    Now you can run `kubectl get nodes` to see the nodes in the cluster.

2. Generate various manifests (replace <system-name> with the system you are installing).

    > NOTE: the call to manifestgen should be done via <system-name>/deploy/generate.sh when we're ready to use all manifests

    ```bash
    spit:~ # git clone https://stash.us.cray.com/scm/shasta-cfg/<system-name>.git
    spit:~ # cd <system-name>
    spit:~ # mkdir -p ./build/manifests
    spit:~ # manifestgen -c customizations.yaml -i ./manifests/platform.yaml > ./build/manifests/platform.yaml
    spit:~ # manifestgen -c customizations.yaml -i ./manifests/sysmgmt.yaml > ./build/manifests/sysmgmt.yaml
    spit:~ # manifestgen -c customizations.yaml -i ./manifests/keycloak-gatekeeper.yaml > ./build/manifests/keycloak-gatekeeper.yaml
    ```

3. Run the deploydecryptionkey.sh script provided by the shasta-cfg/<system-name>.git repo.

    ```bash
    spit:~ # ./deploy/deploydecryptionkey.sh
    ```

4. Run loftsman against the various manifests using shasta-cfg/<system-name> provided-script.

    ```bash
    spit:~ # ./deploy/deploy.sh ./build/manifests/platform.yaml dtr.dev.cray.com http://packages.local:8081/repository/helmrepo.dev.cray.com/
    spit:~ # ./deploy/deploy.sh ./build/manifests/sysmgmt.yaml dtr.dev.cray.com http://packages.local:8081/repository/helmrepo.dev.cray.com/
    spit:~ # ./deploy/deploy.sh ./build/manifests/keycloak-gatekeeper.yaml dtr.dev.cray.com http://packages.local:8081/repository/helmrepo.dev.cray.com/
    ```

    This should execute these manifests without error -- make sure the shasta-cfg repo for your system is up-to-date with the shasta-cfg/stable repo.
