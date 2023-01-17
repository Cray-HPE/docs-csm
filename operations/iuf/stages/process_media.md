# `process-media`

The `process-media` stage extracts all product content found in the media directory specified by the user. The product content is extracted into that same directory. All future stages associated with the activity will execute for all applicable products found in the media directory.

The `process-media` stage does not change the running state of the system.

## Required Input

The following arguments must be specified. See `iuf -h` and `iuf run -h` for additional optional arguments.

| Input           | `iuf` Argument |
| --------------- | -------------- |
| activity        | `-a ACTIVITY`  |
| media directory | `-m MEDIA_DIR` |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `process-media` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(ncn-m001#) Execute the `process-media` stage with product distribution content found in `/opt/cray/iuf/joe/`.

```bash
iuf -a joe-install-20230107 -m /opt/cray/iuf/joe/ run -r process-media
INFO All logs will be stored in /etc/cray/upgrade/csm/iuf/joe-install-20230107/log/20230107215823
INFO MONITORING SESSION: joe-install-20230107u0sil
INFO BEGINNING STAGE: process-media
INFO     WORKFLOW ID: joe-install-20230107u0sil-process-media-8lqms
INFO         BEGIN PHASE: extract-release-distributions
INFO         BEGIN PHASE: start-operation
INFO      FINISHED PHASE: start-operation [Succeeded]
INFO         BEGIN PHASE: list-tar-files
INFO      FINISHED PHASE: list-tar-files [Succeeded]
INFO         BEGIN PHASE: extract-tar-files
INFO         BEGIN PHASE: extract-tar-files(0:cos-2.5.80-20230105215754.tar.gz)
INFO      FINISHED PHASE: extract-tar-files [Succeeded]
INFO      FINISHED PHASE: extract-tar-files(0:cos-2.5.80-20230105215754.tar.gz) [Succeeded]
INFO         BEGIN PHASE: end-operation
INFO      FINISHED PHASE: end-operation [Succeeded]
INFO         BEGIN PHASE: prom-metrics
INFO      FINISHED PHASE: extract-release-distributions [Succeeded]
INFO      FINISHED PHASE: prom-metrics [Succeeded]
INFO          RESULT: Succeeded
INFO        DURATION: 0:01:30
INFO Install completed in 0:01:36
----------------
Stage Summary
command line: iuf -a joe-install-20230107 -m /opt/cray/iuf/joe/ run -r process-media
activity session: joe-install-20230107
media dir: /opt/cray/iuf/joe/
log dir: /etc/cray/upgrade/csm/iuf/joe-install-20230107/log
ran stages: process-media
----------------
```
