# Platform Install 

This page will go over how to install the Platform Manifest 


1. Install kubectl on the LiveCD

    > NOTE:  This is only needed until CASMPET-3442 is resolved. 

    ```bash
    spit:~ # curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl" 
    spit:~ # chmod +x ./kubectl
    spit:~ # mv ./kubectl /usr/local/bin/kubectl
    spit:~ # mkdir ~/.kube
    spit:~ # scp ncn-m001.nmn:/etc/kubernetes/admin.conf ~/.kube/config 
    ``` 
    Now you can run `kubectl get nodes` to see the nodes in the cluster. 

2. Generate the platform manifest.  (Replace <system-name> with the system you are installing.)

    ```bash
    spit:~ # git clone https://stash.us.cray.com/scm/shasta-cfg/<system-name>.git 
    spit:~ # manifestgen -i <system-name>/manifests/platform.yaml > platform.yaml 
    spit:~ # loftsman ship --shape --images-registry dtr.dev.cray.com --charts-repo http://packages.local:8081/repository/helmrepo.dev.cray.com/ --loftsman-images-registry dtr.dev.cray.com --manifest-file-path ./platform.yaml 
    ```

   This should execute the full platform manifest.   Make sure the shasta-cfg repo for your system is up-to-date with the shasta-cfg/stable repo.

