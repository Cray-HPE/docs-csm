# `process-media`

The `process-media` stage extracts all product distribution files found in the media directory specified by the user via `-m`. The product content is extracted into that same directory. All future stages associated with the activity
will execute for all applicable products found in the media directory.

## Impact

The `process-media` stage does not change the running state of the system.

## Input

The following arguments are most often used with the `process-media`. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description |
| --------------- | -------------- | ----------- |
| activity        | `-a ACTIVITY`  | activity created for the install or upgrade operations |
| media directory | `-m MEDIA_DIR` | directory containing the product distribution files to be installed |

## Execution Details

The code executed by this stage exists within IUF. See the `process-media` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `process-media` stage with product distribution content found in `/opt/cray/iuf/joe/`.

```bash
iuf -a joe-install-20230107 -m /opt/cray/iuf/joe/ run -r process-media
```
