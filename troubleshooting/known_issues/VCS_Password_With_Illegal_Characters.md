# VCS Password With Illegal Characters

In rare cases, a new CSM install will generate a VCS administrative password that contains illegal characters.

* [Symptoms](#symptoms)
    * [`csm-config-import` job failure](#csm-config-import-job-failure)
    * [`cmsdev` VCS subtest failure](#cmsdev-vcs-subtest-failure)
* [Remediation](#remediation)

## Symptoms

There are two ways that this problem is discovered.

### `csm-config-import` job failure

When this problem causes a `csm-config-import` job to fail, the Kubernetes pod log will end with an error
similar to the following.

```text
2024-06-13 21:11:20,793 - cf-gitea-import - DEBUG - Cloning repository: csm-config-management
Traceback (most recent call last):
  File "/opt/csm/cf-gitea-import/./import.py", line 446, in <module>
    git_repo = clone_repo(
  File "/opt/csm/cf-gitea-import/./import.py", line 119, in clone_repo
    return Repo.clone_from(clone_url, workdir, depth=1, multi_options=["--no-single-branch"])
  File "/usr/lib/python3.9/site-packages/git/repo/base.py", line 1328, in clone_from
    return cls._clone(
  File "/usr/lib/python3.9/site-packages/git/repo/base.py", line 1237, in _clone
    finalize_process(proc, stderr=stderr)
  File "/usr/lib/python3.9/site-packages/git/util.py", line 453, in finalize_process
    proc.wait(**kwargs)
  File "/usr/lib/python3.9/site-packages/git/cmd.py", line 600, in wait
    raise GitCommandError(remove_password_if_present(self.args), status, errstr)
git.exc.GitCommandError: Cmd('git') failed due to: exit code(128)
  cmdline: git clone -v --depth=1 --no-single-branch -- http://crayvcs:BPuN/M846JL5XKTTWVqcV2mhuZfzOC64nnZ/e54ri1M=@gitea-vcs/cray/csm-config-management.git /tmp/csm
  stderr: 'Cloning into '/tmp/csm'...
fatal: unable to access 'http://crayvcs:BPuN/M846JL5XKTTWVqcV2mhuZfzOC64nnZ/e54ri1M=@gitea-vcs/cray/csm-config-management.git/': URL rejected: Port number was not a decimal number between 0 and 65535
```

### `cmsdev` VCS subtest failure

When this problem is present, the `cmsdev` VCS subtest will report an error that resembles the following:

```text
ERROR (run tag Xe9tC-vcs): Command failed
```

If the test is run in verbose mode, or the `cmsdev` log file is examined, a line similar to the following is found:

```text
fatal: unable to access 'https://crayvcs:BPuN/M846JL5XKTTWVqcV2mhuZfzOC64nnZ/e54ri1M=@api-gw-service-nmn.local/vcs/test-cmsdev-zvkEP50G/harf-zEK1SuiP.git/': URL using bad/illegal format or missing URL
```

See [Software Management Services health checks](sms_health_check.md) for more information on running the test and locating its log file.

## Remediation

The VCS administrative user password needs to be changed to a value that does not contain illegal characters.
Legal passwords should only contain alphanumeric characters, dash/minus (`-`), and underscore (`_`). See
[Change VCS administrative user password](../../operations/configuration_management/VCS_Administrative_User.md#change-vcs-administrative-user-password).
