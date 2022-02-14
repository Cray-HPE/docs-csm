## Artifact Management

The Ceph Object Gateway Simple Storage Service \(S3\) API is used for artifact management. The RESTful API that Ceph provides via the gateway is compatible with the basic data access model of the Amazon S3 API. See the [https://docs.ceph.com/en/pacific/radosgw/s3/](https://docs.ceph.com/en/pacific/radosgw/s3/) for more information about compatibility. The object gateway is also referred to as the RADOS gateway or simply RGW.

S3 is an object storage service that provides high-level performance, scalability, security, and data availability. S3 exposes a rudimentary data model, similar to a file system, where buckets \(directories\) store objects \(files\). Bucket- and object-level Access Control Lists \(ACL\) can be provided for flexible access authorization to artifacts stored in S3.

### RGW on HPE Cray EX Systems

RGW is installed as a part of the HPE Cray EX Stage 3 deployment. The S3 API is available on systems at the following location:

```bash
https://rgw-vip.local
```

The RGW administrative interface \(`radosgw-admin`\) is available on non-compute nodes \(NCNs\).



