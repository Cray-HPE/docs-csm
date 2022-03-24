# Troubleshoot Missing or Incorrect UAI Images

If a UAI shows a `uai_status` of `Waiting` and a `uai_msg` of `ImagePullBackOff`, that indicates that the UAI or the UAI class is configured to use an image that is not in the image registry.

Either obtaining and pushing the image to the image registry, or correcting the name or version of the image in the UAS configuration will usually resolve this.