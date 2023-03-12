# `iuf run` Examples

**`NOTE`** Due to the large number of arguments available for `iuf run` invocations, these examples only include often used key arguments.

(`ncn-m001#`) Execute stages `process-media` through `deliver-product` for activity `admin-230126`.

```bash
iuf -a admin-230126 run -b process-media -e deliver-product
```

---

(`ncn-m001#`) Execute stages `process-media` through `deliver-product` for activity `admin-230126` but skip the `pre-install-check` stage.

```bash
iuf -a admin-230126 run -b process-media -e deliver-product -s pre-install-check
```

---

(`ncn-m001#`) Execute the `update-vcs-config` stage for activity `admin-230126` using recipe variables `./recipe_vars.yaml` and site variables `./site_vars.yaml`.

```bash
iuf -a admin-230126 run -r update-vcs-config -rv ./recipe_vars.yaml -sv ./site_vars.yaml
```

---

(`ncn-m001#`) Execute the `prepare-images` stage for activity `admin-230126` using the HPE-provided `sat bootprep` input and recipe variables files in `/etc/cray/upgrade/csm/admin` and site variables `/etc/cray/upgrade/csm/admin/site_vars.yaml`.

```bash
iuf -a admin-230126 run -r prepare-images -bpcd /etc/cray/upgrade/csm/admin -sv /etc/cray/upgrade/csm/admin/site_vars.yaml
```

---

(`ncn-m001#`) Execute the `prepare-images` stage for activity `admin-230126` using the management `sat bootprep` input file `./management-bootprep.yaml` and the managed `sat bootprep` input file `./compute-and-uan-bootprep.yaml`.

```bash
iuf -a admin-230126 run -r prepare-images -bm ./management-bootprep.yaml -bc ./compute-and-uan-bootprep.yaml
```

---

(`ncn-m001#`) Execute the `management-nodes-rollout` stage for activity `admin-230126` using `--limit-management-rollout` to only target `Management_Worker` nodes and `-cmrp` to roll out 30% of nodes concurrently.

```bash
iuf -a admin-230126 run -r management-nodes-rollout --limit-management-rollout Management_Worker -cmrp 30
```

---

(`ncn-m001#`) Execute the `managed-nodes-rollout` stage for activity `admin-230126` using `--limit-managed-rollout` to only target nodes in the `Compute` HSM node group and `-mrs` to reboot nodes immediately.

```bash
iuf -a admin-230126 run -r managed-nodes-rollout --limit-managed-rollout Compute -mrs reboot
```
