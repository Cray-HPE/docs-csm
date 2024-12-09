# Backup and Restoring FAS Images

This procedure will backup all the images currently in FAS to allow for a restore.

To backup the images, first create an authentication token.
On most systems, this is created with the following command (`ncn-mw#`)

```bash
export TOKEN=$(curl -s -S -d grant_type=client_credentials \
-d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
-o jsonpath='{.data.client-secret}' | base64 -d` \
https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
| jq -r '.access_token')
```

Set the name of the Image Backup Directory (`ncn-mw#`)

```bash
outdir=nameofdir
```

Run the `FASBackupImages` (`ncn-mw#`)

```bash
/usr/share/doc/csm/scripts/operations/firmware/FASBackupImages.py $outdir
```

This will download images from S3 and create the image record for each file.
Each file will have its own directory.

To zip the entire collect for later restore (`ncn-mw#`)

```bash
zip -r $outdir.zip $outdir
```

To restore the images from the zip file into FAS (`ncn-mw#`)

```bash
cray fas images loader --file $outdir.zip
```

This will return a `loaderRunID` which can be used to verify the loading of the firmware.

```bash
cray fas images describe loaderRunID --format json
```
