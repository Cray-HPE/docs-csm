# SAT and IUF

The Install and Upgrade Framework (IUF) provides commands which install, upgrade, and deploy
products on systems managed by CSM with the help of `sat bootprep`. Outside of IUF, it is uncommon
to use `sat bootprep`.

For more information on IUF, see [Install and Upgrade Framework](../../iuf/IUF.md). For more
information on `sat bootprep`, see [SAT Bootprep](SAT_Bootprep.md).

## Variable Substitutions

Both IUF and `sat bootprep` allow variable substitutions into the default HPC
CSM Software Recipe bootprep input files. The default variables of the HPC
CSM Software Recipe are available in a `product_vars.yaml` file. To override
the default variables, specify any site variables in a `site_vars.yaml` file.
Variables are sourced from the command line, any variable files directly
provided, and the HPC CSM Software Recipe files used, in that order.

### IUF Session Variables

IUF also has special session variables internal to the `iuf` command that
override any matching entries. Session variables are the set of product and
version combinations being installed by the current IUF activity, and they are
found inside IUF's internal `session_vars.yaml` file. For more information on
IUF and variable substitutions, see [Install and Upgrade Framework](../../iuf/IUF.md).

### SAT Variable Limitations

When using `sat bootprep` outside of IUF, substituting variables into the
default bootprep input files might cause problems. Complex variables like
`"{{ working_branch }}"` cannot be completely resolved outside of IUF and
its internal session variables. Thus, the default `product_vars.yaml` file is
unusable with only the `sat bootprep` command when variables like
`"{{ working_branch }}"` are used. To work around this limitation when
substituting complex variables, use the internal IUF `session_vars.yaml` file
with `sat bootprep` and the default bootprep input files.

1. Find the `session_vars.yaml` file from the most recent IUF activity on the
   system.

   This process is documented in the CSM upgrade procedure, during the prerequisites stage. See
   steps 1-6 of [Stage 0.3 - Option 2](../../../upgrade/Stage_0_Prerequisites.md#option-2-upgrade-of-csm-on-system-with-additional-products).

1. (`ncn-m001#`) Use the `session_vars.yaml` file to substitute variables into the default
   bootprep input files.

   ```bash
   sat bootprep run --vars-file session_vars.yaml
   ```

## Limit SAT Bootprep Run into Stages

The `sat bootprep run` command uses information from the bootprep input files
to create CFS configurations, IMS images, and BOS session templates. To restrict
this creation into separate stages, use the `--limit` option and list whether
to create `configurations`, `images`, `session_templates`, or some
combination of these. IUF uses the `--limit` option in this way to install,
upgrade, and deploy products on a system in stages.

(`ncn-m001#`) For example, to create only CFS configurations, run the following command used
by the IUF `update-cfs-config` stage:

```bash
sat bootprep run --limit configurations example-bootprep-input-file.yaml
```

Example output:

```text
INFO: Validating given input file example-bootprep-input-file.yaml
INFO: Input file successfully validated against schema
INFO: Creating 3 CFS configurations
...
INFO: Skipping creation of IMS images based on value of --limit option.
INFO: Skipping creation of BOS session templates based on value of --limit option.
```

(`ncn-m001#`) To create only IMS images and BOS session templates, run the following command
used by the IUF `prepare-images` stage:

```bash
sat bootprep run --limit images --limit session_templates example-bootprep-input-file.yaml
```

Example output:

```text
INFO: Validating given input file example-bootprep-input-file.yaml
INFO: Input file successfully validated against schema
INFO: Skipping creation of CFS configurations based on value of --limit option.
```
