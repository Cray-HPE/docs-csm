# Race Condition Creating Gitea Repository During IUF `deliver-product`

## Summary

During the IUF `deliver-product` stage, `cf-gitea-import` can fail with a
`500 Internal Server Error` while creating a Gitea repository. This happens when two product
variants (for example, the same product built for two different architectures, such as
`aarch64` and `x86_64`) are delivered in the same IUF session and both resolve to the **same**
Gitea repository name (e.g. a shared `*-config-management` repository).

`cf-gitea-import` creates the repository with a `POST` to `/vcs/api/v1/org/<org>/repos` before
importing content. When two `deliver-product` sub-workflows for different architecture variants
of the same product start at (or very near) the same time, both issue this `POST` call almost
simultaneously. Gitea's repository-creation endpoint is not safely idempotent under this kind of
concurrent, identical request: only one caller's request actually creates the repository. The
losing caller does not receive the "repository already exists" response that `cf-gitea-import`
already knows how to tolerate; instead it receives `500 Internal Server Error`, which is not
caught, so `resp.raise_for_status()` raises an unhandled `HTTPError` and the stage fails:

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

If there is any time gap between the two `POST` calls (rather than a near-simultaneous
collision), the second caller correctly receives the "already exists" response from Gitea and
`cf-gitea-import` proceeds normally without error. The failure is therefore a narrow,
timing-dependent race rather than a deterministic misconfiguration, which is why re-running the
same stage does not always reproduce it.

### Workaround

1. Confirm the failure is this race by checking that the `deliver-product` Argo logs show a
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
