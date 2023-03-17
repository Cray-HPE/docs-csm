# `process-media`

The `process-media` stage extracts all product distribution files found in the media directory specified by the user via `-m` and associates it with an activity identifier provided by the `-a` argument. The product
content is extracted into that same directory. All future stages associated with the activity will execute for all applicable products found in the media directory, and thus `-m` does not need to be specified for future stages.

**`NOTE`** `process-media` must be run at least once for a given activity before any of the other stages can be run. This is required because `process-media` associates the product content being installed or upgraded with an
activity identifier and that information is used for all other stages.

`process-media` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `process-media` stage does not change the running state of the system.

## Input

The following arguments are most often used with the `process-media`. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description                                                                     |
| --------------- | -------------- | ------------------------------------------------------------------------------- |
| Activity        | `-a ACTIVITY`  | Activity created for the install or upgrade operations                          |
| Media directory | `-m MEDIA_DIR` | Directory containing the product distribution files to be installed or upgraded |

## Execution details

The code executed by this stage exists within IUF. See the `process-media` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `process-media` stage with product distribution content found in `/etc/cray/upgrade/csm/media/admin-230127`, creating an activity named `admin-230127` in the process.

```bash
iuf -a admin-230127 -m /etc/cray/upgrade/csm/media/admin-230127 run -r process-media
```
