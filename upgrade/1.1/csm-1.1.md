Copyright 2021 Hewlett Packard Enterprise Development LP

# CSM 1.1 Upgrade Guide

Procedures:

- [CSM 1.1 Upgrade Guide](#csm-11-upgrade-guide)
  - [Update Customizations](#update-customizations)

<a name="update-customizations"></a>
## Update Customizations

Before [deploying upgraded manifests](#deploy-manifests), `customizations.yaml`
in the `site-init` secret in the `loftsman` namespace must be updated.

1. If the [`site-init` repository is available as a remote
   repository](../../install/prepare_site_init.md#push-to-a-remote-repository) then clone
   it on the host orchestrating the upgrade:

   ```bash
   ncn-m001# git clone "$SITE_INIT_REPO_URL" site-init
   ```

   Otherwise, create a new `site-init` working tree:

   ```bash
   ncn-m001# git init site-init
   ```

1. Download `customizations.yaml`:

   ```bash
   ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

1. Review, add, and commit `customizations.yaml` to the local `site-init`
   repository as appropriate.

   > **`NOTE:`** If `site-init` was cloned from a remote repository in step 1,
   > there may not be any differences and hence nothing to commit. This is
   > okay. If there are differences between what's in the repository and what
   > was stored in the `site-init`, then it suggests settings were improperly
   > changed at some point. If that's the case then be cautious, _there may be
   > dragons ahead_.

   ```bash
   ncn-m001# cd site-init
   ncn-m001# git diff
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Add customizations.yaml from site-init secret'
   ```

1. Update `customizations.yaml`.

   ```bash
   linux# yq write -s - -i ./customizations.yaml <<EOF
   - command: update
     path: spec.kubernetes.services.cray-dns-unbound.domain_name
     value: '{{ network.dns.external }}'
   EOF
   ```

1. Review the changes to `customizations.yaml` and verify [baseline system
   customizations](../../install/prepare_site_init.md#create-baseline-system-customizations)
   and any customer-specific settings are correct.

   ```
   ncn-m001# git diff
   ```

1. Add and commit `customizations.yaml` if there are any changes:

   ```
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m "Update customizations.yaml consistent with CSM $CSM_RELEASE_VERSION"
   ```

1. Update `site-init` sealed secret in `loftsman` namespace:

   ```bash
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. Push to the remote repository as appropriate:

   ```bash
   ncn-m001# git push
   ```
