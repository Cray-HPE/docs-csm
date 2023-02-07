# `iuf abort` Examples

(`ncn-m001#`) Abort activity `admin-230126`, allowing the current stage to complete.

```bash
iuf -a admin-230126 abort
```

---

(`ncn-m001#`) Abort activity `admin-230126` immediately, terminating all in progress operations.

```bash
iuf -a admin-230126 abort -f
```
