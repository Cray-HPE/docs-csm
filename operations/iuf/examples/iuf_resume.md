# `iuf resume` Examples

(`ncn-m001#`) Begin executing stages `process-media` through `deliver-product` for activity `admin-230126`.

```bash
iuf -a admin-230126 run -b process-media -e deliver-product
```

(`ncn-m001#`) Forcefully abort activity `admin-230126` while it is still executing, causing the current stage to fail immediately.

```bash
iuf -a admin-230126 abort -f
```

(`ncn-m001#`) Resume activity `admin-230126` to re-execute any failed or aborted steps in the most recent stage of the IUF session specified earlier via `iuf run` and then execute any remaining steps that were not run prior
the execution of `iuf abort`.

```bash
iuf -a admin-230126 resume
```

(`ncn-m001#`) Resume activity `admin-230126` and add a comment to the activity log.

```bash
iuf -a admin-230126 resume "resuming activity"
```
