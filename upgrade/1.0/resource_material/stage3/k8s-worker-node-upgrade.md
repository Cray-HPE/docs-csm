# Worker Specific Steps

1. Determine if the worker being rebuilt is running a `cray-cps-cm-pm` pod.  If so, there's a final step to re-deploy
   this pod once the worker is rebuilt. In the example below nodes ncn-w001, ncn-w002, and ncn-w003 have the pod.

   > NOTE: If the command below doesn't return any pod names, proceed to step 2.

   > NOTE: If `cray` is not initialized, please check [Initialize the CLI Configuration](https://stash.us.cray.com/projects/CSM/repos/docs-csm/browse/operations/validate_csm_health.md#uas-uai-init-cli-init)

    ```text
    ncn# cray cps deployment list --format json | jq '.[] | [.node,.podname]'
    [
      "ncn-w003",
      "cray-cps-cm-pm-9tdg5"
    ]
    [
      "ncn-w001",
      "cray-cps-cm-pm-fsd8w"
    ]
    [
      "ncn-w002",
      "cray-cps-cm-pm-sg954"
    ]
    ```

    If the node being rebuilt is one of those three, this step should be run **after** the completion of the common
   upgrade steps below.

    ```bash
    ncn# cray cps deployment update --nodes "ncn-w001,ncn-w002,ncn-w003"
    ```

2. Confirm what the CFS setting is for `configurationStatus` before shutting down the node. If the state is `pending`,
   the administrator may want to tail the logs of the `cray-cps-cm-pm` pod running on that node to watch the job finish
   before rebooting this node.  If the state is `failed` for this node, then you'll know that the failed CFS job state
   preceded this worker rebuild, and that can be addressed independent of rebuilding this worker.

   ```text
   ncn# cray cfs components describe $UPGRADE_XNAME --format json
   {
     "configurationStatus": "configured",
     "desiredConfig": "ncn-personalization-full",
     "enabled": true,
     "errorCount": 0,
     "id": "x3000c0s7b0n0",
     "retryPolicy": 3,
    ```

3. Ensure the nexus pod has the ability to start on any worker node by
   pre-caching the required images from the new CSM release.

   > NOTE: The command pipeline used in this step ties everything together in a
   > single command to precache the appropriate images before rebooting any
   > worker nodes. As a result it must be run from the node that has the
   > extracted CSM release distribution. If this is not possible, then see the
   > note below to sync each image one at a time.

   ```bash
   ncn-m001# workers="$(kubectl get node --selector='!node-role.kubernetes.io/master' -o name | sed -e 's,^node/,,' | paste -sd,)"
   ncn-m001# export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
   ncn-m001# yq r ./${CSM_RELEASE}/manifests/platform.yaml 'spec.charts(name==cray-precache-images).values.cacheImages[*]' | while read image; do echo >&2 "+ caching $image"; pdsh -w "$workers" "crictl pull $image"; done
   ```

   > HOW-TO: **Manually precache images.** Inspect the `cray-precache-images`
   > chart configuration in the new platform.yaml manifest to get the list of
   > images that must be precached:
   >
   > ```bash
   > ncn-m001# yq r ./${CSM_RELEASE}/manifests/platform.yaml 'spec.charts(name==cray-precache-images).values.cacheImages[*]'
   > docker.io/sonatype/nexus3:3.25.0
   > dtr.dev.cray.com/cray/cray-nexus-setup:0.3.2
   > dtr.dev.cray.com/baseos/busybox:1
   > dtr.dev.cray.com/cray/cray-dns-unbound:0.2.18
   > dtr.dev.cray.com/cray/proxyv2:1.7.8-cray1
   > k8s.gcr.io/pause:3.2
   > dtr.dev.cray.com/k8s.gcr.io/pause:3.2
   > ```
   >
   > Images are cached on a worker node using `crictl pull`, e.g.:
   >
   > ```bash
   > ncn-w# crictl pull docker.io/sonatype/nexus3:3.25.0
   > Image is up to date for sha256:0aedb49b54b0cc4499b02de66d41f45b956f911932e733f60b436165f4cb4d2d
   > ```
   >
   > Use `pdsh 'crictl pull ...'` to cache each image on all workers, e.g.:
   >
   > ```bash
   > ncn# workers="$(kubectl get node --selector='!node-role.kubernetes.io/master' -o name | sed -e 's,^node/,,' | paste -sd,)"
   > ncn# export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
   > ncn# pdsh -w "$workers" 'crictl pull docker.io/sonatype/nexus3:3.25.0'
   > ncn-w001: Image is up to date for sha256:0aedb49b54b0cc4499b02de66d41f45b956f911932e733f60b436165f4cb4d2d
   > ncn-w003: Image is up to date for sha256:0aedb49b54b0cc4499b02de66d41f45b956f911932e733f60b436165f4cb4d2d
   > ncn-w002: Image is up to date for sha256:0aedb49b54b0cc4499b02de66d41f45b956f911932e733f60b436165f4cb4d2d
   > ```

4. Gather any logs/info from pods in a `Completed` state on the worker node being updated.

   > NOTE: Pods in a `Completed` state are not moved to another worker node when the node being upgraded is drained, but rather they are deleted.  ***If the administrator would like to gather any information from pods in this state, now is the last chance to do so.***

5. Ensure that the previously rebuilt worker node (if applicable) has started any etcd pods (if necessary).  ***We don't want to begin rebuilding the next worker node until etcd pods have reached quorum.***  Run the following command, and pause on this step until all pods are in a `Running` state:

   ```bash
   ncn#  kubectl get po -A -l 'app=etcd'
   ```

6. Use the script provided in this repository to cordon/drain the node.  This will evacuate pods running on the node.

   ```bash
   ncn# /usr/share/doc/csm/upgrade/1.0/scripts/k8s/remove-k8s-node.sh $UPGRADE_NCN
   ```

Proceed to [Common Upgrade Steps](../common/upgrade-steps.md)
