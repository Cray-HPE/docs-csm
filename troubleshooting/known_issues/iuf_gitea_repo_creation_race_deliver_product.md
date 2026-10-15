# slingshot-shmem-config-management VCS repository creation fails with a `500 Internal Server Error`

## Description

During _slingshot-shmem_ upgrade with IUF, the `deliver-product` stage fails with `500 Internal Server Error`.
This happens when creating VCS repository for _slingshot-shmem_(`slingshot-shmem-config-management`).
_slingshot-shmem_ has two different branches for two different architectures(`aarch64` and `x86_64`).

IUF operation to import VCS artifacts for the two different architectures initially creates the repository.
During repository creation, if the request to create repository is given simultaneously to gitea for the two different branches, one of the requests succeeds while other fails with `500 Internal Server Error`

## Symptoms

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

## Impact

- IUF `deliver-product` stage fail with a `500 Internal Server Error` while creating a Gitea repository.

### Workaround

1. Rerun the `deliver-product` stage:

    ```bash
    iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run --site-vars "${ADMIN_DIR}/site_vars.yaml" -bpcd "${ADMIN_DIR}" -r deliver-product --force
    ```

    On the rerun, since the repository already exists the `deliver-product` stage succeeds with "repository already exists" message.

1. Verify the repository is present :

    ```bash
    curl -s https://api-gw-service-nmn.local/vcs/api/v1/repos/cray/slingshot-shmem-config-management
    ```
