# Platform Install

This page will go over how to install the Platform Manifest


1. Install kubectl on the LiveCD

    > NOTE:  This is only needed until CASMINST-110 is resolved.

    ```bash
    pit:~ # curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl"
    pit:~ # chmod +x ./kubectl
    pit:~ # mv ./kubectl /usr/local/bin/kubectl
    pit:~ # mkdir ~/.kube
    pit:~ # scp ncn-m002.nmn:/etc/kubernetes/admin.conf ~/.kube/config
    ```
    Now you can run `kubectl get nodes` to see the nodes in the cluster.

2. Generate various manifests (replace <system-name> with the system you are installing).

    > NOTE: the call to manifestgen should be done via <system-name>/deploy/generate.sh when we're ready to use all manifests

    ```bash
    pit:~ # git clone https://stash.us.cray.com/scm/shasta-cfg/<system-name>.git
    pit:~ # cd <system-name>
    pit:~ # mkdir -p ./build/manifests
    pit:~ # manifestgen -c customizations.yaml -i ./manifests/platform.yaml > ./build/manifests/platform.yaml
    pit:~ # manifestgen -c customizations.yaml -i ./manifests/sysmgmt.yaml > ./build/manifests/sysmgmt.yaml
    pit:~ # manifestgen -c customizations.yaml -i ./manifests/keycloak-gatekeeper.yaml > ./build/manifests/keycloak-gatekeeper.yaml
    ```

3. Run the deploydecryptionkey.sh script provided by the shasta-cfg/<system-name>.git repo.

    ```bash
    pit:~ # ./deploy/deploydecryptionkey.sh
    ```

4. Run loftsman against the various manifests using shasta-cfg/<system-name> provided-script.

    ```bash
    pit:~ # ./deploy/deploy.sh ./build/manifests/platform.yaml dtr.dev.cray.com http://packages.local:8081/repository/helmrepo.dev.cray.com/
    pit:~ # ./deploy/deploy.sh ./build/manifests/sysmgmt.yaml dtr.dev.cray.com http://packages.local:8081/repository/helmrepo.dev.cray.com/
    pit:~ # ./deploy/deploy.sh ./build/manifests/keycloak-gatekeeper.yaml dtr.dev.cray.com http://packages.local:8081/repository/helmrepo.dev.cray.com/
    ```

    This should execute these manifests without error -- make sure the shasta-cfg repo for your system is up-to-date with the shasta-cfg/stable repo.
