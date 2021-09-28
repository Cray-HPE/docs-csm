# Landing spot for all csi supported storage configuations.
## Below is for 1.2 - Moving provsioners to namespaces

function create_ceph_rbd_1.2_csi_configmap () {
  FSID=$(ceph fsid)
  MON_DUMP=$(ceph mon dump -f json)
   echo "---
   apiVersion: v1
   kind: ConfigMap
   data:
     config.json: |-
       [
         {
           \"clusterID\": \"$FSID\",
           \"monitors\": [
             $(echo $MON_DUMP|jq '.mons[0]|.public_addrs.addrvec[1].addr'),
             $(echo $MON_DUMP|jq '.mons[1]|.public_addrs.addrvec[1].addr'),
             $(echo $MON_DUMP|jq '.mons[2]|.public_addrs.addrvec[1].addr')
           ]
         }
       ]
   metadata:
     name: ceph-csi-config
     namespace: ceph-rbd
   " > /srv/cray/tmp/csi_rbd_configmap.yaml

   kubectl apply -f /srv/cray/tmp/csi_rbd_configmap.yaml

}


function create_ceph_cephfs_1.2_csi_configmap () {
  FSID=$(ceph fsid)
  MON_DUMP=$(ceph mon dump -f json)
   echo "---
   apiVersion: v1
   kind: ConfigMap
   data:
     config.json: |-
       [
         {
           \"clusterID\": \"$FSID\",
           \"monitors\": [
             $(echo $MON_DUMP|jq '.mons[0]|.public_addrs.addrvec[1].addr'),
             $(echo $MON_DUMP|jq '.mons[1]|.public_addrs.addrvec[1].addr'),
             $(echo $MON_DUMP|jq '.mons[2]|.public_addrs.addrvec[1].addr')
           ]
         }
       ]
   metadata:
     name: ceph-csi-config
     namespace: ceph-cephfs
     " > /srv/cray/tmp/csi_cephfs_configmap.yaml

   kubectl apply -f /srv/cray/tmp/csi_cephfs_configmap.yaml

}

function create_k8s_1.2_ceph_secrets () {
  CEPH_KUBE_KEY=$(ceph auth get-key client.kube)

  echo "---
  apiVersion: v1
  kind: Secret
  metadata:
    name: csi-kube-secret
    namespace: ceph-rbd
  stringData:
    userID: kube
    userKey: $CEPH_KUBE_KEY
  " > /srv/cray/tmp/csi_kube_secret.yaml
  kubectl apply -f /srv/cray/tmp/csi_kube_secret.yaml
}

function create_sma_1.2_ceph_secrets () {
  CEPH_SMA_KEY=$(ceph auth get-key client.smf)

  echo "---
  apiVersion: v1
  kind: Secret
  metadata:
    name: csi-sma-secret
    namespace: ceph-rbd
  stringData:
    userID: smf
    userKey: $CEPH_SMA_KEY
  " > /srv/cray/tmp/csi_sma_secret.yaml
  kubectl apply -f /srv/cray/tmp/csi_sma_secret.yaml
}

function create_cephfs_1.2_ceph_secrets () {
  CEPH_CEPHFS_KEY=$(ceph auth get-key client.admin)

  echo "---
  apiVersion: v1
  kind: Secret
  metadata:
    name: csi-cephfs-secret
    namespace: ceph-cephfs
  stringData:
    userID: admin
    userKey: $CEPH_CEPHFS_KEY
    adminID: admin
    adminKey: $CEPH_CEPHFS_KEY
  " > /srv/cray/tmp/csi_cephfs_secret.yaml
  kubectl apply -f /srv/cray/tmp/csi_cephfs_secret.yaml
}

function create_k8s_1.2_storage_class {
  FSID=$(ceph fsid)
  echo "---
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: kube-csi-sc
    namespace: ceph-rbd
  data:
    sc-kube.yaml: |
      ---
      apiVersion: storage.k8s.io/v1
      kind: StorageClass
      metadata:
         name: k8s-block-replicated
      provisioner: rbd.csi.ceph.com
      allowVolumeExpansion: true
      parameters:
         clusterID: $FSID
         pool: kube
         csi.storage.k8s.io/provisioner-secret-name: csi-kube-secret
         csi.storage.k8s.io/provisioner-secret-namespace: default
         csi.storage.k8s.io/controller-expand-secret-name: csi-kube-secret
         csi.storage.k8s.io/controller-expand-secret-namespace: default
         csi.storage.k8s.io/node-stage-secret-name: csi-kube-secret
         csi.storage.k8s.io/node-stage-secret-namespace: default
         imageFeatures: layering
      reclaimPolicy: Delete
      mountOptions:
         - discard
  " | kubectl apply -f -
}

function create_sma_1.2_storage_class {
  FSID=$(ceph fsid)
  echo "---
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: sma-csi-sc
    namespace: ceph-rbd
  data:
    sc-sma.yaml: |
      ---
      apiVersion: storage.k8s.io/v1
      kind: StorageClass
      metadata:
         name: sma-block-replicated
      provisioner: rbd.csi.ceph.com
      allowVolumeExpansion: true
      parameters:
         clusterID: $FSID
         pool: smf
         csi.storage.k8s.io/provisioner-secret-name: csi-sma-secret
         csi.storage.k8s.io/provisioner-secret-namespace: default
         csi.storage.k8s.io/controller-expand-secret-name: csi-sma-secret
         csi.storage.k8s.io/controller-expand-secret-namespace: default
         csi.storage.k8s.io/node-stage-secret-name: csi-sma-secret
         csi.storage.k8s.io/node-stage-secret-namespace: default
         imageFeatures: layering
      reclaimPolicy: Delete
      mountOptions:
         - discard
  " | kubectl apply -f -
}

function create_cephfs_1.2_storage_class {
  FSID=$(ceph fsid)
  echo "---
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: cephfs-csi-sc
    namespace: ceph-cephfs
  data:
    sc-cephfs.yaml: |
      ---
      apiVersion: storage.k8s.io/v1
      kind: StorageClass
      metadata:
         name: ceph-cephfs-external
      provisioner: cephfs.csi.ceph.com
      parameters:
         clusterID: $FSID
         fsName: cephfs
         pool: $(ceph fs ls --format json-pretty|jq -r '.[].data_pools[]')
         csi.storage.k8s.io/provisioner-secret-name: csi-cephfs-secret
         csi.storage.k8s.io/provisioner-secret-namespace: default
         csi.storage.k8s.io/controller-expand-secret-name: csi-cephfs-secret
         csi.storage.k8s.io/controller-expand-secret-namespace: default
         csi.storage.k8s.io/node-stage-secret-name: csi-cephfs-secret
         csi.storage.k8s.io/node-stage-secret-namespace: default
      reclaimPolicy: Delete
      allowVolumeExpansion: true
      mountOptions:
  " | kubectl apply -f -
}