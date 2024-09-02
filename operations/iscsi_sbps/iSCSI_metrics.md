# iSCSI based boot content projection metrics

## Description

https://github.com/Cray-HPE/sbps-marshal/blob/main/README.md

iSCSI based boot content projection (CPS) is replacing the DVS CPS. A few of the iSCSI metrics listed in (CASMPET-6820) are read from sysfs and projected to node exporter / promethus. 
This repo contains the files related to docker container image. The files are the scripts which retrieve the iSCSI metrics from sysfs every 28secs as prometheus scrape interval is 30secs and Dockerfile.  

Example:
```
ncn-w002:/sys/kernel/config/target/iscsi/iqn.2023-06.csm.iscsi:ncn-w002/tpgt_1/lun/lun_0/statistics/scsi_tgt_port # ls
dev  hs_in_cmds  in_cmds  indx  inst  name  port_index  read_mbytes  write_mbytes
ncn-w002:/sys/kernel/config/target/iscsi/iqn.2023-06.csm.iscsi:ncn-w002/tpgt_1/lun/lun_0/statistics/scsi_tgt_port # cat read_mbytes
137
```
## Getting Started
```
iscsi metrics can be retrieved on the particular node in text mode and web interface as below:
Text mode:
#curl <node_ip>:9100/metrics | grep iscsi
```
Web interface:
example URL to open if the system name is odin: https://prometheus.cmn.odin.hpc.amslabs.hpecorp.net
Then query for iscsi metrics.
```
### Prerequisites

iSCSI should be configured and SBPS marshal agent should be running where it projects the iSCSI luns to client(compute) nodes. 

### Installation

Setting up / Installation of worker nodes with iscsi and SBPS marshal agent is done via ansible play books (CASMPET-6797).

### Usage

This container image is stored at artifactory.algol60.net. commands to pull the image:
```
  docker login artifactory.algol60.net
  docker pull artifactory.algol60.net/csm-docker/unstable/iscsi-cps:0.0.0-1-g8f2625b
```
## Contributing

See the [CONTRIBUTING.md](CONTRIBUTING.md) file for how to contribute to this project.

## Changelog

See the [CHANGELOG.md](CHANGELOG.md) for the changes and release history of this project.

## Authors and Acknowledgments (optional)

Thanks to Jeremy Duckworth who was the lead for iscsi based content projection and Mikhail Tupitsyn who helped in  creating this repo and image. 

## License

This project is copyrighted by Hewlett Packard Enterprise Development LP and is distributed under the MIT license. See the [LICENSE.txt](LICENSE.txt) file for details.
