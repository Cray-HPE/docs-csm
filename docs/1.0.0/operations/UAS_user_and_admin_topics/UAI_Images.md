# UAI Images

There are three kinds of UAI images used by UAS:

* A pre-packaged broker UAI image provided with the UAS
* A pre-packaged basic end-user UAI Image provided with the UAS
* Custom end-user UAI images created on site, usually based on compute node contents

UAS provides two stock UAI images when installed. The first is a standard end-user UAI Image that has the necessary software installed in it to support a basic Linux distribution login experience. This image also comes with with the Slurm and PBS Professional workload management client software installed, allowing users to take advantage of one or both of these if the underlying support is installed on the host system.

The second image is a broker UAI image. Broker UAIs are a special type of UAIs used in the "broker based" operation model. Broker UAIs present a single SSH endpoint that responds to each SSH connection by locating or creating a suitable end-user UAI and redirecting the SSH session to that end-user UAI.

