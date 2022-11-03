# Manage Artifacts with the Cray CLI

The artifacts \(objects\) available for use on the system are created and managed with the Cray CLI. The cray artifacts command provides the ability to manage any given artifact. The Cray CLI automatically authenticates users and provides Simple Storage Service \(S3\) credentials.

All operations with the cray artifacts command assume that the user has already been authenticated. If the user has not been authenticated with the Cray CLI, run the following command and enter the appropriate credentials:

```bash
ncn# cray auth login
Username: adminuser
Password:
Success!
```

**Authorization Is Local to a Host:** whenever you are using the CLI (`cray` command) on a host (e.g. a workstation or NCN) where it has not been used before, it is necessary to authenticate on that host using `cray auth login`. There is no mechanism to distribute CLI authorization amongst hosts.

### View S3 Buckets

There are several S3 buckets available that can be used to upload and download files with the cray artifacts command. To see the list of available S3 buckets:

```screen
ncn# cray artifacts buckets list
results = [ "alc", "badger", "benji-backups", "boot-images", "etcd-backup", "fw-update", "ims", "nmd", "sds", "ssm", "vbis", "wlm",]
```

### Create and Upload Artifacts

Use the `cray artifacts create` command to create an object and upload it to S3.

In the example below, S3\_BUCKET is a placeholder for the bucket name, site/repos/repo.tgz is the object name, and /path/to/repo.tgz is the location of the file to be uploaded to S3 on the local file system.

```bash
ncn# cray artifacts create S3_BUCKET site/repos/repo.tgz /path/to/repo.tgz
artifact = "5c5b6ae5-64da-4212-887a-301087a17099"
Key = "site/repos/repo.tgz"
```

In S3, the object name can be path-like and include slashes to resemble files in directories. This is useful for organizing objects within a bucket, but S3 treats it as a name only. No directory structure exists.

When interacting with Cray services, use the artifact value returned by the cray artifacts create command. This will ensure that Cray services can access the uploaded object.

### Download Artifacts

Artifacts are downloaded with the cray artifacts get command. Provide the object name, the bucket, and a file path to download the artifact in order to use this command.

```bash
ncn# cray artifacts get S3_BUCKET S3_OBJECT_KEY DOWNLOAD_FILEPATH
```

For example:

```bash
ncn# cray artifacts get boot-images 5c5b6ae5-64da-4212-887a-301087a17099 /path/to/downloads/dl-repo.tgz
```

No output is shown unless an error occurs.

### Delete Artifacts

Artifacts are removed from buckets with the `cray artifacts delete` command. Provide the object name and the bucket to delete it.

```bash
ncn# cray artifacts delete S3_BUCKET S3_OBJECT_KEY
```

No output is shown unless an error occurs.

### List Artifacts

Use the `cray artifacts list` command to list all artifacts in a bucket.

```bash
ncn# cray artifacts list S3_BUCKET
[[artifacts]]
LastModified = "2020-04-03T12:20:23.876000+00:00"
ETag = "\"e3f195c20a2399bf1b5a20df12416115\""
StorageClass = "STANDARD"
Key = "recipes/47411cbe-e249-40f2-8c13-0df7856b91a3/recipe.tar.gz"
Size = 11234

[artifacts.Owner]
DisplayName = "Image Management Service User"
ID = "IMS"

...
```

### Retrieve Artifact Details

Details of an artifact object in a bucket are found with the `cray artifacts describe` command. The output of this command provides information about the size of the artifact and any metadata associated with the object.

**IMPORTANT:** The Cray-specific metadata provided by this command is automatically generated. This metadata should be considered deprecated and should not be used for future development.

```bash
ncn# cray artifacts describe S3_BUCKET S3_OBJECT_KEY
[artifact]
AcceptRanges = "bytes"
ContentType = "binary/octet-stream"
LastModified = "2020-04-03T12:20:23+00:00"
ContentLength = 11234
VersionId = ".2aoRPGDGRuRIFrjc9urQiHLADvwPCU"
ETag = "\"e3f195c20a2399bf1b5a20df12416115\""

[artifact.Metadata]
md5sum = "e3f195c20a2399bf1b5a20df12416115"
```

