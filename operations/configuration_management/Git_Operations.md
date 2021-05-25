## Git Operations

Use the git command to manage repository content in the Version Control Service \(VCS\).

Once a repository is cloned, the git command line tool is available to interact with a repository from the Version Control Service \(VCS\). The git command is used for making commits, creating new branches, and pushing new branches, tags, and commits to the remote repository stored in VCS.

<<<<<<< HEAD
When pushing changes to the VCS server using the `crayvcs` user, input the password retrieved from the Kubernetes secret as the credentials. See the "VCS Administrative User" heading in [Version Control Service \(VCS\)](Version_Control_Service_VCS.md) for more information.
=======
When pushing changes to the VCS server using the `crayvcs` user, input the password retrieved from the Kubernetes secret as the credentials. See the "VCS Administrative User" heading in [Version Control Service \(VCS\)](/portal/developer-portal/operations/Version_Control_Service_VCS.md) for more information.
>>>>>>> 269058d (STP-2624: imported several files from the admin guide)

```bash
ncn# git push
Username for 'https://api-gw-service-nmn.local': crayvcs
<<<<<<< HEAD
Password for 'https://crayvcs@api-gw-service-nmn.local': <input password here>
=======
Password for 'https://crayvcs@api-gw-service-nmn.local': **<input password here>**
>>>>>>> 269058d (STP-2624: imported several files from the admin guide)
...
```

For more information on how to use the git command line tools, refer to the external [Git User Manual](https://git-scm.com/docs/user-manual.html).




