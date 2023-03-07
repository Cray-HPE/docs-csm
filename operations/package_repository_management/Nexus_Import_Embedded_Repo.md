# The Embedded Repository 

The "embedded repo" is the complete set of packages installed on the Kubernetes and Storage Ceph NCN images, as well as the packages found on the PIT ISO. The list of installed packages in these images is queried when building each CSM release tarball, and a repo is created from that list and included in the CSM release tarball. This procedure describes how to manually install the "embedded repo" into Nexus.

## Manually import the Embedded Repository into Nexus

**Prerequisites:** 

1. The CSM $RELEASE_VERSION is required and will be provided as the 1st parameter to the import script, described below. 

1. It is necessary to have an extracted copy of the CSM release tarball available at a known path in order to proceed. This path will be provided as the 2nd paramter to the import script, described below.

(`ncn-m#`) Run the following command on a master node:

```bash
/usr/share/doc/csm/operations/nexus/setup-embedded-repository.sh $RELEASE_VERSION $PATH_TO_EXTRACTED_CSM_TARBALL_CONTENT
```

On the success, the above command will report:

\+ Nexus setup complete
setup-embedded-repository.sh: OK


## Using the Embedded Repo

In order to access the packages in the embedded repo, it is necessary to add the repository to zypper on each of the NCNs it will be accessed from. A simple "zypper ar" command is all that is needed:

(`ncn-m#`) zypper ar https://packages.local/repository/csm-${RELEASE_VERSION}-embedded csm-embedded

