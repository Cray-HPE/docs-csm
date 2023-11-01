# `iuf abort` Examples

(`ncn-m001#`) Abort activity `admin.05-15`, allowing the current stage to complete.

```bash
iuf -a admin.05-15 abort
```

---

(`ncn-m001#`) Abort activity `admin.05-15` immediately, terminating all in progress operations.

```bash
iuf -a admin.05-15 abort -f
```

(`ncn-m001#`) Abort activity `admin.05-15` immediately and add a comment to the activity log.

```bash
iuf -i input.yaml abort -f "Aborting the activity"
```
