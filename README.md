# Non Compute Nodes (NCN)

This space covers everything non-compute node, from admin guides for deployments and upgrades
to overview/educational background information.

## Deployment Guides (LiveCD)

> If this topic is relevant to you, be sure to revisit this space for
> updates.

For **new users** of the liveCD on a Shasta metal cluster, start here:

* [LiveCD Creation](005-LIVECD-CREATION.md)
* [LiveCD Setup](006-LIVECD-SETUP.md)
* [LiveCD NCN Boots](007-LIVECD-NCN-BOOTS.md)

For **virtual** users, go [here](https://connect.us.cray.com/confluence/display/MTL/Shasta+Pre-install+Toolkit+Image%3A+Building+and+Booting) for assistance testing.

## 1.3 Upgrade & Rollback Guides

For guidance collecting information to embark on a 1.4 upgrade, see here:
* [LiveCD Preflight](004-LIVECD-PREFLIGHT.md)

For guidance on rolling back to the previous 1.3 install, see here:
* [LiveCD 1.3 Rollback](003-LIVECD-1.3-ROLLBACK.md)

## Packages in use

In MTL-1163, we're trying to track down what packages were in use in 1.3.  The goal is to get a defined list of packages we need installed and their specific version so we can ship only what we need.  This file has everything from 1.3 that was discovered and a list of what we install in 1.4 (under the ## livecd heading).

* [Package list](200-PACKAGES.md)

## 1.4+ Upgrade Guides

> TODO

## NCN Architecture

* [Images](100-IMAGES.md)
* [Booting](101-BOOTING.md)
* [Firmware](102-FIRMWARE.md)
* [Networking](103-NETWORKING.md)
* [Partitioning](104-PARTITIONING.md)
