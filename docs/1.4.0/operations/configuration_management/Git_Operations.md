# Git Operations

Use the `git` command to manage repository content in the Version Control Service \(VCS\).

Once a repository is cloned, the git command line tool is available to interact with a repository from VCS. The `git` command is used for making commits, creating new branches, and pushing new branches, tags, and commits to the remote repository stored in VCS.

When pushing changes to the VCS server using the `crayvcs` user, input the password retrieved from the Kubernetes secret as the credentials. See the "VCS Administrative User" heading in [Version Control Service \(VCS\)](Version_Control_Service_VCS.md#vcs-administrative-user) for more information.

```bash
git push
```

Enter the appropriate credentials when prompted:

```text
Username for 'https://api-gw-service-nmn.local': crayvcs
Password for 'https://crayvcs@api-gw-service-nmn.local': <input password here>
```

For more information on how to use the Git command line tools, refer to the external [Git User Manual](https://git-scm.com/docs/user-manual.html).
