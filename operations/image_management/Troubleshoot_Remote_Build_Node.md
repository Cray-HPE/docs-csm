# Troubleshoot Issues with Remote Build Nodes

Remote builds work by creating and running containerized jobs via podman on a remote node. There
are times that problems crop up with running these remote jobs.

## Prerequisites

* Administrative access to a master node on the K8S cluster
* Administrative access to the remote build node

## Jobs fail to launch on remote nodes
- check remote node is defined in IMS
- check ssh keys on remote node
- check podman on remote node
- check arch of job and remote node
- look at IMS logs for job creation - should list checks on remote noded

## Clean up orphaned jobs
- ssh to remote node
- delete orphaned running containers
- delete stopped containers
- delete unused images
- prune volumes

## Jobs fail on remote node
- Not sufficient space
  - check orphaned jobs
  - look at 'setting up remote build node' docs for adding volume space to node


The jobs will be running on x9000c1s3b1n0.
You can ssh into x9000c1s3b1n0 to monitor the remote jobs (running as podman containers)
There should only be one container running at a time for now (fix is in the work to allow unlimited)
Run podman ps -a
If you see multiple 'completed' jobs, they should be cleaned up
Use podman stop CONTAINER_ID to stop orphaned jobs
Use podman rm CONTAINER_ID to remove completed jobs
Run podman image list to see docker images on the system.
There should only be one image present - the one used by a valid running job
Use podman rmi IMAGE_ID to remove images not needed any more
Run podman volume prune -f to complete removing dangling resources
The jobs use temporary directories to transfer artifacts back to the K8s pods.
They are located in /tmp/ims_IMS_JOB_ID
There should only be one present - the currently running job
If there are directories hanging around from killed/errored jobs, they can be manually deleted.
If this just really isn't working and I am not around to help (I will be out from Thur 2/15, back Tue 2/20):
Disable the remote node through IMS: cray ims remote-build-nodes delete x9000c1s3b1n0
If things are still really messed up at that point, revert the last IMS install:
helm -n services rollback cray-ims 1