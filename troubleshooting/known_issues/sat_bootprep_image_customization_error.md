# `sat bootprep` image customization error

On CSM 1.5.2 systems, the following error occurs when you try to customize an image using the `sat bootprep` command directly from management nodes:

```text
Traceback (most recent call last):
  File "/sat/venv/bin/sat", line 8, in <module>
    sys.exit(main())
  File "/sat/venv/lib/python3.9/site-packages/sat/main.py", line 122, in main
    subcommand(args)
  File "/sat/venv/lib/python3.9/site-packages/sat/cli/bootprep/main.py", line 405, in do_bootprep
    do_bootprep_run(schema_validator, args)
  File "/sat/venv/lib/python3.9/site-packages/sat/cli/bootprep/main.py", line 287, in do_bootprep_run
    created_images = create_images(instance, args, ims_client)
  File "/sat/venv/lib/python3.9/site-packages/sat/cli/bootprep/image.py", line 520, in create_images
    waiter.wait_for_completion()
  File "/sat/venv/lib/python3.9/site-packages/sat/waiting.py", line 331, in wait_for_completion
    super().wait_for_completion()
  File "/sat/venv/lib/python3.9/site-packages/sat/waiting.py", line 169, in wait_for_completion
    self._wait_polling_loop()
  File "/sat/venv/lib/python3.9/site-packages/sat/waiting.py", line 549, in _wait_polling_loop
    if self.member_has_completed(member):
  File "/sat/venv/lib/python3.9/site-packages/sat/cli/bootprep/image.py", line 407, in member_has_completed
    if member.has_completed:
  File "/sat/venv/lib/python3.9/site-packages/sat/cli/bootprep/input/image.py", line 513, in has_completed
    self.begin_image_configure()
  File "/sat/venv/lib/python3.9/site-packages/sat/cli/bootprep/input/image.py", line 405, in begin_image_configure
    self.image_configure_session = self.cfs_client.create_image_customization_session(
TypeError: create_image_customization_session() missing 1 required positional argument: 'image_name' 
```

This affects versions 3.25.14 and 3.25.15 of the `sat` CLI. The version of the `sat` CLI can be
viewed with `sat --version`. These versions of the `sat` CLI were included in SAT product versions
2.6.18 and 2.6.19, respectively.

## Workaround

Set the environment variable `SAT_IMAGE` to point at the older version of
`cray-sat` provided by CSM 1.5.2 instead of the version from the newer SAT product stream.
Do this only for `sat bootprep` commands. For example,

```bash
SAT_IMAGE="registry.local/artifactory.algol60.net/sat-docker/stable/cray-sat:3.25.11" sat bootprep run
```
