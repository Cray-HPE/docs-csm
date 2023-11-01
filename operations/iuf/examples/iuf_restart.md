# `iuf restart` Examples

(`ncn-m001#`) Begin executing stages `process-media` through `deliver-product` for activity `admin-230126`.

```bash
iuf -a admin-230126 run -b process-media -e deliver-product
```

(`ncn-m001#`) Forcefully abort activity `admin-230126` while it is still executing, causing the current stage to fail immediately.

```bash
iuf -a admin-230126 abort -f
```

(`ncn-m001#`) Restart activity `admin-230126` to re-execute all failed or previously unexecuted steps in all stages of the IUF session specified earlier via `iuf run`.

```bash
iuf -a admin-230126 restart
```

---

(`ncn-m001#`) Begin executing stages `process-media` through `deliver-product` for activity `admin-230126`.

```bash
iuf -a admin-230126 run -b process-media -e deliver-product
```

(`ncn-m001#`) Forcefully abort activity `admin-230126` while it is still executing, causing the current stage to fail immediately.

```bash
iuf -a admin-230126 abort -f
```

(`ncn-m001#`) Restart activity `admin-230126` with the `-f` argument to re-execute all steps in all stages of the IUF session specified earlier via `iuf run`. Steps which previously executed successfully will be re-executed.

```bash
iuf -a admin-230126 restart -f
```

(`ncn-m001#`) Restart activity `admin-230126` and add a comment to the activity log.

```bash
iuf -a admin-230126 restart "Restarting activity admin-230126"
```
