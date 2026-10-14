# Race Condition Creating Gitea Repository during IUF `deliver-product` Stage

## Summary

During the IUF `deliver-product` stage, `cf-gitea-import` can fail with a
`500 Internal Server Error` while creating a Gitea repository. This happens when two product
variants (for example, the same product built for two different architectures, such as
`aarch64` and `x86_64`) are delivered in the same IUF session and both resolve to the **same**
Gitea repository name (e.g. a shared `slingshot-shmem-config-management` repository).

`cf-gitea-import` tries creating the repository before importing content. When two `deliver-product` sub-workflows for different architecture variants of the same product requests creating the same repository to be handled near-simultaneous(
collision), both tries creating the same repository almost simultaneously while the first sub-workflow receives "repository already exists" or "successfully created" response
while the second sub-workflow instead receives `500 Internal Server Error` and the stage fails:

```text
DEBUG - Attempting to create gitea repository: https://api-gw-service-nmn.local/vcs/api/v1/org/cray/repos
Traceback (most recent call last):
  File "/opt/csm/cf-gitea-import/./import.py", line 439, in <module>
    create_gitea_repository(repo_name, org, gitea_url, repo_privacy, session)
  File "/opt/csm/cf-gitea-import/./import.py", line 103, in create_gitea_repository
    resp.raise_for_status()
  File "/usr/lib/python3.9/site-packages/requests/models.py", line 953, in raise_for_status
    raise HTTPError(http_error_msg, response=self)
requests.exceptions.HTTPError: 500 Server Error: Internal Server Error for url: https://api-gw-service-nmn.local/vcs/api/v1/org/cray/repos
```

If there is no near-simultaneous(collision), the second caller also receives the "repository already exists" response from Gitea and `cf-gitea-import` proceeds normally without error.
The failure is timing-dependent race rather than a deterministic misconfiguration, which is why re-running the
same stage does not always reproduce it.

### Workaround

1. Ensure the failure is whether the race condition mentioned by checking that the `deliver-product` Argo logs show a
   `500 Server Error` on `.../org/cray/repos` for a repository shared by more than one product
   architecture variant.

1. Re-run the `deliver-product` stage:

    ```bash
    iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run --site-vars "${ADMIN_DIR}/site_vars.yaml" -bpcd "${ADMIN_DIR}" -r deliver-product --force
    ```

    On the re-run, the repository already exists (created by the variant that won the original
    race), so `cf-gitea-import` receives the "repository already exists" response and continues
    without error.

1. Verify the repository is present and importable:

    ```bash
    curl -s https://api-gw-service-nmn.local/vcs/api/v1/repos/cray/<repo_name>
    ```
