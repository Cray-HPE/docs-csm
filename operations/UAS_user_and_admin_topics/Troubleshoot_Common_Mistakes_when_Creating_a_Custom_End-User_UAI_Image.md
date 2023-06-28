# Troubleshoot Common Mistakes when Creating a Custom End-User UAI Image

There are several problems that may occur while making or working with custom end-user UAI images.
The following are some basic troubleshooting questions to ask:

* Does `SESSION_NAME` match an actual entry in `cray bos v1 sessiontemplate list`?
* Is the `SESSION_ID` set to an appropriate UUID format? Did the `awk` command not parse the UUID correctly?
* Did the file `/etc/security/limits.d/99-slingshot-network.conf` get removed from the tarball correctly?
* Does the `ENTRYPOINT` `/usr/bin/uai-ssh.sh` exist?
* Did the container image get pushed and registered with UAS?
* Did the creation process run from a real worker or master node as opposed to a LiveCD node?

[Top: User Access Service (UAS)](README.md)

[Next Topic: Troubleshoot UAS / CLI Authentication Issues](Troubleshoot_UAI_Authentication_Issues.md)
