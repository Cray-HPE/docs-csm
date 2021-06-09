## Manage Ceph Services

The following commands are required to start, stop, or restart Ceph services. Restarting Ceph services is helpful for troubleshoot issues with the utility storage platform.

**Important:** Commands to start or stop Ceph processes must be run on the node where the process exists.

### Ceph Monitor Service

**Location:** Commands can be run on the node where the ceph-mon service is being restarted.

Start the ceph-mon service:

```bash
ncn-m001# systemctl start ceph-mon@NODE_NAME
```

Stop the ceph-mon service:

```bash
ncn-m001# systemctl stop ceph-mon@NODE_NAME
```

Restart the ceph-mon service:

```bash
ncn-m001# systemctl restart ceph-mon@NODE_NAME
```

### Ceph OSD Service

**Location:** Commands can be run on the node where the OSD resides.

Start the ceph-osd service:

```bash
ncn-m001# systemctl start ceph-osd@OSD_NAME
```

Stop the ceph-osd service:

```bash
ncn-m001# systemctl stop ceph-osd@OSD_NAME
```

Restart the ceph-osd service:

```bash
ncn-m001# systemctl restart ceph-osd@OSD_NAME
```

### Ceph Manager Service

**Location:** Commands can be run on the node where the ceph-mgr service is being restarted.

Start the ceph-mgr service:

```bash
ncn-m001# systemctl start ceph-mgr@NODE_NAME
```

Stop the ceph-mgr service:

```bash
ncn-m001# systemctl stop ceph-mgr@NODE_NAME
```

Restart the ceph-mgr service:

```bash
ncn-m001# systemctl restart ceph-mgr@NODE_NAME
```

### Ceph Rados-Gateway Service

**Location:** Commands can be run on the node where the rados-gateway is being restarted.

Start the rados-gateway:

```bash
ncn-m001# systemctl start ceph-radosgw@rgw.NODE_NAME.rgw0
```

Stop the rados-gateway:

```bash
ncn-m001# systemctl stop ceph-radosgw@rgw.NODE_NAME.rgw0
```

Restart the rados-gateway:

```bash
ncn-m001# systemctl restart ceph-radosgw@rgw.NODE_NAME.rgw0
```

### Ceph Manager Modules

**Location:** Ceph manager modules can be enabled or disabled from any ceph-mon nodes.

Enable Ceph manager modules:

```bash
ncn-m001# ceph mgr MODULE_NAME enable MODULE
```

Disable Ceph manager modules:

```bash
ncn-m001# ceph mgr MODULE_NAME disable MODULE
```


