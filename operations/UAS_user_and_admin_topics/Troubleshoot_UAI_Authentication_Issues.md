/var/www/ephemeral/${CSM_RELEASE}/hack/load-container-image.sh dtr.dev.cray.com/zeromq/zeromq:v4.0.5
/var/www/ephemeral/prep/site-init/utils/secrets-reencrypt.sh /var/www/ephemeral/prep/site-init/customizations.yaml \
/var/www/ephemeral/prep/site-init/certs/sealed_secrets.key /var/www/ephemeral/prep/site-init/certs/sealed_secrets.crt
/var/www/ephemeral/prep/site-init/utils/secrets-seed-customizations.sh \
/var/www/ephemeral/prep/site-init/customizations.yaml
