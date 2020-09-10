# Booting

This covers booting in every context, namely:
- Bootstrap: bare-metal or fresh-installs of a Shasta metal cluster.
- Installed: a deployed Shasta stack on metal.

### Bootstrap

> Responsibility: **LiveCD (`spit.nmn`)**

1. NCNs will network boot using PXE and fetch an x86_64-secureboot iPXE binary.
2. The iPXE binary chains to a final script, defining HTTP endpoints for kernel and initrd locations.
3. Artifacts are fetched & written to disk (squashFS).
4. System pivots to boot from local squashFS.
5. Cloud-init provides personalization.

The disk-write is for two reasons:
- Running the squashFS from disk frees memory, vs. running it in memory.
- The local image serves as a fallback.

### Installed

> Responsibility: **BOS**
 
1. NCNs will network boot using PXE.
2.  cray-tftp replies with a compiled iPXE binary pointing to the next chain..
3. cray-bss replies with a final script to point the node to its artifacs (squashFS).
4. iPXE script runs and fetches from S3.
5. Artifacts are written to disk (squashFS).
6. System pivots to local squashFS.
7. Cloud-init provides personalization.
 
### Flow

[![Layered Images Diagram](./img/ncn-flow.png)](https://miro.com/app/board/o9J_kmgYTe4=/?moveToWidget=3074457349632214094&cot=12)
