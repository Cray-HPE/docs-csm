<a name="cray-system-management"></a>
# Cray System Management (CSM) - Documentation

The documentation included here describes how to install or upgrade the Cray System Management (CSM)
software and related supporting operational procedures.  CSM software is the foundation upon which
other software product streams for the HPE Cray EX system depend.

This documentation is in Markdown format.  Although much of it can be viewed with any text editor,
a richer experience will come from using a tool which can render the Markdown to show different font
sizes, the use of bold and italics formatting, inclusion of diagrams and screen shots as image files,
and to follow navigational links within a topic file and to other files.

There are many tools which can render the Markdown format to get these advantages.  Any Internet search
for Markdown tools will provide a long list of these tools.  Some of the tools are better than others
at displaying the images and allowing you to follow the navigational links.

The exploration of the CSM documentation begins with the Table of Contents in
the [Cray System Management Installation Guide](index.md) which introduces 
topics related to CSM software installation, upgrade, and operational use.  Notice that the
previous sentence had a link to the index.md file for the Cray System Management Installation Guide. 
If the link does not work, then a better Markdown viewer is needed.

Within this REAMDME.md file, these topics are described.

   * [Offline Documentation](#offline-documentation)
   * [Review and Contribution](#review-and-contribution)
   * [Releases](#releases)
   * [Versioning](#versioning)
   * [Discussions](#discussions)


<a name="offline-documentation"></a>
### Offline Documentation

The CSM documentation is included within the CSM product release tarball.  After it has been installed, the 
documentation will be available at `/usr/share/doc/metal` as installed by the `docs-csm-install` rpm.

This command will report the version of your installed documentation:

```bash
ncn# rpm -q docs-csm-install
```

To install the latest docs-csm-install RPM after installation:

```bash
ncn# zypper ar -cf --gpgcheck-allow-unsigned https://packages.local/repository/csm-sle-15sp2 csm-sle-15sp2
ncn# zypper ref csm-sle-15sp2
ncn# zypper in -y --from csm-sle-15sp2 docs-csm-install
```

<a name="review-and-contribution"></a>
### Review and Contribution

Anyone with Git access to this repo may feel free to submit changes for review -- tagging to the
relevant ticket(s) (if necessary).

All changes undergo a review process.  This governance is up to the reviewers' discretion. The
review serves to keep core contributors in alignment while maintaining coherency throughout
the documentation.

<a name="releases"></a>
### Releases 

This guide follows a basic release model for enabling amendments and maintenance across releases.

> Note: Leading up to a release the "stable" and "unstable" branches may be _equal_.
> However once a release has shipped, any amendments to that release must be made to the respective release branch.

- The "stable" (release) version of this guide exists within branches prefixed with "`release/`"
- The "unstable" (latest) version of this guide exists within the `main` branch

<a name="versioning"></a>

### Versioning

This CSM documentation is versioned and packaged for offline reference.

    X.Y.Z-HASH

The HASH will always change, it changes for every contribution that is pushed to this repository.

The X.Y.Z does not always change, it must be incremented by the contributor or this repository's
owner(s). This pattern follows semantic version as described by http://semver.org.

- X: Major Version - This should be incremented by the repository owner for dramatic, or substantial
  changes to the structure or format.
- Y: Minor Version - This should be incremented by the developer when making new pages or large
  amendments to the flow.
- Z: Bug Fix/patch - This should be incremented by the developer when making amendments confined to
  a page.

Any contributor should feel welcome to ask for clarification on versioning within their change's review.

<a name="discussions"></a>
### Discussions

For discussion about the CSM documentation, see the HPE Cray Slack [#docs-csm].  This is not public.
External access may be available for various partners & customers.

