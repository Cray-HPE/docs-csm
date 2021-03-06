<a name="cray-system-management---guides-and-references"></a>

# CRAY System Management - Guides and References

> **These pages are available offline on the LiveCD** all CSM documentation can be found at `/usr/share/doc/metal`.

* [CRAY System Management - Guides and References](#cray-system-management---guides-and-references)
    * [Offline Documentation](#offline-documentation)
    * [Review and Contribution](#review-and-contribution)
    * [Releases and Vintages](#releases-and-vintages)
    * [Versioning](#versioning)
    * [Discussions](#discussions)
    * [Original Authors / Reviewers](#original-authors-/-reviewers)

This repository serves to provides coherent guides for installing or upgrading a CRAY system across
all its various node-types and states.

Product Coverage:

- Cray Pre-Install Toolkit (LiveCD/PIT)
- Non-Compute Nodes (NCN)
- Compute Nodes (CNs)
- User Access Nodes (UAN)
- High-Speed Network (HSN)
    - **`hpe-portal`**: 📑[slingshot documentation][3]

One may also find technical information, see the following for navigating and contributing to this
guidebook:

- [Info / Inside-Panel](000-INFO.md) Contribution and rules
- [Table of Contents](001-GUIDES.md) Lay of the land; where information is by chapter

<a name="offline-documentation"></a>

### Offline Documentation

The docs on a customer's LiveCD should match their reality, their install should follow the docs
shipped on their liveCD.

This will report the version of your installed docs:

```bash
sles# rpm -q docs-csm-install
```

To install the latest docs-csm-install RPM after installation:

```bash
sles# zypper ar -cf --gpgcheck-allow-unsigned https://packages.local/repository/csm-sle-15sp2 csm-sle-15sp2
sles# zypper ref csm-sle-15sp2
sles# zypper in -y --from csm-sle-15sp2 docs-csm-install
```

<a name="review-and-contribution"></a>

### Review and Contribution

Anyone with Git access to this repo may feel free to submit changes for review, tagging to the
relevant JIRA(s) (if necessary).

All changes undergo a review process, this governance is up to the reviewers' own discretions. The
review serves to keep core contributors on the "same page" while maintaining coherency throughout
the doc.

<a name="releases-and-vintages"></a>

### Releases and Vintages

This guide follows a basic release model for enabling amendments and maintenance across releases.

> Note: Leading up to a release heads out the door the "stable" and "unstable" branches may be _equal_.
> However once a release has shipped, any amendments to that release must be made to the respective release branch.

- The "stable" (release) version of this guide exists within branches prefixed with "`release/`"
- The "unstable" (latest) version of this guide exists within the `master` branch

<a name="versioning"></a>

### Versioning

This guide is versioned and packaged for offline or in-field reference.

    X.Y.Z-HASH

The HASH will always change, it changes for every contribution that is pushed to this repository.

The X.Y.Z does not always change, it must be incremented by the contributor or this repository's
owner(s). This pattern follows [semver][2]:

- X: Major Version - this should be incremented by the repo owner for dramatic, or substantial
  changes to the structure or format of the guide.
- Y: Minor Version - this should be incremented by the developer when making new pages or large
  amendments to the flow.
- Z: Bug Fix/patch - this should be incremented by the developer when making amendments confined to
  a page.

Any contributor should feel welcome to ask for clarification on versioning within their change's
review.

<a name="discussions"></a>

### Discussions

See the Cray /HPE Slack [#docs-csm-install][1] (not public; external access may be available for
various partners & customers).

<a name="original-authors-/-reviewers"></a>

##### Original Authors / Reviewers

This document can be discussed in [#docs-csm-install][1].

These folks are main contributors or reviewers, none of which are the owners of this repository. Any
email should include the list, otherwise ping the slack channel.

- PET: [Brad Klein](mailto:bradley.klein@hpe.com)
- PET: [Craig DeLatte](mailto:craig.delatte@hpe.com)
- METAL: [Jacob Salmela](mailto:jacob.salmela@hpe.com)
- PET: [Jeanne Ohren](mailto:jeanne.ohren@hpe.com)
- METAL: [Russell Bunch](mailto:doomslayer@hpe.com)

[1]: https://cray.slack.com/messages/docs-csm-install

[2]: https://semver.org/

[3]: http://web.us.cray.com/~ekoen/slingshot_portal/master/portal/public/developer-portal/overview/