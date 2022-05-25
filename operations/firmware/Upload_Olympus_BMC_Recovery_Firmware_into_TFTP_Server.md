# Upload BMC Recovery Firmware into TFTP Server

`cray-upload-recovery-images` is a utility for uploading the BMC recovery files for ChassisBMCs, NodeBMCs, and RouterBMCs to be served by the *cray-tftp* service. The tool uses the cray cli (*fas*, *artifacts*) and *cray-tftp* to download the s3 recovery images (as remembered by FAS) then upload them into the PVC that is used by *cray-tftp*.
`cray-upload-recovery-images` should be run on every system.

### Procedure

1. Execute the `cray-upload-recovery-images` script.

	```bash
	ncn# cray-upload-recovery-images
	Attempting to retrieve ChassisBMC .itb file
	s3:/fw-update/d7bb5be9eecc11eab18c26c5771395a4/cc-1.3.10.itb
	d7bb5be9eecc11eab18c26c5771395a4/cc-1.3.10.itb

	Uploading file: /tmp/cc.itb
	Defaulting container name to cray-ipxe.
	Successfully uploaded /tmp/cc.itb!
	removed /tmp/cc.itb
	ChassisBMC recovery image upload complete
	========================================
	Attempting to retrieve NodeBMC .itb file
	s3:/fw-update/d81157f7eecc11ea943d26c5771395a4/nc-1.3.10.itb
	d81157f7eecc11ea943d26c5771395a4/nc-1.3.10.itb

	Uploading file: /tmp/nc.itb
	Defaulting container name to cray-ipxe.
	Successfully uploaded /tmp/nc.itb!
	removed /tmp/nc.itb
	NodeBMC recovery image upload complete
	========================================
	Attempting to retrieve RouterBMC .itb file
	s3:/fw-update/d85398f2eecc11ea94ff26c5771395a4/rec-1.3.10.itb
	d85398f2eecc11ea94ff26c5771395a4/rec-1.3.10.itb

	Uploading file: /tmp/rec.itb
	Defaulting container name to cray-ipxe.
	Successfully uploaded /tmp/rec.itb!
	removed /tmp/rec.itb
	RouterBMC recovery image upload complete
	```
