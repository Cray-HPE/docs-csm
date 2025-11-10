# BOS, IMS, and CSM-Config Architecture Overview

This document provides architectural diagrams showing how the Boot Orchestration Service (BOS), Image Management Service (IMS), and CSM-Config work together to boot and configure compute nodes.

## High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ADMINISTRATOR                                       │
└───────────────────────┬─────────────────────────────────────────────────────┘
                        │
                        │ 1. Create/Customize Images
                        │ 2. Upload Config Playbooks
                        │ 3. Create BOS Session Templates
                        │ 4. Initiate Boot Sessions
                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     CRAY SYSTEM MANAGEMENT (CSM)                             │
│                                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                  │
│  │     IMS      │    │     BOS      │    │     CFS      │                  │
│  │    Image     │───▶│    Boot      │───▶│Configuration │                  │
│  │  Management  │    │Orchestration │    │  Framework   │                  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘                  │
│         │                   │                    │                          │
│         │                   │                    │                          │
│  ┌──────▼───────────────────▼────────────────────▼───────┐                 │
│  │              Ceph S3 Object Storage                    │                 │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │                 │
│  │  │ Boot Images  │  │   Recipes    │  │Config Repos │ │                 │
│  │  │(kernel,initrd│  │  (Kiwi-NG)   │  │  (Ansible)  │ │                 │
│  │  │  rootfs)     │  │              │  │             │ │                 │
│  │  └──────────────┘  └──────────────┘  └─────────────┘ │                 │
│  └────────────────────────────────────────────────────────┘                 │
│                                                                              │
│  ┌────────────────────────────────────────────────────────┐                 │
│  │  Supporting Services:                                  │                 │
│  │  • BSS (Boot Script Service)                           │                 │
│  │  • HSM (Hardware State Manager)                        │                 │
│  │  • PCS (Power Control Service)                         │                 │
│  │  • Nexus (RPM Repository)                              │                 │
│  │  • VCS (Version Control - Gitea)                       │                 │
│  └────────────────────────────────────────────────────────┘                 │
└───────────────────────────────┬──────────────────────────────────────────────┘
                                │
                                │ Boot artifacts, power control, configuration
                                ▼
                    ┌───────────────────────┐
                    │   COMPUTE NODES       │
                    │  (Hardware/BMCs)      │
                    └───────────────────────┘
```

## Image Creation and Boot Workflow

### Phase 1: Image Creation (IMS)

```
Administrator                    IMS                  Nexus/S3              Kiwi-NG
     │                            │                       │                    │
     │ 1. Upload Recipe          │                       │                    │
     ├──────────────────────────▶│                       │                    │
     │                            │ 2. Fetch Recipe      │                    │
     │                            ├──────────────────────▶│                    │
     │                            │◀──────────────────────┤                    │
     │                            │                       │                    │
     │                            │ 3. Get RPM Repos     │                    │
     │                            ├──────────────────────▶│                    │
     │                            │◀──────────────────────┤                    │
     │                            │                       │                    │
     │                            │ 4. Build Image        │                    │
     │                            ├───────────────────────┼───────────────────▶│
     │                            │                       │    (installs pkgs, │
     │                            │                       │     runs scripts)  │
     │                            │◀──────────────────────┼────────────────────┤
     │                            │      (kernel, initrd, rootfs)              │
     │                            │                       │                    │
     │                            │ 5. Upload Artifacts   │                    │
     │                            ├──────────────────────▶│                    │
     │                            │    to boot-images/    │                    │
     │                            │                       │                    │
     │ 6. Image ID Created       │                       │                    │
     │◀───────────────────────────┤                       │                    │
     │   (e.g., ims-id-12345)    │                       │                    │
```

### Phase 2: Configuration Setup (csm-config + CFS)

```
Administrator              VCS/Gitea              csm-config            CFS
     │                         │                      │                  │
     │ 1. Push Ansible         │                      │                  │
     │    Playbooks            │                      │                  │
     ├────────────────────────▶│                      │                  │
     │   (from csm-config)     │                      │                  │
     │                         │                      │                  │
     │ 2. Create CFS Config    │                      │                  │
     ├─────────────────────────┼──────────────────────┼─────────────────▶│
     │  (point to VCS repo)    │                      │                  │
     │                         │                      │                  │
     │ 3. Config Registered    │                      │                  │
     │◀────────────────────────┼──────────────────────┼──────────────────┤
     │  (config-name)          │                      │                  │
```

### Phase 3: Boot Orchestration (BOS)

```
Admin     BOS           S3        BSS       HSM       PCS      CFS      Node
  │        │            │          │         │         │        │         │
  │ 1. Create Session  │          │         │         │        │         │
  │   Template         │          │         │         │        │         │
  ├───────▶│           │          │         │         │        │         │
  │        │ (includes: │         │         │         │        │         │
  │        │  - node list)        │         │         │        │         │
  │        │  - ims-image-id)     │         │         │        │         │
  │        │  - cfs-config)       │         │         │        │         │
  │        │           │          │         │         │        │         │
  │ 2. Create Session  │          │         │         │        │         │
  ├───────▶│           │          │         │         │        │         │
  │        │           │          │         │         │        │         │
  │        │ 3. Get Boot Artifacts│         │         │        │         │
  │        ├──────────▶│          │         │         │        │         │
  │        │◀──────────┤          │         │         │        │         │
  │        │ (kernel, initrd,     │         │         │        │         │
  │        │  rootfs paths)       │         │         │        │         │
  │        │           │          │         │         │        │         │
  │        │ 4. Set Boot Params   │         │         │        │         │
  │        ├──────────────────────▶│        │         │        │         │
  │        │  (kernel params,     │         │         │        │         │
  │        │   artifact URLs)     │         │         │        │         │
  │        │           │          │         │         │        │         │
  │        │ 5. Check Node State  │         │         │        │         │
  │        ├─────────────────────────────────▶│       │        │         │
  │        │◀─────────────────────────────────┤       │        │         │
  │        │           │          │         │         │        │         │
  │        │ 6. Set CFS Config    │         │         │        │         │
  │        ├───────────────────────────────────────────▶│       │         │
  │        │  (disable until boot)│         │         │        │         │
  │        │           │          │         │         │        │         │
  │        │ 7. Power On Node     │         │         │        │         │
  │        ├──────────────────────────────────────────▶│       │         │
  │        │           │          │         │         │        │         │
  │        │           │          │         │         │ 8. Power On       │
  │        │           │          │         │         ├───────────────────▶│
  │        │           │          │         │         │        │         │
  │        │           │          │         │         │        │ 9. iPXE Boot
  │        │           │          │◀────────────────────────────────────────┤
  │        │           │          │ (get boot script)│         │         │
  │        │           │          ├────────────────────────────────────────▶│
  │        │           │          │         │         │        │         │
  │        │           │          │         │         │        │ 10. Download
  │        │           │◀──────────────────────────────────────────────────┤
  │        │           ├────────────────────────────────────────────────────▶│
  │        │           │ (kernel, initrd, rootfs)    │         │         │
  │        │           │          │         │         │        │         │
  │        │           │          │         │         │        │ 11. Boot OS
  │        │           │          │         │         │        │         │
  │        │ 12. Monitor Power    │         │         │        │         │
  │        ├─────────────────────────────────▶│       │        │         │
  │        │◀─────────────────────────────────┤       │        │         │
  │        │  (power: on)         │         │         │        │         │
  │        │           │          │         │         │        │         │
  │        │ 13. Enable CFS       │         │         │        │         │
  │        ├───────────────────────────────────────────▶│       │         │
  │        │           │          │         │         │        │         │
  │        │           │          │         │         │ 14. Run Ansible   │
  │        │           │          │         │         │        ├────────▶│
  │        │           │          │         │         │        │  (apply │
  │        │           │          │         │         │        │  config)│
  │        │           │          │         │         │        │◀────────┤
  │        │           │          │         │         │        │         │
  │        │ 15. Check CFS Status │         │         │        │         │
  │        ├───────────────────────────────────────────▶│       │         │
  │        │◀───────────────────────────────────────────┤       │         │
  │        │  (configuration complete)      │         │        │         │
  │        │           │          │         │         │        │         │
  │ 16. Session       │          │         │         │        │         │
  │    Complete       │          │         │         │        │         │
  │◀───────┤          │          │         │         │        │         │
```

## BOS Session Template Structure

```
Session Template
├─ name: "compute-node-template"
├─ boot_sets:
│  └─ "compute-nodes":
│     ├─ type: "s3"
│     ├─ path: "s3://boot-images/<ims-image-id>/manifest.json"
│     ├─ etag: "<s3-etag>"
│     ├─ kernel_parameters: "console=ttyS0,115200 ..."
│     ├─ node_list: ["x3000c0s1b0n0", "x3000c0s1b0n1", ...]
│     ├─ rootfs_provider: "sbps"
│     └─ cfs:
│        └─ configuration: "node-personalization-config"
├─ enable_cfs: true
└─ cfs:
   └─ configuration: "default-config"
```

## Data Flow Summary

### 1. **Image Creation Flow**
```
Kiwi Recipe → IMS → Kiwi-NG Build → Boot Artifacts → S3 → Image ID
```

### 2. **Configuration Flow**
```
csm-config (Ansible) → VCS/Gitea → CFS Configuration → Nodes (post-boot)
```

### 3. **Boot Flow**
```
Session Template → BOS → 
  ├─ Boot Artifacts (from S3/IMS) → BSS → Nodes
  └─ Configuration (from CFS) → Ansible → Nodes
```

## Key Integration Points

| Component | Provides To | What |
|-----------|-------------|------|
| **IMS** | S3 | Boot artifacts (kernel, initrd, rootfs) |
| **IMS** | BOS | Image manifest location in S3 |
| **csm-config** | VCS | Ansible playbooks for node configuration |
| **VCS** | CFS | Git repository containing configurations |
| **BOS** | BSS | Boot parameters and artifact locations |
| **BOS** | CFS | Configuration to apply to nodes |
| **BOS** | PCS | Power on/off commands |
| **BOS** | HSM | Node state queries |
| **S3** | Nodes | Boot artifacts during iPXE boot |
| **CFS** | Nodes | Ansible-based configuration |

## Service Dependencies

```
                    ┌─────────────┐
                    │   S3/Ceph   │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
         ┌────────┐   ┌────────┐   ┌────────┐
         │  IMS   │   │  BOS   │   │  VCS   │
         └────────┘   └───┬────┘   └───┬────┘
                          │            │
              ┌───────────┼────────┬───┘
              │           │        │
              ▼           ▼        ▼
         ┌────────┐   ┌────────┐  ┌────────┐
         │  PCS   │   │  BSS   │  │  CFS   │
         └────────┘   └────────┘  └────────┘
              │           │            │
              └───────────┼────────────┘
                          ▼
                    ┌──────────┐
                    │  Nodes   │
                    └──────────┘
```

## References

- [BOS Workflows](operations/boot_orchestration/BOS_Workflows.md)
- [Image Management Workflows](operations/image_management/Image_Management_Workflows.md)
- [BOS Documentation](operations/boot_orchestration/Boot_Orchestration.md)
- [IMS Documentation](operations/image_management/Image_Management.md)

