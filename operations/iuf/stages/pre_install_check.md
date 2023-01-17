# `pre-install-check`

The `pre-install-check` stage ensures that CSM is operating properly so that products can be installed. For example, it verifies that S3 storage is functional, that CFS, VCS, and IMS microservices are functional, etc. Products may provide hook scripts to perform additional product-specific system checks.

The `pre-install-check` stage does not change the running state of the system.

## Required Input

The following arguments must be specified. See `iuf -h` and `iuf run -h` for additional optional arguments.

| Input           | `iuf` Argument |
| --------------- | -------------- |
| activity        | `-a ACTIVITY`  |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `pre-install-check` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(ncn-m001#) Execute the `pre-install-check` stage.

```bash
iuf -a joe-install-20230107 run -r pre-install-check
INFO All logs will be stored in /etc/cray/upgrade/csm/iuf/joe-install-20230107/log/20230107223713
INFO MONITORING SESSION: joe-install-20230107rr78c
INFO BEGINNING STAGE: pre-install-check
INFO     WORKFLOW ID: joe-install-20230107rr78c-pre-install-check-nn9hs
INFO         BEGIN PHASE: preflight-checks-for-services
INFO         BEGIN PHASE: preflight-checks
INFO         BEGIN PHASE: preflight-checks(0)
INFO      FINISHED PHASE: preflight-checks-for-services [Succeeded]
INFO      FINISHED PHASE: preflight-checks [Succeeded]
INFO      FINISHED PHASE: preflight-checks(0) [Succeeded]
INFO          RESULT: Succeeded
INFO        DURATION: 0:00:22
INFO Install completed in 0:00:27
----------------
Stage Summary
activity session: joe-install-20230107
command line: iuf -a joe-install-20230107 run -r pre-install-check
log dir: /etc/cray/upgrade/csm/iuf/joe-install-20230107/log
media dir: /opt/cray/iuf/joe/
ran stages: process-media pre-install-check
----------------
```
