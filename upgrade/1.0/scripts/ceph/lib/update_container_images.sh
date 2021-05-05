#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

function update_image_values () {
 IMAGE="$registry/ceph/ceph:v15.2.8"
 ceph config set global container_image $IMAGE
 for SERVICE in mon mgr osd mds client
  do
   CURRENT_IMG_VALUE=$(ceph config get $SERVICE container_image)
   echo "Current image value for $SERVICE is $CURRENT_IMG_VALUE"
   if [ "$CURRENT_IMG_VALUE" != "$IMAGE" ]
   then
    ceph config set $SERVICE $IMAGE
   fi
  done
}
