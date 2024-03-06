# Manage Artifacts with the Cray CLI

The artifacts \(objects\) available for use on the system are created and managed with the Cray CLI.
The `cray artifacts` command provides the ability to manage any given artifact. The Cray CLI automatically
authenticates users and provides Simple Storage Service \(S3\) credentials.

- [Authenticate with the CLI](#authenticate-with-the-cli)
- [View S3 buckets](#view-s3-buckets)
- [List artifacts](#list-artifacts)
- [Retrieve artifact details](#retrieve-artifact-details)
- [Create and upload artifacts](#create-and-upload-artifacts)
- [Download artifacts](#download-artifacts)
- [Delete artifacts](#delete-artifacts)

## Authenticate with the CLI

(`ncn#`) All operations with the `cray artifacts` command assume that the user has already been authenticated.
If the user has not been authenticated with the Cray CLI, then run the following command:

```bash
cray auth login
```

Enter the appropriate credentials when prompted:

```text
Username: adminuser
Password:
```

`Success!` will be returned if the user is successfully authenticated.

For more information on how to initialize and authenticate the `cray` CLI, see [Configure the Cray Command Line Interface](../configure_cray_cli.md).

## View S3 buckets

(`ncn#`) There are several S3 buckets available that can be used to upload and download files with the `cray artifacts` command.
In order to see the list of available S3 buckets, run the following command:

```bash
cray artifacts buckets list --format toml
```

Example output:

```toml
results = [ "alc", "badger", "benji-backups", "boot-images", "etcd-backup", "fw-update", "ims", "nmd", "sds", "ssm", "vbis", "wlm",]
```

## List artifacts

(`ncn#`) Use the `cray artifacts list` command to list all artifacts in a bucket.

```bash
cray artifacts list S3_BUCKET --format toml
```

Example output:

```toml
[[artifacts]]
Key = "138cd9e3-a855-4485-a067-87a3f4ff991e/initrd"
LastModified = "2024-03-01T11:50:00.955000+00:00"
ETag = "\"59f3827a5ce243243469a5df7716a96f-12\""
Size = 99105989
StorageClass = "STANDARD"

[artifacts.Owner]
DisplayName = ""
ID = "STS"
```

## Retrieve artifact details

(`ncn#`) Details of an artifact object in a bucket are displayed using the `cray artifacts describe` command.
The output of this command provides information about the size of the artifact and any metadata associated with the object.

**IMPORTANT:** The Cray-specific metadata provided by this command is automatically generated. This metadata should be considered deprecated and should not be used for future development.

```bash
cray artifacts describe S3_BUCKET S3_OBJECT_KEY --format toml
```

Example output:

```toml
[artifact]
AcceptRanges = "bytes"
LastModified = "2024-03-01T11:50:00+00:00"
ContentLength = 99105989
ETag = "\"59f3827a5ce243243469a5df7716a96f-12\""
ContentType = "binary/octet-stream"

[artifact.Metadata]
md5sum = "3e9bfd34f94bce3bac938b011af82840"
```

## Create and upload artifacts

(`ncn#`) Use the `cray artifacts create` command to create an object and upload it to S3.

```bash
cray artifacts create S3_BUCKET S3_OBJECT_KEY UPLOAD_FILEPATH
```

For example: 

```bash
cray artifacts create boot-images 138cd9e3-a855-4485-a067-87a3f4ff991e/initrd initrd
```

Example output:

```toml
artifact = "138cd9e3-a855-4485-a067-87a3f4ff991e/initrd"
Key = "138cd9e3-a855-4485-a067-87a3f4ff991e/initrd"
```

In S3, the object name can be path-like and include slashes to resemble files in directories. This is useful for organizing objects within a bucket, but S3 treats it as a name only. No directory structure exists.

When interacting with Cray services, use the artifact value returned by the `cray artifacts create` command. This will ensure that Cray services can access the uploaded object.

## Download artifacts

(`ncn#`) Artifacts are downloaded with the `cray artifacts get` command. The command requires the object name, the bucket, and a file path for the downloaded artifact.

```bash
cray artifacts get S3_BUCKET S3_OBJECT_KEY DOWNLOAD_FILEPATH
```

For example:

```bash
cray artifacts get boot-images 138cd9e3-a855-4485-a067-87a3f4ff991e/initrd initrd
```

No output is shown unless an error occurs.

## Delete artifacts

(`ncn#`) Artifacts are removed from buckets with the `cray artifacts delete` command. The command requires the object name and the bucket name.

```bash
cray artifacts delete S3_BUCKET S3_OBJECT_KEY
```

No output is shown unless an error occurs.
